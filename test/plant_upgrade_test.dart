import 'package:flutter_test/flutter_test.dart';
import 'package:game_tower_defense/game/tower_defense_game.dart';
import 'package:game_tower_defense/models/map_data.dart';
import 'package:game_tower_defense/models/plant_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Plant Upgrade Progression Tests (Peashooter)', () {
    test('Chỉ số thăng tiến chuẩn xác Lv1 -> Lv2 -> Lv3 theo GDD', () {
      final pea = PlantData.fromType(PlantType.peashooter);

      // Level 1: Mặc định
      expect(pea.level, equals(1));
      expect(pea.cost, equals(100));
      expect(pea.totalInvestedGold, equals(100));
      expect(pea.rangeInTiles, equals(4.0));
      expect(pea.attackInterval, equals(1.0));
      expect(pea.damage, equals(20.0));
      expect(pea.upgradeCost, equals(80)); // Phí lên Lv2
      expect(pea.sellRefund, equals(70)); // 100 * 0.7 = 70

      // Lên Level 2
      pea.totalInvestedGold += pea.upgradeCost; // 100 + 80 = 180
      pea.applyLevel(2);
      expect(pea.level, equals(2));
      expect(pea.totalInvestedGold, equals(180));
      expect(pea.rangeInTiles, equals(4.0));
      expect(pea.attackInterval, equals(0.8));
      expect(pea.damage, equals(28.0));
      expect(pea.upgradeCost, equals(140)); // Phí lên Lv3
      expect(pea.sellRefund, equals(126)); // 180 * 0.7 = 126

      // Lên Level 3
      pea.totalInvestedGold += pea.upgradeCost; // 180 + 140 = 320
      pea.applyLevel(3);
      expect(pea.level, equals(3));
      expect(pea.isMaxLevel, isTrue);
      expect(pea.totalInvestedGold, equals(320));
      expect(pea.rangeInTiles, equals(5.0)); // Tầm bắn mở rộng lên 5 ô
      expect(pea.attackInterval, equals(0.67));
      expect(pea.damage, equals(40.0));
      expect(pea.upgradeCost, equals(0)); // Cấp tối đa
      expect(pea.sellRefund, equals(224)); // 320 * 0.7 = 224
    });
  });

  group('PlantComponent Upgrade & Sell In-Game Logic Tests', () {
    late TowerDefenseGame game;

    setUp(() {
      game = TowerDefenseGame();
      game.mapData = MapData.level1();
    });

    test('Nâng cấp trụ thành công khi đủ tiền và trừ đúng Gold', () {
      // Cho người chơi 500 vàng
      game.goldNotifier.value = 500;

      // Đặt Peashooter tại ô (2, 2) tốn 100 vàng -> còn 400 vàng
      final plant = game.placePlant(2, 2, PlantType.peashooter)!;
      expect(game.playerGold, equals(400));
      expect(plant.data.level, equals(1));

      // Nâng cấp lên Level 2: tốn 80 vàng -> còn 320 vàng
      final upgradedToLv2 = plant.upgrade();
      expect(upgradedToLv2, isTrue);
      expect(plant.data.level, equals(2));
      expect(game.playerGold, equals(320));
      expect(plant.data.totalInvestedGold, equals(180));

      // Nâng cấp lên Level 3: tốn 140 vàng -> còn 180 vàng
      final upgradedToLv3 = plant.upgrade();
      expect(upgradedToLv3, isTrue);
      expect(plant.data.level, equals(3));
      expect(game.playerGold, equals(180));
      expect(plant.data.totalInvestedGold, equals(320));

      // Thử nâng cấp tiếp khi đã ở Level 3 -> Thất bại, không trừ tiền
      final upgradedBeyondMax = plant.upgrade();
      expect(upgradedBeyondMax, isFalse);
      expect(plant.data.level, equals(3));
      expect(game.playerGold, equals(180));
    });

    test('Không thể nâng cấp khi không đủ tiền', () {
      // Người chơi chỉ có 120 vàng
      game.goldNotifier.value = 120;

      // Đặt Peashooter tốn 100 vàng -> còn 20 vàng
      final plant = game.placePlant(0, 0, PlantType.peashooter)!;
      expect(game.playerGold, equals(20));

      // Phí lên Lv2 là 80 vàng nhưng chỉ có 20 vàng -> thất bại
      final success = plant.upgrade();
      expect(success, isFalse);
      expect(plant.data.level, equals(1));
      expect(game.playerGold, equals(20));
    });

    test('Bán trụ hoàn trả chuẩn 70% tổng vốn và giải phóng ô đất', () {
      game.goldNotifier.value = 500;

      // 1. Đặt trụ tại (3, 3): tốn 100 -> còn 400
      final plant = game.placePlant(3, 3, PlantType.peashooter)!;
      expect(game.hasPlantAt(3, 3), isTrue);

      // 2. Nâng lên Lv2: tốn 80 -> còn 320 (Tổng đầu tư = 180)
      plant.upgrade();
      expect(plant.data.totalInvestedGold, equals(180));
      expect(game.playerGold, equals(320));

      // 3. Bán trụ: Hoàn 70% của 180 = 126 vàng
      final refund = plant.sell();
      expect(refund, equals(126));

      // Số vàng sau khi bán: 320 + 126 = 446 vàng
      expect(game.playerGold, equals(446));

      // Ô (3, 3) đã được giải phóng
      expect(game.hasPlantAt(3, 3), isFalse);

      // Có thể đặt trụ mới ngay vào ô (3, 3)
      final newPlant = game.placePlant(3, 3, PlantType.sunflower);
      expect(newPlant, isNotNull);
      expect(game.hasPlantAt(3, 3), isTrue);
    });
  });
}
