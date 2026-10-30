import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../pairing/presentation/providers/pairing_provider.dart';

class MoodState {
  final String? myMood;
  final String? myMessage;
  final DateTime? myCheckedAt;
  final String? partnerMood;
  final String? partnerMessage;
  final DateTime? partnerCheckedAt;
  final int streakDays;
  final bool isLoading;
  final String? error;

  const MoodState({
    this.myMood,
    this.myMessage,
    this.myCheckedAt,
    this.partnerMood,
    this.partnerMessage,
    this.partnerCheckedAt,
    this.streakDays = 1,
    this.isLoading = false,
    this.error,
  });

  MoodState copyWith({
    String? myMood,
    String? myMessage,
    DateTime? myCheckedAt,
    String? partnerMood,
    String? partnerMessage,
    DateTime? partnerCheckedAt,
    int? streakDays,
    bool? isLoading,
    String? error,
  }) {
    return MoodState(
      myMood: myMood ?? this.myMood,
      myMessage: myMessage ?? this.myMessage,
      myCheckedAt: myCheckedAt ?? this.myCheckedAt,
      partnerMood: partnerMood ?? this.partnerMood,
      partnerMessage: partnerMessage ?? this.partnerMessage,
      partnerCheckedAt: partnerCheckedAt ?? this.partnerCheckedAt,
      streakDays: streakDays ?? this.streakDays,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MoodNotifier extends StateNotifier<MoodState> {
  final SupabaseClient _client;
  final Ref _ref;
  RealtimeChannel? _subscription;

  MoodNotifier(this._client, this._ref) : super(const MoodState()) {
    init();
  }

  String get _todayDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> init() async {
    final pairingState = _ref.read(pairingProvider);
    final duoId = pairingState.space?['id'] as String?;
    final user = _client.auth.currentUser;

    if (duoId == null || user == null) return;

    await loadTodayMoods(duoId, user.id);
    _setupRealtime(duoId);
  }

  Future<void> loadTodayMoods(String duoId, String currentUserId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final date = _todayDate;

      // 1. Fetch today's check-ins for this Duo
      final res = await _client
          .from('mood_checkins')
          .select('*')
          .eq('duo_id', duoId)
          .eq('local_date', date);

      String? myMood;
      String? myMessage;
      DateTime? myCheckedAt;
      String? partnerMood;
      String? partnerMessage;
      DateTime? partnerCheckedAt;

      for (final item in res as List<dynamic>) {
        final row = item as Map<String, dynamic>;
        final userId = row['user_id'] as String;
        final mood = row['mood'] as String;
        final msg = row['message'] as String?;
        final createdAtStr = row['created_at'] as String?;
        final createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;

        if (userId == currentUserId) {
          myMood = mood;
          myMessage = msg;
          myCheckedAt = createdAt;
        } else {
          partnerMood = mood;
          partnerMessage = msg;
          partnerCheckedAt = createdAt;
        }
      }

      // 2. Calculate streak count
      final streakRes = await _client
          .from('mood_checkins')
          .select('local_date')
          .eq('duo_id', duoId)
          .order('local_date', ascending: false)
          .limit(30);

      int streak = 0;
      if (streakRes.isNotEmpty) {
        final dates = (streakRes as List<dynamic>)
            .map((e) => (e as Map<String, dynamic>)['local_date'] as String)
            .toSet();
        
        var checkDate = DateTime.now();
        while (true) {
          final dateStr = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
          if (dates.contains(dateStr)) {
            streak++;
            checkDate = checkDate.subtract(const Duration(days: 1));
          } else {
            // If checked in today, don't break if yesterday wasn't checked until yesterday is verified
            if (streak == 0) {
              checkDate = checkDate.subtract(const Duration(days: 1));
              final yesterdayStr = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
              if (dates.contains(yesterdayStr)) {
                streak++;
                checkDate = checkDate.subtract(const Duration(days: 1));
                continue;
              }
            }
            break;
          }
        }
      }

      state = state.copyWith(
        myMood: myMood,
        myMessage: myMessage,
        myCheckedAt: myCheckedAt,
        partnerMood: partnerMood,
        partnerMessage: partnerMessage,
        partnerCheckedAt: partnerCheckedAt,
        streakDays: streak > 0 ? streak : 1,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _setupRealtime(String duoId) {
    _subscription?.unsubscribe();

    _subscription = _client
        .channel('public:mood_checkins:$duoId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'mood_checkins',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'duo_id',
            value: duoId,
          ),
          callback: (payload) {
            final user = _client.auth.currentUser;
            if (user != null) {
              loadTodayMoods(duoId, user.id);
            }
          },
        )
        .subscribe();
  }

  Future<bool> setMood(String mood, {String? message}) async {
    final pairingState = _ref.read(pairingProvider);
    final duoId = pairingState.space?['id'] as String?;
    final user = _client.auth.currentUser;

    if (duoId == null || user == null) return false;

    // Optimistic UI update
    final prevMood = state.myMood;
    final prevMsg = state.myMessage;
    state = state.copyWith(myMood: mood, myMessage: message, myCheckedAt: DateTime.now());

    try {
      final date = _todayDate;
      await _client.from('mood_checkins').upsert({
        'duo_id': duoId,
        'user_id': user.id,
        'mood': mood,
        'message': message,
        'local_date': date,
      }, onConflict: 'duo_id, user_id, local_date');

      return true;
    } catch (e) {
      // Rollback on failure
      state = state.copyWith(myMood: prevMood, myMessage: prevMsg, error: e.toString());
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}

final moodProvider = StateNotifierProvider<MoodNotifier, MoodState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return MoodNotifier(client, ref);
});
