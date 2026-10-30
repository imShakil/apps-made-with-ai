import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/duo_colors.dart';
import '../localization/locale_provider.dart';
import '../localization/duo_strings.dart';
import 'bouncy_press.dart';

class DuoBottomNav extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const DuoBottomNav({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);

    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 18, bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xE61E1C29)
                  : const Color(0xF2FFFFFF),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : DuoColors.primary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  context,
                  index: 0,
                  icon: Icons.favorite_rounded,
                  label: DuoStrings.get('nav_home', locale),
                  locale: locale,
                ),
                _buildNavItem(
                  context,
                  index: 1,
                  icon: Icons.sports_esports_rounded,
                  label: DuoStrings.get('nav_play', locale),
                  locale: locale,
                ),
                _buildNavItem(
                  context,
                  index: 2,
                  icon: Icons.auto_stories_rounded,
                  label: DuoStrings.get('nav_memories', locale),
                  locale: locale,
                ),
                _buildNavItem(
                  context,
                  index: 3,
                  icon: Icons.explore_rounded,
                  label: DuoStrings.get('nav_together', locale),
                  locale: locale,
                ),
                _buildNavItem(
                  context,
                  index: 4,
                  icon: Icons.settings_rounded,
                  label: DuoStrings.get('nav_profile', locale),
                  locale: locale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required String locale,
  }) {
    final isSelected = navigationShell.currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const activeColor = DuoColors.primary;
    final inactiveColor = isDark ? DuoColors.textMutedDark : DuoColors.textMutedLight;

    return Expanded(
      child: Semantics(
        label: label,
        selected: isSelected,
        button: true,
        child: BouncyPress(
          onTap: () => _onTap(index),
          scaleFactor: 0.92,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: isDark ? 0.22 : 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                  letterSpacing: -0.1,
                  fontFamily: locale == 'bn' ? 'Noto Sans Bengali' : null,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
