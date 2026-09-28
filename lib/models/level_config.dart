import 'package:flame/extensions.dart';
import '../game/components/wave_spawner_component.dart';
import 'enemy_type.dart';
import 'plant_data.dart';
import 'skill_data.dart';

/// Cấu hình dữ liệu chi tiết của một Màn chơi (Level) trong chiến dịch
class LevelConfig {
  LevelConfig({
    required this.levelNumber,
    required this.title,
    required this.startingGold,
    required this.unlockedPlants,
    required this.unlockedSkills,
    required this.tileMatrix,
    required this.waypointsList,
    required this.waveSchedule,
    this.bossType,
  });

  /// Số thứ tự màn chơi (1 đến 8)
  final int levelNumber;

  /// Tên gọi chủ đề của màn chơi
  final String title;

  /// Số vàng khởi đầu của người chơi trong màn này
  final int startingGold;

  /// Danh sách các loại trụ được phép sử dụng ở màn này
  final List<PlantType> unlockedPlants;

  /// Danh sách các kỹ năng được phép sử dụng ở màn này
  final List<SkillType> unlockedSkills;

  /// Ma trận địa hình 20 Cột x 11 Hàng
  final List<List<int>> tileMatrix;

  /// Danh sách các nhánh đường đi (Màn 1-7 có 1 nhánh, Màn 8 có 2 nhánh độc lập)
  final List<List<Vector2>> waypointsList;

  /// Lộ trình các đợt quái xuất hiện theo thời gian
  final List<SpawnEvent> waveSchedule;

  /// Loại Boss đặc biệt xuất hiện ở cuối màn (nếu có)
  final EnemyType? bossType;

  /// Lấy danh sách waypoints theo pixel tâm ô của nhánh đầu tiên
  List<Vector2> get primaryWaypointPixelCenters {
    return waypointsList.first
        .map((wp) => Vector2((wp.x + 0.5) * 32.0, (wp.y + 0.5) * 32.0))
        .toList();
  }

  /// Lấy danh sách waypoints theo pixel tâm ô cho toàn bộ các nhánh
  List<List<Vector2>> get allWaypointsPixelCenters {
    return waypointsList.map((branch) {
      return branch
          .map((wp) => Vector2((wp.x + 0.5) * 32.0, (wp.y + 0.5) * 32.0))
          .toList();
    }).toList();
  }

  // ==========================================
  // NẠP TOÀN BỘ CẤU HÌNH CHI TIẾT 8 MÀN CHƠI
  // ==========================================

  /// Trả về danh sách đầy đủ 8 màn chơi
  static List<LevelConfig> get allLevels => [
        _buildLevel1(),
        _buildLevel2(),
        _buildLevel3(),
        _buildLevel4(),
        _buildLevel5(),
        _buildLevel6(),
        _buildLevel7(),
        _buildLevel8(),
      ];

  /// Lấy cấu hình của một màn cụ thể (clamped 1..8)
  static LevelConfig getLevel(int levelNumber) {
    final clamped = levelNumber.clamp(1, 8);
    return allLevels[clamped - 1];
  }

  // --- MÀN 1: BƯỚC ĐẦU PHÒNG THỦ (Đại Lộ Thẳng) ---
  static LevelConfig _buildLevel1() {
    final matrix = _createMatrixWithStraightPath(5, 0, 19);
    final waypoints = [
      [Vector2(0, 5), Vector2(19, 5)],
    ];
    final timeline = [
      SpawnEvent(triggerTime: 5.0, enemyType: EnemyType.greenSlime, waveNumber: 1),
      SpawnEvent(triggerTime: 7.5, enemyType: EnemyType.greenSlime, waveNumber: 1),
      SpawnEvent(triggerTime: 20.0, enemyType: EnemyType.greenSlime, waveNumber: 2),
      SpawnEvent(triggerTime: 21.5, enemyType: EnemyType.greenSlime, waveNumber: 2),
      SpawnEvent(triggerTime: 23.0, enemyType: EnemyType.greenSlime, waveNumber: 2),
      SpawnEvent(triggerTime: 35.0, enemyType: EnemyType.basicZombie, waveNumber: 3),
      SpawnEvent(triggerTime: 37.0, enemyType: EnemyType.greenSlime, waveNumber: 3),
      SpawnEvent(triggerTime: 39.0, enemyType: EnemyType.greenSlime, waveNumber: 3),
      SpawnEvent(triggerTime: 55.0, enemyType: EnemyType.basicZombie, waveNumber: 4),
      SpawnEvent(triggerTime: 56.5, enemyType: EnemyType.greenSlime, waveNumber: 4),
      SpawnEvent(triggerTime: 58.0, enemyType: EnemyType.basicZombie, waveNumber: 4),
      SpawnEvent(triggerTime: 59.5, enemyType: EnemyType.greenSlime, waveNumber: 4),
      SpawnEvent(triggerTime: 61.0, enemyType: EnemyType.greenSlime, waveNumber: 4),
      SpawnEvent(triggerTime: 65.0, enemyType: EnemyType.darkTitan, waveNumber: 4),
    ];

    return LevelConfig(
      levelNumber: 1,
      title: 'Màn 1: Bước Đầu Phòng Thủ',
      startingGold: 200,
      unlockedPlants: [PlantType.peashooter],
      unlockedSkills: [],
      tileMatrix: matrix,
      waypointsList: waypoints,
      waveSchedule: timeline,
      bossType: EnemyType.darkTitan,
    );
  }

  // --- MÀN 2: THỬ THÁCH GIÁP CỨNG (Khúc Cua Chữ L) ---
  static LevelConfig _buildLevel2() {
    final waypoints = [
      [Vector2(0, 2), Vector2(14, 2), Vector2(14, 8), Vector2(19, 8)],
    ];
    final matrix = _generateMatrixFromWaypoints(waypoints[0]);
    final timeline = [
      SpawnEvent(triggerTime: 4.0, enemyType: EnemyType.greenSlime, waveNumber: 1),
      SpawnEvent(triggerTime: 6.0, enemyType: EnemyType.purpleSnake, waveNumber: 1),
      SpawnEvent(triggerTime: 18.0, enemyType: EnemyType.purpleSnake, waveNumber: 2),
      SpawnEvent(triggerTime: 20.0, enemyType: EnemyType.greenSlime, waveNumber: 2),
      SpawnEvent(triggerTime: 22.0, enemyType: EnemyType.purpleSnake, waveNumber: 2),
      SpawnEvent(triggerTime: 32.0, enemyType: EnemyType.basicZombie, waveNumber: 3),
      SpawnEvent(triggerTime: 34.0, enemyType: EnemyType.purpleSnake, waveNumber: 3),
      SpawnEvent(triggerTime: 36.0, enemyType: EnemyType.basicZombie, waveNumber: 3),
      SpawnEvent(triggerTime: 48.0, enemyType: EnemyType.purpleSnake, waveNumber: 4),
      SpawnEvent(triggerTime: 50.0, enemyType: EnemyType.basicZombie, waveNumber: 4),
      SpawnEvent(triggerTime: 53.0, enemyType: EnemyType.purpleSnake, waveNumber: 4),
    ];

    return LevelConfig(
      levelNumber: 2,
      title: 'Màn 2: Thử Thách Khúc Cua',
      startingGold: 225,
      unlockedPlants: [PlantType.peashooter, PlantType.sunflower],
      unlockedSkills: [SkillType.goldenStorm],
      tileMatrix: matrix,
      waypointsList: waypoints,
      waveSchedule: timeline,
    );
  }

  // --- MÀN 3: BẦU TRỜI NGUY HIỂM (Đường Chữ U) ---
  static LevelConfig _buildLevel3() {
    final waypoints = [
      [Vector2(0, 2), Vector2(16, 2), Vector2(16, 7), Vector2(3, 7)],
    ];
    final matrix = _generateMatrixFromWaypoints(waypoints[0]);
    final timeline = [
      SpawnEvent(triggerTime: 4.0, enemyType: EnemyType.redEyedBat, waveNumber: 1),
      SpawnEvent(triggerTime: 6.0, enemyType: EnemyType.greenSlime, waveNumber: 1),
      SpawnEvent(triggerTime: 18.0, enemyType: EnemyType.redEyedBat, waveNumber: 2),
      SpawnEvent(triggerTime: 20.0, enemyType: EnemyType.redEyedBat, waveNumber: 2),
      SpawnEvent(triggerTime: 22.0, enemyType: EnemyType.purpleSnake, waveNumber: 2),
      SpawnEvent(triggerTime: 32.0, enemyType: EnemyType.redEyedBat, waveNumber: 3),
      SpawnEvent(triggerTime: 34.0, enemyType: EnemyType.basicZombie, waveNumber: 3),
      SpawnEvent(triggerTime: 36.0, enemyType: EnemyType.redEyedBat, waveNumber: 3),
      SpawnEvent(triggerTime: 50.0, enemyType: EnemyType.redEyedBat, waveNumber: 4),
      SpawnEvent(triggerTime: 52.0, enemyType: EnemyType.basicZombie, waveNumber: 4),
      SpawnEvent(triggerTime: 54.0, enemyType: EnemyType.redEyedBat, waveNumber: 4),
    ];

    return LevelConfig(
      levelNumber: 3,
      title: 'Màn 3: Bầu Trời Nguy Hiểm',
      startingGold: 250,
      unlockedPlants: [PlantType.peashooter, PlantType.sunflower, PlantType.clover],
      unlockedSkills: [SkillType.goldenStorm],
      tileMatrix: matrix,
      waypointsList: waypoints,
      waveSchedule: timeline,
    );
  }

  // --- MÀN 4: THUNG LŨNG BĂNG GIÁ (Zig-zag Đứng) ---
  static LevelConfig _buildLevel4() {
    final waypoints = [
      [
        Vector2(0, 2),
        Vector2(6, 2),
        Vector2(6, 8),
        Vector2(13, 8),
        Vector2(13, 2),
        Vector2(19, 2),
      ],
    ];
    final matrix = _generateMatrixFromWaypoints(waypoints[0]);
    final timeline = [
      SpawnEvent(triggerTime: 4.0, enemyType: EnemyType.purpleHound, waveNumber: 1),
      SpawnEvent(triggerTime: 6.0, enemyType: EnemyType.armoredScorpion, waveNumber: 1),
      SpawnEvent(triggerTime: 18.0, enemyType: EnemyType.purpleHound, waveNumber: 2),
      SpawnEvent(triggerTime: 20.0, enemyType: EnemyType.armoredScorpion, waveNumber: 2),
      SpawnEvent(triggerTime: 23.0, enemyType: EnemyType.purpleHound, waveNumber: 2),
      SpawnEvent(triggerTime: 35.0, enemyType: EnemyType.armoredScorpion, waveNumber: 3),
      SpawnEvent(triggerTime: 37.0, enemyType: EnemyType.basicZombie, waveNumber: 3),
      SpawnEvent(triggerTime: 40.0, enemyType: EnemyType.armoredScorpion, waveNumber: 3),
      SpawnEvent(triggerTime: 52.0, enemyType: EnemyType.purpleHound, waveNumber: 4),
      SpawnEvent(triggerTime: 54.0, enemyType: EnemyType.armoredScorpion, waveNumber: 4),
      SpawnEvent(triggerTime: 57.0, enemyType: EnemyType.basicZombie, waveNumber: 4),
    ];

    return LevelConfig(
      levelNumber: 4,
      title: 'Màn 4: Thung Lũng Băng Giá',
      startingGold: 275,
      unlockedPlants: [
        PlantType.peashooter,
        PlantType.sunflower,
        PlantType.clover,
        PlantType.iceShroom,
      ],
      unlockedSkills: [SkillType.goldenStorm, SkillType.tornado],
      tileMatrix: matrix,
      waypointsList: waypoints,
      waveSchedule: timeline,
    );
  }

  // --- MÀN 5: PHÁO ĐÀI LỬA ĐỎ (Vòng Cung Chữ C) ---
  static LevelConfig _buildLevel5() {
    final waypoints = [
      [
        Vector2(2, 0),
        Vector2(2, 9),
        Vector2(17, 9),
        Vector2(17, 2),
        Vector2(10, 2),
      ],
    ];
    final matrix = _generateMatrixFromWaypoints(waypoints[0]);
    final timeline = [
      SpawnEvent(triggerTime: 4.0, enemyType: EnemyType.cyborgRunner, waveNumber: 1),
      SpawnEvent(triggerTime: 6.5, enemyType: EnemyType.armoredScorpion, waveNumber: 1),
      SpawnEvent(triggerTime: 18.0, enemyType: EnemyType.cyborgRunner, waveNumber: 2),
      SpawnEvent(triggerTime: 20.0, enemyType: EnemyType.capZombie, waveNumber: 2),
      SpawnEvent(triggerTime: 23.0, enemyType: EnemyType.cyborgRunner, waveNumber: 2),
      SpawnEvent(triggerTime: 35.0, enemyType: EnemyType.capZombie, waveNumber: 3),
      SpawnEvent(triggerTime: 37.5, enemyType: EnemyType.cyborgRunner, waveNumber: 3),
      SpawnEvent(triggerTime: 40.0, enemyType: EnemyType.armoredScorpion, waveNumber: 3),
      SpawnEvent(triggerTime: 54.0, enemyType: EnemyType.capZombie, waveNumber: 4),
      SpawnEvent(triggerTime: 56.5, enemyType: EnemyType.cyborgRunner, waveNumber: 4),
      SpawnEvent(triggerTime: 59.0, enemyType: EnemyType.capZombie, waveNumber: 4),
    ];

    return LevelConfig(
      levelNumber: 5,
      title: 'Màn 5: Pháo Đài Lửa Đỏ',
      startingGold: 300,
      unlockedPlants: [
        PlantType.peashooter,
        PlantType.sunflower,
        PlantType.clover,
        PlantType.iceShroom,
        PlantType.firePeashooter,
      ],
      unlockedSkills: [SkillType.goldenStorm, SkillType.tornado],
      tileMatrix: matrix,
      waypointsList: waypoints,
      waveSchedule: timeline,
    );
  }

  // --- MÀN 6: HỘI TỤ TÂM ĐIỂM (Crossroad) ---
  static LevelConfig _buildLevel6() {
    final waypoints = [
      [
        Vector2(0, 5),
        Vector2(8, 5),
        Vector2(8, 2),
        Vector2(15, 2),
        Vector2(15, 8),
        Vector2(19, 8),
      ],
    ];
    final matrix = _generateMatrixFromWaypoints(waypoints[0]);
    final timeline = [
      SpawnEvent(triggerTime: 4.0, enemyType: EnemyType.whitePhantom, waveNumber: 1),
      SpawnEvent(triggerTime: 6.0, enemyType: EnemyType.cyborgRunner, waveNumber: 1),
      SpawnEvent(triggerTime: 18.0, enemyType: EnemyType.whitePhantom, waveNumber: 2),
      SpawnEvent(triggerTime: 20.0, enemyType: EnemyType.capZombie, waveNumber: 2),
      SpawnEvent(triggerTime: 23.0, enemyType: EnemyType.whitePhantom, waveNumber: 2),
      SpawnEvent(triggerTime: 35.0, enemyType: EnemyType.capZombie, waveNumber: 3),
      SpawnEvent(triggerTime: 37.0, enemyType: EnemyType.whitePhantom, waveNumber: 3),
      SpawnEvent(triggerTime: 40.0, enemyType: EnemyType.cyborgRunner, waveNumber: 3),
      SpawnEvent(triggerTime: 52.0, enemyType: EnemyType.whitePhantom, waveNumber: 4),
      SpawnEvent(triggerTime: 54.0, enemyType: EnemyType.capZombie, waveNumber: 4),
      SpawnEvent(triggerTime: 57.0, enemyType: EnemyType.whitePhantom, waveNumber: 4),
    ];

    return LevelConfig(
      levelNumber: 6,
      title: 'Màn 6: Hội Tụ Tâm Điểm',
      startingGold: 325,
      unlockedPlants: [
        PlantType.peashooter,
        PlantType.sunflower,
        PlantType.clover,
        PlantType.iceShroom,
        PlantType.firePeashooter,
        PlantType.electricShroom,
      ],
      unlockedSkills: [SkillType.goldenStorm, SkillType.tornado, SkillType.magicBind],
      tileMatrix: matrix,
      waypointsList: waypoints,
      waveSchedule: timeline,
    );
  }

  // --- MÀN 7: MÊ CUNG SỐ 8 (Figure-8 Labyrinth) ---
  static LevelConfig _buildLevel7() {
    final waypoints = [
      [
        Vector2(0, 8),
        Vector2(6, 8),
        Vector2(6, 2),
        Vector2(14, 2),
        Vector2(14, 8),
        Vector2(19, 8),
      ],
    ];
    final matrix = _generateMatrixFromWaypoints(waypoints[0]);
    final timeline = [
      SpawnEvent(triggerTime: 4.0, enemyType: EnemyType.whitePhantom, waveNumber: 1),
      SpawnEvent(triggerTime: 6.0, enemyType: EnemyType.armoredScorpion, waveNumber: 1),
      SpawnEvent(triggerTime: 18.0, enemyType: EnemyType.cyborgRunner, waveNumber: 2),
      SpawnEvent(triggerTime: 20.0, enemyType: EnemyType.capZombie, waveNumber: 2),
      SpawnEvent(triggerTime: 23.0, enemyType: EnemyType.whitePhantom, waveNumber: 2),
      SpawnEvent(triggerTime: 35.0, enemyType: EnemyType.capZombie, waveNumber: 3),
      SpawnEvent(triggerTime: 37.0, enemyType: EnemyType.armoredScorpion, waveNumber: 3),
      SpawnEvent(triggerTime: 40.0, enemyType: EnemyType.cyborgRunner, waveNumber: 3),
      SpawnEvent(triggerTime: 53.0, enemyType: EnemyType.capZombie, waveNumber: 4),
      SpawnEvent(triggerTime: 55.0, enemyType: EnemyType.whitePhantom, waveNumber: 4),
      SpawnEvent(triggerTime: 58.0, enemyType: EnemyType.cyborgRunner, waveNumber: 4),
    ];

    return LevelConfig(
      levelNumber: 7,
      title: 'Màn 7: Mê Cung Số 8',
      startingGold: 350,
      unlockedPlants: [
        PlantType.peashooter,
        PlantType.sunflower,
        PlantType.clover,
        PlantType.iceShroom,
        PlantType.firePeashooter,
        PlantType.electricShroom,
        PlantType.starfruit,
      ],
      unlockedSkills: [SkillType.goldenStorm, SkillType.tornado, SkillType.magicBind],
      tileMatrix: matrix,
      waypointsList: waypoints,
      waveSchedule: timeline,
    );
  }

  // --- MÀN 8: NÚT THẮT TỬ THẦN 2 NHÁNH (Dual-Gate Chokepoint) ---
  static LevelConfig _buildLevel8() {
    final branch1 = [
      Vector2(0, 2),
      Vector2(9, 2),
      Vector2(9, 5),
      Vector2(19, 5),
    ];
    final branch2 = [
      Vector2(0, 8),
      Vector2(9, 8),
      Vector2(9, 5),
      Vector2(19, 5),
    ];

    final matrix = _generateDualBranchMatrix(branch1, branch2);
    final timeline = [
      // Wave 1: Quái xuất phát từ cả 2 cổng
      SpawnEvent(triggerTime: 4.0, enemyType: EnemyType.greenSlime, waveNumber: 1),
      SpawnEvent(triggerTime: 6.0, enemyType: EnemyType.purpleSnake, waveNumber: 1),
      SpawnEvent(triggerTime: 8.0, enemyType: EnemyType.purpleHound, waveNumber: 1),

      // Wave 2: Quái bay & Giáp
      SpawnEvent(triggerTime: 18.0, enemyType: EnemyType.redEyedBat, waveNumber: 2),
      SpawnEvent(triggerTime: 20.0, enemyType: EnemyType.armoredScorpion, waveNumber: 2),
      SpawnEvent(triggerTime: 23.0, enemyType: EnemyType.cyborgRunner, waveNumber: 2),

      // Wave 3: Quân đoàn Zombie & Quái tàng hình
      SpawnEvent(triggerTime: 35.0, enemyType: EnemyType.capZombie, waveNumber: 3),
      SpawnEvent(triggerTime: 37.0, enemyType: EnemyType.whitePhantom, waveNumber: 3),
      SpawnEvent(triggerTime: 39.0, enemyType: EnemyType.cyborgRunner, waveNumber: 3),
      SpawnEvent(triggerTime: 42.0, enemyType: EnemyType.capZombie, waveNumber: 3),

      // Wave 4: ĐẠI CHIẾN BOSS DARK TITAN & BẢO VỆ NÚT THẮT
      SpawnEvent(triggerTime: 54.0, enemyType: EnemyType.capZombie, waveNumber: 4),
      SpawnEvent(triggerTime: 56.0, enemyType: EnemyType.armoredScorpion, waveNumber: 4),
      SpawnEvent(triggerTime: 58.0, enemyType: EnemyType.cyborgRunner, waveNumber: 4),
      SpawnEvent(triggerTime: 60.0, enemyType: EnemyType.whitePhantom, waveNumber: 4),
      SpawnEvent(triggerTime: 65.0, enemyType: EnemyType.darkTitan, waveNumber: 4),
    ];

    return LevelConfig(
      levelNumber: 8,
      title: 'Màn 8: Nút Thắt Tử Thần (2 Cổng)',
      startingGold: 400,
      unlockedPlants: [
        PlantType.peashooter,
        PlantType.sunflower,
        PlantType.clover,
        PlantType.iceShroom,
        PlantType.firePeashooter,
        PlantType.electricShroom,
        PlantType.starfruit,
        PlantType.melonPult,
      ],
      unlockedSkills: [
        SkillType.goldenStorm,
        SkillType.tornado,
        SkillType.magicBind,
        SkillType.meteorite,
      ],
      tileMatrix: matrix,
      waypointsList: [branch1, branch2],
      waveSchedule: timeline,
      bossType: EnemyType.darkTitan,
    );
  }

  // ==========================================
  // THUẬT TOÁN TỰ ĐỘNG SINH MA TRẬN TILE HỢP LỆ
  // ==========================================

  /// Tạo ma trận đường thẳng chuẩn cho Màn 1
  static List<List<int>> _createMatrixWithStraightPath(int row, int startCol, int endCol) {
    final matrix = List.generate(11, (_) => List.filled(20, 0));

    // Bờ trên
    for (int col = 0; col < 20; col++) {
      matrix[row - 1][col] = 2; // tren-giua
    }
    // Đường đi
    for (int col = 0; col < 20; col++) {
      matrix[row][col] = 1; // duong-di-quai
    }
    matrix[row][startCol] = 98; // Cổng Spawn
    matrix[row][endCol] = 99;   // Căn cứ Base

    // Bờ dưới
    for (int col = 0; col < 20; col++) {
      matrix[row + 1][col] = 3; // duoi
    }

    return matrix;
  }

  /// Sinh ma trận 20x11 chuẩn xác từ danh sách waypoints
  static List<List<int>> _generateMatrixFromWaypoints(List<Vector2> waypoints) {
    final matrix = List.generate(11, (_) => List.filled(20, 0));

    // Đánh dấu các ô đường đi (ID 1)
    for (int i = 0; i < waypoints.length - 1; i++) {
      final start = waypoints[i];
      final end = waypoints[i + 1];

      int minX = start.x.toInt();
      int maxX = end.x.toInt();
      if (minX > maxX) {
        final tmp = minX;
        minX = maxX;
        maxX = tmp;
      }

      int minY = start.y.toInt();
      int maxY = end.y.toInt();
      if (minY > maxY) {
        final tmp = minY;
        minY = maxY;
        maxY = tmp;
      }

      for (int y = minY; y <= maxY; y++) {
        for (int x = minX; x <= maxX; x++) {
          if (y >= 0 && y < 11 && x >= 0 && x < 20) {
            matrix[y][x] = 1;
          }
        }
      }
    }

    // Đặt Cổng quái (ID 98) và Căn cứ (ID 99)
    final spawn = waypoints.first;
    final base = waypoints.last;
    matrix[spawn.y.toInt()][spawn.x.toInt()] = 98;
    matrix[base.y.toInt()][base.x.toInt()] = 99;

    return matrix;
  }

  /// Sinh ma trận cho Màn 8 kết hợp 2 nhánh waypoints
  static List<List<int>> _generateDualBranchMatrix(
    List<Vector2> branch1,
    List<Vector2> branch2,
  ) {
    final matrix = List.generate(11, (_) => List.filled(20, 0));

    void markBranch(List<Vector2> branch) {
      for (int i = 0; i < branch.length - 1; i++) {
        final start = branch[i];
        final end = branch[i + 1];

        int minX = start.x.toInt().clamp(0, 19);
        int maxX = end.x.toInt().clamp(0, 19);
        if (minX > maxX) {
          final tmp = minX;
          minX = maxX;
          maxX = tmp;
        }

        int minY = start.y.toInt().clamp(0, 10);
        int maxY = end.y.toInt().clamp(0, 10);
        if (minY > maxY) {
          final tmp = minY;
          minY = maxY;
          maxY = tmp;
        }

        for (int y = minY; y <= maxY; y++) {
          for (int x = minX; x <= maxX; x++) {
            matrix[y][x] = 1;
          }
        }
      }
    }

    markBranch(branch1);
    markBranch(branch2);

    // Cổng Spawn 1 & Cổng Spawn 2
    matrix[branch1.first.y.toInt()][branch1.first.x.toInt()] = 98;
    matrix[branch2.first.y.toInt()][branch2.first.x.toInt()] = 98;

    // Căn cứ Nhà Chính chung
    matrix[branch1.last.y.toInt()][branch1.last.x.toInt()] = 99;

    return matrix;
  }
}
