import 'package:unirouter/unirouter.dart';
import 'package:rxdart/rxdart.dart';
import 'event_bus.dart';

/// 页面生命周期匹配的事件提供者接口。
/// 一般页面中消费某些通过事件总线发出的事件时，页面可能处于
/// 不同的生命周期中，在不合适的生命周期处理可能会导致崩溃等问题
/// 出现。该接口定义了可在指定的生命周期内消费最近发出的事件的
/// [Observable]提供方法。
/// 如果在不匹配的生命周期内收到总线发出的事件时，不会通知[Observable]，
/// 而会首先保留最后一个事件，待生命周期改变和匹配成功后在发送。
/// 使用者在不需要监听事件后必须主动cancel（遵循[Observable]的listen和
/// cancel方式）
/// 示例：
///    // observe for "onCreate" event when page is appeared.
///    final subscription =
///        provider.eventOnAppeared("onCreate").listen((event) => print("$event"));
///    // When not use, just cancel it.
///    subscription?.cancel();
abstract class LifecycleAwareEventProvider {
  /// 获取匹配指定生命周期状态集合及事件ID的可观察实例
  /// @param eventKey 匹配的事件I（non null）
  /// @param lifecycleStates 需要匹配的生命周期集合，如果为null，则表示匹配任意生命周期
  /// @return 匹配的[Observable]实例
  Stream eventOnLifecycle(
      dynamic eventKey, List<PageState> lifecycleStates);

  /// 获取当页面可见时的指定事件ID的可观察实例
  /// @param eventKey 匹配的事件I（non null）
  /// @return 匹配的[Observable]实例
  Stream eventOnAppeared(dynamic eventKey);

  /// 获取当页面不可见时的指定事件ID的可观察实例
  /// @param eventKey 匹配的事件I（non null）
  /// @return 匹配的[Observable]实例
  Stream eventOnDisappeared(dynamic eventKey);

  /// 获取当页面初始化时的指定事件ID的可观察实例
  /// @param eventKey 匹配的事件I（non null）
  /// @return 匹配的[Observable]实例
  Stream eventOnInit(dynamic eventKey);

  /// 获取当页面销毁时的指定事件ID的可观察实例
  /// @param eventKey 匹配的事件I（non null）
  /// @return 匹配的[Observable]实例
  Stream eventOnDisposed(dynamic eventKey);
}

class _Consumer {
  final PublishSubject eventSubject;
  final List lifecycleStates;
  dynamic event;

  _Consumer(this.eventSubject, this.lifecycleStates);

  bool lifecycleMatch(PageState lifecycleState) =>
      lifecycleStates == null || lifecycleStates.contains(lifecycleState);
}

/// 页面生命周期匹配的事件提供者的实现类。
class LifecycleAwareEventManager implements LifecycleAwareEventProvider {
  List<_Consumer> _consumers = [];
  PageState lastState;
  final EventBus _eventBus = EventBus();

  Stream eventOnLifecycle(
      dynamic eventKey, List<PageState> lifecycleStates) {
    PublishSubject subject = PublishSubject();
    final _Consumer _consumer = _Consumer(subject, lifecycleStates);

    void onEventCallback(dynamic event) {
      // 如果生命周期匹配，则发送事件，否则保存此事件，
      // 等[handleLifecycle]时再匹配处理
      if (_consumer.lifecycleMatch(lastState)) {
        _consumer.event = null;
        subject.add(event);
      } else {
        _consumer.event = event;
      }
    }

    subject.onListen = () {
      _eventBus.register(eventKey, onEventCallback);
      _consumers.add(_consumer);
    };
    subject.onCancel = () {
      _eventBus.unRegister(eventKey, onEventCallback);
      _consumers.remove(_consumer);
    };

    return subject;
  }

  Stream eventOnAppeared(dynamic eventKey) {
    return eventOnLifecycle([PageState.appeared], eventKey);
  }

  Stream eventOnDisappeared(dynamic eventKey) {
    return eventOnLifecycle([PageState.disappeared], eventKey);
  }

  Stream eventOnInit(dynamic eventKey) {
    return eventOnLifecycle([PageState.init], eventKey);
  }

  Stream eventOnDisposed(dynamic eventKey) {
    return eventOnLifecycle([PageState.disposed], eventKey);
  }

  /// 处理界面生命周期的改变。当页面容器生命周期发生改变时，
  /// 必须调用该方法以便匹配消费者和发送待发的事件。
  /// @param lifecycleState 页面容器改变后的生命周期状态
  void handleLifecycle(PageState lifecycleState) {
    if (lifecycleState != lastState) {
      lastState = lifecycleState;
      // 遍历所有注册的消费者，如果其保留未发送的事件有效且生命周期匹配，则发送事件
      for (final consumer in _consumers) {
        if (consumer.event != null && consumer.lifecycleMatch(lifecycleState)) {
          consumer.eventSubject.add(consumer.event);
          consumer.event = null;
        }
      }
    }
  }
}
