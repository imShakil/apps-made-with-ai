import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../pairing/presentation/providers/pairing_provider.dart';

class PrayerState {
  final bool isEnabled;
  final Map<String, bool> myPrayers;
  final Map<String, bool> partnerPrayers;
  final String date;
  final String? lastNudgeMessage;
  final bool showCelebration;

  const PrayerState({
    this.isEnabled = false,
    this.myPrayers = const {
      'fajr': false,
      'dhuhr': false,
      'asr': false,
      'maghrib': false,
      'isha': false,
    },
    this.partnerPrayers = const {
      'fajr': false,
      'dhuhr': false,
      'asr': false,
      'maghrib': false,
      'isha': false,
    },
    this.date = '',
    this.lastNudgeMessage,
    this.showCelebration = false,
  });

  bool isPrayedByMe(String key) => myPrayers[key] == true;
  bool isPrayedByPartner(String key) => partnerPrayers[key] == true;
  bool isBothPrayed(String key) => isPrayedByMe(key) && isPrayedByPartner(key);

  int get myCompletedCount => myPrayers.values.where((v) => v).length;
  int get partnerCompletedCount => partnerPrayers.values.where((v) => v).length;
  int get bothCompletedCount => myPrayers.keys.where((k) => isBothPrayed(k)).length;
  bool get allCompletedTogether => bothCompletedCount == 5;

  PrayerState copyWith({
    bool? isEnabled,
    Map<String, bool>? myPrayers,
    Map<String, bool>? partnerPrayers,
    String? date,
    String? lastNudgeMessage,
    bool? showCelebration,
  }) {
    return PrayerState(
      isEnabled: isEnabled ?? this.isEnabled,
      myPrayers: myPrayers ?? this.myPrayers,
      partnerPrayers: partnerPrayers ?? this.partnerPrayers,
      date: date ?? this.date,
      lastNudgeMessage: lastNudgeMessage,
      showCelebration: showCelebration ?? this.showCelebration,
    );
  }
}

class PrayerNotifier extends StateNotifier<PrayerState> {
  final Ref _ref;
  final SupabaseClient _client;
  RealtimeChannel? _realtimeChannel;

  static const List<String> prayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  PrayerNotifier(this._ref, this._client) : super(const PrayerState()) {
    _init();
  }

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('duo_prayer_enabled') ?? false;
    final today = _todayKey;

    // Load local today prayers
    final mySaved = prefs.getString('duo_my_prayers_$today');
    final partnerSaved = prefs.getString('duo_partner_prayers_$today');

    Map<String, bool> myMap = {for (var k in prayerKeys) k: false};
    Map<String, bool> partnerMap = {for (var k in prayerKeys) k: false};

    if (mySaved != null) {
      try {
        final decoded = jsonDecode(mySaved) as Map<String, dynamic>;
        for (var k in prayerKeys) {
          if (decoded.containsKey(k)) myMap[k] = decoded[k] == true;
        }
      } catch (_) {}
    }

    if (partnerSaved != null) {
      try {
        final decoded = jsonDecode(partnerSaved) as Map<String, dynamic>;
        for (var k in prayerKeys) {
          if (decoded.containsKey(k)) partnerMap[k] = decoded[k] == true;
        }
      } catch (_) {}
    }

    state = state.copyWith(
      isEnabled: enabled,
      date: today,
      myPrayers: myMap,
      partnerPrayers: partnerMap,
    );

    _setupRealtime();
  }

  void _setupRealtime() {
    final pairing = _ref.read(pairingProvider);
    final duoId = pairing.space?['id'] as String?;
    if (duoId == null) return;

    _realtimeChannel?.unsubscribe();
    _realtimeChannel = _client.channel('duo_pulse:$duoId');

    _realtimeChannel?.onBroadcast(
      event: 'prayer_update',
      callback: (payload) {
        final senderId = payload['sender_id'] as String?;
        final user = _client.auth.currentUser;
        if (senderId == null || senderId == user?.id) return;

        final date = payload['date'] as String?;
        if (date != _todayKey) return;

        final prayersRaw = payload['prayers'] as Map<String, dynamic>?;
        if (prayersRaw != null) {
          final updatedPartner = Map<String, bool>.from(state.partnerPrayers);
          for (var k in prayerKeys) {
            if (prayersRaw.containsKey(k)) {
              updatedPartner[k] = prayersRaw[k] == true;
            }
          }

          // Check if both now completed a prayer that was pending
          bool triggerCelebration = false;
          for (var k in prayerKeys) {
            if (state.myPrayers[k] == true && updatedPartner[k] == true && state.partnerPrayers[k] != true) {
              triggerCelebration = true;
            }
          }

          state = state.copyWith(
            partnerPrayers: updatedPartner,
            showCelebration: triggerCelebration,
          );

          // Save partner prayers to SharedPreferences
          SharedPreferences.getInstance().then((prefs) {
            prefs.setString('duo_partner_prayers_$_todayKey', jsonEncode(updatedPartner));
          });
        }
      },
    );

    _realtimeChannel?.onBroadcast(
      event: 'prayer_nudge',
      callback: (payload) {
        final senderId = payload['sender_id'] as String?;
        final user = _client.auth.currentUser;
        if (senderId == null || senderId == user?.id) return;

        final prayerName = payload['prayer_name'] as String? ?? 'Salah';
        final senderName = payload['sender_name'] as String? ?? 'Your partner';

        state = state.copyWith(
          lastNudgeMessage: '$senderName nudged: Time for $prayerName! 🤲❤️',
        );
      },
    );

    _realtimeChannel?.subscribe();

    // Broadcast our current prayers on space connection so partner can sync
    _broadcastCurrentPrayers();
  }

  Future<void> toggleEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('duo_prayer_enabled', enabled);
    state = state.copyWith(isEnabled: enabled);
    if (enabled) {
      _setupRealtime();
    }
  }

  Future<void> togglePrayer(String prayerKey) async {
    if (!prayerKeys.contains(prayerKey)) return;

    final updated = Map<String, bool>.from(state.myPrayers);
    final newVal = !(updated[prayerKey] ?? false);
    updated[prayerKey] = newVal;

    final isBothNow = newVal && (state.partnerPrayers[prayerKey] == true);

    state = state.copyWith(
      myPrayers: updated,
      showCelebration: isBothNow,
    );

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('duo_my_prayers_$_todayKey', jsonEncode(updated));

    // Broadcast to partner
    _broadcastCurrentPrayers();
  }

  Future<void> _broadcastCurrentPrayers() async {
    final pairing = _ref.read(pairingProvider);
    final duoId = pairing.space?['id'] as String?;
    final user = _client.auth.currentUser;
    if (duoId == null || user == null) return;

    try {
      await _realtimeChannel?.sendBroadcastMessage(
        event: 'prayer_update',
        payload: {
          'sender_id': user.id,
          'date': _todayKey,
          'prayers': state.myPrayers,
        },
      );
    } catch (_) {}
  }

  Future<bool> sendPrayerNudge(String prayerKey, String partnerName, String myName) async {
    final pairing = _ref.read(pairingProvider);
    final duoId = pairing.space?['id'] as String?;
    final user = _client.auth.currentUser;
    if (duoId == null || user == null) return false;

    try {
      await _realtimeChannel?.sendBroadcastMessage(
        event: 'prayer_nudge',
        payload: {
          'sender_id': user.id,
          'sender_name': myName,
          'prayer_name': prayerKey[0].toUpperCase() + prayerKey.substring(1),
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearCelebration() {
    state = state.copyWith(showCelebration: false);
  }

  void clearNudge() {
    state = state.copyWith(lastNudgeMessage: null);
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}

final prayerProvider = StateNotifierProvider<PrayerNotifier, PrayerState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PrayerNotifier(ref, client);
});
