import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/duo_colors.dart';
import '../../../../core/widgets/duo_app_bar.dart';
import '../../../../core/widgets/bouncy_press.dart';
import '../../../../core/widgets/duo_progress_bar.dart';
import '../../../pairing/presentation/providers/pairing_provider.dart';
import '../providers/together_provider.dart';
import '../widgets/add_bucket_item_sheet.dart';
import '../widgets/add_countdown_sheet.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/duo_strings.dart';
import '../../../../core/localization/duo_formatters.dart';

class TogetherScreen extends ConsumerStatefulWidget {
  const TogetherScreen({super.key});

  @override
  ConsumerState<TogetherScreen> createState() => _TogetherScreenState();
}

class _TogetherScreenState extends ConsumerState<TogetherScreen> {
  String _selectedCategory = 'all';

  void _openAddBucketItem(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => const AddBucketItemSheet(),
    );
  }

  void _openCountdownSheet(BuildContext context, {Map<String, dynamic>? event}) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => AddCountdownSheet(existingEvent: event),
    );
  }

  Map<String, int> _calculateTimeRemaining(String? targetDateStr) {
    if (targetDateStr == null) return {'days': 0, 'hours': 0, 'mins': 0};
    final target = DateTime.tryParse(targetDateStr);
    if (target == null) return {'days': 0, 'hours': 0, 'mins': 0};

    final now = DateTime.now();
    final difference = target.difference(now);
    if (difference.isNegative) return {'days': 0, 'hours': 0, 'mins': 0};

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final mins = difference.inMinutes % 60;

    return {'days': days, 'hours': hours, 'mins': mins};
  }

  String _formatDate(String? isoString, String locale) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    return DuoFormatters.formatDate(dt, locale);
  }

  String _getCategoryIcon(String? category) {
    switch (category) {
      case 'food':
        return '🍝';
      case 'adventure':
        return '⛺';
      case 'home':
        return '🏡';
      case 'romance':
        return '💖';
      case 'travel':
      default:
        return '✈️';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);
    final togetherState = ref.watch(togetherProvider);
    final pairingState = ref.watch(pairingProvider);

    final partnerName = pairingState.partner?['display_name'] as String? ?? 'Partner';
    final heroEvent = togetherState.heroCountdown;
    final timeMap = _calculateTimeRemaining(heroEvent?['target_date'] as String?);

    final filteredBucketItems = _selectedCategory == 'all'
        ? togetherState.bucketItems
        : togetherState.bucketItems.where((b) => b['category'] == _selectedCategory).toList();

    final otherCountdowns = togetherState.countdowns.where((c) => c['id'] != heroEvent?['id']).toList();

    return Scaffold(
      appBar: DuoAppBar(
        title: DuoStrings.get('together_title', locale),
        subtitle: '${DuoStrings.get('together_sub', locale)} $partnerName 🌍',
        actions: [
          IconButton(
            tooltip: DuoStrings.get('add_countdown', locale),
            icon: const Icon(Icons.alarm_add_rounded, size: 26),
            onPressed: () => _openCountdownSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DuoColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(DuoStrings.get('add_dream', locale)),
        onPressed: () => _openAddBucketItem(context),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final duoId = pairingState.space?['id'] as String?;
          if (duoId != null) {
            await ref.read(togetherProvider.notifier).loadAll(duoId);
          }
        },
        child: ListView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
          children: [
            // 1. Anniversary Countdown Hero Banner
            if (heroEvent != null) ...[
              BouncyPress(
                semanticsLabel: '${heroEvent['title'] ?? 'Our Special Milestone'}: Tap to edit date',
                onTap: () => _openCountdownSheet(context, event: heroEvent),
                child: Card(
                  color: isDark ? DuoColors.cardDark : DuoColors.surfaceWarm,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DuoStrings.get('next_special_date', locale),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: DuoColors.primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: DuoColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(heroEvent['icon'] ?? '💍', style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit_calendar_rounded, size: 14, color: DuoColors.primary),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          heroEvent['title'] ?? 'Our Special Milestone',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              _formatDate(heroEvent['target_date'] as String?, locale),
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '• Tap to change date',
                              style: TextStyle(fontSize: 11, color: DuoColors.primary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCountdownUnit(timeMap['days'] ?? 0, DuoStrings.get('days', locale), locale),
                            _buildCountdownSeparator(),
                            _buildCountdownUnit(timeMap['hours'] ?? 0, DuoStrings.get('hours', locale), locale),
                            _buildCountdownSeparator(),
                            _buildCountdownUnit(timeMap['mins'] ?? 0, DuoStrings.get('mins', locale), locale),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text('💍', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 12),
                      const Text(
                        'No Upcoming Countdowns Yet',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Count down to your next anniversary, romantic vacation, or special date night.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: DuoColors.primary),
                        icon: const Icon(Icons.add_alarm_rounded, size: 18),
                        label: Text(DuoStrings.get('add_countdown', locale)),
                        onPressed: () => _openCountdownSheet(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Other Countdowns List (if multiple)
            if (otherCountdowns.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'MORE UPCOMING MILESTONES',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ...otherCountdowns.map((cd) {
                final targetStr = cd['target_date'] as String?;
                final target = targetStr != null ? DateTime.tryParse(targetStr) : null;
                final days = target != null ? target.difference(DateTime.now()).inDays : 0;
                final icon = cd['icon'] as String? ?? '⏳';
                final title = cd['title'] as String? ?? 'Milestone';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => _openCountdownSheet(context, event: cd),
                    leading: Text(icon, style: const TextStyle(fontSize: 22)),
                    title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: Text(_formatDate(targetStr, locale), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? DuoColors.accent.withValues(alpha: 0.22) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${DuoFormatters.formatNumber(days, locale)}d left',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: DuoColors.getAccessibleTextColor(DuoColors.accent, isDark: isDark),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit_rounded, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 20),

            // 2. Shared Bucket List Header & Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DuoStrings.get('shared_bucket_list', locale),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: isDark ? DuoColors.textMutedDark : DuoColors.textMutedLight,
                  ),
                ),
                Text(
                  '${DuoFormatters.formatNumber(togetherState.completedBucketCount, locale)} / ${DuoFormatters.formatNumber(togetherState.bucketItems.length, locale)} Dreams ✨',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DuoColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress Bar
            DuoProgressBar(
              progress: togetherState.bucketProgress,
              height: 7,
            ),
            const SizedBox(height: 14),

            // Category Filter Chips
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('all', '${DuoStrings.get('filter_all', locale)} (${DuoFormatters.formatNumber(togetherState.bucketItems.length, locale)})'),
                  _buildFilterChip('travel', DuoStrings.get('filter_travel', locale)),
                  _buildFilterChip('romance', DuoStrings.get('filter_romance', locale)),
                  _buildFilterChip('food', DuoStrings.get('filter_food', locale)),
                  _buildFilterChip('adventure', DuoStrings.get('filter_adventure', locale)),
                  _buildFilterChip('home', DuoStrings.get('filter_home', locale)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Bucket List Items
            if (filteredBucketItems.isEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      Text(
                        _selectedCategory == 'all'
                            ? 'Your Bucket List is Empty'
                            : 'No $_selectedCategory dreams yet',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Dream together! Add places to visit, foods to try, and couple goals.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: DuoColors.primary),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(locale == 'bn' ? 'প্রথম স্বপ্নটি যোগ করুন' : 'Add First Dream'),
                        onPressed: () => _openAddBucketItem(context),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ...filteredBucketItems.map((item) {
                final id = item['id'] as String;
                final isDone = item['completed'] == true;
                final category = item['category'] as String?;
                final icon = _getCategoryIcon(category);
                final completedBy = (item['users'] as Map<String, dynamic>?)?['display_name'];

                return Dismissible(
                  key: Key(id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  ),
                  onDismissed: (_) {
                    ref.read(togetherProvider.notifier).deleteBucketItem(id);
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Checkbox(
                        value: isDone,
                        activeColor: DuoColors.mint,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        onChanged: (val) {
                          ref.read(togetherProvider.notifier).toggleBucketItem(id, val ?? false);
                        },
                      ),
                      title: Row(
                        children: [
                          Text(icon, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isDone ? FontWeight.normal : FontWeight.w600,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                                color: isDone ? Colors.grey : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: isDone && completedBy != null
                          ? Text(
                              'Completed by $completedBy ✨',
                              style: const TextStyle(fontSize: 11, color: DuoColors.mint, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String id, String label) {
    final isSelected = _selectedCategory == id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: BouncyPress(
        semanticsLabel: label,
        onTap: () => setState(() => _selectedCategory = id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? DuoColors.primary
                : (isDark ? Colors.black26 : DuoColors.borderLight.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownUnit(int number, String label, String locale) {
    return Column(
      children: [
        Text(
          DuoFormatters.formatNumber(number, locale),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: DuoColors.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownSeparator() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        ':',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }
}
