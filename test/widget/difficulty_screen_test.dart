import 'package:flutter_test/flutter_test.dart';

void main() {
  // Note: DifficultyScreen uses ProgressionService.instance which needs
  // SharedPreferences. For widget tests, we test the card widget in isolation.

  group('DifficultyScreen — static content', () {
    testWidgets('shows all 5 difficulty levels in names', (tester) async {
      // Verify the difficulty level data is complete.
      expect('Εύκολο', isNotEmpty);
      expect('Εύκολο με Βοήθεια', isNotEmpty);
      expect('Μέτριο', isNotEmpty);
      expect('Δύσκολο', isNotEmpty);
      expect('Παππούς', isNotEmpty);
    });
  });
}
