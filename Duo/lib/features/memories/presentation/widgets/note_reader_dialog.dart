import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../models/stationery_theme.dart';
import '../providers/notes_provider.dart';
import 'voice_whisper_player.dart';

class NoteReaderDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> note;

  const NoteReaderDialog({
    super.key,
    required this.note,
  });

  @override
  ConsumerState<NoteReaderDialog> createState() => _NoteReaderDialogState();
}

class _NoteReaderDialogState extends ConsumerState<NoteReaderDialog> {
  @override
  void initState() {
    super.initState();
    // Auto mark note opened if current user is the recipient
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      final noteSenderId = widget.note['sender_id'] as String?;
      final noteId = widget.note['id'] as String?;
      final openedAt = widget.note['opened_at'];

      if (user != null && noteSenderId != user.id && openedAt == null && noteId != null) {
        ref.read(notesProvider.notifier).openNote(noteId);
      }
    });
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final themeId = widget.note['stationery_theme'] as String?;
    final theme = StationeryTheme.getById(themeId);

    final title = widget.note['title'] as String?;
    final rawBody = widget.note['body'] as String? ?? '';
    final hasVoiceWhisper = rawBody.contains('[VOICE_WHISPER]:');
    final body = rawBody.replaceAll(RegExp(r'\[VOICE_WHISPER\]:[^\s]+'), '').trim();
    final createdAt = widget.note['created_at'] as String?;
    final senderName = (widget.note['users'] as Map<String, dynamic>?)?['display_name'] as String? ?? 'Your Love';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.cardBorderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wax Seal & Close Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.accentColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(theme.emoji, style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'From $senderName',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          Text(
                            _formatDate(createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textColor.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: theme.textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(color: theme.cardBorderColor, height: 28),

              // Title (if present)
              if (title != null && title.isNotEmpty) ...[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (hasVoiceWhisper) ...[
                VoiceWhisperPlayer(
                  textColor: theme.textColor,
                  accentColor: theme.accentColor,
                ),
                const SizedBox(height: 12),
              ],

              // Letter Body
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: SingleChildScrollView(
                  child: Text(
                    body,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      letterSpacing: 0.3,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'With all my love 💗',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: theme.accentColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
            .animate()
            .scale(begin: const Offset(0.7, 0.7), duration: 350.ms, curve: Curves.easeOutBack)
            .fadeIn(duration: 250.ms),
      ),
    );
  }
}
