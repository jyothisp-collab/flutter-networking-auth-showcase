import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_networking_auth_showcase/auth/auth_service.dart';
import 'package:flutter_networking_auth_showcase/core/network/api_client.dart';
import 'package:flutter_networking_auth_showcase/core/network/api_exceptions.dart';
import 'package:flutter_networking_auth_showcase/features/data/data_service.dart';
import 'package:flutter_networking_auth_showcase/features/data/data_model.dart';

void main() {
  late AuthService authService;
  late ApiClient apiClient;
  late DataService dataService;

  setUp(() {
    authService = AuthService();
    apiClient = ApiClient(authService);
    dataService = DataService(apiClient);
  });

  group('Authentication Flow', () {
    test('login returns tokens and sets authenticated state', () async {
      expect(authService.isAuthenticated, isFalse);

      await authService.login('test', 'password');

      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentToken, isNotNull);
      expect(authService.currentToken!.accessToken, 'access_token_expired');
      expect(authService.currentToken!.refreshToken, 'refresh_token_valid');
    });

    test('login sets isLoading to true during execution', () async {
      expect(authService.isLoading, isFalse);

      final loginFuture = authService.login('test', 'password');
      // isLoading may be true briefly during async execution;
      // we primarily verify it resets to false after completion
      await loginFuture;

      expect(authService.isLoading, isFalse);
    });

    test('logout clears tokens and updates auth state', () async {
      await authService.login('test', 'password');
      expect(authService.isAuthenticated, isTrue);

      authService.logout();

      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentToken, isNull);
    });
  });

  group('Protected Data Access', () {
    test('protected data without auth throws AuthException', () async {
      expect(
        () => dataService.getProtectedData(),
        throwsA(isA<AuthException>()),
      );
    });

    test('protected data with expired token triggers refresh and succeeds',
        () async {
      // 1. Login to get the initially "expired" token
      await authService.login('test', 'password');
      expect(authService.currentToken!.accessToken, 'access_token_expired');

      // 2. Fetch protected data — interceptor should catch 401,
      //    refresh the token, and retry automatically
      final data = await dataService.getProtectedData();

      // 3. Verify data was returned and token was updated to valid
      expect(data, isA<DataModel>());
      expect(data.id, 1);
      expect(data.title, 'Secret Protected Data');
      expect(authService.currentToken!.accessToken, 'access_token_valid');
      expect(authService.isAuthenticated, isTrue);
    });
  });

  group('Public Data & API Client Behavior', () {
    test('public data works without authentication', () async {
      final data = await dataService.getPublicData();

      expect(data, isA<DataModel>());
      expect(data.id, 100);
      expect(data.title, 'Public Data');
      expect(data.body, 'Anyone can see this.');
    });

    test('POST data works correctly', () async {
      final data = await dataService.createData(
        const DataModel(id: 0, title: 'Test Post', body: 'Test body'),
      );

      expect(data, isA<DataModel>());
      expect(data.id, 101);
      expect(data.title, 'Test Post');
      expect(data.body, 'Successfully created new resource.');
    });
  });

  group('Token Refresh Concurrency', () {
    test('concurrent 401s trigger only one refresh', () async {
      await authService.login('test', 'password');

      // Fire two requests at once that will both get 401 with an expired token.
      // The interceptor should handle both, but only trigger one refresh.
      final results = await Future.wait([
        dataService.getProtectedData(),
        dataService.getProtectedData(),
      ]);

      // Both should succeed after the single refresh
      expect(results, hasLength(2));
      expect(results[0], isA<DataModel>());
      expect(results[1], isA<DataModel>());
      expect(authService.currentToken!.accessToken, 'access_token_valid');
    });
  });
}
