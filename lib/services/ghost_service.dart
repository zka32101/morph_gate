import 'package:hive_flutter/hive_flutter.dart';

/// ゴーストレース — 前回のベストランのスコアタイムラインを記録・再生する
///
/// 記録単位: 壁を通過するたびにスコアを記録
/// 保存形式: List<int> [wall0_score, wall1_score, wall2_score, ...]
class GhostService {
  static const _boxKey = 'ghost_timeline';
  static late Box<dynamic> _box;

  static Future<void> init() async {
    _box = await Hive.openBox('ghost_data');
  }

  // ── 保存 ──────────────────────────────────────────────────────────────

  /// 今回のランを保存（ハイスコア更新時のみ）
  static void saveBestRun(List<int> scoreTimeline, int finalScore) {
    final saved = getBestRunFinalScore();
    if (finalScore > saved) {
      _box.put(_boxKey, scoreTimeline);
      _box.put('ghost_final_score', finalScore);
    }
  }

  // ── 取得 ──────────────────────────────────────────────────────────────

  /// ベストランのスコアタイムラインを取得（なければ空）
  static List<int> getBestTimeline() {
    final raw = _box.get(_boxKey);
    if (raw == null) return [];
    return List<int>.from(raw as List);
  }

  /// ベストランの最終スコアを取得
  static int getBestRunFinalScore() =>
      _box.get('ghost_final_score', defaultValue: 0) as int;

  /// 指定壁番号のゴーストスコアを取得（範囲外なら最終スコア）
  static int ghostScoreAt(List<int> timeline, int wallIndex) {
    if (timeline.isEmpty) return 0;
    if (wallIndex >= timeline.length) return timeline.last;
    return timeline[wallIndex];
  }
}

/// ゲーム中のゴーストランレコーダー
class GhostRecorder {
  final List<int> _timeline = [];

  void recordWall(int currentScore) {
    _timeline.add(currentScore);
  }

  List<int> get timeline => List.unmodifiable(_timeline);

  void save(int finalScore) {
    GhostService.saveBestRun(_timeline, finalScore);
  }

  void reset() => _timeline.clear();
}
