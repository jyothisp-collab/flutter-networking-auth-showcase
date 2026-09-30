import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

/// Fake [HttpClientAdapter] that intercepts requests and returns canned
/// responses with a simulated network delay.
class FakeHttpClientAdapter implements HttpClientAdapter {
  static const _networkDelay = Duration(milliseconds: 200);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future.delayed(_networkDelay);

    if (cancelFuture != null) {
      await cancelFuture;
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.cancel,
      );
    }

    return _dispatch(options);
  }

  ResponseBody _dispatch(RequestOptions options) {
    final path = options.path;
    final method = options.method.toUpperCase();

    // Auth endpoints
    if (_matches(path, '/auth/login')) {
      if (method == 'POST') {
        return _jsonResponse(200, {
          'access_token': 'access_token_expired',
          'refresh_token': 'refresh_token_valid',
        });
      }
      return _jsonResponse(405, {'error': 'Method not allowed'});
    }

    if (_matches(path, '/auth/refresh')) {
      if (method == 'POST') {
        final body = _extractRequestBody(options);
        if (body.contains('refresh_token_valid')) {
          return _jsonResponse(200, {
            'access_token': 'access_token_valid',
            'refresh_token': 'refresh_token_valid',
            'expires_at': DateTime.now()
                .add(const Duration(hours: 1))
                .toIso8601String(),
          });
        }
        return _jsonResponse(401, {'error': 'Invalid refresh token'});
      }
      return _jsonResponse(405, {'error': 'Method not allowed'});
    }

    // Public data endpoints
    if (_matches(path, '/public-data')) {
      if (method == 'GET') {
        return _jsonResponse(200, {
          'id': 100,
          'title': 'Public Data',
          'body': 'Anyone can see this.',
        });
      }
      if (method == 'POST') {
        final title = _extractTitleFromBody(options.data);
        return _jsonResponse(201, {
          'id': 101,
          'title': title,
          'body': 'Successfully created new resource.',
        });
      }
      return _jsonResponse(405, {'error': 'Method not allowed'});
    }

    // Protected data — requires a valid Bearer token
    if (_matches(path, '/protected-data')) {
      if (method == 'GET') {
        final authHeader = options.headers['Authorization']
                as String? ??
            options.headers['authorization'] as String?;

        if (authHeader == 'Bearer access_token_valid') {
          return _jsonResponse(200, {
            'id': 1,
            'title': 'Secret Protected Data',
            'body': 'This was fetched using a valid access token.',
          });
        }

        if (authHeader == 'Bearer access_token_expired') {
          return _jsonResponse(401, {'error': 'Token expired'});
        }

        return _jsonResponse(401, {'error': 'Missing or invalid Authorization header'});
      }
      return _jsonResponse(405, {'error': 'Method not allowed'});
    }

    return _jsonResponse(404, {'error': 'Not found: $path'});
  }

  bool _matches(String path, String suffix) {
    return path == suffix || path.endsWith(suffix);
  }

  String _extractRequestBody(dynamic data) {
    if (data == null) return '';
    if (data is Map) return jsonEncode(data);
    return data.toString();
  }

  String _extractTitleFromBody(dynamic data) {
    if (data is Map && data['title'] is String) {
      return data['title'] as String;
    }
    return 'Created Data';
  }

  ResponseBody _jsonResponse(int statusCode, Map<String, dynamic> data) {
    final bodyStr = jsonEncode(data);
    return ResponseBody.fromString(
      bodyStr,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
