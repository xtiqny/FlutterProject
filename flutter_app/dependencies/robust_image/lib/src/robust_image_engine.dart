import 'dart:async';
import 'dart:ui' as ui show instantiateImageCodec, Codec;

import 'package:async/async.dart';
import 'package:cn21base/cn21base.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';

import 'robust_image_module.dart';

/// 请求参数配置
class RequestConfig {
  const RequestConfig({
    this.useDiskCache = true,
    this.cacheSourceToDisk = true,
    this.useMemroyCache = true,
    this.cacheRenderToDisk = true,
  });

  /// 是否使用内存缓存
  final bool useMemroyCache;

  /// 是否使用本地磁盘缓存
  final bool useDiskCache;

  /// 是否缓存源图像文件到磁盘
  final bool cacheSourceToDisk;

  /// 是否缓存适合渲染的图像文件到磁盘
  final bool cacheRenderToDisk;
}

/// 加载图像的渲染请求
/// [RenderRequest]以渲染目标[ImageRender]为导向(同时以RobustImageKey为目标标识)，
/// 作为请求的上下文，为[RobustImageEngine]提供请求相关的 [RobustImageModule]，同时
/// 为应用提供图像加载请求的取消机制，当任务取消后，加载过程将抛出[CancelationException]
class RenderRequest<T extends RobustImageKey> {
  RenderRequest(
      {@required this.module,
      @required this.renderTarget,
      this.config = const RequestConfig()})
      : key = renderTarget.key;

  /// 加载目标图像所需的[RobustImageModule]对象
  final RobustImageModule module;

  /// 加载目标
  final ImageRender renderTarget;

  /// 图像的唯一标识
  final T key;

  /// 请求的配置参数
  final RequestConfig config;

  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  CancelableOperation _operation;
  ExecuteTask _executeTask;
  RobustImageEngine _engine;
  ExecuteTask _dispatchTask;
//  _ImageStreamCompleterWrapper _imageStreamCompleter;

  void _trackLoadingEngine(RobustImageEngine engine) {
    final old = _engine;
    _engine = engine;
    void onActiveChanged(ImageRender render, bool active) {
//      (active) ? _engine?._active(this) : _engine?._inactive(this);
      if (!active) {
//        cancel();
      }
    }

    if (old != _engine) {
      (_engine != null)
          ? renderTarget.addActiveCallback(onActiveChanged)
          : renderTarget.removeActiveCallback(onActiveChanged);
    }
  }

  void _trackCurrentOperation(CancelableOperation operation) {
    _operation = operation;
    if (operation != null && _cancelled) {
      operation.cancel();
    }
  }

  void _trackDispatchTask(ExecuteTask task) {
    _dispatchTask = task;
    if (task != null && _cancelled) {
      task.cancel();
    }
  }

  void _trackCurrentExecuteTask(ExecuteTask task) {
    _executeTask = task;
    if (task != null && _cancelled) {
      task.cancel();
    }
  }

//  void _trackImageCompleter(_ImageStreamCompleterWrapper imageCompleter) {
//    _imageStreamCompleter = imageCompleter;
//    if (imageCompleter != null && _cancelled) {
//      imageCompleter.cancel();
//    }
//  }

  /// 取消请求
  /// 调用该方法后，该对象不能再用于新的请求
  void cancel() {
    if (_cancelled) {
      return;
    }
    _cancelled = true;
    _operation?.cancel();
    _executeTask?.cancel();
    _dispatchTask?.cancel();
//    if (_imageStreamCompleter != null) {
//      _imageStreamCompleter.cancel();
//    }
  }
}

class _ExeTask<T> extends ExecuteTask {
  final Future<T> Function() runner;
  final Completer<T> completer;
  final ExecuteQueue executeQueue;
  bool _alreadyRunned = false;
  _ExeTask(String name, this.executeQueue, this.runner)
      : completer = Completer<T>(),
        super(name);
  @override
  FutureOr<void> run() {
    _alreadyRunned = true;
    final result = runner?.call();
    return result
        .then((val) => completer.complete(val),
            onError: (e) => completer.completeError(e))
        .then((_) {});
  }

  @override
  void onDetach() {
    if (!_alreadyRunned && !completer.isCompleted) {
      // Not being run before complete
      completer
          .completeError(CancelationException('Removed from running queue.'));
    }
  }

  @override
  void onCancel() {
    if (!isExecuting && !completer.isCompleted) {
      completer.completeError(CancelationException("Operation cancelled"));
    }
  }
}

class _DispatchTask extends _ExeTask<ui.Codec> {
  _DispatchTask(this.request, ExecuteQueue queue, Future<ui.Codec> loader())
      : super('dispatchTask', queue, () async {
          return loader();
        });

  @override
  void onDetach() {
    super.onDetach();
    imageStreamCompleter = null;
  }

  @override
  void onCancel() {
    if (!isExecuting && request != null && imageStreamCompleter != null) {
      // Since we are not running and imageStreamCompleter is not null,
      // it means we are not done for the image load, so we should clear
      // the memory cache for safety.
      request.module.imageCache?.evict(request.key);
    }
    super.onCancel();
  }

  final RenderRequest request;
  ImageStreamCompleter imageStreamCompleter;
}

Future<T> _execute<T>(String taskName, ExecuteQueue queue,
    RenderRequest request, Future<T> runner()) async {
  final task = _ExeTask(taskName, queue, () async {
    try {
      if (request.isCancelled) {
        throw CancelationException(
            'task:$taskName is cancelled. request:${request.key.renderKey}');
      }
      return await runner();
    } finally {
      request._trackCurrentExecuteTask(null);
    }
  });
  queue.enqueueTail(task);
  request._trackCurrentExecuteTask(task);
  final result = await task.completer.future;
  if (request.isCancelled) {
    throw CancelationException(
        'task:$taskName is cancelled. request:${request.key.renderKey}');
  }
  return result;
}

typedef ImageStreamRetainVote = bool Function(
    RobustImageKey key, ImageStreamCompleter completer);

const int kDecodeQueueFreeSize = 2;

class _AutoConcurrentResolver {
  _AutoConcurrentResolver(
      {this.maxDecodeConcurrent = 1,
      this.maxDiskCacheConcurrent = 1,
      this.maxSourceFetchConcurrent = 1});
  RobustImageEngine engine;
  int maxDiskCacheConcurrent;
  int maxSourceFetchConcurrent;
  int maxDecodeConcurrent;
  int resolveConcurrent(ExecuteQueue queue) {
    if (engine == null) {
      return 0;
    }
    // Decode queue is always the highest priority task. Since all the IO
    // operations in Flutter is on the same thread spawned by IORunner,
    // so if there are to many decode task are performing or pending, we stop
    // the scheduling of other IO tasks.
    if (queue == engine._decodeQueue) {
      if (queue.total <= kDecodeQueueFreeSize) {
        if (engine._diskCacheQueue.total > 0) {
          Future(() => engine._diskCacheQueue.scheduleTasks());
        }
        if (engine._sourceFetchQueue.total > 0) {
          Future(() => engine._sourceFetchQueue.scheduleTasks());
        }
      }
      return maxDecodeConcurrent;
    } else if (queue == engine._diskCacheQueue) {
      int total = engine._decodeQueue.total;
      if (total > kDecodeQueueFreeSize) {
        return 0;
      } else if (total > 0) {
        return 1;
      } else {
        return maxDiskCacheConcurrent;
      }
//      return (engine._decodeQueue.total > 0) ? 0 : maxDiskCacheConcurrent;
    } else if (queue == engine._sourceFetchQueue) {
      int total = engine._decodeQueue.total;
      if (total > kDecodeQueueFreeSize) {
        return 0;
      } else if (total > 0) {
        return 1;
      } else {
        return maxSourceFetchConcurrent;
      }
//      return (engine._decodeQueue.total > 0) ? 0 : maxSourceFetchConcurrent;
    } else if (queue == engine._dispatchQueue) {
      int diskCacheConcurrent = engine._diskCacheQueue.maxConcurrent;
      int sourceFetchConcurrent = engine._sourceFetchQueue.maxConcurrent;
      int count = diskCacheConcurrent + sourceFetchConcurrent;
      return count < 4 ? 4 : count;
//      return count > 8 ? 8 : count;
    }
    return 0;
  }
}

/// 图像加载引擎
/// 该对象利用并发调度对象，控制图像加载请求的调度运行
/// 图像加载分内存缓存、本地磁盘缓存两级缓存，当两级缓存无法命中时，通过源站加载，
/// 其中图像资源的标识由[RobustImageKey]表示，所需要的所有领域对象由[RobustImageModule]
/// 提供。这些对象都通过加载请求的[RenderRequest]关联并提供。
/// 图像数据加载会依照[RequestConfig]配置是否使用缓存、使用哪一种缓存、从源站加载
/// 后是否保存源数据到本地磁盘缓存。图像加载后会使用[ImageRender]解码渲染。
class RobustImageEngine {
  RobustImageEngine({
    ExecuteQueue diskCacheQueue,
    ExecuteQueue sourceFetchQueue,
    ExecuteQueue decodeQueue,
  })  : _diskCacheQueue =
            diskCacheQueue ?? ExecuteQueue.max(4, name: 'diskCacheQueue'),
        _sourceFetchQueue =
            sourceFetchQueue ?? ExecuteQueue.max(8, name: 'sourceFetchQueue'),
        _decodeQueue =
            decodeQueue ?? ExecuteQueue.max(48, name: 'decodeQueue') {
    _AutoConcurrentResolver resolver = _AutoConcurrentResolver();
    resolver.engine = this;
    _dispatchQueue =
        ExecuteQueue.custom(resolver.resolveConcurrent, name: 'dispatchQueue');
  }

  /// 创建自动调度的加载引擎
  /// 引擎将自行创建相应的IO任务队列并使用decode优先的自动任务调度机制、
  /// 执行图像加载。使用者仍然可以指定磁盘缓存、源站请求以及解码队列的
  /// 最大并发数量限制。自动调度的IO队列将不会超过这些限制
  factory RobustImageEngine.auto(
      {int maxDiskCacheConcurrent = 3,
      int maxSourceFetchConcurrent = 3,
      int maxDecodeConcurrent = 8}) {
    _AutoConcurrentResolver resolver = _AutoConcurrentResolver(
        maxDecodeConcurrent: maxDecodeConcurrent,
        maxDiskCacheConcurrent: maxDiskCacheConcurrent,
        maxSourceFetchConcurrent: maxSourceFetchConcurrent);
    RobustImageEngine engine = RobustImageEngine(
        diskCacheQueue: ExecuteQueue.custom(resolver.resolveConcurrent,
            name: 'diskCacheQueue'),
        sourceFetchQueue: ExecuteQueue.custom(resolver.resolveConcurrent,
            name: 'sourceFetchQueue'),
        decodeQueue: ExecuteQueue.custom(resolver.resolveConcurrent,
            name: 'decodeQueue'));
    resolver.engine = engine;
    return engine;
  }
  final ExecuteQueue _diskCacheQueue;
  final ExecuteQueue _sourceFetchQueue;
  final ExecuteQueue _decodeQueue;
  ExecuteQueue _dispatchQueue;
  int _keepQueueSize = 100;
  bool _schedulingDiscard = false;
  final List<ImageStreamRetainVote> _voteList = [];

  /// 启动所请求图像的加载
  ImageStreamCompleter resolve(RenderRequest request,
      {ImageErrorListener onError}) {
    assert(request != null);
    RobustImageModule module = request.module;
    ImageCache imageCache = module.imageCache;
    final RobustImageKey key = request.key;
    ImageStreamCompleter completer;
    if (request.config.useMemroyCache && imageCache != null) {
      completer = imageCache.putIfAbsent(key, () => _dispatch(request),
          onError: onError);
    } else {
      completer = _dispatch(request);
    }
    // Try to schedule auto discard policy if no policy running currently.
    scheduleNextAutoDiscardPolicy();
    return completer;
  }

  /// 分派加载任务
  ImageStreamCompleter _dispatch(RenderRequest request) {
    final task = _DispatchTask(request, _dispatchQueue, () async {
      try {
        if (request.isCancelled) {
          throw CancelationException(
              'request:${request.key.renderKey} is cancelled. request:${request.key.renderKey}');
        }
        return await _safeLoadAsync(request);
      } finally {
        request._trackDispatchTask(null);
      }
    });

    ImageStreamCompleter imageCompleter =
        request.renderTarget.render(() => task.completer.future);
    task.imageStreamCompleter = imageCompleter;
    _dispatchQueue.enqueueHead(task);
    request._trackDispatchTask(task);
    return imageCompleter;
  }

  Future<ui.Codec> _safeLoadAsync(RenderRequest request) async {
    try {
//      print(
//          '----------- Start _safeLoadAsync request:${request.key.renderKey} instance:${request.hashCode}');
      assert(request._engine == null || request._engine == this);
      request._trackLoadingEngine(this);
      final result = await _loadAsync(request);
      assert(result != null,
          '!!!!!!!!!!!!!!!! Oh no! the result is null, there is some bug.');
//      print(
//          '----------- End _safeLoadAsync request:${request.key.renderKey} instance:${request.hashCode} result=$result');
      // Mark we have done the loading, so we won't call
      // active or inactive later.
//      request._imageStreamCompleter?.completer?.complete();
      return result;
    } catch (e) {
//      print(
//          '----------- Error _safeLoadAsync $e request:${request.key.renderKey} instance:${request.hashCode}');
      // FIXME: 由于Flutter的[ImageCache]没有自动的出错清理机制，
      // 为了避免加入到[ImageCache]的请求由于错误导致后续无法重新
      // 请求加载，因此出错时先尝试清理掉对应的内存缓存
      bool done = request.module.imageCache?.evict(request.key);
      if (done) {
//        debugPrint('Removed request:${request.key} from memory cache.');
      }

      // Mark loading failed, so we won't call
      // active or inactive later.
//      request._imageStreamCompleter?.completer?.completeError(e);
      rethrow;
    } finally {
      request._trackLoadingEngine(null);
    }
  }

  Future<ui.Codec> _convertAndDecode(
      RenderRequest request, BinaryData data) async {
    return _execute('_convertAndDecode', _decodeQueue, request, () async {
      ui.Codec codec = await request.renderTarget.instantiateImageCodec(data);
      if (codec != null) {
        // If there is a still image, we wait for
        // the first frame decoded, because we should
        // control the number of concurrent IO operations.
        if (codec.frameCount == 1) {
//          debugPrint(
//              'Try to decode the frame. request:${request.key.renderKey}');
//          await codec.getNextFrame();
        }
        return codec;
      } else {
        throw Exception('Can not initialize the codec');
      }
    });
  }

  Future<ui.Codec> _loadAsync(RenderRequest request) async {
    final RobustImageKey key = request.key;
    RobustImageModule module = request.module;
    DiskCache diskCache = module.diskCache;
    SourceFetcher fetcher = module.sourceFetcher;
    ImageRender imageRender = request.renderTarget;
    RequestConfig config = request.config;
    ui.Codec codec;
    // Try to load from disk.
    if (config.useDiskCache && diskCache != null) {
      if (request.isCancelled) {
        throw CancelationException('Cancelled before load from disk cache.');
      }
      try {
        BinaryData data = await _execute("LoadDiskCache", _diskCacheQueue,
            request, () => diskCache.load(key, CacheFit.any));
        if (request.isCancelled) {
          throw CancelationException(
              'request cancelled before initialize the codec. request:${request.key.renderKey} instance:${request.hashCode}');
        }
        if (data != null) {
//          debugPrint(
//              '-----------> Request:${request.key.renderKey} instance:${request.hashCode} loaded from disk cache!');
          codec = await _convertAndDecode(request, data);
          return codec;
        }
      } catch (e) {
        if (e is! CancelationException) {
          print(e);
        }
      }
    }
    // Try to fetch from source.
    if (fetcher != null) {
      if (request.isCancelled) {
        throw CancelationException(
            '...... _loadAsync request cancelled before fetch. request:${key.renderKey} instance:${request.hashCode}');
      }
      try {
        BinaryData data =
            await _execute("FetchSource", _sourceFetchQueue, request, () async {
//          print('>>>> Start to fetch ${key.renderKey}');
          CancelableOperation<BinaryData> operation = fetcher.fetch(key);
          // Let the request track this operation, so it can cancel
          // when the user want to do that.
          request._trackCurrentOperation(operation);
          BinaryData source = await operation.valueOrCancellation(null);
          if (request.isCancelled) {
            throw CancelationException(
                '...... _loadAsync request cancelled after fetch. request:${key.renderKey} instance:${request.hashCode}');
          }
          if (source != null) {
            if (config.cacheSourceToDisk && diskCache != null) {
              // The source raw image data is not designed for rendering
              // We will store the source to disk first.
              // Store it first
              try {
//                debugPrint('Store source file to disk cache.');
                await diskCache.store(key, source, CacheLevel.source);
              } catch (e) {
                if (e is! CancelationException) {
                  print(e);
                }
              }
            }
            if (key.sourceKey != key.renderKey) {
              // build the render version first.
              source = await imageRender.buildRenderImage(source);
              // Save the render version to disk now.
              if (config.cacheRenderToDisk && diskCache != null) {
                try {
//                  debugPrint('Store render file to disk cache.');
                  await diskCache.store(key, source, CacheLevel.render);
                } catch (e) {
                  if (e is! CancelationException) {
                    print(e);
                  }
                }
              }
            }
          }
//          debugPrint(
//              '-----------> Request:${request.key.renderKey} instance:${request.hashCode} loaded from source site!');
          return source;
        });
        //          /\
        //          ||
        // Now data should be equal to the source which returned above
        if (data != null) {
          codec = await _convertAndDecode(request, data);
          return codec;
        }
      } finally {
        request._trackCurrentOperation(null);
      }
    }
    throw Exception(
        "Failed to load image. request:${request.key.renderKey} instance:${request.hashCode}");
  }

  void addImageStreamRetainVote(ImageStreamRetainVote vote) {
    if (!_voteList.contains(vote)) {
      _voteList.add(vote);
    }
  }

  bool removeImageStreamRetainVote(ImageStreamRetainVote vote) {
    return _voteList.remove(vote);
  }

  /// 判断加载任务中的图像是否有关注者
  bool _hasConcern(_DispatchTask task) {
    final key = task.request?.key;
    final completer = task.imageStreamCompleter;
    if (key == null || completer == null) {
//      print('Null key or completer. key=$key completer=$completer');
      return false;
    }
    final list = _voteList.toList(growable: false);
    for (var vote in list) {
      if (vote(key, completer)) {
        // There is someone cares about this image stream.
        return true;
      }
    }
    return false;
  }

  /// 调度下一次自动清理策略
  void scheduleNextAutoDiscardPolicy() {
    if (!_schedulingDiscard) {
      _schedulingDiscard = true;
      Timer(Duration(milliseconds: 2000),
          () => _runAutoDiscardPolicy(_keepQueueSize));
    }
  }

  /// 执行自动清理策略
  int _runAutoDiscardPolicy(int keepSize) {
    try {
      _schedulingDiscard = false;
      print('disp(t:${_dispatchQueue.total} c:${_dispatchQueue.concurrent})'
          ' src(t:${_sourceFetchQueue.total} c:${_sourceFetchQueue.concurrent})'
          ' disk(t:${_diskCacheQueue.total} c:${_diskCacheQueue.concurrent}) '
          ' dec(t:${_decodeQueue.total} c:${_decodeQueue.concurrent})'
          ' l:${_voteList.length}');
      if (keepSize >= _dispatchQueue.total) {
        // Do nothing
        return 0;
      }
      var discardList = _dispatchQueue.getTasksFromTail((t) {
        var task = (t as _DispatchTask);
        int count = 0;
        if (task.request != null &&
            keepSize + count < _dispatchQueue.total &&
            !_hasConcern(task)) {
          ++count;
          if (!task.isCancelled && !task.isRemoving) {
            // Discard this
            return true;
          }
        }
        return false;
      });
      for (var task in discardList) {
        (task as _DispatchTask).request?.cancel();
        (task as _DispatchTask).cancel();
      }
      int length = discardList.length;
      if (discardList.isNotEmpty) {
        debugPrint('We have newly discarded $length tasks.');
      }
      return length;
    } catch (e) {
      print(e);
    } finally {
      if (_dispatchQueue.total > 0) {
        scheduleNextAutoDiscardPolicy();
      }
    }
    return 0;
  }

  /// 放弃请求
  void discard(RenderRequest request) {
    ExecuteTask task = request._dispatchTask;
    if (task == null) {
      // Just cancel since we have never schedule it.
      request.cancel();
      return;
    }
    // Ask every body if they are still demanding the image stream completer
    // which is handled by this request, if so, don't cancel the request.
    // Why not just cancel the request is because sometimes a image widget state
    // could be unmounted and soon mounted again(scroll out and in again) for
    // the same image. It's inefficient to cancel and then reload it again.
    if (!_hasConcern(task)) {
//      debugPrint(
//          'No body concern when a request:${request.key.renderKey} is being discarded.');
      request.cancel();
      if (request._dispatchTask != null) {
        _dispatchQueue.remove(task);
      }
    } else {
      // We will keep it on queue to complete or cancelled
//      debugPrint('We will keep the discarded request:${request.key.renderKey}');
    }
  }

  void _active(RenderRequest request) {
//    debugPrint(
//        '----> Requst active: requests=${request.hashCode}, key=${request.key.renderKey}');
    if (!request.isCancelled) {
      _handleRequestActiveChange(request, true);
    }
  }

  void _inactive(RenderRequest request) {
//    debugPrint(
//        '====> Requst inactive: requests=${request.hashCode}, key=${request.key.renderKey}');
    _handleRequestActiveChange(request, false);
  }

  void _handleRequestActiveChange(RenderRequest request, bool active) {
    ExecuteTask task = request._executeTask;
    if (task != null &&
        task is _ExeTask &&
        task.isInQueue &&
        !task.isRemoving) {
      bool done = active
          ? task.executeQueue?.enqueueHead(task)
          : task.executeQueue?.enqueueTail(task);
      assert(done);
    }
  }
}
