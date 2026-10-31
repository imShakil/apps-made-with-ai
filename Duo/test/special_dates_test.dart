import 'package:flutter_test/flutter_test.dart';
import 'package:duo/features/profile/presentation/providers/special_dates_provider.dart';

void main() {
  group('SpecialDatesState Calculations', () {
    test('Calculates days together and duration accurately', () {
      final now = DateTime.now();
      final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
      final state = SpecialDatesState(
        anniversaryDate: oneYearAgo,
        anniversaryType: 'dating',
      );

      expect(state.daysTogether, greaterThanOrEqualTo(365));
      expect(state.relationshipDuration, isNotNull);
      expect(state.relationshipDuration!['years'], greaterThanOrEqualTo(1));
      expect(state.anniversaryType, equals('dating'));
    });

    test('Computes next anniversary date with annual rollover', () {
      final now = DateTime.now();
      // An anniversary date 5 days ago
      final pastThisYear = DateTime(now.year - 2, now.month, now.day - 5);
      final statePast = SpecialDatesState(
        anniversaryDate: pastThisYear,
        anniversaryType: 'wedding',
      );

      final nextAnniv = statePast.nextAnniversaryDate;
      expect(nextAnniv, isNotNull);
      // Since it already occurred 5 days ago this year, next should be next year
      expect(nextAnniv!.isAfter(DateTime(now.year, now.month, now.day)), isTrue);
      expect(statePast.daysUntilNextAnniversary, greaterThan(0));
      expect(statePast.nextAnniversaryYearCount, equals(3));
    });

    test('Computes next birthday and next age correctly', () {
      final now = DateTime.now();
      final birthYear = now.year - 25;
      final birthDate = DateTime(birthYear, 12, 25);
      final state = SpecialDatesState(
        myBirthdate: birthDate,
      );

      final nextBday = state.getNextBirthday(state.myBirthdate);
      expect(nextBday, isNotNull);
      expect(nextBday!.month, equals(12));
      expect(nextBday.day, equals(25));

      final nextAge = state.getNextAge(state.myBirthdate);
      expect(nextAge, greaterThanOrEqualTo(25));
      expect(state.getDaysUntilBirthday(state.myBirthdate), isNotNull);
    });
  });
}
