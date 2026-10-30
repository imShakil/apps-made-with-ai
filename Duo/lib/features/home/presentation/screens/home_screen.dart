import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/duo_colors.dart';
import '../../../../core/widgets/duo_app_bar.dart';
import '../../../../core/widgets/bouncy_press.dart';
import '../../../../core/widgets/duo_progress_bar.dart';
import '../../../pairing/presentation/providers/pairing_provider.dart';
import '../../../together/presentation/providers/together_provider.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../providers/mood_provider.dart';
import '../providers/daily_question_provider.dart';
import '../widgets/daily_question_answer_sheet.dart';
import '../widgets/partner_guess_dialog.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/duo_strings.dart';
import '../../../../core/localization/duo_formatters.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<Map<String, String>> _moods = [
    {'emoji': '😊', 'label': 'Happy', 'id': 'happy'},
    {'emoji': '🥰', 'label': 'Loved', 'id': 'loved'},
    {'emoji': '😴', 'label': 'Tired', 'id': 'tired'},
    {'emoji': '😔', 'label': 'Down', 'id': 'down'},
    {'emoji': '🤩', 'label': 'Excited', 'id': 'excited'},
  ];

  String _getMoodEmoji(String? moodId) {
    return _moods.firstWhere(
      (m) => m['id'] == moodId,
      orElse: () => {'emoji': '🥰'},
    )['emoji']!;
  }

  String _getMoodLabel(String? moodId) {
    return _moods.firstWhere(
      (m) => m['id'] == moodId,
      orElse: () => {'label': 'Good'},
    )['label']!;
  }

  void _showAnswerSheet(Map<String, dynamic> question, String partnerName) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => DailyQuestionAnswerSheet(
        question: question,
        partnerName: partnerName,
      ),
    );
  }

  void _showGuessDialog(String partnerName, String questionText) {
    showDialog(
      context: context,
      builder: (context) => PartnerGuessDialog(
        partnerName: partnerName,
        questionText: questionText,
      ),
    );
  }

  void _showMoodNoteDialog(String moodId) {
    final currentMsg = ref.read(moodProvider).myMessage ?? '';
    final controller = TextEditingController(text: currentMsg);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add a Thought for Partner 💭'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          decoration: const InputDecoration(
            hintText: 'e.g. Missing you today, busy morning...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              ref.read(moodProvider.notifier).setMood(moodId, message: text.isEmpty ? null : text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  void _sendQuickHug(BuildContext context, String locale) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🤗', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DuoStrings.get('hug_sent_toast', locale),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: DuoColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);
    final pairingState = ref.watch(pairingProvider);
    final user = ref.watch(currentUserProvider);
    final moodState = ref.watch(moodProvider);
    final questionState = ref.watch(dailyQuestionProvider);
    final togetherState = ref.watch(togetherProvider);

    final myName = user?.userMetadata?['full_name'] as String? ?? 'You';
    final partnerName = pairingState.partner?['display_name'] as String? ?? 'Partner';
    final coupleGreeting = '$myName & $partnerName ✨';
    final activeMood = moodState.myMood;

    final heroEvent = togetherState.heroCountdown;
    String countdownTitle = DuoStrings.get('plan_milestone_title', locale);
    String countdownSubtitle = DuoStrings.get('plan_milestone_sub', locale);
    String countdownIcon = '💍';
    String? daysBadge;

    if (heroEvent != null) {
      countdownTitle = heroEvent['title'] as String? ?? 'Our Special Milestone';
      countdownIcon = heroEvent['icon'] as String? ?? '💍';
      final targetStr = heroEvent['target_date'] as String?;
      final target = targetStr != null ? DateTime.tryParse(targetStr) : null;
      if (target != null) {
        final daysLeft = target.difference(DateTime.now()).inDays;
        final formatted = DuoFormatters.formatDate(target, locale);
        if (daysLeft < 0) {
          countdownSubtitle = 'Passed on $formatted';
          daysBadge = '${DuoFormatters.formatNumber(0, locale)}d';
        } else if (daysLeft == 0) {
          countdownSubtitle = 'Today is the day! 🎉';
          daysBadge = DuoStrings.get('today_tag', locale);
        } else {
          countdownSubtitle = 'In ${DuoFormatters.formatDays(daysLeft, locale)} • $formatted';
          daysBadge = '${DuoFormatters.formatNumber(daysLeft, locale)}d';
        }
      }
    }

    final greeting = DuoFormatters.getTimeGreeting(locale);
    final localizedStreak = DuoFormatters.formatNumber(moodState.streakDays, locale);
    final streakProgress = ((moodState.streakDays % 7) / 7.0).clamp(0.15, 1.0);

    return Scaffold(
      appBar: DuoAppBar(
        title: DuoStrings.get('app_title', locale),
        subtitle: '$greeting • $coupleGreeting',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Daily Mood Check-In & Streak Hero Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DuoStrings.get('todays_mood', locale),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: DuoColors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? DuoColors.surfaceWarmDark : DuoColors.surfaceWarm,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '🔥 $localizedStreak ${DuoStrings.get('streak_suffix', locale)}',
                            style: const TextStyle(fontSize: 11, color: DuoColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DuoStrings.get('how_feeling', locale),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    // Micro Progress Bar for weekly streak milestone
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DuoStrings.get('streak_target', locale),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? DuoColors.textMutedDark : DuoColors.textMutedLight,
                              ),
                            ),
                            Text(
                              '${DuoFormatters.formatNumber(moodState.streakDays % 7, locale)}/ ${DuoFormatters.formatNumber(7, locale)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: DuoColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        DuoProgressBar(progress: streakProgress, height: 6),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Mood Selector with BouncyPress
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _moods.map((m) {
                        final isSelected = activeMood == m['id'];
                        final moodLabel = DuoStrings.get('mood_${m['id']}', locale);
                        return BouncyPress(
                          semanticsLabel: moodLabel,
                          onTap: () {
                            ref.read(moodProvider.notifier).setMood(m['id']!);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? DuoColors.primary.withValues(alpha: 0.15)
                                  : (isDark ? Colors.black26 : DuoColors.bgLight),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? DuoColors.primary : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(m['emoji']!, style: const TextStyle(fontSize: 26)),
                                const SizedBox(height: 4),
                                Text(
                                  moodLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? DuoColors.primary : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (activeMood != null) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: DuoColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: Text(
                            moodState.myMessage != null
                                ? 'Note: "${moodState.myMessage}" (Tap to edit)'
                                : DuoStrings.get('add_note_partner', locale),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () => _showMoodNoteDialog(activeMood),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Partner Mood Snapshot
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black38 : DuoColors.bgLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Text(
                            moodState.partnerMood != null ? _getMoodEmoji(moodState.partnerMood) : '💭',
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: moodState.partnerMood != null
                                ? RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? DuoColors.textPrimaryDark : DuoColors.textPrimaryLight,
                                      ),
                                      children: [
                                        TextSpan(text: '$partnerName ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        TextSpan(text: locale == 'bn' ? ' বোধ করছেন ' : ' feels '),
                                        TextSpan(
                                          text: _getMoodLabel(moodState.partnerMood),
                                          style: const TextStyle(color: DuoColors.primary, fontWeight: FontWeight.bold),
                                        ),
                                        if (moodState.partnerMessage != null)
                                          TextSpan(text: ' ("${moodState.partnerMessage}")'),
                                      ],
                                    ),
                                  )
                                : Text(
                                    DuoStrings.get('waiting_checkin', locale),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: isDark ? DuoColors.textMutedDark : DuoColors.textMutedLight,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Question of the Day Card (TwoTruths Engine)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DuoStrings.get('question_of_day', locale),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: DuoColors.secondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: DuoColors.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (questionState.question?['category'] as String? ?? 'Deep Talks')
                                .toUpperCase()
                                .replaceAll('_', ' '),
                            style: const TextStyle(fontSize: 11, color: DuoColors.secondary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '"${questionState.question?['text_en'] ?? 'What is one little thing that always makes you smile?'}"',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18),
                    ),
                    if (questionState.question?['text_bn'] != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        questionState.question!['text_bn'],
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? DuoColors.textMutedDark : DuoColors.textMutedLight,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // State Display: Unanswered vs Locked vs Revealed
                    if (questionState.bothAnswered) ...[
                      // Reveal Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: DuoColors.secondary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: DuoColors.secondary.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('✨', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  DuoStrings.get('both_revealed', locale),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: DuoColors.secondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '$myName: "${questionState.myAnswer}"',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$partnerName: "${questionState.partnerAnswer}"',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DuoColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.psychology_rounded, size: 18),
                        label: Text(DuoStrings.get('guess_partner', locale)),
                        onPressed: () {
                          final qText = questionState.question?['text_en'] as String? ?? '';
                          _showGuessDialog(partnerName, qText);
                        },
                      ),
                    ] else if (questionState.myAnswer != null) ...[
                      // Waiting for partner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DuoColors.secondary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: DuoColors.secondary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_rounded, size: 20, color: DuoColors.secondary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                DuoStrings.get('answer_locked', locale),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Action needed: Answer question
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DuoColors.secondary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: DuoColors.secondary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_clock_rounded, size: 20, color: DuoColors.secondary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                questionState.hasPartnerAnswered
                                    ? DuoStrings.get('partner_answered_cta', locale)
                                    : DuoStrings.get('answers_private_info', locale),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      BouncyPress(
                        semanticsLabel: DuoStrings.get('submit_answer_btn', locale),
                        onTap: () => _showAnswerSheet(
                          questionState.question ?? DailyQuestionNotifier.defaultQuestion,
                          partnerName,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [DuoColors.secondary, Color(0xFFB5A9FC)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: DuoColors.secondary.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              DuoStrings.get('submit_answer_btn', locale),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Quick Connect Actions Bar (Send Hug, Secret Note, Play)
            Row(
              children: [
                Expanded(
                  child: BouncyPress(
                    semanticsLabel: DuoStrings.get('send_hug', locale),
                    onTap: () => _sendQuickHug(context, locale),
                    child: Card(
                      color: isDark ? DuoColors.cardDark : DuoColors.surfaceWarm,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🤗', style: TextStyle(fontSize: 24)),
                            const SizedBox(height: 6),
                            Text(
                              DuoStrings.get('send_hug', locale),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: DuoColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BouncyPress(
                    semanticsLabel: DuoStrings.get('secret_note_title', locale),
                    onTap: () => context.go('/memories'),
                    child: Card(
                      color: isDark ? DuoColors.cardDark : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('💌', style: TextStyle(fontSize: 24)),
                            const SizedBox(height: 6),
                            Text(
                              DuoStrings.get('secret_note_title', locale),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? DuoColors.textPrimaryDark : DuoColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BouncyPress(
                    semanticsLabel: DuoStrings.get('together_play_title', locale),
                    onTap: () => context.go('/play'),
                    child: Card(
                      color: isDark ? DuoColors.cardDark : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🎮', style: TextStyle(fontSize: 24)),
                            const SizedBox(height: 6),
                            Text(
                              DuoStrings.get('together_play_title', locale),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? DuoColors.textPrimaryDark : DuoColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Upcoming Countdown Special Day Card
            BouncyPress(
              semanticsLabel: countdownTitle,
              onTap: () => context.go('/together'),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: DuoColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(countdownIcon, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              countdownTitle,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              countdownSubtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? DuoColors.textMutedDark : DuoColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (daysBadge != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: DuoColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            daysBadge,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD49B00),
                            ),
                          ),
                        ),
                      ] else ...[
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
