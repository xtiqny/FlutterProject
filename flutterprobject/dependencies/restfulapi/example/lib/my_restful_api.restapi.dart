// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_restful_api.dart';

// **************************************************************************
// RestfulServiceGenerator
// **************************************************************************

class MyRestfulServiceImpl extends MyRestfulService {
  MyRestfulServiceImpl(RestfulAgent agent) : super(agent);

  @override
  CancelableFuture<String> sayHello(String message, int size,
      {String extra, String key}) {
    var genUrl = agent.baseUrl.resolve('http://www.test.nouse/sayHello');

    final genHeaders = HttpHeaders();
    genHeaders.add("X-key", key);
    genHeaders.add("X-request-id", "1234");
    final queryBuffer = StringBuffer();
    queryBuffer.write('msg=${Uri.encodeQueryComponent(message)}');
    genUrl = genUrl.replace(query: queryBuffer.toString());
    final genRequest = Request('GET', genUrl, headers: genHeaders);
    return sendRequest(genRequest);
  }

  @override
  CancelableFuture<Future<int>> sayHi(String message,
      [int size, String extra, String info]) {
    var genUrl = agent.baseUrl.resolve('/sayHi');

    final queryBuffer = StringBuffer();
    queryBuffer.write('msg=${Uri.encodeQueryComponent(message)}');
    genUrl = genUrl.replace(query: queryBuffer.toString());
    final genRequest = Request('POST', genUrl);
    return sendRequest(genRequest);
  }

  @override
  CancelableFuture<void> sayGoodBye({String extra, String key}) {
    var genUrl = agent.baseUrl.resolve('/sayGoodBye');

    final genContentType = 'application/x-www-form-urlencoded';
    final genContent = utf8.encode(
            'ex=${Uri.encodeQueryComponent(extra)}&key=${Uri.encodeQueryComponent(key)}')
        as Uint8List;
    final genBody = HttpBody.fromBytes(genContentType, genContent);
    final genRequest = Request('POST', genUrl, body: genBody);
    return sendRequest(genRequest);
  }

  @override
  CancelableFuture<Uint8List> saySomething(
      String friend, int content, String requestId,
      [FutureOr<dynamic> Function(Request request, [Response response])
          onCancelRequest]) {
    var genUrl = agent.baseUrl.resolve('/saySomething/$friend');

    final genHeaders = HttpHeaders();
    genHeaders.add("X-requestId", requestId);
    genHeaders.add("Date", "2019-7-1");
    final genBody =
        agent.convFactoryManager.getRequestConverter(int)?.call(content);
    final genRequest =
        Request('PUT', genUrl, headers: genHeaders, body: genBody);
    return sendRequest(genRequest, onCancelRequest);
  }
}
