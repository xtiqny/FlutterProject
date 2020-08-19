import 'dart:convert';

import '../common/skin_manager.dart';
import 'package:flutter/services.dart';

/// 如何支持图片资源的换肤：
/// 1）在assets/dark_skin目录添加对应在资源文件，名称与普通模式名称相同。
/// 2）在命令行中调用脚本生成资源索引：python make_skin_res.py
/// 3）如果添加了新的assets目录，需要在pubspec.yaml中配置
/// 4）在用到资源的地方使用sk()进行转换，如 sk('assets/images/header_back_normal.png')
///

class SkinRes {
  static SkinRes ins = SkinRes();
  static SkinRes get() => ins;

  /// 黑暗模式在资源映射表
  static Map<String, dynamic> _darkRes;

  /// 加载皮肤资源
  void initLoad() {
    _loadDarkSkin("assets/dark_skin.json");
  }

  /// 加载指定一个皮肤资源
  void _loadDarkSkin(String skinFile) {
    // TODO: Load dark skin file
//    rootBundle.loadString(skinFile).then((res) {
//      Map<String, dynamic> resObject = json.decode(res);
//      _darkRes = resObject;
//    });
  }

  /// 获取当前皮肤对应的图片文件
  String skinRes(String fileName) {
    /// 根据当前的皮肤配置返回指定的颜色集合
    switch (SkinManager.get().getCurrentSkin()) {
      case SkinType.normal:
        return fileName;
        break;

      case SkinType.dark:
        if (_darkRes != null && _darkRes.containsKey(fileName)) {
          return _darkRes[fileName];
        }
        break;
    }

    return fileName;
  }
}
