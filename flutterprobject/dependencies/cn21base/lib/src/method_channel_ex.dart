import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'async_util.dart';

/// 对象转换函数定义
/// 用于将[MethodChannelEx]中Codec解码返回的对象数据进行额外的转换操作
/// 例如[StandardMethodCodec]可能将调用返回的编码数据decode为List，然后
/// 通过此函数可以做任何将List转换为任意目标对象的操作。
/// 注意，此函数必须是顶级函数，不能是类中的方法。
/// @param from 经过Codec解码后的数据
/// @return 经过转换后的对象，作为[MethodChannelEx]中方法调用最终返回的实例。
/// 因此必须与invokeMethodAndConvert<T>中的T具有相容性
typedef ConvertToObject = FutureOr<dynamic> Function(dynamic from);

/// [MethodChannelEx]中invokeMethod返回数据时所提供的返回方式类型。
/// 其中normal与一般的返回方式一致，即一次调用后在send中返回数据，
/// stream方式则将返回数据通过单独的数据通道进行分批传送。调用时
/// send只返回[_MethodStreamDataDesc]实例说明需要接收的数据通道信息。
/// [MethodChannelEx]自动从数据通道中获取并最终合成应用需要的数据。
/// 因此这两种方式对使用方完全透明。
enum _DataTransferType { normal, stream }

/// 方法调用返回的数据通道描述对象
class _MethodStreamDataDesc {
  /// 数据通道名称，全局唯一
  final String dataChannelName;

  /// 列表元素的总数量（非分批数量）
  final int elementCount;
  _MethodStreamDataDesc(this.dataChannelName, this.elementCount);
}

/// 数据分批迭代提供处理函数定义
/// 当[MethodChannelEx]方法调用需要返回大量数据对象时，可提供该函数用于
/// 对返回的数据对象列表进行分割，以便分批传送处理。这样有利于
/// 1、提高内存的利用率和内存分配压力(小块内存更容易分配)，减少GC
/// 2、均衡对数据进行decode和转换及内存拷贝耗时，避免UI卡顿
/// @param list 需要分割的数据对象列表集合
/// @param refMethodCall 涉及的[MethodCall]对象实例
/// @return 分割的迭代器，每次迭代提供相应的该批次的数据对象子列表
typedef SplitListIteratorHandler = Iterable<List> Function(
    List list, MethodCall refMethodCall);

/// 方法编解码包装类
class _MethodCodecEx implements MethodCodec {
  final MethodCodec wrappedCodec;

  const _MethodCodecEx(this.wrappedCodec);

  @override
  dynamic decodeEnvelope(ByteData envelope) {
    final result = wrappedCodec.decodeEnvelope(envelope);
    // 执行至此表示没有异常发送
    if (result is List) {
      int code = result[0];
      if (code == _DataTransferType.normal.index) {
        // 普通数据类型
        return result[1];
      } else if (code == _DataTransferType.stream.index) {
        // 数据流方式
        return _MethodStreamDataDesc(result[1], result[2]);
      }
    }
    return result;
  }

  @override
  MethodCall decodeMethodCall(ByteData methodCall) {
    return wrappedCodec.decodeMethodCall(methodCall);
  }

  @override
  ByteData encodeErrorEnvelope({String code, String message, details}) {
    return wrappedCodec.encodeErrorEnvelope(
        code: code, message: message, details: details);
  }

  @override
  ByteData encodeMethodCall(MethodCall methodCall) {
    return wrappedCodec.encodeMethodCall(methodCall);
  }

  @override
  ByteData encodeSuccessEnvelope(result) {
    List wrapResult;
    if (result is _MethodStreamDataDesc) {
      // 用流式数据通道传送数据
      wrapResult = [
        _DataTransferType.stream.index, // 流式数据
        result.dataChannelName, // 数据通道名称
        result.elementCount // 列表元素数量
      ];
      return wrappedCodec.encodeSuccessEnvelope(wrapResult);
    }
    // 用普通方式(非分割)编码
    wrapResult = [_DataTransferType.normal.index, result];
    return wrappedCodec.encodeSuccessEnvelope(wrapResult);
  }
}

/// 编解码调度执行处理函数定义
/// [MethodChannelEx]使用者提供该函数的实现，完成对编解码等
/// 耗时操作的调度执行。通常通过Isolate机制进行调度以避免
/// UI线程阻塞。该函数最终必须通过执行entry(argument)完成
/// 相应的任务，并返回其结果。
/// @param entry 需要被调度执行的任务入口函数，必须为顶级函数
/// @param argument 执行entry时需要传入的参数
/// @return 调度运行entry后返回的结果
typedef ScheduleExecute<Q, R> = FutureOr<R> Function(
    ComputeCallback<Q, R> entry, Q argument);

/// [MethodChannelEx]编解码调度器提供者对象，用于提供
/// 用于执行不同编解码任务的[ScheduleExecute]函数实例
abstract class MethodChannelScheduler {
  /// 获取用于编码任务的[ScheduleExecute]调度器函数实例
  /// @param data 将要被编码的对象实例
  /// @param refMethodCall 涉及的[MethodCall]对象，nullable
  /// @param caller true表示用于作为调用方的参数编码(即data
  /// 是调用invokeMethod时的参数)，false表示用于作为被调用方
  /// 返回数据时的结果编码(即data是处理来自Native的invokeMethod
  /// 调用后需要返回的结果)
  /// @return [ScheduleExecute]调度器函数或null表示不需要额外调度
  ScheduleExecute<Q, ByteData> schedulerForEncode<T, Q>(
      T data, MethodCall refMethodCall, bool caller);

  /// 获取用于解码任务的[ScheduleExecute]调度器函数实例
  /// @param data 将要被解码的原始数据
  /// @param refMethodCall 涉及的[MethodCall]对象，nullable
  /// @param caller true表示用于作为调用方获取到返回结果解码(即data
  /// 是调用invokeMethod后返回的结果)，false表示用于作为被调用方
  /// 对接收到的参数的解码(即data是处理来自Native的invokeMethod
  /// 调用中的参数)
  /// @return [ScheduleExecute]调度器函数或null表示不需要额外调度
  ScheduleExecute<Q, R> schedulerForDecode<Q, R>(
      ByteData data, MethodCall refMethodCall, bool caller);
}

/// 基于Isolate的调度器提供者对象
class IsolateScheduler implements MethodChannelScheduler {
  final IsolateService _isolateService;

  /// 构造方法。
  /// 通过isolateService生成相应的调度器函数实例
  IsolateScheduler(IsolateService isolateService)
      : _isolateService = isolateService;

  @override
  ScheduleExecute<Q, R> schedulerForDecode<Q, R>(
      ByteData data, MethodCall refMethodCall, bool caller) {
    final Function execute = (ComputeCallback<Q, R> entry, Q arg) {
      return _isolateService.execute(entry, arg);
    };
    return execute;
  }

  @override
  ScheduleExecute<Q, ByteData> schedulerForEncode<T, Q>(
      T data, MethodCall refMethodCall, bool caller) {
    final Function execute = (ComputeCallback<Q, ByteData> entry, Q arg) {
      return _isolateService.execute(entry, arg);
    };
    return execute;
  }
}

/// 用于调度执行MethodCall编码的顶级内部函数
/// @param arguments 打包的参数列表，0th是[MethodCall]实例，1th是[_MethodCodecEx]实例
ByteData _encodeMethodCall(List arguments) {
  final MethodCall methodCall = arguments[0];
  final _MethodCodecEx codec = arguments[1];
  return codec.encodeMethodCall(methodCall);
}

/// 用于调度执行调用结果解码的顶级内部函数
/// @param arguments 打包的参数列表，
/// 0th是编码的结果实例，
/// 1th是[_MethodCodecEx]实例，
/// 2th如果存在，是[ConvertToObject]顶级函数实例
FutureOr<T> _decodeMethodResult<T>(List arguments) {
  final ByteData data = arguments[0];
  final _MethodCodecEx codec = arguments[1];
  final ConvertToObject handleConvert =
      (arguments.length > 2) ? arguments[2] : null;
  final result = codec.decodeEnvelope(data);
  // rawData可能是内部使用的[_MethodStreamDataDesc]实例，
  // 在调用真正的handler前必须先过滤
  if (handleConvert != null && result is! _MethodStreamDataDesc) {
    return handleConvert(result);
  } else {
    return result;
  }
}

/// 用于调度执行MethodCall解码的顶级内部函数
/// @param arguments 打包的参数列表，0th是[MethodCall]实例，1th是[_MethodCodecEx]实例
MethodCall _decodeMethodCall(List arguments) {
  final ByteData methodCall = arguments[0];
  final _MethodCodecEx codec = arguments[1];
  return codec.decodeMethodCall(methodCall);
}

/// 用于调度执行调用结果编码的顶级内部函数
/// @param arguments 打包的参数列表，0th是待编码的结果实例，1th是[_MethodCodecEx]实例
ByteData _encodeReturnResult<T>(List arguments) {
  final T data = arguments[0];
  final _MethodCodecEx codec = arguments[1];
  return codec.encodeSuccessEnvelope(data);
}

/// 扩展的[MethodChannel]，基本用法与[MethodChannel]相同，
/// 但针对[MethodChannel]在UI线程进行参数及返回结果的编解码
/// 进行了以下优化
/// 1、提供调度器机制，耗时的编解码及对象转换操作可在Isolate
/// 中进行处理
/// 2、提供对同时传送大量对象的调用结果进行分批传送机制，从而
/// 避免大内存分批造成的OOM、GC问题，同时避免UI线程的大内存拷贝
/// 耗时造成卡顿问题
class MethodChannelEx extends MethodChannel {
  final _MethodCodecEx _codec;
  final SplitListIteratorHandler _splitToStream;
  final MethodChannelScheduler _methodChannelScheduler;
  static int _sDataChannelsNumber = 0;
  static List<String> _dataChannelTrackList = [];

  /// 构造方法
  /// 除了[MethodChannel]所需的参数外，使用者可以指定用于处理编解码任务调度
  /// 的[MethodChannelScheduler]对象实例，以及用于分割数据传递的
  /// [SplitListIteratorHandler]函数对象实例
  ///
  /// 例子：
  ///
  /// // 警告：以下仅是简单的调度器，仅用于示例说明，请不要在实际工程中无脑使用！
  /// class MyUselessScheduler extends IsolateScheduler {
  ///  MyUselessScheduler(IsolateService isolateService) : super(isolateService);
  ///
  ///  @override
  ///  schedulerForDecode<Q, R>(
  ///      ByteData data, MethodCall refMethodCall, bool caller) {
  ///    if (data.lengthInBytes > 512 * 1024) {
  ///      // 仅当数据大小超过512K时，才通过isolate调度解码
  ///      return super.schedulerForDecode<Q, R>(data, refMethodCall, caller);
  ///    } else {
  ///      // 不需要调度
  ///      return null;
  ///    }
  ///  }
  ///
  ///  @override
  ///  schedulerForEncode<T, Q>(T data, MethodCall refMethodCall, bool caller) {
  ///    if (caller &&
  ///        data != null &&
  ///        data is MethodCall &&
  ///        refMethodCall != null &&
  ///        refMethodCall.method == "someFunction") {
  ///      final List largeData = refMethodCall.arguments[0];
  ///      if (largeData.length > 1000) {
  ///        // 仅当目标函数为someFunction，其中参数是列表且元素数量过大
  ///        // 时才使用isolate进行调度编码
  ///        return super.schedulerForEncode<T, Q>(data, refMethodCall, caller);
  ///      }
  ///    }
  ///    // 不需要调度
  ///    return null;
  ///  }
  /// }
  ///
  /// void test() {
  ///   final SplitListIteratorHandler handler =
  ///      (List list, MethodCall refMethodCall) {
  ///    // 仅当结果列表元素总数超过2000时才进行分割
  ///    if (list.length > 2000) {
  ///      // 返回一个分批的Iterable迭代器
  ///      return () sync* {
  ///        int index = 0;
  ///        int total = list.length;
  ///        while (index < total) {
  ///          int remain = total - index;
  ///          int subsize = (remain < 2000) ? remain : 2000;
  ///          // 最多每2000个元素产生一个sub-list
  ///          yield list.getRange(index, index + subsize).toList();
  ///          index += subsize;
  ///        }
  ///      }();
  ///    }
  ///    // 无需分批
  ///    return null;
  ///  };
  ///
  ///  // 使用isolate并发机制进行调度控制
  ///  final scheduler = MyUselessScheduler(IsolateService()..initService());
  ///  MethodChannelEx channel = MethodChannelEx('mychannel',
  ///      methodChannelScheduler: scheduler,
  ///      splitListIteratorHandler: handler,
  ///      codec: StandardMethodCodec());
  /// }
  ///
  MethodChannelEx(
    String name, {
    MethodChannelScheduler methodChannelScheduler,
    SplitListIteratorHandler splitListIteratorHandler,
    MethodCodec codec = const StandardMethodCodec(),
    /*BinaryMessenger binaryMessenger = defaultBinaryMessenger*/
  })  : _codec = _MethodCodecEx(codec),
        _methodChannelScheduler = methodChannelScheduler,
        _splitToStream = splitListIteratorHandler,
        super(
          name,
          codec, /*binaryMessenger*/
        );

  /// 尝试创建数据通道方法
  /// 负责根据使用者指定的[SplitListIteratorHandler]判断是否需要
  /// 使用分批传递机制，并且建立相应的数据通道及返回通道信息
  _MethodStreamDataDesc _tryCreateDataStream(
      List list, MethodCall refMethodCall) {
    final iterable = _splitToStream?.call(list, refMethodCall);
    if (iterable != null && iterable.isNotEmpty) {
      // 需要对列表进行分割，创建额外数据通道进行处理
      final dataChannelName = '${name}_fdata:${++_sDataChannelsNumber}';
      int currentIndex = 0;
      int total = iterable.length;
      BinaryMessages.setMessageHandler(dataChannelName,
          (ByteData message) async {
        if (message != null) {
          final result = iterable.elementAt(currentIndex);
          currentIndex++;
          if (currentIndex >= total) {
            // 没有更多数据需要对方获取，关闭数据通道
            BinaryMessages.setMessageHandler(dataChannelName, null);
            _dataChannelTrackList.remove(dataChannelName);
          }
          if (_methodChannelScheduler != null) {
            ScheduleExecute<List, ByteData> execute = _methodChannelScheduler
                .schedulerForEncode(result, refMethodCall, false);
            if (execute != null)
              return execute(_encodeReturnResult, [result, _codec]);
          }
          return _encodeReturnResult([result, _codec]);
        }
        // 对方要求关闭
        BinaryMessages.setMessageHandler(dataChannelName, null);
        _dataChannelTrackList.remove(dataChannelName);
        return null;
      });
      _dataChannelTrackList.add(dataChannelName);
      return _MethodStreamDataDesc(dataChannelName, list.length);
    }
    return null;
  }

  /// 从指定的数据通道读取分批数据并还原，同时完成对象的转换操作
  Future<List> _readResultFromDataChannel(
      _MethodStreamDataDesc desc, ConvertToObject convertHandler) async {
    final actionRecv = ByteData(1)..setInt8(0, 0);
    ByteData data;
    List resultList = List.filled(desc.elementCount, null, growable: true);
    int offset = 0;
    try {
      while (offset < desc.elementCount) {
        // 请求获取一次迭代的列表数据
        data = await BinaryMessages.send(desc.dataChannelName, actionRecv);
        if (data != null && data.lengthInBytes > 0) {
          List pack = _codec.wrappedCodec.decodeEnvelope(data);
          // 第0个元素表示数据传输类型，这里应该恒为0，表示不需要再分割(因为这个
          // 数据通道就是用于接收已经分割好的各个分片数据)。第1个元素是分片后的数据
          assert(pack[0] == 0);
          List result = pack[1];
          if (convertHandler != null) {
            resultList.setRange(
                offset, offset + result.length, convertHandler(result));
          } else {
            resultList.setRange(offset, offset + result.length, result);
          }
          offset += result.length;
        } else {
          // 没有数据了
          break;
        }
      }
    } catch (e) {
      debugPrint('_readResultFromDataChannel exception:${e.toString()}');
    }
    assert(offset == desc.elementCount);
    if (offset < desc.elementCount) {
      // For safety
      resultList.removeRange(offset, resultList.length);
    }
    return resultList;
  }

  /// 处理调用方法时的编码操作
  FutureOr<ByteData> _handleEncodeMethodCall(MethodCall methodCall) {
    if (_methodChannelScheduler != null) {
      ScheduleExecute<List, ByteData> execute = _methodChannelScheduler
          .schedulerForEncode(methodCall, methodCall, true);
      if (execute != null)
        return execute(_encodeMethodCall, [methodCall, _codec]);
    }
    return _encodeMethodCall([methodCall, _codec]);
  }

  /// 处理调用返回结果的解码操作
  FutureOr<dynamic> _handleDecodeReturnResult(ByteData data,
      [MethodCall refMethodCall, ConvertToObject convertHandler]) {
    if (_methodChannelScheduler != null) {
      ScheduleExecute<List, dynamic> execute =
          _methodChannelScheduler.schedulerForDecode(data, refMethodCall, true);
      if (execute != null)
        return execute(_decodeMethodResult, [data, _codec, convertHandler]);
    }
    FutureOr<dynamic> typedResult =
        _decodeMethodResult([data, _codec, convertHandler]);
    return typedResult;
  }

  /// 处理收到调用请求后的参数解码操作
  FutureOr<MethodCall> _handleDecodeMethodCall(ByteData data) {
    if (_methodChannelScheduler != null) {
      ScheduleExecute<List, MethodCall> execute =
          _methodChannelScheduler.schedulerForDecode(data, null, false);
      if (execute != null) return execute(_decodeMethodCall, [data, _codec]);
    }
    FutureOr<MethodCall> typedResult = _decodeMethodCall([data, _codec]);
    return typedResult;
  }

  /// 处理收到的请求处理完后结果返回的编码操作
  FutureOr<ByteData> _handleEncodeReturnResult<T>(
      T result, MethodCall refMethodCall) {
    if (result is List) {
      // 尝试分割列表及建立数据通道
      final streamDesc = _tryCreateDataStream(result, refMethodCall);
      if (streamDesc != null) {
        // 使用通道分批传送。由于只是建立了数据通道并将基本的通道信息作为
        // 结果返回，因此无需调度执行encode工作
        return _codec.encodeSuccessEnvelope(streamDesc);
      }
    }
    // 不进行分配传送
    if (_methodChannelScheduler != null) {
      ScheduleExecute<List, ByteData> execute = _methodChannelScheduler
          .schedulerForEncode(result, refMethodCall, false);
      if (execute != null)
        return execute(_encodeReturnResult, [result, _codec]);
    }
    return _encodeReturnResult([result, _codec]);
  }

  @override
  @optionalTypeArgs
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) async {
    final result = await _invokeMethod(method, null, arguments);
    return result as T;
  }

  /// 以预期返回List<T>数据的方式进行调用并指定对象转换操作
  ///
  /// 例子：
  /// 将data（假设为List<List<dynamic>>）转换为List<MyData>
  /// 其中List<List<dynamic>>中每个元素都是一个sublist，每个sublist
  /// 都是MyData实例编码后生成，通过MyData的fromList类方法可以
  /// 通过sublist构造出MyData实例
  ///
  /// FutureOr<dynamic> _convertToObject(dynamic data) {
  ///   final List list = data;
  ///   list.map((sublist) => MyData.fromList(sublist));
  ///   // 返回的是List<MyData>实例
  ///   return list.map((sublist) => MyData.fromList(sublist)).toList()
  /// }
  ///
  /// void somefunc() async {
  ///   // 注意此处 _convertToObject 应该返回的是[List<MyData>]而非[MyData]实例
  ///   final List<MyData> data = await channel.invokeListMethodAndConvert<MyData>(
  ///        'getDataFromListStream', _convertToObject);
  ///   print('getDataFromListStream decoded');
  /// }
  ///
  Future<List<T>> invokeListMethodAndConvert<T>(
      String method, ConvertToObject convertHandler,
      [dynamic arguments]) async {
    final List<dynamic> result = await invokeMethodAndConvert<List<dynamic>>(
        method, convertHandler, arguments);
    return result?.cast<T>();
  }

  /// 在invokeMethod的基础上对解码后的数据转换为T类型对象
  ///
  /// 例子：
  /// 将data（假设为List<dynamic>）转换为MyData
  /// 其中List<dynamic>是MyData实例编码后生成，
  /// 通过MyData的fromList类方法可以通过List<dynamic>
  /// 构造出MyData实例
  ///
  /// FutureOr<dynamic> _convertToObject(dynamic data) {
  ///   final List list = data;
  ///   return MyData.fromList(list);
  /// }
  ///
  /// void somefunc() async {
  ///   final MyData data = await channel.invokeMethodAndConvert<MyData>(
  ///        'getDataFromList', _convertToObject);
  ///   print('getDataFromList decoded');
  /// }
  Future<T> invokeMethodAndConvert<T>(
      String method, ConvertToObject convertHandler,
      [dynamic arguments]) async {
    final result = await _invokeMethod(method, convertHandler, arguments);
    return result as T;
  }

//  Future<Stream<T>> invokeMethodAndDecodeStream<T>(
//      String method, void decodeHandler(ByteData data, Sink sink),
//      [dynamic arguments, bool execOnlyOnListen = false]) async {
//    final encoded = await _isolateService.execute(
//        _encodeMethodCall, MethodCall(method, arguments));
//    final ByteData result = await binaryMessenger.send(name, encoded);
//    if (result == null) {
//      throw MissingPluginException(
//          'No implementation found for method $method on channel $name');
//    }
//    final Stream<T> typedResult =
//        _isolateService.executeStream(decodeHandler, result, execOnlyOnListen);
//    return typedResult;
//  }

  /// 实际的方法调用过程处理方法
  @optionalTypeArgs
  Future _invokeMethod(String method, ConvertToObject convertHandler,
      [dynamic arguments]) async {
    assert(method != null);
    ByteData encoded;
    final methodCall = MethodCall(method, arguments);

    /// 处理参数的编码及调度
    final data = _handleEncodeMethodCall(methodCall);
    encoded = (data is Future) ? (await data) : data;
    final ByteData result = await BinaryMessages.send(name, encoded);
    if (result == null) {
      throw MissingPluginException(
          'No implementation found for method $method on channel $name');
    }

    dynamic finalResult;
    // 处理返回结果的解码及调度
    final decoded =
        _handleDecodeReturnResult(result, methodCall, convertHandler);
    final obj = (decoded is Future) ? (await decoded) : decoded;
    if (obj is _MethodStreamDataDesc) {
      // 结果以流的方式由数据通道返回
      final list = await _readResultFromDataChannel(obj, convertHandler);
      finalResult = list;
    } else {
      finalResult = obj;
    }
    return finalResult;
  }

  /// Sets a callback for receiving method calls on this channel.
  ///
  /// The given callback will replace the currently registered callback for this
  /// channel, if any. To remove the handler, pass null as the
  /// `handler` argument.
  ///
  /// If the future returned by the handler completes with a result, that value
  /// is sent back to the platform plugin caller wrapped in a success envelope
  /// as defined by the [codec] of this channel. If the future completes with
  /// a [PlatformException], the fields of that exception will be used to
  /// populate an error envelope which is sent back instead. If the future
  /// completes with a [MissingPluginException], an empty reply is sent
  /// similarly to what happens if no method call handler has been set.
  /// Any other exception results in an error envelope being sent.
  @override
  void setMethodCallHandler(Future<dynamic> handler(MethodCall call)) {
    BinaryMessages.setMessageHandler(
      name,
      handler == null
          ? null
          : (ByteData message) => _handleAsMethodCall(message, handler),
    );
  }

  /// 收到来自Native端的调用后的处理总入口
  Future<ByteData> _handleAsMethodCall(
      ByteData message, Future<dynamic> handler(MethodCall call)) async {
    // 处理方法参数的解码及调度
    final data = _handleDecodeMethodCall(message);
    final MethodCall call = (data is Future) ? (await data) : data;
    try {
      final result = await handler(call);
      // 处理返回结果的编码及调度
      return _handleEncodeReturnResult(result, call);
    } on PlatformException catch (e) {
      return codec.encodeErrorEnvelope(
        code: e.code,
        message: e.message,
        details: e.details,
      );
    } on MissingPluginException {
      return null;
    } catch (e) {
      return codec.encodeErrorEnvelope(
          code: 'error', message: e.toString(), details: null);
    }
  }
}
