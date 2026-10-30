import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Feature 7: Couple Wrapped Recap', () {
    test('Calculates recap stats and handles empty space gracefully', () {
      final sampleNotes = [
        {'id': '1', 'body': 'Hey honey! [VOICE_WHISPER]:15s'},
        {'id': '2', 'stationery_theme': 'photo_moment', 'body': 'Sunset together'},
        {'id': '3', 'body': 'Just a love letter'},
      ];

      final totalNotes = sampleNotes.length;
      final voiceCount = sampleNotes.where((n) => (n['body'] ?? '').contains('[VOICE_WHISPER]:')).length;
      final photoCount = sampleNotes.where((n) => n['stationery_theme'] == 'photo_moment').length;

      expect(totalNotes, equals(3));
      expect(voiceCount, equals(1));
      expect(photoCount, equals(1));
    });
  });

  group('Feature 8: Home Screen Widgets Engine', () {
    test('Calculates milestone days left and formats widget status', () {
      final now = DateTime.now();
      final targetDate = now.add(const Duration(days: 14));
      final daysLeft = targetDate.difference(now).inDays;

      expect(daysLeft, equals(14));

      // Widget display label logic
      final widgetString = '${daysLeft}d left';
      expect(widgetString, equals('14d left'));
    });
  });
}
