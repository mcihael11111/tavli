# Material Design 3 Alignment

> How Tavli maps to, extends, and deviates from Material Design 3
> Flutter `useMaterial3: true` | Material 3 specification v2

## Related Documents

- [Design System](01_DESIGN_SYSTEM.md) — Core tokens referenced here
- [Components](02_COMPONENTS.md) — Per-component M3 mapping
- [States](03_STATES.md) — State layer implementation via M3
- [Accessibility](05_ACCESSIBILITY.md) — M3 accessibility features used

---

## 1. Overview

Tavli adopts Material Design 3 as its **structural foundation** — leveraging its component architecture, state management, typography system, and accessibility patterns — while applying a custom warm aesthetic that evokes the Mediterranean backgammon tradition.

### Philosophy

> Use M3 structure. Override M3 personality.

We keep:
- Component architecture (`ElevatedButton`, `Card`, `NavigationBar`, etc.)
- State management (`WidgetState`, `WidgetStateProperty`)
- Layout patterns (`Scaffold`, `AppBar`, `BottomSheet`)
- Accessibility infrastructure (`Semantics`, `FocusNode`, `MediaQuery`)

We replace:
- Color generation (static warm palette, not HCT dynamic color)
- Type scale ratio (Minor Second 1.067, not M3 Major Second 1.125)
- Shadow system (warm-tinted, not neutral grey)
- Shape personality (warmer radii, fully rounded nav bar)

---

## 2. Color System Mapping

### 2.1 Core Color → M3 Color Roles

| M3 Color Role | Tavli Token | Hex | Notes |
|---------------|-------------|-----|-------|
| `primary` | `primary` | `#6B4F3A` | Interactive elements, emphasis |
| `onPrimary` | `light` | `#F3F0EB` | Text/icons on primary |
| `primaryContainer` | `surface` | `#A67F5B` | Cards, elevated surfaces |
| `onPrimaryContainer` | `text` | `#1A1A1A` | Text on primaryContainer |
| `secondary` | `surface` | `#A67F5B` | Secondary actions |
| `onSecondary` | `text` | `#1A1A1A` | Text on secondary |
| `secondaryContainer` | `backgroundHover` | `#C4B298` | Subtle containers |
| `onSecondaryContainer` | `text` | `#1A1A1A` | Text on secondaryContainer |
| `tertiary` | `primary` | `#6B4F3A` | Tertiary accent (same as primary) |
| `onTertiary` | `light` | `#F3F0EB` | Text on tertiary |
| `surface` | `surface` | `#A67F5B` | Page backgrounds, scaffold |
| `onSurface` | `light` | `#F3F0EB` | Primary text on surface |
| `onSurfaceVariant` | `primary` | `#6B4F3A` | Secondary text, icons |
| `outline` | `primary` | `#6B4F3A` | Borders, dividers |
| `outlineVariant` | `surface` | `#A67F5B` | Subtle borders |
| `error` | `error` | `#A0442C` | Error states |
| `onError` | `light` | `#F3F0EB` | Text on error |
| `inverseSurface` | `text` | `#1A1A1A` | Snackbar background |
| `onInverseSurface` | `light` | `#F3F0EB` | Snackbar text |
| `shadow` | — | `#000000` | Shadow color (opacity varies) |
| `surfaceTint` | `primary` | `#6B4F3A` | M3 elevation tint |

### 2.2 ColorScheme Constructor (Light)

```dart
static const ColorScheme lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: TavliColors.primary,           // #6B4F3A
  onPrimary: TavliColors.light,           // #F3F0EB
  primaryContainer: TavliColors.surface,   // #A67F5B
  onPrimaryContainer: TavliColors.text,    // #1A1A1A
  secondary: TavliColors.surface,          // #A67F5B
  onSecondary: TavliColors.text,           // #1A1A1A
  secondaryContainer: TavliColors.backgroundHover, // #C4B298
  onSecondaryContainer: TavliColors.text,  // #1A1A1A
  tertiary: TavliColors.primary,           // #6B4F3A
  onTertiary: TavliColors.light,           // #F3F0EB
  surface: TavliColors.surface,             // #A67F5B
  onSurface: TavliColors.light,            // #F3F0EB
  onSurfaceVariant: TavliColors.primary,   // #6B4F3A
  outline: TavliColors.primary,            // #6B4F3A
  outlineVariant: TavliColors.surface,     // #A67F5B
  error: TavliColors.error,               // #A0442C
  onError: TavliColors.light,             // #F3F0EB
  inverseSurface: TavliColors.text,        // #1A1A1A
  onInverseSurface: TavliColors.light,     // #F3F0EB
  shadow: Colors.black,
  surfaceTint: TavliColors.primary,        // #6B4F3A
);
```

### 2.3 ColorScheme Constructor (Dark)

```dart
static const ColorScheme darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: TavliColors.primaryDark,              // #D4C2A8
  onPrimary: TavliColors.textDark,               // #1A1A1A (mapped)
  primaryContainer: TavliColors.surfaceDark,      // #3D2E20
  onPrimaryContainer: TavliColors.lightDark,      // reuse light
  secondary: TavliColors.surfaceDark,             // #3D2E20
  onSecondary: TavliColors.light,                 // #F3F0EB
  surface: TavliColors.backgroundDark,            // #1A1A1A
  onSurface: TavliColors.light,                   // #F3F0EB
  onSurfaceVariant: TavliColors.primaryDark,      // #D4C2A8
  outline: TavliColors.primaryDark,               // #D4C2A8
  outlineVariant: TavliColors.surfaceDark,        // #3D2E20
  error: TavliColors.error,                       // #A0442C
  onError: TavliColors.light,                     // #F3F0EB
  inverseSurface: TavliColors.light,              // #F3F0EB
  onInverseSurface: TavliColors.text,             // #1A1A1A
  shadow: Colors.black,
  surfaceTint: TavliColors.primaryDark,           // #D4C2A8
);
```

### 2.4 Deviation: No Dynamic Color

M3 generates palettes via the HCT (Hue, Chroma, Tone) color space from a seed color. Tavli **does not** use dynamic color because:

1. The brand identity is defined by 5 specific hex values from the Figma design
2. The warm brown palette is intentional — algorithm-generated tones would drift from the Mediterranean aesthetic
3. Game board colors must remain visually distinct from UI colors

**Implementation:** `colorSchemeSeed` is NOT used. A fully explicit `ColorScheme` is provided instead.

---

## 3. Typography Mapping

### 3.1 Scale Comparison

| M3 Style | M3 Default Size | Tavli Size | Difference |
|-----------|----------------|------------|------------|
| displayLarge | 57px | 42px | -26% (Minor Second ceiling) |
| displayMedium | 45px | 31px | -31% |
| displaySmall | 36px | 27px | -25% |
| headlineLarge | 32px | 24px | -25% |
| headlineMedium | 28px | 21px | -25% |
| headlineSmall | 24px | 18px | -25% |
| titleLarge | 22px | 18px | -18% |
| titleMedium | 16px | 16px | Same |
| titleSmall | 14px | 14px | Same |
| bodyLarge | 16px | 16px | Same |
| bodyMedium | 14px | 14px | Same |
| bodySmall | 12px | 12px | Same |
| labelLarge | 14px | 14px | Same |
| labelMedium | 12px | 12px | Same |
| labelSmall | 11px | 11px | Same |

### 3.2 Deviation: Minor Second vs M3 Major Second

M3 uses a Major Second ratio (1.125), producing larger intervals between sizes. Tavli uses Minor Second (1.067), which creates:
- **Tighter size increments** — more subtle hierarchy steps
- **Smaller display sizes** — 42px max vs M3's 57px
- **Better for compact game UI** — less vertical space consumed by headings
- **Body/label sizes identical** — the scales converge at the base (16px down to 11px)

### 3.3 TextTheme Constructor

```dart
static TextTheme get _textTheme => const TextTheme(
  displayLarge: TextStyle(fontSize: 42, fontWeight: FontWeight.w700, height: 1.24, letterSpacing: -0.84),
  displayMedium: TextStyle(fontSize: 31, fontWeight: FontWeight.w700, height: 1.29, letterSpacing: -0.62),
  displaySmall: TextStyle(fontSize: 27, fontWeight: FontWeight.w600, height: 1.33, letterSpacing: -0.27),
  headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.33, letterSpacing: -0.48),
  headlineMedium: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, height: 1.33, letterSpacing: -0.42),
  headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.33, letterSpacing: 0),
  titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, height: 1.33, letterSpacing: 0),
  titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.38, letterSpacing: 0.15),
  titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.43, letterSpacing: 0.1),
  bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, letterSpacing: 0),
  bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.43, letterSpacing: 0.25),
  bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.33, letterSpacing: 0.4),
  labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.43, letterSpacing: 0.1),
  labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.33, letterSpacing: 0.5),
  labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.45, letterSpacing: 0.5),
);
```

---

## 4. Component Mapping

### 4.1 M3 Component → Tavli Usage

| M3 Component | Flutter Widget | Tavli Usage | Customization |
|--------------|---------------|-------------|---------------|
| Filled Button | `FilledButton` | Primary actions ("Next", "Play") | Custom colors, radius 8px |
| Outlined Button | `OutlinedButton` | Secondary actions | Border `primary`, radius 8px |
| Text Button | `TextButton` | Tertiary actions, links | `primary` color |
| Icon Button | `IconButton` | Nav icons, settings | 48dp touch target |
| Filled Tonal Button | `FilledButton.tonal` | Not used | — |
| FAB | `FloatingActionButton` | Not used (game context) | — |
| Card | `Card` | List items, menu items | `primary` fill, `background` border, radius 16px |
| Dialog | `AlertDialog` | Confirmations, errors | Radius 16px |
| Bottom Sheet | `BottomSheet` | Game options, share | Radius 16px top |
| NavigationBar | `NavigationBar` | Main nav (Home) | Fully rounded, `background` bg |
| AppBar | `AppBar` | Screen titles | Transparent, no elevation |
| TextField | `TextField` | Search, profile name | `surface` fill, `primary` border |
| Slider | `Slider` | Greek level, volumes | `surface` track, `primary` thumb |
| Switch | `Switch` | Settings toggles | `primary`/`surface` colors |
| ListTile | `ListTile` | Settings items, menu items | Custom card-wrapped variant |
| Chip | `FilterChip` | Game type tabs (Portes, Plakoto, Fevga) | `surface` fill, radius 16px |
| SnackBar | `SnackBar` | Non-critical notifications | `text` bg, `light` text |
| Tooltip | `Tooltip` | Icon button descriptions | Default M3 styling |
| ProgressIndicator | `CircularProgressIndicator` | Loading states | `primary` color |

### 4.2 Components Used As-Is (No Customization)

- `Tooltip`
- `CircularProgressIndicator` / `LinearProgressIndicator`
- `Divider` (color overridden via theme)
- `SnackBar` (colors via theme)
- `Scrollbar`

### 4.3 Components Not Used

| M3 Component | Reason |
|--------------|--------|
| FAB | No persistent floating action in game context |
| NavigationDrawer | Bottom nav used instead |
| NavigationRail | Mobile-only app |
| SegmentedButton | Custom chip-style tabs used |
| DatePicker / TimePicker | No date/time input needed |
| DataTable | No tabular data |
| Badge | Not part of design language |
| SearchBar (M3) | Custom search input used |

---

## 5. Shape System

### 5.1 M3 Shape Scale → Tavli Radius

| M3 Shape | M3 Default | Tavli Value | Usage |
|----------|-----------|-------------|-------|
| Extra Small | 4dp | 4px (`TavliRadius.xs`) | Subtle rounding |
| Small | 8dp | 8px (`TavliRadius.sm`) | Buttons, inputs |
| Medium | 12dp | 12px (`TavliRadius.md`) | Dialogs, chips |
| Large | 16dp | 16px (`TavliRadius.lg`) | Cards, bottom sheets |
| Extra Large | 28dp | 24px (`TavliRadius.xl`) | Modals |
| Full | 50% | 100px (`TavliRadius.full`) | Avatars, pills, nav bar |

### 5.2 Deviation

M3 Extra Large is 28dp; Tavli uses 24px (aligned to the 4px spacing grid). Full shapes use a fixed 100px radius instead of 50% to ensure consistent pill shapes at varying sizes.

---

## 6. Elevation System

### 6.1 M3 Elevation → Tavli Shadows

M3 uses a combination of shadow + surface tint overlay. Tavli uses **shadow only** (no tint overlay) to keep the warm palette clean.

| M3 Level | M3 Elevation | Tavli Shadow | Usage |
|----------|-------------|-------------|-------|
| Level 0 | 0dp | None | Flat elements |
| Level 1 | 1dp | `xsmall` (0 1px 2px 0.3α) | Cards, buttons, list items |
| Level 2 | 3dp | `small` (0 0 8px 0.1α) | Slider thumb, tooltips |
| Level 3 | 6dp | `medium` (0 4px 16px 0.15α) | Dialogs, bottom sheets |
| Level 4 | 8dp | `large` (0 0 48px 0.2α) | Carousel cards, hero images |
| Level 5 | 12dp | Not used | — |

### 6.2 Deviation: No Surface Tint

M3 adds a `surfaceTint` overlay at higher elevations to differentiate surfaces in light mode. Tavli skips this because:
- The warm palette already differentiates surfaces via `background` vs `surface` colors
- Tint overlays would muddy the carefully chosen brown tones
- Cards use explicit `primary` fill + `background` border instead of elevation tinting

**Implementation:** Set `surfaceTintColor: Colors.transparent` in `ThemeData` if needed to prevent M3 automatic tinting.

---

## 7. State Layers

### 7.1 M3 State Layer Opacity → Tavli Treatment

M3 defines state layers as semi-transparent overlays on the `primary` color:

| State | M3 Opacity | Tavli Approach |
|-------|------------|---------------|
| Hover | 8% | Darken/lighten core color by 8% (pre-computed shade) |
| Focus | 10% | 2px `primary` focus ring (no overlay) |
| Pressed | 10% | Darken/lighten core color by 12% (pre-computed shade) |
| Dragged | 16% | Same as pressed |
| Disabled | — | 38% opacity on entire element |

### 7.2 Deviation

M3 uses a runtime `Color.withOpacity()` overlay. Tavli uses **pre-computed shade colors** to avoid translucency artifacts on textured/patterned backgrounds (the game board). This ensures consistent rendering on both Flutter UI and Flame canvas overlays.

### 7.3 Implementation Pattern

```dart
// M3 standard (NOT used by Tavli):
// MaterialStateProperty.resolveWith((states) {
//   if (states.contains(MaterialState.hovered))
//     return primary.withOpacity(0.08);
// })

// Tavli approach (pre-computed shades):
WidgetStateProperty.resolveWith((states) {
  if (states.contains(WidgetState.disabled)) {
    return TavliColors.primary.withOpacity(0.38);
  }
  if (states.contains(WidgetState.pressed)) {
    return TavliColors.primaryActive;  // #846852
  }
  if (states.contains(WidgetState.hovered)) {
    return TavliColors.primaryHover;   // #7A5E49
  }
  return TavliColors.primary;          // #6B4F3A
});
```

---

## 8. Motion System

### 8.1 M3 Motion Tokens → Tavli

| M3 Token | M3 Default | Tavli Value | Usage |
|----------|-----------|-------------|-------|
| Duration Short 1 | 50ms | 50ms | Ripple start |
| Duration Short 2 | 100ms | 100ms | Micro-interactions |
| Duration Short 3 | 150ms | 150ms | State changes (hover, press) |
| Duration Short 4 | 200ms | 200ms | Small transitions |
| Duration Medium 1 | 250ms | 250ms | Component enter/exit |
| Duration Medium 2 | 300ms | 300ms | Page transitions |
| Duration Medium 3 | 350ms | 350ms | Complex transitions |
| Duration Medium 4 | 400ms | 400ms | Checker movement |
| Duration Long 1 | 450ms | 450ms | — |
| Duration Long 2 | 500ms | 500ms | — |
| Easing Standard | cubic-bezier(0.2, 0, 0, 1) | `Curves.easeInOut` | Default easing |
| Easing Emphasized | cubic-bezier(0.2, 0, 0, 1) | `Curves.easeOutCubic` | Enter transitions |
| Easing Decelerate | cubic-bezier(0, 0, 0, 1) | `Curves.decelerate` | Arriving elements |

### 8.2 Game-Specific Motion

| Animation | Duration | Curve | Reduced Motion |
|-----------|----------|-------|---------------|
| Dice roll | 800ms | Custom spring | Instant result |
| Checker move | 400ms | `easeOutCubic` | Instant reposition |
| Checker hit | 300ms | `easeInOut` | Instant bar placement |
| Board flip | 500ms | `easeInOutCubic` | Instant flip |
| Victory particles | 2000ms | Linear | Static badge |

---

## 9. Token Mapping (Complete Reference)

### 9.1 Design Tokens

| M3 Token | Tavli Constant | Value |
|----------|---------------|-------|
| `md.sys.color.primary` | `TavliColors.primary` | `#6B4F3A` |
| `md.sys.color.on-primary` | `TavliColors.light` | `#F3F0EB` |
| `md.sys.color.surface` | `TavliColors.surface` | `#A67F5B` |
| `md.sys.color.on-surface` | `TavliColors.light` | `#F3F0EB` |
| `md.sys.color.outline` | `TavliColors.primary` | `#6B4F3A` |
| `md.sys.color.error` | `TavliColors.error` | `#A0442C` |
| `md.sys.typescale.body-large.size` | 16px | Minor Second base |
| `md.sys.typescale.display-large.size` | 42px | Minor Second +15 |
| `md.sys.shape.corner.large` | `TavliRadius.lg` | 16px |
| `md.sys.shape.corner.full` | `TavliRadius.full` | 100px |
| `md.sys.elevation.level1` | `TavliShadows.xsmall` | 0 1px 2px |
| `md.sys.state.hover.state-layer-opacity` | 8% darken | Pre-computed shade |
| `md.sys.state.pressed.state-layer-opacity` | 12% darken | Pre-computed shade |
| `md.sys.state.disabled.container-opacity` | 0.38 | 38% alpha |
| `md.sys.motion.duration.medium2` | 300ms | Page transitions |

---

## 10. ThemeData Reference (Annotated)

```dart
class TavliTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: lightScheme,
    scaffoldBackgroundColor: TavliColors.surface,
    textTheme: _textTheme.apply(
      bodyColor: TavliColors.text,
      displayColor: TavliColors.text,
    ),
    fontFamily: 'Poppins',

    // AppBar: transparent, no elevation, centered title
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 24, fontWeight: FontWeight.w600,
        color: TavliColors.text, fontFamily: 'Poppins',
      ),
      iconTheme: IconThemeData(color: TavliColors.primary, size: 24),
    ),

    // Cards: primary fill, background border, rounded 16px
    cardTheme: CardTheme(
      color: TavliColors.primary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: TavliColors.background),
      ),
      margin: EdgeInsets.zero,
    ),

    // Filled button: primary bg, light text, 8px radius
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: TavliColors.primary,
        foregroundColor: TavliColors.light,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
    ),

    // Outlined button: surface fill, primary border, 8px radius
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: TavliColors.surface,
        foregroundColor: TavliColors.primary,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: TavliColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
    ),

    // Input fields: surface fill, primary border
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TavliColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: TavliColors.primary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: TavliColors.primary, width: 2),
      ),
      labelStyle: const TextStyle(color: TavliColors.text),
      hintStyle: TextStyle(color: TavliColors.text.withOpacity(0.6)),
    ),

    // Navigation bar: custom fully rounded, background fill
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: TavliColors.background,
      indicatorColor: TavliColors.primary,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: TavliColors.light, size: 24);
        }
        return const IconThemeData(color: TavliColors.primary, size: 24);
      }),
      height: 68,
    ),

    // Slider: surface track, primary thumb
    sliderTheme: SliderThemeData(
      activeTrackColor: TavliColors.surface,
      inactiveTrackColor: TavliColors.surface,
      thumbColor: TavliColors.surface,
      overlayColor: TavliColors.primary.withOpacity(0.12),
      trackHeight: 12,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return TavliColors.primary;
        return TavliColors.surface;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return TavliColors.surface;
        return TavliColors.backgroundHover;
      }),
    ),

    // Dialog
    dialogTheme: DialogTheme(
      backgroundColor: TavliColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: const TextStyle(
        fontSize: 21, fontWeight: FontWeight.w600,
        color: TavliColors.text, fontFamily: 'Poppins',
      ),
    ),

    // Bottom sheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: TavliColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color: TavliColors.primary.withOpacity(0.2),
      thickness: 1,
    ),

    // Disable surface tint (M3 deviation)
    // surfaceTintColor handled via ColorScheme
  );
}
```

---

## 11. Known Deviations Summary

| Area | M3 Standard | Tavli Deviation | Rationale |
|------|------------|----------------|-----------|
| Color generation | HCT dynamic color | Static 5-color palette | Brand identity preservation |
| Type scale ratio | Major Second (1.125) | Minor Second (1.067) | Compact game UI needs tighter scale |
| Display sizes | 36-57px | 27-42px | Game screens don't need massive type |
| Surface tint | Tint overlay at elevation | No tint, explicit colors | Warm palette preservation |
| State layers | Runtime opacity overlay | Pre-computed shade colors | Consistent rendering on game canvas |
| NavigationBar | Standard M3 shape | Fully rounded pill | Design aesthetic choice |
| Shape extra large | 28dp | 24px | Aligned to 4px grid |
| Shadow color | Neutral black | Warm-tinted (same black, warm context) | Mediterranean aesthetic |
| Tertiary color | Distinct hue | Same as primary | 5-color constraint |

---

## 12. Accessibility via M3

See [Accessibility](05_ACCESSIBILITY.md) for the full specification. M3 features leveraged:

| Feature | Widget/API | Usage |
|---------|-----------|-------|
| Semantic labels | `Semantics` | All interactive elements |
| Focus management | `FocusNode`, `FocusTraversalGroup` | Logical tab order |
| State-aware styling | `WidgetStateProperty` | Contrast maintained across states |
| Touch targets | `minimumSize` in button styles | 48dp minimum enforced via theme |
| Text scaling | `MediaQuery.textScaler` | System setting honored |
| Motion preference | `MediaQuery.disableAnimations` | Reduced motion respected |
| Tooltips | `Tooltip` widget | All icon-only buttons |
