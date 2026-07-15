---
name: flutter-production-builder
description: 'Use whenever building, extending, or reviewing a feature/screen/module for ANY production Flutter app (marketplace, social, chat, booking, fintech, content, dashboard, on-demand, or other domain) integrating a backend API. Enforces one architecture contract app-wide, regardless of domain: Riverpod state, a Dio API layer decoupled from the UI, sealed Result/Failure error handling so backend failures never crash the app, feature-first layered folders, independently-updating widgets, overflow-safe responsive layouts, virtualized paginated lists, a shared design-token library for theming (light + dark) and accessibility, and strict data-privacy encapsulation. Trigger for any new feature/module/screen (list/detail, cart, checkout, dashboard, chat, reviews, search, notifications, wallet, settings, onboarding, or any other screen), code review against these standards, or phrases like "build the next module", "add the X screen", "integrate the X API" - even without the words "skill" or "architecture".'
---

# Flutter Production App — Module Builder

## What this skill is for

The user is building a production-grade Flutter app **one feature/module at a time**, not all at once — this applies regardless of the app's domain (marketplace/e-commerce, social, chat, booking, fintech, content/media, internal dashboard, on-demand services, or anything else). Each time, they'll hand you a feature name and description. Your job is to generate code for *that one feature* that slots into the existing app without touching unrelated code, follows the exact same architecture as every other module, and would survive a code review at a company that actually ships to millions of users.

The reason this skill exists: when every module is generated ad hoc, apps rot — inconsistent state management, API calls sprinkled inside widgets, one crashed request taking down an entire screen, giant `build()` methods, hardcoded colors everywhere. This skill is the single contract that prevents that, so module #40 looks and behaves exactly like module #1, no matter what kind of app it is.

**Read the reference file for a topic before writing code that touches it** — they contain the actual patterns and code shapes, not just principles:

| Reference file | Read it when you're... |
|---|---|
| `references/folder-structure.md` | Placing any new file — where it goes and how it's named |
| `references/state-management.md` | Writing any Riverpod provider/notifier |
| `references/api-layer.md` | Writing anything that touches the network (Dio, repositories, DTOs) |
| `references/error-handling.md` | Writing anything that can fail — which is almost everything |
| `references/ui-components.md` | Writing any widget — overflow safety, reuse, theming, widget/screen size limits |
| `references/design-system.md` | Touching typography, color/dark-mode, spacing/radius/shadow tokens, animation, icons, or assets |
| `references/responsiveness-accessibility.md` | Writing any layout that must adapt across phone/foldable/tablet, or any screen reader/touch-target/form concern |
| `references/performance.md` | Writing any list, image, or anything rendering many items |
| `references/code-templates.md` | Scaffolding a brand-new feature from scratch |
| `references/definition-of-done.md` | Before telling the user the feature is ready to test |

Don't try to hold all of these in your head at once — go read the relevant one when you hit that part of the work. They're short and specific on purpose.

## The tech stack contract (do not deviate per-module)

| Concern | Choice | Why it's fixed |
|---|---|---|
| State management | **Riverpod** (`flutter_riverpod` + `riverpod_annotation`/codegen) | One mental model everywhere; `.select()` and provider scoping are what make independent, non-cascading UI updates possible |
| Networking | **Dio** | Interceptors give one place for auth headers, retry, logging, and timeout policy instead of repeating it per call |
| Architecture | **Feature-first, layered inside each feature** (hybrid) | Every feature is a self-contained folder with its own data/domain/presentation, so it can be added, removed, or handed to another dev without touching other features. Shared code lives in `core/` |
| Routing | **go_router** | Declarative, deep-link friendly, works cleanly with Riverpod for auth-gated redirects |
| Local persistence/cache | **Hive** (or `shared_preferences` for flags) | Fast, no native build step, good for offline-first list caching |
| Secure storage | **flutter_secure_storage** | Tokens and anything sensitive never touch plain SharedPreferences |
| Images | **cached_network_image**, **flutter_svg** (icons/illustrations), **lottie** (micro-animations) | Most production apps are image/media-heavy somewhere (product photos, avatars, post media, banners); caching is non-negotiable for performance and data usage, and vector/Lottie assets keep icons and empty-state illustrations crisp and small |
| Theming | **Material 3** (`ColorScheme.fromSeed`/explicit `ColorScheme`), light + dark `ThemeData` | One design-token source of truth (`design-system.md`) driving both themes keeps 40 independently-built modules looking like one app in either mode |
| Testing | **flutter_test + mocktail** | Mocktail avoids codegen friction for mocks; keeps unit tests fast to write per module |

If the user's project already uses different choices for any of these, ask before assuming — don't silently mix e.g. Provider and Riverpod in the same app.

## Non-negotiable principles (the "why" behind every rule below)

1. **UI never talks to Dio directly.** Widgets depend only on a `Repository` interface returning domain models. This is what lets a backend outage, a slow endpoint, or an API contract change stay contained to one file instead of rippling into every screen that shows that data.
2. **Nothing throws past the repository boundary.** Every repository method returns a `Result<T, Failure>` (see `error-handling.md`). Providers turn that into `AsyncValue`, and the UI renders loading/data/empty/error states from a single reusable pattern. A failed API call becomes a friendly retry card, never a red screen or a silent crash.
3. **Providers are scoped as narrowly as possible.** A price updating shouldn't rebuild the whole product card, and a product card updating shouldn't rebuild the whole list. Use `.select()`, split notifiers per concern, and keep `ConsumerWidget`s small. This is both the "modules update independently" requirement and a major performance lever — they're the same problem.
4. **Every feature folder is deletable.** If you can't remove a feature folder without hunting for stray imports scattered across `core/` or other features, the boundary is wrong. Shared stuff belongs in `core/`; feature-specific stuff never leaks out of its folder.
5. **No screen trusts fixed sizes.** Real-world data (names, titles, prices in different currencies, counts, message lengths — whatever the domain's content is) varies wildly in length, and the screen it renders on varies from a small phone to a foldable to a tablet. Every layout must survive both — see the overflow rules in `ui-components.md` and the responsive-layout tools in `responsiveness-accessibility.md`.
6. **Large lists are always virtualized and paginated.** Never `Column` + `.map()` over a list that could grow large (products, orders, chat messages, reviews). Always `ListView.builder`/`SliverList` with pagination — see `performance.md`.
7. **Nothing sensitive leaves the layer that owns it.** Auth tokens, raw API error bodies/stack traces, and internal IDs meant only for the backend never get logged, never get shown in a user-facing message, and never get exposed as public fields outside the module that owns them (prefix with `_` and expose narrow getters instead).
8. **One design-token source of truth.** Colors, spacing, radii, shadows, durations, and text styles are never hardcoded in a widget — they come from `AppTheme`/`AppColors`/`AppTypography`/`AppSpacing`/`AppShadows`/`AppDurations` in `core/theme/`, and every screen works in both light and dark mode. This is what keeps 40 independently-built modules looking like one app — see `design-system.md`.
9. **Widgets default to stateless and stay small.** `StatelessWidget` unless a widget genuinely owns ephemeral local state; ≈200 lines per widget, ≈300 per screen, as a signal to extract rather than a hard rule. See `ui-components.md`.
10. **Accessibility and form states are built in, not bolted on.** Semantic labels, minimum touch targets, contrast, and dynamic text scaling are part of the first pass on a screen; every form implements focused/error/disabled/loading/success states from the start. See `responsiveness-accessibility.md`.

## Workflow for building one feature/module

Follow this every time, regardless of what the feature is:

1. **Clarify scope in one pass, not many rounds.** If the user's feature description is missing something structurally important (which API endpoints exist and their shapes, whether it needs offline support, whether it's paginated), ask once, up front. Don't guess at API contracts — ask for the endpoint/response shape or ask the user to paste API docs/Postman/OpenAPI if you don't have it.
2. **Scaffold the feature folder** per `folder-structure.md` — don't touch other features' folders.
3. **Build bottom-up**: domain model → DTO + mapper → repository interface + implementation → Riverpod providers/notifiers → UI. This order means every layer below the UI is done and typed before you write a widget against it.
4. **Wire in error handling and loading/empty states from the start** — not as an afterthought bolted on at the end. Use the `AsyncValue`/`Result` patterns from `error-handling.md` from the first line of the notifier, not after the happy path works.
5. **Use existing shared widgets before creating new ones.** Check `core/widgets/` (buttons, cards, loading shimmer, error/empty state views, domain-specific chips/badges) first. Only add a new shared widget if the pattern will clearly recur; otherwise keep it local to the feature.
6. **Register the route** in the central `go_router` config, in its own small file the router imports — don't hand-edit a giant switch statement.
7. **Self-check against `definition-of-done.md`** before handing the feature back. Call out explicitly which boxes are checked and which need the user's backend/API to actually verify (e.g., real network failure testing).

## The universal per-feature prompt

This is the template the user fills in and sends for every new module. When you receive a message shaped like this, treat every field as a real constraint, not a suggestion — and apply everything above automatically without being re-asked.

```
FEATURE: <name, e.g. "Product Listing Screen", "Chat Thread View", "Booking Confirmation Screen" — any feature in any app>

DESCRIPTION:
<what it does, from the user's perspective>

API DETAILS:
<endpoint(s), method, request/response shape, pagination params, auth requirements —
 or "not available yet, mock it behind the repository interface">

UI REQUIREMENTS:
<layout specifics, states it needs to handle, any design reference>

DEPENDS ON:
<other features/shared widgets/providers it needs to read, if any>

OUT OF SCOPE:
<explicitly what NOT to touch this round>
```

If the user sends a bare feature name with no detail, don't stall — apply the Workflow step 1 above: ask the one or two structurally-important questions (API shape, pagination, offline needs) and proceed with everything else defaulted to this skill's standards.

## Output expectations

- Generate real files in the project structure (not one giant pasted blob) — respect `folder-structure.md`.
- Every new public class gets a one-line doc comment explaining its responsibility — future modules (and the user) need to know what's safe to depend on.
- Call out in your response, briefly: what you built, where it lives, what's mocked vs. real, and what the user should manually verify before marking the module done.
- Don't refactor or "improve" unrelated existing code while building a feature — flag it to the user instead and let them decide if it's in scope.
