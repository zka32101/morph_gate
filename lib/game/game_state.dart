import 'package:flutter/foundation.dart';
import 'dart:math';
import '../utils/constants.dart';
import '../utils/shape_utils.dart';
import '../services/ai_service.dart';

enum GameStatus { idle, playing, paused, gameOver }

enum GameMode { normal, dailyChallenge }

enum MissionType {
  wallsPassed,      // n壁以上通過
  comboStreak,      // nコンボ達成
  noShieldLoss,     // シールド喪失なしでn壁
  dangerSurvive,    // 危機モード（1枚）でn壁耐える
  bonusWalls,       // nつのボーナス壁クリア
}

class Mission {
  final MissionType type;
  final int targetValue;
  final String description;
  final String icon;

  int progress = 0;
  bool completed = false;

  Mission({
    required this.type,
    required this.targetValue,
    required this.description,
    required this.icon,
  });

  String get progressText {
    switch (type) {
      case MissionType.wallsPassed:
      case MissionType.noShieldLoss:
      case MissionType.dangerSurvive:
      case MissionType.bonusWalls:
        return '$progress/$targetValue';
      case MissionType.comboStreak:
        return '$progress/$targetValue';
    }
  }
}

class GameState extends ChangeNotifier {
  GameStatus status = GameStatus.idle;
  GameMode mode = GameMode.normal;

  // Score
  int score = 0;
  int wallsPassed = 0;
  int combo = 0;
  double comboMultiplier = GameConfig.comboMin;

  // Player shape
  ShapeType activeShape = ShapeType.square;
  CompositeShape? activeComposite;
  bool isCompositeActive = false;

  // Morph Charge system
  ShapeType? _lastWallShape;
  int morphChargeCount = 0;
  bool isMorphCharged = false;

  // Difficulty
  DifficultyLevel difficultyLevel = DifficultyLevel.easy;
  double currentSpeed = GameConfig.speedEasy;
  double currentHoleSizeRatio = GameConfig.holeSizeEasy;

  // Evolution
  int jellifyLevel = 0;

  // Shield / HP system — ハラハラ感の核
  static const int maxShields = 3;
  int shields = maxShields;
  bool get isInDanger => shields <= 1;
  bool get isLastChance => shields == 1;

  // Mission system
  Mission? currentMission;
  int missionRewardMultiplier = 1;
  bool _missionJustCompleted = false;
  bool get missionJustCompleted => _missionJustCompleted;
  void consumeMissionCompletedFlag() => _missionJustCompleted = false;

  // Next wall hint (set by wall_game after spawning)
  ShapeType? nextWallShape;
  bool nextWallIsComposite = false;
  CompositeShape? nextWallComposite;
  WallTier nextWallTier = WallTier.normal;

  void setNextWall({
    ShapeType? shape,
    bool isComposite = false,
    CompositeShape? composite,
    WallTier tier = WallTier.normal,
  }) {
    nextWallShape = shape;
    nextWallIsComposite = isComposite;
    nextWallComposite = composite;
    nextWallTier = tier;
    notifyListeners();
  }

  void addBonusScore(int amount) {
    score += amount;
    notifyListeners();
  }

  void startGame(int savedJellifyLevel, {GameMode mode = GameMode.normal}) {
    status = GameStatus.playing;
    this.mode = mode;
    score = 0;
    wallsPassed = 0;
    combo = 0;
    comboMultiplier = GameConfig.comboMin;
    activeShape = ShapeType.square;
    activeComposite = null;
    isCompositeActive = false;
    jellifyLevel = savedJellifyLevel;
    shields = maxShields;
    currentSpeed = GameConfig.speedEasy;
    currentHoleSizeRatio = GameConfig.holeSizeEasy;
    nextWallShape = null;
    nextWallIsComposite = false;
    nextWallComposite = null;
    nextWallTier = WallTier.normal;
    missionRewardMultiplier = 1;
    _generateRandomMission();
    notifyListeners();
  }

  void _generateRandomMission() {
    final rng = Random();
    final missions = [
      Mission(
        type: MissionType.wallsPassed,
        targetValue: 20 + rng.nextInt(15),
        description: '壁を通過する',
        icon: '🧱',
      ),
      Mission(
        type: MissionType.comboStreak,
        targetValue: 10 + rng.nextInt(10),
        description: 'コンボを達成',
        icon: '⭐',
      ),
      Mission(
        type: MissionType.noShieldLoss,
        targetValue: 15 + rng.nextInt(10),
        description: 'シールドロスなし',
        icon: '🛡️',
      ),
      Mission(
        type: MissionType.dangerSurvive,
        targetValue: 8 + rng.nextInt(6),
        description: '危機モードで耐える',
        icon: '💔',
      ),
      Mission(
        type: MissionType.bonusWalls,
        targetValue: 3 + rng.nextInt(3),
        description: 'ボーナス壁をクリア',
        icon: '✨',
      ),
    ];
    currentMission = missions[rng.nextInt(missions.length)];
  }

  /// 日付ベースの乱数シード生成（デイリーチャレンジ用）
  static int getDailyChallengeSeed() {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  void setShape(ShapeType shape) {
    activeShape = shape;
    activeComposite = null;
    isCompositeActive = false;
    notifyListeners();
  }

  void setCompositeShape(CompositeShape composite) {
    activeComposite = composite;
    isCompositeActive = true;
    notifyListeners();
  }

  void onWallPassed({required bool isComposite, required double accuracy, WallTier wallTier = WallTier.normal}) {
    wallsPassed++;

    final accuracyBonus = (accuracy * ScoreConfig.accuracyBonusMax).toInt();
    final compositeBonus = isComposite ? ScoreConfig.compositeBonusFlatScore : 0;
    final evolutionBonus = 1.0 + (jellifyLevel * ScoreConfig.evolutionBonusPerLevel);

    var gained = ((ScoreConfig.baseScore + accuracyBonus + compositeBonus) *
            comboMultiplier *
            evolutionBonus)
        .toInt();

    // Mission progress & reward
    _updateMissionProgress(wallTier);
    if (currentMission?.completed ?? false) {
      final missionBonus = (gained * 0.5 * missionRewardMultiplier).toInt();
      gained += missionBonus;
      _missionJustCompleted = true;
      missionRewardMultiplier++;
    }
    score += gained;

    combo++;
    comboMultiplier = (GameConfig.comboMin + combo * GameConfig.comboStep)
        .clamp(GameConfig.comboMin, GameConfig.comboMax);

    // Morph Charge
    if (_lastWallShape == activeShape && !isComposite) {
      morphChargeCount++;
      if (morphChargeCount >= 3) {
        isMorphCharged = true;
        morphChargeCount = 0;
      }
    } else {
      morphChargeCount = 0;
    }
    _lastWallShape = isComposite ? null : activeShape;

    // シールド回復: 15壁ごとに1枚（満タンでない場合）
    if (wallsPassed % 15 == 0 && shields < maxShields) {
      shields++;
      _justRecoveredShield = true;
    }

    _updateDifficultyByWall();
    notifyListeners();
  }

  // 1フレームだけ立つフラグ（演出トリガー用）
  bool _justRecoveredShield = false;
  bool consumeShieldRecoveredFlag() {
    if (_justRecoveredShield) {
      _justRecoveredShield = false;
      return true;
    }
    return false;
  }

  void _updateMissionProgress(WallTier wallTier) {
    final m = currentMission;
    if (m == null || m.completed) return;

    switch (m.type) {
      case MissionType.wallsPassed:
        m.progress = wallsPassed;
      case MissionType.comboStreak:
        m.progress = combo;
      case MissionType.noShieldLoss:
        if (shields == maxShields) {
          m.progress = wallsPassed;
        }
      case MissionType.dangerSurvive:
        if (isInDanger && shields > 0) {
          m.progress++;
        }
      case MissionType.bonusWalls:
        if (wallTier == WallTier.bonus) {
          m.progress++;
        }
    }

    if (m.progress >= m.targetValue && !m.completed) {
      m.completed = true;
    }
  }

  /// 壁に当たった。シールドを1枚消費。
  /// 戻り値: true=まだ生存（シールド残あり）, false=ゲームオーバー
  bool onWallMissed() {
    combo = 0;
    comboMultiplier = GameConfig.comboMin;
    morphChargeCount = 0;
    isMorphCharged = false;
    if (shields > 0) shields--;
    notifyListeners();
    return shields > 0;
  }

  /// シールド回復（一定壁数ごとのご褒美）
  void recoverShield() {
    if (shields < maxShields) {
      shields++;
      notifyListeners();
    }
  }

  void triggerGameOver() {
    status = GameStatus.gameOver;
    notifyListeners();
  }

  void _updateDifficultyByWall() {
    if (wallsPassed >= GameConfig.stageExpertStart) {
      difficultyLevel = DifficultyLevel.expert;
      currentSpeed = GameConfig.speedExpert;
      currentHoleSizeRatio = GameConfig.holeSizeExpert;
    } else if (wallsPassed >= GameConfig.stageHardStart) {
      difficultyLevel = DifficultyLevel.hard;
      currentSpeed = GameConfig.speedHard;
      currentHoleSizeRatio = GameConfig.holeSizeHard;
    } else if (wallsPassed >= GameConfig.stageNormalStart) {
      difficultyLevel = DifficultyLevel.normal;
      currentSpeed = GameConfig.speedNormal;
      currentHoleSizeRatio = GameConfig.holeSizeNormal;
    }
  }

  void applyAIDifficulty(DifficultyAdjustment adjustment) {
    difficultyLevel = adjustment.level;
    currentSpeed *= adjustment.speedMultiplier;
    currentHoleSizeRatio *= adjustment.holeSizeMultiplier;
    currentSpeed = currentSpeed.clamp(100.0, 500.0);
    currentHoleSizeRatio = currentHoleSizeRatio.clamp(0.9, 2.0);
    notifyListeners();
  }
}
