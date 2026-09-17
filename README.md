# Flutter Networking & Auth Showcase

This repository is a technical showcase of practical, senior-level REST API networking and authentication patterns in Flutter using `dio`. 

It is designed to be **small, focused, and easy to review**. It is not a complete application, but a reference implementation demonstrating how to correctly handle typical network scenarios.

## What's Demonstrated

### 1. REST API Networking
- **Dio Setup**: Clean configuration of `Dio` with interceptors (`ApiClient`).
- **Standardized Error Handling**: Transforming `DioException` into meaningful, app-specific domain exceptions (`ApiException`, `NetworkException`, `UnauthorizedException`).
- **GET & POST**: Examples of both request types handling models.
- **Manual JSON Serialization**: Minimal, type-safe data models without code generation.

### 2. Authentication & Token Refresh Flow
- **In-Memory Token State**: `AuthService` acts as a simplified state holder (secure storage is intentionally omitted to keep focus).
- **Request Interception**: `AuthInterceptor` automatically injects the `Authorization: Bearer <token>` header into protected requests.
- **Refresh Flow (Retry Pattern)**: If an API request returns `401 Unauthorized`, the interceptor catches it, pauses the request queue, fetches a new token, updates the headers, and transparently retries the original request.

### 3. Architecture
- `lib/core/network`: Networking logic, clients, and interceptors.
- `lib/auth`: Token models and authentication state management.
- `lib/features`: Data services and a minimal UI to test the flow.
- The project intentionally avoids massive architecture layers (e.g. strict Clean Architecture) in favor of a lightweight, pragmatic approach suited for networking logic alone.

### Request Flow
1. **Trigger**: UI calls `DataService.getProtectedData()`.
2. **Inject Token**: `AuthInterceptor` adds the current access token.
3. **Execute**: The request hits the network (simulated by `FakeBackendInterceptor`).
4. **401 Handling**: If the token is expired, a 401 is returned.
5. **Refresh**: `AuthInterceptor` halts the failure, calls `AuthService.refreshToken()`, and gets new tokens.
6. **Retry**: The original request is re-fired with the new access token.
7. **Success**: Data is returned seamlessly to the UI.

## Testing
- Tests are focused purely on the client behavior and token refresh mechanisms.
- Run tests via `flutter test`.

## Intentionally Out of Scope
- **Secure Storage**: Keeping tokens in `flutter_secure_storage` is omitted to maintain simplicity.
- **Dependency Injection Frameworks**: No `get_it` or `riverpod` just for DI.
- **Code Generation**: No `freezed` or `json_serializable` (manual mapping used).
- **Persistent State**: State resets on app restart.
