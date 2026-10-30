import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';

class DuoSpaceState {
  final Map<String, dynamic>? space;
  final Map<String, dynamic>? myMembership;
  final Map<String, dynamic>? partner;
  final bool isLoading;
  final String? error;

  const DuoSpaceState({
    this.space,
    this.myMembership,
    this.partner,
    this.isLoading = false,
    this.error,
  });

  bool get isPaired => space != null && space!['status'] == 'active' && partner != null;
  bool get isPendingInvite => space != null && space!['status'] == 'pending';

  DuoSpaceState copyWith({
    Map<String, dynamic>? space,
    Map<String, dynamic>? myMembership,
    Map<String, dynamic>? partner,
    bool? isLoading,
    String? error,
  }) {
    return DuoSpaceState(
      space: space ?? this.space,
      myMembership: myMembership ?? this.myMembership,
      partner: partner ?? this.partner,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PairingNotifier extends StateNotifier<DuoSpaceState> {
  final SupabaseClient _client;

  PairingNotifier(this._client) : super(const DuoSpaceState()) {
    fetchCurrentDuo();
  }

  Future<void> fetchCurrentDuo() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      state = const DuoSpaceState();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Get active membership
      final memberRes = await _client
          .from('duo_members')
          .select('*, duo_spaces(*)')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .maybeSingle();

      if (memberRes == null) {
        state = const DuoSpaceState(isLoading: false);
        return;
      }

      final duoId = memberRes['duo_id'] as String;
      final spaceData = memberRes['duo_spaces'] as Map<String, dynamic>?;

      // 2. Look for partner
      final partnerRes = await _client
          .from('duo_members')
          .select('*, users(*)')
          .eq('duo_id', duoId)
          .neq('user_id', user.id)
          .eq('status', 'active')
          .maybeSingle();

      Map<String, dynamic>? partnerData;
      if (partnerRes != null && partnerRes['users'] != null) {
        partnerData = partnerRes['users'] as Map<String, dynamic>;
      }

      state = DuoSpaceState(
        space: spaceData,
        myMembership: memberRes,
        partner: partnerData,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> createInvitationCode() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      var duoId = state.space?['id'] as String?;

      // Create space if none exists
      if (duoId == null) {
        final createRes = await _client.rpc('create_duo_space', params: {'p_name': null});
        if (createRes != null && createRes['success'] == true) {
          duoId = createRes['duo_id'] as String;
        } else {
          return null;
        }
      }

      // Generate invitation code
      final inviteRes = await _client.rpc('create_invitation', params: {
        'p_duo_id': duoId,
        'p_expires_hours': 48,
      });

      if (inviteRes != null && inviteRes['success'] == true) {
        await fetchCurrentDuo();
        return inviteRes['invite_code'] as String?;
      }
      return null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> acceptInvitation(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.rpc('accept_invitation', params: {
        'p_invite_code': code.trim().toUpperCase(),
      });

      if (res != null && res['success'] == true) {
        await fetchCurrentDuo();
        return true;
      } else {
        final errCode = res?['error']?.toString() ?? 'FAILED_INVITE';
        String message;
        switch (errCode) {
          case 'CANNOT_PAIR_WITH_SELF':
            message = 'You cannot connect using your own invite code. Share this code with your partner to enter on their device!';
            break;
          case 'ALREADY_PAIRED':
            message = 'You are already paired in an active Duo space. To connect with a different partner, unpair first in Profile Settings.';
            break;
          case 'INVALID_OR_EXPIRED_INVITE':
            message = 'This invitation code is invalid or has expired. Please ask your partner to generate a new code.';
            break;
          case 'DUO_FULL':
            message = 'This Duo space already has two partners connected.';
            break;
          default:
            message = 'Failed to accept invitation ($errCode).';
        }
        state = state.copyWith(isLoading: false, error: message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> disconnectDuo() async {
    final duoId = state.space?['id'] as String?;
    if (duoId == null) return false;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.rpc('disconnect_duo', params: {'p_duo_id': duoId});
      if (res != null && res['success'] == true) {
        state = const DuoSpaceState();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: res?['error']?.toString() ?? 'Failed to disconnect',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final pairingProvider = StateNotifierProvider<PairingNotifier, DuoSpaceState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PairingNotifier(client);
});
