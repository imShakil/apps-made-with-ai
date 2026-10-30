import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/duo_colors.dart';
import '../providers/subscription_provider.dart';

class PremiumPaywallScreen extends ConsumerStatefulWidget {
  const PremiumPaywallScreen({super.key});

  @override
  ConsumerState<PremiumPaywallScreen> createState() => _PremiumPaywallScreenState();
}

class _PremiumPaywallScreenState extends ConsumerState<PremiumPaywallScreen> {
  String _selectedPlan = 'annual'; // 'monthly', 'annual', 'lifetime'
  bool _unlockedCelebration = false;

  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'monthly',
      'title': 'Monthly',
      'price': '৳99',
      'period': '/ month',
      'subtext': 'Flexible, cancel anytime',
      'badge': null,
    },
    {
      'id': 'annual',
      'title': 'Annual',
      'price': '৳799',
      'period': '/ year',
      'subtext': '৳66 / month • Save 33%',
      'badge': 'MOST POPULAR 💖',
    },
    {
      'id': 'lifetime',
      'title': 'Forever Duo',
      'price': '৳1,799',
      'period': 'one-time',
      'subtext': 'Pay once, yours for life',
      'badge': 'BEST VALUE 👑',
    },
  ];

  final List<Map<String, dynamic>> _features = [
    {
      'icon': '💌',
      'title': 'Unlimited SecretNotes',
      'desc': 'All 4 luxury stationery themes with sealed envelope animations',
    },
    {
      'icon': '🎮',
      'title': 'Full TogetherPlay Access',
      'desc': 'Spicy & Deep Truth or Dare packs, Would You Rather unlimited',
    },
    {
      'icon': '📸',
      'title': 'Unlimited Check-ins & Media',
      'desc': 'Voice clips, high-res photos, and unrestricted memory archives',
    },
    {
      'icon': '⏳',
      'title': 'Infinite Countdowns & Bucket Lists',
      'desc': 'Track all your relationship milestones and shared dreams',
    },
    {
      'icon': '✨',
      'title': 'Couple Shared Entitlement',
      'desc': 'When you upgrade, your partner gets Duo Premium automatically',
    },
    {
      'icon': '🛡️',
      'title': 'Completely Private & Ad-Free',
      'desc': 'Zero trackers, end-to-end encrypted personal sanctuary',
    },
  ];

  Future<void> _handleUpgrade() async {
    final success = await ref.read(subscriptionProvider.notifier).activatePlan(_selectedPlan);
    if (!mounted) return;

    if (success) {
      setState(() => _unlockedCelebration = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.stars_rounded, color: Colors.amber),
              SizedBox(width: 8),
              Expanded(child: Text('Duo Premium activated for you and your partner! 🎉')),
            ],
          ),
          backgroundColor: const Color(0xFF1B3B2B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final err = ref.read(subscriptionProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err != null ? 'Error: $err' : 'Failed to activate plan. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF1E1325),
                    const Color(0xFF151520),
                    const Color(0xFF0D0D14),
                  ]
                : [
                    const Color(0xFFFFF0F5),
                    const Color(0xFFFFF8F0),
                    Colors.white,
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              // Header Badge & Sparkle
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DuoColors.primary, DuoColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: DuoColors.primary.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('👑', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 6),
                      Text(
                        'DUO PREMIUM',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

              const SizedBox(height: 18),

              // Title
              const Center(
                child: Text(
                  'One Subscription.\nUnlocked For Both of You.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.25,
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  'Pay once — your partner automatically receives\nfull Duo Premium access instantly in real-time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.4,
                  ),
                ),
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 24),

              // Current Status Banner if already Premium
              if (subState.isPremium || _unlockedCelebration) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text('🌟', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Premium Active & Shared!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subState.subscriberName != null
                                  ? 'Unlocked by ${subState.subscriberName} for both of you.'
                                  : 'Both partners enjoy all luxury features!',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(duration: 400.ms),
                const SizedBox(height: 20),
              ],

              // Pricing Cards
              ...List.generate(_plans.length, (index) {
                final plan = _plans[index];
                final isSelected = _selectedPlan == plan['id'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() => _selectedPlan = plan['id'] as String);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark
                            ? (isSelected
                                ? DuoColors.primary.withOpacity(0.2)
                                : DuoColors.cardDark)
                            : (isSelected ? const Color(0xFFFFF0F5) : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? DuoColors.primary : Colors.grey.withOpacity(0.2),
                          width: isSelected ? 2.2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: DuoColors.primary.withOpacity(0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (plan['badge'] != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: DuoColors.accent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                plan['badge'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                          Row(
                            children: [
                              Radio<String>(
                                value: plan['id'] as String,
                                groupValue: _selectedPlan,
                                activeColor: DuoColors.primary,
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedPlan = val);
                                },
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plan['title'] as String,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      plan['subtext'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    plan['price'] as String,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: DuoColors.primary,
                                    ),
                                  ),
                                  Text(
                                    plan['period'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: (300 + index * 80).ms);
              }),

              const SizedBox(height: 12),

              // CTA Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: subState.isLoading ? null : _handleUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DuoColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    shadowColor: DuoColors.primary.withOpacity(0.5),
                  ),
                  child: subState.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('💎', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              subState.isPremium ? 'Extend Duo Premium' : 'Unlock for Both of Us',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  'Restore Purchases • Terms of Service • Privacy Policy',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Feature Highlights Grid
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'EVERYTHING INCLUDED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.grey,
                  ),
                ),
              ),

              ..._features.map((feat) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: DuoColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(feat['icon'] as String, style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feat['title'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              feat['desc'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
