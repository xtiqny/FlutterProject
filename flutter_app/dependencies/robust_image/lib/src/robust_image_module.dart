import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui show instantiateImageCodec, Codec;

import 'package:async/async.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// 操作取消异常类
class CancelationException implements Exception {
  final String message;
  CancelationException([this.message = '']);

  @override
  String toString() {
    return 'CancelationException:$message';
  }
}

/// 丢弃异常
class DiscardedException implements Exception {
  final String message;
  DiscardedException([this.message = '']);

  @override
  String toString() {
    return 'DiscardedException:$message';
  }
}

/// 图像模型中代表某一图像资源并包含相关加载信息的key对象
/// 子类必须重载 == 操作符和 hashCode 属性
/// 所有子类必须是@immutable的
@immutable
class RobustImageKey {
  RobustImageKey(this.sourceKey, this.renderKey);
  RobustImageKey.source(this.sourceKey) : renderKey = sourceKey;

  /// 标识源图像资源的key，通常用于磁盘缓存和源获取
  final String sourceKey;

  /// 标识适合用于渲染的图像资源的key，通常用于内存和磁盘缓存
  final String renderKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RobustImageKey &&
          runtimeType == other.runtimeType &&
          sourceKey == other.sourceKey &&
          renderKey == other.renderKey;

  @override
  int get hashCode => hashValues(sourceKey, renderKey);
}

/// 加载的数据表示对象
/// 由于模型中的各种loader可能不必直接加载如整个图像文件的二进制数据到内存，
/// 仅最终用于图像decode显示时才需要，所以加载的结果使用BinaryData来表示。
/// 例如[RobustImageEngine]加载图像时，从模型中的[SourceFetcher]获取到
/// [BinaryData]派生对象，表示在源站中的数据(可能已经获取到本地)，然后引擎
/// 调用模型中的[DiskCache]缓存该数据。
/// 从缓存读取时，[DiskCache]可以返回一个文件数据流对象或者甚至只返回一个
/// 包含[File]的文件的BinaryData派生类，引擎转而调用[ImageRender]的
/// buildRenderImage方法产生转换后的用于渲染的数据(同样时BinaryData类型)，
/// 然后引擎再次使用模型中的[DiskCache]派生类将结果写入缓存，最后引擎把数据
/// 返回给[ImageRender]用于decode成最终的图像并展现。
///
abstract class BinaryData {
  Future<Uint8List> toBytes();
}

class Uint8ListData implements BinaryData {
  /// 如果明确传递的为Uint8ListData对象，可以直接访问该字段
  final Uint8List data;
  const Uint8ListData(this.data);

  @override
  Future<Uint8List> toBytes() {
    return Future.value(data);
  }
}

enum CacheLevel { source, render }

enum CacheFit { renderOnly, sourceOnly, any }

/// 本地磁盘缓存管理对象
abstract class DiskCache {
  /// 加载已缓存的图像数据
  Future<BinaryData> load(RobustImageKey key, CacheFit fitVal);

  /// 缓存图像数据到本地存储
  Future<void> store(
      RobustImageKey key, BinaryData binaryData, CacheLevel level);

  /// 删除指定的本地缓存图像
  Future<void> delete(RobustImageKey key, [CacheFit fitVal = CacheFit.any]);

  /// 清除无效的缓存
  Future<void> clearInvalid();

  /// 清空所有缓存
  Future<void> clear();
}

class FileDiskCache implements DiskCache {
  final Directory cacheDir;
  FileDiskCache(this.cacheDir);

  /// 通过fileKey定位到在本地磁盘的具体位置
  @protected
  FutureOr<File> resolvePath(String fileKey) {
    String md5Key = md5.convert(utf8.encode(fileKey)).toString();
    return File(p.join(cacheDir.path, md5Key));
  }

  Future<BinaryData> load(RobustImageKey key, CacheFit fitVal) async {
    bool useRender = fitVal == CacheFit.any || fitVal == CacheFit.renderOnly;
    bool useSource = fitVal == CacheFit.any || fitVal == CacheFit.sourceOnly;
    Future<BinaryData> doLoad(String fileKey) async {
      final result = resolvePath(fileKey);
      File cacheFlie;
      if (result is Future) {
        cacheFlie = await result;
      } else {
        cacheFlie = result;
      }
      if (await cacheDir.exists()) {
        if (await cacheFlie.exists()) {
          final data = await cacheFlie.readAsBytes();
          if (data != null) {
            return Uint8ListData(data);
          }
        }
      }
      return null;
    }

    if (useRender) {
      final data = doLoad(key.renderKey);
      if (data != null) return data;
    }
    if (useSource) {
      final data = doLoad(key.sourceKey);
      return data;
    }
    return null;
  }

  Future<void> store(
      RobustImageKey key, BinaryData binaryData, CacheLevel level) async {
    final result = resolvePath(
        (level == CacheLevel.source) ? key.sourceKey : key.renderKey);
    File cacheFlie;
    if (result is Future) {
      cacheFlie = await result;
    } else {
      cacheFlie = result;
    }
    if (!(await cacheDir.exists())) {
      // Create cache directory first.
      await cacheDir.create(recursive: true);
    }
    Uint8List data = await binaryData?.toBytes();
    if (data != null) await cacheFlie.writeAsBytes(data);
  }

  Future<void> delete(RobustImageKey key,
      [CacheFit fitVal = CacheFit.any]) async {
    bool deleteRender = fitVal == CacheFit.any || fitVal == CacheFit.renderOnly;
    bool deleteSource = fitVal == CacheFit.any || fitVal == CacheFit.sourceOnly;
    Future<void> doDelete(String fileKey) async {
      final result = resolvePath(fileKey);
      File cacheFlie;
      if (result is Future) {
        cacheFlie = await result;
      } else {
        cacheFlie = result;
      }
      await cacheFlie.delete();
    }

    if (deleteRender) await doDelete(key.renderKey);
    if (deleteSource) await doDelete(key.sourceKey);
  }

  Future<void> clearInvalid() async {
    // We don't know what is invalid, do nothing.
  }

  Future<void> clear() async {
    await cacheDir.list()?.forEach((entity) async {
      await entity.delete();
    });
  }
}

/// 源文件获取处理对象
abstract class SourceFetcher {
  /// 从指定的源key获取图像数据
  /// 源数据可能位于服务端或本地磁盘中，子类通过实现该方法处理具体的获取数据逻辑。
  /// @param key 源图像资源的key
  CancelableOperation<BinaryData> fetch(RobustImageKey key);
}

/// Don't use this class in product, test only!
class RemoteHttpFetcher implements SourceFetcher {
  static final HttpClient _httpClient = HttpClient();
  final Duration timeout;
  RemoteHttpFetcher({this.timeout});

  FutureOr<String> resolveUrl(RobustImageKey key) {
    return key.sourceKey;
  }

  CancelableOperation<BinaryData> fetch(RobustImageKey key) {
    final completer = CancelableCompleter<BinaryData>();
    void requestBody(CancelableCompleter<BinaryData> completer) async {
      try {
        String url;
        final result = resolveUrl(key);
        if (result is Future) {
          url = await result;
        } else {
          url = result;
        }
        // Test only
//        await Future.delayed(Duration(seconds: 2), () {});
//        Future<Response> res = _httpClient.get(url);
//        if (timeout != null) {
//          res = res.timeout(timeout);
//        }
//        Response response = await res;

        final HttpClientRequest request =
            await _httpClient.getUrl(Uri.parse(url));
//        headers?.forEach((String name, String value) {
//          request.headers.add(name, value);
//        });
        final HttpClientResponse response =
            await request.close().timeout(Duration(seconds: 30));
        if (response.statusCode != HttpStatus.ok)
          throw Exception(
              'HTTP request failed, statusCode: ${response?.statusCode}, $url');

        final Uint8List bytes =
            await consolidateHttpClientResponseBytes(response);
        if (bytes.lengthInBytes == 0)
          throw Exception('NetworkImage is an empty file: $url');
        if (!completer.isCompleted) {
          completer.complete(Uint8ListData(bytes));
        }

//        completer.complete(Uint8ListData(response?.bodyBytes));
      } catch (e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      }
    }

    requestBody(completer);
    return completer.operation;
  }
}

typedef ActiveChangeCallback = void Function(
    ImageRender renderTarget, bool active);

class _ActiveImageStreamCompleter extends MultiFrameImageStreamCompleter {
  _ActiveImageStreamCompleter({
    @required this.renderTarget,
    @required Future<ui.Codec> codec,
    @required double scale,
    InformationCollector informationCollector,
  }) : super(
            codec: codec,
            scale: scale,
            informationCollector: informationCollector);
  bool completed = false;
  final ImageRender renderTarget;
  dynamic lastError;
  @override
  void addListener(ImageStreamListener listener) {
    if (!hasListeners) {
//      print(
//          '=======> AddListener listener:${listener.hashCode} request:${request?.key?.renderKey} isCompleted:${completer.isCompleted}');
      if (!completed) {
        // Make it active so we can load other active(should be visible)
        // images first.
        renderTarget._onActiveChange(true);
      } else {
        debugPrint('The loading is ended, we will not call active any more');
      }
    }
    super.addListener(listener);
  }

  @override
  void removeListener(ImageStreamListener listener) {
    bool hasBefore = hasListeners;
    super.removeListener(listener);
    if (!hasListeners && hasBefore) {
//      print(
//          '=======> RemoveListener listener:${listener.hashCode} request:${request?.key?.renderKey} isCompleted:${completer.isCompleted}');
      if (!completed) {
        // Make it inactive so we can load other active(should be visible)
        // images first.
        renderTarget._onActiveChange(false);
      } else {
        debugPrint('The loading is ended, we will not call inactive any more');
      }
    }
  }

  @override
  void reportError(
      {DiagnosticsNode context,
      dynamic exception,
      StackTrace stack,
      InformationCollector informationCollector,
      bool silent = false}) {
    lastError = exception;
    completed = true;
    super.reportError(
        context: context,
        exception: exception,
        informationCollector: informationCollector,
        silent: silent);
  }

  @override
  void setImage(ImageInfo image) {
    completed = true;
    assert(lastError == null);
    if (image != null) {
      lastError = null;
    }
    super.setImage(image);
  }
}

/// 图像渲染目标对象
class ImageRender {
  final ImageConfiguration configuration;

  /// @param key 图像资源标识对象
  final RobustImageKey key;
  ImageStreamListener _imageStreamListener;
  ImageStreamCompleter _imageStreamCompleter;
  ImageRender(this.key, this.configuration);
  List<ActiveChangeCallback> _callbackList = [];

  /// 实例化用于解码图像数据的Codec
  Future<ui.Codec> instantiateImageCodec(BinaryData binaryData) async {
    return ui.instantiateImageCodec(await binaryData.toBytes());
  }

  /// 构建用于渲染的图像数据
  /// 如果用于渲染的图像和源数据相同，可以直接返回sourceData
  Future<BinaryData> buildRenderImage(BinaryData sourceData) async {
    return sourceData;
  }

  /// 获取缩放比例
  @protected
  double getScale() {
    return 1.0;
  }

  /// 渲染已获取的图像数据
  /// 图像数据通过loadData方法提供
  /// @param loadData 获取图像数据的函数对象
  /// @return [ImageStreamCompleter]对象，不能为null
  ImageStreamCompleter render(Future<ui.Codec> loadData()) {
    if (_imageStreamCompleter != null) {
      throw CancelationException('ImageStreamCompleter already exist.');
    }
    _imageStreamCompleter = MultiFrameImageStreamCompleter(
        codec: loadData().whenComplete(() {
//                print('<<<<<<<<<<<< I got you.>>>>>>>>>>>>>');

          // Since ImageStreamCompleter will report any error
          // as the unhandled exception if there isn't listener.
          // We don't want the app crashing that way, so we add
          // one for this case.
          // Why we just add listener after error is because
          // ImageStreamCompleter may make some optimal work
          // based on whether there is subscriber.
          void onsuccess(ImageInfo info, bool synccall) {
            // When we get the callback, no more use.
            _imageStreamCompleter?.removeListener(_imageStreamListener);
            // This is important. because the completer instance
            // may reference a large image which causes OOM
            _imageStreamCompleter = null;
            _imageStreamListener = null;
          }

          void onfailed(dynamic e, StackTrace st) {
            // When we get the callback, no more use.
            _imageStreamCompleter?.removeListener(_imageStreamListener);
            // This is important. because the completer instance
            // may reference a large image which causes OOM
            _imageStreamCompleter = null;
            _imageStreamListener = null;
          }

          // Now we should add the onsuccess and onfailed as the listener,
          // because we may be called back soon.
          _imageStreamListener =
              ImageStreamListener(onsuccess, onError: onfailed);
          _imageStreamCompleter?.addListener(_imageStreamListener);
        }),
        scale: getScale(),
        informationCollector: () {
          return [
            DiagnosticsNode.message('Image render: $this, Image key: $key')
          ];
        });
    if (_imageStreamCompleter == null) {
      // Is this possible?
      throw Exception(
          'We expect the imageStreamCompleter is not null, but not true.');
    }
    return _imageStreamCompleter;
  }

  bool addActiveCallback(ActiveChangeCallback callback) {
    if (!_callbackList.contains(callback)) {
      _callbackList.add(callback);
      return true;
    } else {
      return false;
    }
  }

  bool removeActiveCallback(ActiveChangeCallback callback) {
    return _callbackList.remove(callback);
  }

  void _onActiveChange(bool active) {
    if (_callbackList.isEmpty) return;
    final localCallbacks = _callbackList.toList(growable: false);
    try {
      localCallbacks.forEach((cb) => cb(this, active));
    } catch (e) {
      print(e);
    }
  }
}

/// 图像加载模型
/// 该模型包含所有特定图像领域相关的加载对象，包括key的定义，以及以key为代表的图像资源
/// 如何获取，如何缓存等的处理器集合。但于key相关的渲染器[ImageRender]由于与加载的目标
/// 要求相关，因此在[RenderRequest]中提供。
class RobustImageModule {
  final ImageCache imageCache;
  final DiskCache diskCache;
  final SourceFetcher sourceFetcher;

  RobustImageModule({
    ImageCache imageCache,
    DiskCache diskCache,
    SourceFetcher sourceFetcher,
  })  : imageCache = imageCache,
        diskCache = diskCache,
        sourceFetcher = sourceFetcher,
        assert(
            imageCache != null || diskCache != null || sourceFetcher != null);
}
