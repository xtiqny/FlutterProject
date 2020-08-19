///订阅者回调函数，even为回调信息
typedef void EventCallback(even);

///简单的事件总线，已eventKey作为事件回调标识
class EventBus {
  static EventBus _singleton = new EventBus._internal();
  factory EventBus()=> _singleton;

  EventBus._internal();

  ///事件订阅者队列，eventKey:事件标识，value: 对应事件的订阅者队列
  var _eventQueue = new Map<Object, List<EventCallback>>();

  ///是否注册过某事件标识
  bool hasRegister(eventKey, EventCallback callback){
    if (eventKey == null || callback == null) return false;
    List<EventCallback> evenCallback = _eventQueue[eventKey];
    if(evenCallback != null && evenCallback.isNotEmpty && evenCallback.contains(callback)){
      return true;
    }
    return false;
  }

  ///订阅
  void register(eventKey, EventCallback callback) {
    if (eventKey == null || callback == null) return;
    _eventQueue[eventKey] ??= new List<EventCallback>();
    _eventQueue[eventKey].add(callback);
  }

  ///取消订阅
  void unRegister(eventKey, [EventCallback callback]) {
    var list = _eventQueue[eventKey];
    if (eventKey == null || list == null) return;
    if (callback == null) {
      _eventQueue[eventKey] = null;
    } else {
      list.remove(callback);
    }
  }

  ///发送事件
  void post(eventKey, [event]) {
    var list = _eventQueue[eventKey];
    if (list == null) return;
    int len = list.length - 1;
    for (var i = len; i > -1; --i) {
      list[i](event);
    }
  }
}