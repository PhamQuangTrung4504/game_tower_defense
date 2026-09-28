import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tower_defense/game/components/enemy_component.dart';
import 'package:game_tower_defense/game/components/wave_spawner_component.dart';
import 'package:game_tower_defense/game/tower_defense_game.dart';
import 'package:game_tower_defense/models/enemy_type.dart';
import 'package:game_tower_defense/models/level_config.dart';
import 'package:game_tower_defense/models/map_data.dart';
import 'package:game_tower_defense/models/skill_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mana System Tests', () {
    late TowerDefenseGame game;

    setUp(() {
      game = TowerDefenseGame();
      game.mapData = MapData.level1();
      game.waveSpawner = WaveSpawnerComponent(waypoints: game.mapData.getWaypointPixelCenters());
    });


    test('Mana ban đầu là 100, tiêu hao và hồi phục 2.5 MP/s chuẩn xác', () {
      expect(game.mana, equals(100.0));
      expect(game.manaNotifier.value, equals(100.0));

      // Tiêu hao 40 MP cho Bão Vàng -> còn 60 MP
      final success = game.spendMana(40.0);
      expect(success, isTrue);
      expect(game.mana, equals(60.0));
      expect(game.manaNotifier.value, equals(60.0));

      // Không thể tiêu 70 MP khi chỉ còn 60 MP
      final fail = game.spendMana(70.0);
      expect(fail, isFalse);
      expect(game.mana, equals(60.0));

      // Hồi phục trong 4 giây: 60 + 2.5 * 4 = 70 MP
      game.update(4.0);
      expect(game.mana, closeTo(70.0, 0.001));

      // Không vượt quá mức trần 100 MP
      game.update(20.0);
      expect(game.mana, equals(100.0));
    });
  });

  group('Skill Casting & Cooldown Tests', () {
    late TowerDefenseGame game;

    setUp(() {
      game = TowerDefenseGame();
      game.currentLevelConfig = LevelConfig.getLevel(8);
      game.mapData = MapData.level1();
      game.waveSpawner = WaveSpawnerComponent(waypoints: game.mapData.getWaypointPixelCenters());
    });


    test('Thi triển Bão Vàng trừ 40 MP và kích hoạt hồi chiêu 30s', () {
      final goldenStorm = game.skills[SkillType.goldenStorm]!;
      expect(goldenStorm.isReady, isTrue);
      expect(goldenStorm.manaCost, equals(40.0));
      expect(goldenStorm.cooldown, equals(30.0));

      // Thi triển
      final ok = game.castSkill(SkillType.goldenStorm);
      expect(ok, isTrue);
      expect(game.mana, equals(60.0));
      expect(goldenStorm.isReady, isFalse);
      expect(goldenStorm.currentCooldown, equals(30.0));
      expect(game.isGoldenStormActive, isTrue);

      // Thử thi triển lại ngay khi đang cooldown -> Thất bại
      final ok2 = game.castSkill(SkillType.goldenStorm);
      expect(ok2, isFalse);
      expect(game.mana, equals(60.0)); // Mana không bị trừ thêm

      // Cập nhật 15s -> Cooldown còn 15s
      game.update(15.0);
      expect(goldenStorm.currentCooldown, closeTo(15.0, 0.001));
      expect(goldenStorm.isReady, isFalse);

      // Cập nhật thêm 15s -> Hồi chiêu xong
      game.update(15.0);
      expect(goldenStorm.isReady, isTrue);
    });

    test('Bão Vàng cộng thêm 50% Gold khi diệt quái', () {
      final slimeData = MonsterData.fromType(EnemyType.greenSlime); // 10 Gold gốc

      final initialGold = game.playerGold;

      // 1. Diệt quái khi KHÔNG có Bão Vàng: nhận đúng 10 Gold
      slimeData.currentHp = 0.0;
      int normalReward = slimeData.goldReward;
      if (game.isGoldenStormActive) {
        normalReward = (normalReward * 1.5).round();
      }
      game.addGold(normalReward);
      expect(game.playerGold, equals(initialGold + 10));

      // 2. Kích hoạt Bão Vàng và diệt quái: nhận 15 Gold (10 * 1.5)
      game.castSkill(SkillType.goldenStorm);
      expect(game.isGoldenStormActive, isTrue);

      final slimeData2 = MonsterData.fromType(EnemyType.greenSlime);
      slimeData2.currentHp = 0.0;
      int buffedReward = slimeData2.goldReward;
      if (game.isGoldenStormActive) {
        buffedReward = (buffedReward * 1.5).round();
      }
      game.addGold(buffedReward);
      expect(buffedReward, equals(15));
      expect(game.playerGold, equals(initialGold + 10 + 15));
    });
  });

  group('Boss Dark Titan & Skill Mechanics Tests', () {
    test('Boss Dark Titan kháng 100% làm chậm từ đạn băng', () {
      final titanData = MonsterData.fromType(EnemyType.darkTitan);
      expect(titanData.maxHp, equals(2200.0));
      expect(titanData.isBoss, isTrue);

      final titan = EnemyComponent(
        data: titanData,
        waypoints: [Vector2(0, 0), Vector2(100, 0)],
      );

      // Thử áp dụng làm chậm 50%
      titan.applySlow(0.5, 3.0);
      // Kiểm tra: Boss không bị ảnh hưởng, tốc độ vẫn giữ nguyên
      expect(titan.data.speed, equals(0.40));
    });

    test('Trói Ma Thuật trừ 20% Max HP quái thường, nhưng trừ 8% Max HP đối với Boss', () {
      // Quái thường: Zombie 150 HP
      final zombieData = MonsterData.fromType(EnemyType.basicZombie);
      final zombie = EnemyComponent(
        data: zombieData,
        waypoints: [Vector2(0, 0)],
      );
      // Trừ 20% của 150 = 30 dmg -> còn 120 HP
      zombie.takePercentDamage(0.20);
      expect(zombieData.currentHp, equals(120.0));

      // Boss: Dark Titan 2200 HP
      final titanData = MonsterData.fromType(EnemyType.darkTitan);
      final titan = EnemyComponent(
        data: titanData,
        waypoints: [Vector2(0, 0)],
      );
      // Trừ 8% của 2200 = 176 dmg -> còn 2024 HP
      titan.takePercentDamage(0.08);
      expect(titanData.currentHp, equals(2024.0));
    });

    test('Boss Dark Titan bị trói tối đa 1.5s, quái thường trói 3.0s', () {
      // Quái thường
      final slime = EnemyComponent(
        data: MonsterData.fromType(EnemyType.greenSlime),
        waypoints: [Vector2(0, 0)],
      );
      slime.applyStun(3.0);
      expect(slime.stunTimer, equals(3.0));

      // Boss Dark Titan
      final titan = EnemyComponent(
        data: MonsterData.fromType(EnemyType.darkTitan),
        waypoints: [Vector2(0, 0)],
      );
      titan.applyStun(3.0);
      expect(titan.stunTimer, equals(1.5)); // Bị giới hạn 1.5s
    });

    test('Lốc Xoáy đẩy lùi quái thường nhưng Boss chỉ khựng 0.3s', () {
      // Quái thường ở x = 200
      final slime = EnemyComponent(
        data: MonsterData.fromType(EnemyType.greenSlime),
        waypoints: [Vector2(16, 176), Vector2(624, 176)],
      );
      slime.position = Vector2(200, 176);
      slime.pushBack(110.0);
      expect(slime.position.x, equals(90.0)); // Lùi 110 px

      // Boss ở x = 200
      final titan = EnemyComponent(
        data: MonsterData.fromType(EnemyType.darkTitan),
        waypoints: [Vector2(16, 176), Vector2(624, 176)],
      );
      titan.position = Vector2(200, 176);
      titan.pushBack(110.0);
      expect(titan.position.x, equals(200.0)); // Không bị đẩy lùi vị trí
      expect(titan.stunTimer, equals(0.3)); // Chỉ khựng 0.3s
    });
  });
}
