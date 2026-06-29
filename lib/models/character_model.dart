import 'package:flutter/material.dart';

class CharacterDef {
  final String id;
  final String name;
  final String description;
  final int price;
  final Color baseColor;
  final Color glowColor;
  final String emoji;
  final String? assetImage; // Leonardo AI generated image path

  const CharacterDef({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.baseColor,
    required this.glowColor,
    required this.emoji,
    this.assetImage,
  });
}

class CharacterCatalog {
  static const List<CharacterDef> all = [
    CharacterDef(
      id: 'slime',
      name: 'スライム',
      description: '最初からの仲間',
      price: 0,
      baseColor: Color(0xFF5DADE2),
      glowColor: Color(0xFF3498DB),
      emoji: '💧',
      assetImage: 'assets/images/jelly_variants/jelly_steel_blue.jpg',
    ),
    CharacterDef(
      id: 'fire',
      name: 'ファイアジェリー',
      description: '炎をまとったジェリー',
      price: 100,
      baseColor: Color(0xFFFF6B35),
      glowColor: Color(0xFFFF4500),
      emoji: '🔥',
      assetImage: 'assets/images/jelly_variants/jelly_ruby_red.jpg',
    ),
    CharacterDef(
      id: 'ice',
      name: 'アイスジェリー',
      description: '氷のように澄みわたる',
      price: 150,
      baseColor: Color(0xFF81D4FA),
      glowColor: Color(0xFF00BCD4),
      emoji: '❄️',
      assetImage: 'assets/images/jelly_variants/jelly_emerald_green.jpg',
    ),
    CharacterDef(
      id: 'shadow',
      name: 'シャドウジェリー',
      description: '闇から生まれた影の存在',
      price: 200,
      baseColor: Color(0xFF7B1FA2),
      glowColor: Color(0xFF4A148C),
      emoji: '🌑',
      assetImage: 'assets/images/jelly_variants/jelly_royal_purple.jpg',
    ),
    CharacterDef(
      id: 'toxic',
      name: 'トキシックジェリー',
      description: '毒々しくも美しい輝き',
      price: 250,
      baseColor: Color(0xFF76FF03),
      glowColor: Color(0xFF64DD17),
      emoji: '☣️',
    ),
    CharacterDef(
      id: 'gold',
      name: 'ゴールデンジェリー',
      description: '黄金に輝く伝説の体',
      price: 300,
      baseColor: Color(0xFFFFD700),
      glowColor: Color(0xFFFFC107),
      emoji: '✨',
    ),
    CharacterDef(
      id: 'thunder',
      name: 'サンダージェリー',
      description: '稲妻のスピードで駆ける',
      price: 350,
      baseColor: Color(0xFFFFF176),
      glowColor: Color(0xFFFFEB3B),
      emoji: '⚡',
    ),
    CharacterDef(
      id: 'crystal',
      name: 'クリスタルジェリー',
      description: '光を七色に分散する結晶体',
      price: 450,
      baseColor: Color(0xFFE1F5FE),
      glowColor: Color(0xFFB3E5FC),
      emoji: '💎',
    ),
    CharacterDef(
      id: 'cosmic',
      name: 'コズミックジェリー',
      description: '宇宙の深淵を泳ぐ存在',
      price: 500,
      baseColor: Color(0xFF3F51B5),
      glowColor: Color(0xFF1A237E),
      emoji: '🌌',
    ),
    CharacterDef(
      id: 'void',
      name: 'ヴォイドジェリー',
      description: '虚空に生きる究極の存在',
      price: 800,
      baseColor: Color(0xFFB71C1C),
      glowColor: Color(0xFF37474F),
      emoji: '🕳️',
    ),
  ];

  static CharacterDef getById(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.first);
}
