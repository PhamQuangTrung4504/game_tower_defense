import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tower_defense/models/map_data.dart';
import 'package:game_tower_defense/models/tile_type.dart';

void main() {
  group('TileType Tests', () {
    test('Kiểm tra map ID sang TileType', () {
      expect(TileType.fromId(0), equals(TileType.grass));
      expect(TileType.fromId(1), equals(TileType.path));
      expect(TileType.fromId(2), equals(TileType.topMiddle));
      expect(TileType.fromId(3), equals(TileType.bottom));
      expect(TileType.fromId(4), equals(TileType.left));
      expect(TileType.fromId(5), equals(TileType.right));
      expect(TileType.fromId(6), equals(TileType.topLeft));
      expect(TileType.fromId(7), equals(TileType.topRight));
      expect(TileType.fromId(8), equals(TileType.bottomLeft));
      expect(TileType.fromId(9), equals(TileType.bottomRight));
      expect(TileType.fromId(10), equals(TileType.bottomRightLeft));
      expect(TileType.fromId(98), equals(TileType.spawnPoint));
      expect(TileType.fromId(99), equals(TileType.base));
    });

    test('Chỉ duy nhất TileType.grass (ID 0) có isBuildable == true', () {
      for (final type in TileType.values) {
        if (type.id == 0) {
          expect(type.isBuildable, isTrue, reason: '${type.name} phải buildable');
        } else {
          expect(type.isBuildable, isFalse, reason: '${type.name} không được buildable');
        }
      }
    });
  });

  group('MapData Level 1 Tests', () {
    late MapData level1;

    setUp(() {
      level1 = MapData.level1();
    });

    test('Kích thước ma trận chuẩn 20 Cột x 11 Hàng và độ phân giải 640x352', () {
      expect(level1.columns, equals(20));
      expect(level1.rows, equals(11));
      expect(level1.tileSize, equals(32.0));
      expect(level1.matrix.length, equals(11));
      for (final row in level1.matrix) {
        expect(row.length, equals(20));
      }
      expect(level1.totalWidth, equals(640.0));
      expect(level1.totalHeight, equals(352.0));
    });

    test('Waypoints Màn 1 chuẩn: [Vector2(0, 5), Vector2(19, 5)]', () {
      expect(level1.waypoints.length, equals(2));
      expect(level1.waypoints[0], equals(Vector2(0, 5)));
      expect(level1.waypoints[1], equals(Vector2(19, 5)));

      final pixelWaypoints = level1.getWaypointPixelCenters();
      // Tâm ô (0, 5): x = (0 + 0.5) * 32 = 16, y = (5 + 0.5) * 32 = 176
      expect(pixelWaypoints[0], equals(Vector2(16.0, 176.0)));
      // Tâm ô (19, 5): x = (19 + 0.5) * 32 = 624, y = (5 + 0.5) * 32 = 176
      expect(pixelWaypoints[1], equals(Vector2(624.0, 176.0)));
    });

    test('isTileBuildable trả về true CHỈ KHI tileID == 0', () {
      // Hàng 0, cột 0 là ID 0 (Cỏ) -> true
      expect(level1.isTileBuildable(0, 0), isTrue);

      // Hàng 4 là bờ trên (ID 2) -> false
      expect(level1.isTileBuildable(0, 4), isFalse);
      expect(level1.isTileBuildable(5, 4), isFalse);

      // Hàng 5: Cổng quái (0, 5) ID 98 -> false
      expect(level1.isTileBuildable(0, 5), isFalse);

      // Hàng 5: Đường đi quái (1..18, 5) ID 1 -> false
      expect(level1.isTileBuildable(1, 5), isFalse);
      expect(level1.isTileBuildable(10, 5), isFalse);
      expect(level1.isTileBuildable(18, 5), isFalse);

      // Hàng 5: Căn cứ (19, 5) ID 99 -> false
      expect(level1.isTileBuildable(19, 5), isFalse);

      // Hàng 6 là bờ dưới (ID 3) -> false
      expect(level1.isTileBuildable(0, 6), isFalse);

      // Các ô ngoài biên -> false
      expect(level1.isTileBuildable(-1, 0), isFalse);
      expect(level1.isTileBuildable(0, -1), isFalse);
      expect(level1.isTileBuildable(20, 5), isFalse);
      expect(level1.isTileBuildable(5, 11), isFalse);
    });
  });
}
