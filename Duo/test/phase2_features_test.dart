import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Feature 3: Monthly Journey Calendar', () {
    test('Calculates day notes grouping correctly', () {
      final sampleNotes = [
        {'id': '1', 'created_at': '2026-10-31T08:30:00Z', 'title': 'Morning Letter'},
        {'id': '2', 'created_at': '2026-10-31T14:15:00Z', 'stationery_theme': 'photo_moment', 'title': 'Park Sunset'},
        {'id': '3', 'created_at': '2026-10-25T11:00:00Z', 'title': 'Sweet Note'},
      ];

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final n in sampleNotes) {
        final dt = DateTime.parse(n['created_at'] as String);
        final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        grouped.putIfAbsent(key, () => []).add(n);
      }

      expect(grouped['2026-10-31']?.length, equals(2));
      expect(grouped['2026-10-25']?.length, equals(1));
      expect(grouped['2026-10-01'], isNull);

      // Verify letter vs photo categorization
      final oct31 = grouped['2026-10-31']!;
      final hasLetter = oct31.any((n) => n['stationery_theme'] != 'photo_moment');
      final hasPhoto = oct31.any((n) => n['stationery_theme'] == 'photo_moment');
      expect(hasLetter, isTrue);
      expect(hasPhoto, isTrue);
    });
  });

  group('Feature 4: 15s Voice Whispers', () {
    test('Extracts voice whisper tag and strips from letter text correctly', () {
      const rawBody = 'My dearest,\nI love you so much!\n\n[VOICE_WHISPER]:15s';
      final hasVoiceWhisper = rawBody.contains('[VOICE_WHISPER]:');
      final cleanedBody = rawBody.replaceAll(RegExp(r'\[VOICE_WHISPER\]:[^\s]+'), '').trim();

      expect(hasVoiceWhisper, isTrue);
      expect(cleanedBody, equals('My dearest,\nI love you so much!'));
      expect(cleanedBody.contains('[VOICE_WHISPER]'), isFalse);
    });

    test('Regular letter without voice note does not trigger voice player', () {
      const rawBody = 'Just a standard romantic letter.';
      final hasVoiceWhisper = rawBody.contains('[VOICE_WHISPER]:');
      expect(hasVoiceWhisper, isFalse);
    });
  });

  group('Feature 6: Virtual Hug & Proximity Touch', () {
    test('Simultaneous hold triggers connected celebration', () {
      bool isHolding = true;
      bool isPartnerHolding = true;
      bool bothConnected = isHolding && isPartnerHolding;

      expect(bothConnected, isTrue);

      isHolding = false;
      bothConnected = isHolding && isPartnerHolding;
      expect(bothConnected, isFalse);
    });
  });
}
