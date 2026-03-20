import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'features/profile/data/achievements.dart';
import 'features/social/friends/friend_service.dart';
import 'shared/services/app_info.dart';
import 'shared/services/progression_service.dart';
import 'shared/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize all services (loads from disk).
  await ProgressionService.initialize();
  await SettingsService.initialize();
  await AchievementService.initialize();
  await FriendService.initialize();
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
