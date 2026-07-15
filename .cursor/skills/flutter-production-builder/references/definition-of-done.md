# Definition of Done — Checklist Before Moving to the Next Module

The user builds one feature at a time and only moves on once the current one "passes all the test cases." Use this checklist at the end of every feature and report it back explicitly — call out anything that genuinely needs the user's real backend to verify (mark it, don't silently skip it).

## Architecture conformance
- [ ] No widget/provider imports `Dio`, `dio`, or a `*Dto` class directly — only the domain repository interface and domain models.
- [ ] Every repository method returns `Result<T, Failure>`; none can throw past its own `try/catch`.
- [ ] The feature lives entirely under `features/<name>/`, with routes registered in their own route file, not hand-edited into a shared list.
- [ ] Any newly-shared widget actually earned its place in `core/widgets/` (used by 2+ features) — nothing promoted "just in case."

## Error handling
- [ ] Loading, data, empty, and error states are all handled and visually distinct — an empty result never looks like an error, and an error never looks like a crash.
- [ ] Every error state has a way forward (retry button, navigate to login, inline field error) — no dead ends.
- [ ] No raw exception text, stack trace, or HTTP status code is ever shown to the user.
- [ ] Tested (or at least reasoned through) what happens on: slow network (loading state shows), request failure (error state + retry works), empty result (empty state, not error).

## Independence & performance
- [ ] Changing one piece of data (e.g. one item's price/favorite state) doesn't visibly rebuild unrelated parts of the screen — verify with Flutter DevTools' rebuild highlighting if unsure.
- [ ] Any list that can exceed a screenful uses `ListView.builder`/`Sliver*`/`GridView.builder` with pagination, not an eagerly-built `Column`.
- [ ] Tested with a realistic data volume (100+ items for lists), not just the 2–3 items in a happy-path mock.
- [ ] `const` used wherever possible; list items have stable `Key`s.

## Layout safety
- [ ] No overflow warnings at the default screen size, a small phone width (~320dp), and with unusually long text in every text field that shows user/backend-provided content (long titles, long names).
- [ ] All `Text` widgets that can overflow have `overflow`/`maxLines` set and are wrapped in `Flexible`/`Expanded` where needed.
- [ ] No buttons wrap into multiple lines, no cropped text/icons, no misaligned widgets at any tested width.

## Responsiveness (see `responsiveness-accessibility.md`)
- [ ] Checked at small/medium/large phone widths; no hardcoded pixel dimensions where a `Flexible`/`LayoutBuilder`/`MediaQuery`-based approach was needed instead.
- [ ] If the feature is tablet/foldable-relevant, verified it adapts at Material 3's Medium/Expanded breakpoints rather than just stretching the phone layout.
- [ ] `SafeArea` respected; content doesn't sit under a notch, status bar, or gesture-nav area.

## UI accuracy (see `design-system.md`)
- [ ] Pixel-perfect match against the provided design reference: spacing, alignment, typography, icon size, padding, margins, radius, elevation, color, shadows, opacity, borders.
- [ ] Verified in both light and dark theme — no hardcoded `Colors.white`/`Colors.black` breaking dark mode.
- [ ] Any animation used is purposeful (not decorative overuse), runs at a smooth frame rate, and every custom `AnimationController` is disposed.

## Accessibility & forms (see `responsiveness-accessibility.md`)
- [ ] Icon-only/gesture-only controls have a semantic label; touch targets are at least 48x48dp.
- [ ] Text/icon contrast meets WCAG AA against its background; layout survives a larger system text scale without overflowing.
- [ ] Any form on this screen implements focused/error/disabled/loading/success states, correct `keyboardType`/`textInputAction` per field, and dismisses the keyboard appropriately.

## Consistency
- [ ] No hardcoded colors, font sizes, spacing, radius, or shadow values — everything traces back to `core/theme/` (`AppColors`/`AppTypography`/`AppSpacing`/`AppShadows`/`AppDurations`).
- [ ] Matches the visual language of already-built features (same card styles, same button styles, same spacing rhythm, same icon family).
- [ ] Naming conventions followed: `PascalCase` classes, `camelCase` variables/constants, `snake_case.dart` files.

## Data safety
- [ ] No token, password, or full API response containing PII is logged, even in debug builds' verbose logging — check the Dio logging interceptor's scope.
- [ ] Sensitive fields (tokens, internal-only IDs) are not exposed as public fields outside the module that owns them.
- [ ] Nothing sensitive is cached in plain `SharedPreferences`/unencrypted storage — tokens go through `SecureStorageService`.

## Handoff notes to give the user
When reporting a finished feature, always state explicitly:
1. What's real vs. mocked (e.g. "repository is wired to a fake in-memory implementation since the `/products` endpoint isn't live yet — swap `ProductRepositoryFake` for `ProductRepositoryImpl` in the provider override once it is").
2. What the user should manually verify with the real backend that can't be verified without it (actual error responses matching the mapped `Failure` messages, actual pagination behavior, actual auth token flow).
3. Any assumption made about the API shape that should be confirmed against real API docs.
