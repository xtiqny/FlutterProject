import 'dart:async';
import 'dart:io';

import '../../app/app_injector.dart';

import '../values/colors.dart';
//import 'package:cn21base/cn21base.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:unirouter/unirouter_plugin.dart';
import 'package:flutterprobject/utils/log.dart';

// 有状态的Page基类
abstract class BasePageStatefulWidget extends StatefulWidget {
  final String instanceKey;
  final Map params;
  BasePageStatefulWidget(this.instanceKey, this.params);

//  // 判断当前Page是否是在顶部显示的Page
//  bool isTopPage() {
//    String topInstanceKey = AppNavObserver.get().getTopPageInstanceKey();
//    return topInstanceKey == instanceKey;
//  }
}

// 有状态的Page的State基类，监听Page生命周期
abstract class BasePageState<T extends StatefulWidget> extends State<T> {
  static const TAG = "BasePageState";
  String instanceKey;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;
  String _connectionStatus = 'Unknown';
  Color _statusBarColor = skinColor().commonPageBg; // Colors.white;
  Brightness _brightness = Brightness.light;
  BasePageState(this.instanceKey);
  PageState _pageState;

  @override
  void initState() {
    super.initState();
    String pageName = T.toString();
    Log.i(pageName, " initState");
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.mobile) {
        onNetworkChange(true);
      } else if (result == ConnectivityResult.wifi) {
        //TODO wifi状态下可能未认证，待处理
        onNetworkChange(true);
      } else {
        onNetworkChange(false);
      }
    });

    _brightness = lightStatusBarBrightness(_statusBarColor);
  }

  @override
  void dispose() {
    String pageName = T.toString();
    Log.i(pageName, "dispose");
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _handlePageLifecycleStateChange(PageState state) {
    PageState oldState = _pageState;
    _pageState = state;
    handlePageLifecycleStateChange(state);
    if (oldState != _pageState && _pageState == PageState.appeared) {
      _showSystemStatusBarBrightness();
    }
  }

  void handlePageLifecycleStateChange(PageState state) {
    debugPrint('${T.toString()} handlePageLifecycleStateChange: state=$state');
  }

  void _showSystemStatusBarBrightness() {
    // FIXME: 当前由于Flutter Boost的问题，导致AppBar无法设置标题栏字体深浅，暂时
    // 用原生的方式设置
    if ((_pageState == PageState.init || _pageState == PageState.appeared)) {
      Log.d(TAG,
          "setSystemStatusBarBrightness color=$_statusBarColor brightness=$_brightness");
      // 由于iOS在页面A切换到B时可能出现B的appeared先出现，并设置状态栏深浅，
      // 然后再到A的disappear出现，继而触发A的build，并且重新设置状态栏深浅
      // 导致最终状态栏的深浅取决于A而非B，因此这里再次判断A是否当前页面。
      if (UniRouter.instance.isTopRoute(context, containerOnly: true)) {
        // 系统状态栏明暗模式设置
        Log.d(TAG, "===========================> brightness=$_brightness");
        sysui.setSystemStatusBarBrightness(_brightness);
      }
    }
  }

  Color getSystemStatusBarColor() {
    return _statusBarColor ?? skinColor().commonPageBg;
  }

  @override
  Widget build(BuildContext context) {
    // 获取当前页面系统状态栏颜色
    Color statusBarColor = getSystemStatusBarColor();
    // 更新当前页面系统状态栏文字颜色
    _brightness = lightStatusBarBrightness(statusBarColor);
//    WidgetsBinding.instance.addPostFrameCallback((_) {
//      if (mounted) _showSystemStatusBarBrightness();
//    });
    return UniPageLifecycle(
      pageStateCallback: _handlePageLifecycleStateChange,
      child: Scaffold(
        appBar: PreferredSize(
          child: AppBar(
            elevation: 0.0,
            backgroundColor: statusBarColor,
            brightness: _brightness,
          ),
          preferredSize: Size(double.infinity, 0),
        ),
        body: FixedScaleTextWidget(
            child: Stack(
          children: <Widget>[
            createPageBody(),
            createDecorView(),
          ],
        )),
        backgroundColor: getPageBackgroundColor(),
        floatingActionButton: createFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      ),
    );
  }

  Widget createPageBody() {
    return Center(
      child: Text("todo"),
    );
  }

  /// 放在body的上层，用于显示全局的动画
  Widget createDecorView() {
    return Container();
  }

  Widget createFloatingActionButton() {
    return null;
  }

  /// 获取页面的背景颜色
  Color getPageBackgroundColor() {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  ///更改状态栏颜色。如不设置默认跟 commonPageBg 相同
  void setStatusBarColor(Color barColor, {bool adjustBrightness = true}) {
    if (barColor != null) {
      // 更新状态栏颜色。
      _statusBarColor = barColor;
      if (adjustBrightness) {
        _brightness = lightStatusBarBrightness(_statusBarColor);
      }
      setState(() {});
    }
  }

  //状态栏颜色是不是亮色
  static Brightness lightStatusBarBrightness(Color color) {
    return color.computeLuminance() >= 0.5 ? Brightness.light : Brightness.dark;
  }

  ///接收网络状态变化处理
  void onNetworkChange(bool isAvailable) {
    Log.i("BaseState", 'is network Available==$isAvailable');
  }
}

class FixedScaleTextWidget extends StatelessWidget {
  final double scale;
  final Widget child;

  const FixedScaleTextWidget({
    Key key,
    this.scale = 1.0,
    @required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    return MediaQuery(
      data: data.copyWith(textScaleFactor: scale),
//      child: SafeArea(child: child),
      child: child,
    );
  }
}
