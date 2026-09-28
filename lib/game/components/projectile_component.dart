import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../services/audio_manager.dart';
import '../tower_defense_game.dart';
import 'enemy_component.dart';

/// Component điều khiển đường bay của đạn bắn từ trụ (Plant) tới quái (Enemy).
///
/// Tính năng:
/// - Bay thẳng về phía mục tiêu với vận tốc ổn định.
/// - Tự động xoay góc hình ảnh theo vector vận tốc.
/// - Phát hiện va chạm (hit detection): Gây sát thương và hiệu ứng làm chậm khi trúng đích.
/// - Tự hủy khi trúng quái hoặc bay ra khỏi vùng hiển thị của màn chơi.
class ProjectileComponent extends PositionComponent
    with HasGameReference<TowerDefenseGame> {
  ProjectileComponent({
    required Vector2 startPosition,
    required this.targetEnemy,
    required this.damage,
    required this.speed,
    required this.spritePath,
    this.slowFactor = 1.0,
    this.slowDuration = 0.0,
    Vector2? targetPosition,
  })  : _lastTargetPosition = targetPosition ?? targetEnemy?.position.clone() ?? startPosition.clone(),
        super(
          position: startPosition.clone(),
          size: Vector2.all(16.0),
          anchor: Anchor.center,
        );

  /// Mục tiêu kẻ địch đang hướng tới
  final EnemyComponent? targetEnemy;

  /// Sát thương gây ra khi trúng đích
  final double damage;

  /// Vận tốc bay (pixel/giây)
  final double speed;

  /// Đường dẫn asset hình ảnh đạn
  final String spritePath;

  /// Hệ số làm chậm kẻ địch (nếu có)
  final double slowFactor;

  /// Thời gian hiệu lực làm chậm (giây)
  final double slowDuration;

  /// Vị trí cuối cùng đã biết của mục tiêu (dùng khi mục tiêu bị tiêu diệt giữa đường)
  Vector2 _lastTargetPosition;

  /// Sprite của viên đạn
  Sprite? _bulletSprite;

  /// Thời gian tồn tại tối đa để phòng ngừa đạn bay vĩnh viễn
  double _lifeTimer = 0.0;
  static const double _maxLifetime = 3.0; // 3 giây

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    try {
      _bulletSprite = await game.loadSprite(spritePath);
    } catch (e) {
      debugPrint('Lỗi tải sprite cho đạn $spritePath: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _lifeTimer += dt;
    if (_lifeTimer >= _maxLifetime) {
      removeFromParent();
      return;
    }

    // Nếu mục tiêu còn sống và còn gắn trên màn chơi -> cập nhật vị trí mới nhất
    if (targetEnemy != null && targetEnemy!.isMounted && !targetEnemy!.data.isDead) {
      _lastTargetPosition = targetEnemy!.position.clone();
    }

    final diff = _lastTargetPosition - position;
    final distance = diff.length;

    // Xoay góc đạn theo hướng bay
    if (distance > 0.1) {
      angle = math.atan2(diff.y, diff.x);
    }

    final stepDistance = speed * dt;

    // Kiểm tra va chạm (trúng mục tiêu nếu khoảng cách < 12px hoặc 1 bước di chuyển)
    if (distance <= stepDistance || distance < 12.0) {
      _hitTarget();
      return;
    }

    // Di chuyển tiếp về phía mục tiêu
    final direction = diff.normalized();
    position += direction * stepDistance;

    // Tự hủy nếu bay ra ngoài biên màn hình (640x352 px)
    if (position.x < -32.0 ||
        position.x > 672.0 ||
        position.y < -32.0 ||
        position.y > 384.0) {
      removeFromParent();
    }
  }

  /// Xử lý va chạm khi đạn chạm tới kẻ địch
  void _hitTarget() {
    if (targetEnemy != null && targetEnemy!.isMounted && !targetEnemy!.data.isDead) {
      // Gây sát thương lên quái
      targetEnemy!.takeDamage(damage);
      AudioManager.instance.playHitSfx();

      // Áp dụng hiệu ứng làm chậm nếu có
      if (slowFactor < 1.0 && slowDuration > 0) {
        targetEnemy!.applySlow(slowFactor, slowDuration);
      }
    }

    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_bulletSprite != null) {
      _bulletSprite!.render(
        canvas,
        size: size,
        anchor: Anchor.center,
      );
    } else {
      // Fallback nếu không có sprite: Vẽ viên đạn tròn màu vàng cam
      final paint = Paint()..color = const Color(0xFFFFB300);
      canvas.drawCircle(Offset.zero, size.x / 2, paint);
    }
  }
}
