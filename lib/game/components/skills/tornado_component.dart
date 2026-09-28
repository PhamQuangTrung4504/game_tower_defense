import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../tower_defense_game.dart';
import '../enemy_component.dart';

/// Hiệu ứng kỹ năng Lốc Xoáy (Tornado).
///
/// Quét ngược từ Căn Cứ Nhà Chính về Cổng Quái:
/// - Tốc độ: 80 px/s (2.5 ô/s).
/// - Gây 30 sát thương.
/// - Đẩy lùi: Quái nhẹ lùi 3-4 ô, Quái nặng lùi 1 ô (choáng 1s), Boss khựng 0.3s.
class TornadoComponent extends PositionComponent
    with HasGameReference<TowerDefenseGame> {
  TornadoComponent({
    required this.waypoints,
  }) : super(
         size: Vector2.all(32.0),
         anchor: Anchor.center,
       );

  final List<Vector2> waypoints;

  /// Tốc độ di chuyển (80 px/s = 2.5 ô/s)
  static const double moveSpeed = 80.0;

  /// Danh sách các quái đã bị lốc trúng (để tránh gây sát thương lặp nhiều lần)
  final Set<EnemyComponent> _hitEnemies = {};

  int _currentWaypointIndex = 0;
  late SpriteAnimationComponent _animComponent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Điểm bắt đầu là waypoint cuối cùng (Căn cứ nhà chính)
    if (waypoints.isNotEmpty) {
      position = waypoints.last.clone();
      _currentWaypointIndex = waypoints.length - 2; // Đi ngược về điểm trước
    }

    // Tải Animation 2 frame từ assets/skills/tornado_64x32.png
    try {
      final animation = await game.loadSpriteAnimation(
        'skills/tornado_64x32.png',
        SpriteAnimationData.sequenced(
          amount: 2,
          stepTime: 0.15,
          textureSize: Vector2(32, 32),
        ),
      );

      _animComponent = SpriteAnimationComponent(
        animation: animation,
        size: Vector2.all(36.0),
        anchor: Anchor.center,
        position: size / 2,
      );
      await add(_animComponent);
    } catch (e) {
      debugPrint('Lỗi tải animation tornado: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_currentWaypointIndex < 0) {
      removeFromParent();
      return;
    }

    final target = waypoints[_currentWaypointIndex];
    final diff = target - position;
    final distance = diff.length;
    final stepDistance = moveSpeed * dt;

    if (distance <= stepDistance || distance < 2.0) {
      position = target.clone();
      _currentWaypointIndex--;
      if (_currentWaypointIndex < 0) {
        removeFromParent();
        return;
      }
    } else {
      final direction = diff.normalized();
      position += direction * stepDistance;
    }

    // Kiểm tra va chạm với các quái trên đường quét qua
    _checkEnemyCollisions();
  }

  void _checkEnemyCollisions() {
    const hitRadius = 26.0;

    for (final child in game.world.children) {
      if (child is EnemyComponent &&
          !child.data.isDead &&
          child.isMounted &&
          !_hitEnemies.contains(child)) {
        final dist = (child.position - position).length;
        if (dist <= hitRadius) {
          _hitEnemies.add(child);

          // 1. Gây 30 sát thương
          child.takeDamage(30.0);

          // 2. Đẩy lùi:
          if (child.data.isBoss) {
            child.pushBack(0); // Boss khựng 0.3s
          } else if (child.data.maxHp < 100.0) {
            child.pushBack(110.0); // Quái nhẹ lùi 3-4 ô
          } else {
            child.pushBack(32.0); // Quái nặng lùi 1 ô (choáng 1s)
          }
        }
      }
    }
  }
}
