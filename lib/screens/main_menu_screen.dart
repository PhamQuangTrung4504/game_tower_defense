import 'package:flutter/material.dart';
import '../models/level_config.dart';
import '../services/storage_service.dart';

/// Màn hình chính (Main Title / Main Menu Screen) phong cách Retro Pixel Art.
///
/// Cung cấp giao diện đón tiếp người chơi ấn tượng với các tùy chọn:
/// - Chơi tiếp chiến dịch (Màn cao nhất đã mở khóa)
/// - Bảng chọn màn chơi (1 đến 8)
/// - Bách khoa toàn thư tra cứu Trụ & Quái
/// - Hộp thoại Cài đặt (BGM, SFX, Reset dữ liệu)
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({
    super.key,
    required this.onStartGame,
    required this.onOpenSettings,
    required this.onOpenEncyclopedia,
  });

  /// Callback khởi chạy trận đấu với số màn cụ thể
  final void Function(int levelNumber) onStartGame;

  /// Callback mở hộp thoại Cài đặt
  final VoidCallback onOpenSettings;

  /// Callback mở hộp thoại Bách khoa toàn thư
  final VoidCallback onOpenEncyclopedia;

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with SingleTickerProviderStateMixin {
  bool _showLevelSelect = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  int get _highestLevel => StorageService.instance.loadHighestUnlockedLevel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          // Nền trang trí lưới ma trận pixel cổ điển
          Positioned.fill(
            child: CustomPaint(
              painter: _GridBackgroundPainter(),
            ),
          ),

          // Nội dung chính của Menu (Căn giữa)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // TIÊU ĐỀ GAME PHONG CÁCH RETRO GLOW
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B3A4B),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF00E5FF), width: 1.2),
                          ),
                          child: const Text(
                            '★ 2D PIXEL TACTICAL DEFENSE ★',
                            style: TextStyle(
                              fontSize: 9.5,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00E5FF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'PLANTS VS MONSTERS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.8,
                            color: Color(0xFF76FF03),
                            shadows: [
                              Shadow(color: Color(0xFF1B5E20), offset: Offset(2, 2), blurRadius: 4),
                              Shadow(color: Color(0xFF76FF03), offset: Offset(0, 0), blurRadius: 16),
                            ],
                          ),
                        ),
                        const Text(
                          'TOWER DEFENSE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3.5,
                            color: Color(0xFFFFD54F),
                            shadows: [
                              Shadow(color: Color(0xFFE65100), offset: Offset(1.5, 1.5), blurRadius: 2),
                              Shadow(color: Color(0xFFFFD54F), offset: Offset(0, 0), blurRadius: 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // KHỐI CÁC NÚT ĐIỀU HƯỚNG CHÍNH
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Column(
                      children: [
                        // Nút 1: BẮT ĐẦU / TIẾP TỤC CHIẾN DỊCH
                        _buildMenuButton(
                          label: 'CHIẾN DỊCH (MÀN $_highestLevel)',
                          icon: Icons.play_arrow_rounded,
                          primaryColor: const Color(0xFF00C853),
                          accentColor: const Color(0xFFB9F6CA),
                          isProminent: true,
                          onPressed: () {
                            widget.onStartGame(_highestLevel);
                          },
                        ),
                        const SizedBox(height: 8),

                        // Nút 2: BẢNG CHỌN MÀN CHƠI
                        _buildMenuButton(
                          label: 'CHỌN MÀN CHƠI (1 - 8)',
                          icon: Icons.map_outlined,
                          primaryColor: const Color(0xFF0091EA),
                          accentColor: const Color(0xFF80D8FF),
                          onPressed: () {
                            setState(() {
                              _showLevelSelect = true;
                            });
                          },
                        ),
                        const SizedBox(height: 8),

                        // Nút 3: BÁCH KHOA TOÀN THƯ (TRỤ & QUÁI)
                        _buildMenuButton(
                          label: 'BÁCH KHOA TOÀN THƯ',
                          icon: Icons.menu_book_rounded,
                          primaryColor: const Color(0xFFFF8F00),
                          accentColor: const Color(0xFFFFE082),
                          onPressed: widget.onOpenEncyclopedia,
                        ),
                        const SizedBox(height: 8),

                        // Nút 4: CÀI ĐẶT
                        _buildMenuButton(
                          label: 'CÀI ĐẶT TRÒ CHƠI',
                          icon: Icons.settings_rounded,
                          primaryColor: const Color(0xFF546E7A),
                          accentColor: const Color(0xFFCFD8DC),
                          onPressed: widget.onOpenSettings,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // FOOTER THÔNG TIN PHIÊN BẢN VÀ TIẾN ĐỘ
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield_outlined, size: 11, color: Color(0xFF76FF03)),
                            const SizedBox(width: 4),
                            Text(
                              'Tiến độ mở khóa: $_highestLevel / 8 Màn',
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: Color(0xFFB0BEC5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'v1.0.0 (Release Edition)',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white30,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // OVERLAY BẢNG CHỌN MÀN CHƠI (KHI BẤM NÚT CHỌN MÀN)
          if (_showLevelSelect)
            _buildLevelSelectModal(),
        ],
      ),
    );
  }

  /// Nút bấm Menu phong cách Pixel viền Neon
  Widget _buildMenuButton({
    required String label,
    required IconData icon,
    required Color primaryColor,
    required Color accentColor,
    required VoidCallback onPressed,
    bool isProminent = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(7),
        splashColor: primaryColor.withValues(alpha: 0.4),
        child: Ink(
          decoration: BoxDecoration(
            color: isProminent ? primaryColor.withValues(alpha: 0.85) : const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: isProminent ? accentColor : primaryColor.withValues(alpha: 0.6),
              width: isProminent ? 1.6 : 1.2,
            ),
            boxShadow: [
              if (isProminent)
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.45),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: isProminent ? Colors.white : accentColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isProminent ? Colors.white : const Color(0xFFECEFF1),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Modal chọn màn chơi trực tiếp từ Main Menu
  Widget _buildLevelSelectModal() {
    final highestUnlocked = _highestLevel;

    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      alignment: Alignment.center,
      child: Container(
        width: 480,
        height: 310,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141923),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00E5FF), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Tiêu đề & Nút đóng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.map, color: Color(0xFF00E5FF), size: 18),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'BẢN ĐỒ CHIẾN DỊCH (8 MÀN CHƠI)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00E5FF),
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showLevelSelect = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.white70),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 14),

            // Lưới 8 màn chơi
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.15,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 8,
                itemBuilder: (context, index) {
                  final levelNum = index + 1;
                  final isUnlocked = levelNum <= highestUnlocked;
                  final config = LevelConfig.getLevel(levelNum);

                  return GestureDetector(
                    onTap: isUnlocked
                        ? () {
                            setState(() {
                              _showLevelSelect = false;
                            });
                            widget.onStartGame(levelNum);
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isUnlocked ? const Color(0xFF1B2A38) : const Color(0x3312151B),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isUnlocked ? const Color(0xFF00E5FF) : Colors.white12,
                          width: isUnlocked ? 1.4 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isUnlocked ? Icons.play_circle_fill : Icons.lock,
                            color: isUnlocked ? const Color(0xFF00E5FF) : Colors.white24,
                            size: 22,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'MÀN $levelNum',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? Colors.white : Colors.white30,
                            ),
                          ),
                          Text(
                            config.title.replaceFirst('Màn $levelNum: ', ''),
                            style: TextStyle(
                              fontSize: 7.5,
                              color: isUnlocked ? const Color(0xFFFFD54F) : Colors.white24,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vẽ nền lưới mờ phong cách pixel
class _GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0C00E5FF)
      ..strokeWidth = 1.0;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
