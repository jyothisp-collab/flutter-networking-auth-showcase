import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_networking_auth_showcase/auth/auth_service.dart';
import 'package:flutter_networking_auth_showcase/core/network/api_client.dart';
import 'package:flutter_networking_auth_showcase/core/network/api_exceptions.dart';
import 'package:flutter_networking_auth_showcase/features/data/data_service.dart';

void main() {
  late AuthService authService;
  late ApiClient apiClient;
  late DataService dataService;

  setUp(() {
    authService = AuthService();
    apiClient = ApiClient(authService);
    dataService = DataService(apiClient);
  });

  group('Authentication Flow & Token Refresh', () {
    test('login returns tokens and updates auth state', () async {
      expect(authService.isAuthenticated, false);

      await authService.login('test', 'password');

      expect(authService.isAuthenticated, true);
      expect(authService.currentToken, isNotNull);
      expect(authService.currentToken!.accessToken, 'access_token_expired');
    });

    test(
      'accessing protected data without auth throws UnauthorizedException',
      () async {
        expect(
          () => dataService.getProtectedData(),
          throwsA(isA<UnauthorizedException>()),
        );
      },
    );

    test(
      'accessing protected data with expired token triggers refresh and succeeds',
      () async {
        // 1. Login to get the initially "expired" token
        await authService.login('test', 'password');
        expect(authService.currentToken!.accessToken, 'access_token_expired');

        // 2. Fetch protected data
        // AuthInterceptor should catch the 401, refresh token, and retry
        final data = await dataService.getProtectedData();

        // 3. Verify data was returned and token was updated
        expect(data.id, 1);
        expect(authService.currentToken!.accessToken, 'access_token_valid');
      },
    );
  });

  group('API Client Behavior', () {
    test('accessing public data works without authentication', () async {
      final data = await dataService.getPublicData();

      expect(data.id, 100);
      expect(data.title, 'Public Data');
    });

    test('creating public data (POST) works correctly', () async {
      final data = await dataService.createPublicData('New Post');

      expect(data.id, 101);
      expect(data.title, 'New Post');
    });
  });
}
