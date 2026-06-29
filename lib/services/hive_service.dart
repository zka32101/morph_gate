import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class HiveService {
  static late Box<UserModel> _userBox;
  static late Box<dynamic> _settingsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(UserModelAdapter());
    _userBox = await Hive.openBox<UserModel>(HiveBoxes.userBox);
    _settingsBox = await Hive.openBox(HiveBoxes.settingsBox);
  }

  static UserModel getOrCreateUser() {
    if (_userBox.isEmpty) {
      final user = UserModel(
        id: const Uuid().v4(),
        nickname: 'JellyPlayer',
        createdAt: DateTime.now(),
      );
      _userBox.add(user);
      return user;
    }
    return _userBox.getAt(0)!;
  }

  static void updateHighScore(int score) {
    final user = getOrCreateUser();
    if (score > user.totalHighScore) {
      user.totalHighScore = score;
      user.save();
    }
  }

  static void addWallsPassed(int count) {
    final user = getOrCreateUser();
    user.totalWallsPassed += count;
    user.save();
  }

  static void updateJellifyLevel(int level) {
    final user = getOrCreateUser();
    user.jellifyLevel = level;
    user.save();
  }

  static void addCoins(int coins) {
    final user = getOrCreateUser();
    user.coins += coins;
    user.save();
  }

  static int getHighScore() => getOrCreateUser().totalHighScore;
  static int getTotalWallsPassed() => getOrCreateUser().totalWallsPassed;
  static int getJellifyLevel() => getOrCreateUser().jellifyLevel;

  static int getTotalGamesPlayed() =>
      _settingsBox.get('totalGamesPlayed', defaultValue: 0) as int;

  static void incrementGamesPlayed() {
    final current = getTotalGamesPlayed();
    _settingsBox.put('totalGamesPlayed', current + 1);
  }

  static double getRecentClearRate() =>
      _settingsBox.get('recentClearRate', defaultValue: 0.5) as double;

  static void updateClearRate(double rate) {
    _settingsBox.put('recentClearRate', rate);
  }

  static bool isSoundEnabled() =>
      _settingsBox.get('soundEnabled', defaultValue: true) as bool;

  static void setSoundEnabled(bool value) =>
      _settingsBox.put('soundEnabled', value);

  static T getSetting<T>(String key, T defaultValue) =>
      (_settingsBox.get(key) as T?) ?? defaultValue;

  static dynamic getSettingNullable(String key) => _settingsBox.get(key);

  static void putSetting(String key, dynamic value) =>
      _settingsBox.put(key, value);
}
