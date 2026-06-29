import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseAnalyticsService {
  static final _analytics = FirebaseAnalytics.instance;

  static Future<void> logGameStart({
    required int jellifyLevel,
    required String difficulty,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'game_start',
        parameters: {
          'jellify_level': jellifyLevel,
          'difficulty': difficulty,
        },
      );
    } catch (e) {
      print('Analytics error: $e');
    }
  }

  static Future<void> logGameOver({
    required int score,
    required String rank,
    required int wallsPassed,
    required int jellifyLevel,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'game_over',
        parameters: {
          'score': score,
          'rank': rank,
          'walls_passed': wallsPassed,
          'jellify_level': jellifyLevel,
        },
      );
    } catch (e) {
      print('Analytics error: $e');
    }
  }

  static Future<void> logCharacterSelect(String characterId) async {
    try {
      await _analytics.logEvent(
        name: 'character_select',
        parameters: {'character_id': characterId},
      );
    } catch (e) {
      print('Analytics error: $e');
    }
  }

  static Future<void> logMissionComplete({
    required String missionType,
    required int reward,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'mission_complete',
        parameters: {
          'mission_type': missionType,
          'reward': reward,
        },
      );
    } catch (e) {
      print('Analytics error: $e');
    }
  }

  static Future<void> logZoneEvent(String zoneName) async {
    try {
      await _analytics.logEvent(
        name: 'zone_triggered',
        parameters: {'zone_name': zoneName},
      );
    } catch (e) {
      print('Analytics error: $e');
    }
  }
}
