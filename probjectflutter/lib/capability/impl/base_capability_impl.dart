import 'dart:ui';

import '../base_capability.dart';
import 'package:cn21base/cn21base_flutter.dart';

class APMNative implements APM {
  static final instance = APMNative._();

  MethodChannelEx _channelEx = MethodChannelEx("apm_capability_ch");
  APMNative._();

  @override
  void insertUxAction(String key) {
    if (key != null && key.isNotEmpty)
      _channelEx.invokeMethod("insertUxAction", key);
  }

  @override
  void reportCrashException(String message, String stackTrace) {
    if (message != null && message.isNotEmpty)
      _channelEx
          .invokeMethod("reportCrashException", [message, stackTrace ?? ""]);
  }
}

class SystemUICapabilityNative implements SystemUICapability {
  static final instance = SystemUICapabilityNative._();
  MethodChannelEx _channelEx = MethodChannelEx("sysui_capability_ch");

  SystemUICapabilityNative._();

  @override
  void setSystemStatusBarBrightness(Brightness brightness) {
    _channelEx.invokeMethod(
        "setSystemStatusBarBrightness", brightness == Brightness.light);
  }
}
