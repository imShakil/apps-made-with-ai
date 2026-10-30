import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../pairing/presentation/providers/pairing_provider.dart';

class HeartbeatState {
  final bool isPulsing;
  final String? receivedFromName;
  final DateTime? receivedAt;

  const HeartbeatState({
    this.isPulsing = false,
    this.receivedFromName,
    this.receivedAt,
  });

  HeartbeatState copyWith({
    bool? isPulsing,
    String? receivedFromName,
    DateTime? receivedAt,
  }) {
    return HeartbeatState(
      isPulsing: isPulsing ?? this.isPulsing,
      receivedFromName: receivedFromName,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }
}

class HeartbeatNotifier extends StateNotifier<HeartbeatState> {
  final Ref _ref;
  final SupabaseClient _client;
  RealtimeChannel? _realtimeChannel;

  HeartbeatNotifier(this._ref, this._client) : super(const HeartbeatState()) {
    _init();
  }

  void _init() {
    final pairing = _ref.read(pairingProvider);
    final duoId = pairing.space?['id'] as String?;
    if (duoId == null) return;

    _realtimeChannel?.unsubscribe();
    _realtimeChannel = _client.channel('duo_pulse:$duoId');

    _realtimeChannel?.onBroadcast(
      event: 'heartbeat',
      callback: (payload) async {
        final senderId = payload['sender_id'] as String?;
        final user = _client.auth.currentUser;
        if (senderId == null || senderId == user?.id) return;

        final senderName = payload['sender_name'] as String? ?? 'Partner';

        // Play double lub-dub haptic
        await _playDoubleHaptic();

        state = state.copyWith(
          isPulsing: true,
          receivedFromName: senderName,
          receivedAt: DateTime.now(),
        );

        // Reset pulsing flag after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            state = state.copyWith(isPulsing: false, receivedFromName: null);
          }
        });
      },
    );

    _realtimeChannel?.subscribe();
  }

  Future<void> _playDoubleHaptic() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 140));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  Future<bool> sendHeartbeat(String myName) async {
    final pairing = _ref.read(pairingProvider);
    final duoId = pairing.space?['id'] as String?;
    final user = _client.auth.currentUser;
    if (duoId == null || user == null) return false;

    // Double haptic locally
    _playDoubleHaptic();

    try {
      await _realtimeChannel?.sendBroadcastMessage(
        event: 'heartbeat',
        payload: {
          'sender_id': user.id,
          'sender_name': myName,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearPulse() {
    state = state.copyWith(isPulsing: false, receivedFromName: null);
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}

final heartbeatProvider = StateNotifierProvider<HeartbeatNotifier, HeartbeatState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return HeartbeatNotifier(ref, client);
});
