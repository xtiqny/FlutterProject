import 'package:flutter/material.dart';
import '../ui/pages/dummy_page.dart';
import 'package:unirouter/unirouter.dart';
import 'package:unirouter/unirouter_plugin.dart';

class AppRouterConfig {
  static final AppRouterConfig _singleton = new AppRouterConfig._internal();
  static final GlobalKey gHomeItemPageWidgetKey =
      new GlobalKey(debugLabel: "[KWLM]");
  static AppRouterConfig sharedInstance() {
    return _singleton;
  }

  void init() {
    UniRouter.instance
      ..setRouteWidgetHandler((
          {RouteAction routeAction, Key key, BuildContext context}) {
        // TODO: return a widget
        print(
            "On router to flutter page: ${routeAction.url}, key:${routeAction.instanceKey}");
        if (routeAction.url == "/dummy_page") {
          return DummyPage(routeAction.instanceKey, routeAction.params);
        } else if (routeAction.url == "/dummy_page2") {
          return DummyPage2(routeAction.instanceKey, routeAction.params);
        }
        return Container(
          child: Text(
              "Unknow page:${routeAction.url}, instanceKey:${routeAction.instanceKey}"),
        );
      });
  }

  AppRouterConfig._internal();
}
