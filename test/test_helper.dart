import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

final Uint8List kTransparentImage = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89,
  0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54,
  0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05,
  0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4,
  0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44,
  0xAE, 0x42, 0x60, 0x82,
]);

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  bool autoUncompress = true;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) =>
      Future.value(_MockHttpClientRequest(url));

  @override
  Future<HttpClientRequest> postUrl(Uri url) =>
      Future.value(_MockHttpClientRequest(url));

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      Future.value(_MockHttpClientRequest(url));
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final Uri uri;
  final HttpHeaders _headers = _MockHttpHeaders();

  _MockHttpClientRequest(this.uri);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  HttpHeaders get headers => _headers;

  @override
  void add(List<int> data) {}

  @override
  void write(Object? obj) {}

  @override
  Future<HttpClientResponse> close() =>
      Future.value(_MockHttpClientResponse());

  @override
  Future<HttpClientResponse> get done => close();
}

class _MockHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  final int statusCode = 200;

  @override
  final String reasonPhrase = 'OK';

  @override
  final int contentLength = kTransparentImage.length;

  @override
  final HttpClientResponseCompressionState compressionState =
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  final Map<String, List<String>> _data = {
    'content-type': ['image/png'],
  };

  @override
  List<String>? operator [](String name) => _data[name.toLowerCase()];

  @override
  String? value(String name) => _data[name.toLowerCase()]?.first;

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _data.putIfAbsent(name.toLowerCase(), () => []).add(value.toString());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _data[name.toLowerCase()] = [value.toString()];
  }

  @override
  ContentType? contentType = ContentType.parse('image/png');
}
