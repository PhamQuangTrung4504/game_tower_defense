import 'package:flame/components.dart';
import '../../models/enemy_type.dart';
import '../tower_defense_game.dart';
import 'enemy_component.dart';

/// Đại diện cho một sự kiện sinh quái theo thời gian thực (Timeline)
class SpawnEvent {
  SpawnEvent({
    required this.triggerTime,
    required this.enemyType,
    required this.waveNumber,
    this.branchIndex,
    this.isSpawned = false,
  });

  /// Thời điểm xuất hiện tính bằng giây (so với lúc bắt đầu game)
  final double triggerTime;

  /// Loại quái vật được sinh ra
  final EnemyType enemyType;

  /// Số đợt quái (Wave) tương ứng
  final int waveNumber;

  /// Nhánh đường đi cụ thể (0 hoặc 1 đối với Màn 8 đa nhánh). Mặc định luân phiên
  final int? branchIndex;

  /// Đã sinh quái chưa
  bool isSpawned;
}

/// Component quản lý dòng thời gian và điều khiển việc sinh quái vật (Wave Spawner).
///
/// Hỗ trợ cả màn 1 nhánh (Màn 1-7) và màn đa nhánh (Màn 8 - 2 Cổng Spawn).
class WaveSpawnerComponent extends Component
    with HasGameReference<TowerDefenseGame> {
  WaveSpawnerComponent({
    List<Vector2>? waypoints,
    List<List<Vector2>>? waypointsList,
    List<SpawnEvent>? timeline,
  })  : waypointsList = waypointsList ?? (waypoints != null ? [waypoints] : []),
        timeline = timeline ?? level1Timeline();

  /// Danh sách tất cả các nhánh đường đi (pixel tâm ô)
  final List<List<Vector2>> waypointsList;

  /// Danh sách waypoints nhánh chính (tiện cho tương thích ngược)
  List<Vector2> get waypoints =>
      waypointsList.isNotEmpty ? waypointsList.first : [];

  /// Danh sách sự kiện sinh quái theo timeline của màn
  final List<SpawnEvent> timeline;

  /// Tổng thời gian game đã trôi qua (giây)
  double gameTime = 0.0;

  /// Đợt quái hiện tại (1..4)
  int currentWave = 1;

  /// Tổng số đợt quái trong màn chơi
  int get totalWaves =>
      timeline.isNotEmpty ? timeline.map((e) => e.waveNumber).reduce((a, b) => a > b ? a : b) : 4;

  /// Bộ đếm số quái đã sinh để luân phiên nhánh ở màn 8
  int _spawnCounter = 0;

  /// Danh sách quái vật đang còn sống trên bản đồ
  final List<EnemyComponent> _activeEnemies = [];

  /// Số lượng quái vật hiện còn sống
  int get activeEnemyCount => _activeEnemies.length;

  /// Đã kết thúc toàn bộ timeline sinh quái chưa
  bool get isAllSpawned => timeline.every((event) => event.isSpawned);

  /// Trạng thái đã chiến thắng (Đã sinh hết quái và không còn quái nào sống sót)
  bool get isVictory => isAllSpawned && _activeEnemies.isEmpty && gameTime > 8.0;

  /// Callback thông báo khi có Wave mới bắt đầu
  void Function(int waveNumber)? onWaveStart;

  /// Callback thông báo khi chiến thắng màn chơi
  void Function()? onVictory;

  bool _victoryTriggered = false;

  @override
  void update(double dt) {
    super.update(dt);
    gameTime += dt;

    // Duyệt timeline để kích hoạt các sự kiện đến hạn
    for (final event in timeline) {
      if (!event.isSpawned && gameTime >= event.triggerTime) {
        event.isSpawned = true;

        if (event.waveNumber != currentWave) {
          currentWave = event.waveNumber;
          onWaveStart?.call(currentWave);
        }

        // Sinh quái theo nhánh chỉ định hoặc luân phiên
        final targetBranch = event.branchIndex ?? (_spawnCounter % waypointsList.length);
        spawnEnemy(event.enemyType, targetBranch);
      }
    }

    // Kiểm tra chiến thắng màn chơi
    if (isVictory && !_victoryTriggered) {
      _victoryTriggered = true;
      onVictory?.call();
    }
  }

  /// Sinh quái vật thuộc [EnemyType] tại điểm xuất phát của nhánh [branchIndex]
  EnemyComponent spawnEnemy(EnemyType type, [int branchIndex = 0]) {
    final monsterData = MonsterData.fromType(type);

    // Xác định nhánh đường đi cho quái
    final safeBranch = branchIndex.clamp(0, waypointsList.length - 1);
    final chosenWaypoints = waypointsList.isNotEmpty ? waypointsList[safeBranch] : <Vector2>[];

    final enemy = EnemyComponent(
      data: monsterData,
      waypoints: chosenWaypoints,
      onDeath: (e) {
        _activeEnemies.remove(e);
      },
      onReachedBase: (e) {
        _activeEnemies.remove(e);
      },
    );

    _activeEnemies.add(enemy);
    _spawnCounter++;

    game.world.add(enemy);

    // Kích hoạt rung lắc màn hình khi Boss Dark Titan bước vào sân
    if (type == EnemyType.darkTitan && isMounted) {
      try {
        game.triggerCameraShake(duration: 0.25, intensity: 3.0);
        game.placementFeedbackNotifier.value = '⚠️ CẢNH BÁO: BOSS DARK TITAN ĐÃ XUẤT HIỆN!';
      } catch (_) {}
    }

    return enemy;
  }

  /// Cấu hình timeline mặc định của MÀN 1 (có Boss Dark Titan ở cuối)
  static List<SpawnEvent> level1Timeline() {
    return [
      // Wave 1: Giây 05 (2 Slime)
      SpawnEvent(triggerTime: 5.0, enemyType: EnemyType.greenSlime, waveNumber: 1),
      SpawnEvent(triggerTime: 7.5, enemyType: EnemyType.greenSlime, waveNumber: 1),

      // Wave 2: Giây 20 (3 Slime)
      SpawnEvent(triggerTime: 20.0, enemyType: EnemyType.greenSlime, waveNumber: 2),
      SpawnEvent(triggerTime: 21.5, enemyType: EnemyType.greenSlime, waveNumber: 2),
      SpawnEvent(triggerTime: 23.0, enemyType: EnemyType.greenSlime, waveNumber: 2),

      // Wave 3: Giây 35 (1 Zombie + 2 Slime)
      SpawnEvent(triggerTime: 35.0, enemyType: EnemyType.basicZombie, waveNumber: 3),
      SpawnEvent(triggerTime: 37.0, enemyType: EnemyType.greenSlime, waveNumber: 3),
      SpawnEvent(triggerTime: 39.0, enemyType: EnemyType.greenSlime, waveNumber: 3),

      // Wave 4: Giây 55 (FINAL WAVE: 2 Zombie + 3 Slime + BOSS DARK TITAN)
      SpawnEvent(triggerTime: 55.0, enemyType: EnemyType.basicZombie, waveNumber: 4),
      SpawnEvent(triggerTime: 56.5, enemyType: EnemyType.greenSlime, waveNumber: 4),
      SpawnEvent(triggerTime: 58.0, enemyType: EnemyType.basicZombie, waveNumber: 4),
      SpawnEvent(triggerTime: 59.5, enemyType: EnemyType.greenSlime, waveNumber: 4),
      SpawnEvent(triggerTime: 61.0, enemyType: EnemyType.greenSlime, waveNumber: 4),
      SpawnEvent(triggerTime: 65.0, enemyType: EnemyType.darkTitan, waveNumber: 4),
    ];
  }
}
