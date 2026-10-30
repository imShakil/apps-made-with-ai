import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/duo_colors.dart';
import '../models/stationery_theme.dart';
import '../providers/notes_provider.dart';

class NoteComposerSheet extends ConsumerStatefulWidget {
  final String partnerName;

  const NoteComposerSheet({
    super.key,
    required this.partnerName,
  });

  @override
  ConsumerState<NoteComposerSheet> createState() => _NoteComposerSheetState();
}

class _NoteComposerSheetState extends ConsumerState<NoteComposerSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  StationeryTheme _selectedTheme = StationeryTheme.all.first;
  bool _isSending = false;

  bool _hasVoiceWhisper = false;
  bool _isRecordingWhisper = false;
  int _whisperSeconds = 0;
  Timer? _whisperTimer;

  @override
  void dispose() {
    _whisperTimer?.cancel();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _startWhisperRecording() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRecordingWhisper = true;
      _whisperSeconds = 0;
      _hasVoiceWhisper = false;
    });

    _whisperTimer?.cancel();
    _whisperTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_whisperSeconds >= 15) {
        _stopWhisperRecording();
      } else {
        setState(() => _whisperSeconds++);
        HapticFeedback.selectionClick();
      }
    });
  }

  void _stopWhisperRecording() {
    _whisperTimer?.cancel();
    HapticFeedback.heavyImpact();
    if (mounted) {
      setState(() {
        _isRecordingWhisper = false;
        _hasVoiceWhisper = true;
      });
    }
  }

  void _removeWhisper() {
    _whisperTimer?.cancel();
    setState(() {
      _hasVoiceWhisper = false;
      _isRecordingWhisper = false;
      _whisperSeconds = 0;
    });
  }

  Future<void> _send() async {
    var body = _bodyController.text.trim();
    if (body.isEmpty && !_hasVoiceWhisper) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write your note or attach a voice whisper before sending.')),
      );
      return;
    }

    if (body.isEmpty) {
      body = 'A special voice whisper for you 🎙️';
    }

    if (_hasVoiceWhisper) {
      body = '$body\n\n[VOICE_WHISPER]:15s';
    }

    setState(() => _isSending = true);
    final success = await ref.read(notesProvider.notifier).sendNote(
      title: _titleController.text.trim(),
      body: body,
      stationeryTheme: _selectedTheme.id,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💌 Letter sealed and sent to ${widget.partnerName}!'),
            backgroundColor: DuoColors.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send letter. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('💌', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      'Letter for ${widget.partnerName}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Stationery Theme Selector
            const Text(
              'CHOOSE STATIONERY',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: StationeryTheme.all.map((t) {
                final isSelected = _selectedTheme.id == t.id;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTheme = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: t.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? DuoColors.primary : t.cardBorderColor,
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(t.emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(
                            t.name.split(' ').first,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: t.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Interactive Stationery Paper Canvas
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _selectedTheme.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _selectedTheme.cardBorderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _selectedTheme.textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title (optional, e.g. Just Because...)',
                      hintStyle: TextStyle(
                        color: _selectedTheme.textColor.withValues(alpha: 0.5),
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Divider(color: _selectedTheme.cardBorderColor, height: 20),
                  TextField(
                    controller: _bodyController,
                    maxLines: 7,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: _selectedTheme.textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Dear ${widget.partnerName}...\n\nWrite something that will make them smile.',
                      hintStyle: TextStyle(
                        color: _selectedTheme.textColor.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 15s Voice Whisper Recorder Widget
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _hasVoiceWhisper
                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                    : (_isRecordingWhisper
                        ? const Color(0xFFE11D48).withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hasVoiceWhisper
                      ? const Color(0xFF10B981).withValues(alpha: 0.3)
                      : (_isRecordingWhisper
                          ? const Color(0xFFE11D48).withValues(alpha: 0.4)
                          : Colors.grey.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  if (_isRecordingWhisper) ...[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE11D48),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Recording... 00:${_whisperSeconds.toString().padLeft(2, '0')} / 00:15',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE11D48)),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: _stopWhisperRecording,
                      child: const Text('Finish', style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ] else if (_hasVoiceWhisper) ...[
                    const Text('🎙️', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        '15s Voice Whisper attached! 🎙️✨',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF047857)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                      onPressed: _removeWhisper,
                    ),
                  ] else ...[
                    const Text('🎙️', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Add 15s Voice Whisper',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: DuoColors.primary),
                      icon: const Icon(Icons.mic_rounded, size: 18),
                      label: const Text('Record'),
                      onPressed: _startWhisperRecording,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DuoColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSending ? null : _send,
                icon: const Icon(Icons.favorite_rounded, size: 20),
                label: _isSending
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Seal with Love & Send 💌'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
