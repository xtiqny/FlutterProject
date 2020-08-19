import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_boost/flutter_boost.dart';

typedef Widget FlutterWidgetHandler({RouteAction routeAction, Key key});
typedef Future<Widget> PrepareApp(dynamic args);

/// 路由的UI处理后的返回结果
/// done: 完成/取消
/// notSupported: 不支持返回值（当为此状态时，不代表路由的UI界面已关闭）
enum RouteResultState { done, notSupported }

/// 路由UI处理结果类
class UniRouteResult {
  UniRouteResult(this.resultState, {this.result});

  /// [RouteResultState]结果状态
  final RouteResultState resultState;

  /// 返回的结果，仅当resultState为done时result有效
  final Map<String, dynamic> result;
}

const String kInstanceKeyField = "instanceKey";
const String kUrlField = "url";
const String kParamsField = "params";
const String kExtIsAnimated = "animated";

const String kResultState = "resultState";
const String kResult = "result";

enum RouteFlag { over, clearBottom, replace }

class RouteAction {
  RouteAction(this.url, {this.instanceKey, this.params, this.ext});

  final String url;
  final String instanceKey;
  final dynamic params;
  final Map ext;
}

/// 应用统一路由器(Flutter端)
/// 该类与Native(Android,iOS)端的UniRouter配合，实现
/// 应用内部Native与Native、Native与Flutter及Flutter
/// 与Flutter间的页面导航。
class UniRouter {
  static final UniRouter _instance = UniRouter._();

  static UniRouter get instance => _instance;
  FlutterWidgetHandler _routerWidgetHandler;
  bool _isReady = false;
  bool _started = false;
  dynamic _startArgs;
  Completer<bool> _startRouteCompleter;

  /// Native 端是否已经准备好
  bool get isReady => _isReady;
  final _methodChannel = MethodChannel('unirouter_manager');

  UniRouter._();

  /// 初始化并运行app
  /// 该初始化方法将确保等待Native端初始化好必要的
  /// 数据或逻辑后，收到Native端发送ready信号并在
  /// 此后运行传入的prepareApp对象。应用可以在prepareApp
  /// 中执行runApp等操作，并返回整个界面逻辑的app widget。
  /// [Unirouter]会自行对widget进行封装并运行runApp
  FutureOr<bool> init(PrepareApp prepareApp) async {
    WidgetsFlutterBinding.ensureInitialized();
    _methodChannel.setMethodCallHandler((call) {
      debugPrint('method: ${call.method}');
      if (call.method == 'startRoute') {
        // Native side starts the routing, we should
        // return a signal to notify when we have done.
        if (_started) {
          debugPrint('Received startRoute request, already done.');
          return Future.value(true);
        } else {
          debugPrint('Received startRoute request, but not done yet.');
          assert(_startRouteCompleter == null);
          _startRouteCompleter = Completer<bool>();
          return _startRouteCompleter.future;
        }
      } else {
        return null;
      }
    });
    if (_isReady) {
      _runOnReady(prepareApp);
      return true;
    } else {
      _startArgs = await _methodChannel.invokeMethod('waitForReady');
      print('Native says ready!');
      _isReady = true;
      _runOnReady(prepareApp);
      return true;
    }
  }

  void _runOnReady(PrepareApp prepareApp) async {
    print('Prepare app');
    Widget app = await prepareApp?.call(_startArgs);
    // Notify that we have done.
    _started = true;
    _startRouteCompleter?.complete(true);
    _startRouteCompleter = null;
    if (app != null) {
      runApp(_UniRouterApp(
        child: app,
      ));
    } else {
      debugPrint("No app for runApp.");
    }
  }

  /// 获取导航界面切换时的builder对象
  /// 应用在构建[WidgetsApp]([MaterialApp],[CupertinoApp])时传递
  /// 此方法返回的[TransitionBuilder]对象到 builder 参数中，且无需
  /// 初始化routes,initialRoute,onGenerateRoute,onUnknownRoute参数。
  /// 例如：
  /// @override
  ///  Widget build(BuildContext context) {
  ///    return new MaterialApp(
  ///      title: 'Unirouter Demo',
  ///      theme: kAppTheme,
  ///      builder: UniRouter.getBuilder(),
  ///      home: Container(
  ///      ),
  ///    );
  ///  }
  ///}
  ///
  static TransitionBuilder getBuilder([TransitionBuilder builder]) {
    return FlutterBoost.init(builder: builder);
  }

  /// 设置导航路由最终的Widget Builder处理器
  /// 处理器需要负责根据传入的[RouteAction]对象构建并返回
  /// 相应的[Widget]对象。返回的[Widget]及其所有层级下的节点
  /// 都可以通过 UniRouter.instance.routeOf(context) 获取到
  /// 对应的[RouteAction]对象。
  void setRouteWidgetHandler(FlutterWidgetHandler handler) {
    _routerWidgetHandler = handler;
    FlutterBoost.singleton.registerDefaultPageBuilder(
        (String pageName, Map containerParams, String uniqueId) {
      final Map params = {};
      final Map ext = {};
      containerParams?.forEach((key, val) {
        if (key is String && key.startsWith('_ext_')) {
          // remove '_ext_' prefix and store it to ext.
          ext[key.substring(5)] = val;
        } else {
          params[key] = val;
        }
      });
      final action = RouteAction(pageName,
          instanceKey: uniqueId,
          params: params,
          ext: ext.isNotEmpty ? null : ext);
      Widget widget = _routerWidgetHandler?.call(routeAction: action);
      return _UniRouteContainer(
        action: action,
        child: widget,
      );
    });
  }

  /// 添加后退按键的监听处理器
  /// @return 监听的句柄对象，用于[removeBackPressedListener]中取消监听
  dynamic addBackPressedListener(BuildContext context, void onBackPressed()) {
//    return BoostContainer.of(context)?.addBackPressedListener(onBackPressed);
    BoostContainerState containerState = BoostContainer.of(context);
    if (containerState == null || !containerState.mounted) {
      return null;
    }
    final Function orgBackPress = containerState.backPressedHandler;
    containerState.backPressedHandler = onBackPressed;
    return () {
      assert(containerState.backPressedHandler == onBackPressed);
      if (onBackPressed != null &&
          containerState.backPressedHandler == onBackPressed) {
        containerState.backPressedHandler = orgBackPress;
      }
    };
  }

  /// 取消后退按键的监听处理器
  /// @param handle [addBackPressedListener]返回的句柄对象
  bool removeBackPressedListener(dynamic handle) {
    if (handle is Function) {
      handle();
      return true;
    } else {
      return false;
    }
  }

  /// 获取当前界面的[RouteAction]路由信息
  /// 当前界面必须通过setRouteWidgetHandler构建，
  /// 所有层次下的节点均可调用该方法获取[RouteAction]
  RouteAction routeOf(BuildContext context) {
    _UniRouteContainer container =
        (context.inheritFromWidgetOfExactType(_typeOf<_UniRouteContainer>())
            as _UniRouteContainer);
    return container?.routeAction;
  }

  /// 获取当前最顶层界面的[RouteAction]路由信息
  /// 最顶层界面仅相对于Flutter端而言，不包含Native端
  RouteAction getTopRoute(BuildContext context) {
    final container = BoostContainerManager.of(context)?.onstageContainer;
    if (container != null) {
      final Map params = {};
      final Map ext = {};
      container.params?.forEach((key, val) {
        if (key is String && key.startsWith('_ext_')) {
          // remove '_ext_' prefix and store it to ext.
          ext[key.substring(5)] = val;
        } else {
          params[key] = val;
        }
      });
      return RouteAction(container.name,
          instanceKey: container.uniqueId,
          params: params,
          ext: ext.isEmpty ? null : ext);
    } else {
      return null;
    }
  }

  /// 判断当前是否处于最顶层界面
  /// 最顶层界面仅相对于Flutter端而言，不包含Native端
  /// containerOnly为true时，表示仅判断context页面所属的容器
  /// 是否最顶层容器，containerOnly为false时表示除了容器外，
  /// 还要判断context所属的页面是否最顶层页面
  bool isTopRoute(BuildContext context, {bool containerOnly = false}) {
    RouteAction curAction = routeOf(context);
    RouteAction topAction = getTopRoute(context);
    if (curAction == null || topAction == null) {
      return false;
    } else {
      if (curAction.url == topAction.url &&
          curAction.instanceKey == topAction.instanceKey) {
        if (!containerOnly) {
          // 需要判断该页面在Container中是否最顶层
          Route curRoute;
          // 以下只获取最顶层的Route，不会执行pop
          Navigator.of(context)?.popUntil((route) {
            if (curRoute == null) curRoute = route;
            return true;
          });
          return (curRoute == null || curRoute == ModalRoute.of(context));
        } else {
          return true;
        }
      } else {
        return false;
      }
    }
  }

  /// 导航到指定的页面。
  /// 其中url用于定位目标页面，但最终是否导航到该url页面，
  /// 还取决于期间的resolver的处理。
  /// 如果返回null，代表跳转的界面不支持返回结果（并不代表界面已经关闭），
  /// 否则返回相应的结果
  Future<Map<String, dynamic>> push(String url,
      {String instanceKey, Map params, Map ext}) async {
//    Map containerParams = {};
    Map query = params ?? {};
//    containerParams["query"] = query;
    query[kInstanceKeyField] = instanceKey;
//    ext?.forEach((key, val) {
//      query["_ext_$key"] = val;
//    });
    final r =
        await FlutterBoost.singleton.open(url, urlParams: query, exts: ext);
//    UniRouteResult routeResult;
//    RouteResultState state = RouteResultState.notSupported;
//    if (r != null) {
//      try {
//        int index = r["resultState"];
//        state = RouteResultState.values[index];
//      } catch (e) {
//        debugPrint("$e");
//      }
//    }
//    routeResult = UniRouteResult(state, result: r);
//    return routeResult;
    return r?.cast<String, dynamic>();
  }

  /// 关闭当前的顶层页面。
  Future<dynamic> pop({Map<String, dynamic> result}) {
    return FlutterBoost.singleton.closeCurrent(result: result);
  }

  /// 关闭指定的页面。
  Future<dynamic> close(String url, String instanceKey,
      {bool animated = true, Map<String, dynamic> result}) {
    return FlutterBoost.singleton.close(instanceKey, result: result);
  }
}

Type _typeOf<T>() => T;

class _UniRouteContainer extends InheritedWidget {
  final RouteAction _routeAction;

  RouteAction get routeAction => _routeAction;

  const _UniRouteContainer({Key key, RouteAction action, Widget child})
      : assert(action != null),
        _routeAction = action,
        super(key: key, child: child);

  static RouteAction routeOf(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(_typeOf<_UniRouteContainer>())
            as _UniRouteContainer)
        ?.routeAction;
  }

  @override
  bool updateShouldNotify(_UniRouteContainer oldWidget) {
    return (oldWidget._routeAction != _routeAction);
  }
}

class _UniRouterApp extends StatefulWidget {
  final Widget child;

  const _UniRouterApp({Key key, this.child}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _UniRouterAppState();
}

class _UniRouterAppState extends State<_UniRouterApp> {
  @override
  void initState() {
    super.initState();
    print('=============> Process OnStart');
//    FlutterBoost.handleOnStartPage();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// 页面生命周期状态
enum PageState { init, appeared, disappeared, disposed }

/// 页面生命周期状态回调函数
typedef PageStateCallback = void Function(PageState state);

/// 页面生命周期回调管理Widget
/// 该 Widget 将自动依次根据App应用生命周期[AppLifecycleState]、
/// 通过[UniRouter]路由构建的容器的可见性以及[UniPageLifecycle]
/// 在最近父级[Navigator]中的可见性(是否顶层Route)回调对应的[PageState]。
/// 其中 init，disposed 只可能依次分别出现1次，appeared, disappeared
/// 可能出现多次，但会成对出现。即出现 appeared 后必然有 disappeared 相对应。
/// init -> [appeared -> disappeared]* -> disposed
/// [UniPageLifecycle] 的child 应该在 disappeared 中终止所有用户交互的
/// 相关请求，并在 appeared 时恢复。
/// 相应的周期状态改变将通过 pageStateCallback 函数回调
class UniPageLifecycle extends StatefulWidget {
  final PageStateCallback pageStateCallback;
  final Widget child;

  UniPageLifecycle({Key key, this.child, this.pageStateCallback})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return UniPageLifecycleState();
  }
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final Function _callback;

  _AppLifecycleObserver(void callback(AppLifecycleState state))
      : _callback = callback;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _callback(state);
  }
}

enum _NavState { appeared, disappeared }

class _PageNavObserver extends NavigatorObserver {
  final UniPageLifecycleState pageLifecycleState;

  _PageNavObserver(this.pageLifecycleState) : super();

  void _removeUntil(List<Route> routes, Route r, [bool addIfEmpty = true]) {
    if (r == null) {
      routes.clear();
      return;
    }
    int index = routes.lastIndexOf(r);
    if (index < 0) {
      routes.clear();
      if (addIfEmpty) {
        routes.add(r);
      }
    } else {
      routes.removeRange(index + 1, routes.length);
    }
  }

  @override
  void didPop(Route route, Route previousRoute) {
//    print(
//        '========> didPop route=${route.settings?.name} prev=${previousRoute.settings?.name}');
    final list = pageLifecycleState._upperRoutes;
    _removeUntil(list,
        previousRoute == pageLifecycleState._route ? null : previousRoute);
    assert(!list.contains(route));
    pageLifecycleState._handleNavigatorCallback();
  }

  @override
  void didPush(Route route, Route previousRoute) {
//    print(
//        '========> didPush route=${route.settings?.name} prev=${previousRoute.settings?.name}');
    final list = pageLifecycleState._upperRoutes;
    _removeUntil(list,
        previousRoute == pageLifecycleState._route ? null : previousRoute);
    list.add(route);
    pageLifecycleState._handleNavigatorCallback();
  }

  @override
  void didRemove(Route route, Route previousRoute) {
//    print(
//        '========> didRemove route=${route.settings?.name} prev=${previousRoute.settings?.name}');
    if (pageLifecycleState._route != route) {
      final list = pageLifecycleState._upperRoutes;
      list.remove(route);
      pageLifecycleState._handleNavigatorCallback();
    }
  }

  @override
  void didReplace({Route newRoute, Route oldRoute}) {
//    print(
//        '========> didReplace route=${newRoute.settings?.name} prev=${oldRoute.settings?.name}');
    if (pageLifecycleState._route != oldRoute) {
      final list = pageLifecycleState._upperRoutes;
      int index = list.indexOf(oldRoute);
      if (index >= 0) {
        list[index] = newRoute;
      }
      pageLifecycleState._handleNavigatorCallback();
    }
  }
}

class UniPageLifecycleState extends State<UniPageLifecycle> {
  /// 应用级别生命周期状态
  AppLifecycleState _appState;

  /// 容器级别生命周期状态
  ContainerLifeCycle _containerState;

  /// Navigator级别生命周期状态
  _NavState _navState;

  /// 页面当前的生命周期状态
  PageState _curPageState;
  _AppLifecycleObserver _appLifecycleObs;
  VoidCallback _containerLifecycleUnregisterFunc;
  bool _isInitialized = false;

  /// 当前页面对应的[Route]路由
  Route _route;

  /// 当前_route路由之上的[Route]列表
  final List<Route> _upperRoutes = [];
  BoostContainerSettings _settings;
  ContainerManagerState _containerManagerState;
  _PageNavObserver _pageNavObserver;

  /// 页面当前的生命周期状态
  PageState get curPageState => _curPageState;

  void _checkAndReinstallNavObserver() {
    if (_pageNavObserver != null) {
      // When this happens, it should be the case that the [NavigatorState]'s
      // didUpdateWidget has been invoked, we should install the observer again.
      final observers = _route?.navigator?.widget?.observers;
      if (observers != null && !observers.contains(_pageNavObserver)) {
        observers.add(_pageNavObserver);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void initState() {
    // 将在马上被调用的 [didChangeDependencies] 中进行初始化
    _isInitialized = false;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (!_isInitialized) {
      _isInitialized = true;
      _appState = WidgetsBinding.instance.lifecycleState;
      if (_appState == null) {
        // iOS上会出现此种情况，假定为resumed
        _appState = AppLifecycleState.resumed;
      }
      // 注册应用级别的生命周期监听
      _appLifecycleObs = _AppLifecycleObserver((state) {
        _appState = state;
        _handleStateChange();
      });
      _containerState = ContainerLifeCycle.Appear;
      // 注册容器级别的生命周期监听
      _containerManagerState = BoostContainerManager.of(context);
      _settings = BoostContainer.of(context)?.settings;
      WidgetsBinding.instance.addObserver(_appLifecycleObs);
      _containerLifecycleUnregisterFunc = FlutterBoost.singleton
          .addBoostContainerLifeCycleObserver(
              (ContainerLifeCycle state, BoostContainerSettings settings) {
        ContainerLifeCycle curState = _containerState;
        if (_containerManagerState != null &&
            _settings != null &&
            sameSetting(_settings, settings)) {
          if (sameSetting(_containerManagerState.onstageSettings, _settings)) {
            if (state == ContainerLifeCycle.Appear) {
              curState = ContainerLifeCycle.Appear;
            } else if (state == ContainerLifeCycle.Disappear ||
                state == ContainerLifeCycle.Destroy) {
              curState = ContainerLifeCycle.Disappear;
            } else {
              return;
            }
          } else {
            curState = ContainerLifeCycle.Disappear;
          }
          if (curState != _containerState) {
            _containerState = curState;
            _handleStateChange();
          }
        }
      });

      _route = ModalRoute.of(context);
      assert(_route != null);
      assert(_route.isCurrent);
      _navState = _NavState.appeared;
      // 注册Navigator级别的生命周期监听
      if (_route != null) {
        _pageNavObserver = _PageNavObserver(this);
        _route.navigator?.widget?.observers?.add(_pageNavObserver);
      }
      // 回调一次 init 周期
      _curPageState = PageState.init;
      widget.pageStateCallback?.call(_curPageState);
      // 将马上回调 appeared 周期
      _handleStateChange();
    } else {
      _checkAndReinstallNavObserver();
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    if (_curPageState == PageState.appeared) {
      // We want to make appeared/disappeared have the same callback count
      _curPageState = PageState.disappeared;
      widget.pageStateCallback?.call(_curPageState);
    }
    // 回调一次 disposed 周期
    _curPageState = PageState.disposed;
    widget.pageStateCallback?.call(_curPageState);
    // 取消应用级别的生命周期监听
    if (_appLifecycleObs != null) {
      WidgetsBinding.instance.removeObserver(_appLifecycleObs);
      _appLifecycleObs = null;
    }
    // 取消容器级别的生命周期监听
    _containerLifecycleUnregisterFunc?.call();
    _containerLifecycleUnregisterFunc = null;
    // 取消Navigator级别的生命周期监听
    if (_pageNavObserver != null) {
      _pageNavObserver.navigator?.widget?.observers?.remove(_pageNavObserver);
      _pageNavObserver = null;
    }
    _containerManagerState = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(UniPageLifecycle oldWidget) {
    _checkAndReinstallNavObserver();
    super.didUpdateWidget(oldWidget);
  }

  bool sameSetting(
      BoostContainerSettings first, BoostContainerSettings second) {
    if (first == second) return true;
    if (first != null && second != null) {
      if (first.name == second.name && first.uniqueId == second.uniqueId) {
        return true;
      }
    }
    return false;
  }

  void _handleNavigatorCallback() {
    if (_route != null) {
//      print('route:${_route.settings.name} is current:${_route.isCurrent}');
      _NavState state = _NavState.appeared;
      if (!_route.isActive) {
        state = _NavState.disappeared;
      } else {
        // 要看上层的Route中是否有Popup类型，再决定是否可见
        for (final r in _upperRoutes) {
          if (r is! PopupRoute) {
            state = _NavState.disappeared;
            break;
          }
        }
      }

      if (state != _navState) {
        _navState = state;
        _handleStateChange();
      }
    }
  }

  void _handleStateChange() {
    PageState state = _curPageState;
    if (_curPageState == PageState.disposed) {
      // No more change.
      return;
    }
    if (_curPageState == PageState.init) {
      // Change to appeared at once.
      _curPageState = PageState.appeared;
      widget.pageStateCallback?.call(_curPageState);
    }
    // When goes here, it's clear that we are either
    // in appeared or disappeared state.
    if (_appState == AppLifecycleState.resumed ||
        _appState == AppLifecycleState.inactive) {
      // The app is still on screen
      if (_containerState == ContainerLifeCycle.Appear) {
        // The container is appeared
        if (_navState == _NavState.appeared) {
          // Appeared
          state = PageState.appeared;
        } else {
          // Disappeared
          state = PageState.disappeared;
        }
      } else if (_containerState == ContainerLifeCycle.Disappear) {
        // The container is disappeared
        state = PageState.disappeared;
      }
    } else {
      // The app is not on screen
      state = PageState.disappeared;
    }
    if (state != _curPageState) {
      _curPageState = state;
      widget.pageStateCallback?.call(_curPageState);
    }
  }
}
