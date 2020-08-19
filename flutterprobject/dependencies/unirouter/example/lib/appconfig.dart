import 'package:flutter/material.dart';
import 'package:unirouter/unirouter.dart';
import 'package:unirouter/unirouter_plugin.dart';
import 'package:unirouter_example/flutterdemo.dart';
import 'package:unirouter_example/fragmentdemo.dart';

class ApplicationConfig {
  static final ApplicationConfig _singleton = new ApplicationConfig._internal();
  static ApplicationConfig sharedInstance() {
    return _singleton;
  }

  void init() {
    UniRouter.instance
        .setRouteWidgetHandler(({RouteAction routeAction, Key key}) {
      if (routeAction.url.startsWith("fltfrag://fragdemo")) {
        return FragmentDemoWidget(key: key);
      } else {
        return FlutterDemoWidget(key: key);
      }
    });
  }

  ApplicationConfig._internal();
}
