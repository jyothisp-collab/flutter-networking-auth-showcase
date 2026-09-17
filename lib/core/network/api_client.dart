import 'package:dio/dio.dart';
import '../../auth/auth_service.dart';
import 'auth_interceptor.dart';
import 'fake_http_adapter.dart';

class ApiClient {
  late final Dio dio;

  ApiClient(AuthService authService) {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.example.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    // Use fake adapter for showcase purposes
    dio.httpClientAdapter = FakeHttpClientAdapter();

    dio.interceptors.addAll([
      AuthInterceptor(authService, dio),
      LogInterceptor(
        responseBody: true,
        requestBody: true,
      ), // Useful for debugging
    ]);
  }
}
