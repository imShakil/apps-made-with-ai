import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/duo_colors.dart';
import '../providers/together_provider.dart';

class AddCountdownSheet extends ConsumerStatefulWidget {
  const AddCountdownSheet({super.key});

  @override
  ConsumerState<AddCountdownSheet> createState() => _AddCountdownSheetState();
}

class _AddCountdownSheetState extends ConsumerState<AddCountdownSheet> {
  final _titleController = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));
  String _selectedIcon = '💍';
  bool _isSaving = false;

  final List<String> _icons = const ['💍', '✈️', '🎂', '🌴', '🏡', '💖', '🎟️', '🚗', '🏖️', '🎆'];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);
    final success = await ref.read(togetherProvider.notifier).addCountdownEvent(
      title: title,
      targetDate: _targetDate,
      icon: _selectedIcon,
      isPinned: true,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏳ Countdown set! Watch the days tick closer together.'),
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
                  Text('⏳', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 8),
                  Text(
                    'Set Special Date',
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
              hintText: 'e.g. 1-Year Anniversary or Paris Vacation',
              filled: true,
              fillColor: isDark ? Colors.black26 : DuoColors.bgLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Date Picker Button
          const Text(
            'TARGET DATE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : DuoColors.bgLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 20, color: DuoColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        '${_targetDate.day}/${_targetDate.month}/${_targetDate.year}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Text('Change Date', style: TextStyle(fontSize: 12, color: DuoColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Icon Picker
          const Text(
            'PICK AN ICON',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _icons.map((icon) {
                final isSelected = _selectedIcon == icon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? DuoColors.primary.withValues(alpha: 0.2) : (isDark ? Colors.black26 : DuoColors.bgLight),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? DuoColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(icon, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: DuoColors.primary),
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Set Countdown ⏳'),
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
