import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/duo_theme.dart';
import 'core/theme/theme_provider.dart';

class DuoApp extends ConsumerWidget {
  const DuoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'duo.',
      debugShowCheckedModeBanner: false,
      theme: DuoTheme.lightTheme,
      darkTheme: DuoTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 480) {
              const mobileWidth = 440.0;
              final media = MediaQuery.of(context);
              return ColoredBox(
                color: isDark ? const Color(0xFF0F0E17) : const Color(0xFFEDE5E5),
                child: Center(
                  child: SizedBox(
                    width: mobileWidth,
                    height: constraints.maxHeight,
                    child: MediaQuery(
                      data: media.copyWith(
                        size: Size(mobileWidth, media.size.height),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF16151F) : const Color(0xFFFBF9F9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.14),
                              blurRadius: 40,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.symmetric(
                            vertical: BorderSide(
                              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                              width: 1,
                            ),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: child,
                      ),
                    ),
                  ),
                ),
              );
            }
            return child;
          },
        );
      },
    );
  }
}

