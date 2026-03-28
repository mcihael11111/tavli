# Multi-Variant Backgammon Strategy

## Executive Summary

Tavli already supports 10 game variants across 4 cultural traditions (Greek Tavli, Turkish Tavla, Russian Nardy, Israeli Shesh Besh). This plan transforms that technical foundation into a **cultural-first product** that makes every backgammon player worldwide feel at home, while using the variant system as a key differentiator and engagement driver.

**Core thesis:** No competitor does multi-variant backgammon well on mobile. The market is split between serious-player apps (Galaxy, XG) that only offer standard backgammon, social-casino apps (Backgammon Live) that don't offer variants, and niche cultural apps (iTavli, Tavla Plus) with dated UIs and weak AI for non-standard variants. Tavli can own the "play your culture's game, beautifully" space.

---

## Part 1: Research Findings

### 1.1 Variant Landscape

There are three core **mechanic families** (already implemented in the engine):

| Mechanic | How It Works | Variants |
|----------|-------------|----------|
| **Hitting** | Land on a single opponent checker to send it to the bar; must re-enter | Portes, Tavla, Short Nard, Shesh Besh, Acey-Deucey |
| **Pinning** | Land on a single opponent checker to trap it in place | Plakoto, Tapa, Mahbusa |
| **Running/Blocking** | Single checker controls a point; no capturing at all | Fevga, Moultezim, Long Nard |

### 1.2 Variants by Culture

#### Greek Tavli (Tavli triptych)
| Variant | Start | Direction | Mechanic | Special Rules |
|---------|-------|-----------|----------|---------------|
| **Portes** | Standard BG setup | Opposing | Hitting | Winner re-rolls opening; no backgammon scoring; no hit-and-run in home board |
| **Plakoto** | All 15 on pts 1/24 | Opposing | Pinning | **Mother piece (mana):** if your last checker on the starting point is pinned, you lose immediately (2 pts). Both pinned = draw |
| **Fevga** | All 15 on diagonal corners | Same (CCW) | Running | Must advance first checker past opponent's start before moving a second; max 5-prime when trapping all opponent checkers |

**Tradition:** Played as a rotating match (Portes -> Plakoto -> Fevga) to target score (3, 5, or 7). Shared dice. No doubling cube.

#### Turkish Tavla
| Variant | Start | Direction | Mechanic | Special Rules |
|---------|-------|-----------|----------|---------------|
| **Tavla** | Standard BG setup | Opposing | Hitting | Same as Portes (winner re-rolls, no hit-and-run) |
| **Tapa** | All 15 on opp 1-pt | Opposing | Pinning | Same as Plakoto but **no mother piece rule** |
| **Moultezim** | All 15 diagonal | Same (CCW) | Running | Same as Fevga |

**Tradition:** Played as a rotating match (Tavla -> Tapa -> Moultezim) or sometimes (Tavla -> Gul Bara -> Tapa).

#### Russian/Caucasian Nardy
| Variant | Start | Direction | Mechanic | Special Rules |
|---------|-------|-----------|----------|---------------|
| **Long Nard (Narde)** | All 15 diagonal | Same (CCW) | Running | **Head rule:** only 1 checker off start per turn (exceptions: first turn with 6-6, 4-4, or 3-3 allows 2). Higher die must be played if only one fits |
| **Short Nard** | Standard BG setup | Opposing | Hitting | **Doubling cube** + Jacoby rule + beaver. Full backgammon (3x) scoring. Closest to Western competitive backgammon |

**Tradition:** Long Nard is the cultural favorite, especially in Caucasus. Short Nard is the competitive/international variant.

#### Israeli Shesh Besh
| Variant | Start | Direction | Mechanic | Special Rules |
|---------|-------|-----------|----------|---------------|
| **Shesh Besh** | Standard BG setup | Opposing | Hitting | **Allows hit-and-run** (can hit and continue past). Otherwise standard |
| **Mahbusa** | All 15 on opp 1-pt | Opposing | Pinning | Same as Plakoto (with mother piece rule) |

### 1.3 Potential Future Variants (Not Yet Implemented)

| Variant | Origin | Mechanic | Notable Feature | Priority |
|---------|--------|----------|-----------------|----------|
| **Acey-Deucey (American)** | USA/Navy | Hitting | All 15 start off-board; rolling 1-2 = choose any doubles + re-roll | Medium |
| **Acey-Deucey (Greek/Asse-Dio)** | Greece | Hitting | Can nominate own blot to be hit | Low |
| **Gul Bara (Crazy Narde)** | Turkey/Azerbaijan | Running | Cascading doubles: rolling doubles triggers all successive doubles through 6-6 | Medium |
| **Nackgammon** | International | Hitting | Different starting position (2 extra on 23-pt); higher skill ceiling | Low |
| **Hypergammon** | International | Hitting | Only 3 checkers each; fully solved game | Low (novelty) |
| **Misere** | International | Hitting | Reverse objective: first to bear off loses | Low (novelty) |

### 1.4 Competitive Landscape

| App | Variants | Strength | Weakness |
|-----|----------|----------|----------|
| **Backgammon Galaxy** | Standard only | Best analysis engine, serious players | No variants, no cultural appeal |
| **Backgammon Live** | Standard only | 10M+ downloads, social features | Casino monetization, no variants |
| **XG Mobile** | Standard only | Gold-standard AI | Dated UI, niche audience |
| **iTavli** | Portes/Plakoto/Fevga | Has the Greek triptych | Dated UI, weak AI for non-Portes, tiny multiplayer pool |
| **Tavla Plus** | Tavla (+ sometimes Moultezim) | Turkish cultural authenticity | Turkish-only, limited variants |
| **Backgammon NJ** | Standard + Narde + Tavla | Multi-variant | Functional but ugly, empty lobbies for non-standard |

**Key insight:** Nobody does multi-variant well with modern UI + strong AI + cultural localization. This is the gap.

### 1.5 Cultural Demographics

| Region | Est. Active Players | Preferred Variants | Key Insight |
|--------|--------------------|--------------------|-------------|
| **Turkey** | 5-10M | Tavla, Moultezim, Tapa | Largest single national market |
| **Greece** | 2-3M | Portes, Plakoto, Fevga | Highest per-capita engagement; tavli in kafeneia is a lifestyle |
| **Iran** | 3-5M | Takhteh Nard (standard) | Huge market but app store restrictions |
| **Russia/Caucasus** | 3-5M | Long Nard, Short Nard | Long Nard is the cultural favorite |
| **Middle East** | 5-10M (combined) | Tawla (standard), Mahbusa | Social play emphasis |
| **Israel** | ~1M | Shesh Besh, Mahbusa | Hit-and-run variant is distinctive |
| **Bulgaria** | 500K-1M | Tabla, Tapa, Gul Bara | Three-game rotation like Greece |
| **USA/West** | 1-2M online | Standard backgammon | Low variant awareness; discovery opportunity |

**Total addressable market:** ~50-100M occasional players globally, 10-20M regular online players.

### 1.6 Matchmaking Research

**The fragmentation problem:** With N variants, you split the player pool N ways. A 10,000 DAU app becomes ~1,000 per variant (or worse, since distribution is uneven).

**What works:**
- **AI fallback:** If no human found in 15-30s, seamlessly offer AI match (Backgammon NJ approach)
- **Multi-queue:** Let players queue for multiple variants simultaneously ("match me with whichever finds an opponent first")
- **Marathon mode as consolidation:** The traditional rotating match format (play all 3) naturally consolidates the pool
- **Featured variant rotation:** "Variant of the day" with bonus rewards concentrates players
- **Regional matchmaking:** Match Greek players with Greek players during Greek evening hours

**Rating system:** Separate ELO per variant (Chess.com/Lichess model). Use Bayesian prior from existing variant ratings when a player starts a new variant (e.g., 1700 Portes player starts Plakoto at ~1500 instead of default 1200).

### 1.7 Monetization Research

**What works for traditional board game apps:**
1. **Cosmetic-only purchases** (boards, checkers, dice skins) — highest user satisfaction, no pay-to-win backlash
2. **Premium subscription** (analysis, stats, ad-free) — strong secondary revenue for serious players
3. **Optional rewarded ads** — not mandatory, watch for bonus coins
4. **Virtual currency tournaments** — engagement driver

**What fails:**
- Pay-to-win mechanics (dice boosts) — universally reviled, especially in backgammon where "rigged dice" suspicion is endemic
- Energy/stamina systems — hated in board game apps
- Loot boxes — increasingly regulated
- Gating game variants behind paywall — user reviews are consistently negative; rules are public domain

**Critical decision: All variants must be free.** Gating rules behind payment fragments the multiplayer pool and generates backlash. Monetize through cosmetics and premium features instead.

---

## Part 2: Design Plan

### 2.1 Information Architecture

```
HOME SCREEN
├── [Quick Play] → Last played variant, last difficulty
├── [Choose Game]
│   ├── Tradition Picker (Tavli / Tavla / Nardy / Shesh Besh)
│   │   └── Variant Cards (e.g., Portes / Plakoto / Fevga)
│   │       └── Game Setup (difficulty, opponent type)
│   └── "Marathon" Mode (rotating match)
├── [Online Play]
│   ├── Quick Match (variant-specific or multi-queue)
│   ├── Play a Friend
│   └── Tournaments
└── [Learn] → Variant tutorials & rule browser
```

### 2.2 Variant Selection UX

**Principle: Cultural context first, then variant.**

#### Step 1: Tradition Selection
Large, visually distinct cards for each tradition:

| Card | Title | Subtitle | Visual |
|------|-------|----------|--------|
| Greek flag/pattern | **Tavli** | "The Greek way — three games, one match" | Kafeneio imagery |
| Turkish flag/pattern | **Tavla** | "The Turkish classic" | Tea house imagery |
| Russian/Caucasian pattern | **Nardy** | "The strategic long game" | Mountain/geometric imagery |
| Israeli pattern | **Shesh Besh** | "Fast and fearless" | Mediterranean imagery |

**Localization behavior:** Default to the user's culture based on:
1. Device language (el -> Tavli, tr -> Tavla, ru -> Nardy, he -> Shesh Besh)
2. Onboarding selection (already exists)
3. Most-played tradition (learned over time)

Show the user's preferred tradition first/prominently, but always show all others.

#### Step 2: Variant Selection (within a tradition)
Three cards per tradition (or two for Nardy/Shesh Besh):

Each card shows:
- **Variant name** (in the tradition's language + English)
- **One-line description** of the key mechanic
- **Icon** representing the mechanic (sword for hitting, lock for pinning, arrow for running)
- **"New to this?"** link to interactive tutorial

Example for Tavli:
```
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│   ⚔️ PORTES  │ │  🔒 PLAKOTO │ │  ➡️ FEVGA   │
│             │ │             │ │             │
│  "Hit and   │ │ "Trap your  │ │ "Race and   │
│   run"      │ │  opponent"  │ │  block"     │
│             │ │             │ │             │
│  [Play]     │ │  [Play]     │ │  [Play]     │
│  [Learn]    │ │  [Learn]    │ │  [Learn]    │
└─────────────┘ └─────────────┘ └─────────────┘
```

#### Step 3: Marathon Mode (Key Differentiator)
A dedicated "Marathon" button for the traditional rotating match:
- **Tavli Marathon:** Portes -> Plakoto -> Fevga (first to 3/5/7)
- **Tavla Marathon:** Tavla -> Tapa -> Moultezim
- This is how the game is traditionally played and **no competitor offers this digitally**
- Consolidates the multiplayer pool (everyone plays the same mode)

### 2.3 Rule Discovery & Onboarding

**First-time variant selection:**
When a player selects a variant they've never played, show a brief overlay:

```
┌──────────────────────────────────┐
│         PLAKOTO                  │
│                                  │
│  How it's different:             │
│  • All 15 checkers start on     │
│    one point                     │
│  • Land on a lone enemy to      │
│    TRAP it (not send to bar)     │
│  • Protect your "mother" —      │
│    if she's trapped, you lose!   │
│                                  │
│  [Got it, let's play]            │
│  [Show me a tutorial first]      │
└──────────────────────────────────┘
```

**In-game rule reminders:**
- Subtle toast/hint on first occurrence of a variant-specific situation
- E.g., first time a player tries to hit in Fevga: "In Fevga, you can't hit — one checker blocks the whole point"
- Can be disabled in settings

**Full tutorial per variant:**
- Interactive lessons (tutorial system already exists)
- Expand to cover each variant's unique mechanics
- 3-5 guided moves per variant, not a full game

### 2.4 Cross-Cultural "Discovery" Feature

**"Explore Other Traditions"** — a gentle nudge to try variants from other cultures:

- After completing 10 games in one tradition, show: "Did you know? In Russia, they play a version called Long Nard where no one can hit. Try it?"
- **Weekly cultural spotlight:** Feature a different tradition each week with a brief cultural note + bonus coins for trying it
- **Achievement chain:** "World Traveler" — win a game in each tradition. "Cosmopolitan" — win 10 games in each tradition

### 2.5 Visual Differentiation Per Tradition

Each tradition should feel subtly distinct beyond just the rules:

| Element | Tavli (Greek) | Tavla (Turkish) | Nardy (Russian) | Shesh Besh (Israeli) |
|---------|--------------|-----------------|-----------------|---------------------|
| **Default board** | Mahogany & Olive | Cedar & Crimson | Birch & Burgundy | Olive & Sandstone |
| **Board accent** | Greek key pattern | Ottoman arabesque | Geometric/carved | Mediterranean tile |
| **Typography accent** | Serif (Playfair) | Serif (Playfair) | Serif (Playfair) | Serif (Playfair) |
| **Bot personality** | Mikhail (Greek elder) | Could add: Mehmet | Could add: Armen | Could add: Yosef |
| **Ambient sound** | Kafeneio chatter | Tea house | Chess clock ticking | Mediterranean cafe |
| **Cultural color** | Blue & white | Red & gold | Blue & red | Blue & white |

Note: The core 5-color palette (background, surface, primary, text, light) stays constant. Cultural differentiation is through board skins and ambient elements, not UI chrome.

### 2.6 Multiplayer Variant Selection

**Quick Match flow:**
```
1. Select tradition (or "Any")
2. Select variant (or "Any" / "Marathon")
3. Select time control (optional)
4. Queue — show estimated wait time
   → Match found: play
   → 20s no match: "No opponents found. Play vs AI instead?"
```

**Multi-queue:** Player can check multiple variants they're willing to play. Matches against the first available opponent in any checked variant.

**Friend invite:** Inviter chooses the variant. Invitee sees which variant before accepting.

### 2.7 Rating & Profile Display

**Per-variant ratings on profile:**
```
┌──────────────────────────────┐
│  Your Ratings                │
│                              │
│  TAVLI                       │
│  Portes    ████████░░ 1650   │
│  Plakoto   ██████░░░░ 1420   │
│  Fevga     █████░░░░░ 1380   │
│                              │
│  NARDY                       │
│  Long Nard ███░░░░░░░ 1200   │
│  (new!)                      │
│                              │
│  Overall   ████████░░ 1520   │
└──────────────────────────────┘
```

**Overall rating:** Weighted average across all played variants (for leaderboard).
**Variant-specific leaderboards:** Separate rankings per variant.

---

## Part 3: Development Plan

### Phase 0: Audit & Foundations (1 session)

**Goal:** Verify existing variant engine correctness and identify gaps.

- [ ] Run full test suite for all 10 variant engines — verify edge cases
- [ ] Audit `VariantRules` for each variant — cross-reference with research above
- [ ] Verify Plakoto mother piece rule works correctly (both pinning and draw)
- [ ] Verify Fevga first-checker rule and prime restriction
- [ ] Verify Long Nard head rule exceptions (3-3, 4-4, 6-6 on first turn)
- [ ] Verify Short Nard doubling cube + Jacoby + beaver rules
- [ ] Verify Shesh Besh hit-and-run is correctly allowed
- [ ] Verify Tapa has NO mother piece rule (unlike Plakoto)
- [ ] Document any discrepancies found

**Deliverable:** Confidence that all 10 variants are rule-accurate.

### Phase 1: Variant Selection UX Redesign (2-3 sessions)

**Goal:** Replace current game-start flow with tradition -> variant -> setup flow.

#### 1A: Home Screen Redesign
- [ ] Design new home screen with Quick Play + Choose Game + Online Play + Learn sections
- [ ] Implement tradition picker (4 large cards with cultural visual identity)
- [ ] Implement variant picker per tradition (2-3 cards with mechanic icons)
- [ ] Add "Marathon" mode card for each tradition
- [ ] Wire Quick Play to last-played variant + difficulty
- [ ] Respect onboarding tradition selection as default
- [ ] Update router for new navigation flow

#### 1B: First-Time Variant Overlay
- [ ] Create reusable `VariantIntroSheet` widget
- [ ] Write concise rule summaries for all 10 variants (3-4 bullet points each)
- [ ] Show overlay on first selection of each variant (track in SharedPreferences)
- [ ] Include "Show me a tutorial" CTA linking to tutorial system
- [ ] Include mechanic family icon (sword/lock/arrow)

#### 1C: In-Game Rule Hints
- [ ] Add contextual hint system for variant-specific situations
- [ ] Plakoto: "Your checker is pinned — it can't move until the opponent leaves"
- [ ] Fevga: "One checker blocks the point in Fevga — you can't land here"
- [ ] Long Nard: "Head rule: only one checker can leave the starting pile per turn"
- [ ] Make hints dismissible and disable-able in settings
- [ ] Track which hints have been shown (don't repeat)

### Phase 2: Marathon Mode (1-2 sessions)

**Goal:** Implement the traditional rotating match format — a key differentiator.

- [ ] Create `MarathonState` model: current variant index, scores per player, target score
- [ ] Create `MarathonNotifier` (StateNotifier) that orchestrates variant rotation
- [ ] After each game: show score, announce next variant, transition
- [ ] Support target scores: first to 3, 5, or 7 points
- [ ] Gammon = 2 points, mother pin = 2 points (variant-specific scoring)
- [ ] Victory screen shows full marathon scorecard (results per variant)
- [ ] Works for: vs AI, pass-and-play, and online multiplayer
- [ ] Achievement: "True Tavli Player" — complete a marathon

### Phase 3: Tutorial Expansion (1-2 sessions)

**Goal:** Interactive tutorials for every variant's unique mechanics.

- [ ] Plakoto tutorial: pinning, unpinning, mother piece danger
- [ ] Fevga tutorial: blocking with single checkers, first-checker rule
- [ ] Long Nard tutorial: head rule, same-direction movement
- [ ] Short Nard tutorial: doubling cube, Jacoby rule
- [ ] Shesh Besh tutorial: hit-and-run concept
- [ ] "Learn" section on home screen: browse all variants with rules + tutorial access
- [ ] Rule reference accessible during gameplay (pause menu -> "Rules")

### Phase 4: Cultural Bot Personalities (1 session)

**Goal:** Make AI opponents feel culturally appropriate.

- [ ] Design 3-4 additional bot personalities beyond Mikhail:
  - **Mikhail** (Greek) — existing, works for Tavli tradition
  - **Mehmet** (Turkish) — tea-house grandmaster, calm and strategic
  - **Armen** (Armenian/Caucasian) — Narde specialist, competitive
  - **Yosef** (Israeli) — fast-talking, aggressive Shesh Besh player
- [ ] Write dialogue lines for each personality (7 languages each)
- [ ] Map default bot to tradition: Tavli -> Mikhail, Tavla -> Mehmet, etc.
- [ ] Allow player to choose any bot regardless of tradition (in settings or game setup)
- [ ] Variant-specific dialogue: bots comment on variant-specific situations

### Phase 5: Cross-Cultural Discovery System (1 session)

**Goal:** Encourage players to explore variants outside their tradition.

- [ ] "Explore Other Traditions" prompt after 10 games in one tradition
- [ ] Weekly cultural spotlight: featured tradition with brief cultural note
- [ ] Bonus coins for first win in a new tradition (50 coins)
- [ ] Achievement chain: "World Traveler" (1 win in each tradition), "Cosmopolitan" (10 wins in each)
- [ ] Variant recommendation engine: "Players who enjoy Plakoto often like Mahbusa"
- [ ] Cultural context cards: brief 2-3 sentence stories about each tradition's history

### Phase 6: Multiplayer Variant Support (2 sessions)

**Goal:** Full online multiplayer for all variants with smart matchmaking.

#### 6A: Variant-Aware Matchmaking
- [ ] Add variant field to matchmaking queue
- [ ] Multi-queue support: player checks which variants they'll accept
- [ ] "Any variant" option that matches against any queue
- [ ] Show estimated wait time per variant
- [ ] AI fallback after 20s timeout with clear messaging
- [ ] Marathon mode matchmaking (matches two players for full rotation)

#### 6B: Per-Variant Rating System
- [ ] Separate ELO rating per variant (stored in Firestore)
- [ ] Bayesian prior: new variant rating seeded from existing ratings
- [ ] Profile screen shows all variant ratings
- [ ] Per-variant leaderboards
- [ ] Overall rating = weighted average for global leaderboard

#### 6C: Online Marathon Mode
- [ ] Extend game room model for marathon (multi-game session)
- [ ] Handle variant transitions in Firestore (both players see next variant)
- [ ] Marathon-specific invite: "Play a Tavli Marathon (first to 5)"

### Phase 7: Future Variant Expansion (ongoing)

**Goal:** Add popular variants not yet implemented.

#### Priority 1: Gul Bara (Crazy Narde) -- IMPLEMENTED
- [x] Implemented cascading doubles rule in GulBaraEngine
- [x] Added to Turkish Tavla tradition as 4th variant
- [x] VariantRules config, intro sheet, rules reference all updated

#### Priority 2: Acey-Deucey (American)
- [ ] Implement off-board starting position
- [ ] Implement 1-2 special roll (choose doubles + re-roll)
- [ ] Create "Western" tradition: Standard Backgammon + Acey-Deucey + Nackgammon

#### Priority 3: Novelty Variants
- [ ] Hypergammon (3 checkers — quick games, good for casual play)
- [ ] Misere (reverse objective — party game)

### Phase 8: Cultural Localization Polish (1 session)

**Goal:** Make each tradition feel authentic beyond just rules.

- [ ] Tradition-specific board accent patterns (Greek key, Ottoman arabesque, etc.)
- [ ] Ambient sound profiles per tradition (kafeneio, tea house, etc.)
- [ ] Localized variant names throughout UI (not just the picker)
- [ ] Cultural color accents on tradition cards
- [ ] Marketing screenshots localized per target culture

---

## Part 4: Success Metrics

### Engagement Metrics
| Metric | Target | Why It Matters |
|--------|--------|----------------|
| Variants played per user (7-day) | >1.5 avg | Users exploring beyond their default |
| Marathon mode adoption | >20% of sessions | Key differentiator is being used |
| Cross-tradition play | >15% play a 2nd tradition within 30 days | Cultural discovery is working |
| Tutorial completion per variant | >40% on first exposure | Rules are accessible |
| Variant retention (play same variant 3+ times) | >60% | Variants are sticky, not just tried once |

### Multiplayer Health
| Metric | Target | Why It Matters |
|--------|--------|----------------|
| Avg matchmaking time (popular variants) | <15s | Healthy pool |
| Avg matchmaking time (niche variants) | <45s | Acceptable with AI fallback |
| AI fallback rate | <30% | Most matches are human |
| Multi-queue adoption | >25% of online players | Players willing to play multiple variants |

### Business Metrics
| Metric | Target | Why It Matters |
|--------|--------|----------------|
| DAU growth after variant launch | +30% in 90 days | Multi-variant attracts new segments |
| Geographic diversity of installs | >4 countries with 1K+ DAU | Cultural appeal is working |
| Retention (D30) | >25% | Variant depth keeps players engaged |

---

## Part 5: Risk Analysis

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Multiplayer pool fragmentation** | High | High | Marathon mode consolidation, multi-queue, AI fallback, featured variant rotation |
| **Overwhelming new users with choices** | High | Medium | Default to device-culture tradition; progressive disclosure; Quick Play defaults to most-played |
| **Weak AI for niche variants** | Medium | Medium | Invest in variant-specific board evaluation; Plakoto/Fevga evaluators need tuning |
| **Rule accuracy complaints** | High | Low | Cross-reference with multiple sources; community beta testing; in-app rule feedback button |
| **Cultural insensitivity** | High | Low | Research cultural context; avoid stereotypes in bot personalities; get native-speaker review for all copy |
| **Feature bloat / scope creep** | Medium | High | Ship phases incrementally; Phase 1-2 is the MVP; everything else is additive |

---

## Part 6: Phased Rollout Strategy

### MVP (Phases 0-2): "Play Your Way"
- All 10 variants working correctly with good AI
- Tradition -> Variant selection flow
- Marathon mode
- First-time rule overlays
- **Target:** 4-6 weeks

### V1.1 (Phases 3-4): "Learn & Explore"
- Full tutorials for all variants
- Cultural bot personalities
- In-game rule hints
- **Target:** 2-3 weeks after MVP

### V1.2 (Phases 5-6): "Play the World"
- Cross-cultural discovery system
- Variant-aware online matchmaking
- Per-variant ratings and leaderboards
- Online Marathon mode
- **Target:** 4-6 weeks after V1.1

### V2.0 (Phases 7-8): "Every Game, Every Culture"
- Gul Bara and Acey-Deucey variants
- Cultural localization polish
- Tournament system with variant rotation
- **Target:** Ongoing

---

## Appendix A: Complete Variant Reference

### Starting Positions

**Standard Backgammon Setup** (Portes, Tavla, Short Nard, Shesh Besh):
```
Point:  24  23  22  21  20  19  |  18  17  16  15  14  13
        [2]                 [5] |                      [5]
                                |          [3]
        ------- OUTER ---------|--------- HOME --------
        [5]                 [2] |                      [5]
                                |          [3]
Point:   1   2   3   4   5   6  |   7   8   9  10  11  12
```
(Numbers represent checker counts; top = Player 2, bottom = Player 1)

**All-On-One-Opposing** (Plakoto, Tapa, Mahbusa):
```
Point:  24  23  22  21  20  19  |  18  17  16  15  14  13
       [15]                     |
        ------- OUTER ---------|--------- HOME --------
       [15]                     |
Point:   1   2   3   4   5   6  |   7   8   9  10  11  12
```
Player 1: all 15 on point 1. Player 2: all 15 on point 24. Move in opposing directions.

**All-On-One-Same-Direction** (Fevga, Moultezim, Long Nard):
```
Point:  24  23  22  21  20  19  |  18  17  16  15  14  13
                                |                     [15] ← P2 start
        ------- OUTER ---------|--------- HOME --------
       [15]                     |                          ← P1 start
Point:   1   2   3   4   5   6  |   7   8   9  10  11  12
```
Both move counterclockwise (same direction). P1: 1->24. P2: 13->12 (wrapping).

### Scoring Summary

| Variant | Normal Win | Gammon | Backgammon | Special |
|---------|-----------|--------|------------|---------|
| Portes | 1 pt | 2 pts | No | — |
| Plakoto | 1 pt | 2 pts | No | Mother pinned = 2 pts |
| Fevga | 1 pt | 2 pts | No | — |
| Tavla | 1 pt | 2 pts | No | — |
| Tapa | 1 pt | 2 pts | No | — |
| Moultezim | 1 pt | 2 pts | No | — |
| Long Nard | 1 pt (oyn) | 2 pts (mars) | No | — |
| Short Nard | 1 pt | 2 pts | 3 pts | Cube multiplier applies |
| Shesh Besh | 1 pt | 2 pts | No | — |
| Mahbusa | 1 pt | 2 pts | No | Mother pinned = 2 pts |

### Rule Quick-Reference per Variant

| Rule | Por | Pla | Fev | Tav | Tap | Mou | LN | SN | SB | Mah |
|------|-----|-----|-----|-----|-----|-----|----|----|----|----|
| Hitting | Y | - | - | Y | - | - | - | Y | Y | - |
| Pinning | - | Y | - | - | Y | - | - | - | - | Y |
| Single blocks | - | - | Y | - | - | Y | Y | - | - | - |
| Hit-and-run | N | - | - | N | - | - | - | N | **Y** | - |
| Doubling cube | - | - | - | - | - | - | - | **Y** | - | - |
| Mother piece | - | **Y** | - | - | **N** | - | - | - | - | **Y** |
| Head rule | - | - | - | - | - | - | **Y** | - | - | - |
| First-checker rule | - | - | **Y** | - | - | **Y** | - | - | - | - |
| Prime restriction | - | - | **Y** | - | - | **Y** | **Y** | - | - | - |
| Winner re-rolls | **Y** | **Y** | **Y** | **Y** | **Y** | **Y** | - | - | - | - |
| Backgammon (3x) | - | - | - | - | - | - | - | **Y** | - | - |
| Same direction | - | - | **Y** | - | - | **Y** | **Y** | - | - | - |
