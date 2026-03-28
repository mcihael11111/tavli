# Onboarding Redesign: History, Culture, Language

## Problem

1. **No username input** — Players default to "Player" or their Google account name. No opportunity to set a custom display name during onboarding.
2. **No historical context** — The app says "One game. Many cultures." but never explains WHY the same game exists across Greece, Turkey, Russia, and Israel. The tradition selection feels arbitrary without understanding the shared history.
3. **Flow order** — The current flow jumps straight from "Welcome" to "Pick your tradition" without context. History should come first to create an emotional connection before the user chooses their culture.

## Current Onboarding (5 screens)

```
1. Welcome → 2. Tradition → 3. Personality → 4. Language → 5. Ready
```

## Proposed Onboarding (7 screens)

```
1. Welcome → 2. Username → 3. History → 4. Tradition → 5. Language → 6. Personality → 7. Ready
```

### Flow Rationale

| Order | Screen | Why here |
|-------|--------|----------|
| 1 | **Welcome** | Brand moment, set the tone |
| 2 | **Username** | Personal identity first — "Who are you?" before "Where do you play?" |
| 3 | **History** | Build emotional context — show the 5,000-year journey before asking the user to pick a branch of it |
| 4 | **Tradition** | Now the user understands WHY these 4 traditions exist — the choice is meaningful |
| 5 | **Language** | Directly follows tradition — "How deep into this culture do you want to go?" |
| 6 | **Personality** | Pick your opponent within your chosen tradition |
| 7 | **Ready** | Summary + shop teaser + Learn to Play |

---

## Screen Designs

### Screen 2: Username (NEW)

**Title:** "What Should We Call You?"

**Content:**
- Text field with 20-character limit
- Placeholder: tradition-neutral (e.g., "Enter your name")
- Validation: 2-20 characters, no empty
- Subtle note: "This is how others see you in online games."

**Persistence:**
- Save to `SettingsService` as `playerDisplayName`
- When user later signs in for online play, use this as the Firestore `displayName` instead of defaulting to "Player"

### Screen 3: History of Tables (NEW)

A single scrollable narrative screen with an illustrated timeline feel. The text should be warm and brief — not a history textbook, but a storytelling moment.

**Title:** "5,000 Years of Play"

**Narrative (3 beats):**

**Beat 1 — Ancient Origins**
> Long before borders were drawn, people played. In ancient Mesopotamia, around 3000 BCE, the Royal Game of Ur was carved into stone — the ancestor of every backgammon board.

**Beat 2 — The Silk Road Spread**
> The game traveled with traders, soldiers, and sailors. The Romans called it Tabula. The Persians called it Takht-e Nard. In medieval Europe it became "Tables" — the name that stuck for centuries.

**Beat 3 — Living Traditions**
> Today, the same game lives in kafeneia in Athens, tea houses in Istanbul, dachas in Moscow, and shuk stalls in Jerusalem. Same board. Same dice. Different names, different rules, different souls.

**Visual treatment:**
- Warm, muted color palette consistent with app aesthetic
- Each beat could be a section with an icon (ancient tablet, compass/route, four flags)
- No interactive elements — this is a reading moment
- "Next" button at the bottom as usual

**Transition to Tradition screen:**
The last line ("Different names, different rules, different souls.") naturally leads to "Which tradition is yours?"

---

## Impact Analysis

### Files Changed

| File | Change |
|------|--------|
| `onboarding_screen.dart` | Add 2 new page widgets, reorder to 7 screens, update `_pageCount` |
| `settings_service.dart` | Add `playerDisplayName` getter/setter |
| `auth_provider.dart` | Use `SettingsService.playerDisplayName` when creating Firestore profile instead of 'Player' |
| `player_profile.dart` | No change (already has displayName field) |
| `profile_screen.dart` | Show saved display name instead of "Player" |

### Files NOT Changed

| File | Reason |
|------|--------|
| `game_room.dart` | Already accepts name from PlayerProfile |
| `matchmaking_screen.dart` | Already reads from PlayerProfile |
| `online_game_screen.dart` | Already displays from GameRoom |

---

## Development Plan

### Phase 1: Add Username Screen (1 session)

- [ ] Add `playerDisplayName` to `SettingsService` (key: `tavli_player_name`, default: `''`)
- [ ] Create `_UsernamePage` widget in `onboarding_screen.dart`
  - TextFormField with warm styling matching app aesthetic
  - 2-20 character validation
  - Saves to `SettingsService.instance.playerDisplayName` on change
- [ ] Insert as screen 2, update `_pageCount` to 7
- [ ] Reorder pages: Welcome, Username, History, Tradition, Language, Personality, Ready
- [ ] Update `auth_provider.dart`: when creating new PlayerProfile, use `SettingsService.instance.playerDisplayName` if non-empty, otherwise fall back to `user?.displayName ?? 'Player'`
- [ ] Update `profile_screen.dart`: show `playerDisplayName` if available

### Phase 2: Add History Screen (1 session)

- [ ] Create `_HistoryPage` widget in `onboarding_screen.dart`
  - Scrollable content with 3-beat narrative
  - Warm typography using Playfair Display for headings
  - Section icons for each era
  - Subtle background color differentiation per beat
- [ ] Write final copy for all 3 beats (Ancient Origins, Silk Road Spread, Living Traditions)
- [ ] Insert as screen 3

### Phase 3: Reorder Language Before Personality (1 session)

- [ ] Move `_LanguageLevelPage` to screen 5 (after Tradition, before Personality)
- [ ] Verify tradition change callback still resets language examples correctly
- [ ] Update all screen number comments
- [ ] Test full 7-screen flow end to end

### Phase 4: Build and Verify (included in each phase)

- [ ] `flutter analyze` passes clean
- [ ] Fresh install onboarding works end to end
- [ ] Username persists and shows in profile
- [ ] History screen scrolls and reads well
- [ ] Skip button still works from any screen
