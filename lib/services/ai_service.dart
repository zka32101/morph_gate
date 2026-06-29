import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class DifficultyAdjustment {
  final DifficultyLevel level;
  final double speedMultiplier;
  final double holeSizeMultiplier;
  final String reason;

  const DifficultyAdjustment({
    required this.level,
    this.speedMultiplier = 1.0,
    this.holeSizeMultiplier = 1.0,
    this.reason = '',
  });
}

class AIService {
  static final String _claudeApiKey =
      dotenv.env['CLAUDE_API_KEY'] ?? '';
  static const String _claudeEndpoint =
      'https://api.anthropic.com/v1/messages';
  static const String _claudeModel = 'claude-haiku-4-5-20251001';

  static const String _systemPrompt =
      'あなたはモバイルゲームの難度調整AIです。プレイヤーデータを分析し、最適な難度を推奨します。JSON形式で回答してください。';

  static Future<DifficultyAdjustment> analyzeDifficulty({
    required int clearRate,
    required int maxCombo,
    required int totalGamesPlayed,
    required DifficultyLevel currentLevel,
  }) async {
    if (_claudeApiKey.isEmpty || _claudeApiKey == 'your_claude_api_key_here') {
      return _fallbackDifficulty(clearRate, currentLevel);
    }

    try {
      final prompt = '''
プレイヤーのゲームデータ分析：
- クリア率: $clearRate%
- 最大コンボ: $maxCombo
- 総プレイ数: $totalGamesPlayed
- 現在難度: ${currentLevel.name}

次の難度を推奨してください。
以下のJSON形式のみで回答:
{"level":"Easy|Normal|Hard|Expert","speedMult":1.0,"holeMult":1.0,"reason":"理由"}
''';

      final response = await http
          .post(
            Uri.parse(_claudeEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': _claudeApiKey,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': _claudeModel,
              'max_tokens': 150,
              'system': _systemPrompt,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['content'][0]['text'] as String;
        return _parseDifficultyResponse(text);
      }
    } catch (_) {}

    return _fallbackDifficulty(clearRate, currentLevel);
  }

  static Future<String> generateEvolutionStory(
      String currentLevel, String nextLevel) async {
    if (_claudeApiKey.isEmpty || _claudeApiKey == 'your_claude_api_key_here') {
      return '$currentLevelから$nextLevelへ進化！新たな力が解放された！';
    }

    try {
      final response = await http
          .post(
            Uri.parse(_claudeEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': _claudeApiKey,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': _claudeModel,
              'max_tokens': 60,
              'messages': [
                {
                  'role': 'user',
                  'content':
                      'ジェリーキャラが$currentLevelから$nextLevelに進化する物語を30字以内で生成。ファンタジー世界のトーンで。',
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['content'][0]['text'] as String).trim();
      }
    } catch (_) {}

    return '$currentLevelから$nextLevelへ！伝説の進化が始まる！';
  }

  static DifficultyAdjustment _fallbackDifficulty(
      int clearRate, DifficultyLevel current) {
    if (clearRate < 40) {
      final idx = current.index > 0 ? current.index - 1 : 0;
      return DifficultyAdjustment(
        level: DifficultyLevel.values[idx],
        speedMultiplier: 0.9,
        holeSizeMultiplier: 1.05,
        reason: 'クリア率が低いため難度を下げます',
      );
    } else if (clearRate > 80) {
      final idx = current.index < 3 ? current.index + 1 : 3;
      return DifficultyAdjustment(
        level: DifficultyLevel.values[idx],
        speedMultiplier: 1.05,
        holeSizeMultiplier: 0.95,
        reason: 'クリア率が高いため難度を上げます',
      );
    }
    return DifficultyAdjustment(level: current, reason: '現在の難度を維持します');
  }

  static DifficultyAdjustment _parseDifficultyResponse(String text) {
    try {
      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}') + 1;
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final json = jsonDecode(text.substring(jsonStart, jsonEnd));
        final levelStr = (json['level'] as String).toLowerCase();
        final level = DifficultyLevel.values.firstWhere(
          (e) => e.name.toLowerCase() == levelStr,
          orElse: () => DifficultyLevel.normal,
        );
        return DifficultyAdjustment(
          level: level,
          speedMultiplier: (json['speedMult'] as num?)?.toDouble() ?? 1.0,
          holeSizeMultiplier: (json['holeMult'] as num?)?.toDouble() ?? 1.0,
          reason: json['reason'] as String? ?? '',
        );
      }
    } catch (_) {}
    return const DifficultyAdjustment(level: DifficultyLevel.normal);
  }
}
