import 'package:flutter/material.dart';
import '../../../core/constants/tradition.dart';
import '../../game/domain/engine/variants/game_variant.dart';
import '../data/models/lesson.dart';

/// Returns the lesson section for a given tradition.
LessonSection sectionForTradition(Tradition tradition) => switch (tradition) {
      Tradition.tavli => _tavliSection,
      Tradition.tavla => _tavlaSection,
      Tradition.nardy => _nardySection,
      Tradition.sheshBesh => _sheshBeshSection,
    };

// ── Tavli (Greece) ──────────────────────────────────────────────

const _tavliSection = LessonSection(
  id: 'tavli',
  title: 'Tavli',
  type: LessonSectionType.tradition,
  tradition: Tradition.tavli,
  prerequisiteSectionId: 'foundation',
  lessons: [
    Lesson(
      id: 'tavli_portes',
      title: 'Portes',
      nativeTitle: 'Πόρτες',
      mechanicFamily: MechanicFamily.hitting,
      tradition: Tradition.tavli,
      variant: GameVariant.portes,
      icon: Icons.gavel,
      botDialogue:
          'Portes is the classic Greek backgammon! Hit your opponent\'s '
          'blots and race to bear off. But remember — no hit-and-run here!',
      setup: 'Standard backgammon: 2 on 24-pt, 5 on 13-pt, 3 on 8-pt, 5 on 6-pt',
      coreMechanic: [
        'Hit lone opponent checkers (blots) to send them to the bar',
        'Hit checkers must re-enter through opponent\'s home board',
        'No hit-and-run — cannot hit and continue on the same die',
      ],
      specialRules: [
        'Winner of opening roll re-rolls both dice for first turn',
        'No backgammon (3×) scoring — only single and gammon',
      ],
      scoring: ['Single win: 1 point', 'Gammon: 2 points'],
      strategyTips: [
        'Build πόρτες (points) — 2+ checkers protect each other',
        'Construct primes (πρίμα) — consecutive blocked points trap the opponent',
        'Keep an anchor in opponent\'s home board as a safety net',
        'Balance between racing and blocking',
      ],
      uniquePoints: [
        'No hit-and-run distinguishes it from international backgammon',
        'Winner re-rolls first turn rather than using opening dice',
        'No backgammon (3×) scoring simplifies stakes',
      ],
    ),
    Lesson(
      id: 'tavli_plakoto',
      title: 'Plakoto',
      nativeTitle: 'Πλακωτό',
      mechanicFamily: MechanicFamily.pinning,
      tradition: Tradition.tavli,
      variant: GameVariant.plakoto,
      icon: Icons.push_pin,
      botDialogue:
          'In Plakoto, you don\'t hit — you PIN! Land on a single '
          'opponent checker and trap it. And watch out for the μάνα!',
      setup: 'All 15 checkers on your 1-point (players at opposite corners)',
      coreMechanic: [
        'Land on a single opponent checker to PIN it in place',
        'Pinned checkers cannot move until the pinning checker leaves',
        'Two of your checkers on a point blocks it completely',
        'No hitting — checkers are never sent to the bar',
      ],
      specialRules: [
        'Mother piece (μάνα): your last checker on the starting point',
        'If opponent pins your mother → you LOSE immediately (2 points)',
        'If both mothers are pinned simultaneously → draw',
      ],
      scoring: [
        'Single: 1 point',
        'Gammon: 2 points',
        'Mother pinned: 2 points (immediate loss)',
      ],
      strategyTips: [
        'Rush your mother (μάνα) off the starting point early',
        'Pin opponent checkers near their home board to slow bearing off',
        'Spread your checkers to control multiple points',
        'Two checkers on a point creates an unbreakable block',
      ],
      uniquePoints: [
        'The mother piece mechanic creates intense early-game tension',
        'Pinning rather than hitting creates a fundamentally different feel',
        'No bar means no re-entry — simpler flow, deeper positional play',
      ],
    ),
    Lesson(
      id: 'tavli_fevga',
      title: 'Fevga',
      nativeTitle: 'Φεύγα',
      mechanicFamily: MechanicFamily.running,
      tradition: Tradition.tavli,
      variant: GameVariant.fevga,
      icon: Icons.directions_run,
      botDialogue:
          'Fevga is the race! No hitting, no pinning. '
          'Just block your opponent and run for the finish!',
      setup: 'All 15 checkers on one point (players at diagonal corners)',
      coreMechanic: [
        'A single checker controls the entire point — blocks opponents',
        'Cannot land on any point occupied by even one opponent checker',
        'No hitting, no pinning — pure blocking and racing',
      ],
      specialRules: [
        'Both players move in the SAME direction (counterclockwise)',
        'Must advance first checker past opponent\'s start before moving a second',
        'Cannot create 6+ consecutive blocked points trapping opponent',
        'Cannot block all 6 starting quadrant points unless opponent passed through',
      ],
      scoring: ['Single: 1 point', 'Gammon: 2 points'],
      strategyTips: [
        'Spread checkers early to claim key points along opponent\'s path',
        'Build partial primes (5 consecutive) to slow the opponent',
        'Race when ahead in pip count, block when behind',
        'The advancement rule makes your first moves critical',
      ],
      uniquePoints: [
        'Same-direction movement creates a unique parallel race dynamic',
        'A single checker is both a blocker and vulnerable to being stranded',
        'Pure positional game — no captures of any kind',
      ],
    ),
    Lesson(
      id: 'tavli_marathon',
      title: 'The Tavli Marathon',
      tradition: Tradition.tavli,
      icon: Icons.emoji_events,
      botDialogue:
          'In Greece, we play all three in a row — Πόρτες, Πλακωτό, Φεύγα! '
          'That\'s the real Tavli. First to reach the target score wins.',
      coreMechanic: [
        'Play Portes, Plakoto, and Fevga in rotation',
        'Each game awards points: 1 for single, 2 for gammon/mother',
        'First player to reach target score (3, 5, or 7 points) wins',
      ],
      specialRules: [
        'Games rotate: Portes → Plakoto → Fevga → Portes → …',
        'This is how Tavli is traditionally played in Greek kafeneia',
      ],
      scoring: [
        'Each game awards 1 or 2 points',
        'Marathon ends when a player reaches the target score',
      ],
      strategyTips: [
        'Mastering all three variants is what makes a true tavli player',
        'Adapt strategy when the variant rotates — hitting ≠ pinning ≠ running',
      ],
      uniquePoints: [
        'The marathon format is unique to Greek tradition',
        'It tests versatility rather than mastery of a single game',
      ],
    ),
  ],
);

// ── Tavla (Turkey) ──────────────────────────────────────────────

const _tavlaSection = LessonSection(
  id: 'tavla',
  title: 'Tavla',
  type: LessonSectionType.tradition,
  tradition: Tradition.tavla,
  prerequisiteSectionId: 'foundation',
  lessons: [
    Lesson(
      id: 'tavla_tavla',
      title: 'Tavla',
      nativeTitle: 'Tavla',
      mechanicFamily: MechanicFamily.hitting,
      tradition: Tradition.tavla,
      variant: GameVariant.tavla,
      icon: Icons.gavel,
      botDialogue:
          'Tavla is the Turkish classic — same rules as Greek Portes. '
          'Hit your opponent\'s blots and race home!',
      setup: 'Standard backgammon: 2 on 24-pt, 5 on 13-pt, 3 on 8-pt, 5 on 6-pt',
      coreMechanic: [
        'Hit lone opponent checkers to send them to the bar',
        'Hit checkers must re-enter through opponent\'s home board',
        'No hit-and-run allowed in home board',
      ],
      specialRules: [
        'Winner of opening roll re-rolls both dice',
        'A gammon is called a "mars" in Turkish',
      ],
      scoring: ['Single: 1 point', 'Mars (gammon): 2 points'],
      strategyTips: [
        'Same strategies as Portes — build points, avoid blots',
        'Blocking opponent\'s re-entry is powerful',
      ],
      uniquePoints: [
        'Functionally identical to Greek Portes',
        'Part of the Turkish coffee-house gaming tradition',
      ],
    ),
    Lesson(
      id: 'tavla_tapa',
      title: 'Tapa',
      nativeTitle: 'Tapa',
      mechanicFamily: MechanicFamily.pinning,
      tradition: Tradition.tavla,
      variant: GameVariant.tapa,
      icon: Icons.push_pin,
      botDialogue:
          'Tapa is like Plakoto — you pin instead of hit. '
          'But here, there is no mother piece rule!',
      setup: 'All 15 checkers on one point (opposite corners)',
      coreMechanic: [
        'Land on a single opponent checker to PIN it in place',
        'Pinned checkers cannot move until the pinning checker leaves',
        'No hitting — pinning only',
      ],
      specialRules: [
        'NO mother piece rule — pinning the last checker on start is NOT an auto-loss',
        'This is the key difference from Greek Plakoto',
      ],
      scoring: ['Single: 1 point', 'Mars (gammon): 2 points'],
      strategyTips: [
        'More defensive and patient than Plakoto — no mother pressure',
        'Focus on controlling key points along opponent\'s path',
        'Pin multiple checkers to create impassable barriers',
        'No urgency to clear the starting point',
      ],
      uniquePoints: [
        'Absence of mother piece rule creates a more relaxed, strategic game',
        'Players can leave their last checker on start without risk',
        'The key distinguishing rule between Tapa and Plakoto',
      ],
    ),
    Lesson(
      id: 'tavla_moultezim',
      title: 'Moultezim',
      nativeTitle: 'Moultezim',
      mechanicFamily: MechanicFamily.running,
      tradition: Tradition.tavla,
      variant: GameVariant.moultezim,
      icon: Icons.directions_run,
      botDialogue:
          'Moultezim is pure racing with blocking. '
          'No captures, just outrun your opponent!',
      setup: 'All 15 checkers on one point (diagonal corners)',
      coreMechanic: [
        'Single checker blocks the entire point — no hitting',
        'Cannot land on any point occupied by an opponent checker',
        'Both players move in the same direction',
      ],
      specialRules: [
        'Must advance first checker past opponent\'s start before spreading',
        'Cannot create 6+ consecutive blocked points trapping opponent',
      ],
      scoring: ['Single: 1 point', 'Gammon: 2 points'],
      strategyTips: [
        'Same strategies as Fevga — spread early, build partial primes',
        'Race when ahead, block when behind',
      ],
      uniquePoints: [
        'Functionally identical to Greek Fevga',
        'Turkish name for the same running game',
      ],
    ),
    Lesson(
      id: 'tavla_gul_bara',
      title: 'Gul Bara',
      nativeTitle: 'Gül Bara',
      mechanicFamily: MechanicFamily.running,
      tradition: Tradition.tavla,
      variant: GameVariant.gulBara,
      icon: Icons.auto_awesome,
      botDialogue:
          'Gul Bara is Fevga with a twist — cascading doubles! '
          'After the third roll, doubles trigger a chain reaction '
          'that can give you up to 24 moves!',
      setup: 'All 15 checkers on one point (diagonal corners)',
      coreMechanic: [
        'Same base rules as Fevga/Moultezim — single blocks, no hitting',
        'Both players move in the same direction',
        'Rolls 1–3: doubles work normally (4 moves)',
        'Roll 4+: cascading doubles — 4 of that number plus 4 of every higher number through 6',
      ],
      specialRules: [
        'Cascade example: rolling 2-2 after roll 3 = four 2s + four 3s + four 4s + four 5s + four 6s = 20 moves',
        'Rolling 1-1 after roll 3 = 24 moves (four of every number 1–6)',
        'If any portion of the cascade cannot be fully played (all 4), the cascade ends immediately',
        'Same advancement rule and prime restrictions as Fevga/Moultezim',
      ],
      scoring: ['Single: 1 point', 'Gammon: 2 points'],
      strategyTips: [
        'Early game plays normally — cascading doubles matter in mid/late game',
        'Position checkers to maximize cascade utilization',
        'Block opponent\'s cascade paths to force early termination',
        'A well-timed 1-1 after roll 3 can nearly bear off your entire set',
      ],
      uniquePoints: [
        'The only variant where a single roll can produce up to 24 moves',
        'Creates dramatic, high-variance moments that can swing the game',
        'The 3-roll warmup period prevents immediate cascade chaos',
        'Also known as "Crazy Narde"',
      ],
    ),
  ],
);

// ── Nardy (Russia / Caucasus) ───────────────────────────────────

const _nardySection = LessonSection(
  id: 'nardy',
  title: 'Nardy',
  type: LessonSectionType.tradition,
  tradition: Tradition.nardy,
  prerequisiteSectionId: 'foundation',
  lessons: [
    Lesson(
      id: 'nardy_long_nard',
      title: 'Long Nard',
      nativeTitle: 'Длинные нарды',
      mechanicFamily: MechanicFamily.running,
      tradition: Tradition.nardy,
      variant: GameVariant.longNard,
      icon: Icons.looks_one,
      botDialogue:
          'In Long Nard, all pieces start on one point — the "head." '
          'You can only move one piece off the head per turn!',
      setup: 'All 15 checkers on the "head" point (diagonal corners)',
      coreMechanic: [
        'No hitting — a single checker blocks the point',
        'Both players move in the same direction (counterclockwise)',
        'Head rule: only ONE checker may leave the head per turn',
      ],
      specialRules: [
        'First turn exception: 3-3, 4-4, or 6-6 allows two off the head',
        'If only one die can be played, the larger die must be used',
        'Cannot build a 6-prime trapping all opponent checkers',
        'Winner does NOT re-roll — uses opening dice directly',
      ],
      scoring: ['Oyn (single): 1 point', 'Mars (gammon): 2 points'],
      strategyTips: [
        'The head rule makes opening moves critical — deploy wisely',
        'Spread early to claim key points before the opponent does',
        'Build partial primes (up to 5 consecutive) to restrict movement',
        'The first-turn exception for 3-3/4-4/6-6 gives a development advantage',
      ],
      uniquePoints: [
        'The head rule creates a unique "slow deployment" dynamic',
        'The specific double exceptions (3-3, 4-4, 6-6) are unique to Long Nard',
        'Extremely popular across Russia, Caucasus, Central Asia, and Iran',
      ],
    ),
    Lesson(
      id: 'nardy_short_nard',
      title: 'Short Nard',
      nativeTitle: 'Короткие нарды',
      mechanicFamily: MechanicFamily.hitting,
      tradition: Tradition.nardy,
      variant: GameVariant.shortNard,
      icon: Icons.casino,
      botDialogue:
          'Short Nard is international backgammon with the doubling cube. '
          'This is where strategy meets stakes!',
      setup: 'Standard backgammon: 2 on 24-pt, 5 on 13-pt, 3 on 8-pt, 5 on 6-pt',
      coreMechanic: [
        'Hit lone opponent checkers — standard backgammon',
        'Hit-and-run IS allowed — hit and continue past',
        'Doubling cube in play (2×, 4×, 8× … up to 64×)',
      ],
      specialRules: [
        'Jacoby rule: gammon/backgammon only count if cube was used',
        'Beaver: immediately re-double after accepting a double',
        'Backgammon (3×) scoring when opponent has checker on bar or in your home',
        'Winner does NOT re-roll opening dice',
      ],
      scoring: [
        'Single: 1 point',
        'Gammon: 2 points',
        'Backgammon: 3 points',
        'All multiplied by cube value',
      ],
      strategyTips: [
        'Cube management is the defining skill — know when to double and accept',
        'Accept a double if you estimate ≥25% winning chances',
        'The Jacoby rule incentivizes doubling (otherwise gammons don\'t count)',
        'Hit-and-run allows aggressive hitting in the home board',
      ],
      uniquePoints: [
        'Most strategically complex variant due to the doubling cube',
        'Closest to international tournament backgammon (USBGF/WBF rules)',
        'Beaver rule adds an extra layer of bluffing and counter-play',
      ],
    ),
  ],
);

// ── Shesh Besh (Israel / Arab World) ────────────────────────────

const _sheshBeshSection = LessonSection(
  id: 'shesh_besh',
  title: 'Shesh Besh',
  type: LessonSectionType.tradition,
  tradition: Tradition.sheshBesh,
  prerequisiteSectionId: 'foundation',
  lessons: [
    Lesson(
      id: 'shesh_besh_shesh_besh',
      title: 'Shesh Besh',
      nativeTitle: 'שש בש',
      mechanicFamily: MechanicFamily.hitting,
      tradition: Tradition.sheshBesh,
      variant: GameVariant.sheshBesh,
      icon: Icons.speed,
      botDialogue:
          'Shesh Besh is fast and aggressive! You can hit '
          'an opponent and keep moving — no stopping required.',
      setup: 'Standard backgammon: 2 on 24-pt, 5 on 13-pt, 3 on 8-pt, 5 on 6-pt',
      coreMechanic: [
        'Hit lone opponent checkers to send them to the bar',
        'Hit-and-run IS allowed — hit a blot and continue moving past',
        'This makes gameplay faster and more aggressive',
      ],
      specialRules: [
        'Winner of opening roll re-rolls both dice',
        'Hit-and-run makes blocking more important since hits are easier',
      ],
      scoring: ['Single: 1 point', 'Gammon: 2 points'],
      strategyTips: [
        'Hit-and-run allows aggressive play — hit and immediately advance',
        'Blocking is more important since hits are easier to execute',
        'Fast-paced gameplay rewards tactical awareness',
        'Don\'t leave blots in areas the opponent can hit-and-run through',
      ],
      uniquePoints: [
        'Hit-and-run is the defining rule — faster than Portes/Tavla',
        'The name means "six-five" — the best opening roll',
        'Most popular variant in Israel and across the Arab world',
      ],
    ),
    Lesson(
      id: 'shesh_besh_mahbusa',
      title: 'Mahbusa',
      nativeTitle: 'محبوسة',
      mechanicFamily: MechanicFamily.pinning,
      tradition: Tradition.sheshBesh,
      variant: GameVariant.mahbusa,
      icon: Icons.push_pin,
      botDialogue:
          'Mahbusa means "imprisoned" — and that\'s what you do! '
          'Pin your opponent\'s lone checkers to trap them.',
      setup: 'All 15 checkers on one point (opposite corners)',
      coreMechanic: [
        'Land on a single opponent checker to PIN it (no hitting)',
        'Pinned checkers cannot move until the pinning checker leaves',
        'Two of your checkers on a point blocks it completely',
      ],
      specialRules: [
        'Mother piece rule: pinning opponent\'s last checker on start = 2 points (immediate loss)',
        'Both mothers pinned = draw',
        'Same mechanic as Greek Plakoto from the Arabic tradition',
      ],
      scoring: [
        'Single: 1 point',
        'Gammon: 2 points',
        'Mother pinned: 2 points (immediate loss)',
      ],
      strategyTips: [
        'Rush your mother off the starting point early',
        'Pin opponent checkers near their home to slow bearing off',
        'Same strategies as Plakoto apply here',
      ],
      uniquePoints: [
        'Functionally identical to Plakoto (including mother piece rule)',
        'The name "Mahbusa" (محبوسة) literally means "imprisoned"',
        'Arabic backgammon tradition, played across the Levant and North Africa',
      ],
    ),
  ],
);
