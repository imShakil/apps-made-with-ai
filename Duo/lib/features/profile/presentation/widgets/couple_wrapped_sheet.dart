import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/duo_formatters.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/duo_colors.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../home/presentation/providers/mood_provider.dart';
import '../../../memories/presentation/providers/notes_provider.dart';
import '../../../pairing/presentation/providers/pairing_provider.dart';
import '../../../together/presentation/providers/together_provider.dart';

class CoupleWrappedSheet extends ConsumerStatefulWidget {
  const CoupleWrappedSheet({super.key});

  @override
  ConsumerState<CoupleWrappedSheet> createState() => _CoupleWrappedSheetState();
}

class _CoupleWrappedSheetState extends ConsumerState<CoupleWrappedSheet> {
  int _currentSlide = 0;
  static const int _totalSlides = 5;
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      if (_currentSlide < _totalSlides - 1) {
        setState(() => _currentSlide++);
      } else {
        _autoAdvanceTimer?.cancel();
      }
    });
  }

  void _nextSlide() {
    HapticFeedback.lightImpact();
    if (_currentSlide < _totalSlides - 1) {
      setState(() => _currentSlide++);
      _startTimer();
    }
  }

  void _prevSlide() {
    HapticFeedback.lightImpact();
    if (_currentSlide > 0) {
      setState(() => _currentSlide--);
      _startTimer();
    }
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final pairing = ref.watch(pairingProvider);
    final moodState = ref.watch(moodProvider);
    final notesState = ref.watch(notesProvider);
    final togetherState = ref.watch(togetherProvider);
    final user = ref.watch(currentUserProvider);

    final myName = user?.userMetadata?['full_name'] as String? ?? 'You';
    final partnerName = pairing.partner?['display_name'] as String? ?? 'Partner';

    final totalNotes = notesState.notes.length;
    final voiceNotes = notesState.notes.where((n) => (n['body'] as String? ?? '').contains('[VOICE_WHISPER]:')).length;
    final photoNotes = notesState.notes.where((n) => n['stationery_theme'] == 'photo_moment' || n['media_url'] != null).length;
    final totalDreams = togetherState.bucketItems.length;
    final completedDreams = togetherState.bucketItems.where((b) => b['completed'] == true).length;
    final streak = moodState.streakDays;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0E17),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DuoColors.primary.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DuoColors.secondary.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Column
          Column(
            children: [
              const SizedBox(height: 12),
              // Story Bars
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: List.generate(_totalSlides, (index) {
                    final isVisited = index < _currentSlide;
                    final isCurrent = index == _currentSlide;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: isVisited || isCurrent
                              ? DuoColors.primary
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 14),

              // Header bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('🎁', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          '$myName & $partnerName’s Wrapped',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Active Slide Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  child: _buildSlideContent(
                    slideIndex: _currentSlide,
                    myName: myName,
                    partnerName: partnerName,
                    streak: streak,
                    totalNotes: totalNotes,
                    voiceNotes: voiceNotes,
                    photoNotes: photoNotes,
                    totalDreams: totalDreams,
                    completedDreams: completedDreams,
                    locale: locale,
                  ),
                ),
              ),

              // Footer navigation helper
              Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_currentSlide + 1} of $_totalSlides',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    if (_currentSlide == _totalSlides - 1)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DuoColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text('Share Recap 💖'),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          final text = '✨ Duo Couple Wrapped ✨\n$myName & $partnerName\n🔥 $streak Day Check-In Streak\n💌 $totalNotes Letters Exchanged\n🌍 $completedDreams Dreams Achieved Together!';
                          Clipboard.setData(ClipboardData(text: text));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Couple Wrapped summary copied to clipboard! 📋✨'),
                              backgroundColor: Color(0xFF047857),
                            ),
                          );
                        },
                      )
                    else
                      Text(
                        locale == 'bn' ? 'ট্যাপ করে পরবর্তী স্টোরি দেখুন' : 'Tap sides to navigate',
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Tap gesture areas (left side: prev, right side: next)
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _prevSlide,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _nextSlide,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideContent({
    required int slideIndex,
    required String myName,
    required String partnerName,
    required int streak,
    required int totalNotes,
    required int voiceNotes,
    required int photoNotes,
    required int totalDreams,
    required int completedDreams,
    required String locale,
  }) {
    switch (slideIndex) {
      case 0:
        return _buildSlide(
          badge: 'MILESTONE STREAK 🔥',
          title: 'You two stayed in sync for',
          bigStat: '${DuoFormatters.formatNumber(streak, locale)} Days',
          subtitle: streak > 1
              ? 'Never letting a day go by without letting $partnerName know you care.'
              : 'Every single journey of a thousand miles begins with a shared heartbeat.',
          emoji: '🔥',
        );
      case 1:
        return _buildSlide(
          badge: 'EMOTIONAL FOOTPRINT 🥰',
          title: 'Your highest recorded vibe together:',
          bigStat: 'Deeply Loved',
          subtitle: 'From morning check-ins to midnight thoughts, warmth was your couple signature.',
          emoji: '💖',
        );
      case 2:
        return _buildSlide(
          badge: 'SECRET LETTERS 💌',
          title: 'Words whispered across distance:',
          bigStat: '${DuoFormatters.formatNumber(totalNotes, locale)} Letters',
          subtitle: '$photoNotes visual photo moments and $voiceNotes intimate voice whispers preserved forever.',
          emoji: '🎙️',
        );
      case 3:
        return _buildSlide(
          badge: 'DREAMS & ADVENTURES 🌍',
          title: 'Adventures planned together:',
          bigStat: '${DuoFormatters.formatNumber(totalDreams, locale)} Bucket Goals',
          subtitle: '$completedDreams dreams already checked off! The world is better when experienced together.',
          emoji: '✈️',
        );
      case 4:
      default:
        return _buildSlide(
          badge: 'COUPLE ARCHETYPE ✨',
          title: 'Your 2026 Duo Persona:',
          bigStat: 'The Soulmate Orbit',
          subtitle: 'A rare celestial harmony where two distinct worlds complete each other effortlessly.',
          emoji: '👑',
        );
    }
  }

  Widget _buildSlide({
    required String badge,
    required String title,
    required String bigStat,
    required String subtitle,
    required String emoji,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: DuoColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DuoColors.primary.withValues(alpha: 0.4)),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              color: DuoColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          emoji,
          style: const TextStyle(fontSize: 64),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          bigStat,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
