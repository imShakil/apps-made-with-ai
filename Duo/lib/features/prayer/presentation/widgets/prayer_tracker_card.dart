import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/duo_formatters.dart';
import '../../../../core/localization/duo_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/widgets/bouncy_press.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../pairing/presentation/providers/pairing_provider.dart';
import '../providers/prayer_provider.dart';

class PrayerTrackerCard extends ConsumerWidget {
  const PrayerTrackerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerState = ref.watch(prayerProvider);
    if (!prayerState.isEnabled) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);
    final pairingState = ref.watch(pairingProvider);
    final user = ref.watch(currentUserProvider);

    final partnerName = pairingState.partner?['display_name'] as String? ?? 'Partner';
    final myName = user?.userMetadata?['full_name'] as String? ?? 'You';

    final totalCompleted = prayerState.myCompletedCount;
    final bothCompleted = prayerState.bothCompletedCount;

    // Listen for nudges and celebrations
    ref.listen<PrayerState>(prayerProvider, (previous, next) {
      if (next.lastNudgeMessage != null && previous?.lastNudgeMessage != next.lastNudgeMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('🤲', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(child: Text(next.lastNudgeMessage!, style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
            backgroundColor: const Color(0xFF134E4A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
        ref.read(prayerProvider.notifier).clearNudge();
      }

      if (next.showCelebration && previous?.showCelebration != true) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DuoStrings.get('prayed_together_toast', locale),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF047857),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 3),
          ),
        );
        ref.read(prayerProvider.notifier).clearCelebration();
      }
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title & Both-Completed Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('🕌', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DuoStrings.get('prayer_card_title', locale),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Color(0xFF059669),
                          ),
                        ),
                        Text(
                          bothCompleted == 5
                              ? DuoStrings.get('both_completed_all', locale)
                              : '${DuoFormatters.formatNumber(totalCompleted, locale)}/5 ${locale == 'bn' ? 'আদায় হয়েছে' : 'prayed'} • ${DuoFormatters.formatNumber(bothCompleted, locale)} ${locale == 'bn' ? 'একসাথে' : 'together'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (bothCompleted == 5)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '✨ 5/5',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Text(
                    '${((totalCompleted / 5) * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Horizontal List of 5 Prayers
            Row(
              children: [
                _buildPrayerPill(
                  context: context,
                  ref: ref,
                  prayerKey: 'fajr',
                  label: DuoStrings.get('prayer_fajr', locale),
                  icon: '🌅',
                  isMe: prayerState.isPrayedByMe('fajr'),
                  isPartner: prayerState.isPrayedByPartner('fajr'),
                  partnerName: partnerName,
                  myName: myName,
                  locale: locale,
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildPrayerPill(
                  context: context,
                  ref: ref,
                  prayerKey: 'dhuhr',
                  label: DuoStrings.get('prayer_dhuhr', locale),
                  icon: '☀️',
                  isMe: prayerState.isPrayedByMe('dhuhr'),
                  isPartner: prayerState.isPrayedByPartner('dhuhr'),
                  partnerName: partnerName,
                  myName: myName,
                  locale: locale,
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildPrayerPill(
                  context: context,
                  ref: ref,
                  prayerKey: 'asr',
                  label: DuoStrings.get('prayer_asr', locale),
                  icon: '🌤️',
                  isMe: prayerState.isPrayedByMe('asr'),
                  isPartner: prayerState.isPrayedByPartner('asr'),
                  partnerName: partnerName,
                  myName: myName,
                  locale: locale,
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildPrayerPill(
                  context: context,
                  ref: ref,
                  prayerKey: 'maghrib',
                  label: DuoStrings.get('prayer_maghrib', locale),
                  icon: '🌇',
                  isMe: prayerState.isPrayedByMe('maghrib'),
                  isPartner: prayerState.isPrayedByPartner('maghrib'),
                  partnerName: partnerName,
                  myName: myName,
                  locale: locale,
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildPrayerPill(
                  context: context,
                  ref: ref,
                  prayerKey: 'isha',
                  label: DuoStrings.get('prayer_isha', locale),
                  icon: '🌙',
                  isMe: prayerState.isPrayedByMe('isha'),
                  isPartner: prayerState.isPrayedByPartner('isha'),
                  partnerName: partnerName,
                  myName: myName,
                  locale: locale,
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 10),
            // Caption helper
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  locale == 'bn'
                      ? 'ট্যাপ করে সম্পন্ন করুন • চেপে ধরে সাথীকে তাগিদ দিন'
                      : 'Tap to check • Long press to nudge partner',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      myName,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      partnerName,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerPill({
    required BuildContext context,
    required WidgetRef ref,
    required String prayerKey,
    required String label,
    required String icon,
    required bool isMe,
    required bool isPartner,
    required String partnerName,
    required String myName,
    required String locale,
    required bool isDark,
  }) {
    final bothPrayed = isMe && isPartner;

    Color bg;
    Border? border;

    if (bothPrayed) {
      bg = const Color(0xFF10B981).withValues(alpha: isDark ? 0.28 : 0.2);
      border = Border.all(color: const Color(0xFF10B981), width: 1.6);
    } else if (isMe) {
      bg = const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.12);
      border = Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.6), width: 1.2);
    } else {
      bg = isDark ? Colors.black26 : const Color(0xFFF7F8FA);
      border = Border.all(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
      );
    }

    return Expanded(
      child: Tooltip(
        message: '$label: ${isMe ? "You prayed" : "Not yet"} | $partnerName: ${isPartner ? "Prayed" : "Not yet"} (Long press to nudge)',
        child: BouncyPress(
          semanticsLabel: label,
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.lightImpact();
            ref.read(prayerProvider.notifier).togglePrayer(prayerKey);
          },
          onLongPress: () async {
            HapticFeedback.mediumImpact();
            final sent = await ref.read(prayerProvider.notifier).sendPrayerNudge(prayerKey, partnerName, myName);
            if (sent && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(DuoStrings.get('prayer_nudge_toast', locale)),
                  backgroundColor: const Color(0xFF047857),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: border,
                boxShadow: bothPrayed
                    ? [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: (isMe || bothPrayed) ? FontWeight.bold : FontWeight.w500,
                      color: bothPrayed
                          ? const Color(0xFF059669)
                          : (isMe
                              ? const Color(0xFF10B981)
                              : (isDark ? Colors.grey[400] : Colors.grey[700])),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Partner & Me status dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // My dot
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF10B981) : Colors.transparent,
                          border: Border.all(
                            color: isMe ? const Color(0xFF10B981) : Colors.grey.withValues(alpha: 0.4),
                            width: 1,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: isMe
                            ? const Icon(Icons.check, size: 5, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 3),
                      // Partner dot
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isPartner ? const Color(0xFFF59E0B) : Colors.transparent,
                          border: Border.all(
                            color: isPartner ? const Color(0xFFF59E0B) : Colors.grey.withValues(alpha: 0.4),
                            width: 1,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: isPartner
                            ? const Icon(Icons.favorite, size: 4, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}
