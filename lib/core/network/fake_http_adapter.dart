import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

/// A fake HttpClientAdapter to simulate API responses for this showcase.
/// It accurately mimics the behavior of a real network adapter.
class FakeHttpClientAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 100));

    final path = options.path;

    if (path.endsWith('/login')) {
      return _jsonResponse(200, {
        'access_token': 'access_token_expired',
        'refresh_token': 'refresh_token_valid',
      });
    }

    if (path.endsWith('/refresh')) {
      // Need to parse body for refresh
      String requestBody = '';
      if (options.data != null) {
        if (options.data is Map) {
          requestBody = jsonEncode(options.data);
        } else {
          requestBody = options.data.toString();
        }
      }

      if (requestBody.contains('refresh_token_valid')) {
        return _jsonResponse(200, {
          'access_token': 'access_token_valid',
          'refresh_token': 'refresh_token_valid',
        });
      }
      return _jsonResponse(401, {'error': 'Invalid refresh token'});
    }

    if (path.endsWith('/protected-data')) {
      final authHeader =
          options.headers['Authorization'] ?? options.headers['authorization'];

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

      return _jsonResponse(401, {'error': 'Unauthorized'});
    }

    if (path.endsWith('/public-data')) {
      if (options.method == 'POST') {
        // Mock POST body
        String title = 'Created Data';
        if (options.data is Map && options.data['title'] != null) {
          title = options.data['title'];
        }

        return _jsonResponse(201, {
          'id': 101,
          'title': title,
          'body': 'Successfully created new resource.',
        });
      }

      return _jsonResponse(200, {
        'id': 100,
        'title': 'Public Data',
        'body': 'Anyone can see this.',
      });
    }

    return _jsonResponse(404, {'error': 'Not found'});
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
