import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/duo_colors.dart';
import '../providers/notes_provider.dart';

class AddPhotoMomentSheet extends ConsumerStatefulWidget {
  final String partnerName;

  const AddPhotoMomentSheet({super.key, required this.partnerName});

  @override
  ConsumerState<AddPhotoMomentSheet> createState() => _AddPhotoMomentSheetState();
}

class _AddPhotoMomentSheetState extends ConsumerState<AddPhotoMomentSheet> {
  final _titleController = TextEditingController();
  final _captionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedPreset = 'sunset';
  bool _isSaving = false;

  final List<Map<String, String>> _presets = [
    {
      'id': 'sunset',
      'label': 'Sunset Glow',
      'emoji': '🌅',
      'url': 'https://images.unsplash.com/photo-1518173946687-a4c8a383392e?w=800&auto=format&fit=crop&q=80',
    },
    {
      'id': 'coffee',
      'label': 'Cozy Date',
      'emoji': '☕',
      'url': 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?w=800&auto=format&fit=crop&q=80',
    },
    {
      'id': 'beach',
      'label': 'Seaside Walk',
      'emoji': '🏖️',
      'url': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&auto=format&fit=crop&q=80',
    },
    {
      'id': 'dinner',
      'label': 'Candle Dinner',
      'emoji': '🍷',
      'url': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&auto=format&fit=crop&q=80',
    },
    {
      'id': 'flowers',
      'label': 'Spring Bloom',
      'emoji': '🌸',
      'url': 'https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=800&auto=format&fit=crop&q=80',
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _saveMoment() async {
    final title = _titleController.text.trim();
    final caption = _captionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a moment title')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final selectedUrl = _presets.firstWhere(
      (p) => p['id'] == _selectedPreset,
      orElse: () => _presets.first,
    )['url']!;

    await ref.read(notesProvider.notifier).addPhotoMoment(
      title: title,
      caption: caption,
      photoUrl: selectedUrl,
      momentDate: _selectedDate,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo Moment captured in your shared timeline! 📸✨'),
          backgroundColor: Color(0xFF1B3B2B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
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
              children: const [
                Text('📸', style: TextStyle(fontSize: 22)),
                SizedBox(width: 8),
                Text(
                  'Capture Couple Moment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Add a romantic date, anniversary, or surprise to your shared journal.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 18),

            // Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Moment Title',
                hintText: 'e.g. Our First Beach Sunset, Coffee Date...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),

            // Date Picker Row
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : DuoColors.bgLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: DuoColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      'Date: ${DateFormat('d MMMM yyyy').format(_selectedDate)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Photo Preset Choice
            const Text(
              'CHOOSE AESTHETIC MOMENT PHOTO',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _presets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final p = _presets[index];
                  final isSelected = _selectedPreset == p['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPreset = p['id']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? DuoColors.primary.withValues(alpha: 0.15)
                            : (isDark ? DuoColors.cardDark : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? DuoColors.primary : Colors.grey.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(p['emoji']!, style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 4),
                          Text(
                            p['label']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? DuoColors.primary : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Reflection / Caption
            TextField(
              controller: _captionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Reflection & Caption (Optional)',
                hintText: 'What made this day so magical for both of you?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DuoColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSaving ? null : _saveMoment,
                icon: const Icon(Icons.favorite_rounded, size: 20),
                label: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save to Shared Memories ✨'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}
}
