import 'package:flame/extensions.dart';

/// Enum định danh 10 loại quái vật trong game Tower Defense.
enum EnemyType {
  greenSlime(1, 'Green Slime'),
  purpleSnake(2, 'Purple Snake'),
  redEyedBat(3, 'Red-eyed Bat'),
  purpleHound(4, 'Purple Hound'),
  armoredScorpion(5, 'Armored Scorpion'),
  basicZombie(6, 'Basic Zombie'),
  cyborgRunner(7, 'Cyborg Runner'),
  capZombie(8, 'Cap Zombie'),
  whitePhantom(9, 'White Phantom'),
  darkTitan(10, 'Dark Titan');

  const EnemyType(this.id, this.label);

  final int id;
  final String label;

  static EnemyType fromId(int id) {
    for (final type in EnemyType.values) {
      if (type.id == id) return type;
    }
    return EnemyType.greenSlime;
  }
}

/// Model lưu trữ toàn bộ chỉ số và cờ trạng thái của một cá thể quái vật.
class MonsterData {
  MonsterData({
    required this.type,
    required this.name,
    required this.spritePath,
    required this.frameSize,
    required this.stepTime,
    required this.maxHp,
    required this.currentHp,
    required this.speed,
    required this.goldReward,
    this.canEvadeStraightBullets = false,
    this.isFlying = false,
    this.isEnraged = false,
    this.isShielded = false,
    this.isStealth = false,
    this.isBoss = false,
    this.renderScale = 1.0,
  });

  final EnemyType type;
  final String name;
  final String spritePath;
  final Vector2 frameSize;
  final double stepTime;

  final double maxHp;
  double currentHp;

  /// Tốc độ di chuyển theo đơn vị (ô / giây)
  final double speed;

  /// Số vàng thưởng cho người chơi khi hạ gục quái
  final int goldReward;

  /// Cờ né đạn bay thẳng (Ví dụ: Purple Hound)
  final bool canEvadeStraightBullets;

  /// Quái bay, bỏ qua bẫy mặt đất (Ví dụ: Red-eyed Bat)
  final bool isFlying;

  /// Trạng thái cuồng nộ tăng tốc khi yếu máu (Ví dụ: Cyborg Runner)
  final bool isEnraged;

  /// Quái có giáp giảm sát thương vật lý (Ví dụ: Armored Scorpion)
  final bool isShielded;

  /// Quái tàng hình cần trụ đặc biệt phát hiện (Ví dụ: White Phantom)
  final bool isStealth;

  /// Quái Boss (Ví dụ: Dark Titan) - Trừ 5 máu nhà chính nếu vượt qua
  final bool isBoss;

  /// Tỷ lệ phóng to hiển thị sprite
  final double renderScale;

  /// Tốc độ di chuyển tính theo pixel / giây (speed * 32.0 px)
  double get basePixelSpeed => speed * 32.0;

  /// Phần trăm lượng máu còn lại (0.0 .. 1.0)
  double get hpPercent => (currentHp / maxHp).clamp(0.0, 1.0);

  /// Kiểm tra quái đã hết máu hay chưa
  bool get isDead => currentHp <= 0.0;

  /// Tạo bản sao độc lập với đầy máu để gán vào từng EnemyComponent khi spawn
  MonsterData clone() {
    return MonsterData(
      type: type,
      name: name,
      spritePath: spritePath,
      frameSize: frameSize.clone(),
      stepTime: stepTime,
      maxHp: maxHp,
      currentHp: maxHp,
      speed: speed,
      goldReward: goldReward,
      canEvadeStraightBullets: canEvadeStraightBullets,
      isFlying: isFlying,
      isEnraged: isEnraged,
      isShielded: isShielded,
      isStealth: isStealth,
      isBoss: isBoss,
      renderScale: renderScale,
    );
  }

  /// Factory mapper tạo MonsterData chuẩn theo thiết kế GDD cho từng EnemyType
  factory MonsterData.fromType(EnemyType type) {
    switch (type) {
      case EnemyType.greenSlime:
        return MonsterData(
          type: type,
          name: 'Green Slime',
          spritePath: 'enemies/monster1_48x24.png',
          frameSize: Vector2(24, 24),
          stepTime: 0.22,
          maxHp: 70.0,
          currentHp: 70.0,
          speed: 1.0, // 1 ô/s = 32 px/s
          goldReward: 10,
        );

      case EnemyType.purpleSnake:
        return MonsterData(
          type: type,
          name: 'Purple Snake',
          spritePath: 'enemies/monster2_64x32.png',
          frameSize: Vector2(32, 32),
          stepTime: 0.20,
          maxHp: 100.0,
          currentHp: 100.0,
          speed: 1.1,
          goldReward: 14,
        );

      case EnemyType.redEyedBat:
        return MonsterData(
          type: type,
          name: 'Red-eyed Bat',
          spritePath: 'enemies/monster3_48x24.png',
          frameSize: Vector2(24, 24),
          stepTime: 0.18,
          maxHp: 60.0,
          currentHp: 60.0,
          speed: 1.4,
          goldReward: 12,
          isFlying: true,
        );

      case EnemyType.purpleHound:
        return MonsterData(
          type: type,
          name: 'Purple Hound',
          spritePath: 'enemies/monster4_48x24.png',
          frameSize: Vector2(24, 24),
          stepTime: 0.20,
          maxHp: 90.0,
          currentHp: 90.0,
          speed: 1.3,
          goldReward: 15,
          canEvadeStraightBullets: true,
        );

      case EnemyType.armoredScorpion:
        return MonsterData(
          type: type,
          name: 'Armored Scorpion',
          spritePath: 'enemies/monster5_64x32.png',
          frameSize: Vector2(32, 32),
          stepTime: 0.25,
          maxHp: 180.0,
          currentHp: 180.0,
          speed: 0.75,
          goldReward: 20,
          isShielded: true,
        );

      case EnemyType.basicZombie:
        return MonsterData(
          type: type,
          name: 'Basic Zombie',
          spritePath: 'enemies/monster6_64x32.png',
          frameSize: Vector2(32, 32),
          stepTime: 0.22,
          maxHp: 150.0,
          currentHp: 150.0,
          speed: 0.85,
          goldReward: 18,
        );

      case EnemyType.cyborgRunner:
        return MonsterData(
          type: type,
          name: 'Cyborg Runner',
          spritePath: 'enemies/monster7_64x32.png',
          frameSize: Vector2(32, 32),
          stepTime: 0.18,
          maxHp: 130.0,
          currentHp: 130.0,
          speed: 1.25,
          goldReward: 22,
          isEnraged: true,
        );

      case EnemyType.capZombie:
        return MonsterData(
          type: type,
          name: 'Cap Zombie',
          spritePath: 'enemies/monster8_64x32.png',
          frameSize: Vector2(32, 32),
          stepTime: 0.22,
          maxHp: 200.0,
          currentHp: 200.0,
          speed: 0.80,
          goldReward: 25,
        );

      case EnemyType.whitePhantom:
        return MonsterData(
          type: type,
          name: 'White Phantom',
          spritePath: 'enemies/monster9_64x32.png',
          frameSize: Vector2(32, 32),
          stepTime: 0.20,
          maxHp: 110.0,
          currentHp: 110.0,
          speed: 1.15,
          goldReward: 24,
          isStealth: true,
        );

      case EnemyType.darkTitan:
        return MonsterData(
          type: type,
          name: 'Dark Titan',
          spritePath: 'enemies/monster10_64x32.png',
          frameSize: Vector2(32, 32),
          stepTime: 0.25,
          maxHp: 2200.0,
          currentHp: 2200.0,
          speed: 0.40, // 0.4 ô/s = 12.8 px/s
          goldReward: 180,
          isBoss: true,
          renderScale: 1.3,
        );
    }
  }
}
