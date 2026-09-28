/// Enum định danh 8 loại trụ phòng thủ trong game Tower Defense
enum PlantType {
  peashooter(1, 'Đậu Bắn (Peashooter)'),
  sunflower(2, 'Hoa Hướng Dương (Sunflower)'),
  clover(3, 'Cỏ 3 Lá (Clover)'),
  iceShroom(4, 'Nấm Băng (Ice-shroom)'),
  firePeashooter(5, 'Đậu Lửa (Fire Peashooter)'),
  electricShroom(6, 'Nấm Sét (Electric Shroom)'),
  starfruit(7, 'Khế 5 Cánh (Starfruit)'),
  melonPult(8, 'Máy Bắn Dưa (Melon-pult)');

  const PlantType(this.id, this.label);

  final int id;
  final String label;
}

/// Model lưu trữ toàn bộ chỉ số chiến đấu, cấp độ (Level 1..3) và tài nguyên của trụ
class PlantData {
  PlantData({
    required this.type,
    required this.name,
    required this.cost,
    required this.rangeInTiles,
    required this.attackInterval,
    required this.damage,
    required this.footSpritePath,
    required this.headSpritePath,
    this.bulletSpritePath,
    this.bulletSpeed = 250.0,
    this.slowFactor = 1.0,
    this.slowDuration = 0.0,
    this.goldProduceAmount = 0,
    this.goldProduceInterval = 0.0,
    this.level = 1,
    int? totalInvestedGold,
  }) : totalInvestedGold = totalInvestedGold ?? cost;

  final PlantType type;
  final String name;

  /// Giá vàng gốc để mua trụ ở Level 1
  final int cost;

  /// Cấp độ hiện tại của trụ (1, 2 hoặc 3)
  int level;

  /// Tổng số vàng người chơi đã đầu tư vào trụ (Bao gồm tiền mua và các lần nâng cấp)
  int totalInvestedGold;

  /// Tầm bắn tính theo số ô lưới (ví dụ: 4 ô)
  double rangeInTiles;

  /// Thời gian hồi giữa 2 phát bắn (giây)
  double attackInterval;

  /// Sát thương gây ra cho mỗi phát bắn
  double damage;

  /// Đường dẫn asset chân đế cố định (32x32)
  final String footSpritePath;

  /// Đường dẫn asset đầu xoay / thân tấn công
  final String headSpritePath;

  /// Đường dẫn asset đạn bay (nếu là trụ bắn)
  final String? bulletSpritePath;

  /// Vận tốc bay của đạn (pixel/giây)
  double bulletSpeed;

  /// Hệ số làm chậm kẻ địch (ví dụ: 0.6 = làm chậm 40%)
  double slowFactor;

  /// Thời gian hiệu lực làm chậm (giây)
  double slowDuration;

  /// Số vàng sản sinh (dành riêng cho Sunflower)
  int goldProduceAmount;

  /// Thời gian hồi sinh vàng (giây)
  double goldProduceInterval;

  /// Tầm bắn tính theo pixel (rangeInTiles * 32.0 px)
  double get rangeInPixels => rangeInTiles * 32.0;

  /// Kiểm tra trụ này có khả năng tấn công bằng đạn hay không
  bool get canAttack => damage > 0 && bulletSpritePath != null;

  /// Kiểm tra trụ có khả năng sinh vàng hay không (Sunflower)
  bool get isProducer => goldProduceAmount > 0;

  /// Kiểm tra trụ đã đạt cấp độ tối đa (Level 3) hay chưa
  bool get isMaxLevel => level >= 3;

  /// Đường dẫn asset icon huy hiệu cấp độ (lv1, lv2, lv3)
  String get levelBadgePath => 'levels/lv${level}_32x32.png';

  /// Chi phí để nâng cấp lên cấp tiếp theo.
  /// - Lv1 -> Lv2: ~80% giá mua ban đầu.
  /// - Lv2 -> Lv3: ~140% giá mua ban đầu.
  /// - Lv3 (MAX): 0.
  int get upgradeCost {
    if (level == 1) {
      return _getUpgradeCostToLv2(type, cost);
    } else if (level == 2) {
      return _getUpgradeCostToLv3(type, cost);
    }
    return 0; // Đã đạt Level 3 tối đa
  }

  /// Số vàng hoàn lại khi bán trụ: Luôn đúng 70% tổng vốn đã đầu tư (dùng phép chia nguyên tránh sai số float)
  int get sellRefund => (totalInvestedGold * 70) ~/ 100;

  /// Phí nâng cấp Lv1 -> Lv2
  static int _getUpgradeCostToLv2(PlantType type, int baseCost) {
    switch (type) {
      case PlantType.peashooter:
        return 80;
      case PlantType.sunflower:
        return 40;
      case PlantType.clover:
        return 100;
      case PlantType.iceShroom:
        return 140;
      case PlantType.firePeashooter:
        return 140;
      case PlantType.electricShroom:
        return 120;
      case PlantType.starfruit:
        return 100;
      case PlantType.melonPult:
        return 240;
    }
  }

  /// Phí nâng cấp Lv2 -> Lv3
  static int _getUpgradeCostToLv3(PlantType type, int baseCost) {
    switch (type) {
      case PlantType.peashooter:
        return 140;
      case PlantType.sunflower:
        return 70;
      case PlantType.clover:
        return 175;
      case PlantType.iceShroom:
        return 245;
      case PlantType.firePeashooter:
        return 245;
      case PlantType.electricShroom:
        return 210;
      case PlantType.starfruit:
        return 175;
      case PlantType.melonPult:
        return 420;
    }
  }

  /// Cập nhật chỉ số thăng tiến khi lên cấp mới (1..3)
  void applyLevel(int newLevel) {
    if (newLevel < 1 || newLevel > 3) return;
    level = newLevel;

    switch (type) {
      case PlantType.peashooter:
        if (level == 1) {
          rangeInTiles = 4.0;
          attackInterval = 1.0;
          damage = 20.0;
        } else if (level == 2) {
          rangeInTiles = 4.0;
          attackInterval = 0.8;
          damage = 28.0; // DPS: 35
        } else if (level == 3) {
          rangeInTiles = 5.0; // Tăng tầm bắn lên 5 ô (160 px)
          attackInterval = 0.67; // Tốc độ bắn nhanh
          damage = 40.0; // Bắn liên tiếp 2 viên x 20 dmg -> DPS: 60
        }
        break;

      case PlantType.sunflower:
        if (level == 1) {
          goldProduceAmount = 25;
          goldProduceInterval = 6.0;
        } else if (level == 2) {
          goldProduceAmount = 35;
          goldProduceInterval = 5.0;
        } else if (level == 3) {
          goldProduceAmount = 50;
          goldProduceInterval = 4.0;
        }
        break;

      case PlantType.clover:
        if (level == 1) {
          rangeInTiles = 3.5;
          attackInterval = 0.8;
          damage = 15.0;
        } else if (level == 2) {
          rangeInTiles = 3.5;
          attackInterval = 0.65;
          damage = 22.0;
        } else if (level == 3) {
          rangeInTiles = 4.0;
          attackInterval = 0.5;
          damage = 32.0;
        }
        break;

      case PlantType.iceShroom:
        if (level == 1) {
          rangeInTiles = 3.5;
          attackInterval = 1.2;
          damage = 15.0;
          slowFactor = 0.55;
          slowDuration = 2.5;
        } else if (level == 2) {
          rangeInTiles = 3.5;
          attackInterval = 1.0;
          damage = 22.0;
          slowFactor = 0.50;
          slowDuration = 3.0;
        } else if (level == 3) {
          rangeInTiles = 4.2;
          attackInterval = 0.8;
          damage = 32.0;
          slowFactor = 0.40; // Làm chậm tới 60%
          slowDuration = 3.5;
        }
        break;

      case PlantType.firePeashooter:
        if (level == 1) {
          rangeInTiles = 4.0;
          attackInterval = 1.0;
          damage = 35.0;
        } else if (level == 2) {
          rangeInTiles = 4.0;
          attackInterval = 0.85;
          damage = 50.0;
        } else if (level == 3) {
          rangeInTiles = 5.0;
          attackInterval = 0.7;
          damage = 75.0;
        }
        break;

      case PlantType.electricShroom:
        if (level == 1) {
          rangeInTiles = 3.2;
          attackInterval = 0.9;
          damage = 22.0;
        } else if (level == 2) {
          rangeInTiles = 3.5;
          attackInterval = 0.75;
          damage = 32.0;
        } else if (level == 3) {
          rangeInTiles = 4.0;
          attackInterval = 0.6;
          damage = 48.0;
        }
        break;

      case PlantType.starfruit:
        if (level == 1) {
          rangeInTiles = 3.5;
          attackInterval = 1.1;
          damage = 18.0;
        } else if (level == 2) {
          rangeInTiles = 3.5;
          attackInterval = 0.9;
          damage = 26.0;
        } else if (level == 3) {
          rangeInTiles = 4.0;
          attackInterval = 0.75;
          damage = 38.0;
        }
        break;

      case PlantType.melonPult:
        if (level == 1) {
          rangeInTiles = 5.0;
          attackInterval = 2.0;
          damage = 75.0;
        } else if (level == 2) {
          rangeInTiles = 5.0;
          attackInterval = 1.7;
          damage = 110.0;
        } else if (level == 3) {
          rangeInTiles = 6.0;
          attackInterval = 1.4;
          damage = 160.0;
        }
        break;
    }
  }

  /// Factory mapper tạo cấu hình chỉ số chuẩn cho từng PlantType ở Level 1
  factory PlantData.fromType(PlantType type) {
    switch (type) {
      case PlantType.peashooter:
        return PlantData(
          type: type,
          name: 'Peashooter',
          cost: 100,
          rangeInTiles: 4.0, // 128 px
          attackInterval: 1.0,
          damage: 20.0,
          footSpritePath: 'plants/foot_pea_shotter_32x32.png',
          headSpritePath: 'plants/pea_shotter_32x32.png',
          bulletSpritePath: 'bullets/bullet_bean_32x32.png',
          bulletSpeed: 260.0,
        );

      case PlantType.sunflower:
        return PlantData(
          type: type,
          name: 'Sunflower',
          cost: 50,
          rangeInTiles: 0.0,
          attackInterval: 0.0,
          damage: 0.0,
          footSpritePath: 'plants/foot_sun_flower_32x32.png',
          headSpritePath: 'plants/sun_flower_32x32.png',
          goldProduceAmount: 25,
          goldProduceInterval: 6.0,
        );

      case PlantType.clover:
        return PlantData(
          type: type,
          name: 'Clover 3 Lá',
          cost: 125,
          rangeInTiles: 3.5, // 112 px
          attackInterval: 0.8,
          damage: 15.0,
          footSpritePath: 'plants/foot_clover_32x32.png',
          headSpritePath: 'plants/clover_32x32.png',
          bulletSpritePath: 'bullets/bullet_leaf_32x32.png',
          bulletSpeed: 280.0,
        );

      case PlantType.iceShroom:
        return PlantData(
          type: type,
          name: 'Ice-shroom',
          cost: 175,
          rangeInTiles: 3.5, // 112 px
          attackInterval: 1.2,
          damage: 15.0,
          footSpritePath: 'plants/foot_pea_shotter_32x32.png',
          headSpritePath: 'plants/ice_shroom_32x32.png',
          bulletSpritePath: 'bullets/bullet_snow_32x32.png',
          bulletSpeed: 240.0,
          slowFactor: 0.55,
          slowDuration: 2.5,
        );

      case PlantType.firePeashooter:
        return PlantData(
          type: type,
          name: 'Fire Peashooter',
          cost: 175,
          rangeInTiles: 4.0, // 128 px
          attackInterval: 1.0,
          damage: 35.0,
          footSpritePath: 'plants/foot_fire_pea_shotter_32x32.png',
          headSpritePath: 'plants/fire_pea_shotter_64x32.png',
          bulletSpritePath: 'bullets/bullet_bean_fire_64x32.png',
          bulletSpeed: 270.0,
        );

      case PlantType.electricShroom:
        return PlantData(
          type: type,
          name: 'Electric Shroom',
          cost: 150,
          rangeInTiles: 3.2,
          attackInterval: 0.9,
          damage: 22.0,
          footSpritePath: 'plants/foot_pea_shotter_32x32.png',
          headSpritePath: 'plants/ice_shroom_32x32.png',
          bulletSpritePath: 'bullets/bullet_electric_48x32.png',
          bulletSpeed: 300.0,
        );

      case PlantType.starfruit:
        return PlantData(
          type: type,
          name: 'Starfruit',
          cost: 125,
          rangeInTiles: 3.5,
          attackInterval: 1.1,
          damage: 18.0,
          footSpritePath: 'plants/foot_clover_32x32.png',
          headSpritePath: 'plants/clover_32x32.png',
          bulletSpritePath: 'bullets/bullet_star_fruit_32x32.png',
          bulletSpeed: 250.0,
        );

      case PlantType.melonPult:
        return PlantData(
          type: type,
          name: 'Melon-pult',
          cost: 300,
          rangeInTiles: 5.0, // 160 px
          attackInterval: 2.0,
          damage: 75.0,
          footSpritePath: 'plants/foot_melon_pult_32x32.png',
          headSpritePath: 'plants/melon_pult_32x32.png',
          bulletSpritePath: 'bullets/bullet_winter_melon_32x32.png',
          bulletSpeed: 200.0,
          slowFactor: 0.7,
          slowDuration: 2.0,
        );
    }
  }
}
