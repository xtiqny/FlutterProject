import 'dart:io';
import 'dart:ui';
import 'values/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

/// 应用的主题对象
/// 一般而言该对象只用于顶级Widget（MaterialApp）的build方法中，
/// 用于指定整个应用级别的主题，在其子Widget中如果需要访问某些样式
/// 或修改部分样式，不应直接使用 kAppTheme，而应该使用
/// Theme.of(context) 的方式访问。
class ThemeProvider {
  static ThemeProvider _ins = ThemeProvider();
  static ThemeProvider ins() => _ins;

  ThemeMode _themeMode = ThemeMode.light;

  /// 获取当前主题
  ThemeMode getThemeMode() => _themeMode;

  final PublishSubject<bool> _themeUpdate = PublishSubject<bool>();

  /// 主题变更监听器
  Observable<bool> getObservable() => _themeUpdate;

  /// 皮肤变更,由Host设置
  void setTheme(ThemeMode themeMode) {
    _themeMode = themeMode;
    _themeUpdate.add(true);
  }

  ThemeData getTheme({bool isDarkMode: false}) {
    /// 基础文本样式，用于merge到应用的文本主题中。
    /// iOS特别处理，以便文本存在CJK编码的字符时，系统用默认
    /// 字体（西文字体）找不到对应字符时可以从fallback中查找
    final kBaseTextStyle = Platform.isIOS
        ? TextStyle(fontFamilyFallback: ["PingFang SC", "Heiti SC"])
        : TextStyle();

    /// 基础文本主题对象
    final kBaseTextTheme = TextTheme(
        headline: kBaseTextStyle,
        overline: kBaseTextStyle,
        caption: kBaseTextStyle,
        body1: kBaseTextStyle,
        body2: kBaseTextStyle,
        title: kBaseTextStyle,

        /// 输入框的文本颜色
        subhead: kBaseTextStyle.copyWith(
            color: isDarkMode ? Colors.white : Colors.black),
        subtitle: kBaseTextStyle,
        display1: kBaseTextStyle,
        display2: kBaseTextStyle,
        display3: kBaseTextStyle,
        display4: kBaseTextStyle,
        button: kBaseTextStyle);

    ThemeData theme = ThemeData(
      textTheme: kBaseTextTheme,
      primaryTextTheme: kBaseTextTheme,
      accentTextTheme: kBaseTextTheme,

      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      primaryColor: isDarkMode ? Colors.black : Colors.white,

      /// 页面背景色
      scaffoldBackgroundColor: isDarkMode ? Colors.black : Colors.white,

      /// 滑动条样式（音乐播放）
      sliderTheme: buildSliderTheme(isDarkMode: isDarkMode),

      /// TabBar indicatorColor
      indicatorColor: isDarkMode ? Color(0xFF1F95FF) : Color(0xFF3B86F3),

      /// 通用弹框背景
      dialogBackgroundColor: isDarkMode ? Color(0xFF1C1C1E) : Colors.white,

      /// 分隔线的颜色
      dividerColor:
          isDarkMode ? DarkColor().listDivider : CustomColor().listDivider,

      /// 输入框的光标颜色
      cursorColor: isDarkMode ? Color(0xFF0087FF) : Color(0xFF1F95FF),
    );
    return theme;

//    return ThemeData(
//        errorColor: isDarkMode ? Colours.dark_red : Colours.red,
//        brightness: isDarkMode ? Brightness.dark : Brightness.light,
//        primaryColor: isDarkMode ? Colours.dark_app_main : Colours.app_main,
//        accentColor: isDarkMode ? Colours.dark_app_main : Colours.app_main,
//        // Tab指示器颜色
//        indicatorColor: isDarkMode ? Colours.dark_app_main : Colours.app_main,
//        // 页面背景色
//        scaffoldBackgroundColor:
//            isDarkMode ? Colours.dark_bg_color : Colors.white,
//        // 主要用于Material背景色
//        canvasColor: isDarkMode ? Colours.dark_material_bg : Colors.white,
//        // 文字选择色（输入框复制粘贴菜单）
//        textSelectionColor: Colours.app_main.withAlpha(70),
//        textSelectionHandleColor: Colours.app_main,
//        textTheme: TextTheme(
//          // TextField输入文字颜色
//          subhead: isDarkMode ? TextStyles.textDark : TextStyles.text,
//          // Text文字样式
//          body1: isDarkMode ? TextStyles.textDark : TextStyles.text,
//          subtitle:
//              isDarkMode ? TextStyles.textDarkGray12 : TextStyles.textGray12,
//        ),
//        inputDecorationTheme: InputDecorationTheme(
//          hintStyle:
//              isDarkMode ? TextStyles.textHint14 : TextStyles.textDarkGray14,
//        ),
//        appBarTheme: AppBarTheme(
//          elevation: 0.0,
//          color: isDarkMode ? Colours.dark_bg_color : Colors.white,
//          brightness: isDarkMode ? Brightness.dark : Brightness.light,
//        ),
//        dividerTheme: DividerThemeData(
//            color: isDarkMode ? Colours.dark_line : Colours.line,
//            space: 0.6,
//            thickness: 0.6),
//        cupertinoOverrideTheme: CupertinoThemeData(
//          brightness: isDarkMode ? Brightness.dark : Brightness.light,
//        ));
  }

  /// 生成全局SliderTheme
  SliderThemeData buildSliderTheme({bool isDarkMode: false}) {
    return new SliderThemeData(
      activeTrackColor: isDarkMode ? Color(0xFF45A7FF) : Color(0xff70A0FE),
      inactiveTrackColor: isDarkMode ? Color(0xFF878C96) : Color(0xffd1d1d1),
    );
  }
}
