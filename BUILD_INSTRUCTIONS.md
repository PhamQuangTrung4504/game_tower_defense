# PLANTS VS MONSTERS: TOWER DEFENSE 2D
## TÀI LIỆU HƯỚNG DẪN VẬN HÀNH, KIỂM THỬ VÀ ĐÓNG GÓI PHÁT HÀNH (RELEASE BUILD GUIDE)

---

### 1. TỔNG QUAN DỰ ÁN
- **Tên trò chơi**: Plants vs Monsters: Tower Defense 2D
- **Công nghệ cốt lõi**: Flutter (SDK ^3.8.1) • Flame Engine 1.35.1 • Flame Audio 2.11.14 • SharedPreferences 2.5.3
- **Tỉ lệ khung hình chuẩn**: 20 Cột x 11 Hàng (Mỗi ô 32x32 px, Độ phân giải hiển thị gốc 640x352 px)
- **Định hướng hiển thị**: Khóa xoay ngang (Landscape Only) ở cả tầng Native (Android/iOS/Web) và tầng Flame Engine.

---

### 2. TÍNH NĂNG VÀ HỆ THỐNG ĐÃ HOÀN THIỆN
1. **Hệ Thống 8 Màn Chơi Chiến Dịch (`LevelConfig`)**:
   - Ma trận Tile 20x11, địa hình tùy biến, hệ thống Waypoints dẫn đường thông minh.
   - Mở khóa tuần tự từ Màn 1 đến Màn 8 khi người chơi chiến thắng.
2. **Hệ Thống 8 Loại Trụ Phòng Thủ (`PlantData` & `PlantComponent`)**:
   - Peashooter, Sunflower, Clover 3 Lá, Ice-shroom, Fire Peashooter, Electric Shroom, Starfruit, Melon-pult.
   - Nâng cấp 3 cấp độ (Lv1 -> Lv2 -> Lv3) với huy hiệu và chỉ số thăng tiến rõ rệt.
   - Tính năng bán trụ hoàn lại chuẩn 70% tổng vốn đầu tư.
3. **Hệ Thống 10 Loại Quái Vật & Đại Trùm Boss (`MonsterData` & `EnemyComponent`)**:
   - Quái thường, quái né đạn thẳng, quái bay bỏ qua bẫy, chó săn tốc độ, bọ cạp thiết giáp giảm 50% sát thương vật lý, người máy cuồng nộ, zombie bảo hộ, bóng ma tàng hình.
   - Boss Dark Titan (3000 HP, kháng 100% làm chậm, giảm 50% thời gian trói ma thuật, trừ 5 máu căn cứ).
4. **Hệ Thống 4 Kỹ Năng Chủ Động & Năng Lượng Mana (`SkillData`)**:
   - Bão Vàng (+50% Gold), Lốc Xoáy (đẩy lùi), Trói Ma Thuật (giam chân & sát thương % HP), Thiên Thạch Rơi (AOE hủy diệt).
5. **Nâng Tầm Trải Nghiệm Chiến Đấu (Combat Polish & Game Juice)**:
   - Chữ bay sát thương và tiền vàng (`FloatingTextComponent`).
   - Hiệu ứng chớp trắng khi quái nhận sát thương (`Hit Flash`).
   - Rung lắc màn hình (`Camera Shake`).
   - Tùy chỉnh tốc độ game (`1.0x` / `2.0x`) và tính năng tạm dừng (`Pause`).
6. **Hệ Thống Âm Thanh & Lưu Trữ Tiến Trình Cục Bộ**:
   - Quản lý âm thanh an toàn (`AudioManager`) hỗ trợ BGM và 8 loại SFX fail-safe.
   - Lưu trữ tự động tiến trình màn cao nhất và cài đặt âm thanh qua `shared_preferences`.
7. **Giao Diện Đầu Trận & Bách Khoa Toàn Thư**:
   - Màn hình chính Retro Pixel (`MainMenuScreen`).
   - Bách khoa toàn thư tra cứu chi tiết Trụ & Quái (`EncyclopediaModal`).
   - Hộp thoại Cài đặt (`SettingsModal`).

---

### 3. CÀI ĐẶT MÔI TRƯỜNG & KIỂM TRA PHỤ THUỘC

Trước khi chạy hoặc build ứng dụng, đảm bảo máy phát triển đã cài Flutter SDK và chạy lệnh:
```bash
# Lấy toàn bộ các gói thư viện phụ thuộc
flutter pub get

# Kiểm tra tình trạng môi trường Flutter
flutter doctor
```

---

### 4. LỆNH CHẠY THỬ NGHIỆM (DEBUG / RUN)

#### a. Chạy trên thiết bị di động (Android / iOS / Emulator):
```bash
flutter run
```

#### b. Chạy trên trình duyệt Web (Chrome):
```bash
flutter run -d chrome
```

#### c. Chạy trên Desktop (Windows - nếu đã kích hoạt Desktop Support):
```bash
flutter run -d windows
```

---

### 5. LỆNH ĐÓNG GÓI PHÁT HÀNH (RELEASE BUILD)

#### a. Xuất bản Android APK (Cài đặt trực tiếp):
```bash
# Build một file APK Universal duy nhất
flutter build apk --release

# Hoặc build chia nhỏ theo từng kiến trúc CPU (giảm đáng kể kích thước file cài):
flutter build apk --release --split-per-abi
```
*Đường dẫn file sau khi build hoàn tất:*
`build/app/outputs/flutter-apk/app-release.apk`

#### b. Xuất bản Android App Bundle (.aab - Đưa lên Google Play Store):
```bash
flutter build appbundle --release
```
*Đường dẫn file sau khi build hoàn tất:*
`build/app/outputs/bundle/release/app-release.aab`

#### c. Xuất bản Web (HTML5 / CanvasKit):
```bash
flutter build web --release --web-renderer canvaskit
```
*Đường dẫn thư mục web deploy:*
`build/web/`

#### d. Xuất bản Windows Desktop:
```bash
flutter build windows --release
```
*Đường dẫn thư mục chạy:*
`build/windows/x64/runner/Release/`

---

### 6. CÁC TÍNH NĂNG TIỆN ÍCH KIỂM THỬ TRONG GAME (DEBUG HUD)
Khi đang trong trận đấu, người phát triển và người kiểm thử có thể sử dụng các nút thao tác nhanh trên thanh HUD:
- **`+Slime`**: Lập tức triệu hồi một Green Slime tại điểm xuất phát.
- **`+Zombie`**: Lập tức triệu hồi một Basic Zombie.
- **`+Boss`**: Lập tức triệu hồi Đại Trùm Dark Titan để thử nghiệm hỏa lực phòng thủ.
- **`Lưới: BẬT / TẮT`**: Hiển thị lưới tọa độ 20x11 ô (mỗi ô 32x32 px) để kiểm tra các vị trí đặt trụ hợp lệ và đường đi của quái.
- **`1x / 2x`**: Chuyển đổi tốc độ trận đấu nhanh gấp đôi (hồi Mana nhanh gấp đôi, quái chạy nhanh gấp đôi).
- **`DỪNG / TIẾP TỤC`**: Tạm dừng trận đấu và mở Pause Menu.
- **`📖 (Bách Khoa)`**: Mở nhanh sổ tay bách khoa tra cứu điểm mạnh/yếu của trụ và quái.
- **`⚙️ (Cài Đặt)`**: Mở bảng cấu hình BGM/SFX và nút Reset dữ liệu về Màn 1.

---

### 7. KIỂM THỬ TỰ ĐỘNG & BẢO ĐẢM CHẤT LƯỢNG (QA)

#### a. Chạy toàn bộ Test Suites (10 test suites, 70 unit & widget tests):
```bash
flutter test
```

#### b. Chạy phân tích tĩnh mã nguồn (Static Code Analysis):
```bash
flutter analyze
```
*Yêu cầu tiêu chuẩn:* **0 errors, 0 warnings (No issues found!)**.
