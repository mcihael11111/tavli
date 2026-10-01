# SP1 — Per-Variant Rules Matrix (for user sign-off)

**Date:** 2026-10-01
**Status:** **APPROVED 2026-10-01.** The user accepted every recommendation (**R**) in §6, D1–D22, including:
- **D20 = B:** re-model Tawla 31 as the running game now; add "Tawla 'Ada" as a 14th variant in a later stage.
- **D4/D5 = A:** Tavla house rules are on by default.
- **D9 = A:** Tapa uses the Bulgarian mother rule; a both-pinned tie scores 1 point each.

This document is the **normative rules source** for `tavli_core`. Where a section shows options, the **R** option is binding.
**Parent:** `2026-10-01-gameplay-rewrite-program-design.md` §4.3 (SP1 "Game core")
**Scope:** All 13 `GameVariant`s. Every rule cites a source. Rules that are regional or ambiguous are raised as DECISIONS. No rule here was invented. Where the sources say nothing, the doc says "no source".

---

## 0. Sources and how they rank

| Key | Source | Covers | Weight |
|---|---|---|---|
| **[EOPT]** | Ελληνική Ομοσπονδία Παραδοσιακού Τάβλι (Greek Federation of Traditional Tavli), *Κανονισμός Τουρνουά* v1.0, Aug 2025, §3.1–3.4. `https://eopt.gr/wp-content/uploads/2025/08/κανονισμος.pdf` | Portes, Plakoto, Fevga | **Highest for the Greek games** (governing body, 2025) |
| **[MINSPORT]** | Правила вида спорта «нарды», приказ Минспорта России от 22.07.2024 N 734, via legalacts.ru, §1.20–1.23, 20.1–20.6, 21, 23, 26.2–26.6, 27. A newer order (30.04.2025 N 347) exists but I could not read it. | Long Nard, Short Nard | **Highest for Nardy** (official sport rules) |
| **[PDF]** | `BACKGAMMON_RULES.pdf`, Manopoulos "How to play backgammon", 12 pages (images only, read visually). Covers **standard backgammon only**: p.3 setup, p.5 opening and movement, p.6 must-play, p.7–8 hitting and entering, p.8–9 bearing off, p.9–10 doubling, p.10 gammon and backgammon, p.10–11 optional rules (automatic doubles, beavers, Jacoby), p.11 irregularities. It says nothing about any other variant. | Hitting baseline | Base rules |
| **[BKGM-x]** | bkgm.com/variants/x.html, for x = Tavli, Portes, Plakoto, Fevga, Tavla, Tapa, Moultezim, GulBara, Narde | All except the Arab and Israeli games | Strong secondary source |
| **[WP-x]** | en.wikipedia: Tavli, Plakoto, Fevga, Tavla, Tables_game, Gul_bara · ru.wikipedia: Длинные нарды · bg.wikipedia: Табла (игра) · he.wikipedia: שש בש | Various | Secondary. Some sentences have no citation (noted where it matters) |
| **[TABLABG]** | tabla.bg/blog/vidove-tabla (Bulgarian) | Tapa, Gülbara | Regional |
| **[BETDIR]** | betdirection.com/gilbara (Bulgarian) | Gülbara | Regional |
| **[EGST]** | Egyptian Streets, "Egypt's 5 Most Common Tawla Games", 2022-09-10 | 'Aada, Mahbousa, Tawla 31, Gulbehar | Regional (Egypt) |
| **[ITAVLI31]** | itavli.com forum, "Rules of Tawla 31" | Tawla 31 | Weak to medium |
| **[JAW31] [JAWMAH]** | blog.jawaker.com/en/31-rules-en · blog.jawaker.com/mahboseh-rules (a large Arab online platform) | Tawla 31, Mahbusa | Medium |
| **[MAMOUN]** | J. S. Mamoun, *Fevga or Moultezim or Tawla 31 Board Game Strategy* (2018), archive.org/details/fevga | Fevga, Tawla 31 | Medium |
| **[BRAINKING]** | brainking.com/en/GameRules?tp=111 | Fevga | Medium |
| **[FOXMIND]** | foxmind.co.il, "איך משחקים שש-בש" (Hebrew) | Shesh Besh | Regional (Israel) |
| **[ZAGGAN]** | zaggan.blogspot.com/2017/07 (Greek). Lists the **current customary** Greek rules and argues against them. | Greek custom | Shows actual practice |
| **[TR-HOUSE]** | ekşi sözlük "tavlada içeride vurup kaçma yasağı" (seen only as a search summary; the page returned 403) and the donanimhaber.com bear-off debate | Tavla house rules | Weak. Shows the rules are disputed |
| **[GAMBLER] [LN-GS]** | gambler.ru/Narde · sites.google.com/site/longnarde | Long Nard | Secondary |
| **[APP]** | `tradition_lessons.dart`, `mechanic_comparisons.dart`, `variant_rules_sheet.dart`, `variant_intro_sheet.dart`, `game_variant.dart` | Everything | **Not a source.** Checked against the sources above |
| **[STRAT]** | `docs/plans/MULTI_VARIANT_STRATEGY.md` Part 1 and Appendix A | Everything | Contains no citations, so treated like [APP] |

I could not read: the Papahristou 2015 PhD thesis (access denied), almrsal.com and kuwaitigames.com (Arabic, 403 or closed), the full Minsport 2025 order (paywalled), and the Turkish ekşi page (403).

---

## 1. Coordinate convention (engine-ready)

`tavli_core` stores positions in **player-relative pips** (program spec §4.3):

- Each side counts its own points **24 → 1**. Point 24 is farthest from bearing off. **0 = borne off.** A move from pip *p* with die *d* lands on *p − d*.
- **Home board = pips 1–6** for every variant.
- **Opposing-direction games** (hitting, pinning): my pip *p* is the opponent's pip **25 − p**.
- **Same-direction games** (running): the opponent's pip *q* is my pip **q − 12** when *q* > 12, otherwise **q + 12**. So the opponent's head (their 24) is **my 12**, the opponent's home (their 1–6) is **my 13–18**, and the opponent's starting quarter (their 19–24) is **my 7–12**.

Mapping to today's app indices, for adapters (`board_state.dart`, `fevga_engine.dart`, `plakoto_engine.dart`):

| Layout | P1 index → pip | P2 index → pip | Note |
|---|---|---|---|
| Hitting (`BoardState.initial`) | pip = idx + 1 (P1 moves 23→0) | pip = 24 − idx | |
| Pinning (`allOnOneOpposing`) | pip = 24 − idx (P1 moves 0→23) | pip = idx + 1 | **P1's direction is reversed compared with hitting.** The `BoardState` doc comment (lines 15–16) is wrong for this layout |
| Running (`allOnOneSameDirection`) | pip = 24 − idx | pip = 36 − idx if idx ≥ 12, else 12 − idx | P2 starts at idx 12 and wraps 23→0 |

---

## 2. Summary matrix

Legend: ✅ sourced · ⚠️ contested, see the DECISION number · — not applicable · "no src" means no source found.

| Variant | Layout / dir | Contact | Opening (who / dice) | Special movement rule | Doubles | Win / gammon / triple | Mother | Cube | Match |
|---|---|---|---|---|---|---|---|---|---|
| **Portes** | std / opp | hit | ⚠️D1: EOPT plays the opening roll; bkgm and WP re-roll | none (EOPT). Hit-and-run ⚠️D3 | 4 | 1 / 2 / **counts as 2** | — | none | 3/5/7 marathon |
| **Plakoto** | 24×15 / opp | pin | ⚠️D1 | can't bear off while pinned (EOPT) | 4 | 1 / 2 / — | ✅ 2 pts, timing ⚠️D8 | none | marathon |
| **Fevga** | 24×15 / same | block (single) | ⚠️D1 | first checker must pass the opponent's head; 6-prime bans ⚠️D12–13 | 4 | 1 / 2 / — | — | none | marathon |
| **Tavla** | std / opp | hit | winner **re-rolls** (bkgm, WP) | ⚠️D4 no hit-and-run in home; ⚠️D5 no wasting pips | 4 | 1 / 2 (mars) / none | — | none | ⚠️D22 |
| **Tapa** | 24×15 / opp | pin | re-roll (bkgm) | as Plakoto | 4 | 1 / 2 / — | ⚠️D9 yes (BG sources) or no (WP) | none | 3/5/7 (BG) |
| **Moultezim** | 24×15 / same | block | re-roll (bkgm) | first checker past the opponent's head; ⚠️D14 | 4 | 1 / 2 / — | — | none | ⚠️D22 |
| **Gul Bara** | 24×15 / same | block | re-roll (bkgm, WP, BETDIR) | ⚠️D17 | **cascade** ⚠️D15–16 | 1 / 2 / — | — | none | 3/5/7 (BG) |
| **Long Nard** | 24×15 / same | block | **plays the opening dice** (MINSPORT 26.3) | head rule; 3-3/4-4/6-6 exception ⚠️D18; 6-block trapping all 15 banned ⚠️D19 | 4 | oin 1 / mars 2 / — | — | ⚠️D7 (official play uses one) | to N (MINSPORT 1.19) |
| **Short Nard** | std / opp | hit | **plays the opening dice** (MINSPORT 26.3) | standard | 4 | 1 / 2 / **koks 3** | — | ✅ cube + Crawford; Jacoby ⚠️D7 | to N |
| **Shesh Besh** | std / opp | hit | **plays the opening dice** (FOXMIND) ⚠️D1 | standard | 4 | 1 / 2 / **Turkish mars 3** (WP-he) ⚠️D6 | — | ⚠️D7 | ⚠️D22 |
| **Mahbusa** (IL) | 24×15 / opp | pin | no src ⚠️D1 | as Plakoto | 4 | 1 / 2 / — | ✅ ("misk"), scoring ⚠️D10 | none | ⚠️D22 |
| **Tawla 31** | ⚠️**running, not hitting** (D20–21) | block | no src | first checker to the opponent's home ⚠️D21 | 4 | **winner scores the loser's checkers left on the board** | — | none | **to 31** |
| **Mahbusa** (Arab) | 24×15 / opp | pin | higher roll begins (JAWMAH); dice no src | as Plakoto | 4 | 1 / 2 / — | ✅ ("misk") ⚠️D10 | none | Egypt: first to 3 (EGST) ⚠️D22 |

---

## 3. Rules shared by all variants (unless a section below overrides them)

| # | Rule | Source |
|---|---|---|
| G1 | Each player has 15 checkers. Two dice. The players alternate turns. | [PDF p.2–5] |
| G2 | The two dice are separate moves. One checker may use both, but only if the intermediate point is also open for that checker. | [PDF p.5], [BKGM-Moultezim] |
| G3 | Doubles are played four times. (Gul Bara overrides this after the opening rolls, see §4.7.) | [PDF p.5], [BKGM-Tapa], [MINSPORT 26.6.2] |
| G4 | **Max-dice rule:** use both dice if legally possible (all four for doubles). If only one die can be played, play it. If either die can be played but not both, **play the higher one**. If no die can be played, lose the turn. With doubles, play as many as possible. | [PDF p.6], [MINSPORT 20.6, 26.6.3], [BKGM-Moultezim] |
| G5 | Bearing off starts only when all 15 checkers are in the home board (pips 1–6). | [PDF p.8–9], [BKGM-Plakoto], [MINSPORT 27.1, 27.4] |
| G6 | Bear off with the exact die. If the die's point is empty, you must make a legal move with a checker on a higher point. If there is no checker on a higher point, you must remove one from the highest occupied point. You are not obliged to bear off if another legal move exists. | [PDF p.8], [BKGM-Portes], [MINSPORT 27.3] |
| G7 | Ties on the opening roll are re-rolled. | [PDF p.5], [MINSPORT 26.3] |
| G8 | The first player to bear off all 15 wins. Gammon/mars = the loser has borne off none. | [PDF p.10], every bkgm page, [MINSPORT 1.21] |
| G9 | No legal move means the turn passes (with no prompt in the engine; the UI shows it). | [PDF p.6], [MINSPORT 26.6.3] |

---

## 4. Per-variant rules

### 4.1 Portes (Πόρτες) — Greece, hitting

| Topic | Rule | Source |
|---|---|---|
| Setup | Standard: own 24:2, 13:5, 8:3, 6:5 | [PDF p.3], [WP-Tavli] |
| Direction | Opposing | [PDF p.4] |
| Opening | **⚠️ D1.** [EOPT 3.1.ii]: "the roll that decides who plays first **counts**", so the winner plays the two opening dice. [ZAGGAN] confirms this is current Greek custom ("παίζει το 6×3"). [BKGM-Portes] and [WP-Tavli] say "the winner of the opening roll rerolls". | as cited |
| Next game in a match | The winner of the previous game plays first | [EOPT 3.1.ii], [BKGM-Tavli] |
| Contact | Standard hitting, bar, entry into the opponent's home; must enter before any other move | [EOPT 3.2] ("official backgammon rules"), [PDF p.7–8] |
| Hit-and-run | **⚠️ D3.** EOPT lists only two exceptions to official backgammon rules: no cube, and triples count as doubles. It has **no** hit-and-run restriction. [WP-Tavli] says "There is no hit-and-run in home board" with **no citation**. [BKGM-Portes] says nothing. | as cited |
| Scoring | Single 1, gammon 2. "Triple games are counted as double." No backgammon. | [EOPT 3.2], [BKGM-Portes], [WP-Tavli] |
| Cube | None ("βίδο" excluded) | [EOPT 3.2], [BKGM-Portes] |
| Match | Tavli = Portes → Plakoto → Fevga, cycled, to 3, 5 or 7 points (WP: usually 5 or 7) | [EOPT 3.1.i], [BKGM-Tavli], [WP-Tavli] |

### 4.2 Plakoto (Πλακωτό) — Greece, pinning

| Topic | Rule | Source |
|---|---|---|
| Setup | 15 on own pip 24 (= the opponent's 1-point) | [BKGM-Plakoto], [WP-Plakoto] |
| Direction | Opposing | [BKGM-Plakoto] |
| Opening | Same as Portes (⚠️ D1). EOPT: "same rules as Portes except pinning replaces hitting." | [EOPT 3.3.i] |
| Contact | Landing on a **single** opposing checker pins it. A pinned checker can't move until every pinning checker has left. No bar. | [BKGM-Plakoto], [WP-Plakoto] |
| Blocked point | 2+ of my checkers, **or** 1 of my checkers pinning an opposing one, blocks the point to the opponent. The owner of the pinned checker can't land there. I may add more of my own checkers. | [WP-Plakoto] |
| Pin count | Only a single checker can be pinned, so at most 1 pinned checker per point | follows from above |
| Bear-off | Needs all 15 home. **"If the player bearing off gets pinned, bearing off stops."** In the engine: no bear-off while any of my checkers is pinned. | [EOPT 3.3.ii], [ZAGGAN] (custom), [JAWMAH] (same for Mahbusa) |
| Mother (μάνα) | The mother is the last checker on my start (pip 24). If it is pinned before it leaves: | [BKGM-Plakoto], [WP-Plakoto] |
| — basic | The game ends and the pinned side loses **2 points**. | [BKGM-Plakoto], [WP-Plakoto] |
| — exception | Not if the pinner still has checkers on its own start. [EOPT 3.3.iii]: the game ends as a double **"at the moment the opponent moves off his own mother"**. | [BKGM-Plakoto], [WP-Plakoto], [EOPT] |
| — both pinned | Tie. EOPT: "draw, **neither player gets points**." Next game: re-roll for first player. | [BKGM-Plakoto], [EOPT 3.3.iii, 3.1.ii] |
| Timing | ⚠️ D8 (immediately at that step, or at end of turn) | — |
| Scoring | 1 / 2 (loser borne off none) / mother 2. No triple. No cube. | [BKGM-Plakoto], [WP-Plakoto] |

### 4.3 Fevga (Φεύγα) — Greece, running

| Topic | Rule | Source |
|---|---|---|
| Setup | 15 on own pip 24, diagonally opposite corners. The opponent's head is at my pip 12. | [BKGM-Fevga], [WP-Fevga], [BRAINKING] |
| Direction | Same direction (anticlockwise) | [BKGM-Fevga], [WP-Fevga] |
| Opening | As Portes (⚠️ D1): "same rules as Portes except no hits and direction" | [EOPT 3.4.i] |
| Contact | None. **One checker controls a point.** You can't land or touch down on any point holding an opposing checker. | [BKGM-Fevga], [WP-Fevga] |
| First checker | **Move only one checker until it passes the opponent's mother** (the opponent's head, my pip 12). It must reach pip ≤ 11 before any other checker leaves pip 24. Under EOPT, a die the runner can't play is lost. | [EOPT 3.4.ii], [BKGM-Fevga], [WP-Fevga], [ZAGGAN] |
| Prime limits | **⚠️ D12.** EOPT: (a) no six-prime "at your start" (own pips 19–24); (b) no six-prime "in front of the opponent's mother". bkgm and BrainKing: may not block all six points of your starting table; a prime elsewhere is allowed, but if the opponent has gathered all his checkers on the point behind it, you must open it. Mamoun: no six in your own **or the opponent's** first quadrant. | as cited |
| Leave a move | **⚠️ D13.** EOPT (c): "players must, if possible, play their rolls so that the opponent is left legal moves". [WP-Tavli]: "in making a move, there must remain at least one possible move for the opponent". | [EOPT 3.4.iii.γ], [WP-Tavli] |
| Bear-off | Standard (G5, G6) | [BKGM-Fevga], [WP-Fevga] |
| Scoring | 1. **2 if the loser has borne off none.** No triple. No cube. | [BKGM-Fevga], [WP-Fevga] |

### 4.4 Tavla — Turkey, hitting

| Topic | Rule | Source |
|---|---|---|
| Setup / direction / contact | Standard backgammon | [BKGM-Tavla], [WP-Tavla] |
| Opening | "The winner of the opening roll rerolls for his first turn." (tr.wikipedia only says the higher die starts.) | [BKGM-Tavla], [WP-Tavla] |
| Hit-and-run | **⚠️ D4.** "You may not run for cover after hitting an opposing blot in your own home board. If you hit there, you must cover the hitter or leave it exposed." Turkish sources call it a **traditional but unofficial rule that is agreed before the game** ("içeride vurup kaçma yasağı"). | [BKGM-Tavla], [WP-Tavla], [TR-HOUSE] |
| Bear-off waste | **⚠️ D5.** "You may not unnecessarily waste pips during bearoff." Example: roll 5-2 with a checker on the 3-point; White must use the 5 to bear it off and may not play 2 first (3→1). Turkish forums disagree about this rule. | [BKGM-Tavla], [TR-HOUSE] |
| Scoring | 1, mars 2. No backgammon. No cube. | [BKGM-Tavla], [WP-Tavla] |
| Match | tr.wikipedia: "each game is 5 rounds; winning at least 3 wins". This is unclear (⚠️ D22). | [WP-tr Tavla] |

### 4.5 Tapa — Turkey/Bulgaria, pinning

| Topic | Rule | Source |
|---|---|---|
| Setup / direction | 15 on the opponent's 1-point, opposing directions (same as Plakoto) | [BKGM-Tapa], [TABLABG] |
| Opening | Winner re-rolls | [BKGM-Tapa] |
| Contact | Pinning, identical to Plakoto | [BKGM-Tapa], [TABLABG], [WP-bg] |
| Mother | **⚠️ D9.** [WP-Plakoto] says Tapa has "no mother piece", citing [BKGM-Tapa], but that page only *doesn't mention* one. [WP-bg] and [TABLABG] (Bulgarian, where Tapa comes from) **do** have it: your last start checker pinned before it leaves = you lose (Mars, 2), unless the opponent still has checkers on his start. Both pinned: **draw, each player gets 1 point** [TABLABG]. | as cited |
| Scoring | 1 / 2 ("mars"). No cube. | [BKGM-Tapa], [TABLABG] |
| Match | 3, 5 or 7, played in rotation (Bulgaria) | [WP-bg] |
| Note | Every source places Tapa in **Bulgaria**. I found no Turkish source for "Tapa". The app files it under the Turkish tradition. | [BKGM-Tapa], [WP-bg] |

### 4.6 Moultezim (Mültezim) — Turkey, running

| Topic | Rule | Source |
|---|---|---|
| Setup / direction | As Fevga | [BKGM-Moultezim] |
| Opening | Winner re-rolls | [BKGM-Moultezim] |
| Contact | A single checker blocks | [BKGM-Moultezim] |
| First checker | "Your first checker must pass the opponent's starting point before you may move any other." The Turkish summary says it must reach the opponent's starting **section**. | [BKGM-Moultezim], Turkish search summary (weak) |
| Blocking | **⚠️ D14.** bkgm: "You may not occupy more than four points in the opponent's starting table." The Turkish summary says you can't close all of points 1–6 of your own start, and must open a block if the opponent's remaining checkers are collected right behind it. [WP-Fevga] says Moultezim allows "unlimited prime formation" and "rolls for first play each game". | as cited |
| Scoring | 1 / 2 | [BKGM-Moultezim] |

### 4.7 Gul Bara (Gülbara, "Crazy Narde", Egyptian "Gulbehar") — running with cascading doubles

| Topic | Rule | Source |
|---|---|---|
| Setup / direction | As Fevga, same direction | [BKGM-GulBara], [WP-Gul_bara], [TABLABG], [EGST] |
| Opening | Winner re-rolls both dice | [BKGM-GulBara], [WP-Gul_bara], [BETDIR] |
| Contact | A single checker blocks. No hitting or pinning. | all |
| First checker / primes | **⚠️ D17.** No source mentions a first-checker rule or any prime limit for Gul Bara. [WP-bg] notes you can block six in a row "with few checkers". | — |
| Doubles, early | "During the first three rolls of the game, doubles are played as in backgammon." **⚠️ D15:** [BKGM] says "of the game"; the Bulgarian search summary says "until each player's third roll". | [BKGM-GulBara], [WP-Gul_bara] |
| Doubles, cascade | After that, doubles *d-d*: four *d*s, then four (*d*+1)s … up to four 6s. Example: 3-3 → 4×3, 4×4, 4×5, 4×6. | [BKGM-GulBara], [WP-Gul_bara], [EGST], [BETDIR] |
| Cascade failure | **⚠️ D16.** [BKGM]: "If at any point you are unable to play all four numbers, you lose the remainder of your turn." [WP-Gul_bara], [WP-bg], [TABLABG], [BETDIR]: "…**the opponent plays the remaining numbers** before their own turn." | as cited |
| Scoring | 1 / 2 | [BKGM-GulBara], [TABLABG] |

### 4.8 Long Nard (Длинные нарды) — Russia/Caucasus, running

| Topic | Rule | Source |
|---|---|---|
| Setup / direction | 15 on the "head" (own pip 24); the opponent's head is at my pip 12; same direction | [MINSPORT 20.2], [BKGM-Narde] |
| Opening | Each player throws one die. The higher die moves first **and uses those two numbers** ("this decides who moves first and which numbers he uses"). Ties re-roll. **Each later game is re-drawn the same way.** [BKGM-Narde] says the winner re-rolls; [WP-ru] agrees with MINSPORT. | [MINSPORT 26.3, 26.5], [WP-ru] |
| Contact | Can't land on any point holding an opponent checker | [MINSPORT 20.4, 20.6] |
| Head rule | Only **one** checker may leave the head per turn. A checker that has left may keep moving with the remaining dice. | [MINSPORT 20.3], [BKGM-Narde] |
| Head exception | **⚠️ D18.** MINSPORT: "the only exception is the **second player's first throw**, and only for 3-3, 4-4 or 6-6; then he may take 2 off the head despite any obstruction by the first player." Since the first player plays non-double opening dice, the first player can never have a double on turn 1. [BKGM-Narde]: "the first roll of the game … two off the head is **forced** for 3-3, 4-4, 6-6." [LN-GS]: both players' first turn. | as cited |
| Six-block | **⚠️ D19.** A block of 6 is allowed, **but it may not lock all 15 opposing checkers, not even in the middle of a turn** (you can't build it and dissolve it in the same move). [BKGM-Narde] equivalent: "at least one opposing checker must be in front of your prime." [GAMBLER] adds a variant: "only if at least one opposing checker has entered home". | [MINSPORT 20.5] |
| Must-play | G4 (full move required; higher die if only one can be played) | [MINSPORT 20.6, 26.6.3] |
| Bear-off | G5, G6 | [MINSPORT 27] |
| Scoring | **Oin 1** (loser has borne off ≥1), **Mars 2** (loser has borne off none). **Koks applies only to short nardy.** WP-ru lists "koks 3 / home-mars 4" as *informal* and notes tournaments recognise only oin and mars. | [MINSPORT 1.20–1.22], [WP-ru] |
| Cube | **⚠️ D7.** MINSPORT 23.2 and 26.2 use the cube in **both** long and short nardy. No casual or traditional source mentions a cube for long nard. | [MINSPORT] |

### 4.9 Short Nard (Короткие нарды) — Russia, hitting

| Topic | Rule | Source |
|---|---|---|
| Setup / direction / contact / bar | Standard backgammon; must enter from the bar first; partial entry forfeits the rest of the turn | [MINSPORT 21.1–21.12], [PDF] |
| Opening | Plays the opening dice | [MINSPORT 26.3] |
| Bear-off | A checker hit during bear-off must return home before bearing off continues | [MINSPORT 27.5], [PDF p.9] |
| Scoring | Oin 1, mars 2, **koks 3** (loser has borne off none and has a checker on the bar or in the winner's home), × cube | [MINSPORT 1.20–1.22] |
| Cube | Yes. Values 2–64, double only before rolling, a drop loses the current value, the taker owns the cube. **Crawford** rule in matches. | [MINSPORT 23.1–23.14], [PDF p.9–10] |
| Jacoby / beaver | **⚠️ D7.** Not in MINSPORT. [PDF p.10–11] lists them only as *optional*. The app's text claims both. | — |

### 4.10 Shesh Besh (שש-בש) — Israel, hitting

| Topic | Rule | Source |
|---|---|---|
| Setup / direction / contact | Standard backgammon | [WP-he], [FOXMIND] |
| Opening | One die each; the higher die starts and **plays the two opening dice** ("the first player can't start with a double, because a double is a tie") | [FOXMIND] and the Hebrew search summary |
| Hit-and-run | Allowed. This is simply standard backgammon. No source presents it as distinctive. | [PDF] |
| Scoring | 1 / **mars 2** / **"Turkish mars" 3** (loser has borne off none and still has checkers in the winner's home) | [WP-he] ⚠️ D6 |
| Cube | Described in Hebrew rule guides; no evidence on casual Israeli practice. ⚠️ D7 | [FOXMIND] |

### 4.11 Mahbusa (מחבוסה / محبوسة) — Israeli tradition entry

| Topic | Rule | Source |
|---|---|---|
| Setup / direction / contact | 15 on the opponent's side, opposing directions, pinning ("the hit counter is imprisoned and can't move until the opponent removes his piece") | [WP-Tables_game], [JAWMAH], [EGST] |
| Mother ("misk al-hajar") | "In a rare special case, the game ends if a player imprisons the first opponent stone in their final quarter." That is pinning the opponent's start checker, which sits in the pinner's home. A mahbuse.com description (seen only through a search summary) gives Plakoto's wording: double loss, exception if the pinner's own mother is still on its start, both pinned = tie. ⚠️ D10 | [JAWMAH], mahbuse.com (weak) |
| Bear-off | "Can't bear off if one of your stones in the final quarter is imprisoned." | [JAWMAH] |
| Bear-off detail | Bearing off is not mandatory; you may move within the final quarter instead | [JAWMAH] |
| Scoring | 1 / mars 2 | [EGST] ("same as 'Aada"), [JAWMAH] |
| Match | Egypt: first to 3 [EGST]; Jawaker: "5 rounds" | ⚠️ D22 |

### 4.12 Tawla 31 (طاولة ٣١, "wāḥid wa-thalāthīn") — Arab world

**Every source I found says this is a RUNNING / blocking game, not standard hitting backgammon.**

| Topic | Rule | Source |
|---|---|---|
| Identity | "Fevga is known as 31 … or tawla 31 in Egypt or Lebanon" | [MAMOUN], [WP-Fevga] ("in the Middle East as Tawla 31 or Maghribiyyah"), [WP-Tables_game], [WP-he] ("Thirty-One — a race game without hitting") |
| Direction | Same direction, "counter-clockwise like in Narde" | [ITAVLI31], [WP-Tables_game] |
| Setup | **⚠️ D21.** Mamoun: unlike Fevga, the stacks are "on either the left top and bottom, or the right top and bottom" (same side, not diagonal). [EGST]: "same as Mahbousa (stacked)". Jawaker: "each player's 15 in their designated corner". | as cited |
| Contact | "Once a checker is on a point, the opponent can't land there"; one checker controls a point | [EGST], [JAW31], [ITAVLI31] |
| First checker | **⚠️ D21.** "The first checker has to go to the **home base area of your opponent** before you can move the others" [ITAVLI31]; "advance only one counter to the opponent's 'home board'" [WP-Tables_game]; "move at least one checker to the opponent's side" [JAW31]. Fevga's threshold is pip ≤ 11; this reads as pip ≤ 18. | as cited |
| Primes | No source | — |
| Bear-off | Only when all checkers are in the last quarter; exact die, otherwise the lower-point rule | [JAW31] |
| **Scoring** | **The winner earns as many points as the opponent has checkers left on the board** (1–15). "The set ends when one player reaches 31 points." No source mentions a separate gammon multiplier. | [EGST], [ITAVLI31] |
| Opening | No reliable source ([JAW31] text is unclear) | ⚠️ D1 |

### 4.13 Mahbusa (Arab tradition entry)

Same rules as §4.11 ([JAWMAH], [EGST], [WP-Tables_game]). I found **no rule difference** between "Israeli" and "Arab" Mahbusa. ⚠️ D10 asks whether the two enum values should share one rule set.

---

## 5. Code vs rules — bug list (existing app)

### 5.1 Wiring (the most important)

| # | File:line | Problem | Rule source |
|---|---|---|---|
| C1 | `game_provider.dart:162-213` | Engines are chosen by `mechanicFamily`. **`VariantEngine` is never instantiated anywhere in lib/ or test/.** So: the Long Nard head rule never runs; Gul Bara plays as Fevga (no cascade); Moultezim and Tawla 31 also play as Fevga or Portes. | §4.7, §4.8 |
| C2 | `game_provider.dart:207-213` + `plakoto_engine.dart:328-358` | Tapa and both Mahbusas use `PlakotoEngine.getResult`, so all of them get the mother rule regardless of `hasMotherPiece`. | D9, D10 |
| C3 | `game_provider.dart:209` → `game_engine.dart:110-166` | Every hitting variant scores **backgammon = 3**. That contradicts Portes (EOPT: triples count as 2) and Tavla (no backgammon). `scoringBackgammon` is only read in the unused `VariantEngine`. | §4.1, §4.4 |
| C4 | `game_provider.dart:227-255` | The opening always **plays the opening dice**. `winnerRerolls` is never read. That is wrong for Tavla, Tapa, Moultezim and Gul Bara (bkgm: re-roll). It may be right for the Greek games, Nardy and Shesh Besh. | D1 |
| C5 | `game_provider.dart:307-345` | Human checker selection uses `_generateMovesForDie` and **ignores `legalTurns`**, so G4 (max dice, higher die) isn't enforced for the human. (Also listed in the program spec §1.1.) | G4 |
| C6 | `game_provider.dart:111-116, 471` | The cube is offered whenever `difficulty.usesDoublingCube` (medium and above), **in every variant**, including Plakoto and Fevga, which have no cube. `rules.hasDoublingCube` is ignored. | §4.x cube rows |
| C7 | `variant_rules.dart` + `game_variant.dart` | `winnerRerolls`, `allowHitAndRun`, `singleControlsPoint`, `hasAdvancementRule`, `hasPrimeRestriction`, `maxPrimeWithTrapped` are **never read**. `hasMotherPiece`, `hasHeadRule` and `scoringBackgammon` are read only by the unused `VariantEngine`. | — |

### 5.2 Variant config (`game_variant.dart`)

| # | Line | Config says | Sources say |
|---|---|---|---|
| C8 | 177-185 | `tawla31` = hitting, standard setup, hit-and-run | **Running game**; scored by the loser's remaining checkers to 31 (§4.12) |
| C9 | 107, 116 | Portes `allowHitAndRun: false` | EOPT has no such rule (D3). Tavla: bkgm has the ban (D4) |
| C10 | 108 | Portes `winnerRerolls: true` | EOPT 3.1.ii: the opening roll counts (D1) |
| C11 | 137 | Shesh Besh `winnerRerolls: true` | FOXMIND: plays the opening dice (D1) |
| C12 | 132-140 | Shesh Besh: no backgammon | WP-he: Turkish mars = 3 (D6) |
| C13 | 159 | Tapa `hasMotherPiece: false` | Bulgarian sources have it (D9) |
| C14 | 202-205 | Gul Bara: advancement + prime restriction | No source (D17) |
| C15 | 215-218, 228-231 | Fevga and Moultezim: `maxPrimeWithTrapped: 5` | No source gives a "max 5" number; the rules are positional (D12, D14) |
| C16 | 243 | `headRuleDoubleExceptions: [3,4,6]` | ✅ correct values; the scope question is D18 |
| C17 | 125-126 | Short Nard has a cube, but no Crawford/Jacoby settings | MINSPORT: Crawford (D7) |

### 5.3 Engine bugs (`plakoto_engine.dart`, `fevga_engine.dart`, `gul_bara_engine.dart`, `variant_engine.dart`, `board_state.dart`)

| # | File:line | Bug |
|---|---|---|
| C18 | `plakoto_engine.dart:158-184`, `fevga_engine.dart:216-244` | **The "bear off with a larger die" check runs in the wrong direction, for both players in both engines.** It checks the points *nearer* to off instead of *farther*. Example: P1 home 18–23 with checkers on 22 and 23, die 5 from 22 is refused because of the checker on 23. Meanwhile a checker on 23 with die 5 is allowed even when a checker sits on 18 (6-pt). The hitting `move_validator.dart:51-87` is correct. |
| C19 | `board_state.dart:18-19, 123-127` + `plakoto_engine.dart:76-88` | Points are stored as **signed net counts**, so a pinned point (1 pinned + n pinners) stores n − 1. Effects: (a) a pinned checker is invisible to `checkerCount` and `allInHome`, so a player can bear off while pinned, against [EOPT 3.3.ii]; (b) with one pinner, the value is 0, so `isPointOpen` (`plakoto_engine.dart:98-110`) lets the **pinned side land on the pinner's point**; (c) pip counts and evaluators are wrong. |
| C20 | `plakoto_engine.dart:30-37, 335-341` | The mother rule is only checked **after 15 are borne off**. It never ends the game immediately, has no "pinner still on start" exception, no tie, and scores `backgammon` = **3 points** instead of 2. |
| C21 | `fevga_engine.dart:185-195, 168` | P2's target wraps without stopping at its home. A P2 checker on idx 6–11 that isn't bearing off can move to 12+ and **lap the board**. |
| C22 | `fevga_engine.dart:41-65` | Bans **any** 6 consecutive own points anywhere, including across the wrap, with no condition. No source has that rule (§4.3, §4.6, §4.8). |
| C23 | `fevga_engine.dart:70-111` | The own-start-quarter six is allowed once the opponent has passed. bkgm, BrainKing and EOPT ban it unconditionally (D12). |
| C24 | — | Fevga, Moultezim and Tawla 31 **first-checker rules are not implemented at all**. |
| C25 | `fevga_engine.dart:373-393` | A double (2) needs "loser borne off 0 **and** has a checker in its own start quadrant". The sources need only "borne off 0". |
| C26 | `plakoto_engine.dart:309-314`, `fevga_engine.dart:349-353` | Dedup key is the *ordered* move list, giving the ~10× duplicates in the program spec. `move_generator.dart:283-292` sorts by from/to/die, but that still isn't dedup by resulting position. |
| C27 | `gul_bara_engine.dart:66-111` | The cascade takes the **first legal move greedily** (one path only). The roll counter defaults to 99. Not used anyway (C1). |
| C28 | `variant_engine.dart:170-193` | The head filter treats "first turn" as "15 on head", which is fine. But it also applies Fevga's unconditional prime and start-quadrant rules to Long Nard, where MINSPORT 20.5 has a different rule. |
| C29 | `move_generator.dart` | No Tavla hit-and-run or no-waste logic (D4, D5) |

### 5.4 In-app rule text that contradicts the sources

| File:line | Text | Sources |
|---|---|---|
| `tradition_lessons.dart:39, 53`; `variant_rules_sheet.dart:186`; `variant_intro_sheet.dart:74`; `mechanic_comparisons.dart:39-47` | Portes "No hit-and-run" | EOPT has none (D3) |
| `tradition_lessons.dart:42, 54`; `variant_rules_sheet.dart:189`; `variant_intro_sheet.dart:75` | Portes "winner re-rolls" | EOPT: the opening roll counts (D1) |
| `tradition_lessons.dart:430`; `variant_rules_sheet.dart:323`; `variant_intro_sheet.dart:129` | Shesh Besh "winner re-rolls" | FOXMIND: plays the dice |
| `tradition_lessons.dart:441` | Shesh Besh: "hit-and-run is the defining rule" | It is just standard backgammon |
| `tradition_lessons.dart:500-528`; `variant_rules_sheet.dart:343-356`; `variant_intro_sheet.dart:138-141` | Tawla 31 = hitting, "1 per win, 2 for mars" | Running game; points = loser's remaining checkers |
| `tradition_lessons.dart:225`; `variant_rules_sheet.dart:246`; `mechanic_comparisons.dart:97-103` | Tapa: "NO mother piece" | Bulgarian sources: yes (D9) |
| `tradition_lessons.dart:294`; `variant_rules_sheet.dart:277`; `variant_intro_sheet.dart:111` | Gul Bara: "cascade ends" | Most sources: the opponent plays the remainder (D16) |
| `tradition_lessons.dart:295`; `variant_rules_sheet.dart:278` | Gul Bara: "same advancement and prime rules as Fevga" | No source (D17) |
| `tradition_lessons.dart:377-378`; `variant_rules_sheet.dart:308-309`; `variant_intro_sheet.dart:122` | Short Nard: Jacoby + beaver | MINSPORT: Crawford, neither of those (D7) |
| `tradition_lessons.dart:79`, `mechanic_comparisons.dart:113-118` | "Both mothers pinned → draw" | ✅ matches EOPT and bkgm (EOPT: 0 points) |
| `mechanic_comparisons.dart:186-194` | "Max prime (trapping) 5" for all running games | Not how any source states it |
| `tradition_lessons.dart:117-119` | Fevga prime rules | Partly right; see D12 |

---

## 6. DECISIONS for the user

Each one gives the options, who plays which way, and **my recommendation (R)**. A one-word answer per number is enough.

**D1 — Opening procedure (per variant).** A = the winner **plays the two opening dice** (no doubles possible); B = the winner **re-rolls** both dice.

| Variant | Evidence | R |
|---|---|---|
| Portes, Plakoto, Fevga | A: [EOPT 3.1.ii] (2025 federation) + [ZAGGAN] (custom). B: [BKGM], [WP-Tavli] | **A** (federation + actual custom) |
| Tavla, Tapa, Moultezim, Gul Bara | B: [BKGM] ×4, [WP-Tavla], [BETDIR] | **B** |
| Long Nard, Short Nard | A: [MINSPORT 26.3]. B: [BKGM-Narde] | **A** |
| Shesh Besh | A: [FOXMIND] | **A** |
| Tawla 31, both Mahbusas | no source | **A** (international default; flag in the UI copy as "house rule") |

**D2 — Who starts the next game in a match?** A = the previous winner (Tavli: [EOPT 3.1.ii], [BKGM-Tavli]; after a Plakoto draw, re-roll); B = a new opening roll each game (Nardy: [MINSPORT 26.5]). **R:** A for Tavli marathon games, B everywhere else (no source for the other traditions).

**D3 — Portes hit-and-run.** A = no restriction ([EOPT 3.2] "official backgammon rules"); B = the Tavla-style home-board ban ([WP-Tavli], uncited). **R: A.**

**D4 — Tavla "no hit-and-run in home board."** A = enforce: within a turn, after a hit inside my home board (pips 1–6), no checker may leave that point for the rest of the turn; covering it is allowed ([BKGM-Tavla], [WP-Tavla]). B = off (standard), since Turkish sources call it an agreed house rule ([TR-HOUSE]). **R: A by default, with a "house rules" toggle later.** It is the documented Tavla deviation. Please also confirm that "no checker may leave the hit point" is the semantics you want, since checkers can't be told apart.

**D5 — Tavla "no wasting pips" in bear-off.** A = enforce it as a play filter: among the max-dice legal plays, keep those that bear off the most checkers, then those with the **least wasted pips** (die − distance, summed over bear-offs). This reproduces bkgm's 5-2 example. B = off (standard), because Turkish forums disagree ([TR-HOUSE]). **R: A**, behind the same toggle as D4.

**D6 — Triple (backgammon) scoring outside Short Nard.** Portes: triple counts as **2** ([EOPT 3.2]). Tavla: none, so 2 ([BKGM-Tavla]). Shesh Besh: [WP-he] says "Turkish mars" = **3**. **R:** Portes and Tavla capped at 2; **Shesh Besh 3** (only source); Tawla 31 uses its own scoring (D21).

**D7 — Doubling cube policy.**

| Variant | Evidence | R |
|---|---|---|
| Short Nard | Cube + Crawford in matches ([MINSPORT 23]); Jacoby, beaver and automatic doubles only "optional" ([PDF p.10–11]) | **Cube on, Crawford on; Jacoby, beaver, auto-doubles off.** Fix the app text |
| Long Nard | Official competitions use it ([MINSPORT 23.2, 26.2]); not in traditional play | **Off** by default; a later "tournament" option |
| Shesh Besh | Hebrew guides describe it; no evidence on casual use | **Optional, off by default** |
| All others | Explicitly none ([EOPT], [BKGM] for each) | **None** (fixes C6) |

**D8 — Plakoto mother timing and draw value.** (a) If the pinner has **no** checkers left on its own start, the game ends **at that step**, with remaining dice unplayed, and scores 2. (b) If the pinner still has checkers on its start, the game continues and ends double **the moment the pinner's last start checker leaves**, unless the pinner's own mother is pinned first, which makes a **draw with 0 points** ([EOPT 3.3.iii], [BKGM-Plakoto]). Does a draw count as a played game in a marathon? EOPT: no points, then re-roll for first player. **R: implement (a) and (b) exactly as EOPT describes, checked after every step.**

**D9 — Tapa mother rule.** A = yes, as Plakoto, but a both-pinned tie scores **1 point each** ([WP-bg], [TABLABG]); B = yes, scored exactly like Plakoto (draw 0); C = no mother rule ([WP-Plakoto], built on bkgm's silence; the current app text). **R: A.** It comes from the only sources from Tapa's home country, Bulgaria. If you want Tapa to differ from Plakoto, A differs only in the tie value. Also decide whether Tapa stays under "Turkey" (all sources say Bulgaria).

**D10 — Mahbusa ×2 (Israeli and Arab).** The sources show no rule difference. Options: A = both use Plakoto rules (mother = "misk", 2 points, same exception, tie 0) ([JAWMAH], mahbuse.com); B = keep two enum values with identical rules and different cultural framing only. **R: A + B.** Use one rule set, keep both enum entries, and score misk at 2 (low confidence: Jawaker doesn't state a value).

**D11 — Bear-off while one of your checkers is pinned (all pinning games).** A = not allowed while any own checker is pinned ([EOPT 3.3.ii], [JAWMAH], [ZAGGAN] custom); B = allowed if the pinned checker is inside home. **R: A.**

**D12 — Fevga six-prime rules.** Options:
- A (EOPT): (a) no 6 consecutive own points covering my pips 19–24; (b) no 6 consecutive own points "in front of the opponent's mother", read as my pips 6–11 *while the opponent has ≥1 checker on its head*; (c) D13.
- B (bkgm/BrainKing): (a) as above; a prime elsewhere is legal; if all the opponent's remaining checkers sit on the single point directly behind my prime, I must break it on my next turn when I can.
- C (Mamoun): no 6 in my 19–24 or in my 7–12 (the opponent's starting quadrant); otherwise as B.

**R: A**, the Greek federation, which is the most recent and authoritative. Please confirm the reading of (b): **"the six points directly in front of the opponent's head, only while the head is occupied."** Also: should the check apply after **every step** (as MINSPORT 20.5 requires for nardy) or only at end of turn? **R:** end of turn for Fevga. No Greek source requires a per-step check.

**D13 — Fevga "leave the opponent a legal move."** A = play filter: among legal plays, drop any after which the opponent would have **no legal move for any of the 21 rolls**, unless every play has that result ([EOPT 3.4.iii.γ], [WP-Tavli]); B = weaker: drop plays after which the opponent can't move with *some* roll; C = don't implement. **R: A** (closest to "leave the opponent legal moves"). It needs a hook (§7) and costs one opponent move generation per candidate play, which still fits the 2 ms budget with early exit.

**D14 — Moultezim.** A = identical to Fevga under bkgm-style rules (D12-B) + first checker; B = add bkgm's "may not occupy more than four points in the opponent's starting table" (my pips 7–12) and no other prime limits; C = Fevga minus the prime limits ([WP-Fevga] "unlimited prime formation"). **R: B**, the only explicit Moultezim-specific rule source (bkgm), plus "can't close all six of own start quarter" from the Turkish summary. Low confidence; consider asking a Turkish player.

**D15 — Gul Bara: when does the cascade start?** A = after the first **3 rolls of the game** (rolls 1–3 normal; the opening one-die roll doesn't count) ([BKGM-GulBara], [WP-Gul_bara]); B = after **each player's** first 3 rolls (Bulgarian summary). **R: A.**

**D16 — Gul Bara: cascade failure.** A = the rest of the cascade is lost ([BKGM-GulBara]); B = **the opponent plays the remaining numbers**, under the same cascade rule (stopping at its own first failure), then takes its normal turn ([WP-Gul_bara], [WP-bg], [TABLABG], [BETDIR], 4 sources). **R: B** (majority, and Bulgaria is where Gülbara is most alive). Also: within one number, play as many of the four as possible, then stop. This needs a turn-structure hook (§7).

**D17 — Gul Bara first-checker / prime restrictions.** No source has either. A = none (sources); B = the Fevga set (current app text). **R: A**, but keep the "may not trap all opposing checkers" fallback from D12/D19 only if you want it (no source).

**D18 — Long Nard head exception.** With D1-A (opening dice played), MINSPORT's "second player's first throw only" is the same as "each player's first turn". A = on a player's **first turn**, with 3-3, 4-4 or 6-6, up to **2** checkers may leave the head; the max-dice rule (G4) then forces the second one whenever it is needed. No other double, and no later turn, ever allows 2. B = bkgm's wording ("forced"), which in practice is the same as A plus G4. **R: A.**

**D19 — Long Nard six-block.** A = MINSPORT 20.5: a 6+ run of my points is illegal if **no** opposing checker is ahead of it (all of them are behind), **checked after every step**; B = same, checked at end of turn only; C = [GAMBLER] "only if an opponent checker has entered home". **R: A.** Also: informal koks/home-mars scoring? **R: no** (oin 1, mars 2 only).

**D20 — What is "Tawla 31"?** All sources say it is a **running game**; the app makes it hitting backgammon. A = re-model `tawla31` as the running game (§4.12), leaving the Arab tradition with running (Tawla 31) and pinning (Mahbusa) games but **no hitting game**; B = A + add the Egyptian hitting game **"'Aada / Tawla 'Ada"** later as a 14th variant ([EGST]); C = keep `tawla31` as hitting and rename it ("Tawla"), then add a separate real 31. **R: B.** Fix 31 now (it stays at 13 variants for SP1), and add "Tawla 'Ada" in a later SP.

**D21 — Tawla 31 details** (if D20 = A or B):
- (a) **Layout.** Diagonal (Fevga / Narde, [ITAVLI31] "like Narde") or same side ([MAMOUN]). **R: diagonal.** Same-side stacks with same-direction movement don't fit the board geometry I can verify.
- (b) **First checker** must reach the opponent's **home** (my pips 13–18) before others move ([ITAVLI31], [WP-Tables_game], [JAW31]). **R: yes, threshold pip ≤ 18.**
- (c) **Prime limits.** No source. **R:** only "may not trap all opposing checkers" (as D19-B), or none? **R: none** (sources).
- (d) **Scoring.** The winner gets points = the loser's checkers still on the board; first to **31** wins the set ([EGST], [ITAVLI31]); no separate gammon. **R: yes.**
- (e) **Opening.** D1.

**D22 — Default match formats.** Sources: Tavli 3/5/7 marathon ([BKGM-Tavli], [WP-Tavli]; usually 5 or 7); Bulgaria 3/5/7 ([WP-bg]); Egypt first to 3 ([EGST]); Tawla 31 to 31; Nardy "set by the regulations" ([MINSPORT 1.19]); Turkey "5" (unclear, [WP-tr]). **R:** default single game; match options 3/5/7 everywhere; Tawla 31 fixed at 31; Tavli and Tavla marathons per [STRAT]; Crawford only where a cube is in play (D7).

**Total: 22 DECISIONS.**

---

## 7. Proposed `VariantRules` (data) + hooks (code)

Extend `lib/core/constants/variants/variant_rules.dart` into `tavli_core` (pure Dart). Everything below is data unless marked **HOOK**.

```dart
enum Layout { standard2535, stackOpposing, stackDiagonal }   // §1
enum Direction { opposing, same }
enum Contact { hit, pin, block }                               // block = singleControlsPoint
enum OpeningProcedure { playOpeningDice, winnerRerolls }       // D1
enum NextGameStarter { openingRoll, previousWinner }           // D2

class HeadRule {                                               // Long Nard
  final int maxOffHeadPerTurn;                 // 1
  final Set<int> firstTurnDoubleExceptions;    // {3,4,6}
  final int maxOffHeadOnException;             // 2
}
enum AdvancementThreshold { none, passOpponentHead /*pip<=11*/, reachOpponentHome /*pip<=18*/ }
class Advancement { final AdvancementThreshold threshold; final bool soleRunner; } // Fevga, Moultezim, Tawla 31

class PrimeRules {
  final bool noSixInOwnStartQuarter;           // Fevga (a), Moultezim
  final bool noSixInFrontOfOccupiedOppHead;    // Fevga EOPT (b)
  final int? maxPointsInOppStartQuarter;       // Moultezim bkgm: 4
  final bool noPrimeTrappingAllOpponents;      // Long Nard (MINSPORT 20.5)
  final bool checkEveryStep;                   // Long Nard true, others false
  final bool mustLeaveOpponentAMove;           // Fevga (c)  -> HOOK (lookahead)
}

class PinRules {
  final bool motherRule;
  final int motherPoints;                      // 2
  final bool exceptionWhilePinnerOnStart;      // EOPT/bkgm: true
  final DrawScore bothMothersPinned;           // zeroZero (Plakoto) | oneEach (Tapa)
  final bool noBearOffWhileOwnPinned;          // D11
}

class HitRules {
  final bool noHitAndRunInHome;                // Tavla (D4)  -> HOOK (per-turn state)
  final bool bearOffNoWaste;                   // Tavla (D5)  -> HOOK (play filter)
}

enum DoublesMode { four, cascade }
class Cascade {                                // Gul Bara
  final int normalRolls;                       // 3
  final bool countPerPlayer;                   // D15: false
  final CascadeFailure onFailure;              // forfeit | opponentPlaysRemainder (D16)
}

enum ScoringModel { multiplier, checkersRemaining }   // Tawla 31 = checkersRemaining
class Scoring {
  final ScoringModel model;
  final int single;          // 1
  final int gammon;          // 2
  final int? backgammon;     // 3 (Short Nard koks, Shesh Besh Turkish mars), null = none
  final bool tripleCountsAsGammon; // Portes (EOPT) -> same as backgammon: 2
}

class CubeRules { final bool available; final bool crawford; final bool jacoby; final bool beaver; final bool autoDoubles; }
class MatchDefaults { final int? fixedTarget /*31*/; final List<int> targets; }

class VariantRules {
  final Layout layout; final Direction direction; final Contact contact;
  final OpeningProcedure opening; final NextGameStarter nextGame;
  final HeadRule? head; final Advancement? advancement; final PrimeRules primes;
  final PinRules? pin; final HitRules? hit;
  final DoublesMode doubles; final Cascade? cascade;
  final Scoring scoring; final CubeRules cube; final MatchDefaults match;
}
```

### What can't be pure data (needs hooks in the play generator or reducer)

| Rule | Why it needs a hook | Hook shape |
|---|---|---|
| Fevga "leave the opponent a move" (D13) | Needs opponent move generation for 21 rolls per candidate play | `PlayFilter` that runs after max-dice filtering, with early exit |
| Tavla no-waste bear-off (D5) | A play-level metric, not a per-step one | `PlayFilter` |
| Tavla hit-and-run ban (D4) | Per-turn state (which points had a home-board hit) | `StepValidator` with a turn-scoped context |
| Long Nard per-step six-block (D19) | Must check intermediate positions | `StepValidator` |
| Head rule | Counts head departures within the turn; first-turn exception | `StepValidator` + turn context |
| Fevga / Moultezim / Tawla 31 sole runner | Restricts which checker may move until the threshold is passed | `StepValidator` |
| Plakoto mother timing (D8) | Ends the game mid-turn; deferred trigger when the pinner's head empties | `PostStepEvent` → `GameOver(points)` |
| Gul Bara cascade (D15–16) | Variable dice sequence; on failure the opponent plays the remainder before its own roll | turn-structure hook in the reducer (`DiceQueue` in `GameState`, roll counter) |
| Tawla 31 scoring | Simple, but it is a match-level counter, not a multiplier | `ScoringModel.checkersRemaining` + `MatchState` target 31 |

### Data-model requirement (from C19)

The position must hold, per point, **the occupant count plus a "pinned opponent checker underneath" bit**. That is the program spec's Int8List + pin mask. The pinned checker must count toward its owner's checker total, pip count and "all in home" check, and its point must be closed to its owner while pinned.

---

## 8. Top uncertainties (accuracy honesty)

1. **Tawla 31 setup and first-checker threshold.** Sources are informal (forum, news article, Jawaker); [MAMOUN]'s "same side" claim conflicts with same-direction geometry.
2. **Moultezim.** bkgm, the English Wikipedia and the Turkish summaries each give a different blocking rule. I found no Turkish governing body.
3. **Tapa mother rule.** The sources split along regional lines (Bulgarian: yes; English Wikipedia: no, but only through bkgm's silence).
4. **Gul Bara.** "Three rolls of the game" vs "per player"; forfeit vs opponent plays the remainder.
5. **The meaning of EOPT's "in front of the opponent's mother"** (D12-b).
6. **Arab and Israeli openings, match lengths and cube use.** I found no authoritative source.
7. The Russian rules quoted here are the **2024** order (N 734); a 2025 order (N 347) exists and was not readable.

---

## 9. Addenda — interpretations made during implementation

These are conservative readings chosen where the approved rules didn't settle an edge case. A1 and A2 are covered by tests. A3 is implemented but untested, because no current variant can reach it. They will be surfaced to the user in the SP1 report, and any can be flipped.

| # | Topic | Reading chosen | Where |
|---|---|---|---|
| A1 | Sole runner (Fevga, Moultezim, Tawla 31) with ≥ 2 checkers already off an unreleased head. Unreachable in normal play | The head stays locked; any checker already off the head may move | `step_validators.dart`, Task 5 |
| A2 | Tavla D4 "no checker may leave the hit point" during bear-off | Applies literally: after a hit on home pip *h*, nothing may bear off from *h* for the rest of that turn | Task 5 |
| A3 | D19 six-block and pinned checkers. Only matters if D19 is ever enabled for a pinning game; today only Long Nard uses it | Points where my checker is pinned don't count as held. A pinned opposing checker at the run's start is not "in front" | Task 5 (untested: unreachable today) |
| A4 | A step that ends the game mid-turn: bearing off the 15th checker (G8), an immediate mother win (D8a), or both mothers pinned (draw) | The sequence ends there and **counts as using all its dice** for G4 max-dice, so a game-ending play is never discarded for using fewer dice. A game-ending cascade has an empty remainder | Tasks 6/8/11 |
| A5 | D12-A parts (a)+(b), and D14-B's two parts | Each pair is applied as one filter. If every play breaks some part, all plays survive; neither part is preferred | Task 7 |
| A6 | Gul Bara cascade with no playable step at all | The remainder is the whole queue, which the opponent plays under D16-B | Task 8 |
| A7 | G4 higher-die with step sequences | When only one die can be played, sequences using the lower die are dropped even if they reach the same final position as a higher-die sequence | Task 6 |
| A8 | **Open question for the user.** The approved D5-A filter keeps the plays that "bear off the most checkers" before applying least-waste. That forces a bear-off when one is possible, which goes beyond G6 ("not obliged to bear off") and beyond the bkgm wording (only "don't waste pips"). Example: Tavla, `one {2:1, 6:14}`, dice 2-1: only "2/off + a 1" survives, whereas Portes also allows 6/4, 6/5 | Implemented as approved (D5-A). To be raised in the SP1 report; dropping the "most borne off" stage would make it least-waste only | Task 7 |
| A9 | Resign and clock timeout scoring. Scoring a flat 1 point lets a player escape a threatened gammon, triple or mother loss | The loser forfeits **what the board currently threatens**, × cube: <br>• **Tawla 31:** the loser's checkers on the board. <br>• **Mother rule:** mother points if the loser's mother is pinned. <br>• **Otherwise:** triple if that variant's triple condition holds and the loser has borne off none; gammon if the loser has borne off none; else single. <br>Result kind stays `resign`/`timeout`. A later "offer resignation at a level" UI can be added | Task 10/11 follow-up |
