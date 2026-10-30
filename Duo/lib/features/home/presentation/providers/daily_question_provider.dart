import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../pairing/presentation/providers/pairing_provider.dart';

class DailyQuestionState {
  final Map<String, dynamic>? question;
  final String? sessionId;
  final String? myAnswer;
  final String? partnerAnswer;
  final bool hasPartnerAnswered;
  final String? myGuess;
  final bool? isGuessCorrect;
  final bool isCompleted;
  final bool isLoading;
  final String? error;

  const DailyQuestionState({
    this.question,
    this.sessionId,
    this.myAnswer,
    this.partnerAnswer,
    this.hasPartnerAnswered = false,
    this.myGuess,
    this.isGuessCorrect,
    this.isCompleted = false,
    this.isLoading = false,
    this.error,
  });

  bool get bothAnswered => myAnswer != null && hasPartnerAnswered;

  DailyQuestionState copyWith({
    Map<String, dynamic>? question,
    String? sessionId,
    String? myAnswer,
    String? partnerAnswer,
    bool? hasPartnerAnswered,
    String? myGuess,
    bool? isGuessCorrect,
    bool? isCompleted,
    bool? isLoading,
    String? error,
  }) {
    return DailyQuestionState(
      question: question ?? this.question,
      sessionId: sessionId ?? this.sessionId,
      myAnswer: myAnswer ?? this.myAnswer,
      partnerAnswer: partnerAnswer ?? this.partnerAnswer,
      hasPartnerAnswered: hasPartnerAnswered ?? this.hasPartnerAnswered,
      myGuess: myGuess ?? this.myGuess,
      isGuessCorrect: isGuessCorrect ?? this.isGuessCorrect,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DailyQuestionNotifier extends StateNotifier<DailyQuestionState> {
  final SupabaseClient _client;
  final Ref _ref;
  RealtimeChannel? _subscription;

  static const Map<String, dynamic> defaultQuestion = {
    'id': 'daily_q_default',
    'text_en': 'What is one little thing that always makes you smile?',
    'text_bn': 'আমার কোন ছোট্ট অভ্যাস বা বিষয়টি তোমার মুখে সবসময় হাসি ফোটায়?',
    'category': 'deep_talk',
  };

  DailyQuestionNotifier(this._client, this._ref) : super(const DailyQuestionState(question: defaultQuestion)) {
    init();
    _ref.listen<DuoSpaceState>(pairingProvider, (previous, next) {
      final duoId = next.space?['id'] as String?;
      final user = _client.auth.currentUser;
      if (duoId != null && user != null) {
        loadTodayQuestion(duoId, user.id);
      }
    });
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

    await loadTodayQuestion(duoId, user.id);
  }

  Future<void> loadTodayQuestion(String duoId, String currentUserId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final today = _todayDate;

      // 1. Check for existing session today
      var sessionRes = await _client
          .from('question_sessions')
          .select('*, daily_questions(*)')
          .eq('duo_id', duoId)
          .eq('session_date', today)
          .maybeSingle();

      // 2. If no session exists, create one from questions pool
      if (sessionRes == null) {
        final questionsList = await _client
            .from('daily_questions')
            .select('*')
            .eq('active', true)
            .order('created_at', ascending: true);

        if (questionsList.isNotEmpty) {
          final now = DateTime.now();
          final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
          final pickedQuestion = (questionsList as List<dynamic>)[dayOfYear % questionsList.length] as Map<String, dynamic>;

          final newSession = await _client
              .from('question_sessions')
              .insert({
                'duo_id': duoId,
                'question_id': pickedQuestion['id'],
                'session_date': today,
                'status': 'open',
              })
              .select('*, daily_questions(*)')
              .single();

          sessionRes = newSession;
        }
      }

      if (sessionRes == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final sessionId = sessionRes['id'] as String;
      final questionData = sessionRes['daily_questions'] as Map<String, dynamic>?;

      // 3. Load answers for this session
      final answersRes = await _client
          .from('question_answers')
          .select('*')
          .eq('session_id', sessionId);

      String? myAnswer;
      String? partnerAnswer;
      bool hasPartner = false;
      String? myGuess;
      bool? isGuessCorrect;

      for (final a in answersRes as List<dynamic>) {
        final row = a as Map<String, dynamic>;
        final uid = row['user_id'] as String;
        if (uid == currentUserId) {
          myAnswer = row['answer'] as String?;
          myGuess = row['guessed_answer'] as String?;
          isGuessCorrect = row['is_guess_correct'] as bool?;
        } else {
          hasPartner = true;
          // Partner's answer will only be visible once both have answered!
          partnerAnswer = row['answer'] as String?;
        }
      }

      final bothAnswered = myAnswer != null && hasPartner;

      state = state.copyWith(
        question: questionData,
        sessionId: sessionId,
        myAnswer: myAnswer,
        partnerAnswer: bothAnswered ? partnerAnswer : null,
        hasPartnerAnswered: hasPartner,
        myGuess: myGuess,
        isGuessCorrect: isGuessCorrect,
        isCompleted: sessionRes['status'] == 'completed' || bothAnswered,
        isLoading: false,
      );

      _setupRealtime(sessionId, duoId, currentUserId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _setupRealtime(String sessionId, String duoId, String currentUserId) {
    _subscription?.unsubscribe();

    _subscription = _client
        .channel('public:question_answers:$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'question_answers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (_) {
            loadTodayQuestion(duoId, currentUserId);
          },
        )
        .subscribe();
  }

  Future<bool> submitAnswer(String answer) async {
    final cleanAnswer = answer.trim();
    if (cleanAnswer.isEmpty) return false;

    state = state.copyWith(isLoading: true, error: null);

    final pairingState = _ref.read(pairingProvider);
    final duoId = pairingState.space?['id'] as String?;
    final user = _client.auth.currentUser;

    if (state.sessionId == null && duoId != null && user != null) {
      await loadTodayQuestion(duoId, user.id);
    }

    final sessionId = state.sessionId;

    if (sessionId != null && user != null) {
      try {
        final res = await _client.rpc('submit_question_answer', params: {
          'p_session_id': sessionId,
          'p_answer': cleanAnswer,
        });

        if (res != null && res['success'] == true) {
          if (duoId != null) {
            await loadTodayQuestion(duoId, user.id);
          }
          state = state.copyWith(myAnswer: cleanAnswer, isLoading: false);
          return true;
        }

        // Direct table upsert fallback
        await _client.from('question_answers').upsert({
          'session_id': sessionId,
          'user_id': user.id,
          'answer': cleanAnswer,
        });
        state = state.copyWith(myAnswer: cleanAnswer, isLoading: false);
        return true;
      } catch (e) {
        state = state.copyWith(myAnswer: cleanAnswer, isLoading: false);
        return true;
      }
    } else {
      // Local demo / optimistic submit when offline or pending pairing
      state = state.copyWith(
        myAnswer: cleanAnswer,
        sessionId: state.sessionId ?? 'local_session',
        isLoading: false,
      );
      return true;
    }
  }

  Future<bool?> submitGuess(String guess) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return null;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.rpc('submit_partner_guess', params: {
        'p_session_id': sessionId,
        'p_guess': guess.trim(),
      });

      if (res != null && res['success'] == true) {
        final isCorrect = res['is_correct'] as bool? ?? false;
        final pairingState = _ref.read(pairingProvider);
        final duoId = pairingState.space?['id'] as String?;
        final user = _client.auth.currentUser;
        if (duoId != null && user != null) {
          await loadTodayQuestion(duoId, user.id);
        }
        return isCorrect;
      }
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}

final dailyQuestionProvider = StateNotifierProvider<DailyQuestionNotifier, DailyQuestionState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DailyQuestionNotifier(client, ref);
});
