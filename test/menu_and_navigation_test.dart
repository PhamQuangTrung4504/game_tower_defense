import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tower_defense/main.dart';
import 'package:game_tower_defense/models/enemy_type.dart';
import 'package:game_tower_defense/models/plant_data.dart';
import 'package:game_tower_defense/screens/encyclopedia_modal.dart';
import 'package:game_tower_defense/screens/main_menu_screen.dart';
import 'package:game_tower_defense/screens/settings_modal.dart';
import 'package:game_tower_defense/services/audio_manager.dart';
import 'package:game_tower_defense/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'highest_unlocked_level': 3,
      'bgm_enabled': true,
      'sfx_enabled': true,
    });
    await StorageService.instance.init();
    await AudioManager.instance.init();
  });

  group('MainMenuScreen Tests', () {
    testWidgets('Hiển thị đầy đủ tiêu đề và các nút chức năng chính', (tester) async {
      int? startedLevel;
      bool settingsOpened = false;
      bool encyclopediaOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MainMenuScreen(
            onStartGame: (lvl) => startedLevel = lvl,
            onOpenSettings: () => settingsOpened = true,
            onOpenEncyclopedia: () => encyclopediaOpened = true,
          ),
        ),
      );
      await tester.pump();

      // Kiểm tra tiêu đề
      expect(find.text('PLANTS VS MONSTERS'), findsOneWidget);
      expect(find.text('TOWER DEFENSE'), findsOneWidget);

      // Kiểm tra các nút bấm
      expect(find.textContaining('CHIẾN DỊCH (MÀN 3)'), findsOneWidget);
      expect(find.textContaining('CHỌN MÀN CHƠI (1 - 8)'), findsOneWidget);
      expect(find.textContaining('BÁCH KHOA TOÀN THƯ'), findsOneWidget);
      expect(find.textContaining('CÀI ĐẶT TRÒ CHƠI'), findsOneWidget);

      // Nhấn nút Chiến dịch
      await tester.tap(find.textContaining('CHIẾN DỊCH (MÀN 3)'));
      expect(startedLevel, equals(3));

      // Nhấn nút Bách khoa
      await tester.tap(find.textContaining('BÁCH KHOA TOÀN THƯ'));
      expect(encyclopediaOpened, isTrue);

      // Nhấn nút Cài đặt
      await tester.tap(find.textContaining('CÀI ĐẶT TRÒ CHƠI'));
      expect(settingsOpened, isTrue);
    });

    testWidgets('Mở Level Select Modal từ Main Menu và chọn màn chơi đã mở khóa', (tester) async {
      int? startedLevel;

      await tester.pumpWidget(
        MaterialApp(
          home: MainMenuScreen(
            onStartGame: (lvl) => startedLevel = lvl,
            onOpenSettings: () {},
            onOpenEncyclopedia: () {},
          ),
        ),
      );
      await tester.pump();

      // Mở bảng chọn màn
      await tester.tap(find.textContaining('CHỌN MÀN CHƠI (1 - 8)'));
      await tester.pump();

      expect(find.text('BẢN ĐỒ CHIẾN DỊCH (8 MÀN CHƠI)'), findsOneWidget);
      expect(find.text('MÀN 1'), findsOneWidget);
      expect(find.text('MÀN 2'), findsOneWidget);
      expect(find.text('MÀN 3'), findsOneWidget);
      expect(find.text('MÀN 4'), findsOneWidget);

      // Chọn Màn 2 (đã mở khóa vì highest = 3)
      await tester.tap(find.text('MÀN 2'));
      await tester.pump();

      expect(startedLevel, equals(2));
    });
  });

  group('EncyclopediaModal Tests', () {
    testWidgets('Tra cứu các loại trụ và quái vật trong Encyclopedia', (tester) async {
      bool closed = false;

      // Xác nhận đủ 8 loại trụ và 10 loại quái trong data model
      expect(PlantType.values.length, equals(8));
      expect(EnemyType.values.length, equals(10));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EncyclopediaModal(
              onClose: () => closed = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('BÁCH KHOA TOÀN THƯ CHIẾN THUẬT'), findsOneWidget);
      expect(find.text('TRỤ PHÒNG THỦ (8 LOÀI)'), findsOneWidget);
      expect(find.text('QUÁI VẬT TẤN CÔNG (10 LOÀI)'), findsOneWidget);

      // Kiểm tra trong Tab Trụ: các trụ xuất hiện
      expect(find.text('Peashooter'), findsWidgets);
      expect(find.text('Sunflower'), findsWidgets);

      // Chuyển sang Tab Quái vật
      await tester.tap(find.text('QUÁI VẬT TẤN CÔNG (10 LOÀI)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Kiểm tra trong Tab Quái: quái vật xuất hiện
      expect(find.text('Green Slime'), findsWidgets);
      expect(find.text('Purple Snake'), findsWidgets);

      // Nhấn nút Đóng
      await tester.tap(find.byIcon(Icons.close));
      expect(closed, isTrue);
    });
  });

  group('SettingsModal Tests', () {
    testWidgets('Bật tắt BGM, SFX và đóng modal', (tester) async {
      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsModal(
              onClose: () => closed = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('CÀI ĐẶT TRÒ CHƠI'), findsOneWidget);
      expect(find.textContaining('Nhạc Nền (BGM)'), findsOneWidget);
      expect(find.textContaining('Hiệu Ứng (SFX)'), findsOneWidget);
      expect(find.textContaining('Màn 3 / 8'), findsOneWidget);

      // Nhấn nút Đóng
      await tester.tap(find.text('ĐÓNG'));
      expect(closed, isTrue);
    });
  });

  group('App Navigation Flow Tests', () {
    testWidgets('Luồng điều hướng hoàn chỉnh: Menu -> Trận đấu -> Pause -> Về Menu', (tester) async {
      await tester.pumpWidget(const TowerDefenseApp());
      await tester.pump();

      // 1. Đang ở Main Menu
      expect(find.text('PLANTS VS MONSTERS'), findsOneWidget);

      // 2. Vào trận đấu
      await tester.tap(find.textContaining('CHIẾN DỊCH'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 3. Đã vào trận đấu và hiển thị HUD
      expect(find.textContaining('WAVE 1/4'), findsOneWidget);

      // 4. Mở menu Tạm dừng (Pause)
      await tester.tap(find.text('DỪNG'));
      await tester.pump();

      expect(find.text('TẠM DỪNG TRẬN ĐẤU'), findsOneWidget);
      expect(find.text('VỀ MENU CHÍNH'), findsOneWidget);

      // 5. Bấm Về Menu Chính -> Xuất hiện xác nhận
      await tester.tap(find.text('VỀ MENU CHÍNH'));
      await tester.pump();

      expect(find.text('Rời Khỏi Trận Đấu?'), findsOneWidget);

      // 6. Xác nhận đồng ý Về Menu
      await tester.tap(find.text('VỀ MENU'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 7. Đã quay trở về Main Menu thành công
      expect(find.text('PLANTS VS MONSTERS'), findsOneWidget);
      expect(find.textContaining('CHIẾN DỊCH'), findsOneWidget);
    });
  });
}
