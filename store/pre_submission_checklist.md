# Pre-Submission Checklist

## Functional Testing
- [ ] All 21 non-double opening rolls produce legal moves
- [ ] All 6 double opening rolls produce legal moves
- [ ] Bar entry works correctly (P1 and P2)
- [ ] Bar entry blocks turn when all points are blocked
- [ ] Bearing off with exact die value
- [ ] Bearing off with higher die (no higher point occupied)
- [ ] Cannot bear off with checkers outside home board
- [ ] Mandatory play: both dice used when possible
- [ ] Mandatory play: larger die used when only one possible
- [ ] Doubles give exactly 4 moves
- [ ] Partial doubles handled correctly
- [ ] Hit sends checker to bar
- [ ] Gammon detected correctly (0 borne off)
- [ ] Backgammon detected correctly (checker on bar or in winner's home)
- [ ] Doubling cube offer/accept/refuse flow
- [ ] Cube ownership tracked correctly
- [ ] Undo works within turn
- [ ] Undo restores board state exactly
- [ ] AI plays legal moves at all difficulty levels
- [ ] AI difficulty feels appropriate per level
- [ ] Mikhail dialogue triggers at correct events
- [ ] Dialogue cooldown prevents spam
- [ ] Game over screen shows correct result
- [ ] New game resets all state

## UI/UX Testing
- [ ] Home screen renders correctly
- [ ] Difficulty selection shows all 5 levels
- [ ] Board renders in landscape
- [ ] Board renders in portrait
- [ ] Checkers display correctly on all 24 points
- [ ] Checker stacking works (5+ checkers per point)
- [ ] Move highlights show die values
- [ ] Hit highlights shown in different color
- [ ] Dice display with pip rendering
- [ ] "Tap to roll" prompt appears at turn start
- [ ] Used dice appear dimmed
- [ ] Splash screen animates and navigates
- [ ] Bottom navigation works across all tabs
- [ ] Settings persist between sessions
- [ ] Customization preview shows selections
- [ ] Tutorial progresses through all 5 lessons
- [ ] Victory screen shows score breakdown
- [ ] Pause menu works (resume, new game, exit)

## Platform Testing
- [ ] Android back button handled correctly
- [ ] App survives backgrounding/foregrounding
- [ ] Orientation changes handled
- [ ] No crashes on app launch
- [ ] No ANRs during AI thinking
- [ ] Minimum SDK 26 (Android 8.0)
- [ ] Target SDK 34

## Performance
- [ ] App launches in < 2 seconds
- [ ] Game board renders at 60fps
- [ ] AI move < 3 seconds at highest difficulty
- [ ] No memory leaks during extended play
- [ ] App size < 80MB

## Accessibility
- [ ] Touch targets >= 48dp
- [ ] Color contrast >= 4.5:1 for text
- [ ] Move indicators use shape + color (not color alone)
- [ ] Screen reader labels on interactive elements

## Store Requirements
- [ ] App icon 1024x1024 (adaptive icon for Android)
- [ ] Screenshots: phone (2-3) + tablet (optional)
- [ ] Feature graphic 1024x500 (Google Play)
- [ ] Short description <= 80 chars
- [ ] Full description <= 4000 chars
- [ ] Privacy policy URL accessible
- [ ] Content rating questionnaire completed
- [ ] Data safety form completed
- [ ] Target API level 34+
- [ ] AAB signed with upload key
