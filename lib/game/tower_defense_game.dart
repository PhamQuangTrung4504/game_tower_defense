import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../models/level_config.dart';
import '../models/map_data.dart';
import '../models/plant_data.dart';
import '../models/skill_data.dart';
import '../services/audio_manager.dart';
import '../services/storage_service.dart';
import 'components/map_renderer_component.dart';
import 'components/plant_component.dart';
import 'components/skills/magic_bind_component.dart';
import 'components/skills/meteorite_component.dart';
import 'components/skills/tornado_component.dart';
import 'components/wave_spawner_component.dart';

/// Lớp Game chính quản lý toàn bộ vòng lặp trò chơi Tower Defense.
///
/// Hỗ trợ chiến dịch đầy đủ 8 Màn chơi (Campaign Level System),
/// quản lý tài nguyên, kỹ năng, đặt trụ, và tiến độ mở khóa màn chơi.
class TowerDefenseGame extends FlameGame
    with TapCallbacks, HasCollisionDetection {
  TowerDefenseGame({
    int? initialMaxUnlockedLevel,
    int initialLevel = 1,
  })  : currentLevelNumber = initialLevel.clamp(1, 8),
        currentLevelConfig = LevelConfig.getLevel(initialLevel.clamp(1, 8)),
        currentLevelNotifier = ValueNotifier<int>(initialLevel.clamp(1, 8)),
        maxUnlockedLevelNotifier = ValueNotifier<int>(
          initialMaxUnlockedLevel ?? StorageService.instance.loadHighestUnlockedLevel(),
        ),
        super(
          camera: CameraComponent.withFixedResolution(
            width: 640,
            height: 352,
          ),
        );

  /// Cấu hình màn chơi hiện tại
  int currentLevelNumber = 1;
  LevelConfig currentLevelConfig;
  final ValueNotifier<int> currentLevelNotifier;

  /// Màn chơi cao nhất đã được mở khóa (1..8)
  final ValueNotifier<int> maxUnlockedLevelNotifier;

  /// Dữ liệu bản đồ của màn chơi hiện tại
  late MapData mapData;

  /// Component vẽ bản đồ
  late MapRendererComponent mapRenderer;

  /// Component quản lý sinh quái theo đợt
  late WaveSpawnerComponent waveSpawner;

  /// Máu nhà chính (Khởi điểm 10 tim)
  final ValueNotifier<int> baseHpNotifier = ValueNotifier<int>(10);

  /// Số vàng người chơi đang có
  final ValueNotifier<int> goldNotifier = ValueNotifier<int>(200);

  /// Năng lượng Mana (Khởi điểm 100.0, tối đa 100.0, hồi 2.5 MP/s)
  double mana = 100.0;
  static const double maxMana = 100.0;
  static const double manaRegenRate = 2.5;
  final ValueNotifier<double> manaNotifier = ValueNotifier<double>(100.0);

  /// Đợt quái hiện tại (1..4)
  final ValueNotifier<int> waveNotifier = ValueNotifier<int>(1);

  /// Số quái đang còn sống trên sân
  final ValueNotifier<int> enemyCountNotifier = ValueNotifier<int>(0);

  /// Loại trụ hiện đang được chọn trên thanh Deck
  final ValueNotifier<PlantType?> selectedPlantTypeNotifier =
      ValueNotifier<PlantType?>(PlantType.peashooter);

  /// Trụ hiện đang được chọn để xem thông tin & nâng cấp trên Inspector UI
  final ValueNotifier<PlantComponent?> selectedPlantNotifier =
      ValueNotifier<PlantComponent?>(null);

  /// Kỹ năng hiện đang trong chế độ chọn tọa độ xả chiêu (Magic Bind, Meteorite)
  final ValueNotifier<SkillType?> selectedSkillForTargetingNotifier =
      ValueNotifier<SkillType?>(null);

  /// Thông báo trạng thái game hiển thị nhanh trên HUD
  final ValueNotifier<String> placementFeedbackNotifier =
      ValueNotifier<String>('Chào mừng đến Màn 1: Bước Đầu Phòng Thủ!');

  /// Quản lý danh sách 4 kỹ năng chủ động
  final Map<SkillType, SkillData> skills = {
    for (final type in SkillType.values) type: SkillData(type),
  };

  /// Bộ đếm hiệu lực kỹ năng Bão Vàng (Golden Storm - 6 giây)
  double goldenStormTimer = 0.0;
  double _goldenStormGoldTick = 0.0;
  bool get isGoldenStormActive => goldenStormTimer > 0;

  /// Quản lý danh sách các trụ đã đặt trên bản đồ theo vị trí "col,row"
  final Map<String, PlantComponent> placedPlants = {};

  /// Cờ trạng thái kết thúc trận đấu (Thắng / Thua)
  final ValueNotifier<bool> isGameOverNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isVictoryNotifier = ValueNotifier<bool>(false);

  /// Tốc độ trò chơi (1.0x hoặc 2.0x)
  double gameSpeed = 1.0;
  final ValueNotifier<double> gameSpeedNotifier = ValueNotifier<double>(1.0);

  /// Trạng thái tạm dừng trò chơi
  bool isPaused = false;
  final ValueNotifier<bool> isPausedNotifier = ValueNotifier<bool>(false);

  /// Bộ đếm hiệu ứng rung màn hình (Camera Shake)
  double _shakeTimer = 0.0;
  double _shakeIntensity = 3.0;

  /// Kích hoạt rung lắc màn hình (Camera Shake) trong [duration] giây
  void triggerCameraShake({double duration = 0.25, double intensity = 3.0}) {
    _shakeTimer = duration;
    _shakeIntensity = intensity;
  }

  /// Chuyển đổi tốc độ game giữa 1.0x và 2.0x
  void toggleSpeed() {
    gameSpeed = (gameSpeed == 1.0) ? 2.0 : 1.0;
    _safeNotify(gameSpeedNotifier, gameSpeed);
    placementFeedbackNotifier.value = '⚡ Tốc độ game: ${gameSpeed.toStringAsFixed(0)}x';
  }

  /// Tạm dừng trò chơi
  void pause() {
    isPaused = true;
    _safeNotify(isPausedNotifier, true);
  }

  /// Tiếp tục trò chơi
  void resume() {
    isPaused = false;
    _safeNotify(isPausedNotifier, false);
  }

  /// Đảo trạng thái tạm dừng / tiếp tục
  void togglePause() {
    if (isPaused) {
      resume();
    } else {
      pause();
    }
  }

  bool get isGameOver => isGameOverNotifier.value;
  bool get isVictory => isVictoryNotifier.value;
  int get baseHp => baseHpNotifier.value;
  int get playerGold => goldNotifier.value;
  PlantType? get selectedPlantType => selectedPlantTypeNotifier.value;

  @override
  Color backgroundColor() => const Color(0xFF16191F);

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';

    // Khởi tạo và nạp màn chơi được chỉ định
    await loadLevel(currentLevelNumber);

    camera.viewfinder.anchor = Anchor.topLeft;
  }

  /// Cập nhật giá trị an toàn cho ValueNotifier tránh lỗi setState during build
  void _safeNotify<T>(ValueNotifier<T> notifier, T newValue) {
    if (notifier.value == newValue) return;
    if (WidgetsBinding.instance.buildOwner?.debugBuilding ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.value = newValue;
      });
    } else {
      notifier.value = newValue;
    }
  }

  /// Nạp một màn chơi cụ thể trong chiến dịch (1 đến 8)
  Future<void> loadLevel(int levelNumber) async {
    currentLevelNumber = levelNumber.clamp(1, 8);
    currentLevelConfig = LevelConfig.getLevel(currentLevelNumber);

    // 1. Reset các chỉ số tài nguyên theo cấu hình của màn
    _safeNotify(currentLevelNotifier, currentLevelNumber);
    _safeNotify(baseHpNotifier, 10);
    _safeNotify(goldNotifier, currentLevelConfig.startingGold);
    mana = 100.0;
    _safeNotify(manaNotifier, 100.0);
    _safeNotify(waveNotifier, 1);
    _safeNotify(enemyCountNotifier, 0);
    _safeNotify(isGameOverNotifier, false);
    _safeNotify(isVictoryNotifier, false);
    goldenStormTimer = 0.0;
    _safeNotify(selectedPlantNotifier, null);
    _safeNotify(selectedSkillForTargetingNotifier, null);

    // Chọn trụ đầu tiên được mở khóa trong màn này
    _safeNotify(
      selectedPlantTypeNotifier,
      currentLevelConfig.unlockedPlants.isNotEmpty
          ? currentLevelConfig.unlockedPlants.first
          : null,
    );

    _safeNotify(
      placementFeedbackNotifier,
      'Chào mừng đến ${currentLevelConfig.title}!',
    );

    // Reset trạng thái tạm dừng & rung màn hình
    isPaused = false;
    _safeNotify(isPausedNotifier, false);
    _shakeTimer = 0.0;
    camera.viewfinder.position = Vector2.zero();

    // Reset cooldown các kỹ năng
    for (final s in skills.values) {
      s.resetCooldown();
    }

    // 2. Dọn sạch các entities trong World
    for (final child in world.children.toList()) {
      child.removeFromParent();
    }
    placedPlants.clear();

    // 3. Khởi tạo bản đồ ma trận mới
    mapData = MapData(
      matrix: currentLevelConfig.tileMatrix.map((r) => List<int>.from(r)).toList(),
      waypoints: currentLevelConfig.waypointsList.first,
    );
    mapRenderer = MapRendererComponent(mapData: mapData);
    await world.add(mapRenderer);

    // 4. Khởi tạo Spawner với danh sách Waypoints và Timeline của màn
    final allPixelWaypoints = currentLevelConfig.allWaypointsPixelCenters;
    final timelineEvents = currentLevelConfig.waveSchedule
        .map((e) => SpawnEvent(
              triggerTime: e.triggerTime,
              enemyType: e.enemyType,
              waveNumber: e.waveNumber,
              branchIndex: e.branchIndex,
            ))
        .toList();

    waveSpawner = WaveSpawnerComponent(
      waypointsList: allPixelWaypoints,
      timeline: timelineEvents,
    );

    waveSpawner.onWaveStart = (wave) {
      waveNotifier.value = wave;
      if (wave == waveSpawner.totalWaves) {
        placementFeedbackNotifier.value = '⚠️ ĐỢT CUỐI CÙNG CỦA MÀN $currentLevelNumber!';
      }
    };

    waveSpawner.onVictory = () {
      if (!isGameOver) {
        // Tự động mở khóa màn kế tiếp nếu chưa mở
        if (currentLevelNumber >= maxUnlockedLevelNotifier.value && currentLevelNumber < 8) {
          final nextLvl = currentLevelNumber + 1;
          maxUnlockedLevelNotifier.value = nextLvl;
          StorageService.instance.saveHighestUnlockedLevel(nextLvl);
        }
        isVictoryNotifier.value = true;
        placementFeedbackNotifier.value = '🎉 CHIẾN THẮNG ${currentLevelConfig.title}!';
        AudioManager.instance.playVictorySfx();
      }
    };

    await world.add(waveSpawner);
  }

  /// Chuyển ngay sang màn kế tiếp
  Future<void> nextLevel() async {
    if (currentLevelNumber < 8) {
      await loadLevel(currentLevelNumber + 1);
    } else {
      await loadLevel(1); // Quay vòng về màn 1 nếu đã hoàn thành màn 8
    }
  }

  /// Khởi động lại màn chơi hiện tại
  Future<void> restartCurrentLevel() async {
    await loadLevel(currentLevelNumber);
  }

  @override
  void update(double dt) {
    // Nếu game đang tạm dừng, bỏ qua toàn bộ vòng lặp cập nhật
    if (isPaused) return;

    final effectiveDt = dt * gameSpeed;
    super.update(effectiveDt);

    // Xử lý hiệu ứng rung lắc màn hình (Camera Shake)
    if (_shakeTimer > 0) {
      _shakeTimer -= effectiveDt;
      if (_shakeTimer <= 0) {
        _shakeTimer = 0.0;
        camera.viewfinder.position = Vector2.zero();
      } else {
        final offsetX = (math.Random().nextDouble() * 2 - 1) * _shakeIntensity;
        final offsetY = (math.Random().nextDouble() * 2 - 1) * _shakeIntensity;
        camera.viewfinder.position = Vector2(offsetX, offsetY);
      }
    }

    if (isGameOver || isVictory) return;

    // 1. Tự động hồi phục Mana với tốc độ 2.5 MP/giây
    mana = (mana + manaRegenRate * effectiveDt).clamp(0.0, maxMana);
    _safeNotify(manaNotifier, mana);

    // 2. Cập nhật thời gian hồi chiêu của các kỹ năng
    for (final skill in skills.values) {
      skill.update(effectiveDt);
    }

    // 3. Cập nhật hiệu ứng Bão Vàng (Golden Storm): +5 Gold mỗi giây
    if (goldenStormTimer > 0) {
      goldenStormTimer -= effectiveDt;
      _goldenStormGoldTick += effectiveDt;
      if (_goldenStormGoldTick >= 1.0) {
        _goldenStormGoldTick = 0.0;
        addGold(5);
      }
      if (goldenStormTimer <= 0) {
        goldenStormTimer = 0.0;
      }
    }

    // 4. Cập nhật số quái hiện tại cho UI HUD
    if (isMounted) {
      try {
        enemyCountNotifier.value = waveSpawner.activeEnemyCount;
      } catch (_) {}
    }
  }

  /// Xử lý thao tác tap vào ô lưới (col, row) được truyền từ MapRendererComponent
  void handleMapTap(int col, int row) {
    if (col < 0 || col >= mapData.columns || row < 0 || row >= mapData.rows) {
      return;
    }

    // 1. Nếu đang ở chế độ nhắm mục tiêu KỸ NĂNG (Magic Bind, Meteorite)
    if (selectedSkillForTargetingNotifier.value != null) {
      final skillType = selectedSkillForTargetingNotifier.value!;
      final targetPos = mapData.gridToPixelCenter(col, row);
      castSkill(skillType, targetPos);
      return;
    }

    // 2. Nếu ô ĐÃ CÓ TRỤ -> Mở Inspector Panel của trụ đó
    if (hasPlantAt(col, row)) {
      final plant = placedPlants['$col,$row'];

      selectedPlantTypeNotifier.value = null;

      if (selectedPlantNotifier.value != null && selectedPlantNotifier.value != plant) {
        selectedPlantNotifier.value!.isSelected = false;
      }

      if (plant != null) {
        plant.isSelected = true;
        selectedPlantNotifier.value = plant;
        placementFeedbackNotifier.value =
            'Đang xem ${plant.data.name} (Lv.${plant.data.level}) - Tầm: ${plant.data.rangeInTiles} ô';
      }
      return;
    }

    // 3. Nếu ô TRỐNG và đang chọn thẻ bài trong Deck -> Thực hiện đặt trụ
    if (selectedPlantType != null) {
      _closeInspector();

      final plant = placePlant(col, row, selectedPlantType!);
      if (plant != null) {
        placementFeedbackNotifier.value =
            'Đã đặt ${plant.data.name} tại ($col, $row)';
      }
      return;
    }

    // 4. Nếu ô TRỐNG và không chọn gì -> Đóng Inspector Panel
    _closeInspector();
  }

  /// Đóng bảng điều khiển Inspector và tắt vòng tròn tầm bắn
  void _closeInspector() {
    if (selectedPlantNotifier.value != null) {
      selectedPlantNotifier.value!.isSelected = false;
      selectedPlantNotifier.value = null;
    }
  }

  /// Thi triển kỹ năng chủ động của người chơi
  bool castSkill(SkillType type, [Vector2? targetPos]) {
    final skill = skills[type];
    if (skill == null) return false;

    // Kiểm tra kỹ năng có được phép dùng ở màn này không
    if (!currentLevelConfig.unlockedSkills.contains(type)) {
      placementFeedbackNotifier.value = '⚠️ Kỹ năng chưa được mở khóa ở màn này!';
      return false;
    }

    if (!skill.isReady) {
      placementFeedbackNotifier.value =
          '⚠️ Kỹ năng ${skill.name} đang hồi (${skill.currentCooldown.toStringAsFixed(1)}s)!';
      return false;
    }

    if (!canCastSkill(skill.manaCost)) {
      placementFeedbackNotifier.value = '⚠️ Không đủ Mana (${skill.manaCost.toInt()} MP)!';
      return false;
    }

    if (skill.type.requiresTargetPosition && targetPos == null) {
      selectedPlantTypeNotifier.value = null;
      _closeInspector();
      selectedSkillForTargetingNotifier.value = type;
      placementFeedbackNotifier.value = '🎯 Hãy chạm lên bản đồ để xả chiêu ${skill.name}!';
      return true;
    }

    spendMana(skill.manaCost);
    skill.startCooldown();
    AudioManager.instance.playSkillSfx(type);

    switch (type) {
      case SkillType.goldenStorm:
        goldenStormTimer = 6.0;
        _goldenStormGoldTick = 0.0;
        placementFeedbackNotifier.value = '⚡ BÃO VÀNG: +5 Gold/giây & x1.5 Gold diệt quái!';
        break;

      case SkillType.tornado:
        world.add(TornadoComponent(waypoints: mapData.getWaypointPixelCenters()));
        placementFeedbackNotifier.value = '🌪️ LỐC XOÁY: Quét ngược từ Căn cứ đẩy lùi quái!';
        break;

      case SkillType.magicBind:
        if (targetPos != null) {
          world.add(MagicBindComponent(targetPosition: targetPos));
          placementFeedbackNotifier.value = '⛓️ TRÓI MA THUẬT: Khóa chân & trừ % HP quái!';
        }
        break;

      case SkillType.meteorite:
        if (targetPos != null) {
          world.add(MeteoriteComponent(targetPosition: targetPos));
          placementFeedbackNotifier.value = '☄️ THIÊN THẠCH: 300 sát thương nổ & bãi dung nham!';
        }
        break;
    }

    selectedSkillForTargetingNotifier.value = null;
    return true;
  }

  bool canCastSkill(double cost) => mana >= cost;

  bool spendMana(double cost) {
    if (mana >= cost) {
      mana -= cost;
      manaNotifier.value = mana;
      return true;
    }
    return false;
  }

  void addMana(double amount) {
    mana = (mana + amount).clamp(0.0, maxMana);
    manaNotifier.value = mana;
  }

  bool hasPlantAt(int col, int row) {
    return placedPlants.containsKey('$col,$row');
  }

  bool canPlacePlant(int col, int row, PlantData plantData) {
    if (!mapData.isTileBuildable(col, row)) {
      placementFeedbackNotifier.value = '⚠️ Không thể đặt trụ trên đường đất / viền!';
      return false;
    }

    if (hasPlantAt(col, row)) {
      placementFeedbackNotifier.value = '⚠️ Ô này đã có trụ!';
      return false;
    }

    if (playerGold < plantData.cost) {
      placementFeedbackNotifier.value = '⚠️ Không đủ vàng (${plantData.cost}G)!';
      return false;
    }

    return true;
  }

  PlantComponent? placePlant(int col, int row, PlantType type) {
    final plantData = PlantData.fromType(type);

    if (!canPlacePlant(col, row, plantData)) {
      return null;
    }

    final success = spendGold(plantData.cost);
    if (!success) return null;

    final plant = PlantComponent(
      data: plantData,
      gridCol: col,
      gridRow: row,
    );

    placedPlants['$col,$row'] = plant;
    world.add(plant);

    return plant;
  }

  void addGold(int amount) {
    goldNotifier.value += amount;
  }

  bool spendGold(int amount) {
    if (goldNotifier.value >= amount) {
      goldNotifier.value -= amount;
      return true;
    }
    return false;
  }

  void takeBaseDamage(int damage) {
    if (isGameOver || isVictory) return;

    baseHpNotifier.value = (baseHpNotifier.value - damage).clamp(0, 999);
    if (baseHpNotifier.value <= 0) {
      isGameOverNotifier.value = true;
      placementFeedbackNotifier.value = '💀 CĂN CỨ ĐÃ BỊ PHÁ HỦY! TRẬN ĐẤU KẾT THÚC!';
      AudioManager.instance.playDefeatSfx();
    }
  }

  bool isTileBuildable(int col, int row) {
    return mapData.isTileBuildable(col, row);
  }
}
