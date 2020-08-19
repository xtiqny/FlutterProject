import 'dart:io' show Platform;

import 'package:flutter/material.dart';

/// 应用的主题对象
/// 一般而言该对象只用于顶级Widget（MaterialApp）的build方法中，
/// 用于指定整个应用级别的主题，在其子Widget中如果需要访问某些样式
/// 或修改部分样式，不应直接使用 kAppTheme，而应该使用
/// Theme.of(context) 的方式访问。
final ThemeData kAppTheme = _createAppTheme();

/// 创建应用主题对象
ThemeData _createAppTheme() {
  // 修改该方法中的 ThemeData 构造参数以自定义主题
  ThemeData th = ThemeData(
    primaryColor: Colors.blue,
    textTheme: kBaseTextTheme,
    primaryTextTheme: kBaseTextTheme,
    accentTextTheme: kBaseTextTheme,
  );
  return th;
}

/// 基础文本样式，用于merge到应用的文本主题中。
/// iOS特别处理，以便文本存在CJK编码的字符时，系统用默认
/// 字体（西文字体）找不到对应字符时可以从fallback中查找
final kBaseTextStyle = Platform.isIOS
    ? TextStyle(fontFamilyFallback: ["PingFang SC", "Heiti SC", ".SF UI Text"])
    : null;

/// 基础文本主题对象
final kBaseTextTheme = TextTheme(
    headline: kBaseTextStyle,
    overline: kBaseTextStyle,
    caption: kBaseTextStyle,
    body1: kBaseTextStyle,
    body2: kBaseTextStyle,
    title: kBaseTextStyle,
    subhead: kBaseTextStyle,
    subtitle: kBaseTextStyle,
    display1: kBaseTextStyle,
    display2: kBaseTextStyle,
    display3: kBaseTextStyle,
    display4: kBaseTextStyle,
    button: kBaseTextStyle);
