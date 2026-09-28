import 'package:flutter_test/flutter_test.dart';
import 'package:game_tower_defense/models/plant_data.dart';
import 'package:game_tower_defense/models/skill_data.dart';
import 'package:game_tower_defense/services/audio_manager.dart';
import 'package:game_tower_defense/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.instance.init();
    });

    test('Default values on first launch', () {
      final storage = StorageService.instance;
      expect(storage.loadHighestUnlockedLevel(), equals(1));
      expect(storage.loadBgmEnabled(), isTrue);
      expect(storage.loadSfxEnabled(), isTrue);
    });

    test('Save and load highest unlocked level', () async {
      final storage = StorageService.instance;

      await storage.saveHighestUnlockedLevel(3);
      expect(storage.loadHighestUnlockedLevel(), equals(3));

      // Không cho phép ghi đè màn thấp hơn màn đã mở
      await storage.saveHighestUnlockedLevel(2);
      expect(storage.loadHighestUnlockedLevel(), equals(3));

      // Clamped tối đa 8 màn
      await storage.saveHighestUnlockedLevel(10);
      expect(storage.loadHighestUnlockedLevel(), equals(8));
    });

    test('Reset all progress to level 1', () async {
      final storage = StorageService.instance;

      await storage.saveHighestUnlockedLevel(5);
      expect(storage.loadHighestUnlockedLevel(), equals(5));

      await storage.resetAllProgress();
      expect(storage.loadHighestUnlockedLevel(), equals(1));
    });

    test('Save and load BGM and SFX settings', () async {
      final storage = StorageService.instance;

      await storage.saveBgmEnabled(false);
      expect(storage.loadBgmEnabled(), isFalse);

      await storage.saveSfxEnabled(false);
      expect(storage.loadSfxEnabled(), isFalse);

      await storage.saveBgmEnabled(true);
      expect(storage.loadBgmEnabled(), isTrue);
    });
  });

  group('AudioManager Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'bgm_enabled': true,
        'sfx_enabled': true,
      });
      await StorageService.instance.init();
      await AudioManager.instance.init();
    });

    test('Initial flags match storage settings', () {
      final audio = AudioManager.instance;
      expect(audio.bgmEnabled, isTrue);
      expect(audio.sfxEnabled, isTrue);
    });

    test('Toggling BGM and SFX persists to StorageService', () async {
      final audio = AudioManager.instance;
      final storage = StorageService.instance;

      await audio.setBgmEnabled(false);
      expect(audio.bgmEnabled, isFalse);
      expect(storage.loadBgmEnabled(), isFalse);

      await audio.setSfxEnabled(false);
      expect(audio.sfxEnabled, isFalse);
      expect(storage.loadSfxEnabled(), isFalse);

      await audio.setBgmEnabled(true);
      expect(audio.bgmEnabled, isTrue);
      expect(storage.loadBgmEnabled(), isTrue);
    });

    test('SFX playback functions run safely without throwing exception', () async {
      final audio = AudioManager.instance;

      // Kích hoạt toàn bộ hàm SFX khi bật SFX
      await audio.setSfxEnabled(true);
      for (final type in PlantType.values) {
        expect(() async => await audio.playShootSfx(type), returnsNormally);
      }
      expect(() async => await audio.playHitSfx(), returnsNormally);
      expect(() async => await audio.playEnemyDeathSfx(), returnsNormally);
      expect(() async => await audio.playCoinSfx(), returnsNormally);

      for (final skill in SkillType.values) {
        expect(() async => await audio.playSkillSfx(skill), returnsNormally);
      }
      expect(() async => await audio.playVictorySfx(), returnsNormally);
      expect(() async => await audio.playDefeatSfx(), returnsNormally);

      // Kích hoạt toàn bộ hàm SFX khi tắt SFX
      await audio.setSfxEnabled(false);
      expect(() async => await audio.playShootSfx(PlantType.peashooter), returnsNormally);
      expect(() async => await audio.playHitSfx(), returnsNormally);
      expect(() async => await audio.playEnemyDeathSfx(), returnsNormally);
      expect(() async => await audio.playCoinSfx(), returnsNormally);
      expect(() async => await audio.playSkillSfx(SkillType.meteorite), returnsNormally);
      expect(() async => await audio.playVictorySfx(), returnsNormally);
      expect(() async => await audio.playDefeatSfx(), returnsNormally);
    });

    test('BGM playback functions run safely without throwing exception', () async {
      final audio = AudioManager.instance;

      await audio.setBgmEnabled(true);
      expect(() async => await audio.playBattleBgm(), returnsNormally);
      expect(() async => await audio.stopBgm(), returnsNormally);

      await audio.setBgmEnabled(false);
      expect(() async => await audio.playBattleBgm(), returnsNormally);
      expect(() async => await audio.stopBgm(), returnsNormally);
    });
  });
}
