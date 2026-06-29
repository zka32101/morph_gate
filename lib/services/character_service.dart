import '../models/character_model.dart';
import 'hive_service.dart';

class CharacterService {
  static const String _selectedKey = 'selectedCharacterId';
  static const String _unlockedKey = 'unlockedCharacterIds';

  static String getSelectedId() =>
      HiveService.getSetting(_selectedKey, 'slime');

  static void select(String id) => HiveService.putSetting(_selectedKey, id);

  static List<String> getUnlocked() {
    final raw = HiveService.getSettingNullable(_unlockedKey);
    final base = <String>['slime'];
    if (raw is List) base.addAll((raw as List).cast<String>());
    return base.toSet().toList();
  }

  static bool isUnlocked(String id) =>
      id == 'slime' || getUnlocked().contains(id);

  static bool unlock(String id) {
    final def = CharacterCatalog.getById(id);
    final coins = HiveService.getOrCreateUser().coins;
    if (coins < def.price) return false;
    HiveService.addCoins(-def.price);
    final current = getUnlocked().toSet()..add(id);
    HiveService.putSetting(_unlockedKey, current.toList());
    return true;
  }

  static CharacterDef getSelected() => CharacterCatalog.getById(getSelectedId());
}
