import '../common/skin_manager.dart';
import '../values/skin_res.dart';
import 'package:flutter/material.dart';

/// 支持换肤，since 8.6.0
/// 获取当前使用的皮肤颜色
/// 使用示例： skinColor().mainTitleBg
CustomColor skinColor() {
  return SkinColor.getSkinColor();
}

/// 指定普通模式的颜色,仅用于当前传输页面暂不适配黑暗模式
CustomColor normalColor() {
  return SkinColor.getNormalColor();
}

/// 转换支持换肤的asset图片，since 8.6.0
String sk(String imageFileName) {
  return SkinRes.get().skinRes(imageFileName);
}

/// 普通模式的颜色
class CustomColor {
  final Color commonPageBg = Colors.white;

  final Color mainTitleBg = Colors.white;
  final Color mainTitleColor = Colors.black;
  final Color mainTitleSubtitleColor = Color(0xFFAFB4BE);
  final Color mainTitleTransferMsgtv = Colors.white;

  final Color commonFileItemBg = Colors.white;
  final Color commonFileNameColor = Color(0xFF323746);
  final Color commonFileNameSubColor = Color(0xffAFB4BE);
  final Color commonFileGridNameColor = Color(0xFF2C2C2C);
  final Color commonFileBottomBarBg = Color(0xFF0087FF);

  final Color devTitleColor = Colors.black;
  final Color devBottomTextColor = Colors.black;

  final Color bottomMenuBg = Color(0xFFFFFFFF);
  final Color bottomMenuGroupBg = Color(0xFFF5F5FA);
  final Color bottomMenuNormalText = Color(0xFF323746);
  final Color bottomMenuSelectText = Color(0xFF0087FF);
  final Color bottomMenuDisableText = Color(0xFFAFB4BE);
  final Color bottomMenuFileName = Color(0xFF2c2c2c);
  final Color bottomMenuFileSubinfo = Color(0xFF888888);
  final Color bottomPopMenuText = Color(0xff8F8E94);

  final Color listDivider = Color(0xFFdee1e4);
  final Color inputDivider = Color(0xFFc4c4c4);
}

/// 黑暗模式（深色模式）的颜色
/// 可继承修改默认的颜色,注意名称要一致
class DarkColor extends CustomColor {
  @override
  final Color commonPageBg = Color(0xFF000000); // 0xFF090C1B
  @override
  final Color mainTitleBg = Color(0xFF000000);
  @override
  final Color mainTitleColor = Colors.white;
  @override
  final Color mainTitleSubtitleColor = Color(0xFF878C96);

  final Color commonFileItemBg = Colors.transparent;
  final Color commonFileNameColor = Color(0xFFEFEFF4);
  final Color commonFileNameSubColor = Color(0xff878C96);
  final Color commonFileGridNameColor = Color(0xFFEFEFF4);
  final Color commonFileBottomBarBg = Color(0xFF1F95FF);

  @override
  final Color devTitleColor = Colors.white;
  @override
  final Color devBottomTextColor = Colors.white;

  @override
  final Color bottomMenuBg = Color(0xFF1C1C1E);
  @override
  final Color bottomMenuGroupBg = Color(0xFF1F1F1F);
  @override
  final Color bottomMenuNormalText = Color(0xFFEFEFF4);
  @override
  final Color bottomMenuSelectText = Color(0xFF1F95FF);
  @override
  final Color bottomMenuFileName = Color(0xFFEFEFF4);
  @override
  final Color bottomMenuFileSubinfo = Color(0xFF878C96);
  @override
  final Color bottomPopMenuText = Color(0xFFEFEFF4);
  @override
  final Color listDivider = Color(0xFF38383A);
  final Color inputDivider = Color(0xCC4E4E52);
}

/// 支持按皮肤设置返回对应颜色集合
class SkinColor {
  static CustomColor normalColor = CustomColor();
  static DarkColor darkColor = DarkColor();
  static CustomColor getSkinColor() {
    /// 根据当前的皮肤配置返回指定的颜色集合
    switch (SkinManager.get().getCurrentSkin()) {
      case SkinType.normal:
        return normalColor;
        break;
      case SkinType.dark:
        return darkColor;
        break;
    }

    /// 找不到定义的皮肤，返回默认的皮肤
    return normalColor;
  }

  /// 指定使用普通模式的皮肤
  static CustomColor getNormalColor() {
    return normalColor;
  }
}
