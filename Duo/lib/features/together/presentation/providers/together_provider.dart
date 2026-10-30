import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../pairing/presentation/providers/pairing_provider.dart';

class TogetherState {
  final List<Map<String, dynamic>> countdowns;
  final List<Map<String, dynamic>> bucketItems;
  final bool isLoading;
  final String? error;

  const TogetherState({
    this.countdowns = const [],
    this.bucketItems = const [],
    this.isLoading = false,
    this.error,
  });

  Map<String, dynamic>? get heroCountdown {
    if (countdowns.isEmpty) return null;
    for (final c in countdowns) {
      if (c['is_pinned'] == true) return c;
    }
    return countdowns.first;
  }

  int get completedBucketCount => bucketItems.where((i) => i['completed'] == true).length;
  double get bucketProgress => bucketItems.isEmpty ? 0.0 : completedBucketCount / bucketItems.length;

  TogetherState copyWith({
    List<Map<String, dynamic>>? countdowns,
    List<Map<String, dynamic>>? bucketItems,
    bool? isLoading,
    String? error,
  }) {
    return TogetherState(
      countdowns: countdowns ?? this.countdowns,
      bucketItems: bucketItems ?? this.bucketItems,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TogetherNotifier extends StateNotifier<TogetherState> {
  final SupabaseClient _client;
  final Ref _ref;
  RealtimeChannel? _countdownsSub;
  RealtimeChannel? _bucketSub;

  TogetherNotifier(this._client, this._ref) : super(const TogetherState()) {
    init();
    _ref.listen<DuoSpaceState>(pairingProvider, (previous, next) {
      final duoId = next.space?['id'] as String?;
      final user = _client.auth.currentUser;
      if (duoId != null && user != null) {
        loadAll(duoId);
        _setupRealtime(duoId);
      }
    });
  }

  Future<void> init() async {
    final pairingState = _ref.read(pairingProvider);
    final duoId = pairingState.space?['id'] as String?;
    final user = _client.auth.currentUser;

    if (duoId == null || user == null) return;

    await loadAll(duoId);
    _setupRealtime(duoId);
  }

  Future<void> loadAll(String duoId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = _client.auth.currentUser;

      // 1. Fetch Countdowns from DB (sorted by event_date)
      final cdRes = await _client
          .from('countdown_events')
          .select('*')
          .eq('duo_id', duoId)
          .order('event_date', ascending: true);

      var countdownsList = (cdRes as List).map((row) {
        final r = Map<String, dynamic>.from(row as Map);
        final cat = r['category'] as String? ?? '💍';
        return {
          ...r,
          'target_date': r['event_date'],
          'icon': cat.length <= 4 ? cat : '💍',
          'is_pinned': true,
        };
      }).toList();

      if (countdownsList.isEmpty && user != null) {
        final nextYear = DateTime.now().add(const Duration(days: 42));
        final dateStr = '${nextYear.year}-${nextYear.month.toString().padLeft(2, '0')}-${nextYear.day.toString().padLeft(2, '0')}';
        try {
          final defaultEvent = await _client
              .from('countdown_events')
              .insert({
                'duo_id': duoId,
                'title': '1-Year Anniversary',
                'event_date': dateStr,
                'category': '💍',
                'created_by': user.id,
              })
              .select('*')
              .single();

          countdownsList = [
            {
              ...defaultEvent,
              'target_date': defaultEvent['event_date'],
              'icon': '💍',
              'is_pinned': true,
            }
          ];
        } catch (_) {}
      }

      // 2. Fetch Bucket Items
      List<Map<String, dynamic>> bucketList = [];
      try {
        final bucketRes = await _client
            .from('bucket_items')
            .select('*, users!bucket_items_created_by_fkey(display_name)')
            .eq('duo_id', duoId)
            .order('created_at', ascending: false);

        bucketList = (bucketRes as List).map((row) {
          final r = Map<String, dynamic>.from(row as Map);
          return {
            ...r,
            'completed': r['is_completed'] == true,
            'category': r['description'] ?? 'travel',
            'completed_by': (r['users'] as Map?)?['display_name'],
          };
        }).toList();
      } catch (_) {
        // Fallback without foreign key
        final bucketRes = await _client
            .from('bucket_items')
            .select('*')
            .eq('duo_id', duoId)
            .order('created_at', ascending: false);

        bucketList = (bucketRes as List).map((row) {
          final r = Map<String, dynamic>.from(row as Map);
          return {
            ...r,
            'completed': r['is_completed'] == true,
            'category': r['description'] ?? 'travel',
          };
        }).toList();
      }

      if (bucketList.isEmpty && user != null) {
        try {
          await _client.from('bucket_items').insert([
            {
              'duo_id': duoId,
              'title': 'Watch the sunset together at Cox’s Bazar 🌅',
              'description': 'travel',
              'created_by': user.id,
              'is_completed': false,
            },
            {
              'duo_id': duoId,
              'title': 'Cook homemade Italian pasta from scratch 🍝',
              'description': 'food',
              'created_by': user.id,
              'is_completed': false,
            },
            {
              'duo_id': duoId,
              'title': 'Stargazing camping trip in Sajek Valley ⛺',
              'description': 'adventure',
              'created_by': user.id,
              'is_completed': false,
            },
          ]);

          final seeded = await _client
              .from('bucket_items')
              .select('*')
              .eq('duo_id', duoId)
              .order('created_at', ascending: false);

          bucketList = (seeded as List).map((row) {
            final r = Map<String, dynamic>.from(row as Map);
            return {
              ...r,
              'completed': r['is_completed'] == true,
              'category': r['description'] ?? 'travel',
            };
          }).toList();
        } catch (_) {}
      }

      state = state.copyWith(
        countdowns: countdownsList,
        bucketItems: bucketList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _setupRealtime(String duoId) {
    _countdownsSub?.unsubscribe();
    _bucketSub?.unsubscribe();

    _countdownsSub = _client
        .channel('public:countdown_events:$duoId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'countdown_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'duo_id',
            value: duoId,
          ),
          callback: (_) => loadAll(duoId),
        )
        .subscribe();

    _bucketSub = _client
        .channel('public:bucket_items:$duoId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bucket_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'duo_id',
            value: duoId,
          ),
          callback: (_) => loadAll(duoId),
        )
        .subscribe();
  }

  Future<void> toggleBucketItem(String id, bool isCompleted) async {
    final user = _client.auth.currentUser;
    final pairingState = _ref.read(pairingProvider);
    final duoId = pairingState.space?['id'] as String?;

    // Optimistic local update
    final updatedList = state.bucketItems.map((item) {
      if (item['id'] == id) {
        return {
          ...item,
          'completed': isCompleted,
          'is_completed': isCompleted,
          'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
          'completed_by': isCompleted ? (user?.userMetadata?['full_name'] ?? 'You') : null,
        };
      }
      return item;
    }).toList();

    state = state.copyWith(bucketItems: updatedList);

    if (duoId != null && !id.startsWith('local_')) {
      try {
        await _client.from('bucket_items').update({
          'is_completed': isCompleted,
          'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
        }).eq('id', id);
      } catch (_) {
        await loadAll(duoId);
      }
    }
  }

  Future<bool> addBucketItem({
    required String title,
    String category = 'travel',
    DateTime? targetDate,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return false;

    final pairingState = _ref.read(pairingProvider);
    final duoId = pairingState.space?['id'] as String?;
    final user = _client.auth.currentUser;

    String? targetDateStr;
    if (targetDate != null) {
      targetDateStr = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
    }

    final newItem = {
      'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
      'title': cleanTitle,
      'category': category,
      'description': category,
      'completed': false,
      'is_completed': false,
      'target_date': targetDateStr,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Optimistic local update so UI reflects the dream instantly
    state = state.copyWith(bucketItems: [newItem, ...state.bucketItems]);

    if (duoId != null && user != null) {
      try {
        await _client.from('bucket_items').insert({
          'duo_id': duoId,
          'title': cleanTitle,
          'description': category,
          'created_by': user.id,
          'is_completed': false,
          if (targetDateStr != null) 'target_date': targetDateStr,
        });

        await loadAll(duoId);
      } catch (e) {
        // Keep optimistic item if offline or pending
      }
    }
    return true;
  }

  Future<bool> deleteBucketItem(String id) async {
    // Optimistic delete
    state = state.copyWith(
      bucketItems: state.bucketItems.where((i) => i['id'] != id).toList(),
    );

    final pairingState = _ref.read(pairingProvider);
    final duoId = pairingState.space?['id'] as String?;
    if (duoId != null && !id.startsWith('local_')) {
      try {
        await _client.from('bucket_items').delete().eq('id', id);
        await loadAll(duoId);
      } catch (_) {}
    }
    return true;
  }

  Future<bool> addCountdownEvent({
    required String title,
    required DateTime targetDate,
    String icon = '💍',
    bool isPinned = false,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return false;

    final pairingState = _ref.read(pairingProvider);
    final duoId = pairingState.space?['id'] as String?;
    final user = _client.auth.currentUser;

    final dateStr = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

    final newEvent = {
      'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
      'title': cleanTitle,
      'event_date': dateStr,
      'target_date': dateStr,
      'icon': icon,
      'category': icon,
      'is_pinned': isPinned,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Optimistic update
    state = state.copyWith(countdowns: [...state.countdowns, newEvent]);

    if (duoId != null && user != null) {
      try {
        await _client.from('countdown_events').insert({
          'duo_id': duoId,
          'title': cleanTitle,
          'event_date': dateStr,
          'category': icon,
          'created_by': user.id,
        });

        await loadAll(duoId);
      } catch (e) {
        // Keep optimistic event if offline or pending
      }
    }
    return true;
  }

  Future<bool> updateCountdownEvent({
    required String id,
    required String title,
    required DateTime targetDate,
    String icon = '💍',
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return false;

    final pairingState = _ref.read(pairingProvider);
    final duoId = pairingState.space?['id'] as String?;

    final dateStr = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

    // Optimistic update
    final updatedList = state.countdowns.map((cd) {
      if (cd['id'] == id) {
        return {
          ...cd,
          'title': cleanTitle,
          'event_date': dateStr,
          'target_date': dateStr,
          'icon': icon,
          'category': icon,
        };
      }
      return cd;
    }).toList();
    updatedList.sort((a, b) => (a['target_date'] as String? ?? '').compareTo(b['target_date'] as String? ?? ''));
    state = state.copyWith(countdowns: updatedList);

    if (duoId != null && !id.startsWith('local_')) {
      try {
        await _client.from('countdown_events').update({
          'title': cleanTitle,
          'event_date': dateStr,
          'category': icon,
        }).eq('id', id);

        await loadAll(duoId);
      } catch (_) {}
    }
    return true;
  }

  Future<bool> deleteCountdownEvent(String id) async {
    final pairingState = _ref.read(pairingProvider);
    final duoId = pairingState.space?['id'] as String?;

    // Optimistic delete
    state = state.copyWith(
      countdowns: state.countdowns.where((cd) => cd['id'] != id).toList(),
    );

    if (duoId != null && !id.startsWith('local_')) {
      try {
        await _client.from('countdown_events').delete().eq('id', id);
        await loadAll(duoId);
      } catch (_) {}
    }
    return true;
  }

  @override
  void dispose() {
    _countdownsSub?.unsubscribe();
    _bucketSub?.unsubscribe();
    super.dispose();
  }
}

final togetherProvider = StateNotifierProvider<TogetherNotifier, TogetherState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TogetherNotifier(client, ref);
});
