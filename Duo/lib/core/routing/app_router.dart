import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/widgets/duo_bottom_nav.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/play/presentation/screens/play_screen.dart';
import '../../features/memories/presentation/screens/memories_screen.dart';
import '../../features/together/presentation/screens/together_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/pairing/presentation/screens/pairing_screen.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/pairing/presentation/providers/pairing_provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _playNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _memoriesNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _togetherNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _profileNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/auth',
    redirect: (context, state) {
      User? user;
      try {
        user = Supabase.instance.client.auth.currentUser;
      } catch (_) {
        user = null;
      }

      final isAuthRoute = state.matchedLocation == '/auth';
      final isPairingRoute = state.matchedLocation == '/pairing';

      // 1. If not authenticated, always send to /auth
      if (user == null) {
        return isAuthRoute ? null : '/auth';
      }

      // If authenticated and trying to visit /auth, redirect forward
      if (isAuthRoute) {
        final pairingState = ref.read(pairingProvider);
        if (pairingState.isPaired) {
          return '/home';
        } else {
          return '/pairing';
        }
      }

      // 2. Check pairing state if navigating inside the app
      final pairingState = ref.read(pairingProvider);
      if (!pairingState.isPaired && !isPairingRoute) {
        return '/pairing';
      }

      return null;
    },
    routes: [
      // Auth Route
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),

      // Onboarding & Pairing Routes
      GoRoute(
        path: '/pairing',
        builder: (context, state) => const PairingScreen(),
      ),

      // Stateful Nested Shell for Bottom Navigation Tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            extendBody: true,
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.015),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(navigationShell.currentIndex),
                child: navigationShell,
              ),
            ),
            bottomNavigationBar: DuoBottomNav(navigationShell: navigationShell),
          );
        },
        branches: [
          // Tab 1: Home (DuoDay)
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Tab 2: Play (TwoTruths & Mini-Games)
          StatefulShellBranch(
            navigatorKey: _playNavigatorKey,
            routes: [
              GoRoute(
                path: '/play',
                builder: (context, state) => const PlayScreen(),
              ),
            ],
          ),

          // Tab 3: Memories (SecretNote & Letters)
          StatefulShellBranch(
            navigatorKey: _memoriesNavigatorKey,
            routes: [
              GoRoute(
                path: '/memories',
                builder: (context, state) => const MemoriesScreen(),
              ),
            ],
          ),

          // Tab 4: Together (OurLittleWorld: Countdowns & Bucket List)
          StatefulShellBranch(
            navigatorKey: _togetherNavigatorKey,
            routes: [
              GoRoute(
                path: '/together',
                builder: (context, state) => const TogetherScreen(),
              ),
            ],
          ),

          // Tab 5: Profile (Settings & Duo Premium)
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
