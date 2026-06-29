import 'package:flutter/material.dart';
import '../services/hive_service.dart';
import '../services/sound_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _soundEnabled;

  @override
  void initState() {
    super.initState();
    _soundEnabled = HiveService.isSoundEnabled();
  }

  @override
  Widget build(BuildContext context) {
    final user = HiveService.getOrCreateUser();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.text,
        title: const Text('設定', style: TextStyle(color: AppColors.text)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'プロフィール',
            children: [
              _InfoTile(label: 'プレイヤー名', value: user.nickname),
              _InfoTile(label: 'ID', value: user.id.substring(0, 8)),
              _InfoTile(label: 'ハイスコア', value: '${user.totalHighScore}'),
              _InfoTile(label: '総通過壁数', value: '${user.totalWallsPassed}'),
              _InfoTile(label: '所持コイン', value: '${user.coins}'),
              _InfoTile(
                label: 'ジェリー進化',
                value: EvolutionConfig.names[user.jellifyLevel],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'サウンド',
            children: [
              SwitchListTile(
                title: const Text('サウンド', style: TextStyle(color: AppColors.text)),
                value: _soundEnabled,
                activeColor: AppColors.primary,
                onChanged: (v) {
                  setState(() => _soundEnabled = v);
                  HiveService.setSoundEnabled(v);
                  SoundService().onSettingsChanged(v);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'アプリ情報',
            children: [
              const _InfoTile(label: 'バージョン', value: '1.0.0'),
              const _InfoTile(label: 'エンジン', value: 'Flutter + Flame'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
