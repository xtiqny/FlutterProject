import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cn21base/cn21base.dart';
import 'package:meta/meta.dart';
import 'package:restfulapi/restfulapi.dart';

part 'my_restful_api.restapi.dart';

@RestApi()
abstract class MyRestfulService extends RestfulApiService {
  MyRestfulService(RestfulAgent agent) : super(agent);

  @Get(
      path: "http://www.test.nouse/sayHello", headers: {"X-request-id": "1234"})
  CancelableFuture<String> sayHello(@Query("msg") String message, int size,
      {@required String extra, @Header("X-key") String key = "abc"});

  @Post(path: "/sayHi")
  CancelableFuture<Future<int>> sayHi(@Query("msg") String message,
      [int size = 0, String extra = "yes", String info]);

  @Post(path: "/sayGoodBye")
  CancelableFuture<void> sayGoodBye(
      {@Field("ex") String extra, @Field() String key = "abc"});

  @Put(path: "/saySomething/{to}", headers: {"Date": "2019-7-1"})
  CancelableFuture<Uint8List> saySomething(@Path('to') String friend,
      @Body() int content, @Header("X-requestId") String requestId,
      [@OnCancel() OnCancelRequest onCancelRequest]);

  MyRestfulService factory(RestfulAgent agent) {
    return MyRestfulServiceImpl(agent);
  }
}
