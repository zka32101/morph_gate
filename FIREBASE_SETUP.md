# Morph Gate - Firebase Integration Setup

## 1. Firebase Console Setup

### Step 1: Create Firebase Project
1. Go to **[firebase.google.com](https://firebase.google.com)**
2. Click **"Go to console"**
3. Click **"+ Add project"**
4. Project name: `morph-gate`
5. Continue → Accept terms → Create

### Step 2: Add Android App
1. In Firebase console, click **Android icon**
2. **Package name**: `com.morphgate.game`
3. **App nickname**: Morph Gate
4. **Debug signing certificate SHA-1**: 
   ```bash
   # Get from Android Studio:
   # File → Project Structure → SDK Location
   # Or run:
   # keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore -list -v
   ```
   (Use default debug cert for now)
5. Click **"Register app"**
6. Download `google-services.json`

### Step 3: Place google-services.json
```bash
# Move downloaded file to:
H:\マイドライブ\apps\morph_gate\android\app\
```

---

## 2. Flutter/Dart Setup

### Step 1: Add Firebase Packages
Edit `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.14.0
  firebase_analytics: ^10.7.0
  firebase_realtime_database: ^10.2.0
```

### Step 2: Run pub get
```bash
cd H:\マイドライブ\apps\morph_gate
flutter pub get
```

### Step 3: Initialize Firebase
Edit `lib/main.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

### Step 4: Generate firebase_options.dart
```bash
cd H:\マイドライブ\apps\morph_gate
flutterfire configure
# Select Android
# Select morph-gate Firebase project
# Confirm
```

---

## 3. Firebase Features Implementation

### A. Anonymous Authentication (Quick Setup)
1. Go to Firebase Console → **Authentication**
2. Click **"Sign-in method"**
3. Enable **"Anonymous"**
4. Save

**Code** (lib/services/auth_service.dart):
```dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  
  static Future<User?> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      return result.user;
    } catch (e) {
      print('Auth error: $e');
      return null;
    }
  }
}
```

### B. Cloud Firestore - Leaderboard
1. Go to Firebase Console → **Firestore Database**
2. Click **"Create database"**
3. Select **"Start in test mode"** (not production)
4. Location: **(default)**
5. Create

**Database Structure**:
```
/leaderboards
  /global
    /scores (collection)
      doc: {
        playerId: string,
        playerName: string,
        score: number,
        rank: string,
        timestamp: timestamp,
        jellifyLevel: number
      }
```

**Security Rules** (temporarily):
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Code** (lib/services/leaderboard_service.dart):
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  
  static Future<void> submitScore({
    required int score,
    required String rank,
    required int jellifyLevel,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    await _db.collection('leaderboards').doc('global')
        .collection('scores').add({
      'playerId': user.uid,
      'playerName': 'Player_${user.uid.substring(0, 8)}',
      'score': score,
      'rank': rank,
      'jellifyLevel': jellifyLevel,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
  
  static Future<List<Map>> getTopScores({int limit = 10}) async {
    final snapshot = await _db
        .collection('leaderboards').doc('global')
        .collection('scores')
        .orderBy('score', descending: true)
        .limit(limit)
        .get();
    
    return snapshot.docs
        .map((doc) => {...doc.data(), 'docId': doc.id})
        .toList();
  }
}
```

### C. Realtime Database - Cloud Save
1. Go to Firebase Console → **Realtime Database**
2. Click **"Create Database"**
3. Location: **(default)**
4. Choose **"Test mode"** initially

**Database Structure**:
```
/users
  /{userId}
    gameProgress: {
      highScore: number,
      jellifyLevel: number,
      unlockedCharacters: array,
      totalWallsPassed: number,
      lastPlayTime: timestamp
    }
```

**Code** (lib/services/cloud_save_service.dart):
```dart
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudSaveService {
  static final _db = FirebaseDatabase.instance.ref();
  static final _auth = FirebaseAuth.instance;
  
  static Future<void> saveGameProgress({
    required int highScore,
    required int jellifyLevel,
    required List<String> unlockedCharacters,
    required int totalWallsPassed,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    await _db.child('users/$userId/gameProgress').set({
      'highScore': highScore,
      'jellifyLevel': jellifyLevel,
      'unlockedCharacters': unlockedCharacters,
      'totalWallsPassed': totalWallsPassed,
      'lastPlayTime': DateTime.now().toIso8601String(),
    });
  }
  
  static Future<Map?> loadGameProgress() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    
    final snapshot = await _db.child('users/$userId/gameProgress').get();
    if (snapshot.exists) {
      return Map.from(snapshot.value as Map);
    }
    return null;
  }
}
```

### D. Firebase Analytics
**Code** (lib/services/analytics_service.dart):
```dart
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final _analytics = FirebaseAnalytics.instance;
  
  static Future<void> logGameStart({
    required int jellifyLevel,
    required String difficulty,
  }) async {
    await _analytics.logEvent(
      name: 'game_start',
      parameters: {
        'jellify_level': jellifyLevel,
        'difficulty': difficulty,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
  
  static Future<void> logGameOver({
    required int score,
    required String rank,
    required int wallsPassed,
  }) async {
    await _analytics.logEvent(
      name: 'game_over',
      parameters: {
        'score': score,
        'rank': rank,
        'walls_passed': wallsPassed,
      },
    );
  }
  
  static Future<void> logCharacterSelect(String characterId) async {
    await _analytics.logEvent(
      name: 'character_select',
      parameters: {'character_id': characterId},
    );
  }
}
```

---

## 4. Integration in Game Code

### game_over_screen.dart
Add leaderboard submission:
```dart
import '../services/leaderboard_service.dart';
import '../services/analytics_service.dart';

// In game over handler:
await LeaderboardService.submitScore(
  score: _finalScore,
  rank: _rankLabel(_finalScore),
  jellifyLevel: vm.jellifyLevel,
);

await AnalyticsService.logGameOver(
  score: _finalScore,
  rank: _rankLabel(_finalScore),
  wallsPassed: vm.wallsPassed,
);
```

### home_screen.dart
Initialize auth on app start:
```dart
import '../services/auth_service.dart';

@override
void initState() {
  super.initState();
  AuthService.signInAnonymously();
}
```

---

## 5. Testing Checklist

- [ ] Firebase project created
- [ ] google-services.json placed correctly
- [ ] Firebase packages added to pubspec.yaml
- [ ] flutterfire configure completed
- [ ] firebase_options.dart generated
- [ ] Anonymous auth enabled
- [ ] Firestore database created
- [ ] Realtime database created
- [ ] Analytics enabled
- [ ] Services created (auth, leaderboard, cloud save, analytics)
- [ ] Game code integrated
- [ ] APK builds successfully
- [ ] Anonymous sign-in works in app
- [ ] Leaderboard submissions appear in Firestore
- [ ] Analytics events logged

---

## 6. Common Issues & Fixes

### "google-services.json not found"
```
✓ Ensure file is in: android/app/google-services.json
✓ File exists after flutterfire configure
```

### Firebase package import errors
```bash
flutter pub get
flutter clean
flutter pub get
flutter build apk
```

### Leaderboard not updating
```
✓ Check anonymous auth is enabled
✓ Check Firestore security rules allow write
✓ Check user is signed in before submit
```

### Analytics not appearing
```
✓ Check 24-48 hour delay for Firebase Analytics
✓ Enable Google Analytics in Firebase console
```

---

## 7. Security (Production Ready)

After testing, update Firestore rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /leaderboards/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

---

## Timeline
- Firebase setup: 30 min
- Services implementation: 60 min
- Integration: 60 min
- Testing: 30 min
- **Total Phase B**: 3-4 hours
