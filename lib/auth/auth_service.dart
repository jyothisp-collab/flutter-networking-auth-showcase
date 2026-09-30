import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'auth_token.dart';
import '../core/network/fake_http_adapter.dart';
import '../core/network/api_exceptions.dart';

class AuthService extends ChangeNotifier {
  final Dio _dio;
  AuthToken? _currentToken;
  bool _isLoading = false;
  Completer<AuthToken?>? _refreshCompleter;

  AuthService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.example.com',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        ) {
    _dio.httpClientAdapter = FakeHttpClientAdapter();
  }

  AuthToken? get currentToken => _currentToken;
  bool get isAuthenticated => _currentToken != null && !_currentToken!.hasExpired;
  bool get isLoading => _isLoading;

  Future<void> login(String username, String password) async {
    _setLoading(true);
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        _currentToken = AuthToken.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
        notifyListeners();
      }
    } on DioException catch (e) {
      _currentToken = null;
      notifyListeners();
      throw _mapLoginError(e);
    } catch (e) {
      _currentToken = null;
      notifyListeners();
      throw AuthException('Login failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthToken?> refreshToken() async {
    if (_currentToken == null) return null;

    // If a refresh is already in progress, return the existing future.
    // This prevents multiple concurrent refresh calls from the interceptor.
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<AuthToken?>();

    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': _currentToken!.refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        _currentToken = AuthToken.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
        _refreshCompleter!.complete(_currentToken);
        notifyListeners();
        return _currentToken;
      }

      _refreshCompleter!.complete(null);
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _currentToken = null;
        notifyListeners();
      }
      _refreshCompleter!.completeError(e);
      return null;
    } catch (e) {
      _refreshCompleter!.completeError(e);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  void logout() {
    _currentToken = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Exception _mapLoginError(DioException e) {
    if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        return AuthException('Invalid username or password.');
      }
      if (statusCode != null) {
        return AuthException('Server error: $statusCode');
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return AuthException('Connection timed out. Please try again.');
    }
    return AuthException('Login failed. Please check your connection.');
  }
}
