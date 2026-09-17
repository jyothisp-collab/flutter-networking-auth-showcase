import 'package:dio/dio.dart';
import '../../auth/auth_service.dart';

/// Intercepts requests to inject the access token, and handles 401 Unauthorized
/// by attempting to refresh the token and retrying the request.
class AuthInterceptor extends Interceptor {
  final AuthService _authService;
  final Dio _dio;

  AuthInterceptor(this._authService, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Only inject token if we have one (authenticated user)
    final token = _authService.currentToken?.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Proceed with the request
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Prevent infinite loops if the retry itself returns 401
    if (err.requestOptions.extra['isRetry'] == true) {
      return handler.next(err);
    }

    // If the error is 401 Unauthorized, we attempt to refresh the token
    if (err.response?.statusCode == 401) {
      // Avoid infinite loops if refresh endpoint itself returns 401
      if (err.requestOptions.path.endsWith('/refresh')) {
        return handler.next(err);
      }

      try {
        // Attempt to refresh the token
        final newToken = await _authService.refreshToken();

        if (newToken != null) {
          // Retry the original request with the new token
          final requestOptions = err.requestOptions;
          requestOptions.headers['Authorization'] =
              'Bearer ${newToken.accessToken}';
          requestOptions.extra['isRetry'] = true;

          // Create a new request based on the old one
          final response = await _dio.fetch(requestOptions);
          return handler.resolve(response);
        }
      } on DioException catch (retryError) {
        // If the retry itself fails, pass that error forward
        return handler.next(retryError);
      } catch (e) {
        // Any other exception during refresh, let the original error through
        return handler.next(err);
      }
    }

    // If it's not a 401 or refresh failed, pass the error forward
    handler.next(err);
  }
}
