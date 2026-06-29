import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nickname;

  @HiveField(2)
  int coins;

  @HiveField(3)
  int totalHighScore;

  @HiveField(4)
  int jellifyLevel;

  @HiveField(5)
  int totalWallsPassed;

  @HiveField(6)
  DateTime createdAt;

  UserModel({
    required this.id,
    required this.nickname,
    this.coins = 0,
    this.totalHighScore = 0,
    this.jellifyLevel = 0,
    this.totalWallsPassed = 0,
    required this.createdAt,
  });
}
