import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/duo_colors.dart';
import '../../../../core/widgets/duo_app_bar.dart';
import '../../../pairing/presentation/providers/pairing_provider.dart';
import '../../../home/presentation/providers/daily_question_provider.dart';
import '../../../home/presentation/widgets/daily_question_answer_sheet.dart';
import '../../../home/presentation/widgets/partner_guess_dialog.dart';
import '../providers/games_provider.dart';
import '../widgets/tic_tac_toe_dialog.dart';
import '../widgets/would_you_rather_dialog.dart';
import '../widgets/truth_or_dare_dialog.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/duo_strings.dart';
import '../../../../core/widgets/bouncy_press.dart';

class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openTicTacToe() {
    showDialog(
      context: context,
      builder: (context) => const TicTacToeDialog(),
    );
  }

  void _openWouldYouRather(String partnerName) {
    showDialog(
      context: context,
      builder: (context) => WouldYouRatherDialog(partnerName: partnerName),
    );
  }

  void _openTruthOrDare(String partnerName) {
    showDialog(
      context: context,
      builder: (context) => TruthOrDareDialog(partnerName: partnerName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);
    final pairingState = ref.watch(pairingProvider);
    final partnerName = pairingState.partner?['display_name'] as String? ?? 'Partner';

    return Scaffold(
      appBar: DuoAppBar(
        title: DuoStrings.get('play_header_title', locale),
        subtitle: DuoStrings.get('play_header_sub', locale),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1C28) : const Color(0xFFF0EAEA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                indicator: BoxDecoration(
                  color: isDark ? DuoColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: DuoColors.primary,
                unselectedLabelColor: isDark ? DuoColors.textMutedDark : DuoColors.textMutedLight,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: DuoStrings.get('tab_quiz', locale)),
                  Tab(text: DuoStrings.get('tab_games', locale)),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTwoTruthsTab(context, partnerName, locale),
                _buildMiniGamesTab(context, partnerName, locale),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoTruthsTab(BuildContext context, String partnerName, String locale) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final questionState = ref.watch(dailyQuestionProvider);

    final question = questionState.question ?? DailyQuestionNotifier.defaultQuestion;
    final textEn = question['text_en'] as String? ?? 'What is one little thing that always makes you smile?';
    final textBn = question['text_bn'] as String?;
    final category = (question['category'] as String? ?? 'Deep Talks').toUpperCase().replaceAll('_', ' ');

    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
      children: [
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
                      DuoStrings.get('daily_quiz_tag', locale),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: DuoColors.secondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: DuoColors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DuoColors.secondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '"$textEn"',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
                ),
                if (textBn != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    textBn,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? DuoColors.textMutedDark : DuoColors.textMutedLight,
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                if (questionState.bothAnswered) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
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
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: DuoColors.secondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('Your Answer: "${questionState.myAnswer}"', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text('$partnerName’s Answer: "${questionState.partnerAnswer}"', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DuoColors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.psychology_rounded, size: 18),
                    label: Text(DuoStrings.get('guess_partner', locale)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => PartnerGuessDialog(partnerName: partnerName, questionText: textEn),
                      );
                    },
                  ),
                ] else if (questionState.myAnswer != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: DuoColors.secondary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
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
                  BouncyPress(
                    semanticsLabel: DuoStrings.get('submit_answer_btn', locale),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        useRootNavigator: true,
                        isScrollControlled: true,
                        backgroundColor: Theme.of(context).cardColor,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                        ),
                        builder: (context) => DailyQuestionAnswerSheet(question: question, partnerName: partnerName),
                      );
                    },
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
                            color: DuoColors.secondary.withValues(alpha: 0.35),
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

        // Quick Category Explorers
        Text(
          DuoStrings.get('explore_categories', locale),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildCategoryChip(
                DuoStrings.get('cat_deep', locale),
                Icons.favorite_rounded,
                DuoColors.primary,
                () => _showCategorySheet(context, 'Deep Talks', partnerName),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCategoryChip(
                DuoStrings.get('cat_romance', locale),
                Icons.auto_awesome_rounded,
                DuoColors.secondary,
                () => _showCategorySheet(context, 'Romance', partnerName),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildCategoryChip(
                DuoStrings.get('cat_memories', locale),
                Icons.photo_library_rounded,
                DuoColors.accent,
                () => _showCategorySheet(context, 'Memories', partnerName),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCategoryChip(
                DuoStrings.get('cat_playful', locale),
                Icons.sentiment_very_satisfied_rounded,
                DuoColors.mint,
                () => _showCategorySheet(context, 'Playful', partnerName),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color),
          ],
        ),
      ),
    );
  }

  void _showCategorySheet(BuildContext context, String categoryName, String partnerName) {
    final Map<String, List<Map<String, String>>> pool = {
      'Deep Talks': [
        {
          'text_en': 'What is one small thing I do that makes you feel deeply loved?',
          'text_bn': 'আমার এমন কোন ছোট্ট অভ্যাস বা কাজ আছে যা তোমাকে সবচেয়ে বেশি ভালোবাসার অনুভূতি দেয়?',
          'category': 'deep_talk',
        },
        {
          'text_en': 'When you are feeling stressed or overwhelmed, what comforts you the most?',
          'text_bn': 'যখন তুমি মানসিক চাপে বা ক্লান্ত থাকো, তখন কোন জিনিসটি তোমাকে সবচেয়ে বেশি স্বস্তি দেয়?',
          'category': 'deep_talk',
        },
        {
          'text_en': 'What is one dream or goal for our future that excites you the most?',
          'text_bn': 'আমাদের ভবিষ্যৎ নিয়ে কোন স্বপ্ন বা লক্ষ্যটি তোমাকে সবচেয়ে বেশি রোমাঞ্চিত করে?',
          'category': 'deep_talk',
        },
        {
          'text_en': 'What is one thing about yourself that you feel only I truly understand?',
          'text_bn': 'নিজের কোন বিষয়টি তোমার মনে হয় কেবল আমিই গভীরভাবে বুঝতে পারি?',
          'category': 'deep_talk',
        },
      ],
      'Romance': [
        {
          'text_en': 'What was the first thing you noticed about me when we first met?',
          'text_bn': 'আমাদের প্রথম দেখার দিনে আমার কোন দিকটা তোমার প্রথম চোখে পড়েছিল?',
          'category': 'romance',
        },
        {
          'text_en': 'What is a quality in me that you admire, even if you do not say it often?',
          'text_bn': 'আমার এমন কোন গুণটি তোমার ভালো লাগে যা তুমি হয়তো সচরাচর মুখে বলো না?',
          'category': 'romance',
        },
        {
          'text_en': 'What is your ideal romantic date: a rainy day inside or an adventurous road trip?',
          'text_bn': 'তোমার কাছে পারফেক্ট রোমান্টিক ডেট কোনটি: বৃষ্টির দিনে ঘরে একসাথে বসে থাকা, নাকি লং ড্রাইভে বের হওয়া?',
          'category': 'romance',
        },
        {
          'text_en': 'What song or melody always reminds you of me when you hear it?',
          'text_bn': 'কোন গান বা সুর শুনলেই তোমার আমার কথা মনে পড়ে?',
          'category': 'romance',
        },
      ],
      'Memories': [
        {
          'text_en': 'What is your favorite memory of us from the past year?',
          'text_bn': 'গত এক বছরে আমাদের কাটানো কোন স্মৃতিটি তোমার সবচেয়ে প্রিয়?',
          'category': 'memories',
        },
        {
          'text_en': 'If we could freeze one moment in time from our relationship, which one would you choose?',
          'text_bn': 'আমাদের সম্পর্কের যে কোনো একটি মুহূর্তকে যদি চিরতরে থামিয়ে রাখা যেত, তুমি কোনটি বেছে নিতে?',
          'category': 'memories',
        },
        {
          'text_en': 'What is the funniest photo or video we have ever taken together?',
          'text_bn': 'আমাদের একসঙ্গে তোলা সবচেয়ে মজার ছবি বা ভিডিও কোনটি?',
          'category': 'memories',
        },
        {
          'text_en': 'Where was the most magical place we have ever been together?',
          'text_bn': 'একসঙ্গে যাওয়া কোন জায়গাটিকে তোমার সবচেয়ে জাদুকরী মনে হয়েছিল?',
          'category': 'memories',
        },
      ],
      'Playful': [
        {
          'text_en': 'If we were stranded on a deserted tropical island, which of us would survive longer?',
          'text_bn': 'যদি আমরা কোনো নির্জন দ্বীপে আটকে যাই, আমাদের দুজনের মধ্যে কে বেশি দিন টিকে থাকতে পারবে বলে মনে হয়?',
          'category': 'playful',
        },
        {
          'text_en': 'What is the funniest or most silly misunderstanding we have ever had?',
          'text_bn': 'আমাদের মধ্যে হওয়া সবচেয়ে মজার বা অদ্ভুত ভুল বোঝাবুঝি কোনটি ছিল?',
          'category': 'playful',
        },
        {
          'text_en': 'If we could adopt any pet in the world together tomorrow, what would you pick?',
          'text_bn': 'কালই যদি আমরা একসঙ্গে যেকোনো একটি পোষা প্রাণী নিতে পারতাম, তুমি কোনটি পছন্দ করতে?',
          'category': 'playful',
        },
        {
          'text_en': 'What is my guilty pleasure food that I secretly love the most?',
          'text_bn': 'আমার এমন কোন খাবারটি খুব পছন্দ যা আমি একটু লুকিয়ে বা অপরাধবোধ নিয়ে উপভোগ করি?',
          'category': 'playful',
        },
      ],
    };

    final questions = pool[categoryName] ?? [];

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        categoryName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: DuoColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${questions.length} questions',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DuoColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap any question to answer and compare thoughts with your partner:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ...questions.map((q) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          '"${q['text_en']}"',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            q['text_bn'] ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: DuoColors.primary),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          showModalBottomSheet(
                            context: context,
                            useRootNavigator: true,
                            isScrollControlled: true,
                            backgroundColor: Theme.of(context).cardColor,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                            ),
                            builder: (context) => DailyQuestionAnswerSheet(
                              question: q,
                              partnerName: partnerName,
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMiniGamesTab(BuildContext context, String partnerName, String locale) {
    final tttState = ref.watch(ticTacToeProvider);

    String tttTag;
    Color tttColor;
    if (tttState.winnerUserId != null) {
      tttTag = locale == 'bn' ? 'সমাপ্ত' : 'FINISHED';
      tttColor = Colors.grey;
    } else if (tttState.isMyTurn) {
      tttTag = locale == 'bn' ? 'তোমার চাল ❤️' : 'YOUR TURN ❤️';
      tttColor = DuoColors.primary;
    } else {
      tttTag = locale == 'bn' ? '$partnerName এর চাল ⭐' : 'PARTNER’S TURN ⭐';
      tttColor = DuoColors.secondary;
    }

    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
      children: [
        // Game 1: Tic-Tac-Toe
        _buildGameCard(
          context,
          title: DuoStrings.get('game_ttt_title', locale),
          tag: tttTag,
          tagColor: tttColor,
          subtitle: tttState.isMyTurn
              ? (locale == 'bn' ? 'তোমার চাল! বোর্ডে তোমার প্রতীক বসাও।' : 'Your move! Place your token on the board.')
              : (locale == 'bn' ? '$partnerName এর চালের অপেক্ষায়...' : 'Waiting for $partnerName’s move...'),
          icon: '❤️',
          actionText: locale == 'bn' ? 'টিক-ট্যাক-টো খেলুন' : 'Play Tic-Tac-Toe',
          onTap: _openTicTacToe,
        ),
        const SizedBox(height: 14),

        // Game 2: Would You Rather
        _buildGameCard(
          context,
          title: DuoStrings.get('game_wyr_title', locale),
          tag: locale == 'bn' ? 'যুগল সিদ্ধান্ত' : 'COUPLE DILEMMAS',
          tagColor: DuoColors.secondary,
          subtitle: locale == 'bn'
              ? 'মজার, গভীর এবং রোমান্টিক পরিস্থিতিতে নিজেদের পছন্দ তুলনা করুন।'
              : 'Compare choices on funny, deep, and romantic scenarios.',
          icon: '💬',
          actionText: locale == 'bn' ? 'সিদ্ধান্ত বেছে নিন' : 'Pick Dilemmas',
          onTap: () => _openWouldYouRather(partnerName),
        ),
        const SizedBox(height: 14),

        // Game 3: Truth or Dare
        _buildGameCard(
          context,
          title: DuoStrings.get('game_tod_title', locale),
          tag: locale == 'bn' ? 'রোমান্স ও চ্যালেঞ্জ' : 'ROMANCE & DARES',
          tagColor: DuoColors.accent,
          subtitle: locale == 'bn'
              ? 'দুজনের জন্য মিষ্টি দুষ্টুমি ও রোমান্টিক চ্যালেঞ্জ।'
              : 'Playful questions and intimate challenges for two.',
          icon: '🔥',
          actionText: locale == 'bn' ? 'চ্যালেঞ্জ ড্র করুন' : 'Draw Challenge',
          onTap: () => _openTruthOrDare(partnerName),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String tag,
    required Color tagColor,
    required String subtitle,
    required String icon,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return BouncyPress(
      semanticsLabel: '$title: $actionText',
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: tagColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tagColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onTap,
                child: Text(actionText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
