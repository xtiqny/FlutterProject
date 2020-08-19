import 'dart:async';

import 'package:meta/meta.dart';

/// 业务组件基础类
abstract class BusinessComponent {
  final String _componentName;
  bool _isInitialized = false;

  /// 构造方法
  /// @param _componentName 业务组件名称
  BusinessComponent(this._componentName);

  /// 组件初始化方法
  /// 初始化完成前，各项行为和属性访问处于未知状态。
  /// 即使初始化后，应用也可以多次调用该方法，此时将
  /// 直接返回已完成的状态。调用者也可以进行await
  /// 等待初始化完成。
  FutureOr<void> init() {
    markInitialized(true);
    return null;
  }

  /// 销毁组件
  FutureOr<void> destroy() {
    markInitialized(false);
    return null;
  }

  /// 设置初始化的完成状态
  @protected
  markInitialized(bool done) => _isInitialized = done;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 组件名称
  String get componentName => _componentName;
}
