import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../models/map_data.dart';
import '../../models/tile_type.dart';
import '../tower_defense_game.dart';

/// Component phụ trách hiển thị toàn bộ bản đồ lưới 2D pixel-art.
///
/// Chức năng:
/// - Đọc ma trận [MapData] (chuẩn 20 Cột x 11 Hàng, 32x32 px mỗi ô).
/// - Cache sẵn các [Sprite] tương ứng với từng [TileType] từ assets.
/// - Render chuẩn xác các tile lên canvas với tỉ lệ gốc 640x352 px.
/// - Vẽ visual indicators cho Cổng Quái Spawn (ID 98) và Căn Cứ Nhà Chính Base (ID 99).
/// - Nhận sự kiện Tap/Click thông qua [TapCallbacks] để kích hoạt đặt trụ [TowerDefenseGame.handleMapTap].
class MapRendererComponent extends PositionComponent
    with HasGameReference<TowerDefenseGame>, TapCallbacks {
  MapRendererComponent({
    required this.mapData,
    this.showGrid = false,
  }) : super(
         size: mapData.totalSize,
         position: Vector2.zero(),
       );

  /// Dữ liệu bản đồ đang được render
  final MapData mapData;

  /// Cờ hiển thị đường viền lưới (hữu ích cho chế độ Debug hoặc khi kéo thả đặt trụ)
  bool showGrid;

  /// Cache các sprite đã tải theo từng loại ô để tối ưu hiệu năng
  final Map<TileType, Sprite> _spriteCache = {};

  /// Biến đếm thời gian dùng cho các hiệu ứng hoạt họa lấp lánh (portal/base pulse)
  double _animationTime = 0.0;

  // Paints cho Grid và Markers
  final Paint _gridPaint = Paint()
    ..color = const Color(0x22FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  final Paint _spawnGlowPaint = Paint()
    ..color = const Color(0x889C27B0)
    ..style = PaintingStyle.fill;

  final Paint _spawnPortalPaint = Paint()
    ..color = const Color(0xFFE040FB)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  final Paint _baseGlowPaint = Paint()
    ..color = const Color(0x882196F3)
    ..style = PaintingStyle.fill;

  final Paint _baseShieldPaint = Paint()
    ..color = const Color(0xFF00E5FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Tải trước toàn bộ các sprite địa hình từ assets
    // Lưu ý: Đường dẫn được resolved thông qua game.images (prefix = 'assets/')
    for (final type in TileType.values) {
      if (!_spriteCache.containsKey(type)) {
        try {
          final sprite = await game.loadSprite(type.assetSubPath);
          _spriteCache[type] = sprite;
        } catch (e) {
          debugPrint('Lỗi tải sprite cho tile ${type.name} (${type.assetSubPath}): $e');
        }
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animationTime += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final tileSize = mapData.tileSize;
    final tileSizeVec = Vector2.all(tileSize);

    // 1. Duyệt qua ma trận 20 cột x 11 hàng để vẽ các ô địa hình
    for (int row = 0; row < mapData.rows; row++) {
      for (int col = 0; col < mapData.columns; col++) {
        final tileId = mapData.getTileId(col, row);
        final tileType = TileType.fromId(tileId);
        final sprite = _spriteCache[tileType];
        final tilePos = Vector2(col * tileSize, row * tileSize);

        // Vẽ sprite nền của ô
        if (sprite != null) {
          sprite.render(
            canvas,
            position: tilePos,
            size: tileSizeVec,
          );
        }

        // Vẽ hiệu ứng đặc biệt cho Spawn Point (ID 98) và Base (ID 99)
        if (tileId == 98) {
          _renderSpawnMarker(canvas, tilePos, tileSize);
        } else if (tileId == 99) {
          _renderBaseMarker(canvas, tilePos, tileSize);
        }

        // Hiển thị lưới mờ nếu bật showGrid
        if (showGrid) {
          canvas.drawRect(
            Rect.fromLTWH(tilePos.x, tilePos.y, tileSize, tileSize),
            _gridPaint,
          );
        }
      }
    }
  }

  /// Vẽ biểu tượng Cổng Quái Không Gian ma thuật (Spawn Point - ID 98)
  void _renderSpawnMarker(Canvas canvas, Vector2 pos, double size) {
    final center = Offset(pos.x + size / 2, pos.y + size / 2);
    final pulse = (math.sin(_animationTime * 4.0) + 1.0) / 2.0; // 0..1
    final radius = (size / 3.2) + pulse * 2.0;

    // Vòng hào quang tím ma mị
    canvas.drawCircle(center, radius, _spawnGlowPaint);

    // Vòng tròn cổng không gian xoay nhẹ
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_animationTime * 2.0);
    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
    canvas.drawOval(rect, _spawnPortalPaint);

    // Điểm tâm cổng
    final corePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset.zero, 3.0, corePaint);
    canvas.restore();
  }

  /// Vẽ biểu tượng Căn Cứ Nhà Chính / Khiên Năng Lượng (Base - ID 99)
  void _renderBaseMarker(Canvas canvas, Vector2 pos, double size) {
    final center = Offset(pos.x + size / 2, pos.y + size / 2);
    final pulse = (math.cos(_animationTime * 3.0) + 1.0) / 2.0; // 0..1
    final radius = (size / 3.0) + pulse * 2.5;

    // Hào quang xanh lam công nghệ cao
    canvas.drawCircle(center, radius, _baseGlowPaint);

    // Viền kim cương khiên phòng thủ
    final shieldPath = Path();
    final s = size * 0.32;
    shieldPath.moveTo(center.dx, center.dy - s);
    shieldPath.lineTo(center.dx + s, center.dy);
    shieldPath.lineTo(center.dx, center.dy + s);
    shieldPath.lineTo(center.dx - s, center.dy);
    shieldPath.close();

    canvas.drawPath(shieldPath, _baseShieldPaint);

    // Tâm lõi căn cứ phát sáng
    final corePaint = Paint()..color = const Color(0xFFE0F7FA);
    canvas.drawCircle(center, 3.5, corePaint);
  }

  /// Lắng nghe thao tác chạm trực tiếp trên bản đồ để xác định tọa độ ô lưới (col, row)
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    final col = (event.localPosition.x / mapData.tileSize).floor();
    final row = (event.localPosition.y / mapData.tileSize).floor();
    game.handleMapTap(col, row);
  }

  /// Kiểm tra xem ô tại tọa độ lưới (col, row) có thể xây dựng súng hay không.
  /// Chỉ trả về true khi tileID == 0.
  bool isTileBuildable(int col, int row) {
    return mapData.isTileBuildable(col, row);
  }

  /// Chuyển đổi tọa độ pixel cục bộ trên màn hình thành tọa độ lưới (col, row).
  /// Trả về null nếu nằm ngoài phạm vi bản đồ.
  Vector2? getGridCoordinate(Vector2 localPosition) {
    final col = (localPosition.x / mapData.tileSize).floor();
    final row = (localPosition.y / mapData.tileSize).floor();

    if (col < 0 || col >= mapData.columns || row < 0 || row >= mapData.rows) {
      return null;
    }
    return Vector2(col.toDouble(), row.toDouble());
  }

  /// Kiểm tra xem vị trí pixel cục bộ (ví dụ khi người chơi bấm/chạm) có hợp lệ để đặt súng không.
  bool isTileBuildableAt(Vector2 localPosition) {
    final coord = getGridCoordinate(localPosition);
    if (coord == null) return false;
    return isTileBuildable(coord.x.toInt(), coord.y.toInt());
  }
}
