# Language Level Consistency Plan

## Problem

The language level slider (0.0 = English Only, 1.0 = Fluent) is set during onboarding but only affects **bot time-of-day greetings**. All other UI copy is hardcoded English regardless of the setting. A user who selects "Fluent Greek" still sees "Play vs Bot", "Settings", "Match History", "ROLL", "PAUSE", etc. in English.

## Current State

| Surface | Uses languageLevel? | Status |
|---------|-------------------|--------|
| Bot greetings (home) | Yes (> 0.5 threshold) | Working |
| Bot dialogue (game) | No | Hardcoded bilingual mix |
| Home screen cards | No | Hardcoded English |
| Game screen buttons | No | Hardcoded English |
| Victory screen | No | Hardcoded Greek victory text only |
| Settings screen | No | Hardcoded English |
| Profile screen | No | Hardcoded English |
| Shop screen | No | Hardcoded English |
| Customization screen | No | Greek item names only |
| Challenges screen | No | Hardcoded English |
| Difficulty screen | No | Uses Greek difficulty names |

## Design: 5-Level Language Spectrum

Per `04_COPY_CONTENT.md`, the slider maps to 5 levels:

| Level | Range | UI Behavior |
|-------|-------|-------------|
| 1 | 0.0-0.15 | English only (no native except proper nouns) |
| 2 | 0.15-0.35 | Light native (game terms, greetings) |
| 3 | 0.35-0.65 | Mixed (default) — native headings, English body |
| 4 | 0.65-0.85 | Mostly native — native UI labels, mixed body |
| 5 | 0.85-1.0 | Fluent — full native language |

## Solution: `TavliCopy` Service

A centralized copy service that returns the right string based on `tradition + languageLevel`. Each string has an English and a native variant. The service interpolates between them based on the level.

### String Categories

**Category A — Always Native at Level 2+** (game terms, cultural words):
- Game variant names (Portes, Plakoto, Fevga)
- Victory/defeat (Nikh!/Itta)
- Board set names (already Greek)

**Category B — Native at Level 3+** (headings, navigation):
- Screen titles: "Settings" → "Ρυθμίσεις"
- Card titles: "Play vs Bot" → "Παίξε με Bot"
- Section headers

**Category C — Native at Level 4+** (action labels, body text):
- Button labels: "ROLL" → "ΖΑΡΙΑ"
- Menu items: "Resume" → "Συνέχεια"
- Descriptions and subtitles

**Category D — Native at Level 5 only** (full immersion):
- All remaining body text, tooltips, snackbar messages

## Strings to Localize (Per Tradition)

### Greek (Tavli)

| English | Greek | Category |
|---------|-------|----------|
| Play vs Bot | Παίξε με Bot | B |
| Challenge the AI opponent | Πρόκληση εναντίον AI | C |
| Play Online | Παίξε Online | B |
| Quick match or invite a friend | Γρήγορο παιχνίδι ή πρόσκληση | C |
| Pass & Play | Πάσα & Παίξε | B |
| Two players, one device | Δύο παίκτες, μία συσκευή | C |
| Learn to Play | Μάθε να Παίζεις | B |
| Weekly Challenges | Εβδομαδιαίες Προκλήσεις | B |
| Shop | Κατάστημα | B |
| Replay | Επανάληψη | B |
| Settings | Ρυθμίσεις | B |
| Profile | Προφίλ | B |
| My Collection | Η Συλλογή Μου | B |
| Match History | Ιστορικό Αγώνων | B |
| Achievements | Επιτεύγματα | B |
| ROLL | ΖΑΡΙΑ | C |
| COMPLETE | ΟΛΟΚΛΗΡΩΣΗ | C |
| PAUSE | ΠΑΥΣΗ | C |
| Resume | Συνέχεια | C |
| Resign | Παραίτηση | C |
| New Game | Νέο Παιχνίδι | C |
| Exit to Home | Αρχική | C |
| Victory! | Νίκη! | A |
| Defeat | Ήττα | A |
| PLAY AGAIN | ΠΑΙΞΕ ΞΑΝΑ | C |
| Bot thinking | Σκέφτεται... | C |
| Accept | Δέχομαι | C |
| Decline | Αρνούμαι | C |
| Double | Διπλασιασμός | C |
| Choose Difficulty | Επίλεξε Δυσκολία | B |
| Result | Αποτέλεσμα | C |
| Total Points | Συνολικοί Πόντοι | C |
| Coins Earned | Κέρματα | C |

### Turkish (Tavla)

| English | Turkish | Category |
|---------|---------|----------|
| Play vs Bot | Bot'a Karsi Oyna | B |
| Play Online | Online Oyna | B |
| Settings | Ayarlar | B |
| ROLL | ZAR AT | C |
| Victory! | Zafer! | A |
| Defeat | Yenilgi | A |
| PAUSE | DURAKLAT | C |
| My Collection | Koleksiyonum | B |

### Russian (Nardy)

| English | Russian | Category |
|---------|---------|----------|
| Play vs Bot | Играть с ботом | B |
| Play Online | Играть онлайн | B |
| Settings | Настройки | B |
| ROLL | КОСТИ | C |
| Victory! | Победа! | A |
| Defeat | Поражение | A |
| PAUSE | ПАУЗА | C |
| My Collection | Моя коллекция | B |

### Hebrew (Shesh Besh)

| English | Hebrew | Category |
|---------|--------|----------|
| Play vs Bot | שחק נגד בוט | B |
| Play Online | שחק אונליין | B |
| Settings | הגדרות | B |
| ROLL | הטל קוביות | C |
| Victory! | !ניצחון | A |
| Defeat | הפסד | A |
| PAUSE | השהיה | C |
| My Collection | האוסף שלי | B |

## Implementation Plan

### Phase 1: Create `TavliCopy` service
- New file `lib/shared/services/copy_service.dart`
- Contains all bilingual string pairs organized by tradition
- Single method: `String get(String key)` that returns the right string based on current `tradition` + `languageLevel`

### Phase 2: Update all screens to use `TavliCopy`
- Home screen: card titles and subtitles
- Game screen: ROLL, COMPLETE, PAUSE menu, double overlay, bot thinking
- Victory screen: headings, score labels
- Settings/Profile/Customization/Shop: screen titles
- Difficulty screen: title

### Phase 3: Verify consistency across all language levels
