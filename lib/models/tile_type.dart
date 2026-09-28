/// Enum quản lý các loại ô (Tile) trên bản đồ Tower Defense.
///
/// Các ID quy ước:
/// - 0: Ô cỏ hợp lệ duy nhất để đặt tháp/súng ('giua.png')
/// - 1: Mặt đường đất quái di chuyển ('duong-di-quai.png')
/// - 2..10: Các mép bờ, góc cua trang trí địa hình bản đồ
/// - 98: Cổng quái (Spawn Point)
/// - 99: Căn cứ nhà chính (Base)
enum TileType {
  grass(0, 'setmap/giua.png', isBuildable: true, label: 'Cỏ (Đặt Trụ)'),
  path(1, 'setmap/duong-di-quai.png', isBuildable: false, label: 'Đường Quái Đi'),
  topMiddle(2, 'setmap/tren-giua.png', isBuildable: false, label: 'Mép Bờ Trên'),
  bottom(3, 'setmap/duoi.png', isBuildable: false, label: 'Mép Bờ Dưới'),
  left(4, 'setmap/trai.png', isBuildable: false, label: 'Mép Bờ Trái'),
  right(5, 'setmap/phai.png', isBuildable: false, label: 'Mép Bờ Phải'),
  topLeft(6, 'setmap/trai-tren.png', isBuildable: false, label: 'Góc Trái Trên'),
  topRight(7, 'setmap/phai-tren.png', isBuildable: false, label: 'Góc Phải Trên'),
  bottomLeft(8, 'setmap/trai-duoi.png', isBuildable: false, label: 'Góc Trái Dưới'),
  bottomRight(9, 'setmap/phai-duoi.png', isBuildable: false, label: 'Góc Phải Dưới'),
  bottomRightLeft(10, 'setmap/phai-duoi-trai.png', isBuildable: false, label: 'Góc Nối Phải Dưới Trái'),
  spawnPoint(98, 'setmap/duong-di-quai.png', isBuildable: false, label: 'Cổng Quái Spawn Point'),
  base(99, 'setmap/duong-di-quai.png', isBuildable: false, label: 'Căn Cứ Nhà Chính Base');

  const TileType(
    this.id,
    this.assetSubPath, {
    this.isBuildable = false,
    required this.label,
  });

  /// ID số nguyên tương ứng trong ma trận dữ liệu bản đồ
  final int id;

  /// Đường dẫn tương đối từ thư mục assets/ (ví dụ: 'setmap/giua.png')
  final String assetSubPath;

  /// Cờ xác định ô này có cho phép người chơi đặt tháp phòng thủ hay không
  final bool isBuildable;

  /// Tên mô tả loại ô
  final String label;

  /// Tra cứu [TileType] từ mã ID số nguyên.
  /// Mặc định trả về [TileType.grass] nếu ID không hợp lệ.
  static TileType fromId(int id) {
    for (final type in TileType.values) {
      if (type.id == id) {
        return type;
      }
    }
    return TileType.grass;
  }
}
