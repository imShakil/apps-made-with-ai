import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/duo_colors.dart';
import '../providers/daily_question_provider.dart';

class DailyQuestionAnswerSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> question;
  final String partnerName;

  const DailyQuestionAnswerSheet({
    super.key,
    required this.question,
    required this.partnerName,
  });

  @override
  ConsumerState<DailyQuestionAnswerSheet> createState() => _DailyQuestionAnswerSheetState();
}

class _DailyQuestionAnswerSheetState extends ConsumerState<DailyQuestionAnswerSheet> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    final success = await ref.read(dailyQuestionProvider.notifier).submitAnswer(text);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Answer locked! Once both answer, answers will reveal.'),
            backgroundColor: DuoColors.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not submit answer. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textEn = widget.question['text_en'] as String? ?? '';
    final textBn = widget.question['text_bn'] as String? ?? '';
    final category = widget.question['category'] as String? ?? 'Deep Talks';

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: DuoColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      category.toUpperCase().replaceAll('_', ' '),
                      style: const TextStyle(
                        fontSize: 11,
                        color: DuoColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '"$textEn"',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
              ),
              if (textBn.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  textBn,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? DuoColors.textMutedDark : DuoColors.textMutedLight,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: DuoColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 16, color: DuoColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Private: ${widget.partnerName} cannot see your answer until they answer too.',
                        style: const TextStyle(fontSize: 12, color: DuoColors.primary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLines: 3,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Speak from your heart...',
                  filled: true,
                  fillColor: isDark ? Colors.black26 : DuoColors.bgLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: DuoColors.secondary),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Lock In My Answer 🔒'),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
