import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';

/// 执行任务的基类
/// 子类必须实现其中的run()方法并在此方法中执行
/// 任务的处理逻辑。
/// 使用者应该保证每一个任务实例仅使用一次。即不能
/// 将同一实例同时添加到不同过的[ExecuteQueue]，且
/// 一旦添加后，除非在未执行的情况下调整优先级(参考
/// [ExecuteQueue]的enqueueHead和enqueueTail解释)，
/// 否则不应该重新添加（即已完成、已取消、出现错误
/// 等情况下不能重新添加该实例）。
abstract class ExecuteTask {
  bool _executing = false;
  bool _removing = false;
  bool get isExecuting => _executing;
  bool get isInQueue => _executeQueue != null;
  bool get isRemoving => _removing;
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  ExecuteQueue _executeQueue;
  Future<void> _result;
  final String name;
  ExecuteTask(this.name);

  /// 任务执行逻辑的入口
  /// 子类必须实现该方法。
  /// @return 当处理逻辑立即完成时，返回null，否则返回Future
  @protected
  FutureOr<void> run();
  FutureOr<void> _runInternal() {
    if (_cancelled) {
      // Cancelled before executing.
      return null;
    } else {
      return run();
    }
  }

  /// 当任务添加到任务队列后回调
  @protected
  void onAttach(ExecuteQueue queue) {}

  /// 当任务从任务队列移除后(包括任务完成)回调
  @protected
  void onDetach() {}

  /// 取消任务
  /// 一旦任务取消，则不能次添加到队列中
  /// 子类应该重载onCancel方法，并实现取消任务
  /// 的逻辑(如重置IO操作)。
  /// 该方法会自动调用[ExecuteQueue]的remove方法
  /// 并最终从队列中移除该任务(因为每个任务实例仅
  /// 能使用一次)。
  /// @return 如果此前未调用过cancel方法返回true，否则返回false
  bool cancel() {
    if (_cancelled) {
      return false;
    }
    _cancelled = true;
    onCancel();
    _executeQueue?.remove(this);
    return true;
  }

  /// 取消任务的处理入口
  /// 子类重载该方法以实现如取消IO等必要的取消逻辑
  @protected
  void onCancel() {}
}

/// 具备返回值的函数类任务
/// 返回值通过future属性获取
class FunctionTask<T> extends ExecuteTask {
  final Future<T> Function() _operation;
  final Completer<T> _completer;
  Future<T> get future => _completer.future;
  bool _alreadyRunned = false;
  FunctionTask({String name, Future<T> operation()})
      : _operation = operation,
        _completer = Completer<T>(),
        super(name);
  @override
  FutureOr<void> run() {
    _alreadyRunned = true;
    final result = _operation?.call();
    return result
        .then((val) => _completer.complete(val),
            onError: (e) => _completer.completeError(e))
        .then((_) {});
  }

  @override
  void onDetach() {
    if (!_alreadyRunned && !_completer.isCompleted) {
      // Not being run before complete
      cancel();
    }
  }

  @override
  bool cancel() {
    bool done = super.cancel();
    if (!isExecuting && !_completer.isCompleted) {
      _completer.completeError(Exception('onCancel'));
    }
    return done;
  }
}

/// 任务并发数量控制函数对象
/// 该方法必须返回当前所的最大并发数量(>= 0)。返回值仅对后续的并发调度
/// 产生影响，当前正在执行的任务不受影响。当该方法返回0时，将表示后续
/// 没有任务能够执行。
typedef ConcurrentCountResolver = int Function(ExecuteQueue queue);

const String kQueueName = 'ExecuteQueue';

/// 任务调度执行队列
///  ExecuteQueue 支持优先执行(通过 enqueueHead)和
///  排队执行(通过enqueueTail)两种调度策略。同时可以
///  控制队列的并发执行任务数量。并发数量控制策略可以
///  通过构造函数指定，支持single、max和custom方式。
class ExecuteQueue {
  ExecuteQueue._() : name = kQueueName;

  /// 构造单任务调度队列
  ExecuteQueue.single({this.name = kQueueName}) : _resolver = ((_) => 1);

  /// 构造最大任务调度数量队列
  /// @param maxConcurrentTasks 最大并发调度任务数量
  ExecuteQueue.max(int maxConcurrentTasks, {this.name = kQueueName})
      : _resolver = ((_) => maxConcurrentTasks);

  /// 构造自定义并发任务数量调度队列
  /// @param resolver 并发任务调度策略控制器
  ExecuteQueue.custom(ConcurrentCountResolver resolver,
      {this.name = kQueueName})
      : assert(resolver != null),
        _resolver = resolver;
  ConcurrentCountResolver _resolver;
  final _requestTasks = ListQueue<ExecuteTask>();
  final _executingTasks = HashSet<ExecuteTask>();
  final String name;

  /// 添加优先执行任务
  /// 如果此任务已存在队列中，则会自动将其调整至
  /// 最高优先级。
  /// @param task 待执行任务
  /// @return 是否成功添加（或调整）
  bool enqueueHead(ExecuteTask task) {
    bool firstAttach = true;
    if (task._executeQueue == this) {
      // Already in our queue, remove it first
      _requestTasks.remove(task);
      firstAttach = false;
    } else if (task._executeQueue != null) {
      return false;
    }
    _requestTasks.addFirst(task);
    _handleAdded(task, firstAttach);
    return true;
  }

  /// 添加排队执行任务
  /// 如果此任务已存在队列中，则会自动将其调整至
  /// 最低优先级。
  /// @param task 待执行任务
  /// @return 是否成功添加（或调整）
  bool enqueueTail(ExecuteTask task) {
    bool firstAttach = true;
    if (task._executeQueue == this) {
      // Already in our queue, remove it first
      _requestTasks.remove(task);
      firstAttach = false;
    } else if (task._executeQueue != null) {
      return false;
    }
    _requestTasks.addLast(task);
    _handleAdded(task, firstAttach);
    return true;
  }

  /// 判断任务是否在队列中
  bool contains(ExecuteTask task) {
    return task?._executeQueue == this;
  }

  FutureOr<bool> _removeAt(int index) {
    ExecuteTask task = _requestTasks.elementAt(index);
    task._removing = true;
    if (task.isExecuting && task._result != null) {
      // We will wait it for completed or cancelled
      return task._result.then((_) {
        assert(task._executeQueue == null);
        assert(!_executingTasks.contains(task));
        _handleRemoved(task);
        return true;
      }, onError: (e) {
        print(e);
        _handleRemoved(task);
        return true;
      });
    } else {
      // Not executing, can be removed now.
      assert(!_executingTasks.contains(task));
      _requestTasks.remove(task);
      _handleRemoved(task);
      return true;
    }
  }

  /// 从队列中移除指定任务
  /// 由于指定的任务可能正在执行，而移除操作必须在
  /// 任务没有执行的状态下才能完成，当调用时若移除
  /// 能够立即完成(或不存在该任务)，则立即返回是否
  /// 成功移除(bool类型)，否则将返回Future表示不能
  /// 立即删除，待任务结束(无论完成、被取消还是错误)
  /// 后自动移除。
  /// @param 待移除的任务
  /// @return 是否立即移除成功或Future
  FutureOr<bool> remove(ExecuteTask task) {
    if (task?._executeQueue != this) {
      return false;
    }
    for (int i = 0; i < _requestTasks.length; i++) {
      if (_requestTasks.elementAt(i) == task) {
        return _removeAt(i);
      }
    }
    return false;
  }

  /// 从队列头部开始删除符合条件的任务
  /// @param test 条件测试函数，如果为null则所有任务都符合条件
  /// @return 通过test条件测试的任务列表的删除结果
  List<FutureOr<bool>> removeFromHead([bool test(ExecuteTask task)]) {
    var results = <FutureOr<bool>>[];
    for (int i = 0; i < _requestTasks.length; i++) {
      final task = _requestTasks.elementAt(i);
      if (test == null || test(task)) {
        results.add(_removeAt(i));
        i--;
      }
    }
    return results;
  }

  /// 从队列尾部开始删除符合条件的任务
  /// @param test 条件测试函数，如果为null则所有任务都符合条件
  /// @return 通过test条件测试的任务列表的删除结果
  List<FutureOr<bool>> removeFromTail([bool test(ExecuteTask task)]) {
    var results = <FutureOr<bool>>[];
    for (int i = _requestTasks.length - 1; i >= 0; i--) {
      final task = _requestTasks.elementAt(i);
      if (test == null || test(task)) {
        results.add(_removeAt(i));
      }
    }
    return results;
  }

  void _handleAdded(ExecuteTask task, bool firstAttach) {
    task._removing = false;
    task._executeQueue = this;
    if (firstAttach) {
      task.onAttach(this);
    }
    scheduleTasks();
  }

  void _handleRemoved(ExecuteTask task) {
    final taskQueue = task._executeQueue;
    task._executeQueue = null;
    task._executing = false;
    task._removing = false;
    task._result = null;
    if (taskQueue != null) {
      assert(taskQueue == this);
      task.onDetach();
    }
  }

  void _handleComplete(ExecuteTask task) {
//    debugPrint('$name ====> _handleComplete task:${task.name}');
    task._executing = false;
    final taskQueue = task._executeQueue;
    task._executeQueue = null;
    task._result = null;
    _executingTasks.remove(task);
    _requestTasks.remove(task);
    if (taskQueue != null) {
      assert(taskQueue == this);
      task.onDetach();
    }
    scheduleTasks();
  }

  void _handleError(ExecuteTask task, dynamic error) {
    _handleComplete(task);
  }

  List<ExecuteTask> _getNextExecuteTasks(int quota) {
    final pendingTasks = <ExecuteTask>[];
    var iter = _requestTasks.iterator;
    while (pendingTasks.length < quota && iter.moveNext()) {
      ExecuteTask task = iter.current;
      if (!task.isExecuting) {
        pendingTasks.add(task);
      }
    }
//    debugPrint(
//        '$name ====> getNextExecuteTasks: curRunning:${_executingTasks.length}, total:${_requestTasks.length}, quota=$quota, tasksCount=${pendingTasks.length}');
    return pendingTasks;
  }

  void _runTask(ExecuteTask task) async {
    try {
//      print('$name ====> runTask id:${task.name}#${task.hashCode}');
      final result = task._runInternal();
      if (result is Future) {
        await result;
      } else {
        // Already done.
      }
      _handleComplete(task);
    } catch (e) {
      print(e);
      _handleError(task, e);
    }
  }

  /// 尝试调度执行任务
  /// 该方法将通过[ConcurrentCountResolver]获取最大支持的并发数，
  /// 如果存在可用并发额度，则依照优先级选择队列中的额度内数量
  /// 的任务并调度执行。
  /// 使用者调用enqueueHead或enqueueTail将自动触发调度，无需
  /// 自行调用该方法。因此通常是以custom方式构造队列的方式下，
  /// 当[ConcurrentCountResolver]策略发生了调整(例如可并发执行
  /// 任务数量增加)时需要调用此方法以尽快反应策略的变更。
  void scheduleTasks() {
    int maxConcurrent = _resolver(this);
    int curRunning = _executingTasks.length;
    int quota = maxConcurrent - curRunning;
    if (quota > 0) {
//      debugPrint(
//          '$name ====> There are quotas to run, curRunning:$curRunning, total:${_requestTasks.length}');
      // We can schedule some tasks.
      final tasks = _getNextExecuteTasks(quota);
      tasks.forEach((t) {
        t._executing = true;
        _executingTasks.add(t);
        // It will be scheduled to run, but since
        // the task may complete at once, and then
        // we will call scheduleTasks() again and
        // it will lead to a recursive call which
        // may cause the StackOverflow exception,
        // so we use async call to avoid this problem.
        t._result = Future<void>(() => _runTask(t));
      });
    }
  }

  /// 当前允许的最大并发数量
  int get maxConcurrent => _resolver(this);

  /// 总任务数量
  int get total => _requestTasks.length;

  /// 当前并发调度执行的任务数量
  int get concurrent => _executingTasks.length;

  /// 返回所有的任务对象
  List<ExecuteTask> getAllTasks() {
    return _requestTasks.toList();
  }

  /// 从队列头部开始获取指定条件的任务对象
  /// @param test 过滤条件函数，如果为null则表示无条件，将返回所有任务对象
  /// @return 返回满足条件的任务列表
  List<ExecuteTask> getTasksFromHead([bool test(ExecuteTask task)]) {
    if (test == null) {
      return getAllTasks();
    } else {
      return _requestTasks.where(test);
    }
  }

  /// 从队列尾部开始获取符合条件的任务
  /// @param test 条件测试函数，如果为null则所有任务都符合条件
  /// @return 通过test条件测试的任务列表
  List<ExecuteTask> getTasksFromTail([bool test(ExecuteTask task)]) {
    if (test == null) {
      return getAllTasks();
    } else {
      var results = <ExecuteTask>[];
      for (int i = _requestTasks.length - 1; i >= 0; i--) {
        final task = _requestTasks.elementAt(i);
        if (test == null || test(task)) {
          results.add(_requestTasks.elementAt(i));
        }
      }
      return results;
    }
  }

  /// 获取前面的指定数量的任务对象
  /// @param limit 数量限制，如果为0或null则相当于获取全部
  /// @return 返回任务列表，任务数量为min(limit, total)
  List<ExecuteTask> getHeads([int limit = 1]) {
    if (limit == null || limit <= 0 || _requestTasks.length <= limit) {
      return getAllTasks();
    } else {
      return _requestTasks.take(limit);
    }
  }

  /// 获取后面的指定数量的任务
  /// @param limit 数量限制，如果为0或null则相当于获取全部
  /// @return 返回任务列表，任务数量为min(limit, total)
  List<ExecuteTask> getTails([int limit = 1]) {
    if (limit == null || limit <= 0 || _requestTasks.length <= limit) {
      return getAllTasks();
    } else {
      // FIXME: We use a dart:_internal method here.
      return _requestTasks
          .toList()
          .sublist(_requestTasks.length - limit, limit);
    }
  }

  /// 返回当前正在执行的任务对象
  List<ExecuteTask> getExecutingTasks() {
    return _executingTasks.toList();
  }
}
