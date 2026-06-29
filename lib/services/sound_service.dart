import 'package:flame_audio/flame_audio.dart';
import 'hive_service.dart';

class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  bool _initialized = false;
  bool _bgmPlaying = false;

  static Future<void> init() async {
    try {
      await FlameAudio.audioCache.loadAll([
        'se_pass.wav',
        'se_miss.wav',
        'se_combo.wav',
        'se_evolution.wav',
        'se_button.wav',
      ]);
      SoundService()._initialized = true;
    } catch (_) {
      // Audio init failure is non-fatal
    }
  }

  bool get _enabled => _initialized && HiveService.isSoundEnabled();

  void playPass() {
    if (_enabled) FlameAudio.play('se_pass.wav', volume: 0.7);
  }

  void playMiss() {
    if (_enabled) FlameAudio.play('se_miss.wav', volume: 0.8);
  }

  void playCombo() {
    if (_enabled) FlameAudio.play('se_combo.wav', volume: 0.6);
  }

  void playEvolution() {
    if (_enabled) FlameAudio.play('se_evolution.wav', volume: 0.9);
  }

  void playButton() {
    if (_enabled) FlameAudio.play('se_button.wav', volume: 0.5);
  }

  Future<void> startBgm() async {
    if (!_enabled || _bgmPlaying) return;
    try {
      await FlameAudio.bgm.play('bgm_game.wav', volume: 0.25);
      _bgmPlaying = true;
    } catch (_) {}
  }

  void stopBgm() {
    if (_bgmPlaying) {
      FlameAudio.bgm.stop();
      _bgmPlaying = false;
    }
  }

  void onSettingsChanged(bool enabled) {
    if (!enabled) stopBgm();
  }
}
