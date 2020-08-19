import 'dart:async';

import 'package:flutter/services.dart';

class Cn21base {
  static const MethodChannel _channel =
      const MethodChannel('cn21base');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
