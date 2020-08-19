import '../theme_provider.dart';
import 'package:cn21base/cn21base.dart';
import 'package:flutter/material.dart';

/// 支持换肤,可扩展
enum SkinType {
  /// 普通模式
  normal,

  /// 黑暗模式（深色模式）
  dark,
}

/// 皮肤管理器。
/// 对接主工程需要实现两个对接调用：BasePluginImpl.getSkinType
/// BasePluginImpl.init -> updateSkinType
class SkinManager {
  static const TAG = "SkinManager";
  static SkinManager ins = SkinManager();
  static SkinManager get() => ins;

  SkinType _currentSkin = SkinType.normal;

  SkinManager() {
    // AppInjector会首次查询设置当前皮肤
//    PreferencesUtil.getCurrentSkinType().then((res) {
//      Log.i(TAG, "getCurrentSkinType:$res");
//      setSkinByHost(res);
//    });
  }

  /// 获取当前使用的皮肤类型
  SkinType getCurrentSkin() {
    return _currentSkin;
  }

  /// 修改当前皮肤，需要保存到Preferences
  void setCurrentSkin(SkinType skinType, {bool savePref: false}) {
    Log.i(TAG, "setCurrentSkin:$skinType");
    _currentSkin = skinType;
    ThemeProvider.ins()
        .setTheme(skinType == SkinType.dark ? ThemeMode.dark : ThemeMode.light);

    if (savePref) {
      // TODO: Save preference.
      // PreferencesUtil.setCurrentSkinType(skinType.index);
    }
  }

  /// 由宿主App设定皮肤:0普通，1黑暗
  void setSkinByHost(int skinType) {
    if (skinType == 0) {
      setCurrentSkin(SkinType.normal);
    } else if (skinType == 1) {
      setCurrentSkin(SkinType.dark);
    } else {
      Log.w(TAG, "setSkinByHost unknown skinType: $skinType");
    }
  }
}
