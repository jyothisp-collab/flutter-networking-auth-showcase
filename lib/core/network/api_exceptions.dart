import 'package:dio/dio.dart';

abstract class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException() : super('No internet connection or network failure.');
}

class TimeoutException extends ApiException {
  TimeoutException() : super('The connection timed out.');
}

class UnauthorizedException extends ApiException {
  UnauthorizedException() : super('Unauthorized. Please log in again.');
}

class ServerException extends ApiException {
  ServerException(super.message);
}

class UnknownException extends ApiException {
  UnknownException() : super('An unknown error occurred.');
}

class ExceptionHandler {
  static ApiException handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return TimeoutException();
        case DioExceptionType.connectionError:
          return NetworkException();
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 401) {
            return UnauthorizedException();
          }
          return ServerException(
            error.response?.data?['error'] ?? 'Server error: $statusCode',
          );
        default:
          return UnknownException();
      }
    }
    return UnknownException();
  }
}
