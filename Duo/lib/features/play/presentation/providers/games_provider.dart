import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../pairing/presentation/providers/pairing_provider.dart';

class TicTacToeState {
  final String? sessionId;
  final List<String?> board; // 9 elements: 'heart', 'star', or null
  final String? currentTurnUserId;
  final String? winnerUserId; // null, user_id, or 'draw'
  final List<int>? winningLine;
  final bool isMyTurn;

  const TicTacToeState({
    this.sessionId,
    this.board = const [null, null, null, null, null, null, null, null, null],
    this.currentTurnUserId,
    this.winnerUserId,
    this.winningLine,
    this.isMyTurn = false,
  });

  TicTacToeState copyWith({
    String? sessionId,
    List<String?>? board,
    String? currentTurnUserId,
    String? winnerUserId,
    List<int>? winningLine,
    bool? isMyTurn,
  }) {
    return TicTacToeState(
      sessionId: sessionId ?? this.sessionId,
      board: board ?? this.board,
      currentTurnUserId: currentTurnUserId ?? this.currentTurnUserId,
      winnerUserId: winnerUserId,
      winningLine: winningLine,
      isMyTurn: isMyTurn ?? this.isMyTurn,
    );
  }
}

class GamesNotifier extends StateNotifier<TicTacToeState> {
  final SupabaseClient _client;
  final Ref _ref;
  RealtimeChannel? _subscription;

  GamesNotifier(this._client, this._ref) : super(const TicTacToeState()) {
    init();
  }

  Future<void> init() async {
    final pairingState = _ref.read(pairingProvider);
    final duoId = pairingState.space?['id'] as String?;
    final user = _client.auth.currentUser;

    if (duoId == null || user == null) return;

    await loadTicTacToe(duoId, user.id);
    _setupRealtime(duoId, user.id);
  }

  Future<void> loadTicTacToe(String duoId, String currentUserId) async {
    try {
      final res = await _client
          .from('game_sessions')
          .select('*')
          .eq('duo_id', duoId)
          .eq('game_type', 'tictactoe')
          .eq('status', 'active')
          .maybeSingle();

      if (res != null) {
        final stateJson = res['state'] as Map<String, dynamic>? ?? {};
        final rawBoard = stateJson['board'] as List<dynamic>? ?? List.filled(9, null);
        final board = rawBoard.map((e) => e as String?).toList();
        final currentTurn = res['current_turn'] as String? ?? currentUserId;
        final winnerId = res['winner_id'] as String?;

        final winLine = _checkWinningLine(board);

        state = TicTacToeState(
          sessionId: res['id'] as String,
          board: board,
          currentTurnUserId: currentTurn,
          winnerUserId: winnerId,
          winningLine: winLine,
          isMyTurn: currentTurn == currentUserId,
        );
      } else {
        // Create initial active game
        await startNewGame();
      }
    } catch (_) {}
  }

  void _setupRealtime(String duoId, String currentUserId) {
    _subscription?.unsubscribe();

    _subscription = _client
        .channel('public:game_sessions:$duoId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'game_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'duo_id',
            value: duoId,
          ),
          callback: (_) {
            loadTicTacToe(duoId, currentUserId);
          },
        )
        .subscribe();
  }

  static const List<List<int>> _winPatterns = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
    [0, 4, 8], [2, 4, 6],             // Diagonals
  ];

  List<int>? _checkWinningLine(List<String?> b) {
    for (final pattern in _winPatterns) {
      final p1 = b[pattern[0]];
      final p2 = b[pattern[1]];
      final p3 = b[pattern[2]];
      if (p1 != null && p1 == p2 && p2 == p3) {
        return pattern;
      }
    }
    return null;
  }

  Future<void> makeMove(int index) async {
    final user = _client.auth.currentUser;
    final pairingState = _ref.read(pairingProvider);
    final partnerId = pairingState.partner?['id'] as String?;
    final duoId = pairingState.space?['id'] as String?;

    if (user == null || partnerId == null || duoId == null) return;
    if (state.board[index] != null || state.winnerUserId != null || !state.isMyTurn) return;

    final isOwner = pairingState.space?['created_by'] == user.id;
    final myToken = isOwner ? 'heart' : 'star';

    final newBoard = List<String?>.from(state.board);
    newBoard[index] = myToken;

    final winLine = _checkWinningLine(newBoard);
    String? winnerId;
    String status = 'active';

    if (winLine != null) {
      winnerId = user.id;
      status = 'completed';
    } else if (!newBoard.contains(null)) {
      winnerId = 'draw';
      status = 'completed';
    }

    final nextTurn = (winLine == null && winnerId == null) ? partnerId : user.id;

    // Optimistic local update
    state = state.copyWith(
      board: newBoard,
      currentTurnUserId: nextTurn,
      winnerUserId: winnerId,
      winningLine: winLine,
      isMyTurn: nextTurn == user.id,
    );

    try {
      if (state.sessionId != null) {
        await _client.from('game_sessions').update({
          'state': {'board': newBoard},
          'current_turn': nextTurn,
          'winner_id': winnerId,
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', state.sessionId!);
      }
    } catch (_) {}
  }

  Future<void> startNewGame() async {
    final user = _client.auth.currentUser;
    final pairingState = _ref.read(pairingProvider);
    final duoId = pairingState.space?['id'] as String?;

    if (user == null || duoId == null) return;

    try {
      // Archive existing active sessions
      await _client
          .from('game_sessions')
          .update({'status': 'completed'})
          .eq('duo_id', duoId)
          .eq('game_type', 'tictactoe')
          .eq('status', 'active');

      final emptyBoard = List<String?>.filled(9, null);

      final insertRes = await _client
          .from('game_sessions')
          .insert({
            'duo_id': duoId,
            'game_type': 'tictactoe',
            'state': {'board': emptyBoard},
            'current_turn': user.id,
            'status': 'active',
          })
          .select('*')
          .single();

      state = TicTacToeState(
        sessionId: insertRes['id'] as String,
        board: emptyBoard,
        currentTurnUserId: user.id,
        isMyTurn: true,
      );
    } catch (_) {
      // Fallback local reset
      resetCouchGame();
    }
  }

  void playCouchMove(int index) {
    if (state.board[index] != null || state.winnerUserId != null) return;
    final heartCount = state.board.where((e) => e == 'heart').length;
    final starCount = state.board.where((e) => e == 'star').length;
    final token = heartCount <= starCount ? 'heart' : 'star';

    final newBoard = List<String?>.from(state.board);
    newBoard[index] = token;

    final winLine = _checkWinningLine(newBoard);
    String? winner;
    if (winLine != null) {
      winner = token == 'heart' ? 'heart_win' : 'star_win';
    } else if (!newBoard.contains(null)) {
      winner = 'draw';
    }

    state = state.copyWith(
      board: newBoard,
      winnerUserId: winner,
      winningLine: winLine,
      isMyTurn: true,
    );
  }

  void resetCouchGame() {
    state = const TicTacToeState(
      board: [null, null, null, null, null, null, null, null, null],
      isMyTurn: true,
    );
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}

final ticTacToeProvider = StateNotifierProvider<GamesNotifier, TicTacToeState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return GamesNotifier(client, ref);
});
