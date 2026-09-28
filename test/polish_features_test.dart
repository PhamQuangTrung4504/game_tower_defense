import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tower_defense/game/components/enemy_component.dart';
import 'package:game_tower_defense/game/components/floating_text_component.dart';
import 'package:game_tower_defense/game/components/wave_spawner_component.dart';
import 'package:game_tower_defense/game/tower_defense_game.dart';
import 'package:game_tower_defense/models/enemy_type.dart';
import 'package:game_tower_defense/models/map_data.dart';
import 'package:game_tower_defense/models/skill_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Kiểm thử FloatingTextComponent (Chữ bay sát thương & tiền vàng)', () {
    test('Khởi tạo chữ sát thương thường và DoT đúng thông số', () {
      final normalDamage = FloatingTextComponent.damage(
        position: Vector2(100, 100),
        damage: 25,
        isDot: false,
      );
      expect(normalDamage.text, '-25');
      expect(normalDamage.duration, 0.6);
      expect(normalDamage.opacity, 1.0);
      expect(normalDamage.position.y, 100.0);

      final dotDamage = FloatingTextComponent.damage(
        position: Vector2(100, 100),
        damage: 8,
        isDot: true,
      );
      expect(dotDamage.text, '-8');
      expect(dotDamage.duration, 0.5);
    });

    test('Khởi tạo chữ tiền vàng đúng định dạng và màu vàng óng', () {
      final goldText = FloatingTextComponent.gold(
        position: Vector2(120, 150),
        gold: 15,
      );
      expect(goldText.text, '+15 G');
      expect(goldText.duration, 0.7);
      expect(goldText.riseDistance, 22.0);
    });

    test('Hoạt ảnh bay lên và mờ dần (Tween & Fade Out) theo thời gian', () {
      final textComp = FloatingTextComponent.damage(
        position: Vector2(100, 100),
        damage: 30,
      );

      // Cập nhật nửa thời gian (0.3s / 0.6s)
      textComp.update(0.3);
      expect(textComp.elapsed, closeTo(0.3, 0.001));
      expect(textComp.opacity, closeTo(0.5, 0.05));
      expect(textComp.position.y, closeTo(90.0, 1.0)); // Bay lên ~10px

      // Cập nhật thêm 0.3s (đủ 0.6s) -> Hết thời gian sống
      textComp.update(0.35);
      expect(textComp.elapsed, greaterThanOrEqualTo(0.6));
    });
  });

  group('Kiểm thử Hiệu Ứng Va Chạm & Hit Flash của Quái', () {
    test('Khi quái nhận sát thương, hitFlashTimer được kích hoạt 0.08s', () {
      final slime = EnemyComponent(
        data: MonsterData.fromType(EnemyType.greenSlime),
        waypoints: [Vector2(0, 0), Vector2(200, 0)],
      );

      expect(slime.hitFlashTimer, 0.0);

      // Nhận 20 sát thương
      slime.takeDamage(20.0);
      expect(slime.hitFlashTimer, equals(0.08));

      // Trôi qua 0.04s -> còn 0.04s
      slime.update(0.04);
      expect(slime.hitFlashTimer, closeTo(0.04, 0.001));

      // Trôi qua thêm 0.05s -> kết thúc chớp trắng
      slime.update(0.05);
      expect(slime.hitFlashTimer, equals(0.0));
    });
  });

  group('Kiểm thử Điều Khiển Tốc Độ Game (Game Speed) & Tạm Dừng (Pause)', () {
    late TowerDefenseGame game;

    setUp(() {
      game = TowerDefenseGame();
      game.mapData = MapData.level1();
      game.waveSpawner = WaveSpawnerComponent(waypoints: game.mapData.getWaypointPixelCenters());
    });

    test('Tốc độ mặc định 1.0x và toggle chuyển đổi giữa 1.0x và 2.0x', () {
      expect(game.gameSpeed, 1.0);
      expect(game.gameSpeedNotifier.value, 1.0);

      // Tăng lên 2x
      game.toggleSpeed();
      expect(game.gameSpeed, 2.0);
      expect(game.gameSpeedNotifier.value, 2.0);

      // Quay lại 1x
      game.toggleSpeed();
      expect(game.gameSpeed, 1.0);
      expect(game.gameSpeedNotifier.value, 1.0);
    });

    test('Ở tốc độ 2.0x, Mana hồi phục nhanh gấp đôi', () {
      game.mana = 50.0;
      game.manaNotifier.value = 50.0;
      game.gameSpeed = 2.0;

      // Update 2.0s ở tốc độ 2x -> thời gian thực tế = 2.0 * 2.0 = 4.0s
      // Mana hồi = 50 + 2.5 * 4.0 = 60.0 MP
      game.update(2.0);
      expect(game.mana, closeTo(60.0, 0.01));
    });

    test('Khi Pause (Tạm Dừng), game đóng băng không cập nhật tài nguyên', () {
      game.mana = 60.0;
      game.manaNotifier.value = 60.0;

      // Kích hoạt pause
      game.pause();
      expect(game.isPaused, isTrue);
      expect(game.isPausedNotifier.value, isTrue);

      // Cập nhật 10.0 giây trong trạng thái Pause
      game.update(10.0);
      expect(game.mana, equals(60.0)); // Mana không hồi

      // Resume lại game
      game.resume();
      expect(game.isPaused, isFalse);
      expect(game.isPausedNotifier.value, isFalse);

      // Cập nhật 2.0 giây sau khi Resume -> Mana hồi bình thường
      game.update(2.0);
      expect(game.mana, closeTo(65.0, 0.01));
    });

    test('Kỹ năng hồi chiêu gấp đôi khi bật tốc độ 2x', () {
      final skill = game.skills[SkillType.goldenStorm]!;
      skill.startCooldown(); // 30s hồi chiêu
      expect(skill.currentCooldown, 30.0);

      game.gameSpeed = 2.0;
      // Cập nhật 5s ở tốc độ 2x -> giảm 10s cooldown
      game.update(5.0);
      expect(skill.currentCooldown, closeTo(20.0, 0.01));
    });

    test('Camera Shake rung màn hình và tự khôi phục vị trí (0, 0) sau thời gian rung', () {
      expect(game.camera.viewfinder.position, Vector2.zero());

      // Kích hoạt rung lắc 0.25s
      game.triggerCameraShake(duration: 0.25, intensity: 4.0);

      // Cập nhật 0.1s -> camera bị lệch khỏi (0, 0)
      game.update(0.1);
      // Tọa độ lệch x hoặc y khác 0
      final offset = game.camera.viewfinder.position;
      expect(offset == Vector2.zero(), isFalse);

      // Cập nhật tiếp 0.2s (tổng 0.3s > 0.25s) -> kết thúc rung, camera về (0, 0)
      game.update(0.2);
      expect(game.camera.viewfinder.position, Vector2.zero());
    });
  });
}
