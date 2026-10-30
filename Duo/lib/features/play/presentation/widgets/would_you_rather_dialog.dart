import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/duo_colors.dart';

class WouldYouRatherDialog extends StatefulWidget {
  final String partnerName;

  const WouldYouRatherDialog({super.key, required this.partnerName});

  @override
  State<WouldYouRatherDialog> createState() => _WouldYouRatherDialogState();
}

class _WouldYouRatherDialogState extends State<WouldYouRatherDialog> {
  int _currentIndex = 0;
  int? _myChoice; // 0 for Option A, 1 for Option B
  bool _revealed = false;

  final List<Map<String, dynamic>> _dilemmas = const [
    {
      'category': 'ROMANTIC',
      'optionA': 'Have breakfast in bed every Sunday morning ☕',
      'optionB': 'Take late-night stargazing drives together 🌌',
    },
    {
      'category': 'LIFESTYLE',
      'optionA': 'Cook an elaborate romantic dinner together 🍝',
      'optionB': 'Order takeout in cozy pajamas and binge movies 🍕',
    },
    {
      'category': 'SUPERPOWER',
      'optionA': 'Read each other’s mind for one full day 🔮',
      'optionB': 'Teleport anywhere in the world together for a weekend ✈️',
    },
    {
      'category': 'DEEP TALKS',
      'optionA': 'Relive the exact day we first met 💫',
      'optionB': 'Fast forward 50 years to see our rocking chairs 👵👴',
    },
    {
      'category': 'PLAYFUL',
      'optionA': 'Never have to wash dishes together again 🍽️',
      'optionB': 'Never have to decide "What should we eat?" again 🍕',
    },
    {
      'category': 'TRAVEL & ADVENTURE',
      'optionA': 'Live in a secluded mountain cabin for 3 months 🌲',
      'optionB': 'Live in a beach villa in Bali with sunsets every evening 🏖️',
    },
    {
      'category': 'ROMANCE',
      'optionA': 'Receive an unexpected handwritten love letter every week 💌',
      'optionB': 'Receive surprise warm hugs from behind every single day 🫂',
    },
    {
      'category': 'SPICY & PLAYFUL',
      'optionA': 'Exchange outfits for one entire evening date 👗👔',
      'optionB': 'Communicate only through slow whispers for 2 hours 🤫',
    },
    {
      'category': 'DREAMS & FUTURE',
      'optionA': 'Build our own dream sanctuary house from scratch 🏡',
      'optionB': 'Backpack across 20 countries together with two backpacks 🎒',
    },
    {
      'category': 'SWEET MOMENTS',
      'optionA': 'Dance in the pouring rain with our favorite song playing 🌧️💃',
      'optionB': 'Cozy under blankets watching a crackling fireplace in winter 🪵☕',
    },
    {
      'category': 'FOOD & FLAVOR',
      'optionA': 'Have an endless supply of our favorite desserts forever 🍰',
      'optionB': 'Have a personal master chef cook our anniversary dinner anywhere 🍷',
    },
    {
      'category': 'MEMORIES',
      'optionA': 'Have a photo album automatically printed of our best 100 moments 📸',
      'optionB': 'Have a 10-minute VR recording of our most romantic day together 🎥',
    },
  ];

  void _choose(int option) {
    setState(() {
      _myChoice = option;
      _revealed = true;
    });
  }

  void _next() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _dilemmas.length;
      _myChoice = null;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dilemma = _dilemmas[_currentIndex];

    return Dialog(
      backgroundColor: isDark ? DuoColors.cardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
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
                    dilemma['category'],
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DuoColors.secondary),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Would You Rather... 💬',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Pick your preference and compare with ${widget.partnerName}!',
              style: TextStyle(fontSize: 12, color: isDark ? DuoColors.textMutedDark : DuoColors.textMutedLight),
            ),
            const SizedBox(height: 20),

            // Option A
            GestureDetector(
              onTap: () => _choose(0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _myChoice == 0
                      ? DuoColors.primary.withValues(alpha: 0.18)
                      : (isDark ? Colors.black26 : DuoColors.bgLight),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _myChoice == 0 ? DuoColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  dilemma['optionA'],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: _myChoice == 0 ? FontWeight.bold : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '— OR —',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),

            // Option B
            GestureDetector(
              onTap: () => _choose(1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _myChoice == 1
                      ? DuoColors.secondary.withValues(alpha: 0.18)
                      : (isDark ? Colors.black26 : DuoColors.bgLight),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _myChoice == 1 ? DuoColors.secondary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  dilemma['optionB'],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: _myChoice == 1 ? FontWeight.bold : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            if (_revealed) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: DuoColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Choice locked in! 🔒 Syncing with partner...',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD49B00)),
                ),
              ).animate().fadeIn(duration: 300.ms),
            ],

            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: DuoColors.secondary),
                onPressed: _next,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Next Dilemma 🎲'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
