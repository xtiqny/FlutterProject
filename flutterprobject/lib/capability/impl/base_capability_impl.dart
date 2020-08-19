import 'dart:ui';

import '../base_capability.dart';
//import 'package:cn21base/cn21base_flutter.dart';

class APMNative implements APM {
  static final instance = APMNative._();

 // MethodChannelEx _channelEx = MethodChannelEx("apm_capability_ch");
  APMNative._();

  @override
  void insertUxAction(String key) {

  }

  @override
  void reportCrashException(String message, String stackTrace) {

}


