import 'package:flutter_test/flutter_test.dart';
import 'package:game_tower_defense/main.dart';
import 'package:game_tower_defense/services/audio_manager.dart';
import 'package:game_tower_defense/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.init();
    await AudioManager.instance.init();
  });

  testWidgets('App khởi chạy bình thường với Main Menu và chuyển sang Game HUD', (WidgetTester tester) async {
    await tester.pumpWidget(const TowerDefenseApp());
    await tester.pump();

    // 1. Kiểm tra màn hình Main Menu hiển thị tiêu đề và các nút
    expect(find.text('PLANTS VS MONSTERS'), findsOneWidget);
    expect(find.text('TOWER DEFENSE'), findsOneWidget);
    expect(find.textContaining('CHIẾN DỊCH'), findsOneWidget);
    expect(find.textContaining('CHỌN MÀN CHƠI'), findsOneWidget);
    expect(find.textContaining('BÁCH KHOA TOÀN THƯ'), findsOneWidget);
    expect(find.textContaining('CÀI ĐẶT TRÒ CHƠI'), findsOneWidget);

    // 2. Nhấn nút Chiến Dịch để vào trận đấu
    await tester.tap(find.textContaining('CHIẾN DỊCH'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 3. Kiểm tra đã chuyển sang Gameplay và hiển thị các chỉ số HUD
    expect(find.textContaining('WAVE 1/4'), findsOneWidget);
    expect(find.textContaining('10 HP'), findsOneWidget);
    expect(find.textContaining('200 G'), findsOneWidget);
  });
}
