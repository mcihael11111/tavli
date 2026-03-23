> **DEPRECATED** — This document has been superseded by [`design/06_UNIFORM_DESIGN.md`](design/06_UNIFORM_DESIGN.md) and [`design/02_COMPONENTS.md`](design/02_COMPONENTS.md).

# Tavli Design Standards (Deprecated)

## Overview

This document defines the design principles, quality standards, and review criteria for all visual and interaction design in Tavli. It serves as the source of truth when making design decisions.

---

## 1. Core Design Principles

### 1.1 Board First
The game board is always the hero. Every UI decision must prioritize the playing experience. Chrome, controls, and information overlays must never compete with the board for attention.

### 1.2 30-Second Rule
A first-time user must be able to start playing within 30 seconds of opening the app. Every tap between "open app" and "first move" is a cost.

### 1.3 One-Thumb Playable
All core game interactions (selecting checkers, choosing destinations, rolling dice) must be achievable with one thumb in both portrait and landscape orientation.

### 1.4 Warm, Never Cold
Everything is bathed in Mediterranean warmth — golden light, wood tones, natural materials. Never clinical, corporate, or cold blue-grey.

### 1.5 Premium Simplicity
Clean, uncluttered interface. The app should feel like a luxury product, not a casino game. No flashing elements, no gratuitous animation, no visual noise.

### 1.6 Respect the Ritual
The pace of the app mirrors the rhythm of real tavli — unhurried but purposeful. Animations have weight. Transitions feel organic.

---

## 2. Anti-Patterns — What Tavli Is NOT

| Anti-Pattern | Why It's Wrong |
|-------------|---------------|
| Cartoon/casual aesthetic | We're a premium board game, not a casual puzzler |
| Casino/gambling feel | No flashing lights, coin animations, or slot-machine energy |
| Flat/minimal modern UI | The board itself must be richly textured and dimensional |
| Ad-cluttered layout | No ads, banners, or promotional interruptions |
| Dark patterns | No forced sign-ups, fake urgency, or manipulative CTAs |
| Skeleton Greek theme | No columns, urns, or Parthenon clipart — authentic, not stereotypical |

---

## 3. Visual Quality Standards

### 3.1 Board Rendering
- Board must evoke real Manopoulos craftsmanship
- Wood grain texture must be visible (not flat color fills)
- Frame must appear raised with shadow depth
- Points (triangles) must have subtle outline for definition
- Center bar must include decorative diamond motif
- Checkers must cast shadows onto the playing surface

### 3.2 Checker Rendering
- Concentric ring pattern (like real turned-wood/resin checkers)
- Highlight arc simulating light reflection
- Shadow beneath (offset, soft blur)
- Selection state: gold glow outline + 8% scale increase
- Stacking: visible overlap with consistent offset

### 3.3 Dice Rendering
- Rounded corners (real dice feel)
- Pips are circular dots, not numbers
- Shadow beneath dice
- Used dice appear desaturated
- Roll prompt has clear visual affordance

### 3.4 Animation Quality
- All movement has weight — no instant teleportation
- Checker movement follows arc paths (lift → travel → land)
- Landing has a single dampened bounce
- Dice settle with diminishing wobble
- No animation should exceed 1 second (except dice roll)

---

## 4. Layout Standards

### 4.1 Game Screen (Landscape)
```
┌──────────────────────────────────────┐
│ [Opponent Bar]           [Pip Count] │  ← 48dp
│ ┌──────────────────────────────────┐ │
│ │         GAME BOARD               │ │  ← Fills remaining space
│ │      (Flame rendering)           │ │
│ └──────────────────────────────────┘ │
│ [Dialogue Bar]                       │  ← Conditional, 40dp
│ [Player Bar]     [Undo] [Menu]       │  ← 48dp
└──────────────────────────────────────┘
```

### 4.2 Screen Margins
- Scaffold: 0dp (edge-to-edge)
- Content padding: 16-24dp horizontal
- Card internal padding: 16dp
- Section spacing: 24-32dp vertical

### 4.3 Responsive Behavior
- Board scales to fill available space
- UI bars are fixed height
- Point width = (board_width - frame - bar - trays) / 12
- Checker radius = point_width × 0.45

---

## 5. Content Standards

### 5.1 Text Voice
- Mikhail's dialogue: casual, warm, Greek-inflected English with Greek phrases
- UI copy: concise, friendly, never condescending
- Error messages: helpful, suggest recovery action
- No exclamation marks in UI copy (except Mikhail's dialogue)

### 5.2 Greek Text
- Greek characters must render correctly (polytonic support)
- Greek and English mixed naturally in Mikhail's speech
- Transliterations provided in parentheses for uncommon terms
- Greek difficulty names displayed prominently, English in secondary position

### 5.3 Empty States
Every screen that could be empty has a designed empty state:
- Profile with no games: Mikhail invites you to play
- Match history empty: "No games yet — let's change that!"
- Friend list empty: "Invite a friend to play"

---

## 6. Design Review Checklist

Before merging any UI change:

- [ ] Colors use `TavliColors.*` tokens (no hardcoded hex)
- [ ] Text contrast meets WCAG AA (4.5:1 for body, 3:1 for large)
- [ ] Touch targets are ≥ 48dp
- [ ] Opacity on text is ≥ 0.7 (informational) or ≥ 0.8 (dark bg)
- [ ] Layout works in both portrait and landscape
- [ ] Dark mode renders correctly
- [ ] Animations respect `reduceMotion` preference
- [ ] No new warnings from `dart analyze`
- [ ] Screenshots captured for review at phone and tablet sizes
