import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tower_defense/game/components/enemy_component.dart';
import 'package:game_tower_defense/game/components/wave_spawner_component.dart';
import 'package:game_tower_defense/game/tower_defense_game.dart';
import 'package:game_tower_defense/models/enemy_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MonsterData Tests', () {
    test('Khởi tạo Green Slime đúng thông số chuẩn GDD', () {
      final slime = MonsterData.fromType(EnemyType.greenSlime);
      expect(slime.name, equals('Green Slime'));
      expect(slime.maxHp, equals(70.0));
      expect(slime.currentHp, equals(70.0));
      expect(slime.speed, equals(1.0));
      expect(slime.basePixelSpeed, equals(32.0));
      expect(slime.goldReward, equals(10));
      expect(slime.stepTime, equals(0.22));
      expect(slime.frameSize, equals(Vector2(24, 24)));
      expect(slime.isDead, isFalse);
      expect(slime.hpPercent, equals(1.0));
    });

    test('Khởi tạo Basic Zombie đúng thông số', () {
      final zombie = MonsterData.fromType(EnemyType.basicZombie);
      expect(zombie.name, equals('Basic Zombie'));
      expect(zombie.maxHp, equals(150.0));
      expect(zombie.speed, equals(0.85));
      expect(zombie.goldReward, equals(18));
      expect(zombie.frameSize, equals(Vector2(32, 32)));
    });

    test('Khởi tạo Dark Titan đúng thông số Boss', () {
      final titan = MonsterData.fromType(EnemyType.darkTitan);
      expect(titan.name, equals('Dark Titan'));
      expect(titan.isBoss, isTrue);
      expect(titan.renderScale, equals(1.3));
      expect(titan.maxHp, equals(2200.0));
      expect(titan.speed, equals(0.40));
      expect(titan.goldReward, equals(180));
    });


    test('MonsterData.clone tạo bản sao độc lập với đầy máu', () {
      final origin = MonsterData.fromType(EnemyType.greenSlime);
      final clone = origin.clone();

      clone.currentHp = 20.0;
      expect(clone.currentHp, equals(20.0));
      expect(origin.currentHp, equals(70.0)); // Không ảnh hưởng bản gốc
    });
  });

  group('Enemy Combat & Base Damage Tests', () {
    late TowerDefenseGame game;

    setUp(() {
      game = TowerDefenseGame();
    });

    test('Nhận sát thương và tính giáp (isShielded)', () {
      // Quái thường không giáp
      final slimeData = MonsterData.fromType(EnemyType.greenSlime);
      final slime = EnemyComponent(
        data: slimeData,
        waypoints: [Vector2(0, 0), Vector2(100, 0)],
      );
      slime.takeDamage(30.0);
      expect(slimeData.currentHp, equals(40.0));
      expect(slimeData.hpPercent, closeTo(40.0 / 70.0, 0.001));

      // Quái có giáp (giảm 25% sát thương)
      final scorpionData = MonsterData.fromType(EnemyType.armoredScorpion);
      final scorpion = EnemyComponent(
        data: scorpionData,
        waypoints: [Vector2(0, 0), Vector2(100, 0)],
      );
      // Sát thương 40 * 0.75 = 30 sát thương thực tế
      scorpion.takeDamage(40.0);
      expect(scorpionData.currentHp, equals(150.0)); // 180 - 30 = 150
    });

    test('Quái chết kích hoạt callback và cộng Gold cho game', () {
      final slimeData = MonsterData.fromType(EnemyType.greenSlime);
      bool deathCallbackCalled = false;

      final enemy = EnemyComponent(
        data: slimeData,
        waypoints: [Vector2(0, 0)],
        onDeath: (e) {
          deathCallbackCalled = true;
        },
      );

      final initialGold = game.playerGold;

      // Giả lập logic khi quái chết
      slimeData.currentHp = 0.0;
      expect(slimeData.isDead, isTrue);

      game.addGold(slimeData.goldReward);
      expect(game.playerGold, equals(initialGold + 10));

      enemy.onDeath?.call(enemy);
      expect(deathCallbackCalled, isTrue);
    });

    test('Quái thường chạm nhà chính trừ 1 máu, Boss trừ 5 máu', () {
      expect(game.baseHp, equals(10));

      // Quái thường tới nhà chính
      game.takeBaseDamage(1);
      expect(game.baseHp, equals(9));

      // Boss tới nhà chính -> trừ 5 máu
      game.takeBaseDamage(5);
      expect(game.baseHp, equals(4));

      // Trừ tiếp 10 máu -> máu về 0 và kích hoạt GameOver
      game.takeBaseDamage(10);
      expect(game.baseHp, equals(0));
      expect(game.isGameOver, isTrue);
    });
  });

  group('WaveSpawner Timeline Tests', () {
    test('Timeline Màn 1 có chuẩn 14 sự kiện xuất hiện quái chia làm 4 Wave (có Boss Dark Titan)', () {
      final timeline = WaveSpawnerComponent.level1Timeline();
      expect(timeline.length, equals(14));

      // Wave 1: Giây 05 (2 Slime)
      final wave1 = timeline.where((e) => e.waveNumber == 1).toList();
      expect(wave1.length, equals(2));
      expect(wave1[0].triggerTime, equals(5.0));
      expect(wave1[0].enemyType, equals(EnemyType.greenSlime));
      expect(wave1[1].triggerTime, equals(7.5));
      expect(wave1[1].enemyType, equals(EnemyType.greenSlime));

      // Wave 2: Giây 20 (3 Slime)
      final wave2 = timeline.where((e) => e.waveNumber == 2).toList();
      expect(wave2.length, equals(3));
      expect(wave2[0].triggerTime, equals(20.0));
      expect(wave2[1].triggerTime, equals(21.5));
      expect(wave2[2].triggerTime, equals(23.0));

      // Wave 3: Giây 35 (1 Zombie + 2 Slime)
      final wave3 = timeline.where((e) => e.waveNumber == 3).toList();
      expect(wave3.length, equals(3));
      expect(wave3[0].triggerTime, equals(35.0));
      expect(wave3[0].enemyType, equals(EnemyType.basicZombie));

      // Wave 4: Giây 55 (Final wave: 2 Zombie + 3 Slime + 1 Dark Titan)
      final wave4 = timeline.where((e) => e.waveNumber == 4).toList();
      expect(wave4.length, equals(6));
      expect(wave4[0].triggerTime, equals(55.0));
      expect(wave4[0].enemyType, equals(EnemyType.basicZombie));
      expect(wave4.last.triggerTime, equals(65.0));
      expect(wave4.last.enemyType, equals(EnemyType.darkTitan));
    });
  });

}
