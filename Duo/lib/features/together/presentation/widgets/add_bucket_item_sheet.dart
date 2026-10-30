import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/duo_colors.dart';
import '../providers/together_provider.dart';

class AddBucketItemSheet extends ConsumerStatefulWidget {
  const AddBucketItemSheet({super.key});

  @override
  ConsumerState<AddBucketItemSheet> createState() => _AddBucketItemSheetState();
}

class _AddBucketItemSheetState extends ConsumerState<AddBucketItemSheet> {
  final _titleController = TextEditingController();
  String _selectedCategory = 'travel';
  bool _isSaving = false;

  final List<Map<String, String>> _categories = const [
    {'id': 'travel', 'label': 'Travel', 'icon': '✈️'},
    {'id': 'food', 'label': 'Food & Dates', 'icon': '🍝'},
    {'id': 'adventure', 'label': 'Adventure', 'icon': '⛺'},
    {'id': 'home', 'label': 'Home & Life', 'icon': '🏡'},
    {'id': 'romance', 'label': 'Romance', 'icon': '💖'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);
    final success = await ref.read(togetherProvider.notifier).addBucketItem(
      title: title,
      category: _selectedCategory,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Dream added to your couple bucket list!'),
            backgroundColor: DuoColors.primary,
          ),
        );
      }
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
                  const Row(
                    children: [
                      Text('✨', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 8),
                      Text(
                        'Add Shared Dream',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              TextField(
                controller: _titleController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. Watch northern lights from a glass igloo',
                  filled: true,
                  fillColor: isDark ? Colors.black26 : DuoColors.bgLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'CHOOSE CATEGORY',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((c) {
                  final isSelected = _selectedCategory == c['id'];
                  return ChoiceChip(
                    label: Text('${c['icon']} ${c['label']}'),
                    selected: isSelected,
                    selectedColor: DuoColors.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? DuoColors.primary : null,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = c['id']!);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: DuoColors.primary),
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Add to Our Dreams ✨'),
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
