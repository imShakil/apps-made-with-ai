import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/duo_colors.dart';

class TruthOrDareDialog extends StatefulWidget {
  final String partnerName;

  const TruthOrDareDialog({super.key, required this.partnerName});

  @override
  State<TruthOrDareDialog> createState() => _TruthOrDareDialogState();
}

class _TruthOrDareDialogState extends State<TruthOrDareDialog> {
  bool _isTruth = true;
  int _cardIndex = 0;
  bool _isFlipped = false;

  final List<Map<String, dynamic>> _truths = const [
    {
      'tag': 'ROMANTIC',
      'prompt': 'What was the exact moment you realized you were falling in love with me?',
    },
    {
      'tag': 'PLAYFUL',
      'prompt': 'If we were characters in a cartoon, who would we be and why?',
    },
    {
      'tag': 'DEEP',
      'prompt': 'What is one dream you haven’t shared with anyone else yet?',
    },
    {
      'tag': 'SPICY',
      'prompt': 'Where is the most adventurous place you’d ever want us to kiss?',
    },
    {
      'tag': 'MEMORY',
      'prompt': 'What is your favorite late-night memory with me so far?',
    },
    {
      'tag': 'EMOTIONAL',
      'prompt': 'What song or smell always brings back our sweetest memory?',
    },
    {
      'tag': 'PLAYFUL',
      'prompt': 'What is the most ridiculous outfit you’ve ever seen me wear?',
    },
    {
      'tag': 'INTIMATE',
      'prompt': 'What is one thing I do that gives you instant butterflies?',
    },
    {
      'tag': 'FUTURE',
      'prompt': 'Where do you picture us waking up on our 10-year anniversary?',
    },
    {
      'tag': 'ROMANTIC',
      'prompt': 'If you could write a headline for our love story, what would it be?',
    },
  ];

  final List<Map<String, dynamic>> _dares = const [
    {
      'tag': 'ROMANTIC',
      'prompt': 'Look into my eyes for 60 seconds without speaking or looking away.',
    },
    {
      'tag': 'PLAYFUL',
      'prompt': 'Give me a 30-second dramatic slow-dance right now with no music.',
    },
    {
      'tag': 'SPICY',
      'prompt': 'Whisper the sweetest compliment in my ear with your softest voice.',
    },
    {
      'tag': 'CUTE',
      'prompt': 'Take a silly couple selfie with me right now and set it as your wallpaper.',
    },
    {
      'tag': 'SWEET',
      'prompt': 'Give me a 2-minute gentle shoulder massage.',
    },
    {
      'tag': 'PLAYFUL',
      'prompt': 'Imitate the way I laugh until I laugh myself!',
    },
    {
      'tag': 'ROMANTIC',
      'prompt': 'Feed me a bite of something sweet with your eyes closed.',
    },
    {
      'tag': 'DARE',
      'prompt': 'Recite an improvised 4-line romantic love poem dedicated to me right now.',
    },
    {
      'tag': 'INTIMATE',
      'prompt': 'Plant 5 slow kisses on my face: forehead, nose, both cheeks, and lips.',
    },
    {
      'tag': 'PLAYFUL',
      'prompt': 'Let me do your hair in the funniest style possible for 5 minutes!',
    },
  ];

  void _nextCard() {
    setState(() {
      _cardIndex = (_cardIndex + 1) % (_isTruth ? _truths.length : _dares.length);
      _isFlipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentList = _isTruth ? _truths : _dares;
    final card = currentList[_cardIndex % currentList.length];

    return Dialog(
      backgroundColor: isDark ? DuoColors.cardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 8),
                    Text(
                      'Truth or Dare',
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
            const SizedBox(height: 16),

            // Mode Toggle (Truth vs Dare)
            Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : DuoColors.bgLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isTruth = true;
                        _cardIndex = 0;
                        _isFlipped = false;
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isTruth ? DuoColors.secondary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🔮 Truth',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _isTruth ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isTruth = false;
                        _cardIndex = 0;
                        _isFlipped = false;
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: !_isTruth ? DuoColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🔥 Dare',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: !_isTruth ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Flip Challenge Card
            GestureDetector(
              onTap: () => setState(() => _isFlipped = !_isFlipped),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 180),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isTruth
                        ? [const Color(0xFF9B8AFB).withValues(alpha: 0.15), const Color(0xFF6C5CE7).withValues(alpha: 0.08)]
                        : [const Color(0xFFFF6B81).withValues(alpha: 0.15), const Color(0xFFFF8E53).withValues(alpha: 0.08)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isTruth
                        ? DuoColors.secondary.withValues(alpha: 0.3)
                        : DuoColors.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isTruth ? DuoColors.secondary : DuoColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        card['tag'] as String,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '"${card['prompt']}"',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  .animate(key: ValueKey('$_isTruth-$_cardIndex'))
                  .scale(duration: 300.ms, curve: Curves.easeOutBack)
                  .fadeIn(),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTruth ? DuoColors.secondary : DuoColors.primary,
                ),
                onPressed: _nextCard,
                icon: const Icon(Icons.shuffle_rounded, size: 18),
                label: const Text('Draw Another Card 🔄'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
