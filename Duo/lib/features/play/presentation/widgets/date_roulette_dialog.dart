import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/duo_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/duo_colors.dart';
import '../../../../core/widgets/bouncy_press.dart';
import '../../../together/presentation/providers/together_provider.dart';

class DateIdea {
  final String titleEn;
  final String titleBn;
  final String descEn;
  final String descBn;
  final String vibe; // cozy, romantic, foodie, adventure, budget
  final String vibeIcon;
  final String duration;

  const DateIdea({
    required this.titleEn,
    required this.titleBn,
    required this.descEn,
    required this.descBn,
    required this.vibe,
    required this.vibeIcon,
    required this.duration,
  });
}

const List<DateIdea> kDateIdeas = [
  DateIdea(
    titleEn: 'Candlelight Living Room Picnic',
    titleBn: 'মোমবাতির আলোয় ড্রয়িংরুম পিকনিক',
    descEn: 'Spread a cozy blanket on the floor, dim the lights, light candles, and share homemade finger foods with acoustic music.',
    descBn: 'মেঝেতে সুন্দর চাদর বিছিয়ে, ঘরের বাতি নিভিয়ে মোমবাতি জ্বালান এবং হালকা গানের সাথে প্রিয় খাবার উপভোগ করুন।',
    vibe: 'cozy',
    vibeIcon: '🕯️',
    duration: '2 hours',
  ),
  DateIdea(
    titleEn: 'Stargazing & Midnight Tea Talk',
    titleBn: 'তারা দেখা ও গভীর রাতের চায়ের আড্ডা',
    descEn: 'Go up to the terrace or balcony with warm cups of chai, wrap in a shared blanket, and talk about your deepest dreams.',
    descBn: 'এক কাপ গরম চা নিয়ে বারান্দা বা ছাদে গিয়ে আকাশের তারা দেখুন আর ভবিষ্যৎ স্বপ্নের গল্পে হারিয়ে যান।',
    vibe: 'romantic',
    vibeIcon: '✨',
    duration: '1.5 hours',
  ),
  DateIdea(
    titleEn: 'Mystery Chef Cook-Off',
    titleBn: 'রান্নার রোমাঞ্চকর ডুয়েট প্রতিযোগিতা',
    descEn: 'Pick 3 random ingredients from your kitchen and invent a delicious dessert or midnight snack together.',
    descBn: 'রান্নাঘরের ৩টি উপকরণ বেছে নিয়ে দুজন মিলে নতুন কোনো মিষ্টি বা নাস্তা তৈরির রোমাঞ্চকর পরীক্ষা করুন।',
    vibe: 'foodie',
    vibeIcon: '🍳',
    duration: '1 hour',
  ),
  DateIdea(
    titleEn: 'Secret Sunset View Hunt',
    titleBn: 'সূর্যাস্ত দেখার নতুন স্পট আবিষ্কার',
    descEn: 'Hop on a bike or rickshaw without a set destination and find the most serene spot to watch the sun go down.',
    descBn: 'কোনো নির্দিষ্ট গন্তব্য ছাড়া রিকশা বা গাড়িতে বের হয়ে পড়ি এবং সূর্যাস্ত দেখার সবচেয়ে সুন্দর জায়গা খুঁজে নিই।',
    vibe: 'adventure',
    vibeIcon: '🌇',
    duration: '2.5 hours',
  ),
  DateIdea(
    titleEn: 'Old Photos & Nostalgia Walk',
    titleBn: 'পুরোনো ছবি ও স্মৃতি রোমন্থন',
    descEn: 'Open up your first photo albums, revisit the places you first dated, and take a recreation photo.',
    descBn: 'দুজনের প্রথম দিকের ছবি ও স্মৃতিগুলো আবার দেখুন এবং প্রথম ডেটের জায়গায় গিয়ে একটি নতুন ছবি তুলুন।',
    vibe: 'romantic',
    vibeIcon: '📸',
    duration: '2 hours',
  ),
  DateIdea(
    titleEn: 'Street Food Crawl Under 10 Bucks',
    titleBn: 'রাস্তার মজার স্ট্রিট ফুড ভ্রমণ',
    descEn: 'Walk through an evening market and try 3 different local treats you have never ordered before.',
    descBn: 'সন্ধ্যায় ফুটপাতের নতুন কোনো স্টল বা ক্যাফেতে গিয়ে নতুন স্বাদের খাবার চেখে দেখুন।',
    vibe: 'foodie',
    vibeIcon: '🥟',
    duration: '1.5 hours',
  ),
  DateIdea(
    titleEn: 'Silent Bookstore & Coffee Date',
    titleBn: 'বইয়ের দোকান ও কফি আড্ডা',
    descEn: 'Visit a cozy bookstore, pick a book for each other to read, and discuss your favorite lines over coffee.',
    descBn: 'বইয়ের দোকানে ঘুরে পরস্পরের জন্য বই নির্বাচন করুন এবং কফি খেতে খেতে প্রিয় লাইনগুলো শেয়ার করুন।',
    vibe: 'cozy',
    vibeIcon: '☕',
    duration: '2 hours',
  ),
  DateIdea(
    titleEn: 'Midnight Rainy Drive & Ice Cream',
    titleBn: 'মধ্যরাতে বৃষ্টিতে লং ড্রাইভ ও আইসক্রিম',
    descEn: 'Put on a nostalgic playlist, roll down the windows just enough to smell the rain, and grab late-night ice cream.',
    descBn: 'বৃষ্টির রাতে সুন্দর গান বাজিয়ে শান্ত ড্রাইভ দিন আর শেষ করুন প্রিয় আইসক্রিম দিয়ে।',
    vibe: 'adventure',
    vibeIcon: '🚗',
    duration: '1.5 hours',
  ),
];

class DateRouletteDialog extends ConsumerStatefulWidget {
  const DateRouletteDialog({super.key});

  @override
  ConsumerState<DateRouletteDialog> createState() => _DateRouletteDialogState();
}

class _DateRouletteDialogState extends ConsumerState<DateRouletteDialog> {
  String _selectedVibe = 'all';
  int _currentIndex = 0;
  bool _isSpinning = false;
  bool _isSaved = false;
  final Random _random = Random();

  List<DateIdea> get _filteredList {
    if (_selectedVibe == 'all') return kDateIdeas;
    return kDateIdeas.where((d) => d.vibe == _selectedVibe).toList();
  }

  void _spin() async {
    if (_isSpinning) return;
    setState(() {
      _isSpinning = true;
      _isSaved = false;
    });

    final pool = _filteredList;
    if (pool.isEmpty) {
      setState(() => _isSpinning = false);
      return;
    }

    // Play rapid haptic ticks while spinning
    for (int i = 0; i < 12; i++) {
      await Future.delayed(Duration(milliseconds: 60 + i * 18));
      HapticFeedback.selectionClick();
      if (!mounted) return;
      setState(() {
        _currentIndex = _random.nextInt(pool.length);
      });
    }

    HapticFeedback.heavyImpact();
    if (mounted) {
      setState(() {
        _isSpinning = false;
      });
    }
  }

  void _saveToDreams(DateIdea idea, String locale) async {
    final title = locale == 'bn' ? idea.titleBn : idea.titleEn;
    await ref.read(togetherProvider.notifier).addBucketItem(
      title: title,
      category: 'date',
    );

    if (mounted) {
      setState(() {
        _isSaved = true;
      });
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  DuoStrings.get('saved_to_dreams_toast', locale),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0D9488),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);

    final pool = _filteredList;
    final currentIdea = pool.isNotEmpty ? pool[_currentIndex.clamp(0, pool.length - 1)] : kDateIdeas.first;

    final title = locale == 'bn' ? currentIdea.titleBn : currentIdea.titleEn;
    final desc = locale == 'bn' ? currentIdea.descBn : currentIdea.descEn;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? const Color(0xFF1E1C28) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DuoColors.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🎡', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DuoStrings.get('date_roulette_title', locale),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          locale == 'bn' ? 'স্বতঃস্ফূর্ত ডেট আইডিয়া' : 'Spontaneous date ideas',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Vibe Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildVibeChip('all', locale == 'bn' ? 'সব' : 'All', '🎲', isDark),
                  const SizedBox(width: 6),
                  _buildVibeChip('romantic', locale == 'bn' ? 'রোমান্টিক' : 'Romantic', '🍷', isDark),
                  const SizedBox(width: 6),
                  _buildVibeChip('cozy', locale == 'bn' ? 'আরামদায়ক' : 'Cozy', '☕', isDark),
                  const SizedBox(width: 6),
                  _buildVibeChip('foodie', locale == 'bn' ? 'ফুডি' : 'Foodie', '🍕', isDark),
                  const SizedBox(width: 6),
                  _buildVibeChip('adventure', locale == 'bn' ? 'অ্যাডভেঞ্চার' : 'Adventure', '🎒', isDark),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Date Idea Card
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2B2238), const Color(0xFF1F1A2C)]
                      : [const Color(0xFFFFF0F5), const Color(0xFFFFFAFB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: DuoColors.accent.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: DuoColors.accent.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: DuoColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${currentIdea.vibeIcon} ${currentIdea.vibe.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: DuoColors.accent,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            currentIdea.duration,
                            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Spin & Save Actions
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: BouncyPress(
                    semanticsLabel: DuoStrings.get('spin_date_btn', locale),
                    onTap: _spin,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [DuoColors.primary, DuoColors.accent],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: DuoColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSpinning ? '🎲' : '🎡',
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isSpinning
                                  ? (locale == 'bn' ? 'ঘুরছে...' : 'Spinning...')
                                  : DuoStrings.get('spin_date_btn', locale),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: BouncyPress(
                    semanticsLabel: DuoStrings.get('add_to_dreams_btn', locale),
                    onTap: _isSaved ? null : () => _saveToDreams(currentIdea, locale),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _isSaved
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isSaved ? const Color(0xFF10B981) : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _isSaved ? 'Saved! ✨' : DuoStrings.get('add_to_dreams_btn', locale),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isSaved ? const Color(0xFF10B981) : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVibeChip(String vibeKey, String label, String icon, bool isDark) {
    final isSelected = _selectedVibe == vibeKey;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _selectedVibe = vibeKey;
          _currentIndex = 0;
          _isSaved = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? DuoColors.accent
              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$icon $label',
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[700]),
          ),
        ),
      ),
    );
  }
}
