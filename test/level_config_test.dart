import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tower_defense/game/tower_defense_game.dart';
import 'package:game_tower_defense/models/enemy_type.dart';
import 'package:game_tower_defense/models/level_config.dart';
import 'package:game_tower_defense/models/plant_data.dart';
import 'package:game_tower_defense/models/skill_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Kiểm thử cấu hình Chiến Dịch 8 Màn Chơi (LevelConfig)', () {
    test('Hệ thống có đủ chính xác 8 màn chơi', () {
      final levels = LevelConfig.allLevels;
      expect(levels.length, 8);
      for (int i = 0; i < 8; i++) {
        expect(levels[i].levelNumber, i + 1);
      }
    });

    test('Kiểm tra tính toàn vẹn của cả 8 ma trận bản đồ 20 Cột x 11 Hàng', () {
      for (int lvl = 1; lvl <= 8; lvl++) {
        final config = LevelConfig.getLevel(lvl);
        final matrix = config.tileMatrix;

        // Đủ 11 hàng
        expect(matrix.length, 11, reason: 'Màn $lvl phải có đúng 11 hàng');

        int countSpawn = 0;
        int countBase = 0;

        for (int r = 0; r < 11; r++) {
          // Mỗi hàng đủ 20 cột
          expect(matrix[r].length, 20, reason: 'Màn $lvl hàng $r phải có đúng 20 cột');

          for (int c = 0; c < 20; c++) {
            final tileId = matrix[r][c];
            if (tileId == 98) countSpawn++;
            if (tileId == 99) countBase++;
          }
        }

        // Màn 1-7 có 1 cổng spawn (98); Màn 8 có 2 cổng spawn (98)
        if (lvl == 8) {
          expect(countSpawn, 2, reason: 'Màn 8 phải có đúng 2 Cổng Quái (ID 98)');
        } else {
          expect(countSpawn, greaterThanOrEqualTo(1),
              reason: 'Màn $lvl phải có ít nhất 1 Cổng Quái (ID 98)');
        }

        // Tất cả các màn phải có đúng 1 Căn cứ Base (ID 99)
        expect(countBase, 1, reason: 'Màn $lvl phải có đúng 1 Căn cứ Base (ID 99)');
      }
    });

    test('Kiểm tra Waypoints của cả 8 màn nằm trong giới hạn lưới (0..19, 0..10)', () {
      for (int lvl = 1; lvl <= 8; lvl++) {
        final config = LevelConfig.getLevel(lvl);

        for (int branchIdx = 0; branchIdx < config.waypointsList.length; branchIdx++) {
          final branch = config.waypointsList[branchIdx];
          expect(branch.isNotEmpty, isTrue,
              reason: 'Màn $lvl nhánh $branchIdx không được rỗng');

          for (final wp in branch) {
            expect(wp.x, inInclusiveRange(0.0, 19.0),
                reason: 'Màn $lvl waypoint x=${wp.x} phải nằm trong 0..19');
            expect(wp.y, inInclusiveRange(0.0, 10.0),
                reason: 'Màn $lvl waypoint y=${wp.y} phải nằm trong 0..10');
          }

          // Điểm đầu phải là Cổng Spawn (ID 98)
          final startPoint = branch.first;
          expect(config.tileMatrix[startPoint.y.toInt()][startPoint.x.toInt()], 98,
              reason: 'Điểm đầu nhánh $branchIdx của Màn $lvl phải là ô Spawn 98');

          // Điểm cuối phải là Căn Cứ Base (ID 99)
          final endPoint = branch.last;
          expect(config.tileMatrix[endPoint.y.toInt()][endPoint.x.toInt()], 99,
              reason: 'Điểm cuối nhánh $branchIdx của Màn $lvl phải là ô Base 99');
        }
      }
    });

    test('Màn 8 có đúng 2 nhánh xuất phát độc lập và hội tụ tại nút thắt (9, 5)', () {
      final config = LevelConfig.getLevel(8);
      expect(config.waypointsList.length, 2);

      final branch1 = config.waypointsList[0];
      final branch2 = config.waypointsList[1];

      // Nhánh 1 bắt đầu tại (0, 2)
      expect(branch1.first, Vector2(0, 2));

      // Nhánh 2 bắt đầu tại (0, 8)
      expect(branch2.first, Vector2(0, 8));

      // Cả 2 nhánh cùng đi qua điểm hội tụ (9, 5)
      expect(branch1.contains(Vector2(9, 5)), isTrue);
      expect(branch2.contains(Vector2(9, 5)), isTrue);

      // Cả 2 nhánh cùng kết thúc tại Nhà chính (19, 5)
      expect(branch1.last, Vector2(19, 5));
      expect(branch2.last, Vector2(19, 5));
    });

    test('Kiểm tra Vốn Khởi Đầu (Starting Gold) tăng dần theo GDD', () {
      final expectedGolds = [200, 225, 250, 275, 300, 325, 350, 400];
      for (int i = 0; i < 8; i++) {
        final config = LevelConfig.getLevel(i + 1);
        expect(config.startingGold, expectedGolds[i],
            reason: 'Màn ${i + 1} phải có vốn $expectedGolds[i] Gold');
      }
    });

    test('Kiểm tra Danh sách Trụ mở khóa tích lũy chuẩn từng Màn', () {
      expect(LevelConfig.getLevel(1).unlockedPlants, [PlantType.peashooter]);
      expect(LevelConfig.getLevel(2).unlockedPlants,
          [PlantType.peashooter, PlantType.sunflower]);
      expect(LevelConfig.getLevel(3).unlockedPlants,
          [PlantType.peashooter, PlantType.sunflower, PlantType.clover]);
      expect(LevelConfig.getLevel(4).unlockedPlants, [
        PlantType.peashooter,
        PlantType.sunflower,
        PlantType.clover,
        PlantType.iceShroom,
      ]);
      expect(LevelConfig.getLevel(5).unlockedPlants, [
        PlantType.peashooter,
        PlantType.sunflower,
        PlantType.clover,
        PlantType.iceShroom,
        PlantType.firePeashooter,
      ]);
      expect(LevelConfig.getLevel(6).unlockedPlants, [
        PlantType.peashooter,
        PlantType.sunflower,
        PlantType.clover,
        PlantType.iceShroom,
        PlantType.firePeashooter,
        PlantType.electricShroom,
      ]);
      expect(LevelConfig.getLevel(7).unlockedPlants, [
        PlantType.peashooter,
        PlantType.sunflower,
        PlantType.clover,
        PlantType.iceShroom,
        PlantType.firePeashooter,
        PlantType.electricShroom,
        PlantType.starfruit,
      ]);
      expect(LevelConfig.getLevel(8).unlockedPlants, [
        PlantType.peashooter,
        PlantType.sunflower,
        PlantType.clover,
        PlantType.iceShroom,
        PlantType.firePeashooter,
        PlantType.electricShroom,
        PlantType.starfruit,
        PlantType.melonPult,
      ]);
    });

    test('Kiểm tra Danh sách Kỹ Năng mở khóa chuẩn từng Màn', () {
      expect(LevelConfig.getLevel(1).unlockedSkills, isEmpty);
      expect(LevelConfig.getLevel(2).unlockedSkills, [SkillType.goldenStorm]);
      expect(LevelConfig.getLevel(3).unlockedSkills, [SkillType.goldenStorm]);
      expect(LevelConfig.getLevel(4).unlockedSkills,
          [SkillType.goldenStorm, SkillType.tornado]);
      expect(LevelConfig.getLevel(5).unlockedSkills,
          [SkillType.goldenStorm, SkillType.tornado]);
      expect(LevelConfig.getLevel(6).unlockedSkills,
          [SkillType.goldenStorm, SkillType.tornado, SkillType.magicBind]);
      expect(LevelConfig.getLevel(7).unlockedSkills,
          [SkillType.goldenStorm, SkillType.tornado, SkillType.magicBind]);
      expect(LevelConfig.getLevel(8).unlockedSkills, [
        SkillType.goldenStorm,
        SkillType.tornado,
        SkillType.magicBind,
        SkillType.meteorite,
      ]);
    });

    test('Kiểm tra Wave Quái & Trận Boss cuối ở Màn 1 và Màn 8', () {
      final lvl1 = LevelConfig.getLevel(1);
      expect(lvl1.waveSchedule.isNotEmpty, isTrue);
      expect(lvl1.bossType, EnemyType.darkTitan);
      expect(lvl1.waveSchedule.any((e) => e.enemyType == EnemyType.darkTitan), isTrue);

      final lvl8 = LevelConfig.getLevel(8);
      expect(lvl8.waveSchedule.isNotEmpty, isTrue);
      expect(lvl8.bossType, EnemyType.darkTitan);
      expect(lvl8.waveSchedule.any((e) => e.enemyType == EnemyType.darkTitan), isTrue);
    });

    test('Kiểm tra Pixel Centers chuyển đổi chuẩn xác từ Waypoints', () {
      final config = LevelConfig.getLevel(1);
      final centers = config.primaryWaypointPixelCenters;
      expect(centers.first, Vector2(16.0, (5 + 0.5) * 32.0));
      expect(centers.last, Vector2((19 + 0.5) * 32.0, (5 + 0.5) * 32.0));
    });
  });

  group('Kiểm thử Logic Tiến Trình Mở Khóa Màn (Level Progression)', () {
    test('Khởi tạo game với Màn 1 và mở khóa cao nhất = 1', () {
      final game = TowerDefenseGame();
      expect(game.currentLevelNumber, 1);
      expect(game.maxUnlockedLevelNotifier.value, 1);
    });

    test('Chiến thắng Màn 1 tự động mở khóa Màn 2', () async {
      final game = TowerDefenseGame();
      await game.loadLevel(1);

      expect(game.maxUnlockedLevelNotifier.value, 1);

      // Giả lập kích hoạt chiến thắng màn 1
      game.waveSpawner.onVictory?.call();

      expect(game.isVictoryNotifier.value, isTrue);
      expect(game.maxUnlockedLevelNotifier.value, 2);
    });

    test('Tiến trình mở khóa tuần tự từ Màn 1 đến Màn 8', () async {
      final game = TowerDefenseGame();

      for (int lvl = 1; lvl < 8; lvl++) {
        await game.loadLevel(lvl);
        expect(game.currentLevelNumber, lvl);

        // Kích hoạt thắng
        game.waveSpawner.onVictory?.call();
        expect(game.maxUnlockedLevelNotifier.value, lvl + 1);
      }

      // Khi ở Màn 8 và chiến thắng, maxUnlockedLevel giữ ở 8 (không vượt quá 8)
      await game.loadLevel(8);
      game.waveSpawner.onVictory?.call();
      expect(game.maxUnlockedLevelNotifier.value, 8);
    });

    test('nextLevel() chuyển sang màn tiếp theo hoặc quay về màn 1 khi hết', () async {
      final game = TowerDefenseGame();
      await game.loadLevel(1);
      expect(game.currentLevelNumber, 1);

      await game.nextLevel();
      expect(game.currentLevelNumber, 2);

      await game.loadLevel(8);
      await game.nextLevel();
      expect(game.currentLevelNumber, 1);
    });

    test('restartCurrentLevel() nạp lại đúng cấu hình của màn đó', () async {
      final game = TowerDefenseGame();
      await game.loadLevel(4);
      expect(game.currentLevelNumber, 4);
      expect(game.goldNotifier.value, 275);

      // Thay đổi gold
      game.addGold(50);
      expect(game.goldNotifier.value, 325);

      // Restart màn 4
      await game.restartCurrentLevel();
      expect(game.currentLevelNumber, 4);
      expect(game.goldNotifier.value, 275); // Reset về giá trị startingGold của màn 4
    });
  });
}
