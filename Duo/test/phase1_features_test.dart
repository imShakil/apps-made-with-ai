import 'package:flutter_test/flutter_test.dart';
import 'package:duo/features/prayer/presentation/providers/prayer_provider.dart';
import 'package:duo/features/home/presentation/providers/heartbeat_provider.dart';
import 'package:duo/features/play/presentation/widgets/date_roulette_dialog.dart';

void main() {
  group('Feature 1: Couple Prayer Companion (Salah Tracker)', () {
    test('Default state has prayer tracking disabled and 5 empty prayers', () {
      const state = PrayerState();
      expect(state.isEnabled, isFalse);
      expect(state.myCompletedCount, equals(0));
      expect(state.partnerCompletedCount, equals(0));
      expect(state.bothCompletedCount, equals(0));
      expect(state.allCompletedTogether, isFalse);
      expect(PrayerNotifier.prayerKeys, equals(['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']));
    });

    test('Prayer completion and bothPrayed calculations work accurately', () {
      final state = const PrayerState().copyWith(
        isEnabled: true,
        myPrayers: {
          'fajr': true,
          'dhuhr': true,
          'asr': false,
          'maghrib': false,
          'isha': false,
        },
        partnerPrayers: {
          'fajr': true,
          'dhuhr': false,
          'asr': true,
          'maghrib': false,
          'isha': false,
        },
      );

      expect(state.myCompletedCount, equals(2));
      expect(state.partnerCompletedCount, equals(2));
      expect(state.isPrayedByMe('fajr'), isTrue);
      expect(state.isPrayedByPartner('fajr'), isTrue);
      expect(state.isBothPrayed('fajr'), isTrue);

      expect(state.isPrayedByMe('dhuhr'), isTrue);
      expect(state.isPrayedByPartner('dhuhr'), isFalse);
      expect(state.isBothPrayed('dhuhr'), isFalse);

      expect(state.bothCompletedCount, equals(1));
      expect(state.allCompletedTogether, isFalse);
    });

    test('allCompletedTogether triggers when both complete all 5 daily prayers', () {
      final state = const PrayerState().copyWith(
        isEnabled: true,
        myPrayers: {for (var k in PrayerNotifier.prayerKeys) k: true},
        partnerPrayers: {for (var k in PrayerNotifier.prayerKeys) k: true},
      );

      expect(state.bothCompletedCount, equals(5));
      expect(state.allCompletedTogether, isTrue);
    });
  });

  group('Feature 2: Thinking of You Heartbeat Pulse', () {
    test('Heartbeat state initializes idle and updates on receipt', () {
      const state = HeartbeatState();
      expect(state.isPulsing, isFalse);
      expect(state.receivedFromName, isNull);

      final now = DateTime.now();
      final active = state.copyWith(
        isPulsing: true,
        receivedFromName: 'Shakil',
        receivedAt: now,
      );

      expect(active.isPulsing, isTrue);
      expect(active.receivedFromName, equals('Shakil'));
      expect(active.receivedAt, equals(now));
    });
  });

  group('Feature 5: Date Night Roulette Generator', () {
    test('Curated date deck has valid entries across all vibes', () {
      expect(kDateIdeas.length, greaterThanOrEqualTo(8));
      for (final idea in kDateIdeas) {
        expect(idea.titleEn.isNotEmpty, isTrue);
        expect(idea.titleBn.isNotEmpty, isTrue);
        expect(idea.descEn.isNotEmpty, isTrue);
        expect(idea.descBn.isNotEmpty, isTrue);
        expect(idea.vibe.isNotEmpty, isTrue);
        expect(idea.vibeIcon.isNotEmpty, isTrue);
        expect(idea.duration.isNotEmpty, isTrue);
      }
    });

    test('All vibe filters (cozy, romantic, foodie, adventure) have matches', () {
      final vibes = kDateIdeas.map((i) => i.vibe).toSet();
      expect(vibes.contains('cozy'), isTrue);
      expect(vibes.contains('romantic'), isTrue);
      expect(vibes.contains('foodie'), isTrue);
      expect(vibes.contains('adventure'), isTrue);
    });
  });
}
