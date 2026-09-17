import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/network/fake_http_adapter.dart';
import 'auth_token.dart';

class AuthService extends ChangeNotifier {
  final Dio _dio;
  AuthToken? _currentToken;
  bool _isLoading = false;

  AuthService() : _dio = Dio() {
    _dio.httpClientAdapter = FakeHttpClientAdapter();
    _dio.options.baseUrl = 'https://api.example.com';
  }

  AuthToken? get currentToken => _currentToken;
  bool get isAuthenticated => _currentToken != null;
  bool get isLoading => _isLoading;

  Future<void> login(String username, String password) async {
    _setLoading(true);
    try {
      final response = await _dio.post(
        '/login',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        _currentToken = AuthToken.fromJson(
          Map<String, dynamic>.from(response.data),
        );
        notifyListeners();
      }
    } catch (e) {
      _currentToken = null;
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthToken?> refreshToken() async {
    if (_currentToken == null) return null;

    try {
      final response = await _dio.post(
        '/refresh',
        data: {'refresh_token': _currentToken!.refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        _currentToken = AuthToken.fromJson(
          Map<String, dynamic>.from(response.data),
        );
        notifyListeners();
        return _currentToken;
      }
    } catch (e) {
      logout();
    }
    return null;
  }

  void logout() {
    _currentToken = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
