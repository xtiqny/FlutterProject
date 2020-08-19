import 'dart:async';
import 'dart:typed_data';

import 'package:cn21base/cn21base.dart';

import 'exception.dart';
import 'restful_base.dart';
import 'restful_client.dart';

/// 数据转换器函数定义
/// 实现 R -> V 的数据类型转换
typedef Converter<R, V> = V Function(R data);

/// 数据转换器工厂类
abstract class ConverterFactory {
  /// 获取[Request]的Body转换器函数对象
  /// @param type 模板T的[Type]类型
  /// @param extraInfo 额外的信息，可为null
  /// @return 对应的[Converter]或null
  Converter<T, HttpBody> getRequestConverter<T>(Type type, [dynamic extraInfo]);

  /// 获取[Response]的Body转换器函数对象
  /// @param type 模板T的[Type]类型
  /// @param extraInfo 额外的信息，可为null
  /// @return 对应的[Converter]或null
  Converter<HttpBody, FutureOr<T>> getResponseConverter<T>(Type type,
      [dynamic extraInfo]);

  /// 获取[String]类型的转换器函数对象
  /// @param type 模板T的[Type]类型
  /// @param extraInfo 额外的信息，可为null
  /// @return 对应的[Converter]或null
  Converter<FutureOr<T>, String> getStringConverter<T>(Type type,
      [dynamic extraInfo]);
}

/// [RestfulApiService]的Agent类
/// 该类中包含RestfulApiService所需要的运行环境信息，
/// 并提供新的构造器以修改对应的信息从而构造出新的
/// agent对象，并最终用于新的[RestfulApiService]构建
class RestfulAgent {
  /// 相应API的基地址
  final Uri baseUrl;

  /// 任务并发调度对象
  final dynamic executors;

  /// 转换器工厂管理对象
  final ConverterFactoryManager convFactoryManager;

  /// 执行API请求的客户端对象
  final RestfulClient client;

  RestfulAgent(
      {this.baseUrl, this.executors, this.convFactoryManager, this.client});

  /// 新构造器提供方法，用于修改和构造新的agent
  RestfulAgentBuilder newBuilder() {
    final builder = RestfulAgentBuilder();
    builder._baseUrl = baseUrl;
    builder._executors = executors;
    if (convFactoryManager != null) {
      builder._convFactories.addAll(convFactoryManager._convFactories);
    }
    return builder;
  }
}

/// 数据转换器管理类
/// 该类统一管理和协调多个转换器工厂对象提供相应的转换器函数
class ConverterFactoryManager implements ConverterFactory {
  final List<ConverterFactory> _convFactories;
  ConverterFactoryManager(List<ConverterFactory> factories, [bool copy = true])
      : _convFactories = (copy) ? List.from(factories) : factories;
  @override
  Converter<FutureOr<T>, HttpBody> getRequestConverter<T>(Type type,
      [extraInfo]) {
    Converter<T, HttpBody> converter;
    for (var factory in _convFactories) {
      if ((converter = factory.getRequestConverter(type, extraInfo)) != null) {
        return converter;
      }
    }
    return null;
  }

  @override
  Converter<HttpBody, FutureOr<T>> getResponseConverter<T>(Type type,
      [extraInfo]) {
    Converter<HttpBody, FutureOr<T>> converter;
    for (var factory in _convFactories) {
      if ((converter = factory.getResponseConverter(type, extraInfo)) != null) {
        return converter;
      }
    }
    return null;
  }

  @override
  Converter<FutureOr<T>, String> getStringConverter<T>(Type type, [extraInfo]) {
    Converter<T, String> converter;
    for (var factory in _convFactories) {
      if ((converter = factory.getStringConverter(type, extraInfo)) != null) {
        return converter;
      }
    }
    return null;
  }
}

/// [RestfulAgent]对象构造类
class RestfulAgentBuilder {
  Uri _baseUrl;
  var _executors;
  var _convFactories = <ConverterFactory>[];
  RestfulClient _client;
  set baseUrl(Uri url) => _baseUrl = url;
  set executors(dynamic exes) => _executors = exes;
  set client(RestfulClient client) => _client = client;
  void addConverterFactory(ConverterFactory convFactory) =>
      _convFactories.add(convFactory);
  bool removeConverterFactory(ConverterFactory convFactory) =>
      _convFactories.remove(convFactory);
  void clearConverterFactories() => _convFactories.clear();

  /// [RestfulAgent]对象实例的构造方法
  RestfulAgent build() {
    return RestfulAgent(
        baseUrl: _baseUrl,
        executors: _executors,
        convFactoryManager: ConverterFactoryManager(_convFactories, false),
        client: _client);
  }
}

_typeOf<T>() => T;

/// 取消操作的回调处理函数
/// @param request 被取消的[Request]对象
/// @param response 如果被取消时仍然未获得响应对象则为null，否则为对应的[Response]对象
/// @return 自定义的返回值，如果不能立即返回，则可以返回[Future]
typedef OnCancelRequest = FutureOr<dynamic> Function(Request request,
    [Response response]);

/// Restful API服务的抽象基类
abstract class RestfulApiService {
  final RestfulAgent agent;
  RestfulApiService(this.agent);

  /// 发送Restful请求并返回转换后的结果
  /// @param request Restful API接口的请求对象
  /// @param onCancel 请求被取消时的回调函数对象
  /// @return 从response body转换后的数据的[CancelableFuture]对象
  CancelableFuture<V> sendRequest<V>(Request request,
      [OnCancelRequest onCancel]) {
    Converter<HttpBody, FutureOr<V>> converter =
        agent.convFactoryManager.getResponseConverter(V);
    if (converter == null) {
      if (V == Uint8List) {
        converter = (body) => (body.toBytes()) as FutureOr<V>;
      } else if (V == String) {
        converter = (body) => (body.bytesToString()) as FutureOr<V>;
      } else if (V == _typeOf<Stream<Uint8List>>()) {
        converter = (body) => body.contentStream as V;
      } else {
        throw RestfulException("Failed to find response converter");
      }
    }
    Response response;
    final future = agent.client.execute(request);
    final completer = CancelableCompleter<V>(() {
      // TODO 取消请求
      onCancel?.call(request, response);
      future.cancel();
    });
    completer.complete(future.then((r) {
      response = r;
      return converter(r.body);
    }));
    return completer.future;
  }
}
