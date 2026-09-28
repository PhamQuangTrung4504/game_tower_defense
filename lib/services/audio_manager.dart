import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/plant_data.dart';
import '../models/skill_data.dart';
import 'storage_service.dart';

/// Quản lý hệ thống phát nhạc nền (BGM) và hiệu ứng âm thanh (SFX) cho trò chơi.
///
/// Thiết kế an toàn (Fail-safe):
/// Toàn bộ các lệnh phát âm thanh được bọc try-catch cẩn thận để không bao giờ
/// làm gián đoạn gameplay ngay cả khi file âm thanh chưa được nạp hoặc không tồn tại.
class AudioManager {
  AudioManager._internal();

  static final AudioManager _instance = AudioManager._internal();

  /// Singleton instance
  static AudioManager get instance => _instance;

  factory AudioManager() => _instance;

  bool bgmEnabled = true;
  bool sfxEnabled = true;

  bool _isBgmPlaying = false;
  bool get isBgmPlaying => _isBgmPlaying;

  /// Kiểm tra xem ServicesBinding đã sẵn sàng để phát audio hay chưa
  bool get _canPlayAudio {
    try {
      ServicesBinding.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Khởi tạo và đồng bộ cài đặt từ StorageService
  Future<void> init() async {
    try {
      final storage = StorageService.instance;
      bgmEnabled = storage.loadBgmEnabled();
      sfxEnabled = storage.loadSfxEnabled();
    } catch (e) {
      debugPrint('AudioManager.init error: $e');
    }
  }

  /// Bật / Tắt nhạc nền BGM
  Future<void> setBgmEnabled(bool enabled) async {
    bgmEnabled = enabled;
    await StorageService.instance.saveBgmEnabled(enabled);

    if (!enabled) {
      await stopBgm();
    } else {
      await playBattleBgm();
    }
  }

  /// Bật / Tắt hiệu ứng âm thanh SFX
  Future<void> setSfxEnabled(bool enabled) async {
    sfxEnabled = enabled;
    await StorageService.instance.saveSfxEnabled(enabled);
  }

  /// Phát nhạc nền trận đấu (Battle BGM)
  Future<void> playBattleBgm() async {
    if (!bgmEnabled || !_canPlayAudio) return;
    try {
      if (!_isBgmPlaying) {
        await FlameAudio.bgm.play('battle_bgm.mp3', volume: 0.4);
        _isBgmPlaying = true;
      }
    } catch (_) {
      // Bỏ qua nếu chưa có file asset battle_bgm.mp3
    }
  }

  /// Dừng phát nhạc nền
  Future<void> stopBgm() async {
    if (!_canPlayAudio) {
      _isBgmPlaying = false;
      return;
    }
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {}
    _isBgmPlaying = false;
  }

  /// Phát âm thanh khi trụ bắn đạn
  Future<void> playShootSfx(PlantType type) async {
    if (!sfxEnabled || !_canPlayAudio) return;
    try {
      final sfxFile = switch (type) {
        PlantType.peashooter => 'shoot_pea.wav',
        PlantType.firePeashooter => 'shoot_fire.wav',
        PlantType.iceShroom => 'shoot_ice.wav',
        PlantType.electricShroom => 'shoot_electric.wav',
        PlantType.melonPult => 'shoot_melon.wav',
        _ => 'shoot_default.wav',
      };
      await FlameAudio.play(sfxFile, volume: 0.5);
    } catch (_) {}
  }

  /// Phát âm thanh khi đạn trúng quái vật (Hit Impact)
  Future<void> playHitSfx() async {
    if (!sfxEnabled || !_canPlayAudio) return;
    try {
      await FlameAudio.play('hit.wav', volume: 0.4);
    } catch (_) {}
  }

  /// Phát âm thanh khi quái vật bị tiêu diệt
  Future<void> playEnemyDeathSfx() async {
    if (!sfxEnabled || !_canPlayAudio) return;
    try {
      await FlameAudio.play('enemy_death.wav', volume: 0.5);
    } catch (_) {}
  }

  /// Phát âm thanh khi thu hoạch hoặc nhận vàng rơi (Gold Coin)
  Future<void> playCoinSfx() async {
    if (!sfxEnabled || !_canPlayAudio) return;
    try {
      await FlameAudio.play('coin.wav', volume: 0.6);
    } catch (_) {}
  }

  /// Phát âm thanh khi kích hoạt kỹ năng chủ động (Skills)
  Future<void> playSkillSfx(SkillType type) async {
    if (!sfxEnabled || !_canPlayAudio) return;
    try {
      final sfxFile = switch (type) {
        SkillType.goldenStorm => 'skill_golden_storm.wav',
        SkillType.tornado => 'skill_tornado.wav',
        SkillType.magicBind => 'skill_magic_bind.wav',
        SkillType.meteorite => 'skill_meteorite.wav',
      };
      await FlameAudio.play(sfxFile, volume: 0.7);
    } catch (_) {}
  }

  /// Phát âm thanh chiến thắng màn chơi (Victory)
  Future<void> playVictorySfx() async {
    if (!sfxEnabled || !_canPlayAudio) return;
    try {
      await FlameAudio.play('victory.wav', volume: 0.8);
    } catch (_) {}
  }

  /// Phát âm thanh thất bại (Defeat)
  Future<void> playDefeatSfx() async {
    if (!sfxEnabled || !_canPlayAudio) return;
    try {
      await FlameAudio.play('defeat.wav', volume: 0.8);
    } catch (_) {}
  }
}
