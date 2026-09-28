import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tower_defense/game/tower_defense_game.dart';
import 'package:game_tower_defense/models/enemy_type.dart';
import 'package:game_tower_defense/models/map_data.dart';
import 'package:game_tower_defense/models/plant_data.dart';

void main() {
  group('PlantData Model Tests', () {
    test('Khởi tạo Peashooter chuẩn thông số Màn 1', () {
      final pea = PlantData.fromType(PlantType.peashooter);
      expect(pea.name, equals('Peashooter'));
      expect(pea.cost, equals(100));
      expect(pea.rangeInTiles, equals(4.0));
      expect(pea.rangeInPixels, equals(128.0)); // 4 * 32
      expect(pea.attackInterval, equals(1.0));
      expect(pea.damage, equals(20.0));
      expect(pea.canAttack, isTrue);
      expect(pea.isProducer, isFalse);
      expect(pea.bulletSpritePath, contains('bullet_bean'));
    });

    test('Khởi tạo Sunflower đúng chức năng sản sinh vàng', () {
      final sun = PlantData.fromType(PlantType.sunflower);
      expect(sun.cost, equals(50));
      expect(sun.damage, equals(0.0));
      expect(sun.canAttack, isFalse);
      expect(sun.isProducer, isTrue);
      expect(sun.goldProduceAmount, equals(25));
    });

    test('Khởi tạo Ice-shroom đúng cơ chế làm chậm', () {
      final ice = PlantData.fromType(PlantType.iceShroom);
      expect(ice.cost, equals(175));
      expect(ice.slowFactor, equals(0.55));
      expect(ice.slowDuration, equals(2.5));
    });
  });

  group('Tower Placement System Tests', () {
    late TowerDefenseGame game;

    setUp(() {
      game = TowerDefenseGame();
      game.mapData = MapData.level1();
    });

    test('Đặt trụ thành công tại ô cỏ hợp lệ (ID 0) và bị trừ đúng số vàng', () {
      expect(game.playerGold, equals(200));

      final peaData = PlantData.fromType(PlantType.peashooter);
      // Ô (0, 0) là cỏ
      expect(game.canPlacePlant(0, 0, peaData), isTrue);

      final plant = game.placePlant(0, 0, PlantType.peashooter);
      expect(plant, isNotNull);
      expect(plant!.gridCol, equals(0));
      expect(plant.gridRow, equals(0));
      expect(plant.position, equals(Vector2(16.0, 16.0))); // Tâm ô (0, 0)

      // Kiểm tra tiền đã bị trừ 100 vàng
      expect(game.playerGold, equals(100));
      // Kiểm tra ô đã được ghi nhận có trụ
      expect(game.hasPlantAt(0, 0), isTrue);
    });

    test('Cấm đặt trụ trên ô đường đất của quái (Hàng 5)', () {
      final peaData = PlantData.fromType(PlantType.peashooter);

      // (5, 5) là mặt đường đất (ID 1)
      expect(game.canPlacePlant(5, 5, peaData), isFalse);

      final plant = game.placePlant(5, 5, PlantType.peashooter);
      expect(plant, isNull);
      // Vàng không đổi
      expect(game.playerGold, equals(200));
      expect(game.hasPlantAt(5, 5), isFalse);
    });

    test('Cấm đặt trụ đè lên ô đã có trụ', () {
      final peaData = PlantData.fromType(PlantType.peashooter);

      // Đặt lần 1 tại ô (1, 1)
      final plant1 = game.placePlant(1, 1, PlantType.peashooter);
      expect(plant1, isNotNull);
      expect(game.playerGold, equals(100));

      // Thử đặt lần 2 tại chính ô (1, 1)
      expect(game.canPlacePlant(1, 1, peaData), isFalse);
      final plant2 = game.placePlant(1, 1, PlantType.peashooter);
      expect(plant2, isNull);
      // Tiền vẫn giữ nguyên 100
      expect(game.playerGold, equals(100));
    });

    test('Cấm đặt trụ khi người chơi không đủ vàng', () {
      final peaData = PlantData.fromType(PlantType.peashooter);

      // Đặt 2 trụ hết 200 vàng
      game.placePlant(0, 0, PlantType.peashooter); // 200 -> 100
      game.placePlant(1, 0, PlantType.peashooter); // 100 -> 0
      expect(game.playerGold, equals(0));

      // Thử đặt trụ thứ 3 khi còn 0 vàng
      expect(game.canPlacePlant(2, 0, peaData), isFalse);
      final plant3 = game.placePlant(2, 0, PlantType.peashooter);
      expect(plant3, isNull);
    });
  });

  group('Combat Range & Damage Tests', () {
    test('Xác định mục tiêu nằm trong và ngoài tầm bắn của trụ', () {
      final peaData = PlantData.fromType(PlantType.peashooter);
      final plantPos = Vector2(16.0, 16.0); // Ô (0, 0)
      final range = peaData.rangeInPixels; // 128.0 px

      // Quái A ở (80.0, 16.0) -> Khoảng cách = 64.0 px < 128.0 px (Trong tầm)
      final enemyPosA = Vector2(80.0, 16.0);
      expect((enemyPosA - plantPos).length <= range, isTrue);

      // Quái B ở (150.0, 16.0) -> Khoảng cách = 134.0 px > 128.0 px (Ngoài tầm)
      final enemyPosB = Vector2(150.0, 16.0);
      expect((enemyPosB - plantPos).length <= range, isFalse);
    });

    test('Đạn gây sát thương làm giảm HP quái', () {
      final slime = MonsterData.fromType(EnemyType.greenSlime); // 70 HP
      final peaData = PlantData.fromType(PlantType.peashooter); // 20 Damage

      slime.currentHp -= peaData.damage;
      expect(slime.currentHp, equals(50.0));

      // Bắn thêm 2 phát
      slime.currentHp -= peaData.damage * 2;
      expect(slime.currentHp, equals(10.0));
      expect(slime.isDead, isFalse);

      // Phát cuối tiêu diệt quái
      slime.currentHp -= peaData.damage;
      expect(slime.isDead, isTrue);
    });
  });
}
