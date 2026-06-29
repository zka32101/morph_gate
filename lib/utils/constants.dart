import 'package:flutter/material.dart';

enum WallTier { normal, bonus, danger }

enum DifficultyLevel { easy, normal, hard, expert }

class AppColors {
  static const background = Color(0xFF1A0A2E);
  static const surface = Color(0xFF2D1B4E);
  static const primary = Color(0xFF9B59B6);
  static const accent = Color(0xFFE74C3C);
  static const gold = Color(0xFFFFD700);
  static const text = Color(0xFFF0E6FF);
  static const textSecondary = Color(0xFFB39DDB);

  static const shapeSquare = Color(0xFF3498DB);
  static const shapeCircle = Color(0xFF2ECC71);
  static const shapeStar = Color(0xFFFFD700);
  static const shapeTriangle = Color(0xFFE74C3C);

  static const jellySteelBlue = Color(0xFF5DADE2);
  static const jellyGreen = Color(0xFF58D68D);
  static const jellyCrystal = Color(0xFFAB47BC);
  static const jellyGhost = Color(0xFFB0BEC5);
  static const jellyPrimordial = Color(0xFFFF6F00);
}

class GameConfig {
  // Wall speeds by stage
  static const double speedEasy = 150.0;
  static const double speedNormal = 220.0;
  static const double speedHard = 300.0;
  static const double speedExpert = 380.0;

  // Hole size ratios
  static const double holeSizeEasy = 1.6;
  static const double holeSizeNormal = 1.3;
  static const double holeSizeHard = 1.1;
  static const double holeSizeExpert = 1.0;

  // Stage thresholds
  static const int stageNormalStart = 11;
  static const int stageHardStart = 31;
  static const int stageExpertStart = 51;

  // Combo multiplier
  static const double comboMin = 1.0;
  static const double comboMax = 3.0;
  static const double comboStep = 0.2;

  // Shape transform duration
  static const double shapeDurationSingle = 0.15;
  static const double shapeDurationComposite = 0.2;

  // Composite shape simultaneous press window (ms)
  static const int compositePressWindowMs = 100;

  // Collision tolerance
  static const double collisionTolerance = 0.10;

  // Player size
  static const double playerRadius = 30.0;

  // Wall dimensions
  static const double wallThickness = 60.0;
}

class ScoreConfig {
  static const int baseScore = 100;
  static const int accuracyBonusMax = 50;
  static const int compositeBonusFlatScore = 50;
  static const double evolutionBonusPerLevel = 0.1;
}

class EvolutionConfig {
  static const List<int> thresholds = [0, 101, 501, 2001, 5001];
  static const List<String> names = [
    'Slime',
    'Big Slime',
    'Crystal Jelly',
    'Ghost Jelly',
    'Primordial Jelly',
  ];
}

class HiveBoxes {
  static const String userBox = 'user';
  static const String settingsBox = 'settings';
}
