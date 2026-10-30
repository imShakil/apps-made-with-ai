import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/duo_colors.dart';
import '../providers/daily_question_provider.dart';

class PartnerGuessDialog extends ConsumerStatefulWidget {
  final String partnerName;
  final String questionText;

  const PartnerGuessDialog({
    super.key,
    required this.partnerName,
    required this.questionText,
  });

  @override
  ConsumerState<PartnerGuessDialog> createState() => _PartnerGuessDialogState();
}

class _PartnerGuessDialogState extends ConsumerState<PartnerGuessDialog> {
  final _controller = TextEditingController();
  bool _isChecking = false;
  bool? _matched;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkGuess() async {
    final guess = _controller.text.trim();
    if (guess.isEmpty) return;

    setState(() => _isChecking = true);
    final result = await ref.read(dailyQuestionProvider.notifier).submitGuess(guess);

    if (mounted) {
      setState(() {
        _isChecking = false;
        _matched = result ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? DuoColors.cardDark : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_matched == null) ...[
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: DuoColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('🎯', style: TextStyle(fontSize: 30))),
              ),
              const SizedBox(height: 16),
              Text(
                'Guess ${widget.partnerName}’s Answer',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'How well do you know your person today?',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? DuoColors.textMutedDark : DuoColors.textMutedLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'What did ${widget.partnerName} say?',
                  filled: true,
                  fillColor: isDark ? Colors.black26 : DuoColors.bgLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: DuoColors.primary),
                      onPressed: _isChecking ? null : _checkGuess,
                      child: _isChecking
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Guess! ✨'),
                    ),
                  ),
                ],
              ),
            ] else if (_matched == true) ...[
              // Match Celebration
              const Text('🎉', style: TextStyle(fontSize: 54))
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 12),
              const Text(
                'Mind Reader! 💖',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: DuoColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'You guessed ${widget.partnerName}’s answer exactly! Your bond is electric today.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: isDark ? DuoColors.textMutedDark : DuoColors.textMutedLight),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Celebrate ✨'),
              ),
            ] else ...[
              // Near miss
              const Text('💭', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text(
                'Not quite, but close!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Now you can see what ${widget.partnerName} actually shared!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: isDark ? DuoColors.textMutedDark : DuoColors.textMutedLight),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('View Reveal 💗'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
