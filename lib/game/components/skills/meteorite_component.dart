import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../tower_defense_game.dart';
import '../enemy_component.dart';

/// Hiệu ứng kỹ năng Thiên Thạch Rơi (Meteorite).
///
/// Sau 0.8s rơi thiên thạch phát nổ vùng 2.5x2.5 ô (50px),
/// gây 300 sát thương tức thời, để lại bãi dung nham đốt tiếp 25 dmg/s trong 3s.
class MeteoriteComponent extends PositionComponent
    with HasGameReference<TowerDefenseGame> {
  MeteoriteComponent({
    required this.targetPosition,
  }) : super(
         position: targetPosition.clone(),
         size: Vector2.all(64.0),
         anchor: Anchor.center,
       );

  final Vector2 targetPosition;

  static const double explosionRadius = 50.0; // 2.5 ô bán kính
  static const double fallDuration = 0.8; // Rơi trong 0.8s
  static const double lavaDuration = 3.0; // Bãi dung nham đốt trong 3s

  double _timer = 0.0;
  bool _hasExploded = false;
  double _lavaTickTimer = 0.0;

  Sprite? _meteoriteSprite;

  late Vector2 _startPosition;
  late Vector2 _currentMeteorPos;

  // Paints cho vụ nổ & dung nham
  final Paint _lavaPaint = Paint()
    ..color = const Color(0x88FF5722)
    ..style = PaintingStyle.fill;

  final Paint _lavaBorderPaint = Paint()
    ..color = const Color(0xFFFF9800)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  final Paint _explosionFlashPaint = Paint()
    ..color = const Color(0xCCFFEB3B)
    ..style = PaintingStyle.fill;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Điểm bắt đầu bay chéo từ trên xuống
    _startPosition = targetPosition + Vector2(-60.0, -120.0);
    _currentMeteorPos = _startPosition.clone();

    try {
      _meteoriteSprite = await game.loadSprite('skills/meteorite_32x32.png');
    } catch (e) {
      debugPrint('Lỗi tải sprite meteorite: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    if (!_hasExploded) {
      // 1. Giai đoạn thiên thạch đang rơi (0.0 .. 0.8s)
      final progress = (_timer / fallDuration).clamp(0.0, 1.0);
      _currentMeteorPos = _startPosition + (targetPosition - _startPosition) * progress;

      if (_timer >= fallDuration) {
        _explode();
      }
    } else {
      // 2. Giai đoạn bãi dung nham đốt cháy (0.0 .. 3.0s)
      final lavaTime = _timer - fallDuration;
      _lavaTickTimer += dt;

      // Mỗi 0.5s gây 12.5 sát thương (tương đương 25 dmg / giây)
      if (_lavaTickTimer >= 0.5) {
        _lavaTickTimer = 0.0;
        _burnEnemiesInLava(12.5);
      }

      if (lavaTime >= lavaDuration) {
        removeFromParent();
      }
    }
  }

  /// Xử lý phát nổ tức thời khi thiên thạch chạm đất
  void _explode() {
    _hasExploded = true;

    // Gây 300 sát thương diện rộng
    for (final child in game.world.children) {
      if (child is EnemyComponent && !child.data.isDead && child.isMounted) {
        final dist = (child.position - targetPosition).length;
        if (dist <= explosionRadius) {
          child.takeDamage(300.0);
        }
      }
    }

    // Kích hoạt rung lắc màn hình (Camera Shake)
    try {
      game.triggerCameraShake(duration: 0.25, intensity: 3.5);
    } catch (_) {}
  }

  /// Đốt sát thương theo thời gian đối với quái đứng trong bãi dung nham
  void _burnEnemiesInLava(double tickDamage) {
    for (final child in game.world.children) {
      if (child is EnemyComponent && !child.data.isDead && child.isMounted) {
        final dist = (child.position - targetPosition).length;
        if (dist <= explosionRadius) {
          child.takeDamage(tickDamage, isDot: true);
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);

    if (!_hasExploded) {
      // Vẽ thiên thạch đang bay
      final localMeteorPos = _currentMeteorPos - targetPosition + size / 2;
      if (_meteoriteSprite != null) {
        _meteoriteSprite!.render(
          canvas,
          position: localMeteorPos,
          size: Vector2.all(32.0),
          anchor: Anchor.center,
        );
      }
    } else {
      // Vẽ bãi dung nham đốt cháy
      final pulse = (math.sin((_timer - fallDuration) * 6.0) + 1.0) / 2.0;

      // Chớp nổ ban đầu
      if (_timer - fallDuration < 0.2) {
        canvas.drawCircle(center, explosionRadius * 1.1, _explosionFlashPaint);
      }

      // Vòng tròn dung nham nóng chảy
      canvas.drawCircle(center, explosionRadius + pulse * 2.0, _lavaPaint);
      canvas.drawCircle(center, explosionRadius, _lavaBorderPaint);
    }
  }
}
