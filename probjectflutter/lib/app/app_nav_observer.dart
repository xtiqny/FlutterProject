import 'package:cn21base/cn21base.dart';
import 'package:flutter/material.dart';

// APP路由监听器
class AppNavObserver extends NavigatorObserver {
  static const String TAG = "AppNavObserver";

  static AppNavObserver _instance = AppNavObserver();

  final List<Route<dynamic>> _history = [];

  static AppNavObserver get() {
    return _instance;
  }

  @override
  void didPop(Route route, Route previousRoute) {
    var removed = _history.remove(route);
    Log.d(TAG,
        'didPop ${route?.settings?.name}, removed:$removed, history:${_history.length}');
    notifyNative();
  }

  @override
  void didPush(Route route, Route previousRoute) {
    _history.add(route);
    Log.d(TAG, 'didPush ${route?.settings?.name}, history:${_history.length}');
    notifyNative();
  }

  @override
  void didRemove(Route route, Route previousRoute) {
    var removed = _history.remove(route);
    Log.d(TAG,
        'didRemove ${route?.settings?.name}, removed:$removed, history:${_history.length}');
    notifyNative();
  }

  @override
  void didReplace({Route newRoute, Route oldRoute}) {
    var index = _history.indexOf(oldRoute);
    if (index >= 0) {
      _history[index] = newRoute;
    }
    Log.d(TAG,
        'didReplace newRoute:${newRoute?.settings?.name}, oldRoute:${oldRoute?.settings?.name}, replaced:${index >= 0}, history:${_history.length}');
    notifyNative();
  }

  @override
  void didStartUserGesture(Route route, Route previousRoute) {
    Log.d(TAG, 'didStartUserGesture');
  }

  @override
  void didStopUserGesture() {
    Log.d(TAG, 'didStopUserGesture');
  }

  void notifyNative() {
    // TODO: Notify native.
  }

  // 获取当前页面的数量
  int getPageCount() {
    return _history.length;
  }

  // 获取顶部弹框的数量
  int getTopDialogCount() {
    int count = 0;
    for (int i = _history.length - 1; i >= 0; --i) {
      Route route = _history[i];
      if (route?.settings?.name == null) {
        ++count;
      }
    }
    return count;
  }
}
