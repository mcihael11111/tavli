# Components

> **Self-contained component specifications.** Each component section includes appearance, states, accessibility, and M3 mapping — everything you need in ONE place.
> All values reference tokens from [00_TOKENS.md](00_TOKENS.md) **by name only**. Never hardcode hex or px values.

---

## 1. Buttons

### 1.1 Filled Button (Primary)

The primary action button. Used for "Next", "Play", "Confirm", "Roll Dice".

| Property | Token |
|----------|-------|
| Background | `primary` |
| Text color | `light` |
| Text style | `labelLarge` variant, 16px Medium (w500), capitalize |
| Border radius | `TavliRadius.sm` |
| Padding | `sm` horizontal × `xs` vertical |
| Min size | 48 × 40dp |
| Min touch target | 48 × 48dp |
| Elevation | `TavliShadows.xsmall` |
| Contrast | `light` on `primary` = 5.6:1 (AA pass) |

**States:**

| State | Background | Text | Elevation | Scale |
|-------|-----------|------|-----------|-------|
| Default | `primary` | `light` | `xsmall` | 1.0 |
| Hover | `primaryHover` | `light` | `xsmall` | 1.0 |
| Pressed | `primaryActive` | `light` | none | 0.98 |
| Focused | `primary` + 2px focus ring | `light` | `xsmall` | 1.0 |
| Disabled | `primary` at 38% | `light` at 38% | none | 1.0 |
| Loading | `primary` | hidden (spinner) | `xsmall` | 1.0 |

**Accessibility:**
- Semantic label describes action, not "button"
- 48dp touch target in all directions
- Focus ring: 2px `primary`, 2px offset
- Hover contrast: `light` on `primaryHover` ≈ 4.8:1 (AA)
- Pressed is transient (<200ms), borderline acceptable

**M3:** Maps to `FilledButton` via `filledButtonTheme`.

### 1.2 Outlined Button (Secondary)

Secondary actions: "Cancel", alternative CTAs.

| Property | Token |
|----------|-------|
| Background | `background` (elevated from page) |
| Text color | `primary` |
| Border | 1px solid `primary` |
| Text style | `labelLarge` variant, 16px Medium (w500), capitalize |
| Border radius | `TavliRadius.sm` |
| Padding | `md` horizontal × `xs` vertical |
| Min size | 48 × 40dp |
| Elevation | `TavliShadows.xsmall` |
| Contrast | `primary` on `background` = 3.5:1 (large text / 16px Medium = bold equivalent, passes AA) |

**States:**

| State | Background | Text | Border | Scale |
|-------|-----------|------|--------|-------|
| Default | `background` | `primary` | 1px `primary` | 1.0 |
| Hover | `backgroundHover` | `primary` | 1px `primary` | 1.0 |
| Pressed | `backgroundActive` | `primary` | 1px `primary` | 0.98 |
| Focused | `background` + 2px ring | `primary` | 2px `primary` ring | 1.0 |
| Disabled | `background` at 38% | `primary` at 38% | 1px `primary` at 38% | 1.0 |

**Accessibility:** Same as filled button (touch target, focus ring, semantic label).

**M3:** Maps to `OutlinedButton`.

### 1.3 Text Button (Tertiary)

Tertiary actions, inline links, "Skip", "Learn more".

| Property | Token |
|----------|-------|
| Background | Transparent |
| Text color | `primary` |
| Text style | `labelLarge`, 14px Medium (w500) |
| Padding | `sm` horizontal × `xs` vertical |
| Min touch target | 48 × 48dp (padded invisibly) |

**States:**

| State | Text | Background |
|-------|------|-----------|
| Default | `primary` | Transparent |
| Hover | `primary` | `backgroundHover` at 50% |
| Pressed | `primaryActive` | `backgroundActive` at 50% |
| Focused | `primary` | Transparent + 2px ring |
| Disabled | `primary` at 38% | Transparent |

**M3:** Maps to `TextButton`.

### 1.4 Icon Button

Standalone icon actions: settings, close, back, share.

| Property | Token |
|----------|-------|
| Icon size | 24dp |
| Touch target | 48 × 48dp |
| Icon color (on background) | `primary` |
| Icon color (on primary) | `light` |
| Icon color (disabled) | `primary` at 38% |

**States:**

| State | Icon Color | Background |
|-------|-----------|-----------|
| Default | `primary` | Transparent |
| Hover | `primary` | `backgroundHover` at 30% (circular) |
| Pressed | `primaryActive` | `backgroundActive` at 30%, scale 0.95 |
| Focused | `primary` | Transparent + 2px circle ring |
| Disabled | `primary` at 38% | Transparent |

**Accessibility:**
- `Tooltip` required (describes action)
- Semantic label describes action
- 48dp touch target regardless of icon size

**M3:** Maps to `IconButton`.

### 1.5 Button Sizes

| Variant | Height | Horizontal Padding | Text Size | Usage |
|---------|--------|-------------------|-----------|-------|
| Small | 36dp | `sm` (12px) | `labelMedium` (12px) | Inline, compact |
| Medium (default) | 40dp | `md` (16px) | `labelLarge` (14px) | Standard |
| Large | 48dp | `lg` (24px) | `titleMedium` (16px) | Primary CTAs, hero |

All maintain 48dp touch target (small uses invisible padding).

### 1.6 Button Group Rules

- Spacing between buttons: `sm` (12px)
- Primary action on the right
- Maximum 3 buttons in a group
- Destructive actions require confirmation dialog

---

## 2. Cards

### 2.1 Standard Card (List Item)

Menu items, settings rows, profile options. The primary card pattern.

| Property | Token |
|----------|-------|
| Background | `primary` |
| Border | 1px solid `background` |
| Border radius | `TavliRadius.lg` |
| Elevation | `TavliShadows.xsmall` |
| Internal padding | `TavliSpacing.md` (16px all sides) |
| Gap between cards | 10px (custom, list items only) |
| Text color | `light` |
| Contrast | `light` on `primary` = 5.6:1 (AA pass) |

**Internal Layout:**
```
┌──────────────────────────────────────────┐
│  [Icon 32-40dp]  Title (titleLarge)      │  ← sm gap
│                  Subtitle (bodyMedium) > │  ← chevron optional
└──────────────────────────────────────────┘
```
- Title: `titleLarge` (18px Medium), `light`
- Subtitle: `bodyMedium` (14px Regular), `light`
- Chevron (if navigable): 16-24dp, `light`

**States (tappable):**

| State | Background | Border | Elevation | Scale |
|-------|-----------|--------|-----------|-------|
| Default | `surface` | 1px `primary` | `xsmall` | 1.0 |
| Hover | `surfaceHover` | 1px `primary` | `small` | 1.0 |
| Pressed | `surfaceActive` | 1px `primary` | none | 0.98 |
| Focused | `surface` + 2px ring | 2px `primary` ring | `xsmall` | 1.0 |
| Disabled | `surface` at 38% | 1px `primary` at 38% | none | 1.0 |

**Non-tappable cards:** Default state only, cursor: default.

**Accessibility:**
- Semantic label describes destination/action
- 48dp minimum height
- Focus ring matches card shape (rounded rect)

**M3:** Maps to `Card` via `cardTheme`.

### 2.2 User Profile Card

Home screen user avatar and info. Uses `background` fill (elevated variant).

| Property | Token |
|----------|-------|
| Background | `background` |
| Border | 1px solid `primary` |
| Border radius | `TavliRadius.lg` |
| Elevation | `TavliShadows.xsmall` |
| Internal padding | `TavliSpacing.md` |
| Text color | `primary` |

**States:**

| State | Background | Scale |
|-------|-----------|-------|
| Default | `background` | 1.0 |
| Hover | `backgroundHover` | 1.0 |
| Pressed | `backgroundActive` | 0.98 |

**Layout:**
```
┌──────────────────────────────────────────┐
│  [Avatar 42dp]  Name (titleLarge)        │
│                 Status (bodyMedium)      │
└──────────────────────────────────────────┘
```

### 2.3 Board Selection Card (Carousel)

"Choose Your Boards" onboarding screen.

| Property | Token |
|----------|-------|
| Background | `surface` |
| Border | ~1px solid `primary` |
| Border radius | 14.4px (custom, ~`TavliRadius.lg`) |
| Elevation | `TavliShadows.large` |
| Width | 296.7px (fixed) |
| Image area height | ~417px |
| Info footer padding | ~`sm` |

**Carousel behavior:**
- Front card: upright, full opacity, z-index top
- Behind cards: rotated ~9°, stacked with overlap
- Swipe gesture to cycle
- No hover/focus states (interaction via swipe only)

**Info Footer:** Board name `titleLarge` in `primary`, description in `bodyMedium`.

### 2.4 Tab/Segment Card

Game type selection (Portes, Plakoto, Fevga) on Home screen.

| Property | Token |
|----------|-------|
| Background | `primary` |
| Border | 1px solid `background` |
| Border radius | `TavliRadius.lg` |
| Elevation | `TavliShadows.xsmall` |
| Padding | `TavliSpacing.md` |
| Width | Equal flex (1/3 of container) |
| Gap between tabs | `TavliSpacing.sm` |
| Label | `titleLarge` (18px Medium), `light`, centered |

**States:**

| State | Background | Text/Icon | Border | Shadow |
|-------|-----------|-----------|--------|--------|
| Unselected | `surface` | `light` at 70% | 1px `primary` | none |
| Selected | `primary` | `light` at 100% | **2px `background`** | `xsmall` |
| Hover (unsel.) | `surfaceHover` | `light` at 70% | 1px `primary` | none |
| Pressed (any) | active shade | current text | current border | none, scale 0.98 |
| Focused | current bg + 2px ring | current text | 2px `primary` ring | current |
| Disabled | current bg at 38% | current text at 38% | 1px at 38% | none |

The **2px `background` border** on selected creates a visible beige frame that immediately distinguishes the active card from siblings. This treatment applies universally to all selectable card groups (variant tabs, tradition cards, option cards, shop tabs).

**Accessibility:**
- Role: `tab` / `tablist`
- Selected state announced
- Arrow keys navigate between tabs
- Contrast: `light` on `primary` = 5.6:1 (AA); `light` at 70% on `surface` ≈ 4.0:1 (AA large text pass)

---

## 2b. Content Module (Translucent Card)

The signature depth card pattern. Semi-transparent cards that float on gradient scaffold backgrounds, creating the 3-layer depth aesthetic.

**Dart widget:** `ContentModule` in `lib/shared/widgets/content_module.dart`

| Property | Token |
|----------|-------|
| Background | `module-fill` (`background` at 12% alpha) |
| Border | 1px `module-border` (`primary` at 40% alpha) |
| Border radius | `lg` (16px) |
| Padding | `md` (16px) all sides |
| Shadow | None — depth comes from transparency on gradient |
| Title font | Serif (Playfair), 18px, w500, `light` |
| Body font | Sans (Poppins), 15px, 1.55 line height, `light` |
| Icon | 22px default, `light` color |
| Contrast | `light` on module = 5.6:1+ (AA pass) |

**Variants:**
- **Content**: icon + title + body text (informational)
- **Group**: icon + title + arbitrary child content (wraps sections)
- **Action**: icon + title + body + trailing + onTap (navigational)

**States (when tappable):**

| State | Fill Alpha | Scale | Duration |
|-------|-----------|-------|----------|
| Default | 12% | 1.0 | — |
| Hover | 18% | 1.0 | 100ms easeIn |
| Pressed | 22% | 0.98 | 100ms easeIn |

**When to use Content Module vs Standard Card:**
- **Content Module**: Informational display, section grouping, editorial content
- **Standard Card**: Interactive selection, shop items with complex states

**Accessibility:**
- When `onTap` is provided, wrapped in Semantics with `button: true`
- All text uses `light` on translucent fill — verified contrast on gradient backgrounds

---

## 3. Input Fields

### 3.1 Text Input

Profile name, search, custom game settings.

| Property | Token |
|----------|-------|
| Fill | `surface` |
| Border (rest) | 1px solid `primary` |
| Border (focused) | 2px solid `primary` |
| Border (error) | 2px solid `error` |
| Border radius | `TavliRadius.sm` |
| Text color | `text` |
| Placeholder | `text` at 60% opacity |
| Label color | `text` |
| Height | 48dp minimum |
| Padding | `md` horizontal × `sm` vertical |
| Text style | `bodyLarge` (16px Regular) |

**States:**

| State | Fill | Border | Label |
|-------|------|--------|-------|
| Empty | `surface` | 1px `primary` | `text`, above field |
| Filled | `surface` | 1px `primary` | `text`, above field |
| Focused | `surface` | 2px `primary` | `primary`, scaled |
| Error | `surface` | 2px `error` | `error` |
| Disabled | `surface` at 38% | 1px `primary` at 38% | at 38% |
| Read-only | `background` | 1px `primary` at 50% | `text` |

**Error details:** Border → 2px `error`. Error icon (16dp) + error text (`bodySmall`) below field in `error` color. Field does NOT turn red — only border.

**Accessibility:**
- Label always visible (not placeholder-only)
- Placeholder contrast: `text` at 60% on `surface` ≈ 3.0:1 (acceptable for placeholder per WCAG)
- Error announced by screen reader

**M3:** Maps to `TextField` via `inputDecorationTheme`.

### 3.2 Search Input

Same as text input plus:
- Leading search icon (24dp, `primary`)
- Trailing clear button (when populated)
- No label (search icon serves as label)
- Semantic label: "Search"

---

## 4. Sliders

### 4.1 Greek Level Slider

Custom discrete slider for Greek language level.

| Property | Token |
|----------|-------|
| Track | `surface`, 12px height, `TavliRadius.full` |
| Stop dots | 12×12px, `primary` |
| Stops | 5 (discrete) |
| Thumb (visual) | 28×28px, `surface` fill, 1px `primary` border, 12×12px `primary` inner dot |
| Thumb touch target | 48×48dp |
| Thumb shadow | `TavliShadows.small` |

**States:**

| State | Thumb | Track |
|-------|-------|-------|
| Default | `surface` + `primary` dot + `primary` border | `surface` |
| Dragging | `surfaceHover` + `primary` dot, scale 1.1× | `surface` |
| Hover | `surfaceHover` + shadow increase, cursor: grab | `surface` |
| Focused | `surface` + 2px `primary` ring | `surface` |
| Disabled | `surface` at 38% | `surface` at 38% |

**Labels:** Left: "English Only" / "Can't read and write" — `primary`, `labelLarge`/`bodySmall`. Right: "Fluent" / "Can read and write".

**Example Box:** `surface` fill, 1px `primary` border, `TavliRadius.md`, `TavliShadows.xsmall`, `sm` padding. "Example" label in `background` color `bodySmall`. Sample text in `text` color `bodyLarge`/`bodyMedium`.

**Accessibility:**
- Semantic label: "Greek language level, currently {value}"
- Step changes announced via `SemanticsService.announce`
- Role: `slider`, min/max announced on focus

**M3:** Maps to `Slider` via `sliderTheme`.

---

## 5. Navigation

### 5.1 App Bar

Minimal, transparent.

| Property | Token |
|----------|-------|
| Background | Transparent |
| Elevation | 0 |
| Title style | `headlineLarge` (24px w600) |
| Title color | `text` |
| Title alignment | Center |
| Icon color | `primary`, 24dp |
| Height | 56dp (M3 standard) |

No interactive states (icons use icon button states).

**M3:** Maps to `AppBar` via `appBarTheme`.

### 5.2 Bottom Navigation Bar

Custom fully-rounded pill bar on Home screen.

| Property | Token |
|----------|-------|
| Background | `background` |
| Border radius | `TavliRadius.full` |
| Padding | 10px internal |
| Height | 68dp |
| Horizontal margin | `TavliSpacing.md` |
| Bottom margin | 26px (safe area + padding) |
| Shadow | `TavliShadows.xsmall` |
| Items | 4 |
| Gradient fade | Transparent → `surface` behind bar |

**Nav Item States:**

| State | Container Fill | Icon Color |
|-------|---------------|-----------|
| Active | `background` | `primary` |
| Inactive | `primary` | `light` |
| Hover (inactive) | `primaryHover` | `light` |
| Pressed | `primaryActive` | `light`, scale 0.95 |

Container: 48×48dp circle. Icon: 28dp. Padding: 6px.

**Accessibility:**
- Each item: semantic label ("Home", "Profile", "Customize", "Settings")
- Selected state announced
- 48dp touch targets with 8dp+ spacing

**M3 deviation:** Custom pill bar wrapping standard M3 navigation logic.

### 5.3 Onboarding Pagination

Bottom bar across onboarding screens (1-5).

| Property | Token |
|----------|-------|
| Layout | Left: dots, Right: "Next" button |
| Padding | `md` horizontal × `xl` vertical |
| Active dot | Pill 52×14px, `light`, `TavliRadius.full` |
| Inactive dot | Circle 14×14dp, `primary`, filled |
| Dot gap | 6px |

No interactive states (informational only; "Next" button drives progress).

---

## 6. Avatars

| Variant | Size | Border | Context |
|---------|------|--------|---------|
| Large | 90×90dp | 1px `primary` | Onboarding hero |
| Medium | 48×48dp | 1px `primary` | List items, nav |
| Small | 42×42dp | 0.5px `primary` | Home profile card |

| Property | Token |
|----------|-------|
| Shape | Circle (`TavliRadius.full`) |
| Fill | `surface` |
| Border | `primary` |
| Initial letter | `primary`, ~49% of diameter, w400 |

**Accessibility:** Semantic label "Avatar for {username}". Decorative in lists (merged with parent semantics).

---

## 7. Dialogs

### 7.1 Alert Dialog

Confirmations, errors, destructive action warnings.

| Property | Token |
|----------|-------|
| Background | `background` |
| Border radius | `TavliRadius.lg` |
| Elevation | `TavliShadows.medium` |
| Padding | `TavliSpacing.lg` (24px) |
| Scrim | Black at 32% opacity |
| Max width | 400dp |
| Min width | 280dp (M3 standard) |

**Layout:**
```
┌────────────────────────────┐
│  Title (headlineMedium)    │  ← text color
│                            │
│  Body (bodyLarge)          │  ← text color
│                            │  ← lg gap
│          [Cancel] [Confirm]│  ← right-aligned
└────────────────────────────┘
```
Cancel: text button. Confirm: filled button (destructive: `error` color).

**M3:** Maps to `AlertDialog` via `dialogTheme`.

### 7.2 Bottom Sheet

Game options, sharing, additional actions.

| Property | Token |
|----------|-------|
| Background | `background` |
| Top radius | `TavliRadius.lg` |
| Handle | 32×4dp, `surface`, centered, 8px from top |
| Scrim | Black at 32% opacity |
| Max height | 80% of screen |
| Padding | `TavliSpacing.md` horizontal |

**M3:** Maps to `BottomSheet` via `bottomSheetTheme`.

---

## 8. Lists

### 8.1 Card-Wrapped List Item

Standard list pattern — each item in a card (see [Standard Card](#21-standard-card-list-item)).
Layout: Icon + text column + optional trailing (chevron, switch, value).

### 8.2 Section Header

| Property | Token |
|----------|-------|
| Text style | `titleSmall` (14px w500) |
| Text color | `primary` |
| Padding | `md` horizontal × `xs` bottom |
| Case | Sentence case |

---

## 9. Loading States

### 9.1 Shimmer Placeholder

| Property | Token |
|----------|-------|
| Base color | `backgroundHover` |
| Highlight | `light` |
| Animation | Gradient sweep, 1500ms, ease-in-out |
| Border radius | Matches target element |
| Reduced motion | Static `backgroundHover` fill |

### 9.2 Spinner

| Property | Token |
|----------|-------|
| Color | `primary` |
| Size | 24dp (inline), 48dp (full page) |
| Track color | `surface` at 30% |

---

## 10. Error States

### 10.1 Inline Error

Below input fields on validation failure.

| Property | Token |
|----------|-------|
| Icon | Error triangle, 16dp, `error` color |
| Text | `bodySmall` (12px), `error` color |
| Gap | `xxs` (4px) between icon and text |
| Margin | `xxs` (4px) below input |

### 10.2 Full-Page Error

| Property | Token |
|----------|-------|
| Icon | 64dp error illustration |
| Title | `headlineMedium` |
| Body | `bodyLarge` |
| Action | Filled button "Try Again" |
| Position | Centered vertically |

---

## 11. Empty States

| Property | Token |
|----------|-------|
| Illustration | 120dp themed illustration |
| Title | `headlineSmall` |
| Body | `bodyMedium`, max 2 lines |
| Action (optional) | Outlined button |
| Position | Centered, slightly above center |

---

## 12. Switch

| Property | Token |
|----------|-------|
| M3 widget | `Switch` via `switchTheme` |

**States:**

| State | Thumb | Track |
|-------|-------|-------|
| Off | `surface` | `backgroundHover` |
| On | `primary` | `surface` |
| Off + Hover | `surfaceHover` | `backgroundActive` |
| On + Hover | `primaryHover` | `surfaceHover` |
| Off + Disabled | `surface` at 38% | `backgroundHover` at 38% |
| On + Disabled | `primary` at 38% | `surface` at 38% |
| Focused | current + 2px ring | current |

**Accessibility:** Role: `switch`. Label describes what it controls. State "on"/"off" announced.

---

## 13. Game-Specific Components (Flame Canvas)

Specifications are references — full details in game engine docs.

### 13.1 Dice Display

| Property | Value |
|----------|-------|
| Size | 64×64dp (scalable) |
| Touch target | 64×64dp minimum |
| Visual | 3D rendered with lighting |

**States:**

| State | Visual | Screen Reader |
|-------|--------|---------------|
| Ready to roll | Subtle bounce | "Tap to roll dice" |
| Rolling | Tumble animation (800ms) | "Rolling..." |
| Result shown | Static | "Rolled {value}. {remaining} moves left" |
| Used | 50% opacity | "Die {value} used" |

### 13.2 Checker Display

| Property | Value |
|----------|-------|
| Size | Proportional to board point width |
| Touch target | 48dp minimum |

**States:**

| State | Visual | Screen Reader |
|-------|--------|---------------|
| Default | Base color | "{player}'s checker on point {n}" |
| Selectable | Subtle pulse | "Selectable. {player}'s checker on point {n}" |
| Selected | Elevated, scale 1.1×, glow | "Selected. {player}'s checker on point {n}" |
| Moving | Arc animation (400ms) | "Moving to point {n}" |
| Hit | Flash + move to bar | "Hit! Sent to bar" |
| On bar | In bar area | "On bar. Must re-enter" |

### 13.3 Board Point Highlights

| Indicator | Visual | Screen Reader |
|-----------|--------|---------------|
| Valid target | Pulsing green dot + outline | "Valid move target. Point {n}" |
| Blocked | Static red X | "Blocked. Point {n}" |
| Selected source | Glow + accent | "Move from here" |
| Bear-off zone | Outlined rectangle + pulse | — |

---

## 14. Uniform Design Rules

1. **Same component = same appearance** everywhere
2. **Consistent padding:** `md` (16px) for cards, `sm` (12px) for compact elements
3. **Consistent card gap:** 10px stacked, `sm` (12px) side-by-side
4. **Consistent borders:** 1px `background` on standard cards, 1px `primary` on inputs
5. **No one-off components** — create a new documented variant instead

See [06_UNIFORM_DESIGN.md](06_UNIFORM_DESIGN.md) for full consistency specification.

---

## 15. M3 Widget Mapping

| Component | M3 Widget | Theme Key |
|-----------|-----------|-----------|
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

See [07_MATERIAL_DESIGN.md](07_MATERIAL_DESIGN.md) for complete M3 integration.
