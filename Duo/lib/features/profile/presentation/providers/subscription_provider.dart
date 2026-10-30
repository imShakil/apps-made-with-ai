import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../pairing/presentation/providers/pairing_provider.dart';

class SubscriptionState {
  final bool isPremium;
  final String? plan; // 'monthly', 'annual', 'lifetime'
  final String? subscriberName;
  final DateTime? currentPeriodEnd;
  final bool isLoading;
  final String? error;

  const SubscriptionState({
    this.isPremium = false,
    this.plan,
    this.subscriberName,
    this.currentPeriodEnd,
    this.isLoading = false,
    this.error,
  });

  SubscriptionState copyWith({
    bool? isPremium,
    String? plan,
    String? subscriberName,
    DateTime? currentPeriodEnd,
    bool? isLoading,
    String? error,
  }) {
    return SubscriptionState(
      isPremium: isPremium ?? this.isPremium,
      plan: plan ?? this.plan,
      subscriberName: subscriberName ?? this.subscriberName,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final SupabaseClient _client;
  final Ref _ref;
  RealtimeChannel? _subscription;

  SubscriptionNotifier(this._client, this._ref) : super(const SubscriptionState()) {
    init();
  }

  Future<void> init() async {
    final pairingState = _ref.read(pairingProvider);
    final duoId = pairingState.space?['id'] as String?;
    final user = _client.auth.currentUser;

    if (duoId == null || user == null) return;

    await loadSubscription(duoId);
    _setupRealtime(duoId);
  }

  Future<void> loadSubscription(String duoId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client
          .from('subscriptions')
          .select('*, users!subscriptions_subscriber_user_id_fkey(display_name)')
          .eq('duo_id', duoId)
          .eq('status', 'active')
          .maybeSingle();

      if (res != null) {
        final plan = res['plan'] as String?;
        final endStr = res['current_period_end'] as String?;
        final end = endStr != null ? DateTime.tryParse(endStr) : null;
        final subscriber = (res['users'] as Map<String, dynamic>?)?['display_name'] as String?;

        state = SubscriptionState(
          isPremium: true,
          plan: plan,
          subscriberName: subscriber,
          currentPeriodEnd: end,
          isLoading: false,
        );
      } else {
        state = const SubscriptionState(isPremium: false, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _setupRealtime(String duoId) {
    _subscription?.unsubscribe();

    _subscription = _client
        .channel('public:subscriptions:$duoId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'subscriptions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'duo_id',
            value: duoId,
          ),
          callback: (_) => loadSubscription(duoId),
        )
        .subscribe();
  }

  Future<bool> activatePlan(String plan) async {
    final user = _client.auth.currentUser;
    final pairingState = _ref.read(pairingProvider);
    final duoId = pairingState.space?['id'] as String?;

    if (user == null || duoId == null) return false;

    state = state.copyWith(isLoading: true, error: null);
    try {
      DateTime? periodEnd;
      if (plan == 'monthly') {
        periodEnd = DateTime.now().add(const Duration(days: 30));
      } else if (plan == 'annual') {
        periodEnd = DateTime.now().add(const Duration(days: 365));
      } else {
        periodEnd = null; // Lifetime
      }

      await _client.from('subscriptions').upsert({
        'duo_id': duoId,
        'subscriber_user_id': user.id,
        'plan': plan,
        'status': 'active',
        'platform': 'stripe',
        'current_period_end': periodEnd?.toIso8601String(),
      });

      // Send celebration notification to partner
      final partnerId = pairingState.partner?['id'] as String?;
      if (partnerId != null) {
        await _client.from('notifications').insert({
          'user_id': partnerId,
          'duo_id': duoId,
          'type': 'premium',
          'payload': {'message': 'Duo Premium was unlocked for both of you! 👑✨'},
        });
      }

      await loadSubscription(duoId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SubscriptionNotifier(client, ref);
});
