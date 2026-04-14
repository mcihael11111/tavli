import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/ai/difficulty/difficulty_level.dart';
import '../features/game/data/models/game_result.dart';
import '../features/game/presentation/splash_screen.dart';
import '../features/game/presentation/onboarding_screen.dart';
import '../features/game/presentation/home_screen.dart';
import '../features/game/presentation/difficulty_screen.dart';
import '../features/game/presentation/game_screen.dart';
import '../features/game/presentation/victory_screen.dart';
import '../features/game/presentation/pass_play_screen.dart';
import '../features/game/domain/engine/variants/game_variant.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/match_history_screen.dart';
import '../features/profile/presentation/achievements_screen.dart';
import '../features/customization/presentation/customization_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/learn/presentation/screens/learn_hub_screen.dart';
import '../features/learn/presentation/screens/lesson_detail_screen.dart';
import '../features/learn/presentation/screens/mechanic_comparison_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/multiplayer/presentation/online_lobby_screen.dart';
import '../features/multiplayer/presentation/online_game_screen.dart';
import '../features/multiplayer/presentation/matchmaking_screen.dart';
import '../features/multiplayer/presentation/invite_screen.dart';
import '../features/multiplayer/presentation/join_screen.dart';
import '../features/marathon/presentation/marathon_scoreboard_screen.dart';
import '../features/replay/data/game_recording.dart';
import '../features/replay/presentation/replay_screen.dart';
import '../features/spectate/presentation/spectate_screen.dart';
import '../features/shop/presentation/shop_screen.dart';
import '../features/challenges/presentation/challenges_screen.dart';
import '../features/dualboard/presentation/dual_board_screen.dart';
import 'shell_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondary, child) => child,
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 500),
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      // Shell with bottom nav.
      ShellRoute(
        builder: (context, state, child) =>
            ShellScreen(state: state, child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/customize',
            name: 'customize',
            builder: (context, state) => const CustomizationScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // Full-screen routes.
      GoRoute(
        path: '/difficulty',
        name: 'difficulty',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          final variantName = args?['variant'] as String? ?? 'portes';
          final variant = GameVariant.values.byName(variantName);
          return DifficultyScreen(variant: variant);
        },
      ),
      GoRoute(
        path: '/game',
        name: 'game',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          final difficulty =
              args['difficulty'] as DifficultyLevel? ?? DifficultyLevel.easy;
          final variant =
              args['variant'] as GameVariant? ?? GameVariant.portes;
          return GameScreen(difficulty: difficulty, variant: variant);
        },
      ),
      GoRoute(
        path: '/victory',
        name: 'victory',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return VictoryScreen(
            result: args['result'] as GameResult? ??
                const GameResult(winner: 1, type: GameResultType.single),
            difficulty: args['difficulty'] as DifficultyLevel? ??
                DifficultyLevel.easy,
            isOnline: args['isOnline'] as bool? ?? false,
            opponentName: args['opponentName'] as String?,
            ratingDelta: args['ratingDelta'] as int?,
          );
        },
      ),
      GoRoute(
        path: '/pass-play',
        name: 'pass-play',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          final variantName = args?['variant'] as String? ?? 'portes';
          final variant = GameVariant.values.byName(variantName);
          return PassPlayScreen(variant: variant);
        },
      ),
      // Learn to Play module.
      GoRoute(
        path: '/learn',
        name: 'learn',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return LearnHubScreen(
            initialSection: args?['section'] as String?,
            initialLesson: args?['lesson'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/learn/lesson',
        name: 'learn-lesson',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return LessonDetailScreen(
            sectionId: args['sectionId'] as String? ?? 'foundation',
            lessonIndex: args['lessonIndex'] as int? ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/learn/compare',
        name: 'learn-compare',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return MechanicComparisonScreen(
            family: args['family'] as String? ?? 'hitting',
          );
        },
      ),

      GoRoute(
        path: '/match-history',
        name: 'match-history',
        builder: (context, state) => const MatchHistoryScreen(),
      ),
      GoRoute(
        path: '/achievements',
        name: 'achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),

      // Online multiplayer routes.
      GoRoute(
        path: '/sign-in',
        name: 'sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/online-lobby',
        name: 'online-lobby',
        builder: (context, state) => const OnlineLobbyScreen(),
      ),
      GoRoute(
        path: '/online-game',
        name: 'online-game',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return OnlineGameScreen(
            gameRoomId: args['gameRoomId'] as String? ?? '',
            localPlayerNumber: args['localPlayerNumber'] as int? ?? 1,
            localPlayerUid: args['localPlayerUid'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/matchmaking',
        name: 'matchmaking',
        builder: (context, state) => const MatchmakingScreen(),
      ),
      GoRoute(
        path: '/invite/create',
        name: 'invite-create',
        builder: (context, state) => const InviteScreen(),
      ),
      GoRoute(
        path: '/join',
        name: 'join',
        builder: (context, state) => const JoinScreen(),
      ),

      // V1.5 features.
      GoRoute(
        path: '/replay',
        name: 'replay',
        builder: (context, state) {
          final recording = state.extra as GameRecording?;
          if (recording == null) {
            return const Scaffold(body: Center(child: Text('No recording')));
          }
          return ReplayScreen(recording: recording);
        },
      ),
      GoRoute(
        path: '/spectate',
        name: 'spectate',
        builder: (context, state) => const SpectateListScreen(),
      ),
      GoRoute(
        path: '/shop',
        name: 'shop',
        builder: (context, state) => const ShopScreen(),
      ),
      GoRoute(
        path: '/challenges',
        name: 'challenges',
        builder: (context, state) => const ChallengesScreen(),
      ),

      // Marathon scoreboard (between games).
      GoRoute(
        path: '/marathon-scoreboard',
        name: 'marathon-scoreboard',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return MarathonScoreboardScreen(
            difficulty: args['difficulty'] as DifficultyLevel? ??
                DifficultyLevel.easy,
          );
        },
      ),

      // V2 dual-phone board.
      GoRoute(
        path: '/dual-board',
        name: 'dual-board',
        builder: (context, state) => const DualBoardPairingScreen(),
      ),
    ],
  );
});
