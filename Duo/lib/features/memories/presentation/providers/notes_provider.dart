import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../pairing/presentation/providers/pairing_provider.dart';

class NotesState {
  final List<Map<String, dynamic>> notes;
  final Map<String, dynamic>? unopenedNote;
  final bool isLoading;
  final String? error;

  const NotesState({
    this.notes = const [],
    this.unopenedNote,
    this.isLoading = false,
    this.error,
  });

  NotesState copyWith({
    List<Map<String, dynamic>>? notes,
    Map<String, dynamic>? unopenedNote,
    bool? isLoading,
    String? error,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      unopenedNote: unopenedNote,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotesNotifier extends StateNotifier<NotesState> {
  final SupabaseClient _client;
  final Ref _ref;
  RealtimeChannel? _subscription;

  NotesNotifier(this._client, this._ref) : super(const NotesState()) {
    init();
    _ref.listen<DuoSpaceState>(pairingProvider, (previous, next) {
      final duoId = next.space?['id'] as String?;
      final user = _client.auth.currentUser;
      if (duoId != null && user != null) {
        loadNotes(duoId, user.id);
        _setupRealtime(duoId, user.id);
      }
    });
  }

  Future<void> init() async {
    final pairingState = _ref.read(pairingProvider);
    final duoId = pairingState.space?['id'] as String?;
    final user = _client.auth.currentUser;

    if (duoId == null || user == null) return;

    await loadNotes(duoId, user.id);
    _setupRealtime(duoId, user.id);
  }

  Future<void> loadNotes(String duoId, String currentUserId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client
          .from('notes')
          .select('*, users!notes_sender_id_fkey(display_name)')
          .eq('duo_id', duoId)
          .order('created_at', ascending: false);

      final rawList = List<Map<String, dynamic>>.from(res as List);

      final parsedList = rawList.map((note) {
        final rawBody = note['body'] as String? ?? '';
        String cleanBody = rawBody;
        String? mediaUrl = note['media_url'] as String?;

        if (rawBody.contains('[PHOTO_URL]:')) {
          final parts = rawBody.split('[PHOTO_URL]:');
          cleanBody = parts[0].trim();
          if (parts.length > 1) {
            mediaUrl = parts[1].trim();
          }
        }

        return {
          ...note,
          'body': cleanBody.isEmpty ? 'A cherished moment together 💖' : cleanBody,
          'media_url': mediaUrl,
        };
      }).toList();

      Map<String, dynamic>? unopened;
      for (final note in parsedList) {
        if (note['sender_id'] != currentUserId && note['opened_at'] == null) {
          unopened = note;
          break;
        }
      }

      state = state.copyWith(
        notes: parsedList,
        unopenedNote: unopened,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _setupRealtime(String duoId, String currentUserId) {
    _subscription?.unsubscribe();

    _subscription = _client
        .channel('public:notes:$duoId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'duo_id',
            value: duoId,
          ),
          callback: (_) {
            loadNotes(duoId, currentUserId);
          },
        )
        .subscribe();
  }

  Future<bool> sendNote({
    required String title,
    required String body,
    required String stationeryTheme,
  }) async {
    final pairingState = _ref.read(pairingProvider);
    final duoId = pairingState.space?['id'] as String?;
    final user = _client.auth.currentUser;

    if (duoId == null || user == null) return false;

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _client.from('notes').insert({
        'duo_id': duoId,
        'sender_id': user.id,
        'title': title.trim().isEmpty ? null : title.trim(),
        'body': body.trim(),
        'stationery_theme': stationeryTheme,
      });

      // Notify partner
      final partnerId = pairingState.partner?['id'] as String?;
      if (partnerId != null) {
        await _client.from('notifications').insert({
          'user_id': partnerId,
          'duo_id': duoId,
          'type': 'note',
          'payload': {'message': 'You received a secret love letter! 💌'},
        });
      }

      await loadNotes(duoId, user.id);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> addPhotoMoment({
    required String title,
    required String caption,
    required String photoUrl,
    DateTime? momentDate,
  }) async {
    final pairingState = _ref.read(pairingProvider);
    final duoId = pairingState.space?['id'] as String?;
    final user = _client.auth.currentUser;

    final date = momentDate ?? DateTime.now();
    final cleanCaption = caption.trim();
    final cleanTitle = title.trim();
    final encodedBody = cleanCaption.isNotEmpty
        ? '$cleanCaption\n[PHOTO_URL]:$photoUrl'
        : 'A cherished moment together 💖\n[PHOTO_URL]:$photoUrl';

    final newNote = {
      'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
      'title': cleanTitle,
      'body': cleanCaption.isNotEmpty ? cleanCaption : 'A cherished moment together 💖',
      'media_url': photoUrl,
      'stationery_theme': 'photo_moment',
      'sender_id': user?.id ?? 'me',
      'opened_at': DateTime.now().toIso8601String(),
      'created_at': date.toIso8601String(),
    };

    // Optimistic local update so moment renders instantly
    state = state.copyWith(notes: [newNote, ...state.notes]);

    if (duoId != null && user != null) {
      try {
        await _client.from('notes').insert({
          'duo_id': duoId,
          'sender_id': user.id,
          'title': cleanTitle,
          'body': encodedBody,
          'stationery_theme': 'photo_moment',
          'opened_at': DateTime.now().toIso8601String(),
          'created_at': date.toIso8601String(),
        });

        await loadNotes(duoId, user.id);
      } catch (e) {
        // Keep optimistic note
      }
    }
    return true;
  }

  Future<bool> openNote(String noteId) async {
    try {
      final res = await _client.rpc('mark_note_opened', params: {'p_note_id': noteId});
      if (res != null && res['success'] == true) {
        final pairingState = _ref.read(pairingProvider);
        final duoId = pairingState.space?['id'] as String?;
        final user = _client.auth.currentUser;
        if (duoId != null && user != null) {
          await loadNotes(duoId, user.id);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return NotesNotifier(client, ref);
});
