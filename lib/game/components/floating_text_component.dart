import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Component hiển thị chữ số bay (Floating Text) phong cách pixel cho sát thương và tiền vàng.
///
/// Hoạt ảnh:
/// - Bay lên trên [riseDistance] (mặc định 20 px)
/// - Mờ dần độ đậm (Fade out opacity từ 1.0 về 0.0)
/// - Tự hủy [removeFromParent] sau [duration] giây (mặc định 0.6s)
class FloatingTextComponent extends PositionComponent {
  FloatingTextComponent({
    required Vector2 position,
    required this.text,
    required this.color,
    this.duration = 0.6,
    this.riseDistance = 20.0,
    this.fontSize = 10.0,
  })  : _textPainter = TextPainter(textDirection: TextDirection.ltr),
        super(
          position: position.clone(),
          anchor: Anchor.center,
          priority: 100, // Hiển thị trên đầu các entities
        ) {
    _startY = position.y;
  }

  /// Sát thương thông thường (Màu trắng hoặc vàng cam) hoặc sát thương DoT (Màu đỏ cam)
  factory FloatingTextComponent.damage({
    required Vector2 position,
    required int damage,
    bool isDot = false,
  }) {
    return FloatingTextComponent(
      position: position,
      text: '-$damage',
      color: isDot ? const Color(0xFFFF5722) : const Color(0xFFFFFFFF),
      duration: isDot ? 0.5 : 0.6,
      riseDistance: isDot ? 16.0 : 20.0,
      fontSize: isDot ? 9.0 : 10.5,
    );
  }

  /// Số tiền Gold nhận được khi tiêu diệt quái (Màu vàng kim óng ánh)
  factory FloatingTextComponent.gold({
    required Vector2 position,
    required int gold,
  }) {
    return FloatingTextComponent(
      position: position,
      text: '+$gold G',
      color: const Color(0xFFFFD54F),
      duration: 0.7,
      riseDistance: 22.0,
      fontSize: 11.0,
    );
  }

  /// Nội dung văn bản
  final String text;

  /// Màu sắc chính của chữ
  final Color color;

  /// Thời gian sống của chữ trước khi biến mất (giây)
  final double duration;

  /// Quãng đường bay lên trên (pixel)
  final double riseDistance;

  /// Cỡ chữ
  final double fontSize;

  final TextPainter _textPainter;

  double _elapsed = 0.0;
  double _opacity = 1.0;
  late double _startY;

  /// Tiến độ thời gian đã trôi qua (dùng cho Unit Test)
  double get elapsed => _elapsed;

  /// Độ mờ hiện tại (1.0 -> 0.0)
  double get opacity => _opacity;

  @override
  void onMount() {
    super.onMount();
    _startY = position.y;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    if (_elapsed >= duration) {
      removeFromParent();
      return;
    }

    final progress = (_elapsed / duration).clamp(0.0, 1.0);
    _opacity = (1.0 - progress).clamp(0.0, 1.0);
    position.y = _startY - (riseDistance * progress);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_opacity <= 0.01) return;

    _textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color.withValues(alpha: _opacity),
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: _opacity * 0.9),
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );
    _textPainter.layout();
    _textPainter.paint(
      canvas,
      Offset(-_textPainter.width / 2, -_textPainter.height / 2),
    );
  }
}
