import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/localization/duo_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/duo_colors.dart';
import '../../../home/presentation/providers/mood_provider.dart';
import '../../../pairing/presentation/providers/pairing_provider.dart';
import '../../../together/presentation/providers/together_provider.dart';
import '../../../prayer/presentation/providers/prayer_provider.dart';

class WidgetPreviewDialog extends ConsumerStatefulWidget {
  const WidgetPreviewDialog({super.key});

  @override
  ConsumerState<WidgetPreviewDialog> createState() => _WidgetPreviewDialogState();
}

class _WidgetPreviewDialogState extends ConsumerState<WidgetPreviewDialog> {
  int _selectedTab = 0; // 0: Small, 1: Medium, 2: Lock Screen

  Future<void> _syncWidgetCache(String partnerName, String moodEmoji, String heroTitle, int daysLeft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('duo_widget_partner_name', partnerName);
    await prefs.setString('duo_widget_partner_mood', moodEmoji);
    await prefs.setString('duo_widget_hero_title', heroTitle);
    await prefs.setInt('duo_widget_days_left', daysLeft);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);
    final pairing = ref.watch(pairingProvider);
    final moodState = ref.watch(moodProvider);
    final togetherState = ref.watch(togetherProvider);
    final prayerState = ref.watch(prayerProvider);

    final partnerName = pairing.partner?['display_name'] as String? ?? 'Partner';
    final partnerMood = moodState.partnerMood ?? 'loved';
    final heroEvent = togetherState.heroCountdown;
    final heroTitle = heroEvent?['title'] as String? ?? 'Our Next Milestone';
    final targetStr = heroEvent?['target_date'] as String?;
    final target = targetStr != null ? DateTime.tryParse(targetStr) : null;
    final daysLeft = target != null ? target.difference(DateTime.now()).inDays : 12;

    _syncWidgetCache(partnerName, '🥰', heroTitle, daysLeft);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? const Color(0xFF1E1C28) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DuoColors.secondary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('📱', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DuoStrings.get('widget_preview_title', locale),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DuoStrings.get('widget_preview_sub', locale),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Segmented size controller
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildSizeTab(0, DuoStrings.get('widget_size_small', locale)),
                  _buildSizeTab(1, DuoStrings.get('widget_size_medium', locale)),
                  _buildSizeTab(2, DuoStrings.get('widget_size_lockscreen', locale)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mock Phone Screen Background
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1518895949257-7621c3c786d7?w=600&auto=format&fit=crop'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.black.withValues(alpha: 0.35),
                ),
                child: Center(
                  child: _buildWidgetPreview(
                    partnerName: partnerName,
                    mood: partnerMood,
                    heroTitle: heroTitle,
                    daysLeft: daysLeft,
                    prayerBoth: prayerState.bothCompletedCount,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Actions: Copy Token & Refresh
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DuoColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Space Token', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      final spaceId = pairing.space?['id'] as String? ?? 'duo_space_active';
                      Clipboard.setData(ClipboardData(text: spaceId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(DuoStrings.get('widget_token_copied', locale)),
                          backgroundColor: const Color(0xFF047857),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Sync Widgets',
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.sync_rounded),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _syncWidgetCache(partnerName, '🥰', heroTitle, daysLeft);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Widget data refreshed! 📱✨'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeTab(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = index);
          HapticFeedback.selectionClick();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? DuoColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWidgetPreview({
    required String partnerName,
    required String mood,
    required String heroTitle,
    required int daysLeft,
    required int prayerBoth,
  }) {
    if (_selectedTab == 0) {
      // Small Widget
      return Container(
        width: 120,
        height: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xE61B1826),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('duo.', style: TextStyle(color: DuoColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                ),
              ],
            ),
            Center(
              child: Column(
                children: [
                  const Text('🥰', style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 2),
                  Text(
                    partnerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Text(
              'Feeling loved • 2h ago',
              style: TextStyle(color: Colors.white60, fontSize: 8),
            ),
          ],
        ),
      );
    } else if (_selectedTab == 1) {
      // Medium Widget
      return Container(
        width: 250,
        height: 115,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xE61B1826),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            // Left: Partner Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Text('🥰', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          partnerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Thinking of you 💓', style: TextStyle(color: DuoColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  if (prayerBoth > 0)
                    Text('🕌 $prayerBoth/5 Prayers', style: const TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Container(width: 1, height: 60, color: Colors.white12),
            const SizedBox(width: 12),

            // Right: Milestone Countdown
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    heroTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${daysLeft}d left',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  const Text('💍 Milestone', style: TextStyle(color: DuoColors.secondary, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Lockscreen Widget
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💍', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              '${daysLeft}d to $heroTitle • $partnerName: 🥰',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
  }
}
