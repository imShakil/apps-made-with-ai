import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/duo_formatters.dart';
import '../../../../core/localization/duo_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/duo_colors.dart';
import '../../../../core/widgets/bouncy_press.dart';
import '../../../prayer/presentation/providers/prayer_provider.dart';
import '../providers/notes_provider.dart';
import 'note_reader_dialog.dart';

class JourneyCalendarView extends ConsumerStatefulWidget {
  const JourneyCalendarView({super.key});

  @override
  ConsumerState<JourneyCalendarView> createState() => _JourneyCalendarViewState();
}

class _JourneyCalendarViewState extends ConsumerState<JourneyCalendarView> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  void _showDaySummary(BuildContext context, DateTime date, List<Map<String, dynamic>> dayNotes, String locale) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedDate = DuoFormatters.formatDate(date, locale);
    final prayerState = ref.read(prayerProvider);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DuoStrings.get('on_this_day', locale),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: DuoColors.primary,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DuoColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🗓️', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (dayNotes.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : const Color(0xFFF9F9FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      DuoStrings.get('no_memories_day', locale),
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  '${DuoStrings.get('recorded_memories', locale)} (${dayNotes.length})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: dayNotes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final n = dayNotes[index];
                      final isPhoto = n['stationery_theme'] == 'photo_moment' || n['media_url'] != null;
                      final title = n['title'] as String? ?? (isPhoto ? 'Photo Moment' : 'Letter');
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pop(ctx);
                          showDialog(
                            context: context,
                            builder: (context) => NoteReaderDialog(note: n),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: DuoColors.primary.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            children: [
                              Text(isPhoto ? '📸' : '💌', style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              if (prayerState.isEnabled && date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Text('🕌', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${DuoStrings.get('prayers_done', locale)}: ${DuoFormatters.formatNumber(prayerState.bothCompletedCount, locale)}/5 ${locale == 'bn' ? 'একসাথে' : 'together'}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);
    final notesState = ref.watch(notesProvider);

    final monthName = DateFormat('MMMM yyyy').format(_displayedMonth);

    // Group notes by YYYY-MM-DD
    final Map<String, List<Map<String, dynamic>>> notesByDate = {};
    for (final note in notesState.notes) {
      final createdStr = note['created_at'] as String?;
      if (createdStr != null) {
        final dt = DateTime.tryParse(createdStr);
        if (dt != null) {
          final key = DateFormat('yyyy-MM-dd').format(dt);
          notesByDate.putIfAbsent(key, () => []).add(note);
        }
      }
    }

    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday % 7; // Sunday = 0

    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);

    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
      children: [
        // Month Navigation Header
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                  onPressed: _prevMonth,
                ),
                Text(
                  monthName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Weekday Headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
            return SizedBox(
              width: 38,
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Calendar Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 0.88,
          ),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (context, index) {
            if (index < firstWeekday) {
              return const SizedBox.shrink();
            }

            final day = index - firstWeekday + 1;
            final cellDate = DateTime(_displayedMonth.year, _displayedMonth.month, day);
            final cellKey = DateFormat('yyyy-MM-dd').format(cellDate);

            final isToday = cellKey == todayKey;
            final dayNotes = notesByDate[cellKey] ?? [];
            final hasLetter = dayNotes.any((n) => n['stationery_theme'] != 'photo_moment');
            final hasPhoto = dayNotes.any((n) => n['stationery_theme'] == 'photo_moment');

            return BouncyPress(
              semanticsLabel: '$day ${DateFormat('MMMM').format(_displayedMonth)}',
              onTap: () => _showDaySummary(context, cellDate, dayNotes, locale),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isToday
                      ? DuoColors.primary.withValues(alpha: isDark ? 0.25 : 0.12)
                      : (isDark ? DuoColors.cardDark : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isToday
                        ? DuoColors.primary
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                    width: isToday ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DuoFormatters.formatNumber(day, locale),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                        color: isToday ? DuoColors.primary : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasLetter)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: DuoColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (hasLetter && hasPhoto) const SizedBox(width: 3),
                        if (hasPhoto)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: DuoColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),
        // Legend card
        Card(
          color: isDark ? const Color(0xFF1B1924) : const Color(0xFFFBFBFD),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: DuoColors.primary, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(locale == 'bn' ? 'চিঠি' : 'Letter', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(width: 16),
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: DuoColors.accent, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(locale == 'bn' ? 'মুহূর্ত' : 'Photo Moment', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(width: 16),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    border: Border.all(color: DuoColors.primary, width: 1.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(locale == 'bn' ? 'আজকের দিন' : 'Today', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
