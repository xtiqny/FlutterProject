import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'exception.dart';

class HttpHeaders {
  static const acceptHeader = "accept";
  static const acceptCharsetHeader = "accept-charset";
  static const acceptEncodingHeader = "accept-encoding";
  static const acceptLanguageHeader = "accept-language";
  static const acceptRangesHeader = "accept-ranges";
  static const ageHeader = "age";
  static const allowHeader = "allow";
  static const authorizationHeader = "authorization";
  static const cacheControlHeader = "cache-control";
  static const connectionHeader = "connection";
  static const contentEncodingHeader = "content-encoding";
  static const contentLanguageHeader = "content-language";
  static const contentLengthHeader = "content-length";
  static const contentLocationHeader = "content-location";
  static const contentMD5Header = "content-md5";
  static const contentRangeHeader = "content-range";
  static const contentTypeHeader = "content-type";
  static const dateHeader = "date";
  static const etagHeader = "etag";
  static const expectHeader = "expect";
  static const expiresHeader = "expires";
  static const fromHeader = "from";
  static const hostHeader = "host";
  static const ifMatchHeader = "if-match";
  static const ifModifiedSinceHeader = "if-modified-since";
  static const ifNoneMatchHeader = "if-none-match";
  static const ifRangeHeader = "if-range";
  static const ifUnmodifiedSinceHeader = "if-unmodified-since";
  static const lastModifiedHeader = "last-modified";
  static const locationHeader = "location";
  static const maxForwardsHeader = "max-forwards";
  static const pragmaHeader = "pragma";
  static const proxyAuthenticateHeader = "proxy-authenticate";
  static const proxyAuthorizationHeader = "proxy-authorization";
  static const rangeHeader = "range";
  static const refererHeader = "referer";
  static const retryAfterHeader = "retry-after";
  static const serverHeader = "server";
  static const teHeader = "te";
  static const trailerHeader = "trailer";
  static const transferEncodingHeader = "transfer-encoding";
  static const upgradeHeader = "upgrade";
  static const userAgentHeader = "user-agent";
  static const varyHeader = "vary";
  static const viaHeader = "via";
  static const warningHeader = "warning";
  static const wwwAuthenticateHeader = "www-authenticate";

  @Deprecated("Use acceptHeader instead")
  static const ACCEPT = acceptHeader;
  @Deprecated("Use acceptCharsetHeader instead")
  static const ACCEPT_CHARSET = acceptCharsetHeader;
  @Deprecated("Use acceptEncodingHeader instead")
  static const ACCEPT_ENCODING = acceptEncodingHeader;
  @Deprecated("Use acceptLanguageHeader instead")
  static const ACCEPT_LANGUAGE = acceptLanguageHeader;
  @Deprecated("Use acceptRangesHeader instead")
  static const ACCEPT_RANGES = acceptRangesHeader;
  @Deprecated("Use ageHeader instead")
  static const AGE = ageHeader;
  @Deprecated("Use allowHeader instead")
  static const ALLOW = allowHeader;
  @Deprecated("Use authorizationHeader instead")
  static const AUTHORIZATION = authorizationHeader;
  @Deprecated("Use cacheControlHeader instead")
  static const CACHE_CONTROL = cacheControlHeader;
  @Deprecated("Use connectionHeader instead")
  static const CONNECTION = connectionHeader;
  @Deprecated("Use contentEncodingHeader instead")
  static const CONTENT_ENCODING = contentEncodingHeader;
  @Deprecated("Use contentLanguageHeader instead")
  static const CONTENT_LANGUAGE = contentLanguageHeader;
  @Deprecated("Use contentLengthHeader instead")
  static const CONTENT_LENGTH = contentLengthHeader;
  @Deprecated("Use contentLocationHeader instead")
  static const CONTENT_LOCATION = contentLocationHeader;
  @Deprecated("Use contentMD5Header instead")
  static const CONTENT_MD5 = contentMD5Header;
  @Deprecated("Use contentRangeHeader instead")
  static const CONTENT_RANGE = contentRangeHeader;
  @Deprecated("Use contentTypeHeader instead")
  static const CONTENT_TYPE = contentTypeHeader;
  @Deprecated("Use dateHeader instead")
  static const DATE = dateHeader;
  @Deprecated("Use etagHeader instead")
  static const ETAG = etagHeader;
  @Deprecated("Use expectHeader instead")
  static const EXPECT = expectHeader;
  @Deprecated("Use expiresHeader instead")
  static const EXPIRES = expiresHeader;
  @Deprecated("Use fromHeader instead")
  static const FROM = fromHeader;
  @Deprecated("Use hostHeader instead")
  static const HOST = hostHeader;
  @Deprecated("Use ifMatchHeader instead")
  static const IF_MATCH = ifMatchHeader;
  @Deprecated("Use ifModifiedSinceHeader instead")
  static const IF_MODIFIED_SINCE = ifModifiedSinceHeader;
  @Deprecated("Use ifNoneMatchHeader instead")
  static const IF_NONE_MATCH = ifNoneMatchHeader;
  @Deprecated("Use ifRangeHeader instead")
  static const IF_RANGE = ifRangeHeader;
  @Deprecated("Use ifUnmodifiedSinceHeader instead")
  static const IF_UNMODIFIED_SINCE = ifUnmodifiedSinceHeader;
  @Deprecated("Use lastModifiedHeader instead")
  static const LAST_MODIFIED = lastModifiedHeader;
  @Deprecated("Use locationHeader instead")
  static const LOCATION = locationHeader;
  @Deprecated("Use maxForwardsHeader instead")
  static const MAX_FORWARDS = maxForwardsHeader;
  @Deprecated("Use pragmaHeader instead")
  static const PRAGMA = pragmaHeader;
  @Deprecated("Use proxyAuthenticateHeader instead")
  static const PROXY_AUTHENTICATE = proxyAuthenticateHeader;
  @Deprecated("Use proxyAuthorizationHeader instead")
  static const PROXY_AUTHORIZATION = proxyAuthorizationHeader;
  @Deprecated("Use rangeHeader instead")
  static const RANGE = rangeHeader;
  @Deprecated("Use refererHeader instead")
  static const REFERER = refererHeader;
  @Deprecated("Use retryAfterHeader instead")
  static const RETRY_AFTER = retryAfterHeader;
  @Deprecated("Use serverHeader instead")
  static const SERVER = serverHeader;
  @Deprecated("Use teHeader instead")
  static const TE = teHeader;
  @Deprecated("Use trailerHeader instead")
  static const TRAILER = trailerHeader;
  @Deprecated("Use transferEncodingHeader instead")
  static const TRANSFER_ENCODING = transferEncodingHeader;
  @Deprecated("Use upgradeHeader instead")
  static const UPGRADE = upgradeHeader;
  @Deprecated("Use userAgentHeader instead")
  static const USER_AGENT = userAgentHeader;
  @Deprecated("Use varyHeader instead")
  static const VARY = varyHeader;
  @Deprecated("Use viaHeader instead")
  static const VIA = viaHeader;
  @Deprecated("Use warningHeader instead")
  static const WARNING = warningHeader;
  @Deprecated("Use wwwAuthenticateHeader instead")
  static const WWW_AUTHENTICATE = wwwAuthenticateHeader;

  // Cookie headers from RFC 6265.
  static const cookieHeader = "cookie";
  static const setCookieHeader = "set-cookie";

  @Deprecated("Use cookieHeader instead")
  static const COOKIE = cookieHeader;
  @Deprecated("Use setCookieHeader instead")
  static const SET_COOKIE = setCookieHeader;

  static const generalHeaders = const [
    cacheControlHeader,
    connectionHeader,
    dateHeader,
    pragmaHeader,
    trailerHeader,
    transferEncodingHeader,
    upgradeHeader,
    viaHeader,
    warningHeader
  ];

  @Deprecated("Use generalHeaders instead")
  static const GENERAL_HEADERS = generalHeaders;

  static const entityHeaders = const [
    allowHeader,
    contentEncodingHeader,
    contentLanguageHeader,
    contentLengthHeader,
    contentLocationHeader,
    contentMD5Header,
    contentRangeHeader,
    contentTypeHeader,
    expiresHeader,
    lastModifiedHeader
  ];

  @Deprecated("Use entityHeaders instead")
  static const ENTITY_HEADERS = entityHeaders;

  static const responseHeaders = const [
    acceptRangesHeader,
    ageHeader,
    etagHeader,
    locationHeader,
    proxyAuthenticateHeader,
    retryAfterHeader,
    serverHeader,
    varyHeader,
    wwwAuthenticateHeader
  ];

  @Deprecated("Use responseHeaders instead")
  static const RESPONSE_HEADERS = responseHeaders;

  static const requestHeaders = const [
    acceptHeader,
    acceptCharsetHeader,
    acceptEncodingHeader,
    acceptLanguageHeader,
    authorizationHeader,
    expectHeader,
    fromHeader,
    hostHeader,
    ifMatchHeader,
    ifModifiedSinceHeader,
    ifNoneMatchHeader,
    ifRangeHeader,
    ifUnmodifiedSinceHeader,
    maxForwardsHeader,
    proxyAuthorizationHeader,
    rangeHeader,
    refererHeader,
    teHeader,
    userAgentHeader
  ];
  final Map<String, List<String>> _headers;

  HttpHeaders([Map<String, List<String>> headers])
      : _headers = headers ?? <String, List<String>>{};

  /// Returns the list of values for the header named [name]. If there
  /// is no header with the provided name, [:null:] will be returned.
  List<String> operator [](String name) => _headers[name];

  /// Returns the first value for the header named [name]. If there
  /// is no header with the provided name, null will be returned.
  String first(String name) {
    var values = _headers[name];
    if (values != null && values.isNotEmpty) {
      return values[0];
    }
    return null;
  }

  /// Adds a header value. The header named [name] will have the value
  /// [value] added to its list of values.
  void add(String name, String value) {
    var values = _headers[name];
    if (values == null) {
      values = <String>[value];
      _headers[name] = values;
    } else {
      values.add(value);
    }
  }

  /// Sets a header. The header named [name] will have all its values
  /// cleared before the value [value] is added as its value.
  void set(String name, Object value) {
    var values = _headers[name];
    if (values == null) {
      values = <String>[value];
      _headers[name] = values;
    } else {
      values.clear();
      values.add(value);
    }
  }

  /// Removes a specific value for a header name. Some headers have
  /// system supplied values and for these the system supplied values
  /// will still be added to the collection of values for the header.
  void remove(String name, String value) {
    var values = _headers[name];
    if (values != null) {
      values.removeWhere((v) => v == value);
    }
  }

  /// Removes all values for the specified header name. Some headers
  /// have system supplied values and for these the system supplied
  /// values will still be added to the collection of values for the
  /// header.
  void removeAll(String name) {
    _headers.remove(name);
  }

  /// Enumerates the headers, applying the function [f] to each
  /// header. The header name passed in [:name:] will be all lower
  /// case.
  void forEach(void f(String name, List<String> values)) {
    _headers.forEach(f);
  }

  /// Remove all headers. Some headers have system supplied values and
  /// for these the system supplied values will still be added to the
  /// collection of values for the header.
  void clear() {
    _headers.clear();
  }
}

class HeaderValue {
  String _value;
  Map<String, String> _parameters;
  Map<String, String> _unmodifiableParameters;

  HeaderValue([this._value = "", Map<String, String> parameters]) {
    if (parameters != null) {
      _parameters = new HashMap<String, String>.from(parameters);
    }
  }

  static HeaderValue parse(String value,
      {parameterSeparator: ";",
      valueSeparator: null,
      preserveBackslash: false}) {
    // Parse the string.
    var result = new HeaderValue();
    result._parse(value, parameterSeparator, valueSeparator, preserveBackslash);
    return result;
  }

  String get value => _value;

  void _ensureParameters() {
    if (_parameters == null) {
      _parameters = new HashMap<String, String>();
    }
  }

  Map<String, String> get parameters {
    _ensureParameters();
    if (_unmodifiableParameters == null) {
      _unmodifiableParameters = new UnmodifiableMapView(_parameters);
    }
    return _unmodifiableParameters;
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(_value);
    if (parameters != null && parameters.length > 0) {
      _parameters.forEach((String name, String value) {
        sb..write("; ")..write(name)..write("=")..write(value);
      });
    }
    return sb.toString();
  }

  void _parse(String s, String parameterSeparator, String valueSeparator,
      bool preserveBackslash) {
    int index = 0;

    bool done() => index == s.length;

    void skipWS() {
      while (!done()) {
        if (s[index] != " " && s[index] != "\t") return;
        index++;
      }
    }

    String parseValue() {
      int start = index;
      while (!done()) {
        if (s[index] == " " ||
            s[index] == "\t" ||
            s[index] == valueSeparator ||
            s[index] == parameterSeparator) break;
        index++;
      }
      return s.substring(start, index);
    }

    void expect(String expected) {
      if (done() || s[index] != expected) {
        throw new RestfulException("Failed to parse header value");
      }
      index++;
    }

    void maybeExpect(String expected) {
      if (s[index] == expected) index++;
    }

    void parseParameters() {
      var parameters = new HashMap<String, String>();
      _parameters = new UnmodifiableMapView(parameters);

      String parseParameterName() {
        int start = index;
        while (!done()) {
          if (s[index] == " " ||
              s[index] == "\t" ||
              s[index] == "=" ||
              s[index] == parameterSeparator ||
              s[index] == valueSeparator) break;
          index++;
        }
        return s.substring(start, index).toLowerCase();
      }

      String parseParameterValue() {
        if (!done() && s[index] == "\"") {
          // Parse quoted value.
          StringBuffer sb = new StringBuffer();
          index++;
          while (!done()) {
            if (s[index] == "\\") {
              if (index + 1 == s.length) {
                throw new RestfulException("Failed to parse header value");
              }
              if (preserveBackslash && s[index + 1] != "\"") {
                sb.write(s[index]);
              }
              index++;
            } else if (s[index] == "\"") {
              index++;
              break;
            }
            sb.write(s[index]);
            index++;
          }
          return sb.toString();
        } else {
          // Parse non-quoted value.
          var val = parseValue();
          return val == "" ? null : val;
        }
      }

      while (!done()) {
        skipWS();
        if (done()) return;
        String name = parseParameterName();
        skipWS();
        if (done()) {
          parameters[name] = null;
          return;
        }
        maybeExpect("=");
        skipWS();
        if (done()) {
          parameters[name] = null;
          return;
        }
        String value = parseParameterValue();
        if (name == 'charset' && this is ContentType && value != null) {
          // Charset parameter of ContentTypes are always lower-case.
          value = value.toLowerCase();
        }
        parameters[name] = value;
        skipWS();
        if (done()) return;
        // TODO: Implement support for multi-valued parameters.
        if (s[index] == valueSeparator) return;
        expect(parameterSeparator);
      }
    }

    skipWS();
    _value = parseValue();
    skipWS();
    if (done()) return;
    maybeExpect(parameterSeparator);
    parseParameters();
  }
}

class ContentType extends HeaderValue {
  String _primaryType = "";
  String _subType = "";

  ContentType(String primaryType, String subType, String charset,
      Map<String, String> parameters)
      : _primaryType = primaryType,
        _subType = subType,
        super("") {
    if (_primaryType == null) _primaryType = "";
    if (_subType == null) _subType = "";
    _value = "$_primaryType/$_subType";
    if (parameters != null) {
      _ensureParameters();
      parameters.forEach((String key, String value) {
        String lowerCaseKey = key.toLowerCase();
        if (lowerCaseKey == "charset") {
          value = value.toLowerCase();
        }
        this._parameters[lowerCaseKey] = value;
      });
    }
    if (charset != null) {
      _ensureParameters();
      this._parameters["charset"] = charset.toLowerCase();
    }
  }

  ContentType._();

  static ContentType parse(String value) {
    var result = new ContentType._();
    result._parse(value, ";", null, false);
    int index = result._value.indexOf("/");
    if (index == -1 || index == (result._value.length - 1)) {
      result._primaryType = result._value.trim().toLowerCase();
      result._subType = "";
    } else {
      result._primaryType =
          result._value.substring(0, index).trim().toLowerCase();
      result._subType = result._value.substring(index + 1).trim().toLowerCase();
    }
    return result;
  }

  String get mimeType => '$primaryType/$subType';

  String get primaryType => _primaryType;

  String get subType => _subType;

  String get charset => parameters["charset"];
}

/// Restful Request请求类
class Request {
  /// The HTTP method of the request. Most commonly "GET" or "POST", less
  /// commonly "HEAD", "PUT", or "DELETE". Non-standard method names are also
  /// supported.
  final String method;

  /// The URL to which the request will be sent.
  final Uri url;

  /// The headers for this request.
  final HttpHeaders headers;

  final HttpBody body;

  /// Creates a new HTTP request.
  Request(this.method, this.url, {this.headers, this.body});

  String toString() => "$method $url";
}

/// HTTP的BODY类
class HttpBody {
  HttpBody(this.contentType, this.contentStream, [this.contentLength = -1]);
  HttpBody.fromBytes(this.contentType, Uint8List bytes,
      [this.contentLength = -1])
      : contentStream = Stream.fromIterable([bytes]),
        _bytes = bytes;
  final String contentType;

  /// Returns the number of bytes in that will returned by {@link #bytes}, or {@link #byteStream}, or
  /// -1 if unknown.
  final int contentLength;

  /// The content of this body
  final Stream<Uint8List> contentStream;

  /// When this is not null, it contains all body content an can be returned
  /// at once if the user call toBytes()
  Uint8List _bytes;
  bool get isAllBuffered => _bytes != null;

  /// Get all content as byte array
  /// If the content had been received, it returns the content at once,
  /// otherwise, it returns a [Future]
  FutureOr<Uint8List> toBytes() {
    if (_bytes != null) {
      return _bytes;
    } else {
      var completer = Completer<Uint8List>();
      var sink = ByteConversionSink.withCallback(
          (bytes) => completer.complete((_bytes = Uint8List.fromList(bytes))));
      contentStream.listen(sink.add,
          onError: completer.completeError,
          onDone: sink.close,
          cancelOnError: true);
      return completer.future;
    }
  }

  /// Collect the data of this stream in a [String], decoded according to
  /// [encoding], which defaults to `UTF8`.
  /// If the content had been received, it returns the content at once,
  /// otherwise, it returns a [Future]
  FutureOr<String> bytesToString([Encoding encoding = utf8]) {
    if (_bytes != null) {
      return encoding.decode(_bytes);
    }
    return (contentStream != null)
        ? encoding.decodeStream(contentStream)
        : null;
  }

  /// Get all decoded [String] content as a [Stream], decoded according to
  /// [encoding], which defaults to `UTF8`.
  Stream<String> toStringStream([Encoding encoding = utf8]) {
    if (_bytes != null) {
      return Stream.fromIterable([encoding.decode(_bytes)]);
    }
    return (contentStream != null)
        ? encoding.decoder.bind(contentStream)
        : null;
  }
}

/// Restful的响应类
class Response {
  Response(this.request, this.statusCode,
      {this.reasonPhrase, this.headers, this.body});

  /// The (frozen) request that triggered this response.
  final Request request;

  /// The status code of the response.
  final int statusCode;

  /// The reason phrase associated with the status code.
  final String reasonPhrase;

  /// The headers for this response.
  final HttpHeaders headers;

  final HttpBody body;
}
