import 'package:firebase_database/firebase_database.dart';
import 'firebase_auth_service.dart';

class CloudSaveService {
  static final _db = FirebaseDatabase.instance.ref();

  static Future<void> saveGameProgress({
    required int highScore,
    required int jellifyLevel,
    required List<String> unlockedCharacters,
    required int totalWallsPassed,
  }) async {
    try {
      final userId = FirebaseAuthService.getCurrentUserId();
      if (userId == null) {
        print('User not authenticated');
        return;
      }

      await _db.child('users/$userId/gameProgress').set({
        'highScore': highScore,
        'jellifyLevel': jellifyLevel,
        'unlockedCharacters': unlockedCharacters,
        'totalWallsPassed': totalWallsPassed,
        'lastPlayTime': DateTime.now().toIso8601String(),
      });

      print('Game progress saved');
    } catch (e) {
      print('Cloud save error: $e');
    }
  }

  static Future<Map<String, dynamic>?> loadGameProgress() async {
    try {
      final userId = FirebaseAuthService.getCurrentUserId();
      if (userId == null) {
        print('User not authenticated');
        return null;
      }

      final snapshot = await _db.child('users/$userId/gameProgress').get();
      if (snapshot.exists) {
        final value = snapshot.value as Map?;
        if (value == null) return null;

        return Map<String, dynamic>.from(value);
      }
      return null;
    } catch (e) {
      print('Cloud load error: $e');
      return null;
    }
  }

  static Future<void> deleteGameProgress() async {
    try {
      final userId = FirebaseAuthService.getCurrentUserId();
      if (userId == null) return;

      await _db.child('users/$userId/gameProgress').remove();
      print('Game progress deleted');
    } catch (e) {
      print('Cloud delete error: $e');
    }
  }
}
