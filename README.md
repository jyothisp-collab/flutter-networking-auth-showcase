# Flutter Networking & Authentication Showcase

A focused Flutter reference implementation demonstrating production-grade networking and token-based authentication patterns for client review.

## What It Demonstrates

- **Dio HTTP client** with a custom in-memory `HttpClientAdapter` that simulates an entire API without real network calls.
- **Token-based Bearer authentication** — login flow returning access and refresh tokens.
- **Automatic token refresh on 401** — `AuthInterceptor` catches expired-token failures, calls the refresh endpoint, and transparently retries the original request with the new token.
- **Retry guard** — Prevents infinite retry loops by tracking retry state in request extras.
- **Error classification** — `ExceptionHandler` maps Dio error types into domain-specific exceptions (`NetworkException`, `TimeoutException`, `UnauthorizedException`, `ServerException`, `UnknownException`).
- **Clean layering** — `auth/`, `core/network/`, `features/data/`, `features/ui/` with clear separation of concerns.
- **Manual JSON serialization** — `fromJson`/`toJson` on models without code generation for transparency.

## Architecture Overview

```
lib/
├── main.dart                              — Composition root, DI wiring
├── auth/
│   ├── auth_service.dart                  — Auth state, login/refresh/logout
│   └── auth_token.dart                    — Token model (fromJson/toJson)
├── core/
│   └── network/
│       ├── api_client.dart                — Dio configuration, interceptor wiring
│       ├── api_exceptions.dart            — Sealed ApiException hierarchy
│       ├── auth_interceptor.dart          — Bearer injection + 401 retry
│       └── fake_http_adapter.dart         — In-process mock API
└── features/
    ├── data/
    │   ├── data_model.dart                — Data model (id, title, body)
    │   └── data_service.dart              — Business logic: getPublicData, getProtectedData
    └── ui/
        └── home_screen.dart               — Login, fetch public/protected data
```

### Request Flow

```
User taps "Fetch Protected Data"
  ↓
DataService.getProtectedData()
  ↓
Dio → AuthInterceptor (injects Bearer token)
  ↓
FakeHttpAdapter (sees expired token → returns 401)
  ↓
AuthInterceptor.onError (catches 401)
  ↓
AuthService.refreshToken() (POST /refresh)
  ↓
FakeHttpAdapter (returns new valid token)
  ↓
AuthInterceptor retries original request with new token
  ↓
FakeHttpAdapter (sees valid token → returns 200 + data)
  ↓
Data displayed in UI
```

## Error Handling

`ExceptionHandler.handle()` maps Dio exceptions to domain-specific types:

| Dio Error Type | Mapped Exception |
|---|---|
| Connection error, no internet | `NetworkException` |
| Request timeout | `TimeoutException` |
| Response 401 | `UnauthorizedException` |
| Response 4xx/5xx | `ServerException` |
| Unknown | `UnknownException` |

## Auth Flow

1. User taps Login → `POST /login` → receives expired access token + valid refresh token.
2. User taps "Fetch Protected Data" → request sent with expired token → 401.
3. `AuthInterceptor` refreshes the token → retries original request → succeeds.
4. If refresh itself fails → `UnauthorizedException` → user is logged out.

## Testing

Tests cover the critical authentication and networking paths:

- **Login flow** — successful login returns tokens and sets authenticated state.
- **Unauthorized access** — accessing protected data without auth throws `UnauthorizedException`.
- **Token refresh** — expired token triggers refresh and retry succeeds.
- **Public data** — works without authentication.
- **POST requests** — create data through the API.

Run:

```bash
flutter pub get
flutter test
```

## Key Decisions

- **Dio** is used for its built-in interceptor chain, which makes token injection and retry logic composable and testable.
- **In-memory adapter** keeps the showcase runnable without external infrastructure while exercising the full Retrofit-style request pipeline.
- **Manual JSON serialization** avoids code generation dependencies so the project stays transparent for review.
- **No DI framework** — Dependencies are composed in `main.dart`. A production app would add `get_it` or `riverpod` for scaling.
- **In-memory token storage** — acknowledged as intentional for the showcase. Production apps should use `flutter_secure_storage`.

## Out Of Scope

- Real backend integration (mock adapter simulates all endpoints).
- Secure token persistence (tokens are in-memory only).
- Token expiry prediction (relies on server 401 rather than JWT `exp` claim).
- Concurrent refresh serialization (no mutex/single-flight).
- Retry for transient network errors (only 401 retry is implemented).
- Localization of error messages.
- Request logging and analytics.
