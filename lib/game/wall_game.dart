import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/game_state.dart' show GameMode;
import '../services/ai_service.dart';
import '../services/character_service.dart';
import '../services/sound_service.dart';
import '../viewmodels/game_viewmodel.dart';
import '../utils/constants.dart';
import '../utils/shape_utils.dart';
import 'components/background.dart';
import 'components/player.dart';
import 'components/wall.dart';
import 'collision_handler.dart';
import 'game_state.dart';

enum _RhythmEvent { normal, calm, rush, burst, zigzag, echo, breathe }

class WallGame extends FlameGame {
  final GameState gameState;
  final VoidCallback onGameOver;

  late PlayerComponent _player;
  late BackgroundComponent _background;
  final List<WallComponent> _walls = [];
  late Random _rng;

  double _wallSpawnTimer = 0;
  double _wallSpawnInterval = 2.0;

  // Composite shape simultaneous press tracking
  ShapeType? _pendingShape;
  DateTime? _pendingShapePressTime;

  // Score float texts
  final List<_ScoreFloat> _scoreFloats = [];

  // Screen flash (on pass)
  double _screenFlash = 0.0;
  Color _flashColor = Colors.white;

  // Ghost race
  double _ghostBeatLife = 0.0;
  double _ghostOrbitAngle = 0.0;

  // Near-miss slow-motion
  double _slowmotionTimer = 0.0;
  static const double _slowmotionDuration = 0.3;
  static const double _slowmotionSpeed = 0.4;
  double _slowZoom = 1.0;

  // Rhythm/pattern event system
  _RhythmEvent _currentZone = _RhythmEvent.normal;
  int _zoneWallsLeft = 0;
  int _interZoneCountdown = 0;
  double _zoneMultiplier = 1.0;
  int _patternStep = 0;           // zigzag step
  ShapeType? _echoShape;          // echo last shape
  double _burstPendingTimer = 0;  // burst: timer for queued extra spawns
  int _burstPending = 0;          // burst: number of extra walls still to spawn
  bool _breatheActive = false;    // breathe: skip next spawn

  // Announcements (zone events + difficulty transitions)
  String? _announcement;
  Color _announcementColor = Colors.white;
  double _announcementLife = 0.0;

  // Difficulty transition tracking
  DifficultyLevel _lastDifficulty = DifficultyLevel.easy;

  // Player trail
  final List<_TrailDot> _trail = [];

  // Wall clear burst particles
  final List<_WallBurst> _wallBursts = [];

  // Combo milestone banners
  final List<_ComboMilestone> _comboMilestones = [];

  // Screen shake
  double _shakeTimer = 0.0;
  double _shakeMagnitude = 0.0;

  // Danger mode (low shields) — heartbeat pulse phase
  double _heartbeatPhase = 0.0;
  double _shieldBreakFlash = 0.0;

  GameViewModel? get _vm =>
      gameState is GameViewModel ? gameState as GameViewModel : null;

  WallGame({required this.gameState, required this.onGameOver});

  @override
  Color backgroundColor() => const Color(0xFF080415);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final seed = gameState.mode == GameMode.dailyChallenge
        ? GameState.getDailyChallengeSeed()
        : null;
    _rng = seed != null ? Random(seed) : Random();

    _background = BackgroundComponent();
    add(_background);

    _player = PlayerComponent()
      ..position = Vector2(size.x / 2, size.y * 0.60)
      ..jellifyLevel = gameState.jellifyLevel
      ..characterBaseColor = CharacterService.getSelected().baseColor;
    add(_player);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState.status != GameStatus.playing) return;

    // Sync background with difficulty
    _background.difficultyLevel = gameState.difficultyLevel;

    _spawnWalls(dt);
    _updateProximity();
    _checkCollisions();
    _cleanupWalls();
    _checkDifficultyTransition();

    _player.activeShape = gameState.activeShape;
    _player.activeComposite = gameState.activeComposite;
    _player.isCompositeActive = gameState.isCompositeActive;
    _player.jellifyLevel = gameState.jellifyLevel;

    // Score float texts
    for (final f in _scoreFloats) {
      f.update(dt);
    }
    _scoreFloats.removeWhere((f) => f.dead);

    // Screen flash decay
    if (_screenFlash > 0) {
      _screenFlash = (_screenFlash - dt * 5).clamp(0.0, 1.0);
    }

    // Ghost orbit
    _ghostOrbitAngle += dt * 1.5;
    if (_ghostBeatLife > 0) {
      _ghostBeatLife = (_ghostBeatLife - dt * 1.2).clamp(0.0, 1.0);
    }
    if (_vm?.justOvertookGhost == true) {
      _ghostBeatLife = 1.0;
      _vm?.clearOvertakeFlag();
    }

    // Slow motion
    if (_slowmotionTimer > 0) {
      _slowmotionTimer -= dt;
      final progress = 1.0 - (_slowmotionTimer / _slowmotionDuration);
      _slowZoom = 1.0 + progress * 0.15;
    }

    // Announcement decay
    if (_announcementLife > 0) {
      _announcementLife = (_announcementLife - dt * 0.9).clamp(0.0, 1.5);
    }

    // Player trail dots
    if (gameState.status == GameStatus.playing) {
      _trail.add(_TrailDot(x: _player.position.x, y: _player.position.y));
      for (final t in _trail) {
        t.update(dt);
      }
      _trail.removeWhere((t) => t.dead);
    }

    // Wall burst particles
    for (final b in _wallBursts) {
      b.update(dt);
    }
    _wallBursts.removeWhere((b) => b.dead);

    // Combo milestones
    for (final m in _comboMilestones) {
      m.update(dt);
    }
    _comboMilestones.removeWhere((m) => m.dead);

    // Screen shake
    if (_shakeTimer > 0) {
      _shakeTimer = (_shakeTimer - dt).clamp(0.0, 1.0);
    }

    // Danger heartbeat (faster when last shield)
    if (gameState.isInDanger) {
      final rate = gameState.isLastChance ? 3.2 : 2.0;
      _heartbeatPhase += dt * rate;
    } else {
      _heartbeatPhase = 0.0;
    }

    // Shield break flash decay
    if (_shieldBreakFlash > 0) {
      _shieldBreakFlash = (_shieldBreakFlash - dt * 2.5).clamp(0.0, 1.0);
    }
  }

  void _onShieldBreak(Vector2 at, WallComponent wall) {
    _shieldBreakFlash = 1.0;
    _screenFlash = 0.7;
    _flashColor = const Color(0xFFFF2244);
    _shakeTimer = 0.5;
    _shakeMagnitude = 14.0;
    _slowmotionTimer = _slowmotionDuration;

    // Red shatter burst
    _wallBursts.add(_WallBurst(
      x: at.x,
      y: at.y,
      color: const Color(0xFFFF3355),
      count: 26,
    ));

    // Pulverize the wall so player passes through
    wall.markPassed();

    final remaining = gameState.shields;
    _scoreFloats.add(_ScoreFloat(
      x: at.x,
      y: at.y - GameConfig.playerRadius - 20,
      text: remaining == 1 ? '💔 LAST SHIELD!' : '🛡️ -1',
      color: const Color(0xFFFF5577),
      fontSize: remaining == 1 ? 20 : 16,
    ));

    if (remaining == 1) {
      _showAnnouncement('⚠️ LAST CHANCE!', const Color(0xFFFF3344));
    }
  }

  void _checkDifficultyTransition() {
    final level = gameState.difficultyLevel;
    if (level != _lastDifficulty) {
      _lastDifficulty = level;
      switch (level) {
        case DifficultyLevel.normal:
          _showAnnouncement('▶ NORMAL', const Color(0xFF64B5F6));
        case DifficultyLevel.hard:
          _showAnnouncement('🔥 HARD MODE!', const Color(0xFFFF8C00));
        case DifficultyLevel.expert:
          _showAnnouncement('⚡ EXPERT!!', const Color(0xFFFF3333));
        default:
          break;
      }
    }
  }

  void _triggerNextRhythm() {
    // Weight table based on difficulty
    final diff = gameState.difficultyLevel.index; // 0-3
    // Weights: [calm, rush, burst, zigzag, echo, breathe]
    final weights = diff == 0
        ? [4, 2, 1, 1, 1, 3] // Easy: more calm/breathe
        : diff == 1
            ? [3, 3, 2, 2, 2, 2] // Normal: balanced
            : diff == 2
                ? [2, 4, 3, 3, 3, 1] // Hard: rush/burst heavy
                : [1, 4, 4, 4, 3, 1]; // Expert: intense

    final total = weights.fold(0, (a, b) => a + b);
    int roll = _rng.nextInt(total);
    final events = [
      _RhythmEvent.calm,
      _RhythmEvent.rush,
      _RhythmEvent.burst,
      _RhythmEvent.zigzag,
      _RhythmEvent.echo,
      _RhythmEvent.breathe,
    ];
    int chosen = 0;
    for (int i = 0; i < weights.length; i++) {
      if (roll < weights[i]) {
        chosen = i;
        break;
      }
      roll -= weights[i];
    }
    final event = events[chosen];

    switch (event) {
      case _RhythmEvent.calm:
        _currentZone = _RhythmEvent.calm;
        _zoneMultiplier = 0.55;
        _zoneWallsLeft = 4 + _rng.nextInt(3); // 4-6 walls (was fixed 5)
        _showAnnouncement('💎 CALM ZONE', const Color(0xFF80DEEA));
      case _RhythmEvent.rush:
        _currentZone = _RhythmEvent.rush;
        _zoneMultiplier = 1.45;
        _zoneWallsLeft = 3 + _rng.nextInt(3); // 3-5 walls (was fixed 4)
        _showAnnouncement('⚡ SPEED RUSH!', const Color(0xFFFFD700));
      case _RhythmEvent.burst:
        _currentZone = _RhythmEvent.burst;
        _zoneMultiplier = 1.0;
        _zoneWallsLeft = 2 + _rng.nextInt(3); // 2-4 walls (was fixed 3)
        // Schedule 2-3 extra rapid-fire walls after this tick
        _burstPending = 2 + _rng.nextInt(2); // 2-3 extra (was fixed 2)
        _burstPendingTimer = 0.32;
        _showAnnouncement('🌪️ BURST!', const Color(0xFFFF6B35));
      case _RhythmEvent.zigzag:
        _currentZone = _RhythmEvent.zigzag;
        _zoneMultiplier = 0.9;
        _zoneWallsLeft = 3 + _rng.nextInt(3); // 3-5 walls (was fixed 4)
        _patternStep = 0;
        _showAnnouncement('↔ ZIGZAG!', const Color(0xFF66FFB2));
      case _RhythmEvent.echo:
        _currentZone = _RhythmEvent.echo;
        _zoneMultiplier = 0.85;
        _zoneWallsLeft = 3 + _rng.nextInt(3); // 3-5 walls (was fixed 4)
        _echoShape = null;
        _showAnnouncement('🔁 ECHO!', const Color(0xFFCE93D8));
      case _RhythmEvent.breathe:
        _currentZone = _RhythmEvent.normal; // don't change speed...
        _breatheActive = true;              // ...just stretch next gap
        _interZoneCountdown = 3 + _rng.nextInt(4); // 3-6 walls wait (was fixed 5)
        _showAnnouncement('💨 BREATHE', const Color(0xFF90CAF9));
      default:
        break;
    }
  }

  void _showAnnouncement(String text, Color color) {
    _announcement = text;
    _announcementColor = color;
    _announcementLife = 1.5;
  }

  void _spawnWalls(double dt) {
    // Burst: handle queued extra spawns with delay
    if (_burstPending > 0) {
      _burstPendingTimer -= dt;
      if (_burstPendingTimer <= 0) {
        _burstPendingTimer = 0.38;
        _burstPending--;
        _spawnWall();
      }
    }

    _wallSpawnTimer += dt;
    _wallSpawnInterval =
        (size.y / (gameState.currentSpeed * _zoneMultiplier)) * 0.85;

    // Breathe: stretch one interval
    if (_breatheActive) {
      if (_wallSpawnTimer >= _wallSpawnInterval * 2.2) {
        _wallSpawnTimer = 0;
        _breatheActive = false;
        _spawnWall();
      }
      return;
    }

    if (_wallSpawnTimer >= _wallSpawnInterval) {
      _wallSpawnTimer = 0;
      _onNormalSpawnTick();
    }
  }

  void _onNormalSpawnTick() {
    switch (_currentZone) {
      case _RhythmEvent.zigzag:
        // Hole shifts L → C → R → C → repeat
        final xRatios = [0.28, 0.50, 0.72, 0.50];
        final xRatio = xRatios[_patternStep % xRatios.length];
        _spawnWall(holeXRatio: xRatio);
      case _RhythmEvent.echo:
        // Same shape twice
        final shape = _echoShape ?? ShapeType.values[_rng.nextInt(4)];
        _echoShape = shape;
        _spawnWall(forcedShape: shape, thicknessRatio: 0.7);
      case _RhythmEvent.burst:
        // Main spawn already handled; this tick triggers standard wall
        _spawnWall();
      default:
        _spawnWall();
    }
  }

  /// Actual WallComponent spawner. Optional overrides for pattern use.
  void _spawnWall({
    double holeXRatio = 0.5,
    double thicknessRatio = 1.0,
    ShapeType? forcedShape,
    WallTier? forcedTier,
  }) {
    final isComposite = gameState.difficultyLevel == DifficultyLevel.expert &&
        forcedShape == null &&
        _rng.nextDouble() < 0.3;
    final isReverseRule = gameState.difficultyLevel.index >= 1 &&
        forcedTier == null &&
        _rng.nextDouble() < 0.08;
    final isReverse = gameState.difficultyLevel.index >= 2 &&
        _rng.nextDouble() < 0.05;

    // Determine tier (with increased randomness for visual variety)
    WallTier tier = forcedTier ?? WallTier.normal;
    if (forcedTier == null && !isReverseRule && !isComposite) {
      final roll = _rng.nextDouble();
      if (gameState.difficultyLevel.index >= 1 && roll < 0.12) { // 6% → 12%
        tier = WallTier.bonus;
      } else if (gameState.difficultyLevel.index >= 2 && roll < 0.20) { // 12% → 20%
        tier = WallTier.danger;
      }
    }

    ShapeType? holeShape;
    CompositeShape? holeComposite;

    if (isComposite) {
      holeComposite =
          CompositeShape.values[_rng.nextInt(CompositeShape.values.length)];
    } else {
      holeShape = forcedShape ?? ShapeType.values[_rng.nextInt(ShapeType.values.length)];
    }

    // Add more randomness to hole position (even in themed zones, add slight variation)
    if (holeXRatio == 0.5) {
      holeXRatio = 0.5 + (_rng.nextDouble() - 0.5) * 0.4; // ±20% drift
      holeXRatio = holeXRatio.clamp(0.20, 0.80);
    }

    // Random thickness variation (adds visual unpredictability)
    double actualThicknessRatio = thicknessRatio;
    if (thicknessRatio == 1.0 && _rng.nextDouble() < 0.35) {
      actualThicknessRatio = 0.8 + _rng.nextDouble() * 0.6; // 0.8~1.4
    }

    double sizeModifier = 1.0;
    if (tier == WallTier.bonus) sizeModifier = 1.18;
    if (tier == WallTier.danger) sizeModifier = 0.82;

    final holeRadius = GameConfig.playerRadius *
        gameState.currentHoleSizeRatio *
        sizeModifier *
        (0.90 + _rng.nextDouble() * 0.2); // Increased randomness: 0.90~1.10

    final spawnY = isReverse
        ? size.y + GameConfig.wallThickness * thicknessRatio
        : -GameConfig.wallThickness * thicknessRatio;

    final wallSpeed = gameState.currentSpeed * _zoneMultiplier;

    final wall = WallComponent(
      position: Vector2(0, spawnY),
      width: size.x,
      speed: wallSpeed,
      holeRadius: holeRadius,
      holeShapeType: holeShape,
      holeCompositeShape: holeComposite,
      isCompositeHole: isComposite,
      isReverseRule: isReverseRule,
      isReverse: isReverse,
      tier: tier,
      holeXRatio: holeXRatio,
      thicknessRatio: actualThicknessRatio,
    );
    _walls.add(wall);
    add(wall);

    gameState.setNextWall(
      shape: holeShape,
      isComposite: isComposite,
      composite: holeComposite,
      tier: tier,
    );
  }

  void _onWallPassedZone() {
    if (_zoneWallsLeft > 0) {
      _zoneWallsLeft--;
      if (_currentZone == _RhythmEvent.zigzag) _patternStep++;
      if (_zoneWallsLeft == 0) {
        _currentZone = _RhythmEvent.normal;
        _zoneMultiplier = 1.0;
        _patternStep = 0;
        _echoShape = null;
        _interZoneCountdown = 4 + _rng.nextInt(6); // Reduced pause between zones
      }
    } else if (_interZoneCountdown > 0) {
      _interZoneCountdown--;
    } else if (gameState.wallsPassed > 4 && _rng.nextInt(10) == 0) { // More frequent zone triggers
      _triggerNextRhythm();
    }
  }

  void _updateProximity() {
    final playerY = _player.position.y;
    const warningDistance = 160.0;

    for (final wall in _walls) {
      if (wall.passed || wall.missed) {
        wall.proximityRatio = 0.0;
        continue;
      }
      final wallCenterY = wall.position.y + GameConfig.wallThickness / 2;
      final dist = (playerY - wallCenterY).abs();
      wall.proximityRatio = dist < warningDistance
          ? (1.0 - dist / warningDistance).clamp(0.0, 1.0)
          : 0.0;
    }
  }

  void _checkCollisions() {
    final playerCenter = _player.position;

    for (final wall in _walls) {
      if (wall.passed || wall.missed) continue;

      final wallTop = wall.position.y;
      final wallBottom = wall.position.y + wall.size.y;

      if (playerCenter.y >= wallTop && playerCenter.y <= wallBottom) {
        final result = CollisionHandler.check(
          wall: wall,
          state: gameState,
          playerX: playerCenter.x,
          playerY: playerCenter.y,
        );

        if (result.isPass) {
          wall.markPassed();
          final prevScore = gameState.score;
          final prevCombo = gameState.comboMultiplier;
          gameState.onWallPassed(
            isComposite: wall.isCompositeHole,
            accuracy: result.accuracy,
            wallTier: wall.tier,
          );
          var gained = gameState.score - prevScore;

          // Bonus wall: +50% score
          if (wall.tier == WallTier.bonus) {
            final extra = (gained * 0.5).toInt();
            gameState.addBonusScore(extra);
            gained += extra;
            _scoreFloats.add(_ScoreFloat(
              x: playerCenter.x - 20,
              y: playerCenter.y - GameConfig.playerRadius - 30,
              text: '✨ LUCKY!',
              color: const Color(0xFF66FFB2),
              fontSize: 16,
            ));
          }
          if (wall.tier == WallTier.danger) {
            _scoreFloats.add(_ScoreFloat(
              x: playerCenter.x + 20,
              y: playerCenter.y - GameConfig.playerRadius - 30,
              text: '💥 DANGER CLEAR!',
              color: const Color(0xFFFFAA44),
              fontSize: 14,
            ));
          }

          if (gained > 0) {
            _scoreFloats.add(_ScoreFloat(
              x: playerCenter.x,
              y: playerCenter.y - GameConfig.playerRadius - 10,
              text: '+$gained',
              color: gameState.comboMultiplier > prevCombo
                  ? const Color(0xFFE040FB)
                  : const Color(0xFF7EFFF5),
              fontSize: gameState.comboMultiplier > prevCombo ? 22 : 16,
            ));
          }

          // Wall clear burst
          final burstColor = wall.tier == WallTier.bonus
              ? const Color(0xFF66FFB2)
              : wall.tier == WallTier.danger
                  ? const Color(0xFFFFAA44)
                  : result.usedMorphCharge
                      ? const Color(0xFFFFD700)
                      : const Color(0xFF9C6FFF);
          _wallBursts.add(_WallBurst(
            x: playerCenter.x,
            y: wall.position.y + wall.size.y / 2,
            color: burstColor,
            count: gameState.comboMultiplier >= 2.0 ? 18 : 12,
          ));

          // Combo milestone
          final newCombo = gameState.combo;
          if (newCombo > 0 && (newCombo == 5 || newCombo == 10 || newCombo == 20 || newCombo % 25 == 0)) {
            final isMax = newCombo >= 20;
            _comboMilestones.add(_ComboMilestone(
              x: size.x / 2,
              y: size.y * 0.42,
              combo: newCombo,
              isMax: isMax,
            ));
          }

          // Screen flash
          if (result.usedMorphCharge) {
            _screenFlash = 0.5;
            _flashColor = const Color(0xFFFFD700);
          } else if (wall.tier == WallTier.bonus) {
            _screenFlash = 0.35;
            _flashColor = const Color(0xFF66FFB2);
          } else {
            _screenFlash = gameState.comboMultiplier > prevCombo ? 0.4 : 0.2;
            _flashColor = gameState.comboMultiplier > prevCombo
                ? const Color(0xFFE040FB)
                : const Color(0xFF7EFFF5);
          }

          // Near-miss slow-mo + haptics
          if (result.accuracy >= 0.95) {
            _slowmotionTimer = _slowmotionDuration;
            HapticFeedback.heavyImpact();
          }

          // Shield recovery feedback
          if (gameState.consumeShieldRecoveredFlag()) {
            _scoreFloats.add(_ScoreFloat(
              x: playerCenter.x,
              y: playerCenter.y - GameConfig.playerRadius - 50,
              text: '🛡️ SHIELD +1',
              color: const Color(0xFF64B5F6),
              fontSize: 18,
            ));
            _screenFlash = 0.4;
            _flashColor = const Color(0xFF64B5F6);
            SoundService().playEvolution();
          }

          // Mission complete feedback
          if (gameState.currentMission?.completed ?? false) {
            gameState.consumeMissionCompletedFlag();
            final m = gameState.currentMission!;
            _scoreFloats.add(_ScoreFloat(
              x: playerCenter.x,
              y: playerCenter.y - GameConfig.playerRadius - 70,
              text: '${m.icon} MISSION COMPLETE!',
              color: const Color(0xFFFFD700),
              fontSize: 16,
            ));
            _screenFlash = 0.5;
            _flashColor = const Color(0xFFFFD700);
            _showAnnouncement('🎯 ${m.description}達成!', const Color(0xFFFFD700));
          }

          // Zone progress
          _onWallPassedZone();

          // Sound
          if (result.usedMorphCharge) {
            SoundService().playEvolution();
          } else if (gameState.comboMultiplier > prevCombo) {
            SoundService().playCombo();
          } else {
            SoundService().playPass();
          }
        } else if (result.isCollision) {
          wall.missed = true;
          _player.triggerSquish();
          final survived = gameState.onWallMissed();
          SoundService().playMiss();

          if (survived) {
            // シールドで耐えた — 壁を粉砕して続行
            HapticFeedback.heavyImpact();
            _onShieldBreak(playerCenter, wall);
          } else {
            // シールド全消失 — ゲームオーバー
            gameState.triggerGameOver();
            onGameOver();
            return;
          }
        }
      }
    }
  }

  void _cleanupWalls() {
    final toRemove = _walls
        .where((w) => w.position.y > size.y + GameConfig.wallThickness * 2)
        .toList();
    for (final w in toRemove) {
      _walls.remove(w);
      remove(w);
    }
    // cleanup reverse walls that went off screen (upward)
    final toRemoveUp = _walls
        .where((w) =>
            w.isReverse && w.position.y < -GameConfig.wallThickness * 2)
        .toList();
    for (final w in toRemoveUp) {
      _walls.remove(w);
      remove(w);
    }
  }

  void onShapeButtonPressed(ShapeType shape) {
    HapticFeedback.lightImpact();

    final now = DateTime.now();

    if (_pendingShape != null && _pendingShapePressTime != null) {
      final diff = now.difference(_pendingShapePressTime!).inMilliseconds;
      if (diff <= GameConfig.compositePressWindowMs) {
        final composite = ShapeUtils.toComposite(_pendingShape!, shape);
        if (composite != null) {
          HapticFeedback.mediumImpact();
          gameState.setCompositeShape(composite);
          _pendingShape = null;
          _pendingShapePressTime = null;
          return;
        }
      }
    }

    _pendingShape = shape;
    _pendingShapePressTime = now;
    gameState.setShape(shape);
  }

  @override
  void render(Canvas canvas) {
    // Screen shake
    if (_shakeTimer > 0) {
      final mag = _shakeMagnitude * _shakeTimer;
      final dx = (sin(_shakeTimer * 47) * mag);
      final dy = (cos(_shakeTimer * 31) * mag);
      canvas.save();
      canvas.translate(dx, dy);
    }

    // Near-miss zoom
    if (_slowmotionTimer > 0) {
      canvas.save();
      canvas.translate(size.x / 2, size.y / 2);
      canvas.scale(_slowZoom, _slowZoom);
      canvas.translate(-size.x / 2, -size.y / 2);
    }

    super.render(canvas);

    if (gameState.status == GameStatus.playing) {
      // Player trail
      _renderTrail(canvas);

      // Danger vignette (low shields) — drawn UNDER content for ambient dread
      if (gameState.isInDanger) {
        _renderDangerVignette(canvas);
      }

      // Screen flash
      if (_screenFlash > 0) {
        final flashPaint = Paint()
          ..color = _flashColor.withOpacity(_screenFlash * 0.18);
        canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), flashPaint);
      }

      // Shield break full-screen red wash
      if (_shieldBreakFlash > 0) {
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.x, size.y),
          Paint()
            ..color = const Color(0xFFFF1133)
                .withOpacity(_shieldBreakFlash * 0.35),
        );
      }

      // Combo edge glow (starts at combo 5+)
      _renderComboEdgeGlow(canvas);

      // Player guide line
      _renderPlayerLine(canvas);

      // Zone indicator bar
      if (_currentZone != _RhythmEvent.normal) {
        _renderZoneBar(canvas);
      }

      // Ghost
      if (_vm?.hasGhost == true) {
        _renderGhostPlayer(canvas);
      }

      _renderHUD(canvas);
      _renderShields(canvas);
      _renderNextHoleHint(canvas);
      _renderScoreFloats(canvas);

      // Wall burst particles
      _renderWallBursts(canvas);

      // Combo milestones
      _renderComboMilestones(canvas);

      // Ghost beat
      if (_ghostBeatLife > 0) {
        _renderGhostBeat(canvas);
      }

      // Announcement
      if (_announcementLife > 0 && _announcement != null) {
        _renderAnnouncement(canvas);
      }
    }

    if (_slowmotionTimer > 0) {
      canvas.restore();
    }

    if (_shakeTimer > 0) {
      canvas.restore();
    }

    // Cinematic framing (dark vignette borders)
    _renderCinematicFrame(canvas);
  }

  void _renderCinematicFrame(Canvas canvas) {
    const topHeight = 20.0;
    const bottomHeight = 20.0;

    // Top dark bar
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, topHeight),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.black.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.x, topHeight)),
    );

    // Bottom dark bar
    canvas.drawRect(
      Rect.fromLTWH(0, size.y - bottomHeight, size.x, bottomHeight),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black,
            Colors.black.withOpacity(0.0),
          ],
        ).createShader(
            Rect.fromLTWH(0, size.y - bottomHeight, size.x, bottomHeight)),
    );
  }

  void _renderWallBursts(Canvas canvas) {
    for (final burst in _wallBursts) {
      for (final p in burst.particles) {
        final alpha = (p.life * 2.0).clamp(0.0, 1.0);
        canvas.drawCircle(
          Offset(p.x, p.y),
          p.size * (0.5 + p.life * 0.5),
          Paint()
            ..color = p.color.withOpacity(alpha)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.4),
        );
      }
    }
  }

  void _renderComboMilestones(Canvas canvas) {
    for (final m in _comboMilestones) {
      final life = m.life;
      double alpha;
      if (life > 1.1) {
        alpha = (1.4 - life) / 0.3;
      } else if (life > 0.3) {
        alpha = 1.0;
      } else {
        alpha = life / 0.3;
      }
      alpha = alpha.clamp(0.0, 1.0);

      final scale = life > 1.1
          ? 0.6 + (1.4 - life) / 0.3 * 0.5
          : 1.0 + (1.0 - life) * 0.08;

      final c = m.isMax ? const Color(0xFFFF6B35) : const Color(0xFFE040FB);

      // glow
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset(m.x, m.y + 14),
            width: size.x * 0.7,
            height: 52),
        Paint()
          ..color = c.withOpacity(alpha * 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );

      canvas.save();
      canvas.translate(m.x, m.y);
      canvas.scale(scale, scale);
      canvas.translate(-m.x, -m.y);

      final label = m.isMax ? '🔥 ${m.combo} COMBO!!' : '⭐ ${m.combo} COMBO!';
      _drawText(canvas, label, Offset(m.x, m.y),
          c.withOpacity(alpha), m.isMax ? 26 : 22,
          textAlign: TextAlign.center, bold: true);
      canvas.restore();
    }
  }

  void _renderTrail(Canvas canvas) {
    for (final t in _trail) {
      final char = CharacterService.getSelected();
      final paint = Paint()
        ..color = char.baseColor.withOpacity(t.opacity * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(t.x, t.y), GameConfig.playerRadius * t.opacity * 0.6, paint);
    }
  }

  void _renderDangerVignette(Canvas canvas) {
    // Heartbeat: double-thump curve
    final beat = _heartbeatCurve(_heartbeatPhase % 1.0);
    final baseIntensity = gameState.isLastChance ? 0.42 : 0.24;
    final intensity = baseIntensity + beat * (gameState.isLastChance ? 0.28 : 0.16);

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.85,
        colors: [
          Colors.transparent,
          const Color(0xFFFF1133).withOpacity(intensity * 0.5),
          const Color(0xFFCC0022).withOpacity(intensity),
        ],
        stops: const [0.55, 0.85, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  /// Double-thump heartbeat curve over [0,1)
  double _heartbeatCurve(double t) {
    // two quick pulses then rest
    if (t < 0.12) return sin(t / 0.12 * pi);
    if (t < 0.28) return 0.6 * sin((t - 0.16) / 0.12 * pi).clamp(0.0, 1.0);
    return 0.0;
  }

  void _renderShields(Canvas canvas) {
    const iconSize = 12.0;
    const gap = 6.0;
    final total = GameState.maxShields;
    final active = gameState.shields;
    final startX = 12.0;
    final y = 60.0;

    for (int i = 0; i < total; i++) {
      final cx = startX + i * (iconSize * 2 + gap) + iconSize;
      final center = Offset(cx, y);
      final isActive = i < active;

      if (isActive) {
        // pulse if this is the last shield
        final isLast = active == 1 && i == 0;
        final pulse = isLast
            ? 1.0 + _heartbeatCurve(_heartbeatPhase % 1.0) * 0.25
            : 1.0;
        final color = active == 1
            ? const Color(0xFFFF3355)
            : active == 2
                ? const Color(0xFFFFB74D)
                : const Color(0xFF64B5F6);

        // glow
        canvas.drawCircle(
          center,
          iconSize * 1.3 * pulse,
          Paint()
            ..color = color.withOpacity(0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        _drawShieldIcon(canvas, center, iconSize * pulse, color, true);
      } else {
        _drawShieldIcon(canvas, center, iconSize,
            Colors.white.withOpacity(0.15), false);
      }
    }
  }

  void _drawShieldIcon(
      Canvas canvas, Offset center, double s, Color color, bool filled) {
    final path = Path();
    path.moveTo(center.dx, center.dy - s);
    path.quadraticBezierTo(
        center.dx + s, center.dy - s, center.dx + s, center.dy - s * 0.2);
    path.lineTo(center.dx + s, center.dy + s * 0.2);
    path.quadraticBezierTo(
        center.dx + s, center.dy + s, center.dx, center.dy + s);
    path.quadraticBezierTo(
        center.dx - s, center.dy + s, center.dx - s, center.dy + s * 0.2);
    path.lineTo(center.dx - s, center.dy - s * 0.2);
    path.quadraticBezierTo(
        center.dx - s, center.dy - s, center.dx, center.dy - s);
    path.close();

    if (filled) {
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _renderComboEdgeGlow(Canvas canvas) {
    final combo = gameState.combo;
    if (combo < 5) return;

    final intensity = ((combo - 5) / 25.0).clamp(0.0, 1.0);
    final glowColor = combo >= 20
        ? const Color(0xFFFF6B35) // orange at high combo
        : const Color(0xFFE040FB); // purple at medium combo
    final alpha = 0.06 + intensity * 0.14 + 0.04 * sin(_ghostOrbitAngle * 3);
    final edgePaint = Paint()
      ..color = glowColor.withOpacity(alpha)
      ..style = PaintingStyle.fill;

    const edgeW = 10.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, edgeW, size.y), edgePaint);
    canvas.drawRect(Rect.fromLTWH(size.x - edgeW, 0, edgeW, size.y), edgePaint);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, edgeW), edgePaint);
    canvas.drawRect(Rect.fromLTWH(0, size.y - edgeW, size.x, edgeW), edgePaint);
  }

  void _renderZoneBar(Canvas canvas) {
    final color = switch (_currentZone) {
      _RhythmEvent.calm => const Color(0xFF80DEEA),
      _RhythmEvent.rush => const Color(0xFFFFD700),
      _RhythmEvent.burst => const Color(0xFFFF6B35),
      _RhythmEvent.zigzag => const Color(0xFF66FFB2),
      _RhythmEvent.echo => const Color(0xFFCE93D8),
      _ => Colors.white54,
    };
    final remaining = _zoneWallsLeft;
    final total = switch (_currentZone) {
      _RhythmEvent.calm => 5,
      _RhythmEvent.burst => 3,
      _RhythmEvent.zigzag || _RhythmEvent.echo => 4,
      _ => 4,
    };
    final progress = total > 0 ? remaining / total : 0.0;

    // thin bar at very top
    final barPaint = Paint()..color = color.withOpacity(0.7);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x * progress, 3), barPaint);
  }

  void _renderPlayerLine(Canvas canvas) {
    final py = _player.position.y;
    final cx = size.x / 2;
    final laneW = size.x * 0.22;

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, py), Offset(cx - laneW - 8, py), linePaint);
    canvas.drawLine(Offset(cx + laneW + 8, py), Offset(size.x, py), linePaint);
  }

  void _renderHUD(Canvas canvas) {
    const topY = 10.0;
    final diffColor = _difficultyColor(gameState.difficultyLevel);

    // ── Top Right: Difficulty badge ─────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x - 140, topY - 4, 132, 32),
        const Radius.circular(10),
      ),
      Paint()
        ..color = diffColor.withOpacity(0.15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x - 140, topY - 4, 132, 32),
        const Radius.circular(10),
      ),
      Paint()
        ..color = diffColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _drawText(
      canvas,
      gameState.difficultyLevel.name.toUpperCase(),
      Offset(size.x - 74, topY + 8),
      diffColor,
      14,
      textAlign: TextAlign.center,
      bold: true,
    );

    // ── Center: Morph Charge ────────────────────────────────────────
    if (gameState.isMorphCharged) {
      canvas.drawCircle(
        Offset(size.x / 2, topY + 20),
        24,
        Paint()
          ..color = const Color(0xFFFFD700).withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      _drawText(
        canvas,
        '⚡ MORPH CHARGED!',
        Offset(size.x / 2, topY + 12),
        const Color(0xFFFFD700),
        16,
        textAlign: TextAlign.center,
        bold: true,
      );
    } else if (gameState.morphChargeCount > 0) {
      _drawText(
        canvas,
        'x${gameState.morphChargeCount}/3',
        Offset(size.x / 2, topY + 12),
        const Color(0xFFB39DDB),
        13,
        textAlign: TextAlign.center,
        bold: true,
      );
    }

    // ── Zone label (right side, below difficulty) ───────────────────
    final (zoneLabel, zoneColor) = switch (_currentZone) {
      _RhythmEvent.calm => ('💎 CALM', const Color(0xFF80DEEA)),
      _RhythmEvent.rush => ('⚡ RUSH', const Color(0xFFFFD700)),
      _RhythmEvent.burst => ('🌪 BURST', const Color(0xFFFF6B35)),
      _RhythmEvent.zigzag => ('↔ ZIGZAG', const Color(0xFF66FFB2)),
      _RhythmEvent.echo => ('🔁 ECHO', const Color(0xFFCE93D8)),
      _ => ('', Colors.transparent),
    };
    if (zoneLabel.isNotEmpty) {
      canvas.drawCircle(
        Offset(size.x - 74, topY + 50),
        16,
        Paint()
          ..color = zoneColor.withOpacity(0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      _drawText(canvas, zoneLabel, Offset(size.x - 74, topY + 43),
          zoneColor, 12, textAlign: TextAlign.center, bold: true);
    }
  }

  void _renderNextHoleHint(Canvas canvas) {
    if (_walls.isEmpty) return;

    WallComponent? nextWall;
    for (final w in _walls) {
      if (!w.passed && !w.missed) {
        nextWall = w;
        break;
      }
    }
    if (nextWall == null) return;

    if (nextWall.isReverseRule) {
      _drawText(canvas, '⚠️ REVERSE WALL!', const Offset(10, 40),
          const Color(0xFFFFD700), 14, bold: true);
      return;
    }

    // Mini shape preview
    final label = nextWall.isCompositeHole && nextWall.holeCompositeShape != null
        ? ShapeUtils.compositeShapeLabel(nextWall.holeCompositeShape!)
        : nextWall.holeShapeType != null
            ? ShapeUtils.shapeLabel(nextWall.holeShapeType!)
            : '';

    if (label.isNotEmpty) {
      // Tier color hint
      Color hintColor;
      switch (nextWall.tier) {
        case WallTier.bonus:
          hintColor = const Color(0xFF66FFB2);
        case WallTier.danger:
          hintColor = const Color(0xFFFFAA44);
        case WallTier.normal:
          hintColor = Colors.white.withOpacity(0.6);
      }
      _drawText(canvas, '次: $label', const Offset(10, 40), hintColor, 13);
    }
  }

  void _renderAnnouncement(Canvas canvas) {
    final life = _announcementLife.clamp(0.0, 1.5);
    // fade in quickly, hold, then fade out
    double alpha;
    if (life > 1.2) {
      alpha = (1.5 - life) / 0.3; // fade in
    } else if (life > 0.4) {
      alpha = 1.0; // hold
    } else {
      alpha = life / 0.4; // fade out
    }
    alpha = alpha.clamp(0.0, 1.0);

    final scale = 1.0 + (1.0 - alpha) * 0.1;
    final textY = size.y * 0.35;

    // glow bg
    final glowPaint = Paint()
      ..color = _announcementColor.withOpacity(alpha * 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(size.x / 2, textY + 12),
          width: size.x * 0.85,
          height: 44),
      glowPaint,
    );

    canvas.save();
    canvas.translate(size.x / 2, textY);
    canvas.scale(scale, scale);
    canvas.translate(-size.x / 2, -textY);

    _drawText(
      canvas,
      _announcement!,
      Offset(size.x / 2, textY),
      _announcementColor.withOpacity(alpha),
      24,
      textAlign: TextAlign.center,
      bold: true,
    );
    canvas.restore();
  }

  void _renderScoreFloats(Canvas canvas) {
    for (final f in _scoreFloats) {
      final alpha = f.life.clamp(0.0, 1.0);
      _drawText(
        canvas,
        f.text,
        Offset(f.x, f.y),
        f.color.withOpacity(alpha),
        f.fontSize,
        textAlign: TextAlign.center,
        bold: true,
      );
    }
  }

  void _renderGhostPlayer(Canvas canvas) {
    final vm = _vm!;
    final ghostScore = vm.ghostScoreAt(vm.wallsPassed);
    final isAhead = vm.score >= ghostScore;

    final offsetX = 44.0;
    final ghostX = _player.position.x + offsetX;
    final ghostY = _player.position.y;
    final center = Offset(ghostX, ghostY);
    final radius = GameConfig.playerRadius * 0.65;

    final baseOpacity = isAhead ? 0.12 : 0.28;
    final pulseOpacity = baseOpacity + 0.06 * sin(_ghostOrbitAngle * 1.5);

    final glowPaint = Paint()
      ..color = const Color(0xFFB0BEC5).withOpacity(pulseOpacity * 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center, radius * 1.4, glowPaint);

    if (gameState.isCompositeActive && gameState.activeComposite != null) {
      ShapeUtils.drawCompositeShape(
        canvas,
        gameState.activeComposite!,
        center,
        radius,
        const Color(0xFFCFD8DC).withOpacity(pulseOpacity),
      );
    } else {
      ShapeUtils.drawShape(
        canvas,
        gameState.activeShape,
        center,
        radius,
        const Color(0xFFCFD8DC).withOpacity(pulseOpacity),
      );
    }

    for (int i = 0; i < 3; i++) {
      final angle = _ghostOrbitAngle + (2 * pi / 3) * i;
      final px = center.dx + cos(angle) * (radius + 8);
      final py = center.dy + sin(angle) * (radius + 8) * 0.5;
      canvas.drawCircle(
        Offset(px, py),
        2.0,
        Paint()
          ..color = const Color(0xFFB0BEC5).withOpacity(pulseOpacity * 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    _drawText(canvas, '👻', Offset(ghostX, ghostY - radius - 14),
        const Color(0xFFB0BEC5).withOpacity(pulseOpacity * 1.5), 11,
        textAlign: TextAlign.center);
  }

  void _renderGhostBeat(Canvas canvas) {
    final alpha = _ghostBeatLife;
    final yOffset = (1.0 - alpha) * 40;
    final scale = 0.8 + alpha * 0.4;

    final textY = size.y * 0.38 - yOffset;

    final glowPaint = Paint()
      ..color = const Color(0xFF80DEEA).withOpacity(alpha * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(size.x / 2, textY + 10),
          width: size.x * 0.8,
          height: 40),
      glowPaint,
    );

    canvas.save();
    canvas.translate(size.x / 2, textY);
    canvas.scale(scale, scale);
    canvas.translate(-size.x / 2, -textY);

    _drawText(
      canvas,
      '👻 GHOST BEAT!',
      Offset(size.x / 2, textY),
      Color.fromARGB((alpha * 255).round(), 128, 222, 234),
      20,
      textAlign: TextAlign.center,
      bold: true,
    );
    canvas.restore();
  }

  Color _difficultyColor(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return Colors.greenAccent;
      case DifficultyLevel.normal:
        return Colors.lightBlueAccent;
      case DifficultyLevel.hard:
        return Colors.orangeAccent;
      case DifficultyLevel.expert:
        return Colors.redAccent;
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double fontSize, {
    TextAlign textAlign = TextAlign.left,
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w900 : FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
    )..layout();

    double dx;
    if (textAlign == TextAlign.right) {
      dx = offset.dx - tp.width;
    } else if (textAlign == TextAlign.center) {
      dx = offset.dx - tp.width / 2;
    } else {
      dx = offset.dx;
    }
    tp.paint(canvas, Offset(dx, offset.dy));
  }
}

// ── スコアフロートテキスト ────────────────────────────────────────────────
class _ScoreFloat {
  double x;
  double y;
  final String text;
  final Color color;
  final double fontSize;
  double life = 1.0;

  _ScoreFloat({
    required this.x,
    required this.y,
    required this.text,
    required this.color,
    this.fontSize = 16,
  });

  bool get dead => life <= 0;

  void update(double dt) {
    y -= 65 * dt;
    life -= dt * 2.0;
  }
}

// ── プレイヤートレイル ───────────────────────────────────────────────────
class _TrailDot {
  final double x, y;
  double life = 0.35;

  _TrailDot({required this.x, required this.y});

  bool get dead => life <= 0;
  double get opacity => (life / 0.35).clamp(0.0, 1.0);

  void update(double dt) {
    life -= dt;
  }
}

// ── 壁クリアバーストパーティクル ──────────────────────────────────────────
class _BurstParticle {
  double x, y;
  final double vx, vy;
  final Color color;
  final double size;
  double life;

  _BurstParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.life,
  });

  bool get dead => life <= 0;

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    life -= dt * 2.0;
  }
}

class _WallBurst {
  final List<_BurstParticle> particles;
  double life = 0.5;
  static final _rng = Random();

  _WallBurst({
    required double x,
    required double y,
    required Color color,
    int count = 12,
  }) : particles = List.generate(count, (i) {
         final angle = (2 * pi / count) * i + _rng.nextDouble() * 0.5;
         final speed = 80.0 + _rng.nextDouble() * 140;
         return _BurstParticle(
           x: x,
           y: y,
           vx: cos(angle) * speed,
           vy: sin(angle) * speed,
           color: color,
           size: 3.0 + _rng.nextDouble() * 3.0,
           life: 0.4 + _rng.nextDouble() * 0.3,
         );
       });

  bool get dead => particles.every((p) => p.dead);

  void update(double dt) {
    life -= dt;
    for (final p in particles) {
      p.update(dt);
    }
  }
}

// ── コンボマイルストーン ────────────────────────────────────────────────────
class _ComboMilestone {
  final double x;
  final double y;
  final int combo;
  final bool isMax;
  double life = 1.4;

  _ComboMilestone({
    required this.x,
    required this.y,
    required this.combo,
    required this.isMax,
  });

  bool get dead => life <= 0;

  void update(double dt) {
    life -= dt;
  }
}
