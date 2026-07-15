# API Integration Layer — Fully Decoupled from UI

The rule that makes everything else in this skill work: **UI and providers never see Dio, HTTP status codes, or raw JSON.** They see domain models and a `Result<T, Failure>`. This means an API contract change, a backend outage, or a slow endpoint is fixed in exactly one file — the repository implementation — and can't ripple into screens.

## The chain, in order

```
Dio (network) → *Dto (raw JSON shape) → mapper → domain model → Repository interface → Provider/Notifier → UI
```

### 1. Central Dio client (`core/network/dio_client.dart`)

One `Dio` instance, configured once, with interceptors — not per-call setup:

- **Auth interceptor**: attaches the token from `SecureStorageService`, and on a 401 tries a token refresh once before failing.
- **Timeout policy**: sane connect/receive timeouts so a hung request can't hang a whole screen forever.
- **Retry interceptor**: automatic retry with backoff for idempotent GET requests on network-level failures (timeout, connection error) — not for POST/PUT unless the endpoint is explicitly idempotent.
- **Logging interceptor**: verbose in debug builds only, and it must never log auth tokens or full request/response bodies containing user PII in release builds.

### 2. DTOs (`data/models/`)

Mirror the API response exactly, including `fromJson`/`toJson`. DTOs are allowed to be ugly (nullable everywhere the backend might omit a field, exact backend field names) — that ugliness is contained here and never spreads further.

### 3. Mapper (`data/mappers/`)

Pure functions converting `Dto -> domain model` (and back, if needed for requests). This is where you decide sane defaults for nulls, normalize enums, format things once. If the backend renames a field, only the DTO and mapper change.

### 4. Domain model (`domain/models/`)

The clean, non-nullable-where-reasonable model the rest of the app actually works with. No `Dto` suffix, no backend-specific naming.

### 5. Repository interface + implementation

```dart
// domain/repositories/product_repository.dart — this is what providers depend on
abstract class ProductRepository {
  Future<Result<List<Product>, Failure>> getProducts({required int page, int pageSize = 20});
  Future<Result<Product, Failure>> getProductById(String id);
}
```

```dart
// data/repositories/product_repository_impl.dart — the ONLY file that imports Dio for this feature
class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<Result<List<Product>, Failure>> getProducts({required int page, int pageSize = 20}) async {
    try {
      final response = await _dio.get(ApiEndpoints.products, queryParameters: {
        'page': page,
        'page_size': pageSize,
      });
      final dtos = (response.data['results'] as List).map((j) => ProductDto.fromJson(j));
      return Result.success(dtos.map(ProductMapper.toDomain).toList());
    } on DioException catch (e) {
      return Result.failure(NetworkFailure.fromDioException(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
  // ...
}
```

Every repository method is `try/catch`-wrapped exactly like this — no repository method is ever allowed to throw past its own boundary. See `error-handling.md` for how `DioException` maps to `Failure`.

### 6. Provider wiring

The repository interface is provided via a Riverpod `Provider`, with the concrete implementation swapped in at the composition point — this is also what makes the repository trivially mockable in tests:

```dart
final dioProvider = Provider<Dio>((ref) => DioClient.create());

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(ref.watch(dioProvider));
});
```

## Handling "the API doesn't exist yet"

Don't block on backend availability. Write the domain interface and a fake/in-memory implementation (`ProductRepositoryFake`) returning realistic sample data with the same `Result` shape, wire the UI against the interface, and swap in `ProductRepositoryImpl` later by changing one `Provider` override. The UI code never needs to change when the fake is replaced with the real thing.

## Resilience under load / spikes

- **Debounce, don't spam**: search-as-you-type and filter changes should debounce (e.g. 300–400ms) before firing a request, not fire on every keystroke.
- **Cancel stale requests**: use Dio `CancelToken`s tied to the provider's lifecycle so navigating away from a screen or a fast filter change cancels the in-flight request instead of racing it.
- **Cache reads, don't refetch reflexively**: use `keepAlive`/appropriate provider caching so switching tabs back and forth doesn't refire identical requests; pair with pull-to-refresh for explicit re-fetch.
- **Pagination is mandatory** for any endpoint that can return an unbounded list — see `performance.md`.
