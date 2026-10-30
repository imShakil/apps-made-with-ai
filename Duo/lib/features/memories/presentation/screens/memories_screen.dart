import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/duo_colors.dart';
import '../../../../core/widgets/duo_app_bar.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../pairing/presentation/providers/pairing_provider.dart';
import '../models/stationery_theme.dart';
import '../providers/notes_provider.dart';
import '../widgets/note_composer_sheet.dart';
import '../widgets/note_reader_dialog.dart';
import '../widgets/add_photo_moment_sheet.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/duo_strings.dart';
import '../../../../core/localization/duo_formatters.dart';
import '../../../../core/widgets/bouncy_press.dart';

class MemoriesScreen extends ConsumerStatefulWidget {
  const MemoriesScreen({super.key});

  @override
  ConsumerState<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends ConsumerState<MemoriesScreen> with SingleTickerProviderStateMixin {
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

  void _openComposer(BuildContext context, String partnerName) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => NoteComposerSheet(partnerName: partnerName),
    );
  }

  void _openPhotoMomentSheet(BuildContext context, String partnerName) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => AddPhotoMomentSheet(partnerName: partnerName),
    );
  }

  void _openReader(BuildContext context, Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (context) => NoteReaderDialog(note: note),
    );
  }

  String _formatDate(String? isoString, String locale) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    return DuoFormatters.formatDate(dt, locale);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);
    final notesState = ref.watch(notesProvider);
    final pairingState = ref.watch(pairingProvider);
    final user = ref.watch(currentUserProvider);

    final partnerName = pairingState.partner?['display_name'] as String? ?? 'Partner';
    final myId = user?.id;

    final letters = notesState.notes.where((n) => n['stationery_theme'] != 'photo_moment').toList();
    final photoMoments = notesState.notes.where((n) => n['stationery_theme'] == 'photo_moment' || n['media_url'] != null).toList();

    return Scaffold(
      appBar: DuoAppBar(
        title: DuoStrings.get('memories_title', locale),
        subtitle: DuoStrings.get('memories_sub', locale),
        actions: [
          IconButton(
            tooltip: DuoStrings.get('write_letter', locale),
            icon: const Icon(Icons.edit_note_rounded, size: 28),
            onPressed: () => _openComposer(context, partnerName),
          ),
          IconButton(
            tooltip: DuoStrings.get('capture_moment', locale),
            icon: const Icon(Icons.add_a_photo_rounded, size: 24),
            onPressed: () => _openPhotoMomentSheet(context, partnerName),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DuoColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.favorite_rounded),
        label: Text(_tabController.index == 0 ? DuoStrings.get('write_letter', locale) : DuoStrings.get('capture_moment', locale)),
        onPressed: () {
          if (_tabController.index == 0) {
            _openComposer(context, partnerName);
          } else {
            _openPhotoMomentSheet(context, partnerName);
          }
        },
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
                onTap: (_) => setState(() {}),
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
                  Tab(text: '${DuoStrings.get('tab_letters', locale)} (${letters.length})'),
                  Tab(text: '${DuoStrings.get('tab_photos', locale)} (${photoMoments.length})'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLettersTab(context, letters, notesState.unopenedNote, partnerName, myId, isDark, locale),
                _buildPhotoMomentsTab(context, photoMoments, partnerName, isDark, locale),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLettersTab(
    BuildContext context,
    List<Map<String, dynamic>> letters,
    Map<String, dynamic>? unopenedNote,
    String partnerName,
    String? myId,
    bool isDark,
    String locale,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        final pairingState = ref.read(pairingProvider);
        final duoId = pairingState.space?['id'] as String?;
        if (duoId != null && myId != null) {
          await ref.read(notesProvider.notifier).loadNotes(duoId, myId);
        }
      },
      child: ListView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
        children: [
          // Unopened Secret Note Hero
          if (unopenedNote != null) ...[
            Card(
              color: isDark ? DuoColors.cardDark : DuoColors.surfaceWarm,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('💌', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DuoStrings.get('new_secret_note', locale),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: DuoColors.primary,
                                ),
                              ),
                              Text(
                                'From $partnerName · ${_formatDate(unopenedNote['created_at'], locale)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: DuoColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            DuoStrings.get('unopened', locale),
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      unopenedNote['title'] ?? '"A little secret surprise for you..."',
                      style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () => _openReader(context, unopenedNote),
                      child: Text(DuoStrings.get('tap_open_envelope', locale)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          Text(
            DuoStrings.get('saved_letters', locale),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          if (letters.isEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: DuoColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(child: Text('💌', style: TextStyle(fontSize: 32))),
                    ),
                    const SizedBox(height: 16),
                    Text(DuoStrings.get('no_letters', locale), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      'Leave a sweet surprise or romantic note for $partnerName to wake up to.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: isDark ? DuoColors.textMutedDark : DuoColors.textMutedLight),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: DuoColors.primary),
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      label: Text(locale == 'bn' ? 'আপনার প্রথম চিঠিটি লিখুন ✍️' : 'Write Your First Letter ✍️'),
                      onPressed: () => _openComposer(context, partnerName),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ...letters.map((note) {
              final isSentByMe = note['sender_id'] == myId;
              final themeId = note['stationery_theme'] as String?;
              final theme = StationeryTheme.getById(themeId);
              final title = (note['title'] as String?)?.isNotEmpty == true ? note['title'] : 'Love Letter';
              final body = note['body'] as String? ?? '';
              final isOpened = note['opened_at'] != null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BouncyPress(
                  semanticsLabel: '$title from ${isSentByMe ? "You" : partnerName}',
                  onTap: () => _openReader(context, note),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? DuoColors.cardDark : theme.background,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? DuoColors.borderDark : theme.cardBorderColor,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(theme.emoji, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? null : theme.textColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSentByMe
                                    ? DuoColors.secondary.withValues(alpha: 0.15)
                                    : (isOpened ? Colors.grey.withValues(alpha: 0.15) : DuoColors.primary.withValues(alpha: 0.15)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isSentByMe ? 'SENT' : (isOpened ? 'OPENED' : 'NEW'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSentByMe ? DuoColors.secondary : (isOpened ? Colors.grey : DuoColors.primary),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: isDark ? DuoColors.textMutedDark : theme.textColor.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${isSentByMe ? "You" : partnerName} · ${_formatDate(note['created_at'], locale)}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPhotoMomentsTab(
    BuildContext context,
    List<Map<String, dynamic>> photoMoments,
    String partnerName,
    bool isDark,
    String locale,
  ) {
    if (photoMoments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: DuoColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('📸', style: TextStyle(fontSize: 34))),
              ),
              const SizedBox(height: 18),
              Text(
                DuoStrings.get('no_photos', locale),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Collect snapshots of your dates, road trips, and milestones with $partnerName.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: DuoColors.primary),
                icon: const Icon(Icons.add_a_photo_rounded, size: 20),
                label: Text(locale == 'bn' ? 'প্রথম ছবিটি যুক্ত করুন 📷' : 'Capture First Moment 📷'),
                onPressed: () => _openPhotoMomentSheet(context, partnerName),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
      itemCount: photoMoments.length,
      itemBuilder: (context, index) {
        final moment = photoMoments[index];
        final title = moment['title'] as String? ?? 'Cherished Date';
        final body = moment['body'] as String? ?? '';
        final mediaUrl = moment['media_url'] as String? ?? '';
        final date = _formatDate(moment['created_at'], locale);

        return BouncyPress(
          semanticsLabel: '$title: $date',
          onTap: () => _openReader(context, moment),
          child: Card(
            margin: const EdgeInsets.only(bottom: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mediaUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: mediaUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: DuoColors.primary.withValues(alpha: 0.1),
                          child: const Center(child: Text('📸', style: TextStyle(fontSize: 40))),
                        ),
                      ),
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: DuoColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              date,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DuoColors.primary),
                            ),
                          ),
                        ],
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          body,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
