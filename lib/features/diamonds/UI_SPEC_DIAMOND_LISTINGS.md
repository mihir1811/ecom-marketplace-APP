# Diamond Listings Results Screen — UI Specification

## Overview

The Diamond Listings Results Screen displays paginated search results from the Diamond Finder filters. It supports grid/list toggle, sort options, filter chip summaries, infinite scroll, and empty/loading/error states. All tokens reference the existing `AppColors`, `AppTypography`, `AppSpacing`, and `AppShadows` design system.

---

## 1. Color Palette Mapping

### 1.1 AppBar / Header

| Element | Light Mode | Dark Mode |
|---|---|---|
| AppBar background | `AppColors.creamBg` (#FCFCFA) | `AppColors.obsidianBg` (#0B0C0E) |
| AppBar title ("X Diamonds Found") | `AppColors.textPrimaryLight` (#111827) | `AppColors.textPrimaryDark` (#F9FAFB) |
| Back button icon | `AppColors.textPrimaryLight` (#111827) | `AppColors.textPrimaryDark` (#F9FAFB) |
| "Edit Filters" text button | `AppColors.bronze` (#9E7753) | `AppColors.bronzeLight` (#BCA38B) |

### 1.2 Filter Summary Chips Row

| Element | Light Mode | Dark Mode |
|---|---|---|
| Chip background (selected) | `AppColors.charcoal` (#111827) | `AppColors.slateBorder` (#2E3035) |
| Chip text (selected) | `AppColors.warmWhite` (#FFFFFF) | `AppColors.textPrimaryDark` (#F9FAFB) |
| Chip dismiss icon (selected) | `AppColors.warmWhite` (#FFFFFF), `Icons.close`, 14dp | `AppColors.textPrimaryDark` (#F9FAFB), `Icons.close`, 14dp |
| Chip border (selected) | `AppColors.charcoal` (#111827) | `AppColors.slateBorder` (#2E3035) |
| "Clear All" text button | `AppColors.terracotta` (#D9463E) | `AppColors.terracottaLight` (#E5736E) |

### 1.3 Sort Bar

| Element | Light Mode | Dark Mode |
|---|---|---|
| Row background | `AppColors.creamBg` (#FCFCFA) | `AppColors.obsidianBg` (#0B0C0E) |
| Sort option label (active) | `AppColors.charcoal` (#111827) | `AppColors.textPrimaryDark` (#F9FAFB) |
| Sort option label (inactive) | `AppColors.textMutedLight` (#9CA3AF) | `AppColors.textMutedDark` (#6B7280) |
| Active indicator underline | `AppColors.bronze` (#9E7753) | `AppColors.bronzeLight` (#BCA38B) |
| Sort icon (chevron down) | `AppColors.textMutedLight` (#9CA3AF), `Icons.arrow_drop_down`, 18dp | `AppColors.textMutedDark` (#6B7280), `Icons.arrow_drop_down`, 18dp |

### 1.4 Grid/List Toggle

| Element | Light Mode | Dark Mode |
|---|---|---|
| Active toggle icon | `AppColors.bronze` (#9E7753) | `AppColors.bronzeLight` (#BCA38B) |
| Inactive toggle icon | `AppColors.textMutedLight` (#9CA3AF) | `AppColors.textMutedDark` (#6B7280) |
| Toggle background | Transparent | Transparent |
| Toggle container border | `AppColors.warmBorder` (#E2E2DC) | `AppColors.slateBorder` (#2E3035) |

### 1.5 Diamond Card — Grid Variant

| Element | Light Mode | Dark Mode |
|---|---|---|
| Card background | `AppColors.warmWhite` (#FFFFFF) | `AppColors.slateSurface` (#16181B) |
| Card border | `AppColors.warmBorder` (#E2E2DC), 1.0px | `AppColors.slateBorder` (#2E3035), 1.0px |
| Card shadow | `AppShadows.cardLight` | `AppShadows.cardDark` |
| Image placeholder background | `AppColors.sandSurface` (#F4F4F0) | `AppColors.obsidianBg` (#0B0C0E) |
| Price text | `AppColors.textPrimaryLight` (#111827) | `AppColors.textPrimaryDark` (#F9FAFB) |
| Shape name text | `AppColors.textSecondaryLight` (#4B5563) | `AppColors.textSecondaryDark` (#D1D5DB) |
| Carat weight text | `AppColors.textMutedLight` (#9CA3AF) | `AppColors.textMutedDark` (#6B7280) |
| Badge text (cut/color/clarity/cert) | `AppColors.textSecondaryLight` (#4B5563) | `AppColors.textSecondaryDark` (#D1D5DB) |
| Badge background | `AppColors.sandSurface` (#F4F4F0) | `AppColors.obsidianBg` (#0B0C0E) |

### 1.6 Diamond Card — List Variant

| Element | Light Mode | Dark Mode |
|---|---|---|
| Same as grid card for background, border, shadow, text colors | Same | Same |
| Image thumbnail background | `AppColors.sandSurface` (#F4F4F0) | `AppColors.obsidianBg` (#0B0C0E) |
| Certificate text | `AppColors.textMutedLight` (#9CA3AF) | `AppColors.textMutedDark` (#6B7280) |

### 1.7 Results Count

| Element | Light Mode | Dark Mode |
|---|---|---|
| Text | `AppColors.textSecondaryLight` (#4B5563) | `AppColors.textSecondaryDark` (#D1D5DB) |

### 1.8 Empty State

| Element | Light Mode | Dark Mode |
|---|---|---|
| Illustration stroke/fill | `AppColors.textMutedLight` (#9CA3AF) | `AppColors.textMutedDark` (#6B7280) |
| Heading text ("No Diamonds Found") | `AppColors.textPrimaryLight` (#111827) | `AppColors.textPrimaryDark` (#F9FAFB) |
| Message text ("Try adjusting your filters") | `AppColors.textSecondaryLight` (#4B5563) | `AppColors.textSecondaryDark` (#D1D5DB) |
| "Clear All Filters" button background | `AppColors.terracotta` (#D9463E) | `AppColors.terracottaLight` (#E5736E) |
| "Clear All Filters" button text | `AppColors.warmWhite` (#FFFFFF) | `AppColors.charcoal` (#111827) |

### 1.9 Loading Shimmer

| Element | Light Mode | Dark Mode |
|---|---|---|
| Shimmer base color | `AppColors.sandSurface` (#F4F4F0) | `AppColors.slateSurface` (#16181B) |
| Shimmer highlight color | `AppColors.warmWhite` (#FFFFFF) | `AppColors.slateBorder` (#2E3035) |

### 1.10 Error State

| Element | Light Mode | Dark Mode |
|---|---|---|
| Error icon | `AppColors.error` (#DC2626) | `AppColors.error` (#DC2626) |
| Error message text | `AppColors.textSecondaryLight` (#4B5563) | `AppColors.textSecondaryDark` (#D1D5DB) |
| Retry button background | `AppColors.charcoal` (#111827) | `AppColors.textPrimaryDark` (#F9FAFB) |
| Retry button text | `AppColors.warmWhite` (#FFFFFF) | `AppColors.charcoal` (#111827) |

---

## 2. Typography Mapping

| Text Element | AppTypography Style | Overrides |
|---|---|---|
| AppBar title ("342 Diamonds Found") | `AppTypography.title` (Playfair Display, 15px, w600) | `letterSpacing: 0.5` |
| Results count subtitle | `AppTypography.caption` (Inter, 10px, w400) | `color: AppColors.textSecondaryLight/.textSecondaryDark` |
| Diamond card — Price | `AppTypography.title` (Playfair Display, 15px, w600) | Bold variant if desired |
| Diamond card — Shape name | `AppTypography.label` (Inter, 12px, w500) | — |
| Diamond card — Carat weight | `AppTypography.caption` (Inter, 10px, w400) | — |
| Diamond card — Cut badge | `AppTypography.caption` (Inter, 10px, w400) | `fontWeight: FontWeight.w600` |
| Diamond card — Color badge | `AppTypography.caption` (Inter, 10px, w400) | `fontWeight: FontWeight.w600` |
| Diamond card — Clarity badge | `AppTypography.caption` (Inter, 10px, w400) | `fontWeight: FontWeight.w600` |
| Diamond card — Certificate | `AppTypography.caption` (Inter, 10px, w400) | `fontWeight: FontWeight.w500` |
| Filter chip label | `AppTypography.caption` (Inter, 10px, w400) | `fontWeight: FontWeight.w500` |
| Sort option label | `AppTypography.label` (Inter, 12px, w500) | selected: `fontWeight: FontWeight.w600` |
| Sort "Sort by:" prefix | `AppTypography.caption` (Inter, 10px, w400) | `color: AppColors.textMutedLight/.textMutedDark` |
| Empty state — Heading | `AppTypography.headline` (Playfair Display, 20px, w700) | — |
| Empty state — Message | `AppTypography.body` (Inter, 13px, w400) | — |
| Empty state — Button | `AppTypography.label` (Inter, 12px, w500) | `fontWeight: FontWeight.w600` |
| "Edit Filters" button | `AppTypography.label` (Inter, 12px, w500) | `fontWeight: FontWeight.w600`, `color: AppColors.bronze` |
| "Clear All" link | `AppTypography.caption` (Inter, 10px, w400) | `fontWeight: FontWeight.w600`, `color: AppColors.terracotta` |
| Error message | `AppTypography.body` (Inter, 13px, w400) | — |
| Retry button | `AppTypography.label` (Inter, 12px, w500) | `fontWeight: FontWeight.w600` |
| Loading indicator text | `AppTypography.caption` (Inter, 10px, w400) | `color: AppColors.textMutedLight/.textMutedDark` |

---

## 3. Spacing & Layout Grid

### 3.1 Grid View (Phone — 2 columns)

| Parameter | Value |
|---|---|
| Horizontal screen padding (start/end) | `AppSpacing.s16` (12dp) |
| Horizontal inter-item gap (column spacing) | `AppSpacing.s12` (8dp) |
| Vertical inter-item gap (row spacing) | `AppSpacing.s16` (12dp) |
| Card internal padding (all sides) | `EdgeInsets.all(AppSpacing.s12)` (8dp) |
| Image area (GridView) | `height: 140dp`, full card width minus padding |
| Image container margin (bottom) | `AppSpacing.s8` (4dp) |
| Shape name to carat gap | `0dp` (they stack) |
| Carat to price gap | `AppSpacing.s8` (4dp) |
| Price to badges row gap | `AppSpacing.s4` (2dp) |
| Badges row internal spacing (between badges) | `AppSpacing.s4` (2dp) |

### 3.2 List View (Full-width row cards)

| Parameter | Value |
|---|---|
| Horizontal screen padding | `AppSpacing.s16` (12dp) |
| Vertical spacing between cards | `AppSpacing.s12` (8dp) |
| Card internal vertical padding | `AppSpacing.s12` (8dp) |
| Card internal horizontal padding | `AppSpacing.s16` (12dp) |
| Image thumbnail size | `80dp × 80dp` |
| Image border radius | `AppSpacing.r8` (6dp) |
| Image to text column gap | `AppSpacing.s16` (12dp) |
| Text column internal spacing | `AppSpacing.s4` (2dp) between rows |
| Price alignment | `Align` top-right in the trailing area |

### 3.3 Filter Summary Chips Row

| Parameter | Value |
|---|---|
| Row horizontal padding | `AppSpacing.s16` (12dp) |
| Row vertical padding (top/bottom) | `AppSpacing.s8` (4dp) |
| Spacing between chips | `AppSpacing.s8` (4dp) |
| Chip horizontal padding (internal) | `EdgeInsets.symmetric(horizontal: 10, vertical: 6)` |
| Chip border radius | `AppSpacing.r8` (6dp) |
| Chip dismiss icon size | `14dp` |
| Chip dismiss icon padding (from trailing edge) | `2dp` |
| "Clear All" margin left | `AppSpacing.s8` (4dp) |

### 3.4 Sort Bar

| Parameter | Value |
|---|---|
| Row height | `40dp` |
| Row horizontal padding | `AppSpacing.s16` (12dp) |
| Internal horizontal spacing between items | `AppSpacing.s16` (12dp) |
| Each item internal padding (horizontal) | `AppSpacing.s8` (4dp) |
| Active item underline height | `2dp` |
| Active item underline bottom margin | `2dp` |

### 3.5 Grid/List Toggle

| Parameter | Value |
|---|---|
| Toggle icon size | `22dp` |
| Toggle container width | `72dp` |
| Toggle container height | `36dp` |
| Toggle container border radius | `AppSpacing.r8` (6dp) |
| Toggle container border | 1px solid `AppColors.warmBorder` / `AppColors.slateBorder` |
| Inner icon padding | `EdgeInsets.symmetric(horizontal: 8, vertical: 6)` |

### 3.6 Results Count

| Parameter | Value |
|---|---|
| Position | Between AppBar title/subtitle area and filter chips row |
| Margin top | `AppSpacing.s4` (2dp) below title |
| Margin bottom | `AppSpacing.s8` (4dp) above chips |

### 3.7 Empty State

| Parameter | Value |
|---|---|
| Centering | Full screen center (use `Center` widget or `Expanded` + `Center`) |
| Illustration size | `120dp × 120dp` (use `Icons.diamond_outlined` at 120dp with opacity 0.3, or a custom SVG at that size) |
| Icon color | `AppColors.textMutedLight` / `AppColors.textMutedDark` at 30% opacity |
| Illustration to heading gap | `AppSpacing.s24` (16dp) |
| Heading to message gap | `AppSpacing.s8` (4dp) |
| Message to button gap | `AppSpacing.s24` (16dp) |
| Button padding | `EdgeInsets.symmetric(horizontal: AppSpacing.s32, vertical: AppSpacing.s16)` |

### 3.8 Loading Shimmer

| Parameter | Value |
|---|---|
| Shimmer card height (grid) | Match real card height (approx `260dp`) |
| Shimmer card height (list) | Match real list card height (approx `112dp`) |
| Shimmer border radius | `AppSpacing.r12` (8dp) |
| Shimmer animation duration | `1500ms` loop |

### 3.9 Error State

| Parameter | Value |
|---|---|
| Layout | Centered column |
| Icon size | `56dp` |
| Icon to message gap | `AppSpacing.s16` (12dp) |
| Message to retry gap | `AppSpacing.s24` (16dp) |
| Retry button min width | `160dp` |

---

## 4. Component Specifications

### 4.1 Diamond Card — Grid Variant (2 columns)

```
┌──────────────────────┐
│ ┌──────────────────┐ │  ← card internal padding: AppSpacing.s12 all sides
│ │     [Image]      │ │  ← 140dp height, full width minus 16dp, r8 rounded
│ │   diamond shape  │ │  ← placeholder: icon or network image
│ └──────────────────┘ │
│                      │
│  Round               │  ← AppTypography.label, textSecondary
│  0.50 ct             │  ← AppTypography.caption, textMuted
│                      │
│  $1,234              │  ← AppTypography.title, textPrimary, bold
│                      │
│  E  VS1  GIA  EX     │  ← badge row: AppTypography.caption bold
└──────────────────────┘
```

**Detailed specifications:**

| Property | Value |
|---|---|
| Card width | Stretches to column width |
| Card border radius | `AppSpacing.r12` (8dp) |
| Card border | 1.0px, `AppColors.warmBorder` / `AppColors.slateBorder` |
| Card shadow | `AppShadows.cardLight` / `AppShadows.cardDark` |
| Image container height | `140dp` |
| Image container width | Match parent (minus 16dp internal padding) |
| Image border radius | `AppSpacing.r8` (6dp) |
| Image placeholder | Diamond icon or gem silhouette at 40% opacity, centered |
| Image background | `AppColors.sandSurface` / `AppColors.obsidianBg` |
| Shape name | Positioned at top-left below image area, no extra container |
| Carat weight | Directly below shape name |
| Price | Below carat, prominent using `AppTypography.title` |
| Badges row | Horizontal `Row`, wrapping if needed, `AppSpacing.s4` gap |
| Each badge | Container with `EdgeInsets.symmetric(horizontal: 4, vertical: 2)`, `AppColors.sandSurface`/`AppColors.obsidianBg` background, `AppSpacing.r4` radius |
| Card internal padding | `EdgeInsets.all(AppSpacing.s12)` |
| Image to content gap | `AppSpacing.s8` |

### 4.2 Diamond Card — List Variant (full-width row)

```
┌──────────────────────────────────────────────┐
│  ┌────────┐  Round                    $1,234 │
│  │        │  0.50 ct                        │
│  │  Img   │  Cut: Excellent                 │
│  │ 80x80  │  Color: E   Clarity: VS1        │
│  │        │  Cert: GIA                       │
│  └────────┘                                  │
└──────────────────────────────────────────────┘
```

**Detailed specifications:**

| Property | Value |
|---|---|
| Card width | Full screen width minus `AppSpacing.s16 × 2` |
| Card height | Auto (wraps content, approx 112dp) |
| Card border radius | `AppSpacing.r12` (8dp) |
| Card border | 1.0px, `AppColors.warmBorder` / `AppColors.slateBorder` |
| Card shadow | `AppShadows.cardLight` / `AppShadows.cardDark` |
| Image size | `80dp × 80dp` (fixed square) |
| Image border radius | `AppSpacing.r8` (6dp) |
| Image background | `AppColors.sandSurface` / `AppColors.obsidianBg` |
| Image to text gap | `AppSpacing.s16` |
| Text column | 6 rows stacked with `AppSpacing.s2` gap between detail lines |
| Row 1: Shape name | `AppTypography.label`, textSecondary |
| Row 2: Carat weight | `AppTypography.caption`, textMuted |
| Row 3: Cut | `AppTypography.caption`, textSecondary, label "Cut: " muted, value normal |
| Row 4: Color + Clarity | `AppTypography.caption`, textSecondary |
| Row 5: Certificate | `AppTypography.caption`, textMuted |
| Price | Aligned to top-right, `AppTypography.title`, textPrimary |
| Card internal padding | `EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12)` |

### 4.3 Filter Summary Chips Row

```
[ Round ✕ ]  [ E-F ✕ ]  [ VS1 ✕ ]  [ Ideal ✕ ]  Clear All
```

| Property | Value |
|---|---|
| Layout | Horizontal `ListView` (scrollDirection: horizontal) with `shrinkWrap: true` |
| Chip shape | Fully rounded pill (`AppSpacing.circular` = 999) |
| Chip background (selected) | `AppColors.charcoal` / `AppColors.slateBorder` |
| Chip text style | `AppTypography.caption`, `w500`, `AppColors.warmWhite`/textPrimaryDark |
| Chip padding | `EdgeInsets.only(left: 10, right: 4, top: 6, bottom: 6)` — extra right for dismiss icon |
| Dismiss icon | `Icons.close`, 14dp, color matches text |
| Dismiss icon hit area | At least 32dp (use `InkWell` or `GestureDetector` with `padding: 4`) |
| "Clear All" | `GestureDetector` or `TextButton`, `AppTypography.caption`, `w600`, `AppColors.terracotta` |
| "Clear All" padding | `EdgeInsets.symmetric(horizontal: 8, vertical: 6)` |

### 4.4 Sort Bar

```
[ Sort by: ▼ ]  [ Price ↓ ]  [ Carat ↓ ]  [ Popularity ]
```

| Property | Value |
|---|---|
| Layout | Horizontal `ListView` (scrollDirection: horizontal) with `shrinkWrap: true` |
| Row height | `40dp` |
| Padding horizontal | `AppSpacing.s16` |
| "Sort by:" prefix | `AppTypography.caption`, `textMutedLight`/`textMutedDark`, not tappable |
| Sort option item | `GestureDetector` with `Padding(horizontal: 8, vertical: 6)` |
| Active sort | Text in `AppColors.charcoal`/`textPrimaryDark`, `AppTypography.label`, `w600`, underline 2dp bronze at bottom |
| Inactive sort | Text in `AppColors.textMutedLight`/`textMutedDark`, `AppTypography.label`, `w500` |
| Sort direction icon | `Icons.arrow_drop_down` or `Icons.arrow_upward` (18dp, aligned next to active text) |
| Scroll physics | `BouncingScrollPhysics` |

### 4.5 Grid/List Toggle

```
[ ⊞ ] [ ☰ ]    (Icons.grid_view_rounded, Icons.view_list_rounded)
```

| Property | Value |
|---|---|
| Placement | Right side of AppBar (in `actions` slot) |
| Container | Small container with border, or `SegmentedButton`-like pair |
| Container width | `72dp` |
| Container height | `36dp` |
| Border radius | `AppSpacing.r8` (6dp) |
| Border | 1.0px, `AppColors.warmBorder` / `AppColors.slateBorder` |
| Grid icon | `Icons.grid_view_rounded`, 22dp |
| List icon | `Icons.view_list_rounded`, 22dp |
| Active icon color | `AppColors.bronze` / `AppColors.bronzeLight` |
| Inactive icon color | `AppColors.textMutedLight` / `AppColors.textMutedDark` |
| Active background segment | `AppColors.sandSurface` / `AppColors.slateSurface` |
| Inactive background segment | Transparent |
| Inner padding per segment | `EdgeInsets.symmetric(horizontal: 8, vertical: 6)` |
| Transition | `AnimatedContainer` or `AnimatedSwitcher` for smooth state swap |

### 4.6 Empty State

```
         💎
         (Icons.diamond_outlined, 120dp, 30% opacity)

     No Diamonds Found
    Try adjusting your filters

    [ Clear All Filters ]
```

| Property | Value |
|---|---|
| Layout | `Center` widget wrapping a `Column` with `mainAxisSize: MainAxisSize.min` |
| Icon | `Icons.diamond_outlined`, 120dp, 30% opacity |
| Icon color | `AppColors.textMutedLight` / `AppColors.textMutedDark` |
| Icon to heading gap | `AppSpacing.s24` (16dp) |
| Heading | `AppTypography.headline`, `textPrimaryLight`/`textPrimaryDark` |
| Heading to message gap | `AppSpacing.s8` (4dp) |
| Message | `AppTypography.body`, `textSecondaryLight`/`textSecondaryDark` |
| Message to button gap | `AppSpacing.s24` (16dp) |
| Button | `ElevatedButton` or custom styled button |
| Button background | `AppColors.terracotta` / `AppColors.terracottaLight` |
| Button text | "Clear All Filters", `AppTypography.label`, w600, `AppColors.warmWhite`/`AppColors.charcoal` |
| Button shape | `RoundedRectangleBorder(AppSpacing.r8)` |
| Button padding | `EdgeInsets.symmetric(horizontal: AppSpacing.s32, vertical: AppSpacing.s16)` |

### 4.7 Loading State (Shimmer)

| Property | Value |
|---|---|
| Grid variant | 2-column layout of shimmer cards matching real card dimensions |
| Shimmer card | Container with `AppSpacing.r12` radius, base color `AppColors.sandSurface`/`AppColors.slateSurface` |
| Shimmer image area | Top 140dp section with `AppSpacing.r8` rounded bottom corners on the block |
| Shimmer text lines | 3 short blocks at bottom of card: 60dp, 40dp, 80dp widths, 8dp height each, 4dp gap |
| List variant | Full-width shimmer card with 80×80 image block and 5 text line blocks |
| Animation | Linear gradient sweep (use `Shimmer` package or custom `AnimatedBuilder`) |
| Duration | 1500ms, infinite loop |
| Count | Show 6 shimmer cards in grid, 5 in list |

### 4.8 Error State

| Property | Value |
|---|---|
| Layout | `Center` > `Column(mainAxisSize: min)` |
| Icon | `Icons.error_outline`, 56dp, `AppColors.error` |
| Icon to message gap | `AppSpacing.s16` |
| Message | "Something went wrong. Please try again." |
| Message style | `AppTypography.body`, `textSecondaryLight`/`textSecondaryDark` |
| Message to button gap | `AppSpacing.s24` |
| Retry button | `ElevatedButton`, `AppColors.charcoal`/`textPrimaryDark` background |
| Retry text | "Retry", `AppTypography.label`, w600 |
| Retry button shape | `RoundedRectangleBorder(AppSpacing.r8)` |
| Retry button min width | `160dp` |

---

## 5. Dark Mode Variations

Every element in Section 1 already specifies both light and dark mode tokens. Summary of dark mode changes:

| Area | Light → Dark Change |
|---|---|
| Scaffold background | `AppColors.creamBg` → `AppColors.obsidianBg` |
| Card surfaces | `AppColors.warmWhite` → `AppColors.slateSurface` |
| Borders | `AppColors.warmBorder` → `AppColors.slateBorder` |
| Primary text | `AppColors.textPrimaryLight` → `AppColors.textPrimaryDark` |
| Secondary text | `AppColors.textSecondaryLight` → `AppColors.textSecondaryDark` |
| Muted text | `AppColors.textMutedLight` → `AppColors.textMutedDark` |
| Bronze accents | `AppColors.bronze` → `AppColors.bronzeLight` |
| Chip selected bg | `AppColors.charcoal` → `AppColors.slateBorder` |
| Shimmer base | `AppColors.sandSurface` → `AppColors.slateSurface` |
| Shimmer highlight | `AppColors.warmWhite` → `AppColors.slateBorder` |
| Shadows | `AppShadows.cardLight` → `AppShadows.cardDark` |
| Error/terracotta accent | `AppColors.terracotta` → `AppColors.terracottaLight` |

---

## 6. Responsive Behavior

| Breakpoint | Grid Columns | Card Width | Notes |
|---|---|---|---|
| Small phone (<360dp) | 2 columns | Half screen minus gaps | Reduce image height to 120dp |
| Phone (360–639dp) | 2 columns | ~half screen minus gaps | Standard spec |
| Tablet (640–1023dp) | 3 columns | ~1/3 screen minus gaps | Increase image height to 160dp |
| Large tablet (1024dp+) | 4 columns | ~1/4 screen minus gaps | Increase image height to 180dp |

| Element | Responsive Behavior |
|---|---|
| List view | Full-width card on all breakpoints |
| Filter chips row | Horizontal `ListView` with `BouncingScrollPhysics`; overflow scrolls on all sizes |
| Sort bar | Horizontal scroll; items are tappable, no dropdown needed |
| AppBar | "Edit Filters" always visible in `actions` slot; title adjusts with `flexibleSpace` on scroll |
| Empty state | Centered; illustration stays same size across breakpoints |
| Error state | Centered; no layout change |
| Loading shimmer | Adjusts to match current grid column count |

---

## 7. Layout Composition (Screen Structure)

```
┌─────────────────────────────────────┐
│ AppBar                              │
│  ← Back    342 Diamonds Found  [⊞☰] │  ← title: AppTypography.title
│  "Edit Filters" (in actions)        │     subtitle: AppTypography.caption
├─────────────────────────────────────┤
│ [Round ✕] [E-F ✕] [VS1 ✕] [Clear]  │  ← Filter chips, horizontal scroll
├─────────────────────────────────────┤
│ Sort by: ▼  Price ↓  Carat ↓  Pop.  │  ← Sort bar, horizontal scroll
├─────────────────────────────────────┤
│                                     │
│  ┌──────────┐  ┌──────────┐         │
│  │ Img      │  │ Img      │         │
│  │ Round    │  │ Cushion  │         │  ← Grid (2 cols) or List view
│  │ 0.50ct   │  │ 1.02ct   │         │
│  │ $1,234   │  │ $4,567   │         │
│  │ E VS1    │  │ D IF GIA │         │
│  └──────────┘  └──────────┘         │
│                                     │
│  ┌──────────┐  ┌──────────┐         │
│  │ Img      │  │ Img      │         │
│  │ ...      │  │ ...      │         │
│  └──────────┘  └──────────┘         │
│                                     │
│         [ Loading indicator ]        │  ← infinite scroll: CircularProgressIndicator
│         "Loading more..."            │
└─────────────────────────────────────┘
```

---

## 8. Key Interaction Details

| Interaction | Behavior |
|---|---|
| Grid/List toggle | Tap icon to switch; transition uses `AnimatedSwitcher` or crossfade (300ms ease) |
| Sort option tap | Updates active sort; results re-fetch with new sort parameter |
| Filter chip dismiss | Tapping ✕ removes that filter value and re-fetches results |
| "Clear All" chips | Removes all active filters, resets to unfiltered state |
| "Edit Filters" | Navigates back to `DiamondSearchScreen` with current filter state preserved |
| Scroll to bottom | Triggers next page load; shows `CircularProgressIndicator` (24dp) at bottom |
| Diamond card tap | Navigates to Diamond Detail Screen (future) |
| Shimmer display | Shows on initial load and when pull-to-refresh triggers new search |
| Error retry | Re-fetches the current page |

---

## 9. Design Principles Applied

| Principle | Implementation |
|---|---|
| Luxury/premium aesthetic | Charcoal and bronze primary palette; serif Playfair for prices and headings |
| Clean and minimal | Generous negative space around cards; muted secondary info reduced to 10px caption |
| High information density | Diamond specs compressed into compact badge row; no wasted labels |
| Consistent with DiamondSearchScreen | Same card border radius (r12), same font hierarchy, same color tokens |
| Dark mode fully specified | Every token has a dark variant; contrast ratios preserved |
| Accessibility | All text >= WCAG AA 4.5:1; touch targets >= 44dp on interactive elements; dismiss icons have `Semantics` labels |
| Performance | Shimmer uses simple `Container` blocks; lazy loading via `ScrollController`; images use cached network image |

---

## 10. File Structure

```
lib/features/diamonds/presentation/
  screens/
    diamond_listings_screen.dart       (new — main screen)
  widgets/
    diamond_card_grid.dart             (new — grid card widget)
    diamond_card_list.dart             (new — list card widget)
    listings_filter_chips.dart         (new — filter summary chips row)
    listings_sort_bar.dart             (new — sort options bar)
    listings_empty_state.dart          (new — empty state)
    listings_shimmer.dart              (new — shimmer loading)
    listings_error_state.dart          (new — error+retry state)
```

Route addition in `diamonds_routes.dart`:

```
GoRoute(
  path: 'listings',
  builder: (context, state) => const DiamondListingsScreen(),
)
```
