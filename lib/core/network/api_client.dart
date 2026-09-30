import 'package:dio/dio.dart';
import 'auth_interceptor.dart';
import 'fake_http_adapter.dart';
import '../../auth/auth_service.dart';

class ApiClient {
  late final Dio dio;

  ApiClient(AuthService authService) {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.example.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.httpClientAdapter = FakeHttpClientAdapter();

    dio.interceptors.addAll([
      AuthInterceptor(authService, dio),
    ]);
  }
}
