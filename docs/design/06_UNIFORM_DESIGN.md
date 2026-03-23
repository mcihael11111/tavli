# Uniform Design

> Consistency rules, spacing rhythm, alignment grid, do/don't examples.
> Uniformity is not a constraint — it is a feature.

## Related Documents

- [Design System](01_DESIGN_SYSTEM.md) — Token definitions referenced here
- [Components](02_COMPONENTS.md) — Component specifications
- [States](03_STATES.md) — Consistent state treatments
- [Accessibility](05_ACCESSIBILITY.md) — Consistency as accessibility aid
- [Material Design 3](07_MATERIAL_DESIGN.md) — M3 consistency principles

---

## 1. Core Principle

> **Same component, same appearance, every time.**

Users build mental models through repetition. When a card looks the same on every screen, users learn its behavior once. When spacing is predictable, content feels organized. When transitions are consistent, the app feels polished rather than chaotic.

Uniformity reduces cognitive load, speeds learning, and directly supports accessibility.

---

## 2. Spacing Rhythm

### 2.1 The 4px Grid

All spacing derives from a **4px base unit**. Only these values are permitted:

```
4  ·  8  ·  12  ·  16  ·  24  ·  32  ·  48
```

No arbitrary values. No 5px. No 10px. No 20px. No 36px.

**Exception:** The 10px gap between stacked list cards (from the Figma design) is the only non-grid value. It is documented as a specific component spacing and must not be used elsewhere.

### 2.2 Spacing Application Rules

| Context | Value | Token | Rule |
|---------|-------|-------|------|
| Page horizontal padding | 16px | `md` | Every screen, no exceptions |
| Card internal padding | 16px | `md` | All card variants |
| Compact element padding | 12px | `sm` | Chips, example boxes |
| Gap between stacked cards | 10px | Custom | List items only |
| Gap between side-by-side cards | 12px | `sm` | Tabs, horizontal groups |
| Section title to content | 12px | `sm` | All section headers |
| Between unrelated sections | 24px | `lg` | Major content breaks |
| Bottom safe area | 24px+ | `lg` | Always respected |
| Icon to label gap | 4-8px | `xxs`-`xs` | Inline icon + text |

### 2.3 Do / Don't

**Do:**
- Use 16px horizontal padding on every screen
- Use 16px internal padding in every card
- Use 12px gap between related elements
- Use 24px to separate unrelated sections

**Don't:**
- Use 15px or 17px "because it looks better" — use 16px
- Mix 10px and 12px gaps in the same context
- Use 0px padding on cards to "save space"
- Add extra padding to "center" elements — use alignment instead

---

## 3. Alignment Grid

### 3.1 8px Layout Grid

All layout elements align to an **8px grid**. This means:
- Component positions should fall on 8px increments
- Content areas use 16px (2×), 24px (3×), 32px (4×) margins
- Exceptions: text baselines and centered elements may fall between grid lines

### 3.2 Content Alignment Rules

| Element | Alignment | Rule |
|---------|-----------|------|
| Screen titles | Center | Always centered horizontally |
| Body text | Center (onboarding), Left (settings) | Context-dependent |
| Cards | Full width minus padding | 16px from each edge |
| Buttons (onboarding) | Right-aligned in footer | Next button bottom-right |
| Buttons (dialogs) | Right-aligned | Cancel left, Confirm right |
| Icons in cards | Left, vertically centered | Consistent leading position |
| Avatars (hero) | Center | Centered in upper-third |
| Navigation | Center, evenly distributed | Equal spacing between items |

### 3.3 Do / Don't

**Do:**
- Align card edges to the same 16px page margin
- Center titles consistently
- Align icons to the same left position within cards

**Don't:**
- Eyeball alignment — use the spacing tokens
- Mix left and center alignment for the same type of content
- Offset cards by different amounts on different screens

---

## 4. Color Consistency

### 4.1 Rules

1. **Never hardcode hex values** — always use `TavliColors.*` constants
2. **Never use `Color(0xFF...)` in widgets** — reference the constants class
3. **Same context = same color** — body text is always `text`, headings are always `primary` or `text`
4. **No opacity below 0.38** on any visible element (disabled state minimum)
5. **No opacity on interactive text** — always 100% for readable, interactive content
6. **Semantic colors always with icons** — never color alone for meaning

### 4.2 Do / Don't

**Do:**
```dart
// Correct: use named constant
Text('Hello', style: TextStyle(color: TavliColors.text))
Container(color: TavliColors.background)
```

**Don't:**
```dart
// Wrong: hardcoded hex
Text('Hello', style: TextStyle(color: Color(0xFF1A1A1A)))
Container(color: Color(0xFFD4C2A8))

// Wrong: unnamed opacity
Text('Hello', style: TextStyle(color: Colors.black54))
```

---

## 5. Typography Consistency

### 5.1 Rules

1. **Always use `Theme.of(context).textTheme.*`** — never inline `TextStyle` with arbitrary sizes
2. **Font sizes come from the scale only** — 11, 12, 14, 16, 18, 21, 24, 27, 31, 42
3. **Same content type = same text style** everywhere:
   - Screen titles → `headlineLarge` (24px)
   - Card titles → `titleLarge` (18px)
   - Card subtitles → `bodyMedium` (14px)
   - Body text → `bodyLarge` (16px)
   - Button labels → `labelLarge` (14px) or `titleMedium` (16px)
   - Section headers → `titleSmall` (14px)
4. **No `TextStyle` overrides** that change font size — choose a different text style instead
5. **Color overrides allowed** only to match the background context

### 5.2 Do / Don't

**Do:**
```dart
Text('Tavli', style: Theme.of(context).textTheme.headlineLarge)
Text('Play now', style: Theme.of(context).textTheme.bodyLarge)
```

**Don't:**
```dart
// Wrong: arbitrary size
Text('Tavli', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))

// Wrong: overriding scale size
Text('Play', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15))
```

---

## 6. Component Consistency

### 6.1 Rules

1. **One card style** — don't invent new card variants per screen
2. **One button style per priority** — filled for primary, outlined for secondary, text for tertiary
3. **Consistent border treatment** — standard cards have 1px `background` border; inputs have 1px `primary` border
4. **Consistent radius per component type** — cards are 16px, buttons are 8px, always
5. **Consistent elevation** — cards use `xsmall`, dialogs use `medium`, always
6. **Consistent icon size** — 24dp for standard, 32-40dp for card leading icons

### 6.2 Component Audit Checklist

When adding a new screen, verify:

- [ ] Page uses `surface` color (scaffold background)
- [ ] Horizontal padding is 16px
- [ ] Cards on page use `primary` fill + 1px `background` border + 16px radius with `light` text
- [ ] Elevated cards use `background` fill + 1px `primary` border + 16px radius with `primary` text
- [ ] Buttons match existing style for their priority level
- [ ] Spacing between elements uses documented tokens only
- [ ] Touch targets are ≥ 48dp
- [ ] Focus rings match specification

### 6.3 Do / Don't

**Do:**
- Reuse the standard card component for all list items
- Use the same button variant for the same action type across screens
- Keep the same avatar component at all sizes

**Don't:**
- Create a "special" card with different radius for one screen
- Use a filled button where the same action uses outlined on another screen
- Mix icon sizes for the same type of action

---

## 7. State Treatment Consistency

### 7.1 Rules

1. **Hover = 8% darken/lighten** — every component, no exceptions
2. **Pressed = 12% darken/lighten** — every component
3. **Disabled = 38% opacity** — every component
4. **Focus = 2px `primary` ring, 2px offset** — every focusable element
5. **Transition timing matches the state table** — no custom durations
6. **Press scale = 0.98** — for buttons and cards

See [States](03_STATES.md) for the complete specification.

### 7.2 Do / Don't

**Do:**
- Use `TavliColors.primaryHover` for hover state on primary buttons
- Apply the same 0.98 scale on press to all tappable cards

**Don't:**
- Use a different shade "because it looks better on this screen"
- Skip the press scale on some cards but not others
- Use a different focus ring color for "emphasis"

---

## 8. Animation Consistency

### 8.1 Rules

1. **State transitions: 50-200ms** — see timing table in [States](03_STATES.md)
2. **Page transitions: 300ms** — slide + fade, consistent direction
3. **Standard curve: `easeInOut`** — unless specifically documented otherwise
4. **No custom easing** without documentation
5. **All animations respect reduced motion** — `MediaQuery.disableAnimations`

### 8.2 Do / Don't

**Do:**
- Use 300ms for all page transitions
- Use `easeInOut` for all standard animations
- Check `disableAnimations` before every animated widget

**Don't:**
- Use 500ms on one page and 200ms on another for the same transition type
- Use bouncing spring physics for a button press
- Add decorative animations without a reduced-motion alternative

---

## 9. Naming Conventions

### 9.1 Dart Constants

| Type | Convention | Example |
|------|-----------|---------|
| Colors | `TavliColors.camelCase` | `TavliColors.primaryHover` |
| Spacing | `TavliSpacing.abbreviation` | `TavliSpacing.md` |
| Radius | `TavliRadius.abbreviation` | `TavliRadius.lg` |
| Shadows | `TavliShadows.name` | `TavliShadows.xsmall` |
| Theme | `TavliTheme.variant` | `TavliTheme.light` |

### 9.2 File Naming

| Type | Convention | Example |
|------|-----------|---------|
| Screens | `feature_screen.dart` | `home_screen.dart` |
| Widgets | `widget_name.dart` | `game_card.dart` |
| Constants | `category.dart` | `colors.dart` |
| Models | `model_name.dart` | `board_state.dart` |

### 9.3 Semantic Labels

| Convention | Example |
|-----------|---------|
| Action verbs | "Roll dice", "Open settings" |
| No widget type | "Roll dice" not "Roll dice button" |
| Context-specific | "Your checker on point 12" not "Checker" |

---

## 10. Anti-Patterns

### What Tavli is NOT

| Anti-Pattern | Why |
|-------------|-----|
| Neon colors | Breaks warm Mediterranean palette |
| Sharp shadows | Harsh; use warm-tinted soft shadows |
| Thin 1px text | Poor readability; minimum 11px |
| Complex gradients on UI | Distracts from game board |
| Skeuomorphic UI controls | Game board is textured; UI stays clean |
| Auto-playing video | Breaks reduced motion; no video in UI |
| Infinite scroll | Game app, not content feed |
| Dense data tables | Not a business app |
| Blue/grey color accents | Clashes with warm palette |
| Custom fonts per screen | One family (Poppins) throughout |

---

## 11. Design Review Checklist

Before merging any UI change:

### Visual Consistency
- [ ] Colors use `TavliColors.*` constants (no hardcoded values)
- [ ] Text styles use `Theme.of(context).textTheme.*` (no inline styles)
- [ ] Spacing uses `TavliSpacing.*` (no magic numbers)
- [ ] Border radius uses `TavliRadius.*`
- [ ] Shadows use `TavliShadows.*`

### Component Consistency
- [ ] Same component looks identical to other instances in the app
- [ ] Button variant matches action priority (filled/outlined/text)
- [ ] Cards follow standard specification
- [ ] Navigation elements match existing patterns

### Interaction Consistency
- [ ] Hover, pressed, focused, disabled states implemented
- [ ] State shades use pre-computed constants
- [ ] Focus ring matches specification
- [ ] Disabled state uses 38% opacity

### Accessibility
- [ ] All interactive elements have semantic labels
- [ ] Touch targets ≥ 48dp
- [ ] Text contrast meets WCAG AA
- [ ] Focus navigation works in logical order
- [ ] Reduced motion respected

### Responsive
- [ ] Text scaling to 200% doesn't break layout
- [ ] Safe areas respected (notch, home indicator)
- [ ] Keyboard doesn't obscure inputs

---

## 12. Accessibility Considerations

Uniformity directly supports accessibility:

- **Predictable patterns** reduce cognitive load for all users
- **Consistent focus indicators** make keyboard navigation learnable
- **Reliable spacing** means touch targets are predictably placed
- **Uniform color usage** means contrast is consistently verified
- **Same component behavior** means screen reader users learn interactions once

When consistency and one-off "improvements" conflict, consistency wins.

---

## 13. Material Design 3 Alignment

M3 is built on consistency principles:

| M3 Principle | Tavli Implementation |
|-------------|---------------------|
| Design tokens | `TavliColors`, `TavliSpacing`, `TavliRadius`, `TavliShadows` |
| Component theming | All styling through `ThemeData`, not per-widget |
| State management | `WidgetStateProperty` for all state-aware styling |
| Shape system | Consistent radius tokens mapped to M3 shape scale |
| Type scale | Single scale (Minor Second) applied through `TextTheme` |
| Color roles | Explicit `ColorScheme` with semantic roles |

See [Material Design 3](07_MATERIAL_DESIGN.md) for the complete specification.
