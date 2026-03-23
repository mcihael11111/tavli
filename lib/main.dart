import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'features/notifications/notification_service.dart';
import 'features/profile/data/achievements.dart';
import 'features/challenges/data/challenge_service.dart';
import 'features/shop/data/shop_items.dart';
import 'features/social/friends/friend_service.dart';
import 'shared/services/app_info.dart';
import 'shared/services/progression_service.dart';
import 'shared/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (gracefully handle missing config).
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize push notifications after Firebase is ready.
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Firebase init failed: $e — online features disabled.');
  }

  // Initialize all services (loads from disk).
  await ProgressionService.initialize();
  await SettingsService.initialize();
  await AchievementService.initialize();
  await FriendService.initialize();
  await ShopService.initialize();
  await ChallengeService.initialize();
  await AppInfo.initialize();

  // Lock orientation to portrait for menus; game screen manages its own.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for premium feel.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: TavliApp()));
}
