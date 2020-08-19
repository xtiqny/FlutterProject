import 'dart:ui';

import 'package:flutter/services.dart';

import '../capability/base_capability.dart';
import '../capability/impl/base_capability_impl.dart';

class AppInjector {
  static const TAG = "AppInjector";
  static const int USE_PLUGIN_IMPL = 0;
  static const int USE_MOCK_IMPL = 1;
}

class _SystemUICapabilityFlutter implements SystemUICapability {
  static final instance = _SystemUICapabilityFlutter();
  @override
  void setSystemStatusBarBrightness(Brightness brightness) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarBrightness: brightness));
  }
}

APM apm = APMNative.instance;
// You may use SystemUICapability
SystemUICapability sysui = _SystemUICapabilityFlutter.instance;
