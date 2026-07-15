# Code Templates — Scaffolding a New Feature End-to-End

This walks through one complete, minimal feature ("Product Listing") touching every layer, so you can see how the pieces in the other reference docs fit together. **The domain is illustrative only** — swap `Product` for `Post`, `Message`, `Booking`, `Order`, `Invoice`, or whatever entity the current feature is actually about; the nine-layer shape below is identical regardless of app domain. Use it as the shape for any new feature — swap the domain, keep the layering.

## 1. Domain model — `features/product_listing/domain/models/product.dart`

```dart
/// Clean domain representation of a product. UI and providers depend only on this,
/// never on ProductDto.
class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.sellerName,
    this.rating,
  });

  final String id;
  final String title;
  final double price;
  final String imageUrl;
  final String sellerName;
  final double? rating;
}
```

## 2. DTO — `features/product_listing/data/models/product_dto.dart`

```dart
/// Raw API shape for a product. Never used outside data/ — see product_mapper.dart.
class ProductDto {
  const ProductDto({
    required this.id,
    required this.title,
    required this.priceCents,
    required this.imageUrl,
    this.seller,
    this.avgRating,
  });

  final String id;
  final String title;
  final int priceCents; // backend sends cents, not dollars — mapper handles conversion
  final String imageUrl;
  final Map<String, dynamic>? seller;
  final double? avgRating;

  factory ProductDto.fromJson(Map<String, dynamic> json) => ProductDto(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        priceCents: json['price_cents'] as int? ?? 0,
        imageUrl: json['image_url'] as String? ?? '',
        seller: json['seller'] as Map<String, dynamic>?,
        avgRating: (json['avg_rating'] as num?)?.toDouble(),
      );
}
```

## 3. Mapper — `features/product_listing/data/mappers/product_mapper.dart`

```dart
class ProductMapper {
  const ProductMapper._();
  static Product toDomain(ProductDto dto) => Product(
        id: dto.id,
        title: dto.title,
        price: dto.priceCents / 100,
        imageUrl: dto.imageUrl,
        sellerName: dto.seller?['name'] as String? ?? 'Unknown seller',
        rating: dto.avgRating,
      );
}
```

## 4. Repository interface — `features/product_listing/domain/repositories/product_repository.dart`

```dart
abstract class ProductRepository {
  Future<Result<List<Product>, Failure>> getProducts({required int page, int pageSize = 20});
}
```

## 5. Repository implementation — `features/product_listing/data/repositories/product_repository_impl.dart`

See the full pattern in `api-layer.md` — same shape, `try/catch` mapping `DioException` to `Failure`, never throwing past this file.

## 6. Providers — `features/product_listing/application/product_list_provider.dart`

```dart
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(ref.watch(dioProvider));
});

class ProductListState {
  const ProductListState({
    this.products = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
  });
  final List<Product> products;
  final bool hasMore;
  final bool isLoadingMore;

  ProductListState copyWith({List<Product>? products, bool? hasMore, bool? isLoadingMore}) =>
      ProductListState(
        products: products ?? this.products,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

class ProductListNotifier extends AsyncNotifier<ProductListState> {
  int _page = 1;

  @override
  Future<ProductListState> build() => _fetchPage(1, const ProductListState());

  Future<ProductListState> _fetchPage(int page, ProductListState current) async {
    final result = await ref.read(productRepositoryProvider).getProducts(page: page);
    return switch (result) {
      Success(:final value) => current.copyWith(
          products: page == 1 ? value : [...current.products, ...value],
          hasMore: value.length == 20,
          isLoadingMore: false,
        ),
      ResultFailure(:final failure) => throw failure,
    };
  }

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    _page++;
    state = await AsyncValue.guard(() => _fetchPage(_page, current));
  }
}

final productListProvider = AsyncNotifierProvider<ProductListNotifier, ProductListState>(
  ProductListNotifier.new,
);
```

## 7. Screen — `features/product_listing/presentation/screens/product_list_screen.dart`

```dart
class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: SafeArea(
        child: stateAsync.when(
          data: (state) => state.products.isEmpty
              ? const EmptyStateView(message: 'No products yet')
              : PaginatedListView<Product>(
                  items: state.products,
                  hasMore: state.hasMore,
                  isLoadingMore: state.isLoadingMore,
                  onLoadMore: () => ref.read(productListProvider.notifier).loadNextPage(),
                  itemBuilder: (context, product) => ProductCard(product: product),
                ),
          loading: () => const LoadingShimmer(),
          error: (error, _) => ErrorStateView(
            message: error is Failure ? error.message : 'Something went wrong.',
            onRetry: () => ref.invalidate(productListProvider),
          ),
        ),
      ),
    );
  }
}
```

## 8. Feature-local widget — `features/product_listing/presentation/widgets/product_card.dart`

```dart
class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, super.key});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: ValueKey(product.id),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            CachedNetworkImageWithPlaceholder(url: product.imageUrl, width: 64, height: 64),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  PriceTag(price: product.price),
                  Text(product.sellerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 9. Route registration — `features/product_listing/product_listing_routes.dart`

```dart
List<RouteBase> productListingRoutes = [
  GoRoute(
    path: '/products',
    name: RouteNames.productList,
    builder: (context, state) => const ProductListScreen(),
  ),
];
```

Then in `core/router/app_router.dart`, add `...productListingRoutes` to the root routes list — nothing else about the router changes.

---

Every future feature follows this same nine-step shape: domain model → DTO → mapper → repository interface/impl → providers → screen → local widgets → route. The names and fields change; the architecture doesn't.
