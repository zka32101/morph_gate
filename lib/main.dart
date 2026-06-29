import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'services/ad_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/ghost_service.dart';
import 'services/hive_service.dart';
import 'services/sound_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  FlutterError.onError = (details) => FlutterError.presentError(details);

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Sign in anonymously
    await FirebaseAuthService.signInAnonymously();
  } catch (e) {
    print('Firebase init error: $e');
  }

  await HiveService.init();
  await GhostService.init();
  await AdService.init();
  await SoundService.init();

  runApp(const MorphGateApp());
}
