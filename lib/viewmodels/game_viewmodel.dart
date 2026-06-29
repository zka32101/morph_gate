import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/game_state.dart';
import 'package:flutter/material.dart';
import '../models/character_model.dart';
import '../services/ai_service.dart';
import '../services/character_service.dart';
import '../services/ghost_service.dart';
import '../services/hive_service.dart';
import '../services/sound_service.dart';
import '../utils/constants.dart';

final gameViewModelProvider =
    ChangeNotifierProvider<GameViewModel>((ref) => GameViewModel());

class GameViewModel extends GameState {
  int _sessionWallsHit = 0;
  String? lastAIMessage;
  String? evolutionStory;
  bool showEvolutionOverlay = false;
  bool justOvertookGhost = false;

  Color get characterBaseColor => CharacterService.getSelected().baseColor;

  // ── Ghost Race ────────────────────────────────────────────────────────
  final _ghostRecorder = GhostRecorder();
  List<int> _ghostTimeline = [];
  int get ghostScore =>
      GhostService.ghostScoreAt(_ghostTimeline, wallsPassed);
  bool get hasGhost => _ghostTimeline.isNotEmpty;

  void initGame() {
    final level = HiveService.getJellifyLevel();
    startGame(level);
    _sessionWallsHit = 0;
    _ghostTimeline = GhostService.getBestTimeline();
    _ghostRecorder.reset();
  }

  @override
  void onWallPassed({required bool isComposite, required double accuracy}) {
    final prevScore = score;
    final ghostNow = ghostScoreAt(wallsPassed);
    super.onWallPassed(isComposite: isComposite, accuracy: accuracy);
    _ghostRecorder.recordWall(score);
    _checkEvolution();
    // 追い抜き検出
    if (hasGhost && prevScore < ghostNow && score >= ghostNow) {
      justOvertookGhost = true;
      notifyListeners();
    }
  }

  void clearOvertakeFlag() {
    justOvertookGhost = false;
  }

  int ghostScoreAt(int wall) => GhostService.ghostScoreAt(_ghostTimeline, wall);

  @override
  bool onWallMissed() {
    final survived = super.onWallMissed();
    _sessionWallsHit++;
    return survived;
  }

  @override
  void triggerGameOver() {
    super.triggerGameOver();
    _persistResults();
    _requestAIDifficulty();
  }

  void _checkEvolution() {
    final total = HiveService.getTotalWallsPassed() + wallsPassed;
    final thresholds = EvolutionConfig.thresholds;
    final names = EvolutionConfig.names;

    int newLevel = 0;
    for (int i = thresholds.length - 1; i >= 0; i--) {
      if (total >= thresholds[i]) {
        newLevel = i;
        break;
      }
    }

    if (newLevel > jellifyLevel) {
      final prevName = names[jellifyLevel];
      final nextName = names[newLevel];
      jellifyLevel = newLevel;
      HiveService.updateJellifyLevel(newLevel);
      _generateEvolutionStory(prevName, nextName);
    }
  }

  Future<void> _generateEvolutionStory(String from, String to) async {
    SoundService().playEvolution();
    evolutionStory = await AIService.generateEvolutionStory(from, to);
    showEvolutionOverlay = true;
    notifyListeners();
  }

  void dismissEvolutionOverlay() {
    showEvolutionOverlay = false;
    notifyListeners();
  }

  void _persistResults() {
    _ghostRecorder.save(score);   // ゴーストラン保存（ハイスコア更新時のみ）
    HiveService.updateHighScore(score);
    HiveService.addWallsPassed(wallsPassed);
    HiveService.incrementGamesPlayed();

    final total = wallsPassed + _sessionWallsHit;
    if (total > 0) {
      final rate = (wallsPassed / total * 100).round();
      HiveService.updateClearRate(rate.toDouble());
    }
  }

  Future<void> _requestAIDifficulty() async {
    final clearRate = HiveService.getRecentClearRate().round();
    final adjustment = await AIService.analyzeDifficulty(
      clearRate: clearRate,
      maxCombo: combo,
      totalGamesPlayed: HiveService.getTotalGamesPlayed(),
      currentLevel: difficultyLevel,
    );
    applyAIDifficulty(adjustment);
    lastAIMessage = adjustment.reason;
    notifyListeners();
  }
}
