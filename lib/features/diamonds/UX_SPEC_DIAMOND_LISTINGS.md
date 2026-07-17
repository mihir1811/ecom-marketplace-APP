# UX Specification: Diamond Listings Results Screen

**Feature:** Diamond Listings Results  
**Route:** `/diamonds/results`  
**Feature folder:** `lib/features/diamonds/`  
**Layer structure:** `domain/` → `application/` → `presentation/`  
**Target implementation:** Mobile App Builder, UI Designer, Performance Benchmarker  

---

## 1. Screen Layout (Top to Bottom Wireframe)

### 1.1 AppBar / Header

```
┌─────────────────────────────────────────────────┐
│  ← back    DIAMOND RESULTS     [ Edit Filters ] │  ← AppBar
├─────────────────────────────────────────────────┤
```

| Element | Details |
|---|---|
| Back button (`←`) | `Icons.arrow_back`. Calls `context.pop()` to return to the previous screen (search or app shell). |
| Title | **"DIAMOND RESULTS"** — `AppTypography.title`, bold, letter-spacing 1.0. Centers in AppBar. |
| "Edit Filters" button | Text button, right-aligned. Tapping navigates **back** to `/diamonds` (see §4.2). Label: `"EDIT FILTERS"` — `AppTypography.label`, bold, `AppColors.bronze`. |

**Navigation relationship**: When the user arrives at this screen, it is pushed **on top** of DiamondSearchScreen (i.e., the search screen remains in the stack). Pressing back or "Edit Filters" pops to the search screen, preserving all filter state via `diamondSearchProvider`.

### 1.2 Filter Summary Chips Row

```
┌─────────────────────────────────────────────────┐
│ [Round ▼] [1-1.49 ct ▼] [D-F ▼] [VS+ ▼]  +2   │  ← horizontally scrollable
├─────────────────────────────────────────────────┤
```

| Property | Value |
|---|---|
| Container | Horizontal `ListView`, single child scroll direction. 12px top/bottom padding, 16px horizontal padding. |
| Chip style | `InputChip` or custom chip with `AppColors.bronze` border on light mode, `AppColors.slateBorder` on dark. Background: `AppColors.warmWhite`/`AppColors.slateSurface`. Text: `AppTypography.label`, 12px. |
| Dismiss icon | `Icons.close`, size 16px, on trailing edge of chip. |
| Max visible | Show first 4-5 chips + overflow chip `"+N"` if >5 active filters. Tapping overflow chip scrolls to show more (or opens a bottom sheet). |
| Empty state | Row is hidden (zero height) when no filters are active. See §1.7. |

**Filter-to-chip mapping** (generate chips for any non-default field):

| Filter Field | Chip Label Format | Example | `matchingCountProvider` field |
|---|---|---|---|
| `labNatural` | `"Natural"` or `"Lab Grown"` | `"Natural"` | `labNatural` |
| `shapes` | Per shape name | `"Round"`, `"Princess"` | `shapes[]` |
| `minPrice` / `maxPrice` | `"\$0 - \$10,000"` | `"\$500 - \$5,000"` | `minPrice`, `maxPrice` |
| `minCarat` / `maxCarat` | `"X.XX - Y.YY ct"` | `"1.00 - 1.49 ct"` | `minCarat`, `maxCarat` |
| `minColorIndex` / `maxColorIndex` | `"Color D-F"` | `"Color D-F"` | color range |
| `selectedStandardColors` | Per color | `"D"`, `"E"` | `selectedStandardColors[]` |
| `isFancyColor` | `"Fancy Color"` | `"Fancy Color"` | `isFancyColor` |
| `selectedFancyColors[]` | Per fancy color | `"Pink"` | `selectedFancyColors[]` |
| `minClarityIndex` / `maxClarityIndex` | `"Clarity FL-VS1"` | `"Clarity VS+"` | clarity range |
| `selectedClarityGrades[]` | Per grade | `"VVS1"` | `selectedClarityGrades[]` |
| `selectedCuts[]` | Per cut | `"Excellent"` | `selectedCuts[]` |
| `selectedFinishPreset[]` | Preset label | `"3X"` | `selectedFinishPreset[]` |
| `eyeClean` | `"Eye Clean"` | `"Eye Clean"` | `eyeClean` |
| `noBgm` | `"No BGM"` | `"No BGM"` | `noBgm` |
| `heartAndArrow` | `"H&A"` | `"H&A"` | `heartAndArrow` |
| `threeEx` | `"3EX"` | `"3EX"` | `threeEx` |
| `sellersWithVideo` | `"With Video"` | `"With Video"` | `sellersWithVideo` |
| `sellersWithImages` | `"With Images"` | `"With Images"` | `sellersWithImages` |
| `selectedFluorescence[]` | Per fluorescence | `"Faint"` | `selectedFluorescence[]` |
| `selectedMilkyGrades[]` | Per milky grade | `"Slightly"` | `selectedMilkyGrades[]` |
| `selectedLabs[]` | Per lab | `"GIA"` | `selectedLabs[]` |
| `selectedOrigin` | Country name | `"Botswana"` | `selectedOrigin` |
| `companyNameSearch` | `"Company: XYZ"` | `"Company: Tiffany"` | `companyNameSearch` |
| `vendorLocationSearch` | `"Location: XYZ"` | `"Location: NY"` | `vendorLocationSearch` |
| `selectedGirdles[]` | Per girdle | `"Medium"` | `selectedGirdles[]` |
| `selectedCulets[]` | Per culet | `"None"` | `selectedCulets[]` |
| `selectedEnhancement` | Enhancement type | `"HPHT"` | `selectedEnhancement` |
| `selectedPolish[]` | Per polish | `"Excellent"` | `selectedPolish[]` |
| `selectedSymmetry[]` | Per symmetry | `"Excellent"` | `selectedSymmetry[]` |

**Chip dismissal behavior**: Tapping the dismiss icon on a chip calls the corresponding **clear/reset method** on `DiamondSearchNotifier` (e.g., `clearCuts()`, `clearClarityGrades()`, `reset()` for individual fields). This triggers a rebuild of the results list via the API call that watches `diamondSearchProvider`.

### 1.3 Sort Bar + Grid/List Toggle + Results Count

```
┌─────────────────────────────────────────────────┐
│ 12,450 diamonds     ▼ Price: Low-High    [≡] [▦]│  ← sort bar
├─────────────────────────────────────────────────┤
```

This is a single horizontal row with three zones:

**Left zone — Results count**
| Property | Value |
|---|---|
| Text | `"12,450 diamonds"` — number from `matchingCountProvider` formatted with commas, followed by `" diamond"` (singular if === 1) or `" diamonds"`. |
| Style | `AppTypography.label`, `AppColors.textSecondaryLight`/`textSecondaryDark`. |

**Center zone — Sort dropdown**
| Property | Value |
|---|---|
| Trigger | A tap target showing currently selected sort option with a down-chevron icon. |
| Interaction | Tapping opens a **bottom sheet** (preferred on mobile) or a **dropdown menu** (on wider screens). |
| Selected option | Bold text, `AppColors.bronze`. Unselected: `AppColors.textSecondaryLight`/`textSecondaryDark`. |
| Min touch target | 48x48dp. |

**Right zone — View toggle**
| Property | Value |
|---|---|
| Grid button | `Icons.grid_view_rounded` — highlighted when grid mode is active. |
| List button | `Icons.view_list_rounded` — highlighted when list mode is active. |
| Active color | `AppColors.bronze` |
| Inactive color | `AppColors.textMutedLight` / `AppColors.textMutedDark` |
| Min touch target | 48x48dp each. |

**Sort options** (displayed in bottom sheet / dropdown):

| Label | Sort Key | Description |
|---|---|---|
| `"Price: Low-High"` | `price_asc` | Sort by price ascending (default) |
| `"Price: High-Low"` | `price_desc` | Sort by price descending |
| `"Carat: Low-High"` | `carat_asc` | Sort by carat weight ascending |
| `"Carat: High-Low"` | `carat_desc` | Sort by carat weight descending |
| `"Popularity"` | `popularity` | Sort by popularity/metric (default when no explicit sort chosen — but user sees "Popularity" as the initial label if that's the API default; otherwise "Price: Low-High" is initial) |
| `"Discount %"` | `discount_desc` | Sort by highest discount percentage |
| `"Newest First"` | `newest` | Sort by listing date descending |

**Default sort**: `popularity` — the sort bar initially shows `"Popularity"`. If API does not support popularity, fallback to `"Price: Low-High"`.

### 1.4 Main Content Area (Diamond List)

The content below the sort bar is one of four states: **data**, **loading (shimmer)**, **empty**, or **error**.

#### 1.4.1 Grid View Card

```
┌──────────────────┐   ┌──────────────────┐
│ ┌──────────────┐ │   │ ┌──────────────┐ │
│ │  Diamond     │ │   │ │  Diamond     │ │
│ │  Image       │ │   │ │  Image       │ │
│ │  (3:4 ratio) │ │   │ │  (3:4 ratio) │ │
│ └──────────────┘ │   │ └──────────────┘ │
│ Round            │   │ Princess         │
│ 1.05 ct          │   │ 0.92 ct          │
│ $8,450           │   │ $6,200           │
│                  │   │                  │
│ ★ GIA            │   │ ★ GIA            │
└──────────────────┘   └──────────────────┘
```

| Element | Details |
|---|---|
| Card container | Rounded corners (12px), `AppColors.warmWhite`/`AppColors.slateSurface`, subtle shadow (`AppShadows.cardLight`). |
| Image | Top-aligned, aspect ratio **3:4** (portrait diamond photo). Fill width. Placeholder gradient if no image loaded (charcoal→bronze gradient). |
| Shape name | `AppTypography.caption`, `AppColors.textSecondaryLight`/`textSecondaryDark`, 1 line, ellipsis overflow. |
| Carat weight | `AppTypography.label`, `AppColors.textPrimaryLight`/`textPrimaryDark`, 1 line. Formatted as `"X.XX ct"`. |
| Price | `AppTypography.headline`, 16px, `AppColors.bronze`, bold. Formatted as `"\$8,450"` (or `"\$8,450"` with currency symbol). |
| Certificate | `AppTypography.caption`, `AppColors.textMutedLight`/`textMutedDark`, with star icon and lab name e.g. `"★ GIA"`. 1 line. |

**Grid layout**: 
- Phone portrait: **2 columns**, 12px gap between cards, 16px horizontal padding.
- Phone landscape: **3 columns**.
- Tablet portrait (≥768px): **3 columns**.
- Tablet landscape (≥1024px): **4 columns**.

#### 1.4.2 List View Card

```
┌─────────────────────────────────────────────────┐
│ ┌──────────┐                                    │
│ │ Diamond  │ Round  |  1.05 ct  |  D  |  VS1   │
│ │ Image    │ Cut: Excellent                      │
│ │ (80x100) │ GIA: 1234567890                     │
│ │          │                          $8,450     │
│ └──────────┘                                    │
├─────────────────────────────────────────────────┤
```

| Element | Details |
|---|---|
| Card container | Full width, rounded corners (8px), same surface/ border colors as grid. |
| Image | Left-aligned, fixed **80x100dp** (3:4 ratio preserved). Rounded left corners. |
| Row 1 (top) | **Shape name** (`AppTypography.label`, bold) + pipe separator + **Carat** ("1.05 ct") + pipe + **Color** ("D") + pipe + **Clarity** ("VS1"). All `AppTypography.caption`, `AppColors.textPrimaryLight`/`textPrimaryDark`. |
| Row 2 | **Cut**: "Excellent" — `AppTypography.caption`, `AppColors.textSecondaryLight`/`textSecondaryDark`. |
| Row 3 | **Certificate**: Lab name + certificate ID — `AppTypography.caption`, `AppColors.textMutedLight`/`textMutedDark`. Truncated with ellipsis if long. |
| Price | Right-aligned, `AppTypography.headline`, 16px, `AppColors.bronze`, bold. Positioned in top-right corner of the card. |
| Tap area | Entire card is tappable. |

**List layout**: Single column, full width. 8px gap between cards. 16px horizontal padding.

### 1.5 Empty / No Results State

```
┌─────────────────────────────────────────────────┐
│                                                  │
│                  ┌──────┐                        │
│                  │ 💎   │                        │  ← large diamond icon
│                  │      │                        │     (Icons.diamond_outlined, 80px,
│                  └──────┘                        │      AppColors.bronze 40% opacity)
│                                                  │
│           No diamonds match                      │
│            your filters                          │  ← AppTypography.headline, centered
│                                                  │
│     Try adjusting your search criteria           │  ← AppTypography.body, centered,
│     or clearing some filters.                    │     AppColors.textSecondary
│                                                  │
│        [ CLEAR ALL FILTERS ]                     │  ← Outlined button, AppColors.bronze
│                                                  │     border, calls notifier.reset()
│                                                  │
└─────────────────────────────────────────────────┘
```

| Element | Details |
|---|---|
| Icon | `Icons.diamond_outlined`, 80px, 40% opacity of `AppColors.bronze`. |
| Title | `AppTypography.headline`, centered, `AppColors.textPrimaryLight`/`textPrimaryDark`. |
| Subtitle | `AppTypography.body`, centered, `AppColors.textSecondaryLight`/`textSecondaryDark`. |
| CTA | "CLEAR ALL FILTERS" — outlined button, `AppColors.bronze` for border/text. Calls `notifier.reset()` and refreshes results. |
| Layout | Vertically and horizontally centered in the available scroll area. |

### 1.6 Loading State (Skeleton Shimmer)

**Grid skeleton** (replicates 2-column grid):

```
┌──────────────────┐   ┌──────────────────┐
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │   │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │  ← image placeholder (3:4)
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │   │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │   │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │   │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │   │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │
│ ───────────────  │   │ ───────────────  │
│ ▓▓▓▓▓▓▓▓         │   │ ▓▓▓▓▓▓▓▓         │  ← text line 1 (60% width)
│ ▓▓▓▓▓▓▓▓▓▓       │   │ ▓▓▓▓▓▓▓▓         │  ← text line 2 (40% width)
│ ▓▓▓▓▓▓▓▓         │   │ ▓▓▓▓▓▓▓▓▓▓       │  ← text line 3 (50% width)
└──────────────────┘   └──────────────────┘
```

**List skeleton** (replicates list):

```
┌─────────────────────────────────────────────────┐
│ ▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓ ▓ ▓▓▓▓▓ ▓ ▓▓ ▓ ▓▓▓▓          │
│ ▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓             │
│ ▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    ▓▓▓▓▓▓    │
│ 80px  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                │
└─────────────────────────────────────────────────┘
```

- Use `Shimmer` package or custom implementation with `AnimationController`.
- Shimmer highlight color: white 30% opacity on dark, white 60% opacity on light.
- Show **6 skeleton cards** on initial load (3 rows of 2 in grid, 6 rows in list).
- Shimmer base color: `AppColors.warmBorder` (light) / `AppColors.slateBorder` (dark).

### 1.7 Loading More (Infinite Scroll Indicator)

- Show a small circular progress indicator at the bottom of the list while fetching next page.
- Positioned below the last card, centered, 24px padding top/bottom.
- `SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))`.
- Use `AppColors.bronze` for the indicator color.

### 1.8 Error State

```
┌─────────────────────────────────────────────────┐
│                                                  │
│                  ┌──────┐                        │
│                  │ ⚠️   │                        │  ← Icons.cloud_off, 80px,
│                  └──────┘                        │     AppColors.terracotta
│                                                  │
│        Unable to load results                    │
│                                                  │
│     Please check your connection                 │
│     and try again.                               │
│                                                  │
│        [ TRY AGAIN ]                             │  ← Filled button, AppColors.bronze
│                                                  │     bg, retries API call
│                                                  │
└─────────────────────────────────────────────────┘
```

| Element | Details |
|---|---|
| Icon | `Icons.cloud_off` or `Icons.wifi_off`, 80px, `AppColors.terracotta`. |
| Title | `AppTypography.headline`, centered. |
| Subtitle | `AppTypography.body`, centered. |
| CTA | "TRY AGAIN" — filled button, `AppColors.bronze` background. Retriggers the API call for the current page. |

---

## 2. Interaction Design

### 2.1 Grid/List Toggle Behavior

| Action | Result |
|---|---|
| User taps **grid icon** | Results list transitions to grid layout (2 cols phone, 3-4 cols tablet). Icon becomes highlighted (`AppColors.bronze`). List icon becomes inactive. |
| User taps **list icon** | Results list transitions to list layout (1 col). List icon becomes highlighted. Grid icon becomes inactive. |
| Persistence | View mode is stored as a local `State` variable in the screen (no provider needed — not persisted across app restarts). |
| Transition | Animate crossfade or size transition (200ms ease-in-out) between layouts. |

### 2.2 Sort Selection UX

| Action | Result |
|---|---|
| User taps sort bar | A **bottom sheet** slides up (on mobile) showing the 7 sort options. On tablets / landscape, a **popup menu** anchored to the sort bar is acceptable. |
| User taps a sort option | Bottom sheet dismisses. Sort bar label updates to the selected option. API call re-triggers with new sort parameter. Results list resets to page 1. |
| Accessibility | Bottom sheet has `ariaLabel: "Sort options"`. Each option is a `ListTile` with a checkmark icon when selected. |

**Bottom sheet layout:**
```
┌─────────────────────────────────────────────────┐
│  Sort by                                         │  ← Title, AppTypography.title, bold
├─────────────────────────────────────────────────┤
│  ✓ Popularity                 [checkmark]        │  ← Selected option
│  ○ Price: Low-High                               │  ← Unselected options
│  ○ Price: High-Low                               │
│  ○ Carat: Low-High                               │
│  ○ Carat: High-Low                               │
│  ○ Discount %                                    │
│  ○ Newest First                                  │
└─────────────────────────────────────────────────┘
```

### 2.3 Filter Chip Dismissal

| Action | Result |
|---|---|
| User taps **×** on a chip | The corresponding filter is cleared via the notifier. The results API call automatically re-triggers (since it watches `diamondSearchProvider`). The list resets to page 1. The chip disappears with a fade animation. |
| Chip for `minPrice`/`maxPrice` | Reset both to defaults (0 and 1000000). |
| Chip for `minCarat`/`maxCarat` | Reset both to defaults (0.16 and 100.00) and clear `selectedCaratQuickRanges`. |
| Chip for `labNatural` | Reset to `LabNaturalType.natural`. |
| Chip for range-based fields | Reset the range to full default span. |
| Removing all chips | When last chip is removed, the row collapses (zero height) and the list re-fetches with unfiltered results. |

### 2.4 "Edit Filters" Navigation

| Action | Result |
|---|---|
| User taps "EDIT FILTERS" | **Navigates back** to `/diamonds` via `context.pop()`. Since `diamondSearchProvider` is a global provider, all filter state is preserved exactly as the user left it. The DiamondSearchScreen shows with all previous selections intact. |
| User presses hardware/software back button | Same behavior as above — pops to `/diamonds`, filter state preserved. |

### 2.5 Infinite Scroll Trigger

| Property | Value |
|---|---|
| Trigger point | When the user scrolls within **300px** of the bottom of the current content. |
| Implementation | Use `ScrollController` with a listener that checks `controller.position.pixels >= controller.position.maxScrollExtent - 300`. |
| Debounce | Do not fire another load if one is already in progress (`_isLoadingMore` flag). |
| Page size | 20 items per page (configurable constant). |
| End of list | When all items are loaded, show a small "End of results" label or simply stop showing the loading indicator. |
| Error during load more | Show a small inline retry banner at the bottom: `"Failed to load more. Tap to retry."` |

### 2.6 Tapping a Diamond Card

| Action | Result |
|---|---|
| User taps a card | Navigate to diamond detail screen. Route: `/diamonds/detail/:id` (to be designed in a separate spec — out of scope here). Pass the diamond ID. |
| Future consideration | Long-press could show a quick-preview tooltip or add to wishlist. |

### 2.7 Pull-to-Refresh

| Property | Value |
|---|---|
| Widget | Wrap the scrollable content in a `RefreshIndicator`. |
| Color | `AppColors.bronze` for the refresh indicator. |
| Trigger | User pulls down from the top of the list. |
| Result | Resets to page 1, refreshes all results. Shows shimmer skeleton during refresh? No — show the existing cards with a pull-to-refresh indicator overlay. |
| On refresh | Abort any in-flight pagination request. Reset page counter to 1. Re-fetch with current filters and sort. |

---

## 3. Information Architecture

### 3.1 Diamond Data Model (for card display)

The API response for a diamond listing item should contain at minimum:

| Field | Type | Example |
|---|---|---|
| `id` | String | `"dmd_12345"` |
| `imageUrl` | String? | `"https://..."` |
| `shape` | String | `"Round"` |
| `carat` | double | `1.05` |
| `price` | double | `8450.00` |
| `cut` | String | `"Excellent"` |
| `color` | String | `"D"` |
| `clarity` | String | `"VS1"` |
| `certificate` | {lab, number} | `{"lab": "GIA", "number": "1234567890"}` |
| `discountPercentage` | double? | `15.0` |
| `sellerName` | String? | `"Tiffany & Co."` |
| `isFavorite` | bool | `false` |

### 3.2 Grid Card Content Hierarchy

```
1. Image                   (visual anchor, 3:4 ratio)
2. Shape name              (secondary info, small text)
3. Carat weight            (key spec, medium emphasis)
4. Price                   (primary CTA emphasis, bronze, large)
5. Certificate lab         (trust signal, small text, star prefix)
```

### 3.3 List Card Content Hierarchy

```
Left column:
  1. Image                 (visual anchor, 80x100dp)

Right column, top row:
  2. Shape | Carat | Color | Clarity   (quick specs, row)

Right column, middle row:
  3. Cut: Excellent                    (detail spec)

Right column, bottom row:
  4. Certificate: GIA #1234567890      (trust signal)

Price (top-right, independent):
  5. $8,450                            (primary CTA emphasis, bronze)
```

### 3.4 Sort Options Reference

| Sort Key | API Parameter | Display Label |
|---|---|---|
| `price_asc` | `sort_by=price&order=asc` | "Price: Low-High" |
| `price_desc` | `sort_by=price&order=desc` | "Price: High-Low" |
| `carat_asc` | `sort_by=carat&order=asc` | "Carat: Low-High" |
| `carat_desc` | `sort_by=carat&order=desc` | "Carat: High-Low" |
| `popularity` | `sort_by=popularity` | "Popularity" |
| `discount_desc` | `sort_by=discount&order=desc` | "Discount %" |
| `newest` | `sort_by=created_at&order=desc` | "Newest First" |

---

## 4. Flow Integration

### 4.1 Screen-to-Screen Flow

```
[DiamondSearchScreen]                         [DiamondListingsScreen]
   ┌─────────────┐                              ┌─────────────┐
   │ User sets   │  tap "SHOW N DIAMONDS"       │ Results     │
   │ filters     │ ──────────────────────────►   │ displayed   │
   │             │                              │             │
   │             │  tap "EDIT FILTERS" or ←     │             │
   │             │ ◄──────────────────────────  │             │
   └─────────────┘                              └─────────────┘
                                                       │
                                          tap diamond card
                                                       │
                                                       ▼
                                              ┌─────────────────┐
                                              │ Diamond Detail  │
                                              │ Screen (future) │
                                              └─────────────────┘
```

### 4.2 Filter State Sharing

| Principle | Implementation |
|---|---|
| Single source of truth | `diamondSearchProvider` (`NotifierProvider<DiamondSearchNotifier, DiamondFilterState>`) is the sole owner of filter state. |
| DiamondSearchScreen writes | User sets filters → state updated via notifier methods (e.g., `toggleShape()`, `updatePriceRange()`). |
| DiamondListingsScreen reads | Watches `diamondSearchProvider` via `ref.watch(diamondSearchProvider)`. Convert filter state to API query parameters. |
| No duplication | The results screen never holds its own copy of filters. It always reads from the provider. |
| Chip dismissal writes | Results screen calls notifier methods (e.g., `notifier.clearCuts()`) when a chip is dismissed. The resulting state change triggers a new API call. |

### 4.3 Route Configuration

**Add to `AppRouteNames`:**
```dart
static const String diamondsResults = '/diamonds/results';
```

**Add to `diamondsRoutes` in `diamonds_routes.dart`:**
```dart
GoRoute(
  path: 'results',
  parentNavigatorKey: rootNavigatorKey,
  builder: (context, state) => const DiamondListingsScreen(),
),
```

**Modify `SearchBottomBar` to navigate:**
```dart
onPressed: () {
  context.push(AppRouteNames.diamondsResults);
},
```

**Update the diamonds route** to support nested routes (change `diamondsRoutes` to use a parent `GoRoute` with the search screen as `builder` and results as a sub-route):
```dart
final List<RouteBase> diamondsRoutes = [
  GoRoute(
    path: '/diamonds',
    builder: (context, state) => const DiamondSearchScreen(),
    routes: [
      GoRoute(
        path: 'results',
        builder: (context, state) => const DiamondListingsScreen(),
      ),
    ],
  ),
];
```

### 4.4 "Edit Filters" Navigation Behavior

```
User taps "EDIT FILTERS" or presses ←
  → context.pop()
  → DiamondSearchScreen is revealed beneath
  → diamondSearchProvider still holds ALL filter state as user left it
  → Filter categories show previous selections
  → matchingCountProvider recalculates automatically
```

**Key**: No state restoration logic needed. The provider lives above both screens in the widget tree. The search screen consumes the same provider and automatically shows the correct state.

### 4.5 Removing All Filters via Chips

```
User dismisses last remaining chip
  → Chips row collapses (zero height / gone)
  → API call re-triggers with default (unfiltered) parameters
  → Results update to show all diamonds in inventory
  → Results count header updates to total inventory count
  → If no diamonds exist at all (empty inventory), show empty state
```

---

## 5. Accessibility & Responsiveness

### 5.1 Touch Targets

| Element | Minimum Size | Notes |
|---|---|---|
| All tappable chips | **48x48dp** | The chip itself may be smaller, but the dismiss icon must have a 48dp hit area extension. |
| Sort bar | **48x48dp** | Full height of the bar row is at least 48dp. |
| Grid/List toggle icons | **48x48dp** | Each icon button is wrapped in a 48dp constrained box. |
| "Edit Filters" button | **48x48dp** height, width natural. |
| Diamond cards | Full width, ≥72dp height in list, natural height in grid. |

### 5.2 Semantic Labels

| Element | `Semantics` / `semanticLabel` |
|---|---|
| Grid toggle button | `"Switch to grid view"` |
| List toggle button | `"Switch to list view"` |
| Sort dropdown trigger | `"Sort by, currently {selected option}"` |
| Sort bottom sheet | `"Sort options"` |
| Filter chip dismiss | `"Remove filter: {chip label}"` |
| Diamond card (grid) | `"{shape}, {carat} carat, {price}"` |
| Diamond card (list) | `"{shape}, {carat} carat, color {color}, clarity {clarity}, cut {cut}, {price}"` |
| "Edit Filters" button | `"Edit filters"` |
| Results count | `"{count} diamonds"` |
| Pull-to-refresh | `"Refresh results"` |

### 5.3 Dark Mode Compatibility

All colors reference `AppColors.*` constants which handle both themes.
- Card surfaces: `AppColors.warmWhite` (light) / `AppColors.slateSurface` (dark).
- Borders: `AppColors.warmBorder` (light) / `AppColors.slateBorder` (dark).
- Text: `AppColors.textPrimaryLight`/`textPrimaryDark`, `AppColors.textSecondaryLight`/`textSecondaryDark`, etc.
- No hardcoded light colors — the `isDark` check from `Theme.of(context).brightness` determines which palette constant to use.

### 5.4 Text Overflow Handling

| Element | Overflow Strategy |
|---|---|
| Shape name (grid) | `maxLines: 1`, `TextOverflow.ellipsis` |
| Carat weight | Fixed format `X.XX ct`, no overflow risk. |
| Price | Fixed format, no overflow risk. |
| Certificate lab (grid) | `maxLines: 1`, `TextOverflow.ellipsis` |
| Shape \| Carat line (list) | `maxLines: 1`, `TextOverflow.ellipsis` for the entire row. |
| Certificate number (list) | `maxLines: 1`, `TextOverflow.ellipsis` |
| Sort bar label | `maxLines: 1`, `TextOverflow.ellipsis`, flex layout so it can shrink. |

### 5.5 Responsive Grid Breakpoints

| Screen Width | Grid Columns | Card Sizing | Skeleton Count |
|---|---|---|---|
| < 600px (phone portrait) | 2 | Flexible, ~50% width each | 6 (3 rows) |
| 600-840px (phone landscape / small tablet) | 3 | ~33% width each | 9 (3 rows) |
| 840-1100px (tablet portrait) | 3 | ~33% width each | 9 (3 rows) |
| ≥ 1100px (tablet landscape / desktop) | 4 | ~25% width each | 12 (3 rows) |

**Implementation**: Use `LayoutBuilder` or `MediaQuery` to determine column count based on available width.

```dart
int columnCount(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width >= 1100) return 4;
  if (width >= 840) return 3;
  if (width >= 600) return 3;
  return 2;
}
```

**List view** remains single column regardless of screen width. On tablets, the list card can be slightly wider with larger image (100x125dp) and slightly larger text.

---

## 6. States to Handle

### 6.1 State Machine

```
                  ┌──────────┐
                  │  Initial │  (no data, no error, no loading)
                  └────┬─────┘
                       │
                   fetchData()
                       │
                       ▼
                  ┌──────────┐
            ┌────►│ Loading  │ ◄──── pull-to-refresh
            │     └────┬─────┘
            │          │
            │     ┌────┴─────┐
            │     │          │
            │     ▼          ▼
            │ ┌───────┐ ┌────────┐
            │ │ Data  │ │ Error  │  ◄── retry
            │ └───┬───┘ └───┬────┘
            │     │         │
            │     │   retry │
            │     └─────────┘
            │
            └──── loadMore()
                 (from Data state)
                      │
                      ▼
                 ┌───────────┐
                 │LoadingMore│
                 └─────┬─────┘
                       │
                  ┌────┴─────┐
                  │          │
                  ▼          ▼
              ┌───────┐ ┌────────┐
              │ Data  │ │ Load   │
              │(+more)│ │ Error  │  ◄── retry load
              └───────┘ └────────┘
```

### 6.2 State Definitions

#### 6.2.1 Loading (Initial)

| Aspect | Behavior |
|---|---|
| Trigger | Screen first opens, or pull-to-refresh starts. |
| UI | Shimmer skeleton grid (6 items in 2-col, 9 in 3-col, 12 in 4-col). |
| Sort bar | Visible but non-interactive (disabled) during initial load? No — keep it interactive; user can change sort and loading state will update. |
| Chips | Visible and interactive. |

#### 6.2.2 Loading More (Infinite Scroll)

| Aspect | Behavior |
|---|---|
| Trigger | User scrolls within 300px of bottom while more pages exist. |
| UI | Current cards remain visible. A small `CircularProgressIndicator` appears at the bottom. |
| Input blocking | None — user can still scroll, tap chips, tap cards, toggle view. |
| Multiple triggers | Guard with `_isLoadingMore` flag. Ignore scroll events while fetching. |
| End of list | When `items.length >= totalCount`, show no more indicator. |

#### 6.2.3 Empty (No Results Match Filters)

| Aspect | Behavior |
|---|---|
| Trigger | API returns 0 results for current filters. |
| UI | Centered empty state layout (§1.5). |
| Chips | Still visible (so user can remove filters). |
| Sort bar | Still visible but disabled (no items to sort). Show "0 diamonds" count. |
| CTA | "CLEAR ALL FILTERS" button calls `notifier.reset()`. |

#### 6.2.4 Error (Network Failure + Retry)

| Aspect | Behavior |
|---|---|
| Trigger | API call fails (network error, timeout, server error). |
| UI | Centered error state layout (§1.8). |
| Chips | Still visible (user can remove filters to try different query). |
| Sort bar | Still visible but disabled. |
| CTA | "TRY AGAIN" button retries the API call. |
| Retry logic | Maximum 3 automatic retries with exponential backoff (1s, 2s, 4s) before showing error state to user. |
| Error during load-more | Show inline retry banner at bottom of list (not full-screen error). |

#### 6.2.5 Data (With Results)

| Aspect | Behavior |
|---|---|
| Trigger | API returns ≥1 diamond. |
| UI | Full results list (grid or list depending on toggle). |
| Count display | Shows `"{count} diamonds"` in sort bar. |
| Chips | Visible (if any filters active). |
| All interactions | Enabled. |

#### 6.2.6 All Filters Removed via Chips

| Aspect | Behavior |
|---|---|
| Trigger | User dismisses the last remaining filter chip. |
| UI | Chips row collapses (zero height). List shows all diamonds (unfiltered). |
| Count display | Shows total inventory count. |
| Behavior | Identical to "Data" state but with no chips visible. If total inventory is 0, transition to "Empty" state. |

---

## 7. Provider & Data Layer

### 7.1 New Providers Needed

```dart
// Manages pagination state and API calls for diamond listings
final diamondListingsProvider = AsyncNotifierProvider<DiamondListingsNotifier, DiamondListingsState>(
  DiamondListingsNotifier.new,
);
```

### 7.2 DiamondListingsState

```dart
@immutable
class DiamondListingsState {
  final List<DiamondListing> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int totalCount;
  final String? error;
  final ViewMode viewMode; // enum: grid, list
  final SortOption sortOption;

  // Factory for initial state
  const DiamondListingsState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.totalCount = 0,
    this.error,
    this.viewMode = ViewMode.grid,
    this.sortOption = SortOption.popularity,
  });
}

enum ViewMode { grid, list }

enum SortOption {
  priceAsc,
  priceDesc,
  caratAsc,
  caratDesc,
  popularity,
  discountDesc,
  newest,
}
```

### 7.3 DiamondListingsNotifier

```dart
class DiamondListingsNotifier extends AsyncNotifier<DiamondListingsState> {
  // Listens to diamondSearchProvider for filter changes
  // Re-fetches page 1 when filters change
  // Fetches next page on loadMore()
  // Supports retry, pull-to-refresh
}
```

### 7.4 API Contract

**Endpoint:** `GET /api/diamonds`

**Query parameters (derived from `DiamondFilterState`):**
```
?page=1
&per_page=20
&sort_by=price
&order=asc
&shapes=Round,Princess
&min_price=500
&max_price=5000
&min_carat=1.0
&max_carat=1.49
&min_color_index=0
&max_color_index=3
&min_clarity_index=0
&max_clarity_index=3
&cuts=Excellent
&labs=GIA,IGI
...etc (all filter fields mapped)
```

**Response:**
```json
{
  "data": [
    {
      "id": "dmd_12345",
      "image_url": "https://...",
      "shape": "Round",
      "carat": 1.05,
      "price": 8450.00,
      "cut": "Excellent",
      "color": "D",
      "clarity": "VS1",
      "certificate": {
        "lab": "GIA",
        "number": "1234567890"
      },
      "discount_percentage": null,
      "seller_name": "GemWorld Dealer",
      "is_favorite": false
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total": 12450,
    "last_page": 623
  }
}
```

---

## 8. Implementation Checklist

### Phase 1: Foundation
- [ ] Create `DiamondListing` domain model in `domain/models/diamond_listing.dart`
- [ ] Create `DiamondListingsState` with loading/more/error/data/view/sort fields
- [ ] Create `DiamondListingsNotifier` (AsyncNotifier) with `build()`, `loadMore()`, `refresh()`, `setSort()`, `retry()`
- [ ] Create `diamondListingsProvider` in `application/`
- [ ] Implement API service layer for `GET /api/diamonds` using Dio

### Phase 2: Screen Shell
- [ ] Create `DiamondListingsScreen` (ConsumerStatefulWidget)
- [ ] Implement AppBar with back, title, "Edit Filters" button
- [ ] Implement filter summary chips row
- [ ] Implement sort bar with results count, sort dropdown, grid/list toggle
- [ ] Register route `/diamonds/results` in `diamonds_routes.dart`
- [ ] Modify `SearchBottomBar` to navigate to results route

### Phase 3: Card Rendering
- [ ] Create `DiamondCardGrid` widget
- [ ] Create `DiamondCardList` widget
- [ ] Implement responsive column count (LayoutBuilder/MediaQuery)
- [ ] Implement grid/list toggle with crossfade animation
- [ ] Handle image loading with shimmer + error placeholder
- [ ] Handle text overflow for all fields

### Phase 4: Infinite Scroll
- [ ] Implement `ScrollController` with `_scrollListener`
- [ ] Implement load-more trigger at 300px threshold
- [ ] Show loading indicator at bottom during load-more
- [ ] Handle load-more errors with inline retry
- [ ] Ensure no duplicate requests with `_isLoadingMore` guard

### Phase 5: States
- [ ] Shimmer skeleton for initial loading (6/9/12 items)
- [ ] Empty state widget
- [ ] Error state widget with retry
- [ ] Pull-to-refresh with `RefreshIndicator`
- [ ] End-of-results indicator

### Phase 6: Integration
- [ ] Wire filter chip creation from `DiamondFilterState`
- [ ] Wire chip dismissal to notifier methods
- [ ] Wire "Edit Filters" to `context.pop()`
- [ ] Wire sort change to re-fetch with new sort
- [ ] Wire diamond card tap to detail navigation (route placeholder)
- [ ] Wire pull-to-refresh to `refresh()`
- [ ] Sync `matchingCountProvider` count into sort bar

### Phase 7: Accessibility
- [ ] Add `Semantics` labels to grid/list toggle, sort trigger, chips
- [ ] Verify 48dp minimum touch targets on all interactive elements
- [ ] Test with TalkBack / VoiceOver
- [ ] Ensure keyboard navigation works (Tab order)

### Phase 8: Performance
- [ ] Verify images are cached and lazy-loaded (cached_network_image)
- [ ] Verify list uses `ListView.builder` (not `ListView(children:)`)
- [ ] Verify shimmer only shows on initial load, not on subsequent loads
- [ ] Verify scroll performance (no unnecessary rebuilds)
- [ ] Profile with DevTools to ensure smooth 60fps scrolling

---

## 9. New Files to Create

```
lib/features/diamonds/
├── domain/
│   └── models/
│       ├── diamond_filter_state.dart     (exists)
│       └── diamond_listing.dart          ★ NEW
├── application/
│   ├── diamond_search_provider.dart      (exists)
│   └── diamond_listings_provider.dart    ★ NEW
├── presentation/
│   ├── screens/
│   │   ├── diamond_search_screen.dart    (exists)
│   │   └── diamond_listings_screen.dart  ★ NEW
│   └── widgets/
│       ├── (existing filter widgets...)
│       ├── diamond_card_grid.dart        ★ NEW
│       ├── diamond_card_list.dart        ★ NEW
│       ├── diamond_listings_sort_bar.dart ★ NEW
│       ├── diamond_listings_chips.dart   ★ NEW
│       ├── diamond_listings_empty.dart   ★ NEW
│       ├── diamond_listings_error.dart   ★ NEW
│       └── diamond_listings_shimmer.dart ★ NEW
├── diamonds_routes.dart                  (modify — add results sub-route)
└── UX_SPEC_DIAMOND_LISTINGS.md           ★ THIS DOCUMENT
```

---

## 10. Files to Modify

| File | Change |
|---|---|
| `lib/core/router/route_names.dart` | Add `static const String diamondsResults = '/diamonds/results';` |
| `lib/features/diamonds/diamonds_routes.dart` | Add results sub-route under `/diamonds` parent |
| `lib/features/diamonds/presentation/widgets/search_bottom_bar.dart` | Change `onPressed` to navigate to results screen instead of showing SnackBar |

---

**Spec Author:** ArchitectUX Agent  
**Status:** Final — Ready for Mobile App Builder, UI Designer, and Performance Benchmarker  
**Dependencies:** Existing `diamondSearchProvider`, `DiamondFilterState`, `DiamondSearchNotifier`, `matchingCountProvider`  
**Next Steps:** Begin Phase 1 implementation — create domain model and providers
