import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../pairing/presentation/providers/pairing_provider.dart';
import '../../../together/presentation/providers/together_provider.dart';

class SpecialDatesState {
  final DateTime? anniversaryDate;
  final String anniversaryType; // 'wedding', 'dating', 'engaged'
  final DateTime? myBirthdate;
  final DateTime? partnerBirthdate;
  final bool isLoading;

  const SpecialDatesState({
    this.anniversaryDate,
    this.anniversaryType = 'dating',
    this.myBirthdate,
    this.partnerBirthdate,
    this.isLoading = false,
  });

  SpecialDatesState copyWith({
    DateTime? anniversaryDate,
    String? anniversaryType,
    DateTime? myBirthdate,
    DateTime? partnerBirthdate,
    bool? isLoading,
  }) {
    return SpecialDatesState(
      anniversaryDate: anniversaryDate ?? this.anniversaryDate,
      anniversaryType: anniversaryType ?? this.anniversaryType,
      myBirthdate: myBirthdate ?? this.myBirthdate,
      partnerBirthdate: partnerBirthdate ?? this.partnerBirthdate,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Total days loving each other since anniversary date
  int? get daysTogether {
    if (anniversaryDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(anniversaryDate!.year, anniversaryDate!.month, anniversaryDate!.day);
    final diff = today.difference(start).inDays;
    return diff >= 0 ? diff : 0;
  }

  /// Breakdown in Years & Months together
  Map<String, int>? get relationshipDuration {
    if (anniversaryDate == null) return null;
    final now = DateTime.now();
    int years = now.year - anniversaryDate!.year;
    int months = now.month - anniversaryDate!.month;
    if (now.day < anniversaryDate!.day) months--;
    if (months < 0) {
      years--;
      months += 12;
    }
    return {'years': years >= 0 ? years : 0, 'months': months >= 0 ? months : 0};
  }

  /// Next recurring annual anniversary
  DateTime? get nextAnniversaryDate {
    if (anniversaryDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var next = DateTime(now.year, anniversaryDate!.month, anniversaryDate!.day);
    if (next.isBefore(today)) {
      next = DateTime(now.year + 1, anniversaryDate!.month, anniversaryDate!.day);
    }
    return next;
  }

  int? get daysUntilNextAnniversary {
    if (nextAnniversaryDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return nextAnniversaryDate!.difference(today).inDays;
  }

  int? get nextAnniversaryYearCount {
    if (anniversaryDate == null || nextAnniversaryDate == null) return null;
    return nextAnniversaryDate!.year - anniversaryDate!.year;
  }

  /// Next recurring birthday
  DateTime? getNextBirthday(DateTime? birthdate) {
    if (birthdate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var next = DateTime(now.year, birthdate.month, birthdate.day);
    if (next.isBefore(today)) {
      next = DateTime(now.year + 1, birthdate.month, birthdate.day);
    }
    return next;
  }

  int? getDaysUntilBirthday(DateTime? birthdate) {
    final next = getNextBirthday(birthdate);
    if (next == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return next.difference(today).inDays;
  }

  int? getNextAge(DateTime? birthdate) {
    final next = getNextBirthday(birthdate);
    if (birthdate == null || next == null) return null;
    return next.year - birthdate.year;
  }
}

class SpecialDatesNotifier extends StateNotifier<SpecialDatesState> {
  final SupabaseClient _client;
  final Ref _ref;

  SpecialDatesNotifier(this._client, this._ref) : super(const SpecialDatesState()) {
    loadDates();
  }

  Future<void> loadDates() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();

    // 1. Read local cache for immediate zero-lag display
    DateTime? localAnniv;
    final annivStr = prefs.getString('duo_anniversary_date');
    if (annivStr != null) localAnniv = DateTime.tryParse(annivStr);

    final annivType = prefs.getString('duo_anniversary_type') ?? 'dating';

    DateTime? localMyBirth;
    final myBirthStr = prefs.getString('duo_my_birthdate');
    if (myBirthStr != null) localMyBirth = DateTime.tryParse(myBirthStr);

    DateTime? localPartnerBirth;
    final partnerBirthStr = prefs.getString('duo_partner_birthdate');
    if (partnerBirthStr != null) localPartnerBirth = DateTime.tryParse(partnerBirthStr);

    state = SpecialDatesState(
      anniversaryDate: localAnniv,
      anniversaryType: annivType,
      myBirthdate: localMyBirth,
      partnerBirthdate: localPartnerBirth,
      isLoading: false,
    );

    // 2. Sync from Supabase
    final pairingState = _ref.read(pairingProvider);
    final duoId = pairingState.space?['id'] as String?;
    final user = _client.auth.currentUser;

    if (user != null) {
      final userBirth = user.userMetadata?['birthdate'] as String?;
      if (userBirth != null && localMyBirth == null) {
        final parsed = DateTime.tryParse(userBirth);
        if (parsed != null) {
          localMyBirth = parsed;
          await prefs.setString('duo_my_birthdate', parsed.toIso8601String());
        }
      }
    }

    if (duoId != null) {
      try {
        final events = await _client
            .from('countdown_events')
            .select('*')
            .eq('duo_id', duoId);

        for (final row in (events as List)) {
          final cat = row['category'] as String? ?? '';
          final dateStr = row['event_date'] as String?;
          final title = row['title'] as String? ?? '';

          if (dateStr == null) continue;
          final parsed = DateTime.tryParse(dateStr);
          if (parsed == null) continue;

          if (cat == '💍' || cat == 'anniversary' || title.toLowerCase().contains('anniversary')) {
            localAnniv ??= parsed;
          } else if (cat == '🎂' || cat == 'birthday') {
            if (row['created_by'] == user?.id) {
              localMyBirth ??= parsed;
            } else {
              localPartnerBirth ??= parsed;
            }
          } else if (cat == '🎉' || cat == 'partner_birthday') {
            localPartnerBirth ??= parsed;
          }
        }
      } catch (_) {}
    }

    state = SpecialDatesState(
      anniversaryDate: localAnniv,
      anniversaryType: annivType,
      myBirthdate: localMyBirth,
      partnerBirthdate: localPartnerBirth,
      isLoading: false,
    );
  }

  Future<bool> setAnniversary(DateTime date, {String type = 'dating'}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('duo_anniversary_date', date.toIso8601String());
    await prefs.setString('duo_anniversary_type', type);

    state = state.copyWith(anniversaryDate: date, anniversaryType: type);

    // Sync to Supabase countdown_events table
    final pairingState = _ref.read(pairingProvider);
    final duoId = pairingState.space?['id'] as String?;
    final user = _client.auth.currentUser;

    if (duoId != null && user != null) {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      String title;
      switch (type) {
        case 'wedding':
          title = 'Wedding Anniversary';
          break;
        case 'engaged':
          title = 'Engagement Anniversary';
          break;
        case 'dating':
        default:
          title = 'Our Anniversary';
          break;
      }

      try {
        // Look for existing anniversary row
        final existing = await _client
            .from('countdown_events')
            .select('id')
            .eq('duo_id', duoId)
            .eq('category', '💍')
            .maybeSingle();

        if (existing != null) {
          await _client.from('countdown_events').update({
            'title': title,
            'event_date': dateStr,
          }).eq('id', existing['id']);
        } else {
          await _client.from('countdown_events').insert({
            'duo_id': duoId,
            'title': title,
            'event_date': dateStr,
            'category': '💍',
            'created_by': user.id,
          });
        }

        // Trigger togetherProvider to refresh countdowns & widgets
        await _ref.read(togetherProvider.notifier).loadAll(duoId);
      } catch (_) {}
    }
    return true;
  }

  Future<bool> setMyBirthday(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('duo_my_birthdate', date.toIso8601String());

    state = state.copyWith(myBirthdate: date);

    final pairingState = _ref.read(pairingProvider);
    final duoId = pairingState.space?['id'] as String?;
    final user = _client.auth.currentUser;

    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      await _client.auth.updateUser(UserAttributes(data: {'birthdate': dateStr}));
    } catch (_) {}

    if (duoId != null && user != null) {
      try {
        final existing = await _client
            .from('countdown_events')
            .select('id')
            .eq('duo_id', duoId)
            .eq('category', '🎂')
            .eq('created_by', user.id)
            .maybeSingle();

        if (existing != null) {
          await _client.from('countdown_events').update({
            'event_date': dateStr,
          }).eq('id', existing['id']);
        } else {
          await _client.from('countdown_events').insert({
            'duo_id': duoId,
            'title': 'Birthday 🎂',
            'event_date': dateStr,
            'category': '🎂',
            'created_by': user.id,
          });
        }
        await _ref.read(togetherProvider.notifier).loadAll(duoId);
      } catch (_) {}
    }
    return true;
  }

  Future<bool> setPartnerBirthday(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('duo_partner_birthdate', date.toIso8601String());

    state = state.copyWith(partnerBirthdate: date);

    final pairingState = _ref.read(pairingProvider);
    final duoId = pairingState.space?['id'] as String?;
    final user = _client.auth.currentUser;

    if (duoId != null && user != null) {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      try {
        final existing = await _client
            .from('countdown_events')
            .select('id')
            .eq('duo_id', duoId)
            .eq('category', '🎉')
            .maybeSingle();

        if (existing != null) {
          await _client.from('countdown_events').update({
            'event_date': dateStr,
          }).eq('id', existing['id']);
        } else {
          await _client.from('countdown_events').insert({
            'duo_id': duoId,
            'title': "Partner's Birthday 🎉",
            'event_date': dateStr,
            'category': '🎉',
            'created_by': user.id,
          });
        }
        await _ref.read(togetherProvider.notifier).loadAll(duoId);
      } catch (_) {}
    }
    return true;
  }
}

final specialDatesProvider = StateNotifierProvider<SpecialDatesNotifier, SpecialDatesState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SpecialDatesNotifier(client, ref);
});
