import 'package:unirouter/unirouter_plugin.dart';
import 'package:unirouter_example/appconfig.dart';
import 'package:unirouter_example/demoapp.dart';

//class MyApi {
//  final _channel = MethodChannel("my_api_plugin");
//  static MyApi _instance;
//  static MyApi get instance {
//    if (_instance == null) {
//      _instance = MyApi._();
//    }
//    return _instance;
//  }
//
//  void init() {
//    print('Init MyApi');
//  }
//
//  MyApi._() {
//    _channel.setMethodCallHandler((methodCall) async {
//      if (methodCall.method == 'getText') {
//        print('=================== Hello world ====================');
//        return 'Hello world';
//      } else {
//        print(
//            '================== Unknown method:${methodCall.method} =================');
//        return null;
//      }
//    });
//  }
//}

void main() async {
  print('-------------------- main() --------------------');
//  MyApi.instance.init();
//  String echo = await MyApi.instance._channel.invokeMethod('getEcho');
//  print('=============> I get echo:$echo');
  ApplicationConfig.sharedInstance().init();
  UniRouter.instance.init((startArgs) async {
    print('=========> Start route with args:$startArgs');
    return UniRouteDemoApp();
  });
}
