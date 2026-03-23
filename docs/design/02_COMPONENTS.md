# Components

> Complete specification for every UI component in the Tavli design system.
> All components use tokens from [Design System](01_DESIGN_SYSTEM.md).

## Related Documents

- [Design System](01_DESIGN_SYSTEM.md) — Color, typography, spacing, radius tokens
- [States](03_STATES.md) — Interaction states for each component
- [Accessibility](05_ACCESSIBILITY.md) — Per-component accessibility requirements
- [Material Design 3](07_MATERIAL_DESIGN.md) — M3 component mapping

---

## 1. Buttons

### 1.1 Filled Button (Primary)

The primary action button. Used for "Next", "Play", "Confirm", "Roll Dice".

| Property | Value | Token |
|----------|-------|-------|
| Background | `#6B4F3A` | `primary` |
| Text color | `#F3F0EB` | `light` |
| Text style | 16px, Medium (w500), capitalize | `labelLarge` variant |
| Border radius | 8px | `TavliRadius.sm` |
| Padding | 12px horizontal, 8px vertical | `sm` × `xs` |
| Min size | 48 × 40dp | Touch target compliant |
| Min touch target | 48 × 48dp | WCAG 2.5.8 |
| Elevation | `xsmall` (0 1px 2px 0.3α) | `TavliShadows.xsmall` |
| Font family | Poppins Medium | — |

**Contrast:** Light on Primary = 5.6:1 (AA pass).

**Accessibility:**
- Semantic label must describe the action, not "button"
- Minimum touch target 48dp in all directions
- Focus ring: 2px `primary`, 2px offset

**M3 alignment:** Maps to `FilledButton`. Custom colors via `filledButtonTheme`.

### 1.2 Outlined Button (Secondary)

Secondary actions. Used for "Next" (on Ready to Play screen), "Cancel", alternative CTAs.

| Property | Value | Token |
|----------|-------|-------|
| Background | `#D4C2A8` | `background` (elevated from page) |
| Text color | `#6B4F3A` | `primary` |
| Border | 1px solid `#6B4F3A` | `primary` |
| Text style | 16px, Medium (w500), capitalize | `labelLarge` variant |
| Border radius | 8px | `TavliRadius.sm` |
| Padding | 16px horizontal, 8px vertical | `md` × `xs` |
| Min size | 48 × 40dp | — |
| Elevation | `xsmall` | `TavliShadows.xsmall` |

**Contrast:** Primary on Background = 3.5:1 (large text / bold only). Text is 16px Medium (bold equivalent) so passes AA for large text.

> **Note:** The outlined button uses `background` (`#D4C2A8`) fill to create visual elevation from the `surface` (`#A67F5B`) page background.

**Accessibility:**
- Same touch target and focus ring as filled button
- Border provides 3:1 contrast against background (primary on background = 3.5:1)

**M3 alignment:** Maps to `OutlinedButton`.

### 1.3 Text Button (Tertiary)

Tertiary actions, inline links, "Skip", "Learn more".

| Property | Value | Token |
|----------|-------|-------|
| Background | Transparent | — |
| Text color | `#6B4F3A` | `primary` |
| Text style | 14px, Medium (w500) | `labelLarge` |
| Padding | 12px horizontal, 8px vertical | `sm` × `xs` |
| Min touch target | 48 × 48dp | Padded invisibly |

**Contrast:** Primary on Background = 3.5:1 (large text). Primary on Light = 5.6:1 (AA).

**M3 alignment:** Maps to `TextButton`.

### 1.4 Icon Button

Standalone icon actions: settings gear, close, back arrow, share.

| Property | Value | Token |
|----------|-------|-------|
| Icon size | 24dp | — |
| Touch target | 48 × 48dp | Padded to minimum |
| Icon color (on background) | `#6B4F3A` | `primary` |
| Icon color (on primary) | `#F3F0EB` | `light` |
| Icon color (disabled) | `#6B4F3A` at 38% | — |
| Tooltip | Required | Describes action |

**Accessibility:**
- Must have a `Tooltip` with action description
- Semantic label must describe the action
- 48dp touch target regardless of icon size

**M3 alignment:** Maps to `IconButton`.

### 1.5 Button Sizes

| Variant | Height | Horizontal Padding | Text Size | Usage |
|---------|--------|-------------------|-----------|-------|
| Small | 36dp | 12px | 12px (labelMedium) | Inline actions, compact spaces |
| Medium (default) | 40dp | 16px | 14px (labelLarge) | Standard actions |
| Large | 48dp | 24px | 16px (titleMedium) | Primary CTAs, hero buttons |

All variants maintain 48dp minimum touch target (small uses invisible padding).

### 1.6 Button Group Rules

- Horizontal spacing between buttons: 12px (`sm`)
- Primary action on the right (or bottom in vertical layout)
- Maximum 3 buttons in a group
- Destructive actions always require confirmation dialog

---

## 2. Cards

### 2.1 Standard Card (List Item)

Used for menu items, settings rows, profile options. The primary card pattern in the app.

| Property | Value | Token |
|----------|-------|-------|
| Background | `#6B4F3A` | `primary` |
| Border | 1px solid `#D4C2A8` | `background` |
| Border radius | 16px | `TavliRadius.lg` |
| Elevation | `xsmall` (0 1px 2px 0.3α) | `TavliShadows.xsmall` |
| Internal padding | 16px all sides | `TavliSpacing.md` |
| Gap between cards | 10px | Custom (between `xs` and `sm`) |

**Internal Layout:**

```
┌──────────────────────────────────────────┐
│  [Icon 32-40dp]  Title (L3 18px Medium)  │  ← 12px gap
│                  Subtitle (L5 14px)    > │  ← chevron optional
└──────────────────────────────────────────┘
```

- Icon: 32dp or 40dp, left-aligned, vertically centered
- Title: `labelLarge` equivalent, 18px Poppins Medium, `light` color
- Subtitle: 14px Regular, `light` color
- Chevron (if navigable): 16-24dp, `light` color, right-aligned

> **Note:** Cards use `primary` (`#6B4F3A`) background with `light` (`#F3F0EB`) text, providing 5.6:1 contrast (AA pass). Cards elevated with `background` fill use `primary` text for higher contrast.

**M3 alignment:** Maps to `Card` with custom theme. See [M3 > Component Mapping](07_MATERIAL_DESIGN.md#component-mapping).

### 2.2 User Profile Card

Special card variant on the Home screen showing the user's avatar and info.

| Property | Value | Token |
|----------|-------|-------|
| Background | `#D4C2A8` | `background` (different from standard cards) |
| Border | 1px solid `#6B4F3A` | `primary` |
| Border radius | 16px | `TavliRadius.lg` |
| Elevation | `xsmall` | `TavliShadows.xsmall` |
| Internal padding | 16px | `TavliSpacing.md` |
| Text color | `#6B4F3A` | `primary` (dark on light bg) |

**Internal Layout:**

```
┌──────────────────────────────────────────┐
│  [Avatar 42dp]  Name (L3 18px Medium)    │
│                 Status (L5 14px)         │
└──────────────────────────────────────────┘
```

### 2.3 Board Selection Card (Carousel)

Used in the "Choose Your Boards" onboarding screen.

| Property | Value | Token |
|----------|-------|-------|
| Background | `#A67F5B` | `surface` |
| Border | ~1px solid `#6B4F3A` | `primary` |
| Border radius | 14.4px | Custom (close to `TavliRadius.lg`) |
| Elevation | `large` (0 0 48px 0.2α) | `TavliShadows.large` |
| Width | 296.7px | Fixed |
| Image area height | ~417px | Board photograph |
| Info footer padding | 14.4px | ~`sm` |

**Carousel behavior:**
- Front card: upright, full opacity, z-index highest
- Behind cards: rotated ~9°, stacked with overlap
- Swipe gesture to cycle
- Drop shadow creates depth illusion

**Info Footer:**
- Board name: 18px Medium, `primary` color on `background` fill
- Board description: 14px Regular

### 2.4 Tab/Segment Card

Used on Home screen for game type selection (Portes, Plakoto, Fevga).

| Property | Value | Token |
|----------|-------|-------|
| Background | `#6B4F3A` | `primary` |
| Border | 1px solid `#D4C2A8` | `background` |
| Border radius | 16px | `TavliRadius.lg` |
| Elevation | `xsmall` | `TavliShadows.xsmall` |
| Padding | 16px | `TavliSpacing.md` |
| Width | Equal flex (1/3 of container) | `Expanded` |
| Gap between tabs | 12px | `TavliSpacing.sm` |

**Text:**
- Label: 18px Medium, `light`
- Centered horizontally

**Selected state:** See [States > Tab/Segment States](03_STATES.md#tab-segment-states).

---

## 3. Input Fields

### 3.1 Text Input

Used for profile name, search, custom game settings.

| Property | Value | Token |
|----------|-------|-------|
| Fill color | `#A67F5B` | `surface` |
| Border (rest) | 1px solid `#6B4F3A` | `primary` |
| Border (focused) | 2px solid `#6B4F3A` | `primary`, doubled width |
| Border (error) | 2px solid `#A0442C` | `error` |
| Border radius | 8px | `TavliRadius.sm` |
| Text color | `#1A1A1A` | `text` |
| Placeholder color | `#1A1A1A` at 60% opacity | `text` with alpha |
| Label color | `#1A1A1A` | `text` |
| Height | 48dp minimum | Touch target |
| Padding | 16px horizontal, 12px vertical | `md` × `sm` |
| Text style | 16px Regular | `bodyLarge` |

**Accessibility:**
- Label always visible (not placeholder-only)
- Error state: border changes + error text below + error icon
- Placeholder contrast: `text` at 60% on `surface` ≈ 3.0:1 (borderline, acceptable for placeholder per WCAG)

### 3.2 Search Input

Same as text input with:
- Leading search icon (24dp, `primary`)
- Trailing clear button (when populated)
- No label (search icon serves as label)
- Semantic label: "Search"

---

## 4. Sliders

### 4.1 Greek Level Slider

Custom discrete slider for adjusting Greek language level.

| Property | Value | Token |
|----------|-------|-------|
| Track color | `#A67F5B` | `surface` |
| Track height | 12px | Custom |
| Track radius | Fully rounded | `TavliRadius.full` |
| Stop dots | 12 × 12px, `#6B4F3A` | `primary` |
| Number of stops | 5 | Discrete |
| Thumb size (visual) | 28 × 28px | Custom |
| Thumb touch target | 48 × 48dp | Padded |
| Thumb fill | `#A67F5B` | `surface` |
| Thumb border | 1px solid `#6B4F3A` | `primary` |
| Thumb inner dot | 12 × 12px, `#6B4F3A` | `primary` |
| Thumb shadow | `small` (0 0 8px 0.1α) | `TavliShadows.small` |

**Labels:**
- Left: "English Only" / "Can't read and write" — `primary` color, 14px Medium / 12px Regular
- Right: "Fluent" / "Can read and write" — same styling, right-aligned

**Example Box:**

| Property | Value | Token |
|----------|-------|-------|
| Background | `#A67F5B` | `surface` |
| Border | 1px solid `#6B4F3A` | `primary` |
| Border radius | 12px | `TavliRadius.md` |
| Elevation | `xsmall` | `TavliShadows.xsmall` |
| Padding | 12px | `sm` |
| "Example" label | 12px Regular, `#D4C2A8` | `background` color text |
| Sample text | 16px / 14px, `#1A1A1A` | `text` (WCAG compliant) |

**Accessibility:**
- Semantic label: "Greek language level, currently {value}"
- Step announcements via `SemanticsService.announce`
- 48dp thumb touch target

---

## 5. Navigation

### 5.1 App Bar

Minimal, transparent app bar for screen titles.

| Property | Value | Token |
|----------|-------|-------|
| Background | Transparent | — |
| Elevation | 0 | — |
| Title style | 24px SemiBold (w600) | `headlineLarge` |
| Title color | `#1A1A1A` | `text` |
| Title alignment | Center | — |
| Icon color | `#6B4F3A` | `primary` |
| Icon size | 24dp | — |
| Height | 56dp (M3 standard) | — |

### 5.2 Bottom Navigation Bar

Custom fully-rounded navigation bar on the Home screen.

| Property | Value | Token |
|----------|-------|-------|
| Background | `#D4C2A8` | `background` |
| Border | 1px solid `#D4C2A8` | `background` |
| Border radius | Fully rounded (100px) | `TavliRadius.full` |
| Padding | 10px internal | — |
| Height | 68dp | — |
| Horizontal margin | 16px (page padding) | `TavliSpacing.md` |
| Bottom margin | 26px | Safe area + padding |
| Shadow | `xsmall` | `TavliShadows.xsmall` |
| Items | 4 | — |
| Gradient fade | Behind nav bar, transparent to `surface` (`#A67F5B`) | Fades page content into nav |

**Nav Item:**

| Property | Active | Inactive |
|----------|--------|----------|
| Container | 48 × 48dp circle | 48 × 48dp circle |
| Container fill | `#6B4F3A` (`primary`) | `#D4C2A8` (`background`) |
| Icon size | 28dp | 28dp |
| Icon color | `#F3F0EB` (`light`) | `#6B4F3A` (`primary`) |
| Padding | 6px | 6px |

**Accessibility:**
- Each item has semantic label (e.g., "Home", "Profile", "Customize", "Settings")
- Selected state announced by screen reader
- 48dp touch targets with 8dp+ spacing

**M3 deviation:** Standard M3 `NavigationBar` is rectangular with indicator. Tavli uses a custom pill-shaped bar. Implemented via custom widget wrapping standard M3 navigation logic.

### 5.3 Onboarding Pagination

Bottom bar used across onboarding screens (screens 1-5).

| Property | Value | Token |
|----------|-------|-------|
| Layout | Left: pagination dots, Right: "Next" button | Space-between |
| Padding | 16px horizontal, 32px vertical | `md` × `xl` |

**Pagination Indicator:**
- Active: pill shape, 52 × 14px, `#F3F0EB` (`light`), rounded 100px
- Inactive: circle, 14 × 14dp, `#6B4F3A` (`primary`), filled
- Gap between dots: 6px

---

## 6. Avatars

### 6.1 Sizes

| Variant | Size | Border | Context |
|---------|------|--------|---------|
| Large | 90 × 90dp | 1px `primary` | Onboarding hero |
| Medium | 48 × 48dp | 1px `primary` | List items, nav |
| Small | 42 × 42dp | 0.5px `primary` | Home profile card |

### 6.2 Specification

| Property | Value | Token |
|----------|-------|-------|
| Shape | Circle | `TavliRadius.full` |
| Fill | `#A67F5B` | `surface` |
| Border | 1px solid `#6B4F3A` | `primary` |
| Initial letter color | `#6B4F3A` | `primary` |
| Initial letter size | Proportional to container (~49% of diameter) | — |
| Font weight | Regular (w400) | — |

**Accessibility:**
- Semantic label: "Avatar for {username}"
- Decorative in lists (merged with parent semantics)

---

## 7. Dialogs

### 7.1 Alert Dialog

Used for confirmations, errors, destructive action warnings.

| Property | Value | Token |
|----------|-------|-------|
| Background | `#D4C2A8` | `background` |
| Border radius | 16px | `TavliRadius.lg` |
| Elevation | `medium` (0 4px 16px 0.15α) | `TavliShadows.medium` |
| Padding | 24px | `TavliSpacing.lg` |
| Scrim | Black at 32% opacity | — |
| Max width | 400dp | — |
| Min width | 280dp | M3 standard |

**Content Layout:**

```
┌────────────────────────────┐
│  Title (headlineMedium)    │  ← 21px SemiBold
│                            │
│  Body text (bodyLarge)     │  ← 16px Regular
│                            │  ← 24px gap
│          [Cancel] [Confirm]│  ← Button row, right-aligned
└────────────────────────────┘
```

- Title color: `text` (`#1A1A1A`)
- Body color: `text` (`#1A1A1A`)
- Cancel: Text button
- Confirm: Filled button (destructive: use `error` color)

### 7.2 Bottom Sheet

Used for game options, sharing, additional actions.

| Property | Value | Token |
|----------|-------|-------|
| Background | `#D4C2A8` | `background` |
| Top radius | 16px | `TavliRadius.lg` |
| Handle | 32 × 4dp, `surface`, centered, 8px from top | — |
| Scrim | Black at 32% opacity | — |
| Max height | 80% of screen | — |
| Padding | 16px horizontal | `TavliSpacing.md` |

---

## 8. Lists

### 8.1 Card-Wrapped List Item

The standard list pattern in Tavli wraps each item in a card (see [Cards > Standard Card](#21-standard-card-list-item)).

Layout: Icon + Text column + optional trailing element (chevron, switch, value).

### 8.2 Section Header

| Property | Value | Token |
|----------|-------|-------|
| Text style | 14px Medium (w500) | `titleSmall` |
| Text color | `#6B4F3A` | `primary` |
| Padding | 16px horizontal, 8px bottom | `md` × `xs` |
| Uppercase | No | Sentence case |

---

## 9. Loading States

### 9.1 Shimmer Placeholder

Used while content is loading.

| Property | Value | Token |
|----------|-------|-------|
| Base color | `#C4B298` | `backgroundHover` |
| Highlight color | `#F3F0EB` | `light` |
| Animation | Gradient sweep, 1500ms, ease-in-out | — |
| Border radius | Matches target element | — |
| Reduced motion | Static `backgroundHover` fill | — |

### 9.2 Spinner

| Property | Value | Token |
|----------|-------|-------|
| Color | `#6B4F3A` | `primary` |
| Size | 24dp (inline), 48dp (full page) | — |
| Track color | `#A67F5B` at 30% | `surface` with alpha |

---

## 10. Error States

### 10.1 Inline Error

Below input fields when validation fails.

| Property | Value | Token |
|----------|-------|-------|
| Icon | Error triangle, 16dp | `error` color |
| Text | 12px Regular | `bodySmall` |
| Text color | `#A0442C` | `error` |
| Gap | 4px between icon and text | `xxs` |
| Margin top | 4px below input | `xxs` |

### 10.2 Full-Page Error

When a screen fails to load.

| Property | Value |
|----------|-------|
| Icon | 64dp error illustration |
| Title | `headlineMedium` (21px) |
| Body | `bodyLarge` (16px) |
| Action | Filled button "Try Again" |
| Centered vertically | Yes |

---

## 11. Empty States

When a list or screen has no content.

| Property | Value |
|----------|-------|
| Illustration | 120dp themed illustration |
| Title | `headlineSmall` (18px SemiBold) |
| Body | `bodyMedium` (14px), max 2 lines |
| Action (optional) | Outlined button |
| Centered vertically | Yes, offset slightly above center |

---

## 12. Game-Specific Components

These components exist within the Flame game canvas. Specifications are references — full implementation details live in game engine documentation.

### 12.1 Dice Display

| Property | Value |
|----------|-------|
| Size | 64 × 64dp (scalable) |
| Touch target | 64 × 64dp minimum |
| Visual | 3D rendered with lighting |
| Semantic label | "Die showing {value}" |

### 12.2 Checker Display

| Property | Value |
|----------|-------|
| Size | Proportional to board point width |
| Touch target | 48dp minimum |
| Selected state | Elevated shadow + scale 1.1× + glow |
| Semantic label | "{player}'s checker on point {number}" |

### 12.3 Board Point Highlights

| Indicator | Visual |
|-----------|--------|
| Valid move target | Pulsing green dot + outline |
| Blocked | Static red X |
| Selected source | Raised + shadow + scale |
| Bear-off zone | Outlined rectangle + pulse |

---

## 13. Accessibility Summary

Every component must:

1. **Meet touch target minimums** — 48dp in all directions for interactive elements
2. **Have semantic labels** — describing purpose, not appearance
3. **Support focus navigation** — visible focus ring, logical tab order
4. **Maintain contrast** — text color meets WCAG AA on its background
5. **Provide state feedback** — screen reader announces state changes
6. **Scale with text** — layouts don't break at 200% text scale

See [Accessibility](05_ACCESSIBILITY.md) for the complete specification.

---

## 14. Uniform Design Rules

1. **Same component = same appearance** — a card looks identical everywhere it appears
2. **Consistent internal padding** — always 16px (`md`) for cards, 12px (`sm`) for compact elements
3. **Consistent gap between cards** — 10px for stacked list cards, 12px for side-by-side cards
4. **Consistent border treatment** — 1px `background` border on standard cards, 1px `primary` border on inputs
5. **No one-off components** — if it doesn't fit an existing pattern, create a new documented variant

See [Uniform Design](06_UNIFORM_DESIGN.md) for the complete consistency specification.

---

## 15. Material Design 3 Alignment

All components map to M3 widgets:

| Component | M3 Widget | Custom Theme Key |
|-----------|-----------|-----------------|
| Filled Button | `FilledButton` | `filledButtonTheme` |
| Outlined Button | `OutlinedButton` | `outlinedButtonTheme` |
| Text Button | `TextButton` | `textButtonTheme` |
| Icon Button | `IconButton` | `iconButtonTheme` |
| Card | `Card` | `cardTheme` |
| Text Input | `TextField` | `inputDecorationTheme` |
| Slider | `Slider` | `sliderTheme` |
| Switch | `Switch` | `switchTheme` |
| Dialog | `AlertDialog` | `dialogTheme` |
| Bottom Sheet | `BottomSheet` | `bottomSheetTheme` |
| Navigation Bar | Custom widget | `navigationBarTheme` (partial) |
| List Tile | `ListTile` in `Card` | `listTileTheme` + `cardTheme` |

See [Material Design 3](07_MATERIAL_DESIGN.md) for the complete M3 integration specification.
