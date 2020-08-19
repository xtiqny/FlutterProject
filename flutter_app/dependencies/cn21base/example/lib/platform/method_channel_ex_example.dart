import 'dart:async';
import 'dart:typed_data';

import 'package:cn21base/cn21base_flutter.dart';
import 'package:flutter/services.dart';

class MyData {
  final String name;
  final String idNO;
  final String address;
  final int age;
  final int sex;
  final int height;
  final int weight;
  final String avatarImagePath;
  final String phoneNO;
  final String corp;
  final String nature;
  final DateTime birthDay;

  MyData(
      {this.name,
      this.idNO,
      this.address,
      this.age,
      this.sex,
      this.height,
      this.weight,
      this.avatarImagePath,
      this.phoneNO,
      this.corp,
      this.nature,
      this.birthDay});

  MyData.fromList(List<dynamic> list)
      : name = list[0],
        idNO = list[1],
        address = list[2],
        age = list[3],
        sex = list[4],
        height = list[5],
        weight = list[6],
        avatarImagePath = list[7],
        phoneNO = list[8],
        corp = list[9],
        nature = list[10],
        birthDay = DateTime.fromMillisecondsSinceEpoch(list[11]);

  MyData.fromMap(Map map)
      : name = map['name'],
        idNO = map['idNO'],
        address = map['address'],
        age = map['age'],
        sex = map['sex'],
        height = map['height'],
        weight = map['weight'],
        avatarImagePath = map['avatarImagePath'],
        phoneNO = map['phoneNO'],
        corp = map['corp'],
        nature = map['nature'],
        birthDay = DateTime.fromMillisecondsSinceEpoch(map['birthDay']);
}

List<MyData> _decodeMyDataFromMap(dynamic list) {
  List<MyData> datas = List<MyData>.generate(
      list.length, (index) => MyData.fromMap(list[index]));
  return datas;
}

// 将data（假设为List<List<dynamic>>）转换为List<MyData>
// 其中List<List<dynamic>>中每个元素都是一个sublist，每个sublist
// 都是MyData实例编码后生成，通过MyData的fromList类方法可以
// 通过sublist构造出MyData实例
FutureOr<dynamic> _convertToObject(dynamic data) {
  final List list = data;
  return list.map((sublist) => MyData.fromList(sublist)).toList();
}

void _decodeMyDataStreamFromList(ByteData data, Sink sink) {
  final codec = StandardMethodCodec();
  final List<dynamic> list = codec.decodeEnvelope(data);
  int offset = 0;
  void scheduleSinkData() {
    Future.delayed(Duration(milliseconds: 16), () {
      if (offset < list.length) {
        int len = 10000;
        if (offset + len > list.length) len = list.length - offset;
        List<MyData> datas = List<MyData>.generate(
            len, (index) => MyData.fromList(list[offset + index]));
        sink.add(datas);
        offset += len;
        scheduleSinkData();
      } else {
        sink.close();
      }
    });
  }

//  scheduleSinkData();

  while (offset < list.length) {
    int len = 10000;
    if (offset + len > list.length) len = list.length - offset;
    List<MyData> datas = List<MyData>.generate(
        len, (index) => MyData.fromList(list[offset + index]));
    sink.add(datas);
    offset += len;
  }
  sink.close();
}

List<MyData> _decodeData(ByteData data) {
  print('Start to decode data.');
  final codec = StandardMessageCodec();
  List<dynamic> result = codec.decodeMessage(data);
  print('decodeMessage done.');
  final d = List<MyData>.generate(
      result.length, (index) => MyData.fromList(result[index]));
  print('decode data done.');
  return d;
}

class MethodChannelExExample {
  MethodChannelEx _channel;
  static MethodChannelExExample _instance;
  ByteData _flutterData;
  List<List> _dataList;
  IsolateService _isolateService;

  static Future<String> get platformVersion async {
    final String version =
        await instance._channel.invokeMethod('getPlatformVersion');
    return version;
  }

  List<List> _generateFlutterData() {
    int now = DateTime.now().millisecondsSinceEpoch;
    final list = List.generate(
        100001,
        (index) => <dynamic>[]
          ..add("Person$index")
          ..add("PersonId_$index")
          ..add(
              "room 201, Some Building, Some Dist, Some City, Some Province, China")
          ..add(20)
          ..add(1)
          ..add(180)
          ..add(60)
          ..add("/sdcard/album/camera/img_00000001.jpg")
          ..add("18900000000")
          ..add("Some corp limited")
          ..add("China")
          ..add(now));
    return list;
  }

  Future<List<MyData>> getDataFromList() async {
    print('call getDataFromList from flutter');
    final datas = await _channel.invokeListMethodAndConvert<MyData>(
        'getDataFromList', _convertToObject);
    print('getDataFromList decoded, length=${datas.length}');
    return datas;
  }

  Future<List<MyData>> getDataFromListStream() async {
    print('call getDataFromListStream from flutter');
    final datas = await _channel.invokeListMethodAndConvert<MyData>(
        'getDataFromListStream', _convertToObject);
    print('getDataFromListStream decoded, length=${datas.length}');
    return datas;
//    final datas = await _channel.invokeMethodAndDecodeStream(
//        'getDataFromList', _decodeMyDataStreamFromList);
//    final result = <MyData>[];
//    await for (final list in datas) {
//      result.addAll(list);
//    }
//    print('getDataFromListStream decoded, length=${result.length}');
//    return result;
  }

  Future<List<MyData>> getDataFromMap() async {
    print('call getDataFromMap from flutter');
    final list = await _channel.invokeListMethod<Map>('getDataFromMap');
    print('getDataFromMap returns');
    List<MyData> datas = List<MyData>.generate(
        list.length, (index) => MyData.fromMap(list[index]));
//    final datas = await _channel.invokeMethodAndDecode(
//        'getDataFromMap', _decodeMyDataFromMap);
    print('getDataFromMap decoded, length=${datas.length}');
    return datas;
  }

  Future<List<MyData>> getDataFromFlutter() async {
    print('call getDataFromFlutter from flutter');
    List<MyData> datas =
        await _isolateService.execute(_decodeData, _flutterData);
    print('getDataFromFlutter decoded, length=${datas.length}');
    return datas;
  }

  void getDataFromFlutterToNative() async {
    print('call getDataFromFlutterToNative from flutter');
    await _channel.invokeMethod('getDataFromFlutterToNative');
  }

  static MethodChannelExExample get instance {
    if (_instance == null) {
      _instance = MethodChannelExExample();
      _instance._isolateService = IsolateService()..initService();
      _instance._dataList = _instance._generateFlutterData();
      final codec = StandardMessageCodec();
      _instance._flutterData = codec.encodeMessage(_instance._dataList);

      final SplitListIteratorHandler handler =
          (List list, MethodCall refMethodCall) {
        // 仅当结果列表元素总数超过2000时才进行分割
        if (list.length > 2000) {
          // 返回一个分批的Iterable迭代器
          return () sync* {
            int index = 0;
            int total = list.length;
            while (index < total) {
              int remain = total - index;
              int subsize = (remain < 2000) ? remain : 2000;
              // 最多每2000个元素产生一个sub-list
              yield list.getRange(index, index + subsize).toList();
              index += subsize;
            }
          }();
        }
        // 无需分批
        return null;
      };

      _instance._channel = MethodChannelEx('MethodChannelExExample',
          methodChannelScheduler: MyUselessScheduler(_instance
              ._isolateService), //IsolateScheduler(_instance._isolateService),
          splitListIteratorHandler: handler);
      _instance._channel.setMethodCallHandler((methodCall) async {
        if (methodCall.method == 'getDataFromListStream') {
          return _instance._dataList;
        }
        return null;
      });
    }
    return _instance;
  }
}

// 以下仅是简单的调度器，仅用于示例说明，请不要在实际工程中无脑使用！
class MyUselessScheduler extends IsolateScheduler {
  MyUselessScheduler(IsolateService isolateService) : super(isolateService);

  @override
  schedulerForDecode<Q, R>(
      ByteData data, MethodCall refMethodCall, bool caller) {
    if (data.lengthInBytes > 512 * 1024) {
      // 仅当数据大小超过512K时，才通过isolate调度解码
      return super.schedulerForDecode<Q, R>(data, refMethodCall, caller);
    } else {
      // 不需要调度
      return null;
    }
  }

  @override
  schedulerForEncode<T, Q>(T data, MethodCall refMethodCall, bool caller) {
    if (caller &&
        data != null &&
        data is MethodCall &&
        refMethodCall != null &&
        refMethodCall.method == "someFunction") {
      final List largeData = refMethodCall.arguments[0];
      if (largeData.length > 1000) {
        // 仅当目标函数为someFunction，其中参数是列表且元素数量过大
        // 时才使用isolate进行调度编码
        return super.schedulerForEncode<T, Q>(data, refMethodCall, caller);
      }
    }
    // 不需要调度
    return null;
  }
}
