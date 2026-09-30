import 'package:dio/dio.dart';

/// Base class for all API exceptions.
abstract class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Network-level failure (no internet, DNS failure, connection error, etc.).
class NetworkException extends ApiException {
  const NetworkException() : super('No internet connection or network failure.');
}

/// Request timed out at any stage.
class TimeoutException extends ApiException {
  const TimeoutException() : super('The connection timed out.');
}

/// Server returned an error response.
class ServerException extends ApiException {
  final int? statusCode;

  const ServerException(
    super.message, {
    this.statusCode,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'ServerException($statusCode): $message';
    }
    return 'ServerException: $message';
  }
}

/// Authentication or authorization failure (401, 403).
class AuthException extends ApiException {
  const AuthException(super.message);
}

/// Catch-all for errors that don't fit other categories.
class UnknownException extends ApiException {
  const UnknownException(super.message);
}

/// Maps a [DioException] to the appropriate [ApiException] subtype.
class ExceptionHandler {
  static ApiException handle(dynamic error) {
    if (error is DioException) {
      return _handleDioException(error);
    }
    return const UnknownException('An unexpected error occurred.');
  }

  static ApiException _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const TimeoutException();
      case DioExceptionType.badCertificate:
      case DioExceptionType.connectionError:
      case DioExceptionType.cancel:
        return const NetworkException();
      case DioExceptionType.badResponse:
        return _handleBadResponse(error);
      case DioExceptionType.unknown:
        return const UnknownException('An unknown error occurred.');
    }
  }

  static ApiException _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;

    if (statusCode == 401 || statusCode == 403) {
      final errorMsg = _extractErrorFromResponse(error.response?.data);
      return AuthException(
        errorMsg ?? 'Unauthorized. Please log in again.',
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return ServerException(
        'Server error. Please try again later.',
        statusCode: statusCode,
      );
    }

    if (statusCode != null) {
      final errorMsg = _extractErrorFromResponse(error.response?.data) ??
          error.response?.statusMessage;
      return ServerException(
        errorMsg ?? 'Request failed with status $statusCode.',
        statusCode: statusCode,
      );
    }

    return const ServerException('Server returned an invalid response.');
  }

  static String? _extractErrorFromResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['error']?.toString() ?? data['message']?.toString();
    }
    return null;
  }
}
