# Store & Monetization Plan

## Executive Summary

Shift from "choose your board during onboarding" to a **default board for all users** with a **cosmetic store** for purchasing boards, dice, checkers, table backgrounds, and avatar frames. This creates a revenue stream while simplifying onboarding.

---

## 1. Current State Analysis

### Onboarding (6 screens)
| Screen | Content | Action |
|--------|---------|--------|
| 1. Welcome | App branding | None |
| 2. Tradition | Pick cultural variant (Tavli/Tavla/Nardy/Shesh Besh) | Saves tradition |
| 3. **Board Selection** | Carousel of 3 tradition-specific boards | Saves boardSet (1-3) |
| 4. Opponent | Pick bot personality | Saves botPersonality |
| 5. Language Level | Immersion slider (0-1) | Saves languageLevel |
| 6. Ready | Confirmation + Learn to Play option | Marks onboarding complete |

### Existing Shop Infrastructure (already built)
- **Route:** `/shop` with `ShopScreen` UI (grid tabs by category)
- **ShopService:** Coin wallet (starts at 100), purchase tracking, `SharedPreferences` persistence
- **13 items defined:** 4 boards, 3 checkers, 2 dice, 3 tables, 2 avatar frames
- **Coin pricing:** 200-1000 coins per item
- **Premium placeholders:** 3 items have `iapProductId` fields (Byzantine Gold board, Gold & Silver checkers, Palace Floor table)
- **IAP not implemented:** No `in_app_purchase` package, TODO comment in shop_screen.dart

### Existing Customization
- **Customization tab** in bottom nav with board/checker/dice selection (3 free sets each)
- **Board rendering** is procedural (Canvas-based, not image-based) via `BoardComponent.setBoardSet()`
- **Gap:** Dice set selection exists in UI/settings but is NOT wired to `DiceComponent`
- **Gap:** Online game doesn't pass `checkerSet` to game engine

---

## 2. Proposed Changes

### 2.1 Onboarding Simplification

**Remove Screen 3 (Board Selection)** entirely. New flow:

| Screen | Content | Change |
|--------|---------|--------|
| 1. Welcome | App branding | No change |
| 2. Tradition | Pick cultural variant | No change |
| 3. Opponent | Pick bot personality | Was screen 4 |
| 4. Language Level | Immersion slider | Was screen 5 |
| 5. Ready | Confirmation + CTA to shop | Was screen 6; add "Visit the Shop" teaser |

**Result:** 5 screens instead of 6. Faster onboarding. Board defaults to Set 1 for the user's tradition.

### 2.2 Default Board Strategy

Every user starts with **Board Set 1** (the classic for their tradition):
- Tavli: Μαόνι (Mahogany & Olive)
- Tavla: Sultanahmet (Cedar & Crimson)
- Nardy: Кавказ (Birch & Burgundy)
- Shesh Besh: ירושלים (Olive & Sandstone)

Sets 2 and 3 (currently free) become **earnable/purchasable** through the shop.

### 2.3 Store Enhancement

#### Item Tiers
| Tier | How to Get | Examples |
|------|-----------|----------|
| **Default** | Free at start | Board Set 1, Checker Set 1, Default dice |
| **Earnable** | Coins from challenges/achievements | Board Sets 2-3, Checker Sets 2-3, Dice Sets 2-3 (200-400 coins) |
| **Premium** | Real money (IAP) or high coin cost | Marble Palace board, Gold & Silver checkers, Crystal dice (500-1000 coins OR $1.99-$4.99) |
| **Exclusive** | IAP only | Byzantine Gold board, Palace Floor table ($4.99-$9.99) |

#### Revenue Model Options
| Model | Pros | Cons |
|-------|------|------|
| **Cosmetic-only IAP** | No pay-to-win complaints, ethical | Lower revenue ceiling |
| **Coin packs** | Flexible, players choose what to buy | Can feel grindy |
| **Bundles** | Higher average purchase | Complex to manage |
| **Season pass** | Recurring revenue | Needs ongoing content |

**Recommended:** Start with **cosmetic IAP + coin packs**, expand to bundles later.

#### Suggested IAP Products
| Product ID | Name | Price | Contents |
|------------|------|-------|----------|
| `com.tavli.coins.500` | Coin Pouch | $0.99 | 500 coins |
| `com.tavli.coins.1200` | Coin Bag | $1.99 | 1,200 coins (20% bonus) |
| `com.tavli.coins.3000` | Coin Chest | $4.99 | 3,000 coins (20% bonus) |
| `com.tavli.board.byzantine` | Byzantine Gold Board | $4.99 | Exclusive board |
| `com.tavli.bundle.starter` | Starter Bundle | $2.99 | 1 premium board + 1 checker set + 500 coins |
| `com.tavli.bundle.royal` | Royal Collection | $9.99 | All premium items |

### 2.4 Customization Tab Transformation

The existing **Customize** bottom-nav tab currently shows 3 free boards/checkers/dice. Transform it into:

- **"My Collection"** view showing owned items (equipped item highlighted)
- **"Get More" button** linking to the shop
- Locked items shown greyed with price/coin cost
- Quick-equip: tap owned item to equip

### 2.5 Coin Economy Rebalancing

| Source | Current | Proposed |
|--------|---------|----------|
| Starting coins | 100 | 50 (enough to window-shop, not buy) |
| Weekly challenge | ~50-100 coins | Keep |
| Achievement unlock | 0 coins | Add 10-50 coins per achievement |
| Win vs Bot (Easy) | 0 | 5 coins |
| Win vs Bot (Medium) | 0 | 10 coins |
| Win vs Bot (Hard) | 0 | 20 coins |
| Win online match | 0 | 15 coins |
| Daily login bonus | N/A | 10-30 coins (streak multiplier) |

**Target:** A casual player earns ~200-300 coins/week. Earnable items cost 200-400 coins (1-2 weeks). Premium items cost 500-1000 coins (3-5 weeks) or can be bought with IAP.

---

## 3. Impact Analysis

### 3.1 Files That Change

#### Onboarding (remove board pick, reorder screens)
| File | Change |
|------|--------|
| `lib/features/game/presentation/onboarding_screen.dart` | Remove `_BoardPickPage`, reorder pages from 6 to 5, update page indicators, add shop teaser to Ready page |
| `lib/shared/services/settings_service.dart` | Ensure `boardSet` defaults to 1 (already does) |

#### Shop Enhancement
| File | Change |
|------|--------|
| `lib/features/shop/presentation/shop_screen.dart` | Add IAP integration, improve UI, add "equipped" badges, purchase confirmation dialogs |
| `lib/features/shop/data/shop_items.dart` | Expand items, add coin pack products, move free Sets 2-3 into earnable tier, add `equippedItemId` tracking |
| `pubspec.yaml` | Add `in_app_purchase: ^6.x` dependency |

#### Customization Tab Rework
| File | Change |
|------|--------|
| `lib/features/customization/presentation/customization_screen.dart` | Transform to "My Collection" with owned/locked states, link to shop |

#### Game Integration Fixes (existing gaps)
| File | Change |
|------|--------|
| `lib/flame_game/components/dice_component.dart` | Accept and apply `diceSet` parameter |
| `lib/flame_game/tavli_game.dart` | Pass `diceSet` to DiceComponent |
| `lib/features/game/presentation/game_screen.dart` | Read and pass `diceSet` from settings |
| `lib/features/multiplayer/presentation/online_game_screen.dart` | Pass `checkerSet` and `diceSet` |

#### Coin Economy
| File | Change |
|------|--------|
| `lib/features/challenges/data/challenge_service.dart` | Already has coin rewards (no change needed) |
| `lib/flame_game/tavli_game.dart` or victory flow | Add coin rewards for wins |
| `lib/features/profile/data/achievements.dart` | Add coin rewards to achievement unlocks |

#### New Files
| File | Purpose |
|------|---------|
| `lib/features/shop/data/iap_service.dart` | Platform IAP wrapper (StoreKit/Google Play Billing) |
| `lib/features/shop/presentation/coin_pack_sheet.dart` | Bottom sheet for buying coin packs |

### 3.2 Pages Affected Summary

| Page | Impact | Severity |
|------|--------|----------|
| **Onboarding** | Remove board screen, add shop teaser | High |
| **Shop** | Major upgrade: IAP, equip flow, coin packs | High |
| **Customization** | Rework to "My Collection" with lock states | High |
| **Home** | Minor: maybe add coin balance display | Low |
| **Game Screen** | Wire up dice set, add win coin rewards | Medium |
| **Online Game** | Pass all cosmetic sets to engine | Medium |
| **Victory Screen** | Show coins earned | Low |
| **Settings** | No change needed | None |
| **Profile** | Add coin balance display | Low |

---

## 4. Development Plan

### Phase 1: Onboarding Simplification (1 session)
**Goal:** Remove board selection, streamline to 5 screens

- [ ] Remove `_BoardPickPage` widget and its helper classes (`_BoardInfo`, `_BoardCard`) from `onboarding_screen.dart`
- [ ] Update `_pages` list: reorder remaining screens (Welcome, Tradition, Opponent, Language, Ready)
- [ ] Update page count references (indicators, next button logic, "Get Started" trigger)
- [ ] Add shop teaser text/button to `_ReadyPage` ("Explore the Shop to customize your board")
- [ ] Verify `boardSet` defaults to 1 when no selection is made
- [ ] Test: fresh onboarding flow works end-to-end with 5 screens

### Phase 2: Lock Free Sets Behind Shop (1 session)
**Goal:** Board/checker/dice sets 2 and 3 become purchasable with coins

- [ ] Update `shop_items.dart`: add Sets 2-3 as earnable items (200-400 coins each)
- [ ] Update `ShopService`: add `equippedBoard`, `equippedCheckers`, `equippedDice` tracking
- [ ] Add `isOwned()` checks in customization screen — grey out unowned items
- [ ] Add "Buy" flow: tap locked item → confirm purchase → deduct coins → unlock
- [ ] Transform Customization tab to "My Collection" layout with owned/locked states
- [ ] Add "Get More" button linking to `/shop`

### Phase 3: Fix Existing Cosmetic Gaps (1 session)
**Goal:** All cosmetic selections actually work in-game

- [ ] Wire `diceSet` through: `SettingsService` → `GameScreen` → `TavliGame` → `DiceComponent`
- [ ] Add `DiceComponent.setDiceSet(int)` method with 3 color palettes
- [ ] Pass `checkerSet` and `diceSet` in `OnlineGameScreen`
- [ ] Test all 3 sets render correctly for boards, checkers, and dice

### Phase 4: Coin Economy (1 session)
**Goal:** Players earn coins through gameplay

- [ ] Add coin rewards to victory flow (5/10/20 coins by difficulty)
- [ ] Add coin rewards to achievement unlocks (10-50 coins each)
- [ ] Add daily login bonus system (10-30 coins with streak)
- [ ] Add coin balance display to home screen header
- [ ] Add coin balance to shop screen header (already partially there)
- [ ] Reduce starting coins from 100 to 50
- [ ] Add coin reward animation/toast on earn

### Phase 5: In-App Purchases (1-2 sessions)
**Goal:** Real money purchases work on iOS and Android

- [ ] Add `in_app_purchase` package to pubspec.yaml
- [ ] Create `IapService` wrapper for StoreKit / Google Play Billing
- [ ] Define products in App Store Connect and Google Play Console
- [ ] Implement coin pack purchase flow (bottom sheet with 3 tiers)
- [ ] Implement direct premium item purchase flow
- [ ] Add purchase restoration mechanism
- [ ] Add receipt validation (server-side recommended, can start client-side)
- [ ] Handle edge cases: pending purchases, failed transactions, refunds
- [ ] Test on both platforms

### Phase 6: Polish & Analytics (1 session)
**Goal:** Track monetization metrics, polish UX

- [ ] Add analytics events: shop_viewed, item_purchased, coins_earned, iap_initiated, iap_completed
- [ ] Add purchase confirmation dialogs with item preview
- [ ] Add "New!" badges on recently added shop items
- [ ] Add bundle offers UI
- [ ] Add coin balance animation (counting up/down)
- [ ] Smoke test full flow: onboard → play → earn coins → browse shop → buy item → equip → see in game

---

## 5. Platform Requirements

### App Store (iOS)
- Configure products in App Store Connect
- Implement StoreKit 2 via `in_app_purchase` package
- Review guidelines: cosmetic-only IAP is safe (no loot boxes, no pay-to-win)
- Need privacy policy update for purchases

### Google Play (Android)
- Configure products in Google Play Console
- Implement Google Play Billing via `in_app_purchase` package
- Comply with Families Policy if targeting under-13 (backgammon likely exempt)

### Both Platforms
- Server-side receipt validation recommended for production
- Restore purchases button required (iOS App Store requirement)
- Clear pricing display in local currency

---

## 6. Risk Considerations

| Risk | Mitigation |
|------|------------|
| Users upset free boards are now locked | Grandfather existing users: if `boardSet != 1` in settings, grant that set for free |
| Coin economy too generous (no IAP needed) | Start conservative, tune based on data |
| Coin economy too stingy (feels pay-to-win) | Ensure all gameplay-relevant items stay free; only cosmetics cost money |
| IAP review rejection | Cosmetic-only is safest category; follow platform guidelines exactly |
| Refund abuse | Server-side receipt validation in Phase 5+ |

---

## 7. Success Metrics

| Metric | Target |
|--------|--------|
| Onboarding completion rate | Increase by 10-15% (fewer screens = less drop-off) |
| Shop visit rate | >30% of active users visit shop within first week |
| Conversion rate (free → paid) | 2-5% of active users make at least one purchase |
| Average revenue per paying user | $3-5 in first month |
| Coin earn rate | ~250 coins/week for active casual player |
