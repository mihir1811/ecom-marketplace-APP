# Responsiveness, Accessibility, and Forms

## Responsive design — no hardcoded dimensions

The app must work correctly across small phones, medium phones, large phones, foldables, and tablets (where the feature is tablet-relevant), in both portrait and landscape where the screen reasonably supports it. A layout tuned only for one reference device (e.g. a 390dp-wide design mockup) and never checked against anything smaller or larger is not done.

**Never hardcode a `width`/`height` to a literal pixel value for anything that needs to fit the screen or a text-bearing container.** Use, in rough order of preference:

- **`Flexible`/`Expanded`** inside `Row`/`Column` — the default tool for "share the available space," used before reaching for anything more complex.
- **`LayoutBuilder`** — when a widget needs to make a structural decision based on the space it's actually given (e.g. switch from a 2-column to a 3-column grid, or from a bottom sheet to a side panel on a tablet-width constraint).
- **`MediaQuery.sizeOf(context)` / `.of(context).size`** — for screen-level breakpoint decisions (see below). Prefer `LayoutBuilder` when the decision is about the space a *specific widget* has, since a screen-width breakpoint doesn't account for that widget sitting inside a side panel, split view, or dialog.
- **`FractionallySizedBox`** — sizing something as a fraction of its parent (e.g. a bottom sheet at 90% of screen height).
- **`AspectRatio`** — for anything that must preserve a ratio regardless of available width (product images, video thumbnails).
- **`Spacer`** — pushing content apart in a `Row`/`Column` without a fixed gap.

### Practical breakpoints

There's no single official Flutter breakpoint set — use Material 3's window size classes as the default unless the design spec says otherwise:

| Class | Width | Typical device |
|---|---|---|
| Compact | < 600dp | Phones (small/medium/large) |
| Medium | 600–839dp | Foldables (unfolded), small tablets |
| Expanded | ≥ 840dp | Tablets, landscape tablets |

A feature that's phone-only can ignore Medium/Expanded and just ensure it doesn't break at those widths (no overflow, sensible max content width). A feature explicitly required to support tablets should provide a genuinely different layout at Medium/Expanded (e.g. a list+detail split view) rather than just stretching the phone layout — stretched phone layouts on tablets are a common, easily-avoided visual bug (e.g. an overly wide single-column list with huge empty margins).

### Orientation

Support portrait always; support landscape only where the feature reasonably benefits from it (e.g. a video/image viewer, not necessarily a checkout form). If landscape isn't explicitly supported, at minimum verify the screen doesn't overflow or crash when rotated — don't lock orientation as a substitute for actually testing it, unless the user has explicitly asked to lock it.

### Safe area and cutouts

Every top-level screen is wrapped in `SafeArea` (already required in `ui-components.md`) so content never sits under a notch, status bar, home indicator, or gesture-navigation area. For screens with custom app bars or edge-to-edge imagery, apply `SafeArea` selectively (`top: true, bottom: false` etc.) rather than universally disabling it.

## Accessibility

Accessibility is not optional polish — build it in from the start of each feature, not retrofitted after the UI is "done."

- **Semantic labels**: any interactive element that isn't self-describing from visible text (icon-only buttons, image buttons, custom gesture areas) gets a `Semantics(label: ...)` or the widget's built-in `tooltip`/`semanticLabel` param. A screen reader user should never land on an unlabeled icon button.
- **Minimum touch target**: interactive elements are at least 48x48dp, even if the visual icon/asset is smaller — use padding to expand the tappable area (`InkWell`/`GestureDetector` with adequate padding, or `MaterialTapTargetSize.padded`) rather than shrinking the hit area to match a small icon.
- **Color contrast**: text and icons meet WCAG AA contrast against their background (4.5:1 for normal text, 3:1 for large text/icons) — check this when picking `AppColors` pairs, especially secondary/caption text on colored surfaces, not just primary text on white.
- **Dynamic text scaling**: respect the system font scale (`MediaQuery.textScalerOf(context)`) rather than disabling it with `MediaQuery.withNoTextScaling` or a fixed `textScaleFactor: 1.0`. This means layouts must survive larger text sizes without overflowing — another reason the overflow rules in `ui-components.md` are non-negotiable, not just a visual nicety.
- **Screen reader flow**: verify reading order matches visual order (Flutter generally handles this from widget tree order, but custom `Stack`/`CustomMultiChildLayout` usage can break it — check with TalkBack/VoiceOver if the feature uses unusual layout widgets).
- **Keyboard navigation** (where the platform supports it — web/desktop targets): interactive elements should be reachable and operable via `Tab`/`Enter`/arrow keys, not only touch/mouse.

## Forms

Every form in the app (search filters, checkout, profile edit, seller onboarding, reviews) implements the same set of states — a form missing any of these is incomplete, not just "simplified":

- **Focused state**: clear visual indication of which field is active (border color change via `InputDecorationTheme`, not a one-off per field).
- **Error state**: inline validation message under the field, field border/label switches to `AppColors.error` — never a bare `SnackBar` as the only error signal for a field-level validation error.
- **Disabled state**: visually distinct (reduced opacity/greyed fill) and genuinely non-interactive, used while a dependent async action is in flight or a field isn't yet applicable.
- **Loading state**: the submit action shows a spinner in place of its label (use the shared `AppButton` loading variant from `ui-components.md`) and the form is not resubmittable mid-request — guard against double-submit.
- **Success state**: explicit confirmation (inline message, navigation forward, or a success toast) — a form that just silently returns to its previous state after submitting leaves the user unsure if anything happened.
- **Validation UI**: validate on blur/submit (not on every keystroke, which feels aggressive) unless the field benefits from live feedback (e.g. password strength).

### Keyboard behavior

- Set the correct `keyboardType` per field (`emailAddress`, `phone`, `number`, `visiblePassword`, etc.) — a plain text keyboard on a numeric/email field is a small but real UX cost on every use.
- Set `textInputAction` intentionally: `TextInputAction.next` to move to the next field, `TextInputAction.done` on the last field, wired to actually submit or dismiss the keyboard — a form where hitting "next" does nothing is broken, not minor.
- Dismiss the keyboard on tap-outside (`GestureDetector` with `onTap: () => FocusScope.of(context).unfocus()` wrapping the form, or `resizeToAvoidBottomInset` handled correctly) so the keyboard doesn't linger and obscure content after the user is done with a field.
