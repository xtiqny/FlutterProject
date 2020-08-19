class RestfulException implements Exception {
  final String message;

  /// The URL of the HTTP request or response that failed.
  final Uri uri;
  final int httpStatusCode;
  final String svrError;

  RestfulException(this.message,
      {this.uri, this.httpStatusCode, this.svrError});

  String toString() => message;
}
