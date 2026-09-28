import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/plant_data.dart';
import '../../services/audio_manager.dart';
import '../tower_defense_game.dart';
import 'enemy_component.dart';
import 'projectile_component.dart';

/// Component đại diện cho một trụ phòng thủ (Plant) được đặt trên bản đồ.
///
/// Tính năng:
/// - Chân đế cố định (lớp dưới) và đầu súng tự xoay nhắm mục tiêu (lớp trên).
/// - Hiển thị Huy hiệu Cấp độ (Level Badge Lv1..Lv3) ở góc trên-phải của trụ.
/// - Hỗ trợ nâng cấp [upgrade] (tăng tầm bắn, tốc độ, sát thương) và bán trụ [sell] hoàn 70% vàng.
/// - Hỗ trợ cơ chế bắn Double Shot liên tiếp 2 viên đạn cho Peashooter Lv3.
/// - Quét mục tiêu thông minh: Ưu tiên quái gần Căn Cứ Nhà Chính nhất nằm trong tầm bắn.
class PlantComponent extends PositionComponent
    with HasGameReference<TowerDefenseGame> {
  PlantComponent({
    required this.data,
    required this.gridCol,
    required this.gridRow,
  }) : super(
         position: Vector2((gridCol + 0.5) * 32.0, (gridRow + 0.5) * 32.0),
         size: Vector2.all(32.0),
         anchor: Anchor.center,
       );

  /// Dữ liệu cấu hình & chỉ số của loại trụ
  final PlantData data;

  /// Tọa độ cột trên lưới (0..19)
  final int gridCol;

  /// Tọa độ hàng trên lưới (0..10)
  final int gridRow;

  /// Góc xoay của đầu súng (radian)
  double _headAngle = 0.0;

  /// Bộ đếm thời gian hồi bắn
  double _shootTimer = 0.0;

  /// Bộ đếm thời gian sinh vàng (dành cho Sunflower)
  double _produceTimer = 0.0;

  /// Bộ đếm delay cho phát bắn thứ 2 (Double Shot của Peashooter Lv3)
  double _secondShotTimer = 0.0;
  EnemyComponent? _secondShotTarget;

  /// Mục tiêu kẻ địch hiện tại
  EnemyComponent? _currentTarget;

  /// Cờ hiển thị vòng tròn bán kính tầm bắn khi được chọn
  bool isSelected = false;

  /// Sprite chân đế (cố định)
  Sprite? _footSprite;

  /// Sprite đầu súng (xoay theo mục tiêu)
  Sprite? _headSprite;

  /// Sprite huy hiệu cấp độ (lv1, lv2, lv3)
  Sprite? _badgeSprite;

  // Paints vẽ tầm bắn
  final Paint _rangePaint = Paint()
    ..color = const Color(0x3300E5FF)
    ..style = PaintingStyle.fill;

  final Paint _rangeBorderPaint = Paint()
    ..color = const Color(0x9900E5FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    try {
      _footSprite = await game.loadSprite(data.footSpritePath);
      _headSprite = await game.loadSprite(data.headSpritePath);
      await _loadBadgeSprite();
    } catch (e) {
      debugPrint('Lỗi tải sprite cho trụ ${data.name}: $e');
    }

    // Cho phép bắn ngay phát đầu tiên khi có quái trong tầm
    _shootTimer = data.attackInterval;
  }

  /// Nạp sprite huy hiệu cấp độ tương ứng với data.level
  Future<void> _loadBadgeSprite() async {
    if (!isMounted) return;
    try {
      _badgeSprite = await game.loadSprite(data.levelBadgePath);
    } catch (e) {
      debugPrint('Lỗi tải badge level cho trụ ${data.name}: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 1. Xử lý bắn viên đạn thứ 2 nếu đang có hàng đợi Double Shot (Peashooter Lv3)
    if (_secondShotTimer > 0) {
      _secondShotTimer -= dt;
      if (_secondShotTimer <= 0 && _secondShotTarget != null) {
        if (_isTargetValid(_secondShotTarget)) {
          _fireSingleBullet(_secondShotTarget!, 20.0);
        }
        _secondShotTarget = null;
      }
    }

    // 2. Logic sinh vàng cho Sunflower
    if (data.isProducer) {
      _produceTimer += dt;
      if (_produceTimer >= data.goldProduceInterval) {
        _produceTimer = 0.0;
        game.addGold(data.goldProduceAmount);
        AudioManager.instance.playCoinSfx();
      }
      return;
    }

    // 3. Logic tấn công bằng đạn cho các trụ chiến đấu
    if (!data.canAttack) return;

    _shootTimer += dt;

    // Kiểm tra xem mục tiêu hiện tại còn hợp lệ không
    if (!_isTargetValid(_currentTarget)) {
      _currentTarget = _findBestTarget();
    }

    // Nếu có mục tiêu hợp lệ
    if (_currentTarget != null) {
      final diff = _currentTarget!.position - position;
      _headAngle = math.atan2(diff.y, diff.x);

      // Bắn khi hồi chiêu xong
      if (_shootTimer >= data.attackInterval) {
        _shootTimer = 0.0;
        _shootAtTarget(_currentTarget!);
      }
    }
  }

  /// Kiểm tra xem kẻ địch có còn nằm trong tầm bắn và còn sống hay không
  bool _isTargetValid(EnemyComponent? enemy) {
    if (enemy == null || !enemy.isMounted || enemy.data.isDead) {
      return false;
    }
    final distance = (enemy.position - position).length;
    return distance <= data.rangeInPixels;
  }

  /// Tìm kẻ địch nguy hiểm nhất (gần Căn cứ nhà chính nhất) nằm trong tầm bắn
  EnemyComponent? _findBestTarget() {
    final basePos = game.mapData.gridToPixelCenter(19, 5);

    EnemyComponent? bestEnemy;
    double minDistanceToBase = double.infinity;

    for (final child in game.world.children) {
      if (child is EnemyComponent && !child.data.isDead && child.isMounted) {
        final distToPlant = (child.position - position).length;
        if (distToPlant <= data.rangeInPixels) {
          final distToBase = (child.position - basePos).length;
          if (distToBase < minDistanceToBase) {
            minDistanceToBase = distToBase;
            bestEnemy = child;
          }
        }
      }
    }

    return bestEnemy;
  }

  /// Kích hoạt chuỗi tấn công tới kẻ địch mục tiêu
  void _shootAtTarget(EnemyComponent target) {
    if (data.bulletSpritePath == null) return;

    // Peashooter Lv3: Cơ chế bắn Double Shot (2 viên x 20 damage cách nhau 0.1s)
    if (data.type == PlantType.peashooter && data.level == 3) {
      // Viên 1 bắn ngay lập tức
      _fireSingleBullet(target, 20.0);
      // Hẹn giờ bắn viên 2 sau 0.1 giây
      _secondShotTimer = 0.1;
      _secondShotTarget = target;
    } else {
      // Bắn đơn chuẩn với toàn bộ sát thương của cấp độ
      _fireSingleBullet(target, data.damage);
    }
  }

  /// Bắn ra 1 viên đạn đơn với lượng sát thương xác định
  void _fireSingleBullet(EnemyComponent target, double bulletDamage) {
    if (data.bulletSpritePath == null) return;

    final projectile = ProjectileComponent(
      startPosition: position.clone(),
      targetEnemy: target,
      damage: bulletDamage,
      speed: data.bulletSpeed,
      spritePath: data.bulletSpritePath!,
      slowFactor: data.slowFactor,
      slowDuration: data.slowDuration,
    );

    game.world.add(projectile);
    AudioManager.instance.playShootSfx(data.type);
  }

  /// Nâng cấp trụ lên cấp tiếp theo (Level 1 -> 2 -> 3).
  /// Trả về true nếu nâng cấp thành công.
  bool upgrade() {
    if (data.isMaxLevel) return false;

    final cost = data.upgradeCost;
    if (game.playerGold < cost) return false;

    final success = game.spendGold(cost);
    if (!success) return false;

    data.totalInvestedGold += cost;
    data.applyLevel(data.level + 1);

    // Tải lại icon huy hiệu cấp độ mới
    _loadBadgeSprite();

    return true;
  }

  /// Bán trụ và hoàn trả 70% tổng số vàng đã đầu tư.
  /// Trả về số vàng hoàn lại.
  int sell() {
    final refund = data.sellRefund;
    game.addGold(refund);

    // Xóa trụ khỏi danh sách quản lý lưới của game
    game.placedPlants.remove('$gridCol,$gridRow');

    // Bỏ chọn nếu đang mở bảng Inspector của trụ này
    if (game.selectedPlantNotifier.value == this) {
      game.selectedPlantNotifier.value = null;
    }

    removeFromParent();
    return refund;
  }

  @override
  void render(Canvas canvas) {
    // 1. Vẽ vòng tròn tầm bắn nếu trụ đang được chọn
    if (isSelected && data.rangeInPixels > 0) {
      final center = Offset(size.x / 2, size.y / 2);
      canvas.drawCircle(center, data.rangeInPixels, _rangePaint);
      canvas.drawCircle(center, data.rangeInPixels, _rangeBorderPaint);
    }

    // 2. Vẽ chân đế (cố định không xoay)
    if (_footSprite != null) {
      _footSprite!.render(
        canvas,
        size: size,
        anchor: Anchor.center,
        position: size / 2,
      );
    }

    // 3. Vẽ đầu súng (tự động xoay nhắm vào quái)
    if (_headSprite != null) {
      canvas.save();
      canvas.translate(size.x / 2, size.y / 2);
      canvas.rotate(_headAngle);
      _headSprite!.render(
        canvas,
        size: size,
        anchor: Anchor.center,
        position: Vector2.zero(),
      );
      canvas.restore();
    }

    // 4. Vẽ Huy hiệu Cấp độ (Level Badge) ở góc trên-phải của ô trụ
    if (_badgeSprite != null) {
      _badgeSprite!.render(
        canvas,
        position: Vector2(size.x - 13.0, -1.0),
        size: Vector2.all(14.0),
      );
    }

    super.render(canvas);
  }
}
