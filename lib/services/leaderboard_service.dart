import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_auth_service.dart';

class LeaderboardService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> submitScore({
    required int score,
    required String rank,
    required int jellifyLevel,
    required int wallsPassed,
  }) async {
    try {
      final userId = FirebaseAuthService.getCurrentUserId();
      if (userId == null) {
        print('User not authenticated');
        return;
      }

      await _db.collection('leaderboards').doc('global').collection('scores').add({
        'playerId': userId,
        'playerName': 'Player_${userId.substring(0, 8)}',
        'score': score,
        'rank': rank,
        'jellifyLevel': jellifyLevel,
        'wallsPassed': wallsPassed,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Score submitted: $score');
    } catch (e) {
      print('Leaderboard submit error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getTopScores({int limit = 10}) async {
    try {
      final snapshot = await _db
          .collection('leaderboards')
          .doc('global')
          .collection('scores')
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'docId': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Leaderboard fetch error: $e');
      return [];
    }
  }

  static Future<int?> getPlayerRank(int score) async {
    try {
      final snapshot = await _db
          .collection('leaderboards')
          .doc('global')
          .collection('scores')
          .where('score', isGreaterThan: score)
          .count()
          .get();

      return snapshot.count + 1;
    } catch (e) {
      print('Rank fetch error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getPlayerScore(String userId) async {
    try {
      final snapshot = await _db
          .collection('leaderboards')
          .doc('global')
          .collection('scores')
          .where('playerId', isEqualTo: userId)
          .orderBy('score', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return snapshot.docs.first.data();
    } catch (e) {
      print('Player score fetch error: $e');
      return null;
    }
  }
}
