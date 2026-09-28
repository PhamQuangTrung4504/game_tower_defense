import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../tower_defense_game.dart';
import '../enemy_component.dart';

/// Hiệu ứng kỹ năng Trói Ma Thuật (Magic Bind).
///
/// Khóa chân toàn bộ quái trong vùng 1.5x1.5 ô (48 px) trong 3.0s (Boss: 1.5s).
/// Trừ 20% Max HP quái thường, trừ 8% Max HP đối với Boss.
class MagicBindComponent extends PositionComponent
    with HasGameReference<TowerDefenseGame> {
  MagicBindComponent({
    required Vector2 targetPosition,
  }) : super(
         position: targetPosition.clone(),
         size: Vector2.all(48.0),
         anchor: Anchor.center,
       );

  static const double effectRadius = 48.0; // 1.5 ô (48 px)
  double _lifeTimer = 0.0;
  static const double _maxLifetime = 3.0; // Hiển thị xích trong 3 giây

  Sprite? _bindSprite;

  final Paint _magicRunePaint = Paint()
    ..color = const Color(0x66AB47BC)
    ..style = PaintingStyle.fill;

  final Paint _runeBorderPaint = Paint()
    ..color = const Color(0xFFE040FB)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    try {
      _bindSprite = await game.loadSprite('skills/magic_bind_32x32.png');
    } catch (e) {
      debugPrint('Lỗi tải sprite magic_bind: $e');
    }

    // Kích hoạt sát thương và trói chân tức thời lên toàn bộ quái trong vùng
    _applyBindEffect();
  }

  void _applyBindEffect() {
    for (final child in game.world.children) {
      if (child is EnemyComponent && !child.data.isDead && child.isMounted) {
        final dist = (child.position - position).length;
        if (dist <= effectRadius) {
          if (child.data.isBoss) {
            // Boss: Trừ 8% Max HP, trói tối đa 1.5s
            child.takePercentDamage(0.08);
            child.applyStun(1.5);
          } else {
            // Quái thường: Trừ 20% Max HP, trói 3.0s
            child.takePercentDamage(0.20);
            child.applyStun(3.0);
          }
        }
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lifeTimer += dt;
    if (_lifeTimer >= _maxLifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);
    final pulse = (math.sin(_lifeTimer * 5.0) + 1.0) / 2.0;

    // Vòng ma trận ma thuật phát sáng
    canvas.drawCircle(center, effectRadius * 0.85 + pulse * 3.0, _magicRunePaint);
    canvas.drawCircle(center, effectRadius * 0.85, _runeBorderPaint);

    // Vẽ xích ma thuật
    if (_bindSprite != null) {
      _bindSprite!.render(
        canvas,
        size: Vector2.all(32.0),
        anchor: Anchor.center,
        position: size / 2,
      );
    }
  }
}
