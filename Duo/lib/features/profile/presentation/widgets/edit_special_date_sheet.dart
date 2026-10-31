import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/duo_colors.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/duo_strings.dart';
import '../../../../core/localization/duo_formatters.dart';
import '../providers/special_dates_provider.dart';

enum SpecialDateMode {
  anniversary,
  myBirthday,
  partnerBirthday,
}

class EditSpecialDateSheet extends ConsumerStatefulWidget {
  final SpecialDateMode mode;
  final String myName;
  final String partnerName;

  const EditSpecialDateSheet({
    super.key,
    required this.mode,
    required this.myName,
    required this.partnerName,
  });

  @override
  ConsumerState<EditSpecialDateSheet> createState() => _EditSpecialDateSheetState();
}

class _EditSpecialDateSheetState extends ConsumerState<EditSpecialDateSheet> {
  late DateTime _selectedDate;
  late String _selectedType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final dates = ref.read(specialDatesProvider);
    switch (widget.mode) {
      case SpecialDateMode.anniversary:
        _selectedDate = dates.anniversaryDate ?? DateTime.now().subtract(const Duration(days: 365));
        _selectedType = dates.anniversaryType;
        break;
      case SpecialDateMode.myBirthday:
        _selectedDate = dates.myBirthdate ?? DateTime(2000, 1, 1);
        _selectedType = 'birthday';
        break;
      case SpecialDateMode.partnerBirthday:
        _selectedDate = dates.partnerBirthdate ?? DateTime(2000, 1, 1);
        _selectedType = 'birthday';
        break;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1960),
      lastDate: now,
      helpText: widget.mode == SpecialDateMode.anniversary
          ? 'SELECT RELATIONSHIP START DATE'
          : 'SELECT BIRTHDATE',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    final notifier = ref.read(specialDatesProvider.notifier);
    bool success = false;

    switch (widget.mode) {
      case SpecialDateMode.anniversary:
        success = await notifier.setAnniversary(_selectedDate, type: _selectedType);
        break;
      case SpecialDateMode.myBirthday:
        success = await notifier.setMyBirthday(_selectedDate);
        break;
      case SpecialDateMode.partnerBirthday:
        success = await notifier.setPartnerBirthday(_selectedDate);
        break;
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        final locale = ref.read(localeProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(DuoStrings.get('special_date_updated', locale)),
            backgroundColor: DuoColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);

    String title;
    String icon;
    switch (widget.mode) {
      case SpecialDateMode.anniversary:
        title = DuoStrings.get('our_anniversary', locale);
        icon = '💍';
        break;
      case SpecialDateMode.myBirthday:
        title = DuoStrings.get('my_birthday', locale);
        icon = '🎂';
        break;
      case SpecialDateMode.partnerBirthday:
        title = DuoStrings.get('partner_birthday', locale, params: {'name': widget.partnerName});
        icon = '🎉';
        break;
    }

    // Calculations for preview
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysDiff = today.difference(_selectedDate).inDays;

    var nextAnniv = DateTime(now.year, _selectedDate.month, _selectedDate.day);
    if (nextAnniv.isBefore(today)) {
      nextAnniv = DateTime(now.year + 1, _selectedDate.month, _selectedDate.day);
    }
    final daysUntilNext = nextAnniv.difference(today).inDays;
    final nextYearCount = nextAnniv.year - _selectedDate.year;

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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 10),
                      Text(
                        title,
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
              const SizedBox(height: 18),

              // Anniversary Type Selector (if Anniversary Mode)
              if (widget.mode == SpecialDateMode.anniversary) ...[
                Text(
                  DuoStrings.get('anniversary_type', locale).toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeChip('dating', '💖 Started Dating', isDark),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTypeChip('wedding', '💍 Wedding', isDark),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTypeChip('engaged', '💎 Engaged', isDark),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],

              // Date Picker Card
              Text(
                (widget.mode == SpecialDateMode.anniversary ? 'ANNIVERSARY DATE' : 'BIRTHDATE').toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : DuoColors.bgLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: DuoColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 22, color: DuoColors.primary),
                          const SizedBox(width: 12),
                          Text(
                            DuoFormatters.formatDate(_selectedDate, locale),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: DuoColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          locale == 'bn' ? 'পরিবর্তন' : 'Change',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DuoColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Live Insight Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF261D22) : const Color(0xFFFFF1F4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DuoColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.mode == SpecialDateMode.anniversary) ...[
                            Text(
                              locale == 'bn'
                                  ? '${DuoFormatters.formatNumber(daysDiff, locale)} দিন একসাথে ভালোবাসা পূর্ণ পদচিহ্ন! 💕'
                                  : '${DuoFormatters.formatNumber(daysDiff, locale)} days together in love! 💕',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              locale == 'bn'
                                  ? 'পরবর্তী ${DuoFormatters.formatNumber(nextYearCount, locale)}ম বার্ষিকীর বাকি ${DuoFormatters.formatNumber(daysUntilNext, locale)} দিন'
                                  : '$daysUntilNext days until your ${nextYearCount}th Anniversary 💍',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ] else ...[
                            Text(
                              locale == 'bn'
                                  ? 'পরবর্তী জন্মদিনের বাকি ${DuoFormatters.formatNumber(daysUntilNext, locale)} দিন! 🎂'
                                  : 'Next birthday is in $daysUntilNext days! 🎂',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              locale == 'bn'
                                  ? '${DuoFormatters.formatNumber(nextYearCount, locale)} বছরে পদার্পণ হবে'
                                  : 'Will celebrate turning $nextYearCount years old 🎉',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save CTA Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DuoColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          locale == 'bn' ? 'সংরক্ষণ ও সিঙ্ক করুন ✨' : 'Save & Sync with Partner ✨',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, bool isDark) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? DuoColors.primary
              : (isDark ? Colors.white.withValues(alpha: 0.05) : DuoColors.bgLight),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? DuoColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]),
          ),
        ),
      ),
    );
  }
}
