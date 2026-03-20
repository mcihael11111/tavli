# Tavli — AI Asset Generation Prompt Pack

## Recommended Tools

### For Sprites (Board, Checkers, Dice)

| Tool | Best For | Cost | Why |
|------|----------|------|-----|
| **Midjourney v6.1** | Overall best quality | $10/mo (Basic) | Best at consistent style, lighting, materials. Top pick for premium board game assets. |
| **Leonardo AI** | Good free tier, fast | Free tier / $12/mo | Strong at product renders, good consistency with style references. Great for iterating. |
| **DALL-E 3 (ChatGPT Plus)** | Prompt accuracy | $20/mo (via ChatGPT) | Follows instructions precisely. Good for specific layouts like the board. |

**My pick: Midjourney** — best material rendering (wood, brass, ivory). Use `--style raw` for product-shot realism.

### For 3D Models (if you want real .glb files)

| Tool | Best For | Cost |
|------|----------|------|
| **Meshy.ai** | Text-to-3D, best quality | Free tier / $20/mo |
| **Tripo3D** | Fast single-object 3D | Free tier / $8/mo |
| **CSM (Common Sense Machines)** | Image-to-3D conversion | Free tier |

**Workflow**: Generate a 2D image with Midjourney → upload to **CSM** or **Meshy** image-to-3D → export `.glb` → render sprites from Blender.

### For Lottie Animations

| Tool | Best For | Cost |
|------|----------|------|
| **LottieFiles Creator** | Simple motion effects | Free |
| **Jitter.video** | Motion design → Lottie export | Free tier / $12/mo |
| **Rive** | Interactive animations | Free tier |

AI can't generate good Lottie files yet. Use **Jitter** for the particle/burst effects, or **Rive** for the interactive ones. Both export to Lottie JSON.

---

## How to Use This Prompt Pack

### Consistency Rules

Every prompt below includes these shared style anchors. **Do not remove them** — they keep all assets looking like they belong together:

```
Style anchors (included in every prompt):
- "warm directional lighting from upper left"
- "soft shadows, dark brown shadow tone"
- "75 degree top-down oblique perspective"
- "warm Mediterranean color palette"
- "photorealistic product render"
- "8K, studio lighting"
```

### Midjourney Tips
- Add `--ar 16:10` for board, `--ar 1:1` for checkers/dice
- Add `--style raw` for realistic product look (less "artistic")
- Add `--no text, letters, words, numbers` to avoid unwanted text on surfaces
- Use `--sref [URL]` with your first good result to keep style consistent across all prompts
- Generate at max resolution, then downscale

### Workflow
1. Generate the **board first** (Prompt 1)
2. Once you like it, use that image as a `--sref` style reference for ALL remaining prompts
3. Generate checkers, dice, cube in order
4. Generate backgrounds last

---

## PROMPT 1 — Board (Set 1: Mahogany & Olive Wood)

### Midjourney

```
Top-down oblique view of a premium handcrafted backgammon board, opened flat, 75 degree camera angle. Mahogany wood frame with visible grain and polished finish. 24 alternating triangular points in rich mahogany brown and olive-gold wood tones. Center bar with small brass hinge details and subtle diamond inlay. Recessed playing surface with olive-green felt texture. Bear-off trays on each end. Warm directional lighting from upper left, soft shadows with dark brown shadow tone. No pieces on the board, empty board only. Photorealistic product render, 8K, studio lighting, isolated on transparent background --ar 16:10 --style raw --no text, letters, words, numbers, pieces, checkers, chips
```

### Leonardo AI

```
Prompt: A premium handcrafted backgammon board photographed from above at 75 degree angle. Rich mahogany wood frame with natural grain texture, polished finish with subtle sheen. 24 alternating triangular points in mahogany brown (#A0522D) and olive wood (#9A8B3C). Center dividing bar with two small brass hinges and diamond inlay. Playing surface is recessed with olive-green felt. Bear-off collection trays at both ends. Warm lamp-like lighting from upper-left casting soft shadows. Empty board, no game pieces. Clean product photography, 8K resolution.

Negative prompt: text, letters, numbers, game pieces, checkers, chips, people, hands, low quality, blurry
```

### DALL-E 3

```
Create a photorealistic top-down product photo of an empty premium backgammon board, viewed from a 75-degree angle (almost top-down with slight perspective). The board is made of polished mahogany wood with visible grain. It has 24 alternating triangular points in two colors: rich mahogany brown and olive-gold wood. The center bar has small brass hinges. The playing surface is recessed with a subtle green felt texture. Bear-off trays at both short ends. Warm directional lighting from the upper-left creates soft shadows. No game pieces on the board. Studio product photography style, clean transparent background.
```

---

## PROMPT 2 — Board (Set 2: Mahogany & Teal)

### Midjourney

```
Top-down oblique view of a premium handcrafted backgammon board, opened flat, 75 degree camera angle. Deep reddish-brown wood frame with polished grain. 24 alternating triangular points in deep teal (#1A5C5C) and pale maple cream (#DEC8A0). Center bar with brass hinges. Recessed playing surface with dark teal-green felt. Bear-off trays on each end. Warm directional lighting from upper left, soft shadows with dark brown shadow tone. Empty board, no pieces. Photorealistic product render, 8K, studio lighting --ar 16:10 --style raw --no text, letters, words, numbers, pieces, checkers, chips
```

---

## PROMPT 3 — Board (Set 3: Dark Walnut & Navy)

### Midjourney

```
Top-down oblique view of a premium handcrafted backgammon board, opened flat, 75 degree camera angle. Dark walnut wood frame, almost black-brown, hand-polished. 24 alternating triangular points in warm copper (#B87333) and light ash wood (#C4B28E). Center bar with brass hinges. Recessed playing surface with dark navy blue felt (#2C3E50). Bear-off trays on each end. Warm directional lighting from upper left, soft shadows. Empty board, no pieces. Moody, luxurious feel. Photorealistic product render, 8K, studio lighting --ar 16:10 --style raw --no text, letters, words, numbers, pieces, checkers, chips
```

---

## PROMPT 4 — Light Checkers (Player 1 — Ivory)

### Midjourney

```
A single backgammon checker piece, warm ivory white (#F0E4C8), polished birch wood or bone material. Thick cylindrical disc shape, visible rim edge. Concentric ring groove carved into the top face. Viewed from 75 degree top-down oblique angle matching a board game perspective. Warm directional lighting from upper left, soft shadow cast to lower right on transparent background. Photorealistic product render, 8K, studio macro photography --ar 1:1 --style raw --no text, letters, words, numbers
```

> **Then generate a stack**: After getting a good single piece, run this follow-up:

```
A stack of 5 backgammon checker pieces, warm ivory white (#F0E4C8), polished birch wood. Stacked on top of each other, each piece showing its rim edge. Same cylindrical disc shape with concentric ring grooves. Viewed from 75 degree top-down oblique angle. Warm directional lighting from upper left, soft shadow on transparent background. Photorealistic product render, 8K --ar 1:1 --style raw --no text, letters, words, numbers
```

---

## PROMPT 5 — Dark Checkers (Player 2 — Ebony)

### Midjourney

```
A single backgammon checker piece, rich dark brown almost black (#2C1810), dark walnut or ebony wood. Thick cylindrical disc shape, visible rim edge. Concentric ring groove carved into top face. Viewed from 75 degree top-down oblique angle. Warm directional lighting from upper left creating subtle sheen highlights on dark surface, soft shadow to lower right on transparent background. Photorealistic product render, 8K, studio macro photography --ar 1:1 --style raw --no text, letters, words, numbers
```

> **Stack variant**:

```
A stack of 5 backgammon checker pieces, rich dark brown ebony wood (#2C1810). Stacked on top of each other showing rim edges. Cylindrical discs with concentric ring grooves. 75 degree top-down oblique angle. Warm upper-left lighting with sheen highlights on dark surface, soft shadow on transparent background. 8K product render --ar 1:1 --style raw --no text, letters, words, numbers
```

---

## PROMPT 6 — Selected Checker (Glowing)

### Midjourney

```
A single backgammon checker piece, warm ivory white, polished wood. Slightly elevated above surface as if being picked up. Golden warm glow outline surrounding the piece (#C8A94E amber gold aura). Viewed from 75 degree top-down angle. Warm directional lighting from upper left. The golden glow is soft and ethereal, like warm candlelight highlighting the selected piece. Transparent background. 8K product render --ar 1:1 --style raw --no text, letters, words, numbers
```

> Repeat with dark checker color for the dark selected variant.

---

## PROMPT 7 — Dice (Available State)

### Midjourney

```
Two classic backgammon dice side by side, warm ivory cream color (#FAF6EE), slightly rounded corners. Viewed from 75 degree top-down oblique angle showing top face, right face, and front face. Dark brown drilled pip indentations (#2C1810). Left die showing 4 pips on top, right die showing 3 pips on top. Polished bone or ivory material with subtle translucency. Warm directional lighting from upper left, soft shadows on transparent background. Photorealistic product macro photography, 8K --ar 3:2 --style raw --no text, letters, words
```

> **Individual die faces**: Generate each face value (1-6) separately:

```
A single classic die, warm ivory cream (#FAF6EE), rounded corners, showing [NUMBER] pips on the top face. Dark brown drilled circular pip indentations. 75 degree top-down oblique view showing top, right, and front faces. Polished ivory material. Warm upper-left lighting, soft shadow, transparent background. 8K macro product photo --ar 1:1 --style raw --no text, letters, words
```

> Replace `[NUMBER]` with 1, 2, 3, 4, 5, 6 for each variant.

---

## PROMPT 8 — Dice (Used State)

### Midjourney

```
A single classic die, muted tan desaturated cream color (#D4CDB8), rounded corners, faded and slightly transparent appearance at 55% opacity. Showing 3 pips on top face, faded brown pips (#8C7C60). 75 degree top-down oblique view. Dimmed lighting, less contrast than a normal die. Looks spent and inactive. Transparent background. 8K product photo --ar 1:1 --style raw --no text, letters, words
```

---

## PROMPT 9 — Doubling Cube

### Midjourney

```
A premium backgammon doubling cube, slightly larger than a standard die. Dark polished wood with engraved gold number "2" on the top face. Rounded corners, luxurious feel. 75 degree top-down oblique view showing top, right, and front faces. Warm directional lighting from upper left, gold engraving catching the light. Soft shadow on transparent background. 8K product photography --ar 1:1 --style raw --no text except the number 2
```

> Repeat with numbers 4, 8, 16, 32, 64 — change only the number in the prompt.

---

## PROMPT 10 — Table Surface / Background (Light Theme)

### Midjourney

```
Seamless tileable texture of a warm oak wood table surface, top-down view, straight overhead camera. Natural wood grain, medium golden-brown tone, polished but not glossy. Even warm lighting, no directional shadows. Clean wood surface with subtle grain variation. Texture photography, 8K, seamless pattern --ar 1:1 --tile --style raw --no objects, items, shadows, stains
```

> The `--tile` flag in Midjourney makes it seamlessly tileable.

---

## PROMPT 11 — Table Surface / Background (Dark Theme)

### Midjourney

```
Seamless tileable texture of a dark aged wood table surface, top-down view, straight overhead camera. Deep brown-black walnut wood grain (#1A1209 tone), polished satin finish. Even dim warm lighting, no directional shadows. Clean dark wood surface. Texture photography, 8K, seamless pattern --ar 1:1 --tile --style raw --no objects, items, shadows, stains
```

---

## PROMPT 12 — Bear-Off Checkers (Side Stack)

### Midjourney

```
A side view of backgammon checker pieces stacked horizontally in a wooden tray, like coins in a tray. 5 warm ivory (#F0E4C8) polished wood discs stacked flat, seen from the front. Each disc shows its circular face and thin edge. Wooden tray walls on either side. 75 degree oblique perspective consistent with a board game top-down view. Warm upper-left lighting, soft shadows. Transparent background. 8K product render --ar 2:3 --style raw --no text, letters, words, numbers
```

> Repeat with dark checker color (#2C1810).

---

## Post-Generation Processing

After generating all assets, you'll need to:

### 1. Remove Backgrounds
Use **remove.bg** (free) or **Photoshop** to cut out clean transparent backgrounds. AI generators often add surfaces/shadows you don't want.

### 2. Color Match
AI won't nail exact hex colors. Use Photoshop/GIMP **Hue/Saturation** adjustment to nudge pieces toward the target palette:
- Light checkers → `#F0E4C8`
- Dark checkers → `#2C1810`
- Dice → `#FAF6EE`

### 3. Resize to Spec
Export at the sizes listed in `3d_asset_brief.md`:
- Board: 2880 x 1800px (@3x)
- Checkers: 168 x 200px (@3x)
- Dice: 120 x 140px (@3x)

Then downscale for @2x and @1x.

### 4. Consistency Pass
Lay all assets on the board in Figma/Photoshop to verify:
- Lighting direction matches across all pieces
- Scale feels right (checker fits on point, dice proportional)
- Shadow direction is consistent
- Color palette feels cohesive

### 5. Shadow Cleanup
Ensure all shadows:
- Fall to the **lower-right** (light from upper-left)
- Are **soft** (no hard edges)
- Use dark brown tone, not pure black

---

## Quick Start Checklist

1. [ ] Sign up for **Midjourney** ($10/mo Basic plan)
2. [ ] Generate **Board Set 1** (Prompt 1) — iterate until happy
3. [ ] Save that image, use as `--sref` for all remaining prompts
4. [ ] Generate **light checker** single + stack (Prompts 4)
5. [ ] Generate **dark checker** single + stack (Prompt 5)
6. [ ] Generate **dice** faces 1-6 (Prompt 7)
7. [ ] Remove backgrounds with **remove.bg**
8. [ ] Composite in Figma to test alignment
9. [ ] Color-correct to match hex targets
10. [ ] Export at @1x, @2x, @3x into folder structure from `3d_asset_brief.md`
11. [ ] For Lottie animations, use **Jitter.video** or hire the motion designer with the brief

---

*Prompt Pack v1.0 — March 2026*
