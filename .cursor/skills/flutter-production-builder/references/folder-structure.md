# Folder Structure — Feature-First + Layered (Hybrid)

Every feature is a self-contained folder. Inside that folder, code is layered (data/domain/presentation) the same way every time. Shared code that multiple features genuinely need lives in `core/`. Nothing in `core/` should ever import from a feature folder — dependencies only flow feature → core, never the reverse.

```
lib/
├── main.dart
├── app.dart                      # MaterialApp.router + top-level ProviderScope wiring
│
├── core/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart      # spacing/radius/elevation constants
│   │   └── app_theme.dart        # ThemeData assembled from the above
│   ├── router/
│   │   ├── app_router.dart       # go_router root config, imports each feature's routes
│   │   └── route_names.dart
│   ├── network/
│   │   ├── dio_client.dart       # Dio instance + interceptors (auth, retry, logging)
│   │   ├── api_endpoints.dart    # base URL + path constants
│   │   └── network_exceptions.dart
│   ├── error/
│   │   ├── failure.dart          # sealed Failure hierarchy
│   │   └── result.dart           # Result<T, Failure> type
│   ├── widgets/                  # shared, reused across 2+ features
│   │   ├── app_button.dart
│   │   ├── app_text_field.dart
│   │   ├── loading_shimmer.dart
│   │   ├── error_state_view.dart
│   │   ├── empty_state_view.dart
│   │   └── paginated_list_view.dart
│   ├── utils/
│   │   ├── formatters.dart       # currency, date, etc.
│   │   └── validators.dart
│   └── storage/
│       ├── secure_storage_service.dart
│       └── local_cache_service.dart   # Hive boxes wrapper
│
└── features/
    └── product_listing/                       # <- one folder per feature
        ├── data/
        │   ├── models/
        │   │   └── product_dto.dart            # raw API shape + fromJson/toJson
        │   ├── mappers/
        │   │   └── product_mapper.dart          # DTO <-> domain model
        │   └── repositories/
        │       └── product_repository_impl.dart # implements the domain interface, uses Dio
        ├── domain/
        │   ├── models/
        │   │   └── product.dart                 # clean domain model UI actually uses
        │   └── repositories/
        │       └── product_repository.dart       # abstract interface — UI/providers depend on THIS
        ├── application/
        │   └── product_list_provider.dart        # Riverpod notifiers/providers for this feature
        └── presentation/
            ├── screens/
            │   └── product_list_screen.dart
            └── widgets/
                ├── product_card.dart              # local to this feature (not reused elsewhere yet)
                └── product_list_filters.dart
```

## Naming conventions

- Files: `snake_case.dart`. Classes: `PascalCase`. Providers/notifiers: `camelCaseProvider` / `CamelCaseNotifier`.
- One class of real substance per file. Small private helper widgets can live alongside the widget that uses them in the same file if they're never reused.
- DTOs are suffixed `Dto` and only exist in `data/`. Domain models have no suffix and are what everything above `data/` uses. **Never let a `Dto` class leak into `presentation/` or `application/`** — that's the whole point of the mapper step, and it's what keeps a backend field rename from touching UI code.
- Screens go in `presentation/screens/`, reusable-within-feature widgets in `presentation/widgets/`. Widgets reused across 2+ features get promoted to `core/widgets/` — don't put them there pre-emptively "just in case."

## Adding a new feature checklist

1. Create the folder under `features/<feature_name>/` with the four subfolders above (skip `data/` only if the feature has no network calls of its own).
2. Add its routes in its own small file, e.g. `features/product_listing/product_listing_routes.dart`, and import that into `core/router/app_router.dart` — never hand-edit one giant route list.
3. If it needs a shared widget that doesn't exist yet and is clearly reusable, add it to `core/widgets/`. If unsure, keep it local — promoting later is cheap, demoting a wrongly-shared widget is not.
4. Nothing outside `features/<feature_name>/` should import from inside it except its route file and, if genuinely needed, a public provider another feature explicitly depends on (see `DEPENDS ON` in the per-feature prompt).
