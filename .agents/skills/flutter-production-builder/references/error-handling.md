# Error & Exception Handling — Nothing Reaches the UI Unhandled

Three layers of defense, in order. A well-built feature should almost never need layer 3 — but layer 3 exists so that if something genuinely unexpected happens, the user sees a friendly message instead of a crash, in every build, not just debug.

## Layer 1 — `Result<T, Failure>` at the repository boundary

```dart
// core/error/result.dart
sealed class Result<T, F> {
  const Result();
  factory Result.success(T value) = Success<T, F>;
  factory Result.failure(F failure) = ResultFailure<T, F>;
}
class Success<T, F> extends Result<T, F> { final T value; const Success(this.value); }
class ResultFailure<T, F> extends Result<T, F> { final F failure; const ResultFailure(this.failure); }
```

```dart
// core/error/failure.dart
sealed class Failure {
  const Failure(this.message);
  final String message; // user-facing, already safe to display
}
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
  factory NetworkFailure.fromDioException(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout => const NetworkFailure('This is taking longer than expected. Please try again.'),
    DioExceptionType.connectionError => const NetworkFailure('You appear to be offline. Check your connection and try again.'),
    _ => NetworkFailure(_messageForStatus(e.response?.statusCode)),
  };
}
class ValidationFailure extends Failure { const ValidationFailure(super.message); }
class AuthFailure extends Failure { const AuthFailure(super.message); }
class UnknownFailure extends Failure {
  const UnknownFailure(this.debugDetail) : super('Something went wrong. Please try again.');
  final String debugDetail; // logged internally, NEVER shown to the user or sent to analytics with PII attached
}
```

Every `Failure` message is written **as if a designer wrote the copy** — never a raw exception string, never a stack trace, never a raw HTTP status code shown to the user. Map status codes to sane copy once, centrally (`_messageForStatus`), not per-feature.

Repositories never throw. Every repository method signature returns `Result<T, Failure>`, and every implementation wraps its body in `try/catch` mapping to a `Failure` (see `api-layer.md`).

## Layer 2 — Providers turn `Result` into `AsyncValue`, UI renders it uniformly

```dart
class ProductListNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() => _fetch();

  Future<List<Product>> _fetch() async {
    final result = await ref.read(productRepositoryProvider).getProducts(page: 1);
    return switch (result) {
      Success(:final value) => value,
      ResultFailure(:final failure) => throw failure, // AsyncNotifier converts this into AsyncError for us
    };
  }
}
```

Riverpod's `AsyncValue` already carries loading/data/error — the UI's `.when(...)` (shown in `state-management.md`) is the *only* place error-vs-data branching happens for that data. No `try/catch` scattered through widgets, no nullable "errorMessage" fields threaded through UI state.

Every screen that can be empty (zero results, not an error) must render an explicit empty state, distinct from the error state — an empty search, an empty inbox, or "no items in this category" should never look like a crash.

## Layer 3 — App-wide safety net (catches the truly unexpected)

Two things wired once, in `main.dart`, so a genuinely unhandled exception anywhere in the widget tree degrades gracefully instead of showing Flutter's red/grey error screen in production:

```dart
void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    ErrorWidget.builder = (details) => const FriendlyErrorFallback(); // replaces the red screen
    FlutterError.onError = (details) {
      // log to crash reporting here (Sentry/Crashlytics) — never rethrow to the user
    };
    runApp(const ProviderScope(child: MyApp()));
  }, (error, stack) {
    // catches errors outside the Flutter framework's own error handling (async gaps, isolates)
    // log to crash reporting here too
  });
}
```

This is a safety net, not a substitute for layers 1 and 2 — if you find yourself relying on it to catch expected failure modes (network errors, empty results, validation errors), that's a sign a repository or provider is throwing instead of returning a `Result`/`Failure` properly.

## Retry & recovery UX

Every error state the user can hit from normal use (not layer-3 territory) gets a way forward, not a dead end:

- Network/list errors → `ErrorStateView` with a **Retry** button that calls `ref.invalidate(...)` on the relevant provider.
- Form submission errors (validation, conflict) → inline field errors or a snackbar with the `Failure.message`, form stays filled in, nothing is lost.
- Auth failures (expired session) → route to login, don't just show an error and strand the user.

## What never happens, anywhere in the codebase

- A `catch (e) { print(e); }` that swallows an error silently with no user-visible consequence and no logging.
- A raw `Exception`/`DioException`/stack trace string shown to the user in a `Text` widget or `SnackBar`.
- A widget's `build()` method that can throw on legitimate data (e.g. `list.first` on a list that can be empty, `!` on a value that can genuinely be null from the API) — handle it explicitly instead of assuming.
