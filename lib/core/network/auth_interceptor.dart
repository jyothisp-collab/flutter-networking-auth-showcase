import 'package:dio/dio.dart';
import '../../auth/auth_service.dart';

class AuthInterceptor extends Interceptor {
  final AuthService _authService;
  final Dio _dio;

  AuthInterceptor(this._authService, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _authService.currentToken?.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.requestOptions.extra['isRetry'] == true) {
      return handler.next(err);
    }

    if (err.response?.statusCode == 401) {
      if (err.requestOptions.path.endsWith('/refresh')) {
        return handler.next(err);
      }

      try {
        final newToken = await _authService.refreshToken();

        if (newToken != null) {
          final requestOptions = err.requestOptions;
          requestOptions.headers['Authorization'] =
              'Bearer ${newToken.accessToken}';
          requestOptions.extra['isRetry'] = true;

          final response = await _dio.fetch(requestOptions);
          return handler.resolve(response);
        }
      } on DioException catch (retryError) {
        return handler.next(retryError);
      } catch (e) {
        return handler.next(err);
      }
    }

    handler.next(err);
  }
}
