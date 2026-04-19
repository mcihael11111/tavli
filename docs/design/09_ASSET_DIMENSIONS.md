# 09 — Asset Dimensions & Re-Export Targets

Single source of truth for **pixel dimensions, aspect ratios, and re-export rules** for every raw image asset that the Flame game loads. Read this before cropping, re-exporting, or swapping any sprite — the rendering code is calibrated to specific proportions and will misalign if the numbers drift.

Scope: **all sprite-rendered assets.** Board sprites now exist for sets 1–3; checkers and dice remain set-1-only (sets 2–3 fall back to procedural rendering for those).

---

## 1. Current asset inventory

| Asset | File | Pixels | Ratio | Notes |
|---|---|---|---|---|
| Board (set 1 — mahogany & olive) | [set1_board.png](../../assets/images/boards/set1_board.png) | **2102 × 1950** | 1.0779 | Re-exported 2026-04-19 from shared 4320×2700 template |
| Board (set 2 — walnut & navy) | [set2_board.png](../../assets/images/boards/set2_board.png) | **2102 × 1950** | 1.0779 | Pixel-aligned with set 1 (same template, recolored triangles/felt) |
| Board (set 3 — teal & maple) | [set3_board.png](../../assets/images/boards/set3_board.png) | **2102 × 1950** | 1.0779 | Pixel-aligned with set 1 (same template, recolored triangles/felt) |
| Board shadow (set 1) | [set1_board_shadow.png](../../assets/images/boards/set1_board_shadow.png) | 2106 × 1954 | 1.0778 | Rendered underneath at +2/+3 px; legacy dimensions, 4 px wider/taller than new boards (visually negligible) |
| Table backdrop | [table.png](../../assets/images/backgrounds/table.png) | **4320 × 2700** | 1.60 (8:5) | Wood-table texture intended as game-screen backdrop |
| Light checker (normal) | [set1_light_normal.png](../../assets/images/checkers/set1_light_normal.png) | 293 × 293 | 1.00 (square) | |
| Dark checker (normal) | [set1_dark_normal.png](../../assets/images/checkers/set1_dark_normal.png) | 294 × 294 | 1.00 (square) | |
| Light checker (selected) | [set1_light_selected.png](../../assets/images/checkers/set1_light_selected.png) | **369 × 389** | 0.949 (NOT square) | Misalignment hotspot |
| Dark checker (selected) | [set1_dark_selected.png](../../assets/images/checkers/set1_dark_selected.png) | **369 × 389** | 0.949 (NOT square) | Misalignment hotspot |
| Die face 1–6 | [set1_die_N_active.png](../../assets/images/dice/) | 135–136 × 135 | ~1.00 | 1 px drift between faces |

---

## 1a. Board template (all 3 sets share this)

The three board sprites are derived from a single shared **4320 × 2700 master PNG** where the board art occupies a fixed bounding box `(1103, 379) → (3205, 2329)` = **2102 × 1950 px**. All three exports (mahogany_olive, walnut_navy, teal_maple) were produced from this template with only the triangle and felt colors varied; the frame, hinge, gold clasps, bar, and triangle geometry are pixel-identical.

**Verified alignment after cropping to the board bbox:**

- Top-frame mean pixel diff across all 3 boards: **7 RGB units** (essentially identical)
- Structural frame-column mask: **1–2 columns out of 2102 differ** (0.05–0.10%)
- Gold clasp y-positions: **identical on all 3 boards**

**Implication:** checkers rendered at any point on any board land in the same screen position. Switching themes mid-game produces no visual drift. The percentages in `board_layout.dart` calibrated against the original 2106 × 1954 sprite apply unchanged to the new 2102 × 1950 sprites (ratio difference is 0.0001, inside rounding noise).

---

## 2. Why misalignment happens

The Flame layout math in [board_layout.dart:53-77](../../lib/flame_game/components/board_layout.dart#L53-L77) hard-codes percentages measured **directly against `set1_board.png` at 2106 × 1954**:

| Parameter | Current value | Measured from sprite |
|---|---|---|
| Frame inner edge | 3.1% of board width | 65 / 2106 px |
| Center bar | 3.1% of board width | 66 / 2106 px |
| Top/bottom felt inset | 2.8% of board height | 55 / 1954 px |
| Triangle row height | 32% of board height | 625 / 1954 px |
| Stack anchor nudge | 2.0 px | Triangle base shadow depth |

**If the sprite is re-exported with different proportions, checkers drift off the painted triangles.** Any crop must preserve these internal percentages.

Two additional hotspots:

- **Selected checker sprites are 369 × 389 (not square).** Flame renders them into a square box (`radius × 2`) at [checker_component.dart:185](../../lib/flame_game/components/checker_component.dart#L185), which stretches the art and shifts its visual center off the point's anchor. This is the most likely cause of the select-state misalignment.
- **Board shadow is offset by hard-coded `+2, +3 px`** at [board_component.dart:110-117](../../lib/flame_game/components/board_component.dart#L110-L117). Shadow file must stay pixel-identical to the board file.

---

## 3. Re-export targets

### 3.1 Board + board shadow

- **Ratio:** 1.0779 : 1 (current)
- **Size:** **2102 × 1950 px** (cropped from the shared 4320 × 2700 master)
- **Internal proportions preserved from the shared template** — percentages in `board_layout.dart` remain valid:
  - Frame inner edge: ~3.1% of board width
  - Center bar: ~3.1% of board width
  - Top/bottom felt inset: ~2.8% of board height
  - Triangle row height: ~32% of board height
  - Triangle base shadow: ~2 px
- **All new sets must come from the same 4320 × 2700 master** cropped to the same bbox `(1103, 379) → (3205, 2329)`. This guarantees pixel-alignment across themes so checkers land in identical positions on every board.
- Shadow (`set1_board_shadow.png`) is still 2106 × 1954 from the earlier master — the 4 px discrepancy is visually negligible but can be re-cropped to match if a perfect shadow is produced later.
- If the template is ever replaced with one of a different aspect, the percentages in [board_layout.dart:68-77](../../lib/flame_game/components/board_layout.dart#L68-L77) must be re-measured.

### 3.2 Checkers (all 4 variants)

- **Ratio:** 1:1 square — non-negotiable
- **Size:** **400 × 400 px** for every variant (normal + selected, light + dark)
- Chip artwork must be **centered** with **identical padding** across all 4 files
- Selected-state glow/halo must fit **inside** the same 400 × 400 canvas — do not grow the canvas
- This single change (selected variants becoming 1:1 instead of 0.949:1) resolves the select-state jump

### 3.3 Dice (6 faces)

- **Ratio:** 1:1 square
- **Size:** **400 × 400 px** (consistent with checkers — one canvas size for all sprite assets)
- All 6 faces must be **exactly** the same dimensions (no 1 px drift)
- Pips must sit in the **same safe area on every face** so the die doesn't jitter when the value changes

### 3.4 Background image (table.png now available)

`table.png` (4320 × 2700, 1.60 ratio) is now in [backgrounds/](../../assets/images/backgrounds/table.png) — a warm wood texture ready to be wired as the game-screen backdrop. The game still renders a flat color fill at [game_screen.dart:594](../../lib/features/game/presentation/game_screen.dart#L594); switching to `table.png` is a separate task.

General rules for any background image:

- **Ratio:** **21:9 (2.33:1)** — matches the widest phone so nothing important gets cropped off the ends
- **Size:** **2520 × 1080 px**
- **`BoxFit.cover`** — image scales to fill the landscape viewport

**Safe zones** (content that must survive cropping on narrower devices):

| Target | Safe zone | Devices covered |
|---|---|---|
| Full canvas | 2520 × 1080 (21:9) | Ultrawide Android phones |
| 16:9 safe zone | center 1920 × 1080 | Standard 16:9 phones |
| 4:3 safe zone | center 1440 × 1080 | iPad / tablets landscape |

**Board occlusion zone:** the board covers the center ~2420 × 840 of the viewport. Nothing inside that zone is ever visible — keep it as a neutral texture and put visual interest at the **edges** and **top/bottom bands** (thin slivers beside the board, plus the top-bar and action-area bands above/below it).

**Color direction:** current fill is `#6B4F3A` (warm brown). Replacement imagery should sit in that warm-earth family so the UI text and buttons (designed against this color) keep contrast per [00_TOKENS.md](00_TOKENS.md).

Alternative if round numbers are easier to work with: **16:9 at 2560 × 1440 px**, accepting a small top/bottom crop on ultrawide phones.

---

## 4. Summary rules

| Asset | Ratio | Size | Rule |
|---|---|---|---|
| Board (all sets) | 1.0779:1 | 2102 × 1950 | Must come from the shared 4320×2700 master cropped to bbox `(1103,379)→(3205,2329)` so all sets align pixel-for-pixel |
| Board shadow | 1.0778:1 | 2106 × 1954 | Set-1-only; reuse for all sets or re-crop to 2102×1950 later |
| All checkers | 1:1 | 400 × 400 | Centered artwork, identical padding, selection glow inside the canvas |
| All dice | 1:1 | 400 × 400 | Identical dimensions across all 6 faces, pips in a shared safe area |
| Background | 1.60:1 (or 21:9) | table.png 4320×2700, or re-export 2520×1080 | Visual interest at edges; center ~80% is covered by the board |

Hold these three rules (square checkers, square dice, preserved board proportions) and the existing rendering math keeps working without code changes. Overlays layer cleanly on top.

---

## 5. Files to re-measure if proportions change

If any re-export changes internal proportions (not just resolution), re-measure and update:

- [board_layout.dart:68-77](../../lib/flame_game/components/board_layout.dart#L68-L77) — frame/bar/inset/triangle percentages
- [board_layout.dart:77](../../lib/flame_game/components/board_layout.dart#L77) — `stackAnchorNudge` if triangle base shadow changes
- [board_component.dart:110-117](../../lib/flame_game/components/board_component.dart#L110-L117) — shadow `+2, +3 px` offset if shadow art changes
- [checker_component.dart:185](../../lib/flame_game/components/checker_component.dart#L185) — sprite render size math, if checker canvas becomes non-square
