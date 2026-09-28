import 'package:flame/extensions.dart';
import 'tile_type.dart';

/// Lớp đại diện cho dữ liệu cấu hình bản đồ trong game Tower Defense.
///
/// Quản lý kích thước lưới (mặc định 20 Cột x 11 Hàng, mỗi ô 32x32 px),
/// ma trận địa hình (tile ID) và danh sách đường đi của quái (waypoints).
class MapData {
  /// Khởi tạo dữ liệu bản đồ.
  MapData({
    required this.matrix,
    required this.waypoints,
    this.columns = 20,
    this.rows = 11,
    this.tileSize = 32.0,
  }) : assert(
         matrix.length == rows,
         'Số hàng trong ma trận (${matrix.length}) không khớp với rows ($rows)',
       ),
       assert(
         matrix.every((row) => row.length == columns),
         'Tất cả các hàng trong ma trận phải có đúng $columns cột',
       );

  /// Số cột của bản đồ (mặc định 20)
  final int columns;

  /// Số hàng của bản đồ (mặc định 11)
  final int rows;

  /// Kích thước mỗi ô vuông theo đơn vị pixel (mặc định 32.0)
  final double tileSize;

  /// Ma trận 2 chiều [rows x columns] chứa ID của từng ô
  final List<List<int>> matrix;

  /// Danh sách các điểm mốc (waypoints) quái sẽ đi qua trên hệ tọa độ lưới (Grid [col, row])
  final List<Vector2> waypoints;

  /// Chiều rộng tổng thể của bản đồ tính theo pixel (20 * 32 = 640 px)
  double get totalWidth => columns * tileSize;

  /// Chiều cao tổng thể của bản đồ tính theo pixel (11 * 32 = 352 px)
  double get totalHeight => rows * tileSize;

  /// Kích thước vector của toàn bộ bản đồ
  Vector2 get totalSize => Vector2(totalWidth, totalHeight);

  /// Kiểm tra xem ô tại tọa độ lưới (col, row) có thể xây dựng / đặt tháp hay không.
  ///
  /// Theo quy ước: Trả về `true` CHỈ KHI tileID == 0 (Ô cỏ 'giua').
  bool isTileBuildable(int col, int row) {
    if (col < 0 || col >= columns || row < 0 || row >= rows) {
      return false;
    }
    return matrix[row][col] == 0;
  }

  /// Lấy mã tile ID tại vị trí ô (col, row). Trả về -1 nếu nằm ngoài biên.
  int getTileId(int col, int row) {
    if (col < 0 || col >= columns || row < 0 || row >= rows) {
      return -1;
    }
    return matrix[row][col];
  }

  /// Lấy [TileType] tại ô (col, row).
  TileType getTileType(int col, int row) {
    final id = getTileId(col, row);
    return TileType.fromId(id);
  }

  /// Chuyển đổi tọa độ ô lưới (col, row) thành tọa độ pixel tại góc trên-trái của ô.
  Vector2 gridToPixelTopLeft(int col, int row) {
    return Vector2(col * tileSize, row * tileSize);
  }

  /// Chuyển đổi tọa độ ô lưới (col, row) thành tọa độ pixel tại tâm của ô (tiện cho quái di chuyển & đặt tháp).
  Vector2 gridToPixelCenter(int col, int row) {
    return Vector2((col + 0.5) * tileSize, (row + 0.5) * tileSize);
  }

  /// Lấy danh sách các điểm waypoints đã được chuyển đổi sang tọa độ pixel tâm ô.
  /// Hỗ trợ trực tiếp cho Enemy/Spawner di chuyển mượt mà ở bước tiếp theo.
  List<Vector2> getWaypointPixelCenters() {
    return waypoints
        .map((wp) => gridToPixelCenter(wp.x.toInt(), wp.y.toInt()))
        .toList();
  }

  // ==========================================
  // DỮ LIỆU CẤU HÌNH CỐ ĐỊNH CHO MÀN 1 (LEVEL 1)
  // ==========================================

  /// Ma trận bản đồ Màn 1 chuẩn 20 Cột x 11 Hàng.
  /// - Hàng 4: [2, 2, ...] bờ trên của đường đi
  /// - Hàng 5: [98, 1, ..., 99] đường quái đi từ trái (Cổng 98) sang phải (Căn cứ 99)
  /// - Hàng 6: [3, 3, ...] bờ dưới của đường đi
  /// - Các hàng còn lại: [0, 0, ...] cỏ xanh hợp lệ để đặt trụ súng.
  static const List<List<int>> level1Matrix = [
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2],
    [98, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 99],
    [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  ];

  /// Danh sách waypoints Màn 1: Từ ô Spawn [0, 5] đến ô Base [19, 5].
  static List<Vector2> get level1Waypoints => [
    Vector2(0, 5),
    Vector2(19, 5),
  ];

  /// Factory tạo nhanh phiên bản [MapData] cho Màn 1.
  factory MapData.level1() {
    return MapData(
      matrix: level1Matrix.map((row) => List<int>.from(row)).toList(),
      waypoints: level1Waypoints,
      columns: 20,
      rows: 11,
      tileSize: 32.0,
    );
  }
}
