import 'package:flutter/material.dart';
import '../services/audio_manager.dart';
import '../services/storage_service.dart';

/// Hộp thoại Cài Đặt Trò Chơi (Settings Modal)
///
/// Quản lý bật/tắt nhạc nền (BGM), hiệu ứng âm thanh (SFX)
/// và chức năng xóa dữ liệu tiến trình chơi lại từ đầu.
class SettingsModal extends StatefulWidget {
  const SettingsModal({
    super.key,
    required this.onClose,
    this.onProgressReset,
  });

  final VoidCallback onClose;
  final VoidCallback? onProgressReset;

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  @override
  Widget build(BuildContext context) {
    final highestUnlocked = StorageService.instance.loadHighestUnlockedLevel();

    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        alignment: Alignment.center,
        child: Container(
        width: 330,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.settings, color: Color(0xFF00E5FF), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'CÀI ĐẶT TRÒ CHƠI',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00E5FF),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: widget.onClose,
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

              // Cài đặt Nhạc Nền (BGM)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.music_note, color: Colors.amber, size: 16),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Nhạc Nền (BGM)',
                            style: TextStyle(fontSize: 11, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: AudioManager.instance.bgmEnabled,
                    activeColor: const Color(0xFF00E5FF),
                    activeTrackColor: const Color(0xFF004D40),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) {
                      setState(() {
                        AudioManager.instance.setBgmEnabled(val);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Cài đặt Hiệu Ứng (SFX)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.volume_up, color: Colors.lightGreenAccent, size: 16),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Hiệu Ứng (SFX)',
                            style: TextStyle(fontSize: 11, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: AudioManager.instance.sfxEnabled,
                    activeColor: const Color(0xFF00E5FF),
                    activeTrackColor: const Color(0xFF004D40),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) {
                      setState(() {
                        AudioManager.instance.setSfxEnabled(val);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Hiển thị tiến trình mở khóa
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Tiến Trình Đã Mở:',
                        style: TextStyle(fontSize: 10, color: Color(0xFF90A4AE)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'Màn $highestUnlocked / 8',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD54F),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // Nút Reset Dữ Liệu
            OutlinedButton.icon(
              onPressed: () => _confirmResetProgress(),
              icon: const Icon(Icons.delete_forever, size: 14, color: Color(0xFFFF8A80)),
              label: const Text(
                'XÓA DỮ LIỆU & CHƠI LẠI TỪ ĐẦU',
                style: TextStyle(fontSize: 9.5, color: Color(0xFFFF8A80), fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE53935)),
                backgroundColor: const Color(0x22E53935),
                minimumSize: const Size.fromHeight(32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
            ),
            const SizedBox(height: 8),

            // Nút Đóng
            ElevatedButton(
              onPressed: widget.onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF37474F),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(30),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
              child: const Text('ĐÓNG', style: TextStyle(fontSize: 10)),
            ),
          ],
        ),
      ),
    ),
  ),
);
}

  void _confirmResetProgress() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141923),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE53935), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Color(0xFFE53935), size: 20),
            SizedBox(width: 8),
            Text(
              'Xác Nhận Xóa Dữ Liệu',
              style: TextStyle(fontSize: 14, color: Color(0xFFE53935), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa toàn bộ tiến trình chiến dịch và quay về Màn 1 không? Dữ liệu đã lưu sẽ không thể khôi phục.',
          style: TextStyle(fontSize: 11, color: Color(0xFFB0BEC5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('HỦY', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await StorageService.instance.resetAllProgress();
              if (mounted) {
                setState(() {});
              }
              widget.onProgressReset?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: const Text('ĐỒNG Ý XÓA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
