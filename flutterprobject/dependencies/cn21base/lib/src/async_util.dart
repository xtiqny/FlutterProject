import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

class IsolateServiceConfiguration {
  final SendPort initailReplyPort;
  final SendPort unhandleErrorPort;
  IsolateServiceConfiguration(this.initailReplyPort, [this.unhandleErrorPort]);
}

class _ResultSink<T> implements Sink<T> {
  _ResultSink(this.replyPort);
  final SendPort replyPort;
  final _completer = Completer();
  @override
  void add(T data) {
    replyPort.send([0, data]);
  }

  @override
  void close() {
    _completer.complete(null);
    replyPort.send([1]);
  }

  Future get done => _completer.future;
}

void _spawn(IsolateServiceConfiguration configuration) async {
  SendPort initailReplyPort = configuration.initailReplyPort;
  SendPort unhandleErrorPort = configuration.unhandleErrorPort;
  final receivePort = ReceivePort();
  initailReplyPort.send(receivePort.sendPort);
  await for (final req in receivePort) {
    SendPort replyPort;
    try {
      final respType = req[0];
      replyPort = req[1];
      final callback = req[2];
      final arg = req[3];
      if (respType == ExecRespType.normal) {
        final result = callback(arg);
        replyPort.send([0, result]);
      } else {
        final sink = _ResultSink(replyPort);
        callback(arg, sink);
        await sink.done;
      }
    } catch (e) {
      print('Exception in isolate. $e');
      if (replyPort != null) {
        replyPort.send([-1, e]);
      } else if (unhandleErrorPort != null) {
        unhandleErrorPort.send(e);
      }
    }
  }
}

enum ExecRespType { normal, stream }

class IsolateService {
  Isolate _isolate;
  SendPort _servPort;
  void initService() async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
        _spawn, IsolateServiceConfiguration(receivePort.sendPort));
    assert(_isolate == null);
    _isolate = isolate;
    SendPort servPort = await receivePort.first;
    _servPort = servPort;
  }

  Future<R> execute<Q, R>(ComputeCallback<Q, R> callback, Q message) async {
    final receivePort = ReceivePort();
    try {
      _servPort
          .send([ExecRespType.normal, receivePort.sendPort, callback, message]);
      List response = await receivePort.first;
      if (response[0] == 0) {
        // success
        R result = response[1];
        return result;
      } else {
        throw response[1];
      }
    } finally {
      receivePort.close();
    }
  }

  Stream<R> executeStream<Q, R>(void callback(Q message, Sink sink), Q message,
      [bool execOnlyOnListen = false]) {
    final receivePort = ReceivePort();
    bool executed = false;
    final controller = StreamController<R>(onListen: () {
      if (!executed) {
        _servPort.send(
            [ExecRespType.stream, receivePort.sendPort, callback, message]);
      }
    });
    if (!execOnlyOnListen) {
      executed = true;
      _servPort
          .send([ExecRespType.stream, receivePort.sendPort, callback, message]);
    }

    receivePort.listen((response) {
      final code = response[0];
      if (code == 0) {
        // success
        R result = response[1];
        controller.add(result);
      } else if (code == 1) {
        controller.close();
        receivePort.close();
      } else {
        controller.addError(response[1]);
        controller.close();
      }
    }, onError: (e, stackTrace) {
      controller.addError(e, stackTrace);
      controller.close();
      receivePort.close();
    }, onDone: () {
      controller.close();
    }, cancelOnError: true);

    return controller.stream;
  }
}
