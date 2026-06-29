import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  static final _auth = FirebaseAuth.instance;

  static Future<User?> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      return result.user;
    } catch (e) {
      print('Firebase Auth Error: $e');
      return null;
    }
  }

  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
  }
}
