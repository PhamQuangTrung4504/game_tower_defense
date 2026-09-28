import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/enemy_type.dart';
import '../../services/audio_manager.dart';
import '../tower_defense_game.dart';
import 'floating_text_component.dart';

/// Component đại diện cho một thực thể quái vật di chuyển dọc theo Waypoints.
///
/// Tính năng:
/// - Di chuyển từng điểm theo waypoints (pixel tọa độ tâm ô).
/// - Tự động lật mặt trái/phải theo hướng di chuyển (`flipHorizontally`).
/// - Hiển thị Animation 2 frames mượt mà từ assets `assets/enemies/`.
/// - Render thanh máu (HP Bar) trực quan phía trên đầu quái.
/// - Hỗ trợ hiệu ứng nhận sát thương [takeDamage], làm chậm [applySlow], choáng [applyStun], đẩy lùi [pushBack].
/// - Xử lý đặc quyền của Boss Dark Titan: Kháng làm chậm, giảm thời gian trói, phát hào quang tăng tốc cho quái lân cận.
class EnemyComponent extends PositionComponent
    with HasGameReference<TowerDefenseGame> {
  EnemyComponent({
    required this.data,
    required this.waypoints,
    this.onDeath,
    this.onReachedBase,
  }) : super(
         size: Vector2.all(32.0),
         anchor: Anchor.center,
       );

  /// Dữ liệu chỉ số của quái
  final MonsterData data;

  /// Danh sách các điểm mốc quái sẽ đi qua (tọa độ pixel tâm ô)
  final List<Vector2> waypoints;

  /// Callback khi quái bị tiêu diệt
  final void Function(EnemyComponent enemy)? onDeath;

  /// Callback khi quái chạm tới nhà chính (Căn cứ ID 99)
  final void Function(EnemyComponent enemy)? onReachedBase;

  /// Chỉ mục waypoint mục tiêu quái đang hướng tới
  int _currentWaypointIndex = 0;

  /// Cờ xác định quái đã chết hoặc đã chạm nhà chính
  bool _isRemoved = false;

  /// Hệ số làm chậm (1.0 = bình thường, < 1.0 = bị làm chậm)
  double _slowFactor = 1.0;

  /// Thời gian còn lại của hiệu ứng làm chậm
  double _slowTimer = 0.0;

  /// Thời gian còn lại của hiệu ứng choáng / trói chân (bất động)
  double stunTimer = 0.0;

  /// Hệ số tăng tốc độ từ hào quang của Boss Dark Titan (1.0 = bình thường, 1.2 = +20%)
  double speedBuffMultiplier = 1.0;
  /// Thời gian còn lại của hiệu ứng tăng tốc
  double _speedBuffTimer = 0.0;

  /// Bộ đếm chớp trắng khi nhận đòn (Hit Flash)
  double _hitFlashTimer = 0.0;
  double get hitFlashTimer => _hitFlashTimer;

  /// Animation Component con
  SpriteAnimationComponent? _animComponent;

  // Paints cho thanh máu (HP Bar)
  final Paint _hpBarBgPaint = Paint()
    ..color = const Color(0xCC000000)
    ..style = PaintingStyle.fill;

  final Paint _hpBarBorderPaint = Paint()
    ..color = const Color(0xFF333333)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  final Paint _hpFillRedPaint = Paint()
    ..color = const Color(0xFFE53935)
    ..style = PaintingStyle.fill;

  final Paint _hpFillGreenPaint = Paint()
    ..color = const Color(0xFF4CAF50)
    ..style = PaintingStyle.fill;

  final Paint _slowAuraPaint = Paint()
    ..color = const Color(0x6600E5FF)
    ..style = PaintingStyle.fill;

  final Paint _stunBindPaint = Paint()
    ..color = const Color(0x99FFD600)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  final Paint _bossAuraPaint = Paint()
    ..color = const Color(0x33E53935)
    ..style = PaintingStyle.fill;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Đặt vị trí ban đầu tại waypoint đầu tiên (Cổng Spawn)
    if (waypoints.isNotEmpty) {
      position = waypoints.first.clone();
      _currentWaypointIndex = 1;
    }

    // Tải Animation 2 frames từ assets
    try {
      final animation = await game.loadSpriteAnimation(
        data.spritePath,
        SpriteAnimationData.sequenced(
          amount: 2,
          stepTime: data.stepTime,
          textureSize: data.frameSize,
        ),
      );

      final renderSize = data.frameSize * data.renderScale;
      _animComponent = SpriteAnimationComponent(
        animation: animation,
        size: renderSize,
        anchor: Anchor.center,
        position: size / 2,
      );
      await add(_animComponent!);
    } catch (e) {
      debugPrint('Lỗi tải animation cho quái ${data.name}: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isRemoved) return;

    // 1. Cập nhật thời gian chớp trắng (Hit Flash)
    if (_hitFlashTimer > 0) {
      _hitFlashTimer -= dt;
      if (_hitFlashTimer <= 0) {
        _hitFlashTimer = 0.0;
      }
    }

    // 2. Cập nhật thời gian choáng / trói chân
    if (stunTimer > 0) {
      stunTimer -= dt;
      if (stunTimer <= 0) {
        stunTimer = 0.0;
      }
    }

    // 2. Cập nhật hiệu ứng làm chậm
    if (_slowTimer > 0) {
      _slowTimer -= dt;
      if (_slowTimer <= 0) {
        _slowFactor = 1.0;
      }
    }

    // 3. Cập nhật buff tốc độ từ hào quang Boss
    if (_speedBuffTimer > 0) {
      _speedBuffTimer -= dt;
      if (_speedBuffTimer <= 0) {
        speedBuffMultiplier = 1.0;
      }
    }

    // 4. Nếu là Boss Dark Titan -> Tỏa hào quang tăng tốc cho quái đồng minh xung quanh
    if (data.isBoss && isMounted) {
      _emitBossAura();
    }

    // 5. Nếu đang bị trói / choáng -> không di chuyển
    if (stunTimer > 0) {
      return;
    }

    // 6. Di chuyển dọc theo waypoints
    _moveAlongPath(dt);
  }

  /// Cơ chế Hào quang (Aura) của Boss Dark Titan: Tăng 20% tốc độ cho quái lân cận trong 2 ô (64px)
  void _emitBossAura() {
    const auraRadius = 64.0; // 2 ô
    for (final child in game.world.children) {
      if (child is EnemyComponent && child != this && !child.data.isDead) {
        final dist = (child.position - position).length;
        if (dist <= auraRadius) {
          child.applySpeedBuff(1.2, 0.4); // Tăng 20% tốc độ trong 0.4s (làm mới liên tục)
        }
      }
    }
  }

  /// Nhận buff tăng tốc từ hào quang
  void applySpeedBuff(double multiplier, double duration) {
    speedBuffMultiplier = multiplier;
    _speedBuffTimer = duration;
  }

  /// Thuật toán di chuyển mượt mà bám theo danh sách waypoints
  void _moveAlongPath(double dt) {
    if (_currentWaypointIndex >= waypoints.length) {
      _reachBase();
      return;
    }

    final target = waypoints[_currentWaypointIndex];
    final diff = target - position;
    final distance = diff.length;

    // Tốc độ hiện tại: tính cả làm chậm và buff hào quang
    final currentSpeed = data.basePixelSpeed * _slowFactor * speedBuffMultiplier;
    final stepDistance = currentSpeed * dt;

    // Xử lý xoay hướng mặt quái (lật ngang)
    if (diff.x < -0.5) {
      _animComponent?.scale.x = -1.0;
    } else if (diff.x > 0.5) {
      _animComponent?.scale.x = 1.0;
    }

    // Nếu khoảng cách tới waypoint mục tiêu nhỏ hơn 1 bước đi hoặc < 2px
    if (distance <= stepDistance || distance < 2.0) {
      position = target.clone();
      _currentWaypointIndex++;

      if (_currentWaypointIndex >= waypoints.length) {
        _reachBase();
      }
    } else {
      final direction = diff.normalized();
      position += direction * stepDistance;
    }
  }

  /// Áp dụng hiệu ứng choáng / khóa chân (Stun / Bind)
  void applyStun(double duration) {
    if (_isRemoved || data.isDead) return;

    // Boss Dark Titan kháng khống chế: Giới hạn trói tối đa 1.5s
    if (data.isBoss) {
      stunTimer = duration.clamp(0.0, 1.5);
    } else {
      stunTimer = duration;
    }
  }

  /// Đẩy lùi quái ngược lại trên đường đi (Dành cho Lốc Xoáy)
  void pushBack(double pushDistance) {
    if (_isRemoved || data.isDead) return;

    // Boss Dark Titan chỉ bị khựng 0.3s, không bị đẩy lùi xa
    if (data.isBoss) {
      applyStun(0.3);
      return;
    }

    // Quái thường: Đẩy lùi về phía waypoint trước (ngược hướng di chuyển)
    // Trong Màn 1 đường thẳng từ x=16 tới x=624 (sang phải), đẩy lùi = trừ tọa độ X
    final minX = waypoints.isNotEmpty ? waypoints.first.x : 16.0;
    position.x = (position.x - pushDistance).clamp(minX, 624.0);

    // Choáng nhẹ 1.0s sau khi bị lốc hất tung
    applyStun(1.0);
  }

  /// Quái nhận sát thương
  void takeDamage(double damage, {bool isDot = false}) {
    if (_isRemoved || data.isDead) return;

    double actualDamage = damage;
    // Giáp giảm 25% sát thương nếu có cờ isShielded
    if (data.isShielded) {
      actualDamage *= 0.75;
    }

    data.currentHp = (data.currentHp - actualDamage).clamp(0.0, data.maxHp);
    _hitFlashTimer = 0.08;

    // Hiển thị Floating Text số sát thương khi component đã mount vào game
    if (isMounted && actualDamage > 0) {
      try {
        game.world.add(
          FloatingTextComponent.damage(
            position: position + Vector2(0, -10),
            damage: actualDamage.round(),
            isDot: isDot,
          ),
        );
      } catch (_) {}
    }

    if (data.currentHp <= 0.0) {
      _die();
    }
  }

  /// Nhận sát thương theo % lượng máu tối đa (Dành cho Trói Ma Thuật)
  void takePercentDamage(double percent, {bool isDot = true}) {
    takeDamage(data.maxHp * percent, isDot: isDot);
  }

  /// Áp dụng hiệu ứng làm chậm
  void applySlow(double factor, double duration) {
    if (_isRemoved || data.isDead) return;

    // ĐẶC QUYỀN BOSS DARK TITAN: Kháng 100% hiệu ứng làm chậm từ đạn băng
    if (data.isBoss) {
      return;
    }

    _slowFactor = factor.clamp(0.2, 1.0);
    _slowTimer = duration;
  }

  /// Xử lý khi quái hết máu
  void _die() {
    if (_isRemoved) return;
    _isRemoved = true;

    // Nếu game đang trong thời gian hiệu lực Bão Vàng (Golden Storm): Thưởng x1.5 Gold
    int reward = data.goldReward;
    if (isMounted) {
      try {
        if (game.isGoldenStormActive) {
          reward = (reward * 1.5).round();
        }
        game.addGold(reward);
        game.world.add(
          FloatingTextComponent.gold(
            position: position + Vector2(0, -12),
            gold: reward,
          ),
        );
      } catch (_) {
        game.addGold(reward);
      }
    } else {
      try {
        game.addGold(reward);
      } catch (_) {}
    }

    onDeath?.call(this);
    AudioManager.instance.playEnemyDeathSfx();
    AudioManager.instance.playCoinSfx();
    removeFromParent();
  }

  /// Xử lý khi quái chạm Căn Cứ Nhà Chính
  void _reachBase() {
    if (_isRemoved) return;
    _isRemoved = true;

    // Boss trừ 5 máu, quái thường trừ 1 máu
    final damageToBase = data.isBoss ? 5 : 1;
    if (isMounted) {
      try {
        game.takeBaseDamage(damageToBase);
      } catch (_) {}
    }

    onReachedBase?.call(this);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    // 1. Vẽ vòng hào quang uy lực nếu là Boss Dark Titan
    if (data.isBoss) {
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x * 0.7,
        _bossAuraPaint,
      );
    }

    // 2. Vẽ vầng hào quang băng giá nếu đang bị làm chậm
    if (_slowTimer > 0) {
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x * 0.45,
        _slowAuraPaint,
      );
    }

    super.render(canvas);

    // 3. Hiệu ứng chớp trắng khi trúng đòn (Hit Flash)
    if (_hitFlashTimer > 0) {
      final flashRect = Rect.fromCenter(
        center: Offset(size.x / 2, size.y / 2),
        width: size.x * 0.85,
        height: size.y * 0.85,
      );
      final flashPaint = Paint()
        ..color = const Color(0xCCFFFFFF)
        ..style = PaintingStyle.fill;
      canvas.drawRect(flashRect, flashPaint);
    }

    // 4. Vẽ hiệu ứng xích ma thuật nếu đang bị choáng / trói chân
    if (stunTimer > 0) {
      final rect = Rect.fromCenter(
        center: Offset(size.x / 2, size.y / 2),
        width: size.x * 0.8,
        height: size.y * 0.8,
      );
      canvas.drawOval(rect, _stunBindPaint);
    }

    // 4. Vẽ thanh máu (HP Bar) phía trên đầu quái
    _renderHpBar(canvas);
  }

  /// Vẽ thanh máu trực quan
  void _renderHpBar(Canvas canvas) {
    // Luôn hiển thị thanh máu cho Boss, còn quái thường chỉ hiện khi mất máu
    if (!data.isBoss && data.hpPercent >= 1.0) return;

    final barWidth = data.isBoss ? 36.0 : 22.0;
    final barHeight = data.isBoss ? 4.0 : 3.0;
    final barX = (size.x - barWidth) / 2;
    final barY = data.isBoss ? -7.0 : -4.0;

    // Nền đen mờ
    final bgRect = Rect.fromLTWH(barX, barY, barWidth, barHeight);
    canvas.drawRect(bgRect, _hpBarBgPaint);

    // Nền đỏ
    canvas.drawRect(bgRect, _hpFillRedPaint);

    // Máu xanh còn lại (hoặc vàng ánh kim cho Boss)
    final fillWidth = barWidth * data.hpPercent;
    if (fillWidth > 0) {
      final fillRect = Rect.fromLTWH(barX, barY, fillWidth, barHeight);
      final paint = data.isBoss
          ? (Paint()..color = const Color(0xFFFFD54F))
          : _hpFillGreenPaint;
      canvas.drawRect(fillRect, paint);
    }

    // Viền ngoài thanh máu
    canvas.drawRect(bgRect, _hpBarBorderPaint);
  }
}
