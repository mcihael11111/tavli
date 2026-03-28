# Learn to Play Module — Complete Design Document

## Table of Contents

1. [Overview](#1-overview)
2. [Game Rules by Tradition](#2-game-rules-by-tradition)
3. [Information Architecture](#3-information-architecture)
4. [UX Design](#4-ux-design)
5. [UI Design](#5-ui-design)
6. [Implementation Plan](#6-implementation-plan)

---

## 1. Overview

### Purpose

The Learn to Play module teaches players the rules of all 11 backgammon variants across 4 cultural traditions. It replaces the current flat lesson list with a structured, tradition-aware learning system that progressively builds understanding from universal fundamentals through tradition-specific variants.

### Design Principles

- **Progressive disclosure** — teach fundamentals first, then variant-specific rules
- **Tradition-first organization** — players explore games through their chosen culture
- **Interactive over passive** — mini-board diagrams, try-it-yourself moments, and bot narration
- **Quick reference accessible** — rules always reachable mid-game via pause menu
- **Cross-tradition discovery** — encourage players to explore variants from other cultures

### Scope

- 4 traditions: Tavli (Greece), Tavla (Turkey), Nardy (Russia/Caucasus), Shesh Besh (Israel/Arab World)
- 11 game variants total
- 3 mechanic families: Hitting, Pinning, Running
- 7 universal lessons + 2–4 tradition-specific lessons per tradition

---

## 2. Game Rules by Tradition

### 2.1 Universal Fundamentals (All Variants)

These concepts apply to every backgammon variant. They form the "Foundation" module that all players complete first.

#### The Board
- 24 narrow triangles called **points**, grouped into 4 quadrants of 6
- Player's Home Board (points 1–6), Player's Outer Board (7–12), Opponent's Outer Board (13–18), Opponent's Home Board (19–24)
- A central ridge called the **bar** separates home and outer boards
- Each player has **15 checkers**

#### Dice & Movement
- Roll two dice; each die is a **separate move**
- One checker can use both dice (if the intermediate point is open), or two checkers can each use one die
- **Doubles** = 4 moves (e.g., 6-6 means four sixes)
- Can only land on **open points** (fewer than 2 opponent checkers for hitting games; or unoccupied for running/pinning games)

#### Mandatory Play Rule
- Must use **both dice** if legally possible
- If only one die can be played, must play the **larger** number
- If neither can be played, turn is forfeited
- Doubles: play as many of the four moves as possible

#### Bearing Off
- Begins when **all 15 checkers** are in your home board
- Roll the exact number matching the point, or bear off from the highest occupied point if no checker is on a higher point
- If a checker is hit during bearing off, it must re-enter first

#### Scoring
| Result | Condition | Multiplier |
|--------|-----------|------------|
| Single | Loser bore off at least 1 checker | 1× |
| Gammon | Loser bore off nothing | 2× |
| Backgammon | Loser bore off nothing AND has checker on bar or in winner's home | 3× (some variants only) |

#### The Doubling Cube (Select Variants)
- Starts at 1× (center, available to both)
- Before rolling, a player may offer to double the stakes
- Opponent accepts (game continues at 2×, acceptor owns cube) or declines (loses at current stakes)
- Only the cube owner may re-double (4×, 8×, …, 64×)
- Jacoby rule: gammon/backgammon only count if the cube has been used
- Beaver: immediately re-double after accepting a double

---

### 2.2 Tavli — Greece (Τάβλι) 🇬🇷

The Greek tradition encompasses three variants played in rotation during a traditional **Tavli Marathon** in the kafeneio. Mastering all three is considered the mark of a true tavli player.

#### Portes (Πόρτες) — "Doors"
**Family:** Hitting | **Difficulty:** Beginner

| Aspect | Detail |
|--------|--------|
| **Setup** | Standard backgammon: 2 on 24-pt, 5 on 13-pt, 3 on 8-pt, 5 on 6-pt |
| **Direction** | Players move in **opposite** directions toward their home board |
| **Core Mechanic** | **Hitting** — land on a lone opponent checker (blot) to send it to the bar |
| **Re-entry** | Hit checker must re-enter through opponent's home board before other moves |
| **Hit-and-run** | **Not allowed** — cannot hit and continue on the same die |
| **Opening roll** | Winner of the opening roll **re-rolls** both dice for their first turn |
| **Doubling cube** | Not used in traditional Greek Tavli |
| **Scoring** | Single: 1 pt · Gammon: 2 pts · No backgammon (3×) scoring |

**Key Strategies:**
- Build **πόρτες** (points/doors): 2+ checkers protect each other
- Construct **primes** (πρίμα): consecutive blocked points trap the opponent
- Anchor in opponent's home board as a safety net
- Balance between racing and blocking

**What Makes It Unique:**
- No hit-and-run distinguishes it from international backgammon — more defensive
- Winner re-rolls on first turn (rather than using the opening dice)
- No backgammon (3×) scoring simplifies stakes

---

#### Plakoto (Πλακωτό) — "Pinning"
**Family:** Pinning | **Difficulty:** Intermediate

| Aspect | Detail |
|--------|--------|
| **Setup** | All 15 checkers on your **1-point** (players start at opposite corners) |
| **Direction** | Players move in **opposite** directions |
| **Core Mechanic** | **Pinning** — land on a single opponent checker to **trap it in place** |
| **No hitting** | Checkers are never sent to the bar |
| **Blocking** | Two of your checkers (or one pinning) on a point blocks it completely |
| **Mother piece (μάνα)** | Your last checker remaining on the starting point |
| **Mother rule** | If the opponent pins your mother → you **lose immediately** (2 pts) |
| **Double mother** | If both mothers are pinned simultaneously → **draw** |
| **Scoring** | Single: 1 pt · Gammon: 2 pts · Mother pinned: 2 pts (immediate loss) |

**Key Strategies:**
- Rush your mother (μάνα) off the starting point early — it's your most vulnerable piece
- Pin opponent checkers near their home board to slow their bearing off
- Spread your checkers to control multiple points
- Two checkers on a point creates an unbreakable block

**What Makes It Unique:**
- The mother piece mechanic creates intense early-game tension
- Pinning rather than hitting creates a fundamentally different tactical feel
- No bar means no re-entry — simpler flow but deeper positional play

---

#### Fevga (Φεύγα) — "Running"
**Family:** Running | **Difficulty:** Intermediate

| Aspect | Detail |
|--------|--------|
| **Setup** | All 15 checkers on one point (players at diagonal corners) |
| **Direction** | Both players move in the **same direction** (counterclockwise) |
| **Core Mechanic** | **Blocking** — a single checker controls the entire point |
| **No hitting, no pinning** | Cannot land on any point occupied by even one opponent checker |
| **Advancement rule** | Must advance first checker past opponent's starting point before moving a second checker off your start |
| **Prime restriction** | Cannot create 6+ consecutive blocked points if all opponent checkers are trapped behind them |
| **Starting quadrant rule** | Cannot block all 6 points of your starting quadrant unless opponent has already passed through |
| **Scoring** | Single: 1 pt · Gammon: 2 pts |

**Key Strategies:**
- Spread checkers early to claim key points along the opponent's path
- Build partial primes (5 consecutive blocked points) to slow the opponent
- Race when ahead in pip count, block when behind
- The advancement rule makes your first moves critical

**What Makes It Unique:**
- Same-direction movement creates a unique "parallel race" dynamic
- A single checker is both a blocker and vulnerable to being stranded
- The advancement rule prevents turtling strategies
- Pure positional game — no captures of any kind

---

#### The Tavli Marathon
In traditional Greek play, the three variants are played **in rotation**: Portes → Plakoto → Fevga → Portes → …

- Each game awards points (1 for single, 2 for gammon/mother)
- First player to reach the target score (typically 3, 5, or 7) wins the marathon
- This is how Tavli is played in Greek kafeneia (coffeehouses)

---

### 2.3 Tavla — Turkey (Tavla) 🇹🇷

The Turkish tradition includes four variants, with Gul Bara being the most distinctive due to its cascading doubles mechanic.

#### Tavla — Standard Turkish Backgammon
**Family:** Hitting | **Difficulty:** Beginner

| Aspect | Detail |
|--------|--------|
| **Setup** | Standard backgammon (identical to Portes) |
| **Direction** | Players move in **opposite** directions |
| **Core Mechanic** | **Hitting** — send lone opponent checkers to the bar |
| **Hit-and-run** | **Not allowed** in home board |
| **Opening roll** | Winner re-rolls both dice |
| **Doubling cube** | Not traditionally used |
| **Scoring** | Single: 1 pt · Gammon (mars): 2 pts |

**What Makes It Unique:**
- Functionally identical to Greek Portes
- Turkish terminology: a gammon is called a **mars**
- Part of the broader Turkish coffee-house gaming tradition

---

#### Tapa — Turkish Pinning
**Family:** Pinning | **Difficulty:** Intermediate

| Aspect | Detail |
|--------|--------|
| **Setup** | All 15 checkers on one point (opposite corners) |
| **Direction** | Players move in **opposite** directions |
| **Core Mechanic** | **Pinning** — land on a lone opponent to trap it |
| **No mother rule** | Pinning the last checker on start is **NOT** an automatic loss |
| **Pinned release** | Pinned checker freed only when the pinning checker moves away |
| **Scoring** | Single: 1 pt · Gammon (mars): 2 pts |

**Key Strategies:**
- More defensive and patient than Plakoto since there's no mother piece pressure
- Focus on controlling key points along the opponent's path
- Pin multiple checkers to create impassable barriers
- No urgency to clear the starting point

**What Makes It Unique:**
- The absence of the mother piece rule (vs. Plakoto) creates a more relaxed, strategic game
- Players can leave their last checker on start without existential risk
- This is the key distinguishing rule between Tapa and Plakoto

---

#### Moultezim — Turkish Running
**Family:** Running | **Difficulty:** Intermediate

| Aspect | Detail |
|--------|--------|
| **Setup** | All 15 checkers on one point (diagonal corners) |
| **Direction** | Both players move in the **same direction** |
| **Core Mechanic** | Single checker blocks the entire point (no hitting) |
| **Advancement rule** | Must advance first checker past opponent's start before spreading |
| **Prime restriction** | Cannot create 6+ consecutive blocked points trapping the opponent |
| **Scoring** | Single: 1 pt · Gammon: 2 pts |

**What Makes It Unique:**
- Functionally identical to Greek Fevga
- Turkish name; same rules, same strategies
- Part of the three-game Turkish match tradition (Tavla → Tapa → Moultezim)

---

#### Gul Bara — Cascading Doubles ("Crazy Narde")
**Family:** Running | **Difficulty:** Advanced

| Aspect | Detail |
|--------|--------|
| **Setup** | All 15 checkers on one point (diagonal corners) |
| **Direction** | Both players move in the **same direction** |
| **Base Mechanic** | Same as Fevga/Moultezim — single checker blocks, no hitting |
| **Advancement rule** | Must advance first checker past opponent's start |
| **Prime restriction** | Max 5 consecutive blocked points when trapping |

**The Cascading Doubles Rule:**

This is what makes Gul Bara unique and exciting:

| Phase | Doubles Behavior |
|-------|-----------------|
| **Rolls 1–3** | Normal doubles: 4 moves of that number |
| **Roll 4+** | **Cascading:** 4 of that number + 4 of every higher number through 6 |

**Cascade Examples (after roll 3):**
- Roll **6-6**: four 6s (normal — no higher numbers)
- Roll **5-5**: four 5s + four 6s = 8 moves
- Roll **4-4**: four 4s + four 5s + four 6s = 12 moves
- Roll **3-3**: four 3s + four 4s + four 5s + four 6s = 16 moves
- Roll **2-2**: four 2s + four 3s + four 4s + four 5s + four 6s = 20 moves
- Roll **1-1**: four 1s + four 2s + four 3s + four 4s + four 5s + four 6s = **24 moves**

**Critical Rule:** If any portion of the cascade cannot be fully played (all 4 moves of that number), the cascade **ends immediately**. Remaining higher numbers are forfeited.

**Key Strategies:**
- Early game plays normally; cascading doubles in the mid/late game can be game-deciding
- Position checkers to maximize cascade utilization when doubles hit
- Block opponent's cascade paths to force early cascade termination
- The variance is extreme — a well-timed 1-1 after roll 3 can nearly bear off your entire set

**What Makes It Unique:**
- The only variant where a single roll can produce up to 24 moves
- Creates dramatic, high-variance moments that can swing the game
- The 3-roll warmup period prevents immediate cascade chaos
- Requires understanding both Fevga fundamentals AND cascade positioning

---

### 2.4 Nardy — Russia & Caucasus (Нарды) 🇷🇺

The Russian/Caucasian tradition features two variants: a distinctive running game with the "head rule" and a version of standard backgammon with the full doubling cube.

#### Long Nard (Длинные нарды) — The Head Rule
**Family:** Running | **Difficulty:** Intermediate

| Aspect | Detail |
|--------|--------|
| **Setup** | All 15 checkers on the "head" point (diagonal corners) |
| **Direction** | Both players move in the **same direction** (counterclockwise) |
| **Core Mechanic** | Single checker blocks the point (no hitting) |
| **Head rule** | Only **ONE** checker may leave the head per turn |
| **Head exception** | First turn only: 3-3, 4-4, or 6-6 allows **two** off the head |
| **Larger die rule** | If only one die can be played, the **larger** die must be used |
| **Prime restriction** | Cannot build a 6-prime trapping all opponent checkers |
| **Opening roll** | Winner does NOT re-roll (uses the opening dice directly) |
| **Scoring** | Oyn (single): 1 pt · Mars (gammon): 2 pts |

**Key Strategies:**
- The head rule makes opening moves critical — you can only deploy one checker per turn
- Spread early to claim key points before the opponent does
- Build partial primes (up to 5 consecutive) to restrict opponent movement
- The first-turn exception for 3-3/4-4/6-6 gives a significant development advantage
- Endgame: the head rule stops mattering once all checkers have left

**What Makes It Unique:**
- The head rule creates a unique "slow deployment" dynamic not found in any other variant
- Combined with same-direction movement, it creates a careful, strategic game
- The specific double exceptions (3-3, 4-4, 6-6) are unique to Long Nard
- Extremely popular across Russia, the Caucasus, Central Asia, and Iran

---

#### Short Nard (Короткие нарды) — Competitive Backgammon
**Family:** Hitting | **Difficulty:** Advanced

| Aspect | Detail |
|--------|--------|
| **Setup** | Standard backgammon (2-5-3-5 placement) |
| **Direction** | Players move in **opposite** directions |
| **Core Mechanic** | **Hitting** — standard backgammon captures |
| **Hit-and-run** | **Allowed** (unlike Portes/Tavla) |
| **Doubling cube** | **Yes** — full doubling cube with Jacoby and Beaver rules |
| **Jacoby rule** | Gammon/backgammon only count if the cube has been used |
| **Beaver** | Immediately re-double after accepting a double (retaining cube ownership) |
| **Backgammon scoring** | **Yes** — 3× when loser has checker on bar or in winner's home |
| **Opening roll** | Winner does NOT re-roll |
| **Scoring** | Single: 1 pt · Gammon: 2 pts · Backgammon: 3 pts · All × cube value |

**Key Strategies:**
- Cube management is the defining skill — knowing when to double and when to accept
- Accept a double if you estimate ≥25% winning chances
- The Jacoby rule incentivizes doubling (otherwise gammons don't count)
- Hit-and-run allows more aggressive hitting in the home board
- Backgammon (3×) scoring rewards trapping opponent checkers deep

**What Makes It Unique:**
- The most strategically complex variant due to the doubling cube
- Closest to international tournament backgammon (USBGF/WBF rules)
- Hit-and-run + doubling cube + backgammon scoring = maximum tactical depth
- Beaver rule adds an extra layer of bluffing and counter-play

---

### 2.5 Shesh Besh — Israel & Arab World (שש בש) 🇮🇱

The Levantine tradition features an aggressive hitting variant and an Arabic pinning game.

#### Shesh Besh (שש בש) — Hit and Run
**Family:** Hitting | **Difficulty:** Beginner

| Aspect | Detail |
|--------|--------|
| **Setup** | Standard backgammon (2-5-3-5 placement) |
| **Direction** | Players move in **opposite** directions |
| **Core Mechanic** | **Hitting** — send lone checkers to the bar |
| **Hit-and-run** | **Allowed** — hit a blot and continue moving past on the same die |
| **Opening roll** | Winner re-rolls both dice |
| **Doubling cube** | Not traditionally used |
| **Scoring** | Single: 1 pt · Gammon: 2 pts |

**Key Strategies:**
- Hit-and-run allows aggressive play — hit a blot and immediately advance
- This makes blocking more important (since hits are easier to execute)
- Fast-paced gameplay rewards tactical awareness
- Don't leave blots in areas the opponent can hit-and-run through

**What Makes It Unique:**
- Hit-and-run is the defining rule — makes gameplay faster and more aggressive than Portes/Tavla
- The name "Shesh Besh" means "six-five" in Hebrew/Turkish (the best opening roll)
- The most popular backgammon variant in Israel and across the Arab world

---

#### Mahbusa (محبوسة) — "Imprisoned"
**Family:** Pinning | **Difficulty:** Intermediate

| Aspect | Detail |
|--------|--------|
| **Setup** | All 15 checkers on one point (opposite corners) |
| **Direction** | Players move in **opposite** directions |
| **Core Mechanic** | **Pinning** — land on a lone opponent to trap it |
| **Mother piece rule** | **Yes** — pinning opponent's last checker on start = immediate loss (2 pts) |
| **Double mother** | Both mothers pinned simultaneously = **draw** |
| **Scoring** | Single: 1 pt · Gammon: 2 pts · Mother pinned: 2 pts |

**Key Strategies:**
- Same as Plakoto — rush your mother off start, pin opponents near their home
- The name "Mahbusa" (محبوسة) literally means "imprisoned"
- Arabic backgammon tradition, played widely across the Levant and North Africa

**What Makes It Unique:**
- Functionally identical to Greek Plakoto (including the mother piece rule)
- Arabic terminology and cultural context
- Part of the broader Shesh Besh family of games

---

### 2.6 Cross-Tradition Variant Comparison

#### Hitting Games
| Rule | Portes | Tavla | Short Nard | Shesh Besh |
|------|--------|-------|------------|------------|
| Hit-and-run | No | No | Yes | Yes |
| Winner re-rolls | Yes | Yes | No | Yes |
| Doubling cube | No | No | Yes | No |
| Backgammon (3×) | No | No | Yes | No |
| Jacoby rule | — | — | Yes | — |

#### Pinning Games
| Rule | Plakoto | Tapa | Mahbusa |
|------|---------|------|---------|
| Mother piece rule | Yes | **No** | Yes |
| Mother = auto-loss | 2 pts | — | 2 pts |
| Both mothers pinned | Draw | — | Draw |

#### Running Games
| Rule | Fevga | Moultezim | Long Nard | Gul Bara |
|------|-------|-----------|-----------|----------|
| Head rule | No | No | **Yes** | No |
| Head exception doubles | — | — | 3-3, 4-4, 6-6 | — |
| Cascading doubles | No | No | No | **Yes** |
| Cascade starts after | — | — | — | Roll 3 |
| Advancement rule | Yes | Yes | No (head rule instead) | Yes |
| Max prime (trapping) | 5 | 5 | 5 | 5 |

---

## 3. Information Architecture

### 3.1 Content Hierarchy

```
Learn to Play
├── Foundations (universal — always first)
│   ├── The Board — 24 points, 4 quadrants, the bar
│   ├── Moving Checkers — dice, open points, doubles, mandatory play
│   ├── Hitting & The Bar — blots, hitting, re-entry (hitting games context)
│   ├── Bearing Off — home board, exact rolls, highest point rule
│   ├── Strategy Basics — points, primes, anchors, pip counting
│   └── The Doubling Cube — stakes, accepting/declining, ownership
│
├── Your Tradition (player's selected tradition, shown prominently)
│   ├── [Variant 1] — full lesson with rules, diagrams, strategy
│   ├── [Variant 2] — full lesson
│   ├── [Variant 3] — full lesson (if applicable)
│   ├── [Variant 4] — full lesson (if applicable, e.g. Gul Bara)
│   └── [Marathon/Match Play] — tradition-specific match format
│
├── Explore Other Traditions (expandable sections)
│   ├── Tavli (Greece) — 3 variants
│   ├── Tavla (Turkey) — 4 variants
│   ├── Nardy (Russia & Caucasus) — 2 variants
│   └── Shesh Besh (Israel & Arab World) — 2 variants
│
└── Mechanic Deep Dives (optional, cross-cutting)
    ├── Hitting — compare Portes vs Tavla vs Short Nard vs Shesh Besh
    ├── Pinning — compare Plakoto vs Tapa vs Mahbusa
    └── Running — compare Fevga vs Moultezim vs Long Nard vs Gul Bara
```

### 3.2 Entry Points

The Learn to Play module is accessible from:

1. **Home screen** — "Learn to Play" card in the main content area
2. **Onboarding** — final screen offers "Start Tutorial" before first game
3. **Variant intro sheet** — "Show me a tutorial first" button (first time selecting a variant)
4. **Pause menu** — "Rules" button opens the quick-reference sheet (existing `VariantRulesSheet`)
5. **Settings** — "Learn to Play" link in the Help & Info section

### 3.3 Content Progression Model

```
 FOUNDATION          TRADITION            DISCOVERY
┌─────────────┐    ┌──────────────┐    ┌──────────────────┐
│ Universal    │ →  │ Your         │ →  │ Other Traditions  │
│ Lessons 1-6 │    │ Tradition's  │    │ & Mechanic        │
│ (required)   │    │ Variants     │    │ Deep Dives        │
│              │    │ (recommended)│    │ (optional)        │
└─────────────┘    └──────────────┘    └──────────────────┘
```

**Progress Tracking:**
- Foundation lessons: linear, sequential (must complete in order)
- Tradition variants: unlocked after Foundation, any order
- Other traditions: always accessible, no prerequisites
- Mechanic deep dives: unlocked after completing at least one variant from each family

### 3.4 Lesson Structure (Per Lesson)

Each lesson follows a consistent structure:

1. **Header** — Variant name (English + native script), mechanic family badge, tradition flag
2. **Bot Introduction** — Tradition-specific bot narrates in character (1-2 sentences)
3. **Visual Diagram** — Mini-board showing the concept (interactive where possible)
4. **Rules Section** — Structured as Setup → Core Mechanic → Special Rules → Scoring
5. **Strategy Tips** — 3-4 actionable tips
6. **"What Makes It Unique"** — 2-3 sentences comparing to similar variants
7. **Try It** — Optional interactive mini-exercise (future enhancement)

---

## 4. UX Design

### 4.1 User Flows

#### Flow 1: First-Time Player (from Onboarding)
```
Onboarding → "Start Tutorial" → Foundation Lessons (1-6)
  → "Continue to [Tradition] variants" → Tradition Lessons
  → "Start Playing!" → Home Screen
```

#### Flow 2: Returning Player (from Home)
```
Home → "Learn to Play" card → Learn Hub Screen
  → Resume where left off / Browse by tradition
  → Select lesson → Lesson Detail
  → Back to Hub / Next Lesson
```

#### Flow 3: Mid-Game Quick Reference
```
Game → Pause → "Rules" → Variant Rules Sheet (existing)
  → "Full Tutorial" link → Opens Learn Hub at that variant
```

#### Flow 4: First Variant Selection
```
Difficulty Screen → Select new variant → Variant Intro Sheet
  → "Show me a tutorial first" → Opens Learn Hub at that variant's lesson
  → OR "Got it, let's play!" → Game Screen
```

#### Flow 5: Cross-Tradition Discovery
```
Learn Hub → "Explore Other Traditions" → Tradition Section
  → Select variant → Lesson Detail
  → "Try This Variant" → Difficulty Screen (pre-selected variant)
```

### 4.2 Navigation Model

The Learn Hub uses a **hub-and-spoke** model:

- **Hub:** Learn Hub Screen — shows progress, tradition sections, quick-access
- **Spoke:** Lesson Detail Screen — individual lesson content with prev/next navigation

Navigation within lessons:
- **Swipe left/right** or tap Next/Previous to move between lessons within a section
- **Back button** returns to the Learn Hub
- **Progress bar** at top shows position within current section

### 4.3 Progress & Completion

**Per-lesson tracking:**
- `not_started` → `in_progress` → `completed`
- Stored in SharedPreferences: `learn_lesson_{sectionId}_{lessonIndex}`

**Per-section tracking:**
- Foundation: X/6 completed (linear progress bar)
- Tradition: X/N completed per tradition (circular progress)
- Overall: percentage badge on Home screen card

**Completion rewards:**
- Completing Foundation → unlocks "Fundamentals Master" badge on profile
- Completing all variants in a tradition → unlocks tradition-specific badge
- Completing all 11 variants → unlocks "Scholar of Tables" badge

### 4.4 Bot Narration

Each lesson is narrated by the player's selected bot personality:

- **Tavli:** Mikhail, Uncle Spyros, etc. — warm Greek kafeneio tone
- **Tavla:** Mehmet Abi, etc. — Turkish tea-house hospitality
- **Nardy:** Babushka Vera, etc. — Russian/Caucasian warmth
- **Shesh Besh:** Abu Yusuf, etc. — Levantine storytelling

When viewing OTHER traditions' lessons, the narration switches to that tradition's default bot personality — giving the player a taste of the cultural flavor.

### 4.5 Accessibility

- All diagrams have text descriptions (screen reader)
- Minimum 48×48dp touch targets on all navigation
- Content supports 200% text scaling
- Progress states communicated through icons + text (never color alone)
- Bot dialogue marked as quote regions for screen readers

---

## 5. UI Design

### 5.1 Learn Hub Screen

**Layout:** GradientScaffold with scrollable content

```
┌──────────────────────────────────┐
│  ← Learn to Play           ⋮    │  ← Transparent AppBar, light text
├──────────────────────────────────┤
│                                  │
│  ┌────────────────────────────┐  │
│  │ 📊 Your Progress           │  │  ← ContentModule (translucent)
│  │ ████████░░░░ 58%           │  │     Progress bar + percentage
│  │ 7 of 12 lessons complete   │  │
│  └────────────────────────────┘  │
│                                  │
│  FOUNDATIONS                     │  ← Section header (titleSmall, primary)
│  ┌────────────────────────────┐  │
│  │ ✓ The Board                │  │  ← Standard List Item cards
│  ├────────────────────────────┤  │     Completed = checkmark + muted
│  │ ✓ Moving Checkers          │  │     In-progress = dot indicator
│  ├────────────────────────────┤  │     Locked = lock icon
│  │ ● Hitting & The Bar        │  │
│  ├────────────────────────────┤  │
│  │ 🔒 Bearing Off             │  │
│  ├────────────────────────────┤  │
│  │ 🔒 Strategy Basics         │  │
│  ├────────────────────────────┤  │
│  │ 🔒 The Doubling Cube       │  │
│  └────────────────────────────┘  │
│                                  │
│  YOUR TRADITION — TAVLI 🇬🇷      │  ← Section header
│  ┌────────────────────────────┐  │
│  │ 🎯 Portes (Πόρτες)        │  │  ← Variant cards with mechanic icon
│  │    Hitting Game             │  │     Subtitle = mechanic family
│  ├────────────────────────────┤  │
│  │ 📌 Plakoto (Πλακωτό)      │  │
│  │    Pinning Game             │  │
│  ├────────────────────────────┤  │
│  │ 🏃 Fevga (Φεύγα)          │  │
│  │    Running Game             │  │
│  ├────────────────────────────┤  │
│  │ 🏆 The Tavli Marathon      │  │
│  │    Match Play               │  │
│  └────────────────────────────┘  │
│                                  │
│  EXPLORE OTHER TRADITIONS        │  ← Section header
│  ┌────────────────────────────┐  │
│  │ 🇹🇷 Tavla — Turkey          │  │  ← Expandable tradition cards
│  │    4 variants • 0 complete  │  │     Tap to expand variant list
│  ├────────────────────────────┤  │
│  │ 🇷🇺 Nardy — Russia          │  │
│  │    2 variants • 0 complete  │  │
│  ├────────────────────────────┤  │
│  │ 🇮🇱 Shesh Besh — Israel     │  │
│  │    2 variants • 0 complete  │  │
│  └────────────────────────────┘  │
│                                  │
│  MECHANIC DEEP DIVES        🔒  │  ← Locked until prerequisite met
│  ┌────────────────────────────┐  │
│  │ Complete at least one       │  │
│  │ variant from each family    │  │
│  │ to unlock comparisons.      │  │
│  └────────────────────────────┘  │
│                                  │
└──────────────────────────────────┘
```

### 5.2 Lesson Detail Screen

**Layout:** GradientScaffold, scrollable body, fixed bottom navigation

```
┌──────────────────────────────────┐
│  ← Back         3 / 9       ⋮   │  ← AppBar with lesson counter
├──────────────────────────────────┤
│ ████████████░░░░░░░░░░░░░░░░░░░ │  ← Thin progress bar (3px)
│                                  │
│  ┌─ Icon ─┐                      │
│  │  ⚔️    │  Portes (Πόρτες)    │  ← Icon circle + title (serif 22px)
│  └────────┘  Hitting Game        │     Subtitle = mechanic family
│                                  │
│  ┌────────────────────────────┐  │
│  │ 🧑 "Welcome to Portes!     │  │  ← Bot dialogue (primary bg, light text)
│  │     This is the classic     │  │     Avatar initial + italic text
│  │     Greek backgammon..."    │  │
│  └────────────────────────────┘  │
│                                  │
│  ┌────────────────────────────┐  │
│  │                            │  │  ← Mini-board diagram (200px height)
│  │    [Board Visualization]   │  │     Shows relevant concept
│  │                            │  │     Highlighted points + arrows
│  └────────────────────────────┘  │
│                                  │
│  Setup                           │  ← Section header (serif 16px)
│  • Standard backgammon: 2 on    │  ← Bullet points (14px, 1.4 height)
│    24-pt, 5 on 13-pt...         │
│  • Players move in opposite     │
│    directions                    │
│                                  │
│  Core Mechanic                   │
│  • Hit lone opponent checkers    │
│    to send them to the bar       │
│  • Hit checkers must re-enter    │
│    through opponent's home board │
│                                  │
│  Special Rules                   │
│  • Winner of opening roll        │
│    re-rolls both dice            │
│  • No backgammon (3×) scoring    │
│                                  │
│  Scoring                         │
│  • Single win: 1 point           │
│  • Gammon: 2 points              │
│                                  │
│  Strategy Tips                   │
│  • Build πόρτες — 2+ checkers    │
│    protect each other            │
│  • Construct primes to trap...   │
│                                  │
├──────────────────────────────────┤
│  ┌──────────┐  ┌────────────────┐│  ← Fixed bottom nav
│  │ Previous │  │     Next       ││     Previous (outlined) + Next (filled)
│  └──────────┘  └────────────────┘│     Last lesson: "Start Playing!"
└──────────────────────────────────┘
```

### 5.3 Mechanic Deep Dive Screen

**Layout:** Comparison table format within ContentModule

```
┌──────────────────────────────────┐
│  ← Hitting Games Compared       │
├──────────────────────────────────┤
│                                  │
│  ┌────────────────────────────┐  │
│  │ Comparing 4 hitting games  │  │  ← ContentModule intro
│  │ across traditions          │  │
│  └────────────────────────────┘  │
│                                  │
│  ┌────────────────────────────┐  │
│  │ Hit-and-run                │  │  ← Comparison rows
│  │ Portes: ✗  Tavla: ✗       │  │     Each rule as a card
│  │ Short Nard: ✓  Shesh: ✓   │  │     Check/cross per variant
│  ├────────────────────────────┤  │
│  │ Doubling Cube              │  │
│  │ Portes: ✗  Tavla: ✗       │  │
│  │ Short Nard: ✓  Shesh: ✗   │  │
│  ├────────────────────────────┤  │
│  │ Winner Re-rolls            │  │
│  │ Portes: ✓  Tavla: ✓       │  │
│  │ Short Nard: ✗  Shesh: ✓   │  │
│  └────────────────────────────┘  │
│                                  │
└──────────────────────────────────┘
```

### 5.4 Component Tokens (from Design System)

| Element | Token | Value |
|---------|-------|-------|
| Screen background | `GradientScaffold` | `warmScaffold` gradient |
| Section card | `ContentModule` | 12% alpha fill, 40% alpha border, `lg` radius |
| List item card | Standard card | `primary` bg, `light` text, `lg` radius, 10px gap |
| Lesson title | `headlineMedium` | Serif 22px w600, `light` on gradient |
| Section header | `titleSmall` | Sans 14px w500, `primary` color, sentence case |
| Body text | `bodyLarge` | Sans 15px w400, `light` on gradient, 1.55 line height |
| Bot dialogue bg | — | `primary` solid fill, `lg` radius |
| Bot dialogue text | `bodyMedium` | Sans 14px italic, `light` color, 1.4 height |
| Progress bar bg | — | `primary` at 30% alpha |
| Progress bar fill | — | `light` solid |
| Navigation buttons | Filled + Outlined | Per `02_COMPONENTS.md` button specs |
| Diagram border | — | `primary` at 30% alpha, `sm` radius |

### 5.5 Animations & Transitions

| Transition | Duration | Curve |
|------------|----------|-------|
| Lesson enter (from hub) | 300ms | `easeInOut` (slide from right) |
| Lesson exit (to hub) | 300ms | `easeInOut` (slide to right) |
| Next/Prev lesson | 250ms | `easeInOut` (crossfade + slight slide) |
| Progress bar fill | 200ms | `easeOut` |
| Section expand/collapse | 200ms | `easeInOut` |
| Completion checkmark | 150ms | `bounceOut` (scale 0 → 1) |

---

## 6. Implementation Plan

### 6.1 File Structure

```
lib/features/learn/
├── data/
│   ├── models/
│   │   ├── lesson.dart              # Lesson data model
│   │   ├── lesson_section.dart      # Section grouping (Foundation, Tradition, etc.)
│   │   └── lesson_progress.dart     # Per-lesson completion state
│   └── repositories/
│       └── learn_progress_repository.dart  # SharedPreferences persistence
│
├── domain/
│   ├── learn_content.dart           # All lesson content (rules, bot text, diagrams)
│   ├── foundation_lessons.dart      # 6 universal lessons
│   ├── tradition_lessons.dart       # Per-tradition variant lessons + marathon
│   └── mechanic_comparisons.dart    # Cross-tradition comparison data
│
├── presentation/
│   ├── screens/
│   │   ├── learn_hub_screen.dart    # Main hub with sections and progress
│   │   ├── lesson_detail_screen.dart # Individual lesson viewer
│   │   └── mechanic_comparison_screen.dart # Deep dive comparison
│   ├── widgets/
│   │   ├── progress_overview_card.dart  # Overall progress ContentModule
│   │   ├── lesson_list_item.dart        # Card with status icon
│   │   ├── tradition_section.dart       # Expandable tradition group
│   │   ├── bot_dialogue_box.dart        # Bot avatar + italic text card
│   │   ├── rule_section.dart            # Header + bullet points
│   │   ├── comparison_table.dart        # Check/cross grid for deep dives
│   │   └── lesson_nav_bar.dart          # Fixed bottom prev/next
│   └── providers/
│       └── learn_providers.dart     # Riverpod providers for progress state
│
└── learn.dart                       # Feature barrel export
```

### 6.2 Phase Breakdown

#### Phase 1: Data Layer & Content (Est. foundation)

**Goal:** Define all lesson content and progress persistence.

**Tasks:**
1. Create `Lesson` model with fields: `id`, `title`, `nativeTitle`, `sectionId`, `mechanicFamily`, `tradition`, `icon`, `botDialogue`, `diagram`, `rules` (setup, coreMechanic, specialRules, scoring), `strategyTips`, `uniquePoints`
2. Create `LessonSection` model: `id`, `title`, `type` (foundation/tradition/discovery/deepDive), `lessons`, `prerequisite`
3. Create `LessonProgress` model: `lessonId`, `status` (notStarted/inProgress/completed), `completedAt`
4. Create `LearnProgressRepository` — CRUD operations on SharedPreferences
5. Migrate content from existing `TutorialScreen._baseLessons` and `_traditionSpecificLessons` into new content files
6. Add all 11 variant lessons with full rule content (from Section 2 of this document)
7. Add 4 marathon/match-play lessons (one per tradition)
8. Add 3 mechanic comparison datasets (hitting, pinning, running)

**Key Decisions:**
- Content is defined as Dart constants (not JSON/YAML) for type safety and tree-shaking
- MiniBoardPainter diagrams are created per-lesson where applicable
- Bot dialogue uses the player's active personality (or tradition default for cross-tradition)

#### Phase 2: Learn Hub Screen

**Goal:** Build the main hub with sections, progress tracking, and navigation.

**Tasks:**
1. Create `learn_providers.dart` with:
   - `learnProgressProvider` — reads/writes progress from repository
   - `learnSectionsProvider` — builds section list based on player's tradition
   - `overallProgressProvider` — computed percentage
2. Create `LearnHubScreen` with GradientScaffold
3. Build `ProgressOverviewCard` (ContentModule with progress bar and percentage)
4. Build `LessonListItem` (standard card with status icon: checkmark/dot/lock)
5. Build `TraditionSection` (expandable card showing tradition flag, name, variant count, progress)
6. Wire up lesson tap → navigate to `LessonDetailScreen`
7. Add route to `router.dart`: `/learn` → `LearnHubScreen`
8. Add "Learn to Play" card to Home screen

#### Phase 3: Lesson Detail Screen

**Goal:** Build the lesson viewer with content rendering and navigation.

**Tasks:**
1. Create `LessonDetailScreen` accepting `sectionId` and `lessonIndex` as route params
2. Build `BotDialogueBox` widget (extracted from existing `TutorialScreen` pattern)
3. Build `RuleSection` widget (header + bullet points, matching `VariantRulesSheet` style)
4. Build `LessonNavBar` (fixed bottom with Previous/Next)
5. Integrate `MiniBoardPainter` diagrams
6. Add progress tracking: mark lesson `completed` on reaching the last section or tapping "Next" on final lesson
7. Add swipe gesture for prev/next navigation
8. Add page transition animations (slide + crossfade, 250ms)

#### Phase 4: Integration & Migration

**Goal:** Connect all entry points and migrate from the old tutorial.

**Tasks:**
1. Update onboarding screen's "Start Tutorial" button to route to `/learn` (Foundation section)
2. Update `VariantIntroSheet`'s "Show me a tutorial first" to route to the specific variant lesson in `/learn`
3. Add "Full Tutorial" link in `VariantRulesSheet` that deep-links to the variant's lesson
4. Add "Learn to Play" item in Settings → Help & Info
5. Update `TutorialScreen` to redirect to new Learn Hub (backward compatibility)
6. Add route params for deep-linking: `/learn?section=tavli&lesson=plakoto`

#### Phase 5: Mechanic Deep Dives & Polish

**Goal:** Add comparison screens and polish the experience.

**Tasks:**
1. Create `MechanicComparisonScreen` with comparison table layout
2. Build `ComparisonTable` widget (check/cross grid)
3. Unlock logic: track which mechanic families the player has completed at least one variant from
4. Add completion badges to profile (Fundamentals Master, tradition badges, Scholar of Tables)
5. Add shimmer loading states for progress data
6. Accessibility pass: semantic labels, screen reader testing, 200% text scaling
7. Localization: add all new strings to `app_localizations`

#### Phase 6: Testing

**Tasks:**
1. Unit tests for `LearnProgressRepository` (read/write/reset)
2. Unit tests for lesson content completeness (all 11 variants have all required fields)
3. Widget tests for `LearnHubScreen`, `LessonDetailScreen`, `BotDialogueBox`
4. Integration test: full flow from onboarding → Foundation → tradition lessons → completion
5. Golden tests for key screens at different screen sizes
6. Accessibility audit: contrast ratios, touch targets, screen reader flow

### 6.3 Router Changes

```dart
// New routes to add to router.dart
GoRoute(
  path: '/learn',
  builder: (context, state) {
    final section = state.uri.queryParameters['section'];
    final lesson = state.uri.queryParameters['lesson'];
    return LearnHubScreen(
      initialSection: section,
      initialLesson: lesson,
    );
  },
),
GoRoute(
  path: '/learn/lesson',
  builder: (context, state) {
    final sectionId = state.uri.queryParameters['section']!;
    final index = int.parse(state.uri.queryParameters['index'] ?? '0');
    return LessonDetailScreen(
      sectionId: sectionId,
      lessonIndex: index,
    );
  },
),
GoRoute(
  path: '/learn/compare',
  builder: (context, state) {
    final family = state.uri.queryParameters['family']!;
    return MechanicComparisonScreen(family: family);
  },
),
```

### 6.4 Data Model Sketch

```dart
class Lesson {
  final String id;
  final String title;
  final String? nativeTitle;
  final String sectionId;
  final MechanicFamily? mechanicFamily;
  final Tradition? tradition;
  final GameVariant? variant;
  final IconData icon;
  final String botDialogue;
  final MiniBoardPainter? diagram;
  final String? setup;
  final List<String> coreMechanic;
  final List<String> specialRules;
  final List<String> scoring;
  final List<String> strategyTips;
  final List<String> uniquePoints;
}

class LessonSection {
  final String id;
  final String title;
  final LessonSectionType type;
  final List<Lesson> lessons;
  final String? prerequisiteSectionId;
}

enum LessonSectionType { foundation, tradition, discovery, deepDive }

class LessonProgress {
  final String lessonId;
  final LessonStatus status;
  final DateTime? completedAt;
}

enum LessonStatus { notStarted, inProgress, completed }
```

### 6.5 Migration Notes

- The existing `TutorialScreen` content should be preserved as a fallback during migration
- `VariantRulesSheet` remains unchanged (in-game quick reference, separate purpose)
- `VariantIntroSheet` remains unchanged (first-variant-selection prompt)
- SharedPreferences keys: new prefix `learn_` to avoid collision with existing `variant_intro_seen_` keys
- Old tutorial progress (`tutorial_completed` key) should auto-complete Foundation section for returning players

### 6.6 Dependencies

- No new packages required
- Uses existing: `go_router`, `flutter_riverpod`, `shared_preferences`
- Uses existing widgets: `GradientScaffold`, `ContentModule`, `MiniBoardPainter`
