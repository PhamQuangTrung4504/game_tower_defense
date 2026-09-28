/// Enum định danh 4 kỹ năng chủ động của người chơi
enum SkillType {
  goldenStorm('Bão Vàng', 'skills/button_skill_gold_treasure_32x32.png', 40.0, 30.0),
  tornado('Lốc Xoáy', 'skills/button_skill_tornado_32x32.png', 50.0, 25.0),
  magicBind('Trói Ma Thuật', 'skills/button_magic_bind_32x32.png', 45.0, 20.0),
  meteorite('Thiên Thạch Rơi', 'skills/button_meteorite_32x32.png', 75.0, 40.0);

  const SkillType(this.name, this.iconAssetPath, this.manaCost, this.cooldown);

  final String name;
  final String iconAssetPath;
  final double manaCost;
  final double cooldown;

  /// Kỹ năng có cần người chơi chọn tọa độ trên bản đồ hay không
  bool get requiresTargetPosition =>
      this == SkillType.magicBind || this == SkillType.meteorite;
}

/// Model quản lý dữ liệu và thời gian hồi chiêu (Cooldown) của một kỹ năng
class SkillData {
  SkillData(this.type)
      : name = type.name,
        iconAssetPath = type.iconAssetPath,
        manaCost = type.manaCost,
        cooldown = type.cooldown;

  final SkillType type;
  final String name;
  final String iconAssetPath;
  final double manaCost;
  final double cooldown;

  /// Thời gian hồi chiêu còn lại (giây). = 0 nghĩa là sẵn sàng
  double currentCooldown = 0.0;

  /// Kiểm tra kỹ năng đã hồi xong hay chưa
  bool get isReady => currentCooldown <= 0.0;

  /// Tỷ lệ hồi chiêu còn lại (0.0..1.0) dùng để vẽ overlay mờ
  double get cooldownProgress =>
      cooldown > 0 ? (currentCooldown / cooldown).clamp(0.0, 1.0) : 0.0;

  /// Cập nhật bộ đếm thời gian hồi chiêu theo delta time
  void update(double dt) {
    if (currentCooldown > 0) {
      currentCooldown = (currentCooldown - dt).clamp(0.0, cooldown);
    }
  }

  /// Kích hoạt hồi chiêu sau khi thi triển
  void startCooldown() {
    currentCooldown = cooldown;
  }

  /// Reset hồi chiêu tức thì (phục vụ test hoặc buff)
  void resetCooldown() {
    currentCooldown = 0.0;
  }
}
