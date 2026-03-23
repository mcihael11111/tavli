# Copy & Content

> Voice, tone, writing guidelines, Greek/English bilingual patterns, and the Mikhail character guide.
> Words are part of the design.

## Related Documents

- [Design System](01_DESIGN_SYSTEM.md) — Typography tokens for text sizing
- [Components](02_COMPONENTS.md) — Where copy appears in components
- [Accessibility](05_ACCESSIBILITY.md) — Alt text, semantic labels, screen reader text
- [Uniform Design](06_UNIFORM_DESIGN.md) — Capitalization and terminology consistency

---

## 1. Brand Voice

Tavli speaks like a **knowledgeable friend setting up the board** — warm, unhurried, confident, welcoming.

### Voice Attributes

| Attribute | Description | Example |
|-----------|-------------|---------|
| **Warm** | Mediterranean hospitality, never corporate | "Welcome to Tavli" not "Account created successfully" |
| **Knowledgeable** | Understands the game deeply, shares casually | "Portes is the classic" not "Mode 1 selected" |
| **Unhurried** | No urgency, no pressure | "Ready when you are" not "Start now!" |
| **Welcoming** | Inclusive of all skill levels | "Beautiful boards. Real strategy." not "For serious players" |
| **Playful** | Light humor, never sarcastic | Mikhail's personality carries this |

### Voice is NOT

| Avoid | Example |
|-------|---------|
| Corporate | "Your session has been initialized" |
| Urgent | "Don't miss out!" "Limited time!" |
| Technical | "Error code 403: Unauthorized" |
| Condescending | "It's easy, just tap here" |
| Overly casual | "lol nice move bro" |
| Sarcastic | "Oh great, another loss" |

---

## 2. Tone Spectrum

The voice is consistent; the **tone** adapts to context.

| Context | Tone | Example |
|---------|------|---------|
| Mikhail dialogue | Warm, playful, lightly competitive | "Ah, the double! Bold move." |
| Onboarding | Welcoming, guiding | "I'm Mikhail. Welcome to Tavli." |
| System UI | Neutral, clear | "Settings" "Choose difficulty" |
| Errors | Calm, helpful, solution-oriented | "Couldn't connect. Check your connection and try again." |
| Victory | Celebratory, generous | "Well played! A deserved victory." |
| Defeat | Gracious, encouraging | "Close game. Want to try again?" |
| Settings/Legal | Neutral, precise | "Sound effects volume" "Privacy policy" |

---

## 3. Writing Principles

### 3.1 Be Concise

UI text should be as short as possible without losing meaning.

| Long | Concise |
|------|---------|
| "Click here to start a new game" | "New game" |
| "Are you sure you want to delete your account?" | "Delete account? This can't be undone." |
| "Your current difficulty level is set to medium" | "Difficulty: Medium" |

### 3.2 Use Active Voice

| Passive | Active |
|---------|--------|
| "The game was saved" | "Game saved" |
| "Your move has been undone" | "Move undone" |
| "An error was encountered" | "Something went wrong" |

### 3.3 Lead with the Action

| Buried action | Action-first |
|--------------|-------------|
| "To roll the dice, tap the button" | "Tap to roll" |
| "If you want to undo, press undo" | "Undo last move" |

### 3.4 Error Messages Suggest Recovery

Every error message must include:
1. **What happened** (brief)
2. **What to do** (specific)

| Bad | Good |
|-----|------|
| "Network error" | "Couldn't connect. Check your Wi-Fi and try again." |
| "Invalid input" | "Name must be at least 2 characters." |
| "Something went wrong" | "Couldn't load your games. Pull down to refresh." |

### 3.5 No Exclamation Marks in UI

Exception: Mikhail's dialogue can use them sparingly for personality.

| With exclamation | Without |
|-----------------|---------|
| "Game saved!" | "Game saved" |
| "Your turn!" | "Your turn" |
| "Welcome!" | "Welcome" |
| Mikhail: "Bravo!" | Allowed (character voice) |

---

## 4. Greek / English Bilingual Patterns

### 4.1 Language Levels

The app adjusts Greek usage based on the user's preference (set on the "How Greek Should I Be" screen):

| Level | Greek Usage | Example |
|-------|-------------|---------|
| 1 — English only | No Greek except proper nouns | "Backgammon" "Roll dice" |
| 2 — Light Greek | Greek game terms, English UI | "Portes" "Tavli" but "Settings" |
| 3 — Mixed (default) | Greek greetings + terms, English UI | "Γεια σου" greeting, "Roll dice" |
| 4 — Mostly Greek | Greek UI where practical | "Ρίξε τα ζάρια" |
| 5 — Fluent | Full Greek UI | All strings from Greek localization |

### 4.2 Greek-Primary Content

These elements always appear in Greek regardless of level (at level 2+):

| Element | Greek | Transliteration | English |
|---------|-------|-----------------|---------|
| App greeting | Γεια σου | Yia sou | Hello |
| Game types | Πόρτες, Πλακωτό, Φεύγα | Portes, Plakoto, Fevga | — |
| Mikhail's greeting | Γεια σου, φίλε | Yia sou, file | Hello, friend |
| Victory | Μπράβο | Bravo | Well done |
| Dice roll | Ζάρια | Zaria | Dice |

### 4.3 Mikhail's Speech Patterns

Mikhail mixes Greek and English naturally:

```
Level 1: "Welcome to Tavli. Let's play!"
Level 2: "Welcome to Tavli. Ready for Portes?"
Level 3: "Γεια σου! Ready for a game of Πόρτες?"
Level 4: "Γεια σου, φίλε! Πάμε για Πόρτες;"
Level 5: "Γεια σου, φίλε! Πάμε να παίξουμε;"
```

### 4.4 Localization File Structure

```
lib/l10n/
  app_en.arb    — English strings (base)
  app_el.arb    — Greek strings (full translation)
```

String keys follow the pattern: `{screen}_{element}_{context}`
```json
{
  "home_greeting": "Γεια σου",
  "home_subtitle": "Beautiful boards. Real strategy.",
  "settings_title": "Settings",
  "game_rollDice": "Roll dice",
  "error_networkTitle": "Couldn't connect",
  "error_networkBody": "Check your connection and try again."
}
```

### 4.5 Typography for Greek Characters

- Greek text uses **Noto Sans** as fallback when Poppins lacks polytonic characters
- Font variation settings: `'CTGR' 0, 'wdth' 100, 'wght' 400` for proper rendering
- Greek text must be tested for proper rendering on all target platforms
- Right-to-left: Greek is LTR, no RTL considerations needed

---

## 5. UI Copy Guidelines by Screen

### 5.1 Onboarding Screens

| Screen | Title Style | Body Style | Tone |
|--------|-------------|------------|------|
| Welcome | H3 (32px), Greek greeting | H6 (20px) + L4 (16px) | Warm, inviting |
| Choose Boards | H3, imperative | H6, descriptive | Guiding |
| Profile Setup | H3, personal | H6, explanatory | Conversational |
| Greek Level | H3, question | H6, explanatory | Inclusive |
| Ready to Play | H3, declarative | H6, encouraging | Confident |

### 5.2 Home Screen

| Element | Copy Pattern |
|---------|-------------|
| App title | "Tavli" — always, no subtitle |
| User greeting | "{name}" or "Welcome back" |
| Game type tabs | "Πόρτες" / "Πλακωτό" / "Φεύγα" (or English equivalents per level) |
| Menu items | Title + subtitle format: "Play Mikhail" / "Challenge the AI" |

### 5.3 Settings

| Pattern | Example |
|---------|---------|
| Setting labels | Sentence case: "Sound effects" |
| Section headers | Sentence case: "Game preferences" |
| Toggle descriptions | Brief: "Show move hints" |
| Value displays | Direct: "Medium" / "On" / "50%" |

### 5.4 Error Messages

| Context | Title | Body | Action |
|---------|-------|------|--------|
| Network failure | "Couldn't connect" | "Check your connection and try again." | "Try again" |
| Load failure | "Couldn't load" | "Something went wrong. Pull down to refresh." | "Refresh" |
| Auth failure | "Couldn't sign in" | "Check your credentials and try again." | "Try again" |
| Game sync failure | "Out of sync" | "The game state couldn't be synced." | "Reconnect" |

### 5.5 Empty States

| Context | Title | Body | Action |
|---------|-------|------|--------|
| No games | "No games yet" | "Start your first game of Tavli." | "New game" |
| No friends | "No friends yet" | "Invite friends to play online." | "Invite" |
| No stats | "No stats yet" | "Play a few games to see your stats." | "Play now" |

### 5.6 Victory / Defeat

| Result | Title | Body |
|--------|-------|------|
| Win (single) | "Victory" | "Well played. A clean win." |
| Win (gammon) | "Gammon!" | "Dominant performance. Double points." |
| Win (backgammon) | "Backgammon!" | "Total victory. Triple points." |
| Loss | "Defeat" | "Close game. Ready for another?" |
| Loss (gammon) | "Gammon loss" | "Tough break. Try a different strategy?" |

---

## 6. Game Terminology Glossary

| English | Greek | Transliteration | Definition |
|---------|-------|-----------------|------------|
| Backgammon (the game) | Τάβλι | Tavli | The collective name for Greek backgammon |
| Portes | Πόρτες | Portes | Standard backgammon variant |
| Plakoto | Πλακωτό | Plakoto | Trapping variant (pin opponent) |
| Fevga | Φεύγα | Fevga | Race variant (no hitting) |
| Checker | Πούλι | Pouli | A game piece |
| Point | Θέση | Thesi | A triangle on the board |
| Bar | Μπάρα | Bara | Where hit checkers go |
| Bear off | Μάζεμα | Mazema | Removing checkers from the board |
| Double (cube) | Διπλασιασμός | Diplassiasmos | Doubling the stakes |
| Gammon | Γκαμόν | Gamon | Winning before opponent bears off any |
| Dice | Ζάρια | Zaria | The dice |
| Roll | Ρίξε | Rixe | To roll the dice |
| Your turn | Η σειρά σου | I sira sou | It's your turn |

---

## 7. Mikhail Character Guide

### 7.1 Who is Mikhail?

Mikhail is the AI opponent and guide. He is the "friend across the table."

| Attribute | Description |
|-----------|-------------|
| Personality | Warm, confident, competitive but fair, slightly theatrical |
| Knowledge | Expert backgammon player, knows all variants |
| Mood | Ranges from encouraging to playfully competitive |
| Speech | Mixes Greek and English naturally |
| Age/vibe | Experienced, like a favorite uncle who taught you the game |

### 7.2 Speech Patterns

| Pattern | Example |
|---------|---------|
| Greek greeting | "Γεια σου, φίλε!" |
| Acknowledging good move | "Ah, smart. Very smart." |
| After rolling well | "The dice favor me today." |
| After rolling poorly | "Hmm. Not ideal." |
| Offering double | "I feel confident. Double?" |
| Accepting double | "I accept. Let's see who's right." |
| Winning graciously | "Good game. You pushed me." |
| Losing graciously | "Well earned. Again?" |
| Teaching moment | "A pip count would help here." |
| Encouraging beginner | "Don't worry, everyone starts somewhere." |

### 7.3 Lines by Context

**Game start:**
- "Γεια σου! Ready for a game?"
- "Let's see what the dice have for us."
- "Set up the board. I'll go easy on you." (Easy difficulty)

**Mid-game:**
- "Interesting position..."
- "You're playing well today."
- "The bar is getting crowded." (when pieces are hit)

**Game end — Mikhail wins:**
- "Good game. You made me work for it."
- "Μπράβο... to me!" (playful)
- "Another round?"

**Game end — Mikhail loses:**
- "Well played. You earned that one."
- "I underestimated you. Rematch?"
- "The student becomes the teacher."

### 7.4 Voice line rules

1. Lines must be under 15 words (brevity)
2. Maximum one Greek phrase per line (accessibility)
3. No sarcasm toward the player
4. Never mock a player's mistake
5. Always offer a rematch after a game

---

## 8. Capitalization Rules

| Context | Rule | Example |
|---------|------|---------|
| Screen titles | Title Case | "Choose Your Boards" |
| Section headers | Sentence case | "Game preferences" |
| Button labels | Title Case | "New Game" |
| Settings labels | Sentence case | "Sound effects" |
| Body text | Sentence case | "Beautiful boards. Real strategy." |
| Error titles | Sentence case | "Couldn't connect" |
| Mikhail dialogue | Sentence case | "The dice favor me today." |
| Game terminology | Proper noun case | "Portes" "Plakoto" "Tavli" |

---

## 9. Numbers and Formatting

| Type | Format | Example |
|------|--------|---------|
| Scores | No separators under 1000 | "Score: 42" |
| Scores | Comma separator above | "Score: 1,250" |
| Percentages | No decimal for whole | "75%" |
| Time | Relative where possible | "2 minutes ago" |
| Win/loss ratio | Fraction format | "15 wins, 8 losses" |
| Dice values | Numerals | "Rolled 3 and 5" |

---

## 10. Accessibility

### 10.1 Alt Text Guidelines

| Element | Good Alt Text | Bad Alt Text |
|---------|-------------|-------------|
| Board image | "Mahogany and olive wood backgammon board" | "Image" |
| Mikhail avatar | "Mikhail, your AI opponent" | "Avatar" |
| Dice showing 3 | "Die showing 3" | "Dice" |
| Victory badge | "Victory badge: gammon win" | "Badge" |
| Board set preview | "Preview of teal wood board set" | "Board" |

### 10.2 Semantic Label Conventions

- **Describe purpose**, not appearance: "Open settings" not "Gear icon"
- **Include state**: "Sound effects, currently on" not just "Sound effects"
- **Include value**: "Difficulty: medium" not just "Difficulty"
- **Game context**: "Your checker on point 12, 3 checkers stacked" not "Checker"

### 10.3 Screen Reader Text

Screen reader text may differ from visual text when the visual relies on context:

| Visual | Screen Reader |
|--------|--------------|
| "M" (in avatar) | "Mikhail avatar" |
| "> " (chevron) | "Navigate to {destination}" |
| "3" (on die) | "Die showing 3" |
| Pagination dots | "Page 2 of 5" |

---

## 11. Uniform Design

### Terminology Consistency

- **Same concept = same word** everywhere. Don't use "match" on one screen and "game" on another for the same thing
- **Game type names** are always: Portes, Plakoto, Fevga (capitalized, no translation)
- **"Tavli"** is always capitalized, never "tavli" or "TAVLI"
- **"Mikhail"** is always spelled consistently

### Capitalization Consistency

Follow the capitalization rules table above without exception. Mixed capitalization styles on the same screen is a bug.

---

## 12. Material Design 3 Alignment

M3 content guidelines applied:

| M3 Guideline | Tavli Implementation |
|-------------|---------------------|
| Use sentence case for labels | Applied to settings, body text, errors |
| Lead with the most important information | Error messages: what happened first |
| Use familiar words | No jargon except game terminology (which is taught) |
| Keep text scannable | Short paragraphs, bullet points in onboarding |
| Indicate what a control does | Button labels are verbs: "Play", "Roll", "Undo" |
