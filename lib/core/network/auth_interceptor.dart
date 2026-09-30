import 'package:dio/dio.dart';
import '../../auth/auth_service.dart';

class AuthInterceptor extends Interceptor {
  final AuthService _authService;
  final Dio _dio;

  AuthInterceptor(this._authService, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _authService.currentToken?.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // If this request is already a retry after refresh, don't retry again
    // to prevent infinite loops.
    if (err.requestOptions.extra['isRetry'] == true) {
      return handler.next(err);
    }

    // Only handle 401 errors
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Don't try to refresh if the failing request IS the refresh request itself
    if (err.requestOptions.path.endsWith('/auth/refresh')) {
      return handler.next(err);
    }

    try {
      final newToken = await _authService.refreshToken();

      if (newToken != null) {
        // Clone the request options to avoid mutating the original
        final RequestOptions requestOptions = RequestOptions(
          method: err.requestOptions.method,
          path: err.requestOptions.path,
          data: err.requestOptions.data,
          queryParameters: Map<String, dynamic>.from(
            err.requestOptions.queryParameters,
          ),
          headers: Map<String, dynamic>.from(err.requestOptions.headers),
          baseUrl: err.requestOptions.baseUrl,
          connectTimeout: err.requestOptions.connectTimeout,
          sendTimeout: err.requestOptions.sendTimeout,
          receiveTimeout: err.requestOptions.receiveTimeout,
          responseType: err.requestOptions.responseType,
          contentType: err.requestOptions.contentType,
          followRedirects: err.requestOptions.followRedirects,
          receiveDataWhenStatusError: err.requestOptions.receiveDataWhenStatusError,
          extra: Map<String, dynamic>.from(err.requestOptions.extra),
        );

        requestOptions.headers['Authorization'] =
            'Bearer ${newToken.accessToken}';
        requestOptions.extra['isRetry'] = true;

        // Use handler.resolve to retry the request with the new token
        final response = await _dio.fetch(requestOptions);
        return handler.resolve(response);
      }
    } on DioException catch (_) {
      // If the retry also fails, pass the original error along
      return handler.next(err);
    } catch (e) {
      return handler.next(err);
    }

    // Token refresh returned null (failed), pass the original error
    return handler.next(err);
  }
}
