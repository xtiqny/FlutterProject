import 'dart:collection';

import 'package:cn21base/cn21base.dart';
import 'package:meta/meta.dart';

import 'policy.dart';
import 'restful_base.dart';

/// 拦截器处理函数
/// 拦截器通过[RestfulClientBuilder]注册后，在构建的Client后续
/// 的请求中将会以链条方式调用，拦截器可以修改[InterceptContext]
/// 中的request以修改请求，同时可以自己处理request并返回
/// 相应的response。如果自己不处理，应该调用[forward]方法以调用
/// 链条的下一级进行处理，也可以在下一级响应后再对结果进行处理
typedef Interceptor = CancelableFuture<Response> Function(InterceptContext context);

/// 请求拦截上下文对象
class InterceptContext {
  /// 对应的请求对象
  Request request;

  /// 对应的策略上下文
  final PolicyContextView policy;

  final CancelableFuture<Response> Function(InterceptContext context) _forwardImpl;

  /// 拦截上下文构造方法
  InterceptContext({@required this.request, @required this.policy, @required Interceptor forwardImpl})
      : _forwardImpl = forwardImpl;

  /// 请求推进方法
  /// 调用该方法传递请求到下一级进行处理
  /// 处理将返回可取消的[Response]的[Future]对象
  CancelableFuture<Response> forward() => _forwardImpl?.call(this);
}

/// 负责执行Restful请求的客户端抽象基类
/// RestfulClient可以进行复用，同一个client的请求将共享同一组策略配置
/// 以及连接池等资源。如果某些请求需要设置独立的策略，可以使用[newBuilder]
/// 方法并设置相应策略并重新构造client实现。新的client依然可以和原来的共享
/// 同一个连接池。
abstract class RestfulClient {
  final PolicyContextView policy;
  final UnmodifiableListView<Interceptor> interceptors;
  RestfulClient({PolicyContextView policy, List<Interceptor> interceptors})
      : policy = policy,
        interceptors = UnmodifiableListView(interceptors ?? []),
        super();

  /// 执行Request请求
  /// 请求的执行将自动逐级调用已注册的拦截器进行拦截处理
  /// @return 可取消的[Response]的[Future]对象
  CancelableFuture<Response> execute(Request request) {
    int chainIndex = 0;
    final forwardInterceptors = <Interceptor>[];
    if (interceptors != null) {
      forwardInterceptors.addAll(interceptors);
    }
    CancelableFuture<Response> forwardIntercept(InterceptContext context) {
      if (forwardInterceptors.isNotEmpty && chainIndex < forwardInterceptors.length) {
        // 逐级调用链条进行处理
        return forwardInterceptors[chainIndex++]?.call(context);
      } else {
        // 已没有拦截器，发送最终请求
        return executeFinal(context.request);
      }
    }

    return forwardIntercept(InterceptContext(request: request, policy: policy, forwardImpl: forwardIntercept));
  }

  /// 最终的请求处理方法
  /// 子类必须实现该方法已执行实际的请求处理操作
  /// 如果拦截器没有自行处理请求，则最终将调用该方法进行处理
  @protected
  CancelableFuture<Response> executeFinal(Request request);

  /// 关闭client并释放相关资源
  /// 子类实现该方法以进行必要的清理操作
  void close();

  /// 创建新的[RestfulClientBuilder]
  /// 子类实现该方法以在现有client的资源及策略配置基础上
  /// 提供新的client构建对象。
  RestfulClientBuilder newBuilder();
}

/// [RestfulClient]的构建抽象基类
abstract class RestfulClientBuilder<T extends RestfulClient> {
  PolicyContext _policy;
  List<Interceptor> _interceptors;
  RestfulClientBuilder({PolicyContext policy, List<Interceptor> interceptorList})
      : _policy = policy,
        _interceptors = interceptorList ?? [];
  set policy(PolicyContext policy) => _policy = policy;
  get policyCopy => _policy.copy();
  set interceptors(List<Interceptor> list) => _interceptors = list;
  get interceptorsCopy => [_interceptors];
  void addInterceptor(Interceptor interceptor) {
    if (!_interceptors.contains(interceptor)) {
      _interceptors.add(interceptor);
    }
  }

  bool removeInterceptor(Interceptor interceptor) => _interceptors.remove(interceptor);
  void clearInterceptors() => _interceptors.clear();

  /// 构建方法
  /// 子类实现该方法以最终构建出相应的[RestfulClient]对象
  T build();
}
