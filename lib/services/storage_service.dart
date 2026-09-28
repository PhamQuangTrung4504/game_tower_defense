import 'package:shared_preferences/shared_preferences.dart';

/// Dịch vụ lưu trữ tiến trình trò chơi và cài đặt người dùng cục bộ (Local Persistence).
///
/// Sử dụng SharedPreferences để quản lý:
/// - Màn chơi cao nhất đã mở khóa (`highest_unlocked_level`, mặc định = 1)
/// - Trạng thái bật/tắt nhạc nền BGM (`bgm_enabled`, mặc định = true)
/// - Trạng thái bật/tắt hiệu ứng âm thanh SFX (`sfx_enabled`, mặc định = true)
class StorageService {
  StorageService._internal();

  static final StorageService _instance = StorageService._internal();

  /// Singleton instance
  static StorageService get instance => _instance;

  factory StorageService() => _instance;

  SharedPreferences? _prefs;

  static const String _keyHighestLevel = 'highest_unlocked_level';
  static const String _keyBgmEnabled = 'bgm_enabled';
  static const String _keySfxEnabled = 'sfx_enabled';

  /// Khởi tạo SharedPreferences (hỗ trợ truyền mockPrefs phục vụ Unit Test)
  Future<void> init({SharedPreferences? mockPrefs}) async {
    _prefs = mockPrefs ?? await SharedPreferences.getInstance();
  }

  /// Tải màn chơi cao nhất đã mở khóa (Mặc định: 1)
  int loadHighestUnlockedLevel() {
    return _prefs?.getInt(_keyHighestLevel) ?? 1;
  }

  /// Lưu màn chơi cao nhất đã mở khóa (chỉ lưu nếu level mới lớn hơn level cũ)
  Future<void> saveHighestUnlockedLevel(int level) async {
    final current = loadHighestUnlockedLevel();
    if (level > current) {
      await _prefs?.setInt(_keyHighestLevel, level.clamp(1, 8));
    }
  }

  /// Bắt buộc ghi đè màn cao nhất (dùng khi reset dữ liệu)
  Future<void> forceSetHighestUnlockedLevel(int level) async {
    await _prefs?.setInt(_keyHighestLevel, level.clamp(1, 8));
  }

  /// Tải cài đặt BGM (Mặc định: true)
  bool loadBgmEnabled() {
    return _prefs?.getBool(_keyBgmEnabled) ?? true;
  }

  /// Lưu cài đặt BGM
  Future<void> saveBgmEnabled(bool enabled) async {
    await _prefs?.setBool(_keyBgmEnabled, enabled);
  }

  /// Tải cài đặt SFX (Mặc định: true)
  bool loadSfxEnabled() {
    return _prefs?.getBool(_keySfxEnabled) ?? true;
  }

  /// Lưu cài đặt SFX
  Future<void> saveSfxEnabled(bool enabled) async {
    await _prefs?.setBool(_keySfxEnabled, enabled);
  }

  /// Xóa dữ liệu chơi lại từ đầu (Reset Progress về Màn 1)
  Future<void> resetAllProgress() async {
    await forceSetHighestUnlockedLevel(1);
  }
}
