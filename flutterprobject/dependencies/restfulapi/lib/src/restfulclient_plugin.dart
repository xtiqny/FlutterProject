import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cn21base/cn21base.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

import "policy.dart";
import "restful_base.dart";

class RestfulClientPlugin {
  static const String TAG = "HttpClientPluginImpl";
  static MethodChannel _httpPlugin;

  /// 递增的请求id
  static int sAutoIncRequestId = 100;

  BodyChannelReceiver bodyChannelReceiver = BodyChannelReceiver();

  RestfulClientPlugin() {
    init();
  }

  static init() {
    _httpPlugin =
        const MethodChannel('com.cn21.network.restfulapi/RestfulClientPlugin');
  }

  Future<int> create(PolicyContextView context) async {
    try {
      int clientId = await _httpPlugin.invokeMethod('create', context.getAll());
      return clientId;
    } on Exception catch (e) {
      BaseLog.w(TAG, ": create $e");
    }
    return null;
  }

  void close(int clientId) async {
    try {
      await _httpPlugin.invokeMethod('close', clientId);
    } on Exception catch (e) {
      BaseLog.w(TAG, ": cancelRequest $e");
    }
  }

  Future<Response> execute(int clientId, Request req) async {
    final int requestId = ++sAutoIncRequestId;
    Map headers = {};
    req.headers?.forEach((name, values) {
      headers[name] = values[0];
    });

    Map arguments = {
      'clientId': clientId,
      'requestId': requestId,
      'method': req.method,
      'url': req.url.toString(),
      'headers': headers,
      'body': req.body?.toBytes(),
    };

    // 开始监听此请求的回复
    bodyChannelReceiver.startListenResponse(clientId, requestId);

    MyHttpResponse naRes;
    try {
      Map result = await _httpPlugin.invokeMethod('execute', arguments);
//      BaseLog.w(TAG, ": execute result: $result");
      naRes = MyHttpResponse.fromMap(result);
    } on Exception catch (e) {
      BaseLog.w(TAG, ": execute $e");
    }

    if (naRes != null) {
      // 原生返回了异常，继续抛出
      if (naRes.excpetion != null) {
        bodyChannelReceiver.stopListen(clientId, requestId);
        throw HttpException("${naRes.excpetion} ${naRes.exceptionMsg}");
      }

      /// 构造Response对象
      HttpBody body;
      if (naRes.body != null) {
        bodyChannelReceiver.stopListen(clientId, requestId);
        Uint8List bytes = Uint8List.fromList(naRes.body);
        body = HttpBody.fromBytes(
          'application/string',
          bytes,
          bytes.length,
        );
      } else if (naRes.bodyBinaryLength != null) {
        /// 如果是通过流形式来读取body，需要在些进行监听和接收
        Stream<Uint8List> stream =
            bodyChannelReceiver.consumeBody(clientId, requestId);
//        BaseLog.i(TAG, "consumeBody from receiver: streaming");
        body = HttpBody("application/string", stream);
      }
      HttpHeaders httpHeaders = HttpHeaders();
      naRes.headers?.forEach((name, value) {
        httpHeaders.add(name, value);
      });
      return Response(req, naRes.statusCode,
          reasonPhrase: naRes.statusMsg, headers: httpHeaders, body: body);
    } else {
      bodyChannelReceiver.stopListen(clientId, requestId);
    }
    return null;
  }

  int getLastRequestId() {
    return sAutoIncRequestId;
  }

  void cancelRequest(int clientId, int requestId) async {
    Map arguments = {'clientId': clientId, 'requestId': requestId};
    try {
      await _httpPlugin.invokeMethod('cancelRequest', arguments);
    } on Exception catch (e) {
      BaseLog.w(TAG, ": cancelRequest $e");
    }
  }

  /// 使用BasicChannel发送body内容给原生
//  void _sendRequestBodyByChannel(int clientId, int requestId, HttpBody body) {
//    if (body != null) {
//      String channelName =
//          "com.cn21.ecloud/HttpClient_${clientId}_Request_${requestId}";
//      BasicMessageChannel<ByteData> bodyChannel =
//          BasicMessageChannel(channelName, BinaryCodec());
//
//      if (body.isAllBuffered) {
//        Uint8List bytes = body.toBytes();
//        ByteData data = ByteData.view(bytes.buffer, )
//        bodyChannel.send(message)
//      } else {}
//    }
//  }
}

/// Body二进制数据接收器
class BodyChannelReceiver {
  static const TAG = "BodyChannelReceiver";
  Map<String, BasicMessageChannel<ByteData>> mBodyChannels = {};
  Map<String, StreamController<Uint8List>> mBodyCompleters = {};

  /// 开始监听body结果
  void startListenResponse(int clientId, int requestId) {
    String channelName = buildChannelName(clientId, requestId);

    /// 因为stream的listener监听有先有后，为了保证所有的listener都接收到全部的数据，
    /// 需要使用ReplaySubject
    StreamController<Uint8List> controller = ReplaySubject<Uint8List>();
    mBodyCompleters[channelName] = controller;

    int recieveCount = 0;
    BasicMessageChannel<ByteData> bodyChannel =
        BasicMessageChannel(channelName, BinaryCodec());
    bodyChannel.setMessageHandler((ByteData byteData) {
      if (byteData != null) {
//        BaseLog.d(
//            TAG, "$channelName receive byte: ${byteData.buffer.lengthInBytes}");
        recieveCount += byteData.buffer.lengthInBytes;
        controller.add(byteData.buffer.asUint8List());
      } else {
//        BaseLog.d(TAG,
//            "$channelName receive byte: null. Channel Completed. totalCount: $recieveCount");

        /// 接收到null对象，说明已接收完成，
        controller.close();

        /// 取消监听此消息Channel
        bodyChannel.setMessageHandler(null);
      }
      return null;
    });

    mBodyChannels[channelName] = bodyChannel;
//    BaseLog.d(TAG, "startListenResponse $channelName started.");
  }

  /// 消费body内容,在body接收完成数据流会自动取消监听
  Stream<Uint8List> consumeBody(int clientId, int requestId) {
//    BaseLog.d(TAG, "consumeBody clientId: $clientId, requestId: $requestId");
    String channelName = buildChannelName(clientId, requestId);
    StreamController<Uint8List> controller = mBodyCompleters[channelName];
    if (controller != null) {
      /// 删除此对象的引用
      mBodyChannels[channelName] = null;
      mBodyCompleters[channelName] = null;
      return controller.stream;
    } else {
      return null;
    }
  }

  /// 取消监听
  void stopListen(int clientId, int requestId) {
//    BaseLog.d(TAG, "stopListen clientId: $clientId, requestId: $requestId");
    String channelName = buildChannelName(clientId, requestId);
    BasicMessageChannel<ByteData> channel = mBodyChannels[channelName];
    channel?.setMessageHandler(null);

    StreamController<Uint8List> controller = mBodyCompleters[channelName];
    controller?.close();

    mBodyChannels[channelName] = null;
    mBodyCompleters[channelName] = null;
  }

  String buildChannelName(int clientId, int requestId) {
    return "com.cn21.ecloud/HttpClient_${clientId}_Response_${requestId}";
  }
}

/// 解析Native传递回来的Response
class MyHttpResponse {
  int statusCode;
  String statusMsg;
  Map headers;
  Uint8List body;
  int bodyBinaryLength;

  /// *可选*内容的编号，通过调用onMessageHandler去接收二进制数据(当bodyBinaryLength>0时有效)
  /// [可选]如果有异常如TimeoutException, IOException, CancelException
  String excpetion;

  /// [可选]异常具体信息
  String exceptionMsg;

  MyHttpResponse.fromMap(map) {
    statusCode = map['statusCode'];
    statusMsg = map['statusMsg'];
    headers = map['headers'];
    body = map['body'];

    bodyBinaryLength = map['bodyBinaryLength'];
    excpetion = map['excpetion'];
    exceptionMsg = map['exceptionMsg'];
  }
}
