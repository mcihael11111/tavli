# Tavli — 3D Asset Brief for Motion Designer

**Project**: Tavli (Greek Backgammon)
**Platform**: iOS / Android (Flutter + Flame engine)
**Art Direction**: Kafeneio (Greek coffee house) — warm woods, brass accents, Mediterranean tones

---

## Table of Contents

1. [Overview](#1-overview)
2. [Deliverables Summary](#2-deliverables-summary)
3. [File Format & Technical Specs](#3-file-format--technical-specs)
4. [Asset 1 — Board](#4-asset-1--board)
5. [Asset 2 — Checkers (Pieces)](#5-asset-2--checkers-pieces)
6. [Asset 3 — Dice](#6-asset-3--dice)
7. [Asset 4 — Doubling Cube](#7-asset-4--doubling-cube)
8. [Asset 5 — Lottie Animations](#8-asset-5--lottie-animations)
9. [Asset 6 — Background & Environment](#9-asset-6--background--environment)
10. [Color Reference](#10-color-reference)
11. [Naming Conventions](#11-naming-conventions)
12. [Folder Structure](#12-folder-structure)
13. [Appendix — Board Geometry](#13-appendix--board-geometry)

---

## 1. Overview

Tavli is a Greek backgammon app styled after a traditional kafeneio (coffee house). The game currently renders all visuals procedurally on a 2D canvas with faked 3D depth. We want to upgrade to **pre-rendered 3D sprites** for the board, checkers, and dice — plus **Lottie animations** for motion effects.

The goal: make it look and feel like a **premium physical board game** sitting on a wooden table, lit by warm overhead lamplight.

### Art Direction Keywords
- Warm, tactile, premium
- Real wood grain (mahogany, walnut, olive wood)
- Brass/copper metal accents
- Soft directional lighting (upper-left, warm tone)
- Subtle shadows, no harsh edges
- Mediterranean color palette

---

## 2. Deliverables Summary

| # | Asset | Format | Variants | Priority |
|---|-------|--------|----------|----------|
| 1 | Board (full) | PNG @1x/2x/3x | 3 color sets | P0 |
| 2 | Checkers (light) | PNG @1x/2x/3x + spritesheet | idle, selected, stacked (1-5+) | P0 |
| 3 | Checkers (dark) | PNG @1x/2x/3x + spritesheet | idle, selected, stacked (1-5+) | P0 |
| 4 | Dice | PNG @1x/2x/3x + spritesheet | faces 1-6, available/used states | P0 |
| 5 | Doubling cube | PNG @1x/2x/3x | faces: 2, 4, 8, 16, 32, 64 | P1 |
| 6 | Dice roll animation | Lottie JSON | 1 per die color | P1 |
| 7 | Checker place animation | Lottie JSON | light + dark variants | P1 |
| 8 | Checker hit animation | Lottie JSON | 1 universal | P1 |
| 9 | Victory celebration | Lottie JSON | 1 | P2 |
| 10 | Background table surface | PNG @1x/2x/3x | light + dark theme | P2 |
| 11 | Bear-off tray pieces | PNG @1x/2x/3x | stacked 1-15, both colors | P1 |

---

## 3. File Format & Technical Specs

### Static Sprites (PNG)

| Property | Value |
|----------|-------|
| **Format** | PNG-32 (RGBA, transparency) |
| **Color space** | sRGB |
| **Bit depth** | 8-bit per channel |
| **Compression** | Maximum (lossless) |
| **Resolution multipliers** | @1x, @2x, @3x (see sizes below) |
| **Background** | Transparent (except full board) |
| **Anti-aliasing** | Yes, sub-pixel smoothing |
| **Naming** | lowercase_snake_case (see Section 11) |

### Resolution Targets

| Device class | Scale | Board width target | Checker diameter target |
|-------------|-------|--------------------|------------------------|
| @1x (mdpi) | 1x | 960px | 56px |
| @2x (xhdpi) | 2x | 1920px | 112px |
| @3x (xxhdpi) | 3x | 2880px | 168px |

> Design everything at **@3x** and export downscaled versions. This ensures maximum detail.

### Lottie Animations (JSON)

| Property | Value |
|----------|-------|
| **Format** | Lottie JSON (bodymovin export) |
| **Frame rate** | 60fps |
| **Max duration** | 1.5s (effects), 3s (celebrations) |
| **Max file size** | 150KB per file |
| **Compatibility** | Lottie 5.x (After Effects bodymovin 5.12+) |
| **No embedded images** | Vector only — no raster layers inside Lottie |
| **Color mode** | sRGB |
| **Canvas size** | Match the element size (see per-asset specs) |

### Spritesheets

| Property | Value |
|----------|-------|
| **Format** | PNG spritesheet + JSON atlas (TexturePacker format) |
| **Layout** | Grid (equal-size frames, left-to-right, top-to-bottom) |
| **Max sheet size** | 4096x4096px |
| **Padding** | 2px between frames |
| **Trim** | Do NOT trim transparent pixels (keep uniform frame size) |

### 3D Source Files (for future use)

| Property | Value |
|----------|-------|
| **Format** | `.blend` (Blender) + `.glb` (glTF binary export) |
| **Polygon budget** | Low-poly is fine (rendering to sprite, not real-time 3D) |
| **Textures** | Baked, PBR (base color, roughness, normal map) |
| **Scale** | 1 Blender unit = 1cm |

> Please deliver source `.blend` files alongside all exports so we can re-render if needed.

---

## 4. Asset 1 — Board

### Description
A full backgammon board viewed from a **fixed oblique top-down perspective** (~75 degrees from horizontal, camera slightly above and to the front). The board should look like an opened book — two halves connected by a hinge at the center bar.

### Board Structure

```
┌──────────────────────┬─────┬──────────────────────┐
│  ▽  ▽  ▽  ▽  ▽  ▽  │ BAR │  ▽  ▽  ▽  ▽  ▽  ▽  │
│                      │     │                      │
│                      │     │                      │
│                      │     │                      │
│  △  △  △  △  △  △  │     │  △  △  △  △  △  △  │
├──────────────────────┤     ├──────────────────────┤
│       BEAR-OFF       │     │       BEAR-OFF       │
└──────────────────────┴─────┴──────────────────────┘
```

- **24 triangular points** (12 top, 12 bottom, alternating colors)
- **Center bar** dividing left and right halves
- **Bear-off trays** on left and right edges
- **Wooden frame** with visible thickness/bevel
- **Brass hinges** at center bar (2-3 small hinges)
- **Playing surface**: recessed, felt or leather texture
- **Optional**: small diamond or inlay decoration on the bar

### 3 Color Variants

#### Set 1 — Mahogany & Olive Wood (Default)
| Element | Color | Hex |
|---------|-------|-----|
| Frame (dark) | Mahogany | `#8B4513` |
| Frame (light) | Lighter mahogany | `#A0522D` |
| Points A | Mahogany tone | `#A0522D` |
| Points B | Olive wood | `#9A8B3C` |
| Playing surface | Olive wood light | `#C8B560` |
| Felt/leather | Muted olive green | — |

#### Set 2 — Mahogany & Teal
| Element | Color | Hex |
|---------|-------|-----|
| Frame (dark) | Deep red-brown | `#6F3024` |
| Frame (light) | Warm brown | `#8B4226` |
| Points A | Aegean teal | `#1A5C5C` |
| Points B | Pale maple | `#DEC8A0` |
| Playing surface | Rich brown | `#8B4226` |
| Felt/leather | Dark teal-green | — |

#### Set 3 — Dark Walnut & Navy
| Element | Color | Hex |
|---------|-------|-----|
| Frame (dark) | Dark walnut | `#2A1A0E` |
| Frame (light) | Medium walnut | `#4A3520` |
| Points A | Copper | `#B87333` |
| Points B | Ash wood | `#C4B28E` |
| Playing surface | Navy | `#2C3E50` |
| Felt/leather | Dark navy | — |

### Board Export Spec

| Export | Size @3x | Notes |
|--------|----------|-------|
| `board_set1.png` | 2880 x 1800px | Full board, no checkers |
| `board_set2.png` | 2880 x 1800px | Full board, no checkers |
| `board_set3.png` | 2880 x 1800px | Full board, no checkers |

> Aspect ratio ~16:10 (landscape). Transparent background — we composite onto the table surface.

---

## 5. Asset 2 — Checkers (Pieces)

### Description
Cylindrical wooden/stone checkers viewed from the same oblique perspective as the board. They should look like thick coins — visible top face + visible rim/edge.

### Visual Details
- **Shape**: Cylinder, ~28% height-to-diameter ratio
- **Top face**: Slightly convex, with concentric ring groove (like a real backgammon piece)
- **Rim**: Visible edge with subtle bevel
- **Material**: Polished wood or stone
- **Lighting**: Soft highlight upper-left, shadow lower-right
- **Drop shadow**: Included in sprite, soft, offset down-right

### Colors

| Variant | Base Color | Hex | Material Feel |
|---------|-----------|-----|---------------|
| Light (Player 1) | Warm ivory | `#F0E4C8` | Polished birch or bone |
| Dark (Player 2) | Rich dark brown | `#2C1810` | Dark walnut or ebony |

### States to Render

| State | Description | Visual Difference |
|-------|-------------|-------------------|
| **Idle** | Resting on board | Normal lighting, standard shadow |
| **Selected** | Player has tapped this piece | Golden glow outline (`#C8A94E`), slightly raised shadow (lifted feel), scale 110% |

### Stacking

Checkers stack on top of each other. Render stacks of **1 through 5 checkers**, plus a **6+ indicator**.

| Stack count | Render |
|------------|--------|
| 1 | Single checker |
| 2 | 2 stacked, slight offset showing rim of bottom piece |
| 3 | 3 stacked |
| 4 | 4 stacked |
| 5 | 5 stacked (max visible) |

> For 6+ we overlay a count badge in-app, so just provide up to 5.

### Checker Export Spec

| Export | Size @3x | Notes |
|--------|----------|-------|
| `checker_light_idle_1.png` | 168 x 200px | Single light piece + shadow |
| `checker_light_idle_2.png` | 168 x 230px | Stack of 2 |
| `checker_light_idle_3.png` | 168 x 260px | Stack of 3 |
| `checker_light_idle_4.png` | 168 x 290px | Stack of 4 |
| `checker_light_idle_5.png` | 168 x 320px | Stack of 5 |
| `checker_light_selected_1.png` | 186 x 220px | Single, glowing, scaled up |
| `checker_dark_idle_1.png` | 168 x 200px | (same sizes as light) |
| ... | ... | (repeat for all dark variants) |

> Heights are approximate — allow enough canvas for shadow and stack height. Keep the checker itself centered horizontally.

### Bear-Off Checkers (Side View)

Checkers stacked flat on their side in the bear-off tray, seen from the front.

| Export | Size @3x | Notes |
|--------|----------|-------|
| `bearoff_light_1.png` through `bearoff_light_15.png` | 168 x variable | Stacked sideways, 1-15 |
| `bearoff_dark_1.png` through `bearoff_dark_15.png` | 168 x variable | Same for dark |

---

## 6. Asset 3 — Dice

### Description
Classic 3D dice with rounded corners, viewed from the same oblique perspective. Should look like premium bone or ivory dice with drilled pips.

### Visual Details
- **Shape**: Cube with rounded corners (radius ~12% of edge length)
- **Material**: Polished ivory/cream
- **Pips**: Drilled circular indentations, dark brown fill
- **Visible faces**: Top + right + front (3-quarter view)
- **Lighting**: Consistent with board (upper-left warm light)
- **Shadow**: Soft drop shadow included in sprite

### Colors

| State | Face Color | Pip Color | Opacity |
|-------|-----------|-----------|---------|
| Available | `#FAF6EE` (warm cream) | `#2C1810` (dark brown) | 100% |
| Used | `#D4CDB8` (muted tan) | `#8C7C60` (faded brown) | 55% |

### Faces to Render
Render all 6 faces (values 1-6) in both states (available, used).

Standard pip layouts:
- **1**: Center
- **2**: Top-right, bottom-left (diagonal)
- **3**: Top-right, center, bottom-left
- **4**: Four corners
- **5**: Four corners + center
- **6**: Three left, three right (two columns)

### Dice Export Spec

| Export | Size @3x | Notes |
|--------|----------|-------|
| `die_available_1.png` | 120 x 140px | Value 1, bright state |
| `die_available_2.png` | 120 x 140px | Value 2, bright state |
| ... | ... | Through value 6 |
| `die_used_1.png` | 120 x 140px | Value 1, faded state |
| ... | ... | Through value 6 |

---

## 7. Asset 4 — Doubling Cube

### Description
A slightly larger die with numbers instead of pips. Used to track stakes in the game.

### Visual Details
- Same material/lighting as dice but slightly larger
- Numbers rendered as **engraved gold text** on faces
- Faces show: **2, 4, 8, 16, 32, 64**

### Export Spec

| Export | Size @3x | Notes |
|--------|----------|-------|
| `cube_2.png` | 150 x 170px | Showing "2" on top face |
| `cube_4.png` | 150 x 170px | Showing "4" |
| `cube_8.png` | 150 x 170px | Showing "8" |
| `cube_16.png` | 150 x 170px | Showing "16" |
| `cube_32.png` | 150 x 170px | Showing "32" |
| `cube_64.png` | 150 x 170px | Showing "64" |

---

## 8. Asset 5 — Lottie Animations

All Lottie animations should be vector-only (no embedded rasters). Design at **@3x size** — we scale in-app.

### 8.1 Dice Roll

| Property | Value |
|----------|-------|
| **File** | `dice_roll.json` |
| **Canvas** | 300 x 300px |
| **Duration** | 0.8 - 1.2s |
| **FPS** | 60 |
| **Description** | Two dice tumbling/bouncing and landing. Start mid-air, bounce 2-3 times with decreasing height, settle. The final face values will be composited by us — animate with placeholder values. |
| **Feel** | Satisfying, weighty, tactile. Slight motion blur on fast frames. |

### 8.2 Checker Place / Land

| Property | Value |
|----------|-------|
| **File** | `checker_place_light.json`, `checker_place_dark.json` |
| **Canvas** | 200 x 200px |
| **Duration** | 0.3 - 0.5s |
| **FPS** | 60 |
| **Description** | A checker landing on a point. Slight downward motion, subtle bounce, tiny dust/shadow puff on contact. |
| **Feel** | Snappy, satisfying click. Like setting a stone piece down on wood. |

### 8.3 Checker Hit (Blot)

| Property | Value |
|----------|-------|
| **File** | `checker_hit.json` |
| **Canvas** | 250 x 250px |
| **Duration** | 0.5 - 0.8s |
| **FPS** | 60 |
| **Description** | Impact effect when a checker is sent to the bar. Brief flash/ring expanding outward from center, terracotta tint (`#C67B5C`). The hit piece slides away (animated by us) — this is just the impact burst. |
| **Feel** | Dramatic but not violent. Think chess piece captured, not explosion. |

### 8.4 Victory Celebration

| Property | Value |
|----------|-------|
| **File** | `victory.json` |
| **Canvas** | 1080 x 1920px (portrait full-screen) |
| **Duration** | 2.0 - 3.0s |
| **FPS** | 60 |
| **Description** | Celebration effect for winning a game. Golden particles rising, subtle confetti in olive gold (`#C8A94E`) and parchment (`#F5ECD7`) tones. Warm, classy — not childish or over-the-top. Mediterranean/Greek feel. |
| **Feel** | Premium, warm, celebratory. Like winning a high-stakes kafeneio game. |

### 8.5 Turn Indicator Pulse (Nice-to-Have)

| Property | Value |
|----------|-------|
| **File** | `turn_pulse.json` |
| **Canvas** | 100 x 100px |
| **Duration** | 1.5s (looping) |
| **FPS** | 60 |
| **Description** | Gentle glowing pulse to indicate it's the player's turn. Olive gold (`#C8A94E`) glow that breathes in and out. |

---

## 9. Asset 6 — Background & Environment

### Table Surface

The board sits on a table. Render a seamless tileable wood texture for the table surface.

| Export | Size @3x | Notes |
|--------|----------|-------|
| `table_light.png` | 1024 x 1024px | Warm oak/pine, medium brown, tileable |
| `table_dark.png` | 1024 x 1024px | Dark wood for night/dark mode, tileable |

> Should be **seamlessly tileable** in both X and Y.

---

## 10. Color Reference

### Core Palette

| Name | Hex | Usage |
|------|-----|-------|
| Kafeneio Brown | `#5C3A21` | App background, primary dark |
| Aegean Blue | `#1A5C5C` | Teal accents, board set 2 |
| Olive Gold | `#C8A94E` | Highlights, selection glow, accents |
| Parchment | `#F5ECD7` | Light backgrounds, text |
| Terracotta | `#C67B5C` | Hit effects, warnings |
| Marble White | `#FAF8F5` | Lightest background |
| Night Wood | `#1A1209` | Dark mode background |
| Checker Light | `#F0E4C8` | Player 1 pieces |
| Checker Dark | `#2C1810` | Player 2 pieces |
| Warm Lamplight | `#FFF5E0` | Light color for 3D rendering |

### Accent Swatches (for download)

If helpful, here are the RGB values:

```
#5C3A21  →  R:92   G:58  B:33
#1A5C5C  →  R:26   G:92  B:92
#C8A94E  →  R:200  G:169 B:78
#F5ECD7  →  R:245  G:236 B:215
#C67B5C  →  R:198  G:123 B:92
#F0E4C8  →  R:240  G:228 B:200
#2C1810  →  R:44   G:24  B:16
#FFF5E0  →  R:255  G:245 B:224
```

---

## 11. Naming Conventions

All filenames must be **lowercase_snake_case**. No spaces, no capital letters, no special characters.

### Pattern
```
{asset}_{variant}_{state}_{detail}.{ext}
```

### Examples
```
board_set1.png
board_set2.png
checker_light_idle_1.png
checker_light_idle_5.png
checker_light_selected_1.png
checker_dark_idle_1.png
die_available_1.png
die_used_6.png
cube_16.png
bearoff_light_3.png
dice_roll.json
checker_place_light.json
checker_hit.json
victory.json
table_light.png
```

---

## 12. Folder Structure

Please deliver assets in this structure:

```
delivery/
├── boards/
│   ├── 1x/
│   │   ├── board_set1.png
│   │   ├── board_set2.png
│   │   └── board_set3.png
│   ├── 2x/
│   └── 3x/
├── checkers/
│   ├── 1x/
│   │   ├── checker_light_idle_1.png
│   │   ├── ...
│   │   ├── checker_dark_idle_1.png
│   │   └── ...
│   ├── 2x/
│   └── 3x/
├── dice/
│   ├── 1x/
│   ├── 2x/
│   └── 3x/
├── cube/
│   ├── 1x/
│   ├── 2x/
│   └── 3x/
├── bearoff/
│   ├── 1x/
│   ├── 2x/
│   └── 3x/
├── backgrounds/
│   ├── 1x/
│   ├── 2x/
│   └── 3x/
├── animations/
│   ├── dice_roll.json
│   ├── checker_place_light.json
│   ├── checker_place_dark.json
│   ├── checker_hit.json
│   ├── victory.json
│   └── turn_pulse.json
└── source/
    ├── board.blend
    ├── checker.blend
    ├── dice.blend
    └── scene.blend
```

---

## 13. Appendix A — Board Geometry

### Proportional Layout (for accurate 3D modeling)

These proportions define the board layout. Use them to ensure pieces align correctly with the board render.

| Element | Proportion (of board width) |
|---------|---------------------------|
| Frame thickness | 2.5% |
| Bar width (center) | 4% |
| Bear-off tray width | 5% each side |
| Point width | (100% - 5% frame - 4% bar - 10% bearoff) / 12 = ~6.75% |
| Point height | 42% of board height (from each edge inward) |
| Checker diameter | 90% of point width |
| Checker thickness | 28% of checker diameter |

---

## 14. Appendix B — Camera, Projection & Positioning (CRITICAL)

This section ensures that all sprites align perfectly when composited in-engine. **Read this carefully.**

### Projection Decision: Orthographic

**Use ORTHOGRAPHIC projection, NOT perspective.**

Why: We position checkers programmatically at runtime. With perspective, the far side of the board is smaller than the near side, meaning a checker rendered at one size won't fit at all 24 points. Orthographic eliminates this entirely — one checker sprite fits everywhere.

Orthographic still looks 3D because:
- Checkers have visible cylinder thickness and rim
- Surfaces have light/shadow gradients
- Wood grain and materials read as 3D
- Stacking shows depth

The 3D feel comes from **lighting, materials, and form** — not perspective distortion.

### Camera Setup (Blender)

| Property | Value |
|----------|-------|
| **Projection** | Orthographic |
| **Camera rotation X** | 75 degrees (nearly top-down, 15-degree tilt toward player) |
| **Camera rotation Y** | 0 degrees (centered, no left/right rotation) |
| **Camera rotation Z** | 0 degrees |
| **Orthographic scale** | Fit the board tightly with ~2% margin |
| **Camera position** | Centered directly above the board center |

### Lighting Setup

| Property | Value |
|----------|-------|
| **Key light type** | Area light (soft shadows) |
| **Key light direction** | Upper-left, slightly forward (vector: -0.35, -0.55, 0.75) |
| **Key light color** | Warm `#FFF5E0` |
| **Key light intensity** | Medium-soft (enough to show form, not overexpose wood) |
| **Ambient/HDRI** | 35% intensity, neutral warm |
| **Shadow type** | Soft (area light, large radius) |
| **Shadow color** | Dark brown `#1A0E05` |
| **No harsh shadows** | Everything should feel warm and inviting |

### Why Orthographic Matters for Positioning

With orthographic projection, measurements on the rendered image map linearly to the 3D scene. This means:

- A checker rendered alone at position (0,0) is the **exact same size and shape** as it would be at any of the 24 points
- We can place one checker sprite anywhere on the board and it fits perfectly
- Stacking is simple: offset Y by a fixed amount (no perspective scaling needed)
- The board layout proportions (Section 13) map directly to pixel coordinates in the final render

---

## 15. Appendix C — Registration Points & Alignment Guide

### Board Registration Map

**The artist MUST deliver a registration map alongside the board render.** This is a separate image (or JSON file) showing the exact pixel coordinates of key anchor points on the board.

#### Required Anchor Points (at @3x resolution, 2880 x 1800px)

Deliver a JSON file `board_registration.json` for each board set:

```json
{
  "resolution": [2880, 1800],
  "points": {
    "0":  {"x": 123, "y": 1650, "note": "Bottom-right point 0 (P1 home)"},
    "1":  {"x": 194, "y": 1650},
    "2":  {"x": 265, "y": 1650},
    "...": "etc for all 24 points",
    "5":  {"x": 513, "y": 1650, "note": "Last point in P1 home board"},
    "6":  {"x": 600, "y": 1650, "note": "First point after bear-off tray"},
    "11": {"x": 943, "y": 1650, "note": "Last point before bar"},
    "12": {"x": 1080, "y": 150, "note": "First top point after bar"},
    "23": {"x": 2750, "y": 150, "note": "Top-right point"}
  },
  "bar_center": {"x": 1440, "y": 900},
  "bearoff_left": {"x": 80, "y": 900},
  "bearoff_right": {"x": 2800, "y": 900},
  "dice_area": {"x": 2100, "y": 900},
  "point_width_px": 194,
  "checker_diameter_px": 168,
  "stacking_offset_px": 144,
  "playing_surface_bounds": {
    "top_left": {"x": 72, "y": 45},
    "bottom_right": {"x": 2808, "y": 1755}
  }
}
```

**How to generate this:** In Blender, place small marker objects at the center-base of each point triangle. Render, note the pixel coordinates. Or render a numbered grid overlay as a separate layer.

#### Alternative: Numbered Grid Overlay

If JSON is too tedious, deliver a **separate PNG** at the same resolution as the board, with:
- A colored dot at the center-base of each of the 24 points
- Dots numbered 0-23
- A dot at bar center, bear-off centers, and dice area
- A rectangle showing the playing surface bounds

We can extract coordinates from this image programmatically.

### Checker Anchor Point

Each checker sprite must have its **anchor point at the bottom-center** of the checker (where it touches the board surface). This is where we place it in code.

```
     ┌─────────┐
     │  top    │  ← visible top face
     │  face   │
     ├─────────┤
     │  rim    │  ← visible cylinder edge
     └────●────┘  ← ANCHOR POINT (bottom center)
         ↑
    This pixel is the registration point.
    We position this pixel at the board's point coordinate.
```

**In the sprite:** The anchor point should be at approximately:
- X: 50% of sprite width (horizontally centered)
- Y: ~85% of sprite height (near the bottom, leaving room for shadow below)

### Checker Stacking Offsets

Because we use orthographic projection, stacking is simple:

| Stack position | Y offset from base (in checker-diameter units) |
|---------------|----------------------------------------------|
| 0 (bottom) | 0 |
| 1 | -0.85 × checker height |
| 2 | -1.70 × checker height |
| 3 | -2.55 × checker height |
| 4 | -3.40 × checker height |

The negative direction is "toward the center of the board" (up for bottom-row points, down for top-row points).

> **Stacking overlap**: Each checker overlaps the one below by 15% — this is why we multiply by 0.85 not 1.0.

### Dice Positioning

Dice are placed in the right half of the board, centered vertically. Exact position comes from the registration map's `dice_area` point.

| Element | Position |
|---------|----------|
| Die 1 | dice_area.x - 20px, dice_area.y |
| Die 2 | dice_area.x + 20px, dice_area.y |
| Gap between dice | 14px @1x (42px @3x) |

### Shadow Handling for Compositing

Because we use orthographic projection with a fixed light direction, **all shadows fall in the same direction regardless of board position.** This means:

- Checker shadow is baked into the checker sprite (same shadow everywhere)
- No per-position shadow adjustment needed
- Shadow should extend ~10% of checker diameter toward lower-right
- Shadow opacity: 30-40%, soft Gaussian blur

---

## 16. Appendix D — Making It Look 3D (Visual Depth Checklist)

Even with orthographic projection and 2D sprite compositing, we can achieve a premium 3D look. Here's what sells the illusion:

### Board
- [ ] Visible frame thickness (beveled edges catch light differently on top vs sides)
- [ ] Recessed playing surface (subtle shadow at the inner edge of the frame)
- [ ] Wood grain rendered with bump/normal maps for surface detail
- [ ] Brass hinges with metallic reflection
- [ ] Slight vignette/shadow at board edges where it meets the table

### Checkers
- [ ] Visible cylinder rim (the side of the checker shows thickness)
- [ ] Top face slightly lighter than rim (receiving more direct light)
- [ ] Concentric ring groove on top face catches light as a thin bright line
- [ ] Specular highlight on upper-left of top face (from key light)
- [ ] Soft drop shadow offset to lower-right
- [ ] When stacked, upper checkers cast shadow on lower ones (bake into stack sprites)

### Dice
- [ ] Three visible faces (top, right, front) — classic 3/4 view
- [ ] Rounded corners with specular highlights on edges
- [ ] Drilled pip indentations (dark inside, catching shadow)
- [ ] Soft drop shadow
- [ ] Slight subsurface scattering if ivory material (warm glow through edges)

### Doubling Cube
- [ ] Engraved numbers catch light differently (recessed surface)
- [ ] Metallic gold fill in engravings
- [ ] Heavier/darker wood material than dice (feels premium, separate)

### Overall Scene
- [ ] Warm color temperature throughout (no cool/blue tones)
- [ ] Shadows all consistent direction (lower-right)
- [ ] Materials look tactile — you want to reach out and touch them
- [ ] Nothing looks flat or matte — subtle reflections/sheen on all surfaces

---

## Questions / Notes for Designer

1. **Use ORTHOGRAPHIC projection** — this is non-negotiable for programmatic piece placement. See Section 14 for why.

2. **Deliver the registration map** — either JSON or numbered overlay PNG. Without this, we cannot position pieces accurately. See Section 15.

3. **Checker anchor point is bottom-center** — not the visual center of the sprite. This is where the piece meets the board surface.

4. **Shadows baked into sprites, same direction everywhere** — ortho projection means shadow is identical regardless of board position.

5. **Leave transparent padding** — selected checkers get a golden glow added in-app. Leave ~15% padding on all sides of checker sprites.

6. **Dice final values are set in code** — for the dice roll Lottie, use any placeholder face values. We swap in the correct static sprite when the animation ends.

7. **The 3D illusion comes from materials, not perspective** — see Section 16 checklist. Spend time on lighting, surface detail, and rim visibility rather than camera tricks.

8. **Iterative delivery is welcome** — start with the board + registration map + idle checkers (P0). We can integrate and test alignment before you move on to animations.

---

*Document version: 2.0 — March 2026*
*Contact: [YOUR EMAIL / SLACK HERE]*
