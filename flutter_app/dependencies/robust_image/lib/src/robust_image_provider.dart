import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'robust_image_engine.dart';
import 'robust_image_module.dart';

typedef RenderRequestBuilder = RenderRequest Function(
  RobustImageProvider imageProvider,
  ImageConfiguration configuration,
);

class RobustImageProvider<T extends RobustImageKey> extends ImageProvider<T> {
  final RobustImageEngine engine;
  RenderRequest request;
  ImageConfiguration _curImageConfig;
  final RenderRequestBuilder requestBuilder;

  /// 此Provider的tag标识，tag相同表示provider所要提供的
  /// 图像内容相同，因此通常可以直接以[RobustImageKey]作为tag
  final dynamic tag;
  RobustImageProvider(this.engine, this.requestBuilder, {this.tag})
      : assert(engine != null),
        super();

  @override
  ImageStream resolve(ImageConfiguration configuration) {
    assert(configuration != null);
//    if (_request == null || _curImageConfig != configuration) {
//      _request = requestBuilder(configuration);
//      assert(_request != null);
//      _curImageConfig = configuration;
//    }
    request = requestBuilder(this, configuration);
    final ImageStream stream = ImageStream();
    Future<void> handleError(dynamic exception, StackTrace stack) async {
      await null; // wait an event turn in case a listener has been added to the image stream.
      final _ErrorImageCompleter imageCompleter = _ErrorImageCompleter();
      stream.setCompleter(imageCompleter);
      imageCompleter.setError(
        exception: exception,
        stack: stack,
        context: DiagnosticsNode.message('while resolving an image'),
        silent: true, // could be a network error or whatnot
        informationCollector: () {
          return [
            DiagnosticsNode.message(
                'Image provider: $this, Image configuration: $configuration, Image key: ${request?.key}')
          ];
        },
      );
    }

    final ImageStreamCompleter completer =
        engine.resolve(request, onError: handleError);
    if (completer != null) {
      stream.setCompleter(completer);
    }

    return stream;
  }

  @override
  ImageStreamCompleter load(T key, DecoderCallback decode) {
    assert(false,
        'Since we override the resolve method, this method should never be called. ');
    assert(request != null);
    return engine.resolve(request);
  }

  @override
  Future<T> obtainKey(ImageConfiguration configuration) {
    if (request == null || _curImageConfig != configuration) {
      request = requestBuilder(this, configuration);
      assert(request != null);
      _curImageConfig = configuration;
    }
    return Future.value(request.key as T);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RobustImageProvider &&
          runtimeType == other.runtimeType &&
          engine == other.engine &&
          tag != null &&
          other.tag != null &&
          tag == other.tag;

  @override
  int get hashCode => (tag != null) ? tag.hashCode : super.hashCode;
}

// A completer used when resolving an image fails sync.
class _ErrorImageCompleter extends ImageStreamCompleter {
  _ErrorImageCompleter();

  void setError({
    DiagnosticsNode context,
    dynamic exception,
    StackTrace stack,
    InformationCollector informationCollector,
    bool silent = false,
  }) {
    reportError(
      context: context,
      exception: exception,
      stack: stack,
      informationCollector: informationCollector,
      silent: silent,
    );
  }
}
