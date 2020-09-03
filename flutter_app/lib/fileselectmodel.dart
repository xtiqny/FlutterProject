import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:developer';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'fileselectmodel.dart';

class FileSelectModle
{
  String title;
  String iconPath;
}

class FileSelectFinlect
{
  static String NATIVE_CHANNEL_NAME = "com.cc.flutter.fileselect"; //给native发消息，此处应和客户端名称保持一致
  //channel_name每一个通信通道的唯一标识，在整个项目内唯一！！！
  var _channel =  MethodChannel(NATIVE_CHANNEL_NAME);

  ///
  /// @Params:
  /// @Desc: 获取native的数据
  ///
  Future<dynamic>getNativeData(key,[ dynamic arguments ]) async{
    try {
      String resultValue = await _channel.invokeMethod(key, arguments);
      return resultValue;
    }on PlatformException catch (e){
      print(e.toString());
      return "";
    }
  }

  registerMethod(){
    //接收处理原生消息
    _channel.setMethodCallHandler((handler) {
      switch (handler.method) {
        case "aaa":
        // 发送原生消息
          _channel.invokeMethod("toast", {"msg": "您调用了dart里的方法"});
          break;
      }
    });
  }
}


class IosUtils
{
  static final IosUtils _managerIos = IosUtils.internal();
  StreamController<dynamic> deviceController;
  Stream deviceStream;

  EventChannel _eventChannel = const EventChannel("ios_event_channel");
  final _channel = MethodChannel("ios_channel");

  factory IosUtils.getInstance() {
    return _managerIos;
  }
  IosUtils.internal() {
    deviceController = StreamController();
    deviceStream = deviceController.stream.asBroadcastStream();

    _eventChannel
        .receiveBroadcastStream("init")
        .listen(_onEvent, onError: _onError);
  }

  void _onEvent(Object event) {
    Map map = event;
    print("--------------map:${map}");
    //添加监听
    deviceController.sink.add(map);
  }

  void _onError(Object error){
    print("--------------error:${error}");
  }

  void getWifiName(){
    _channel.invokeMethod('get_wifi_name');
  }
}