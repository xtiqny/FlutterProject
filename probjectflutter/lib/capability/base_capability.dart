import 'dart:ui';

///
/// APM 应用数据采集能力接口
///
abstract class APM {
  /// 崩溃信息报告
  void reportCrashException(String message, String stackTrace);

  /// 添加云涛事件上报
  void insertUxAction(String key);
}

///
/// 系统UI操作能力接口
///
abstract class SystemUICapability {
  /// 设置系统标题栏的明暗
  void setSystemStatusBarBrightness(Brightness brightness);
}
