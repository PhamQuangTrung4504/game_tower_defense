import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/components/plant_component.dart';
import 'game/tower_defense_game.dart';
import 'models/enemy_type.dart';
import 'models/level_config.dart';
import 'models/plant_data.dart';
import 'models/skill_data.dart';
import 'screens/encyclopedia_modal.dart';
import 'screens/main_menu_screen.dart';
import 'screens/settings_modal.dart';
import 'services/audio_manager.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo dịch vụ lưu trữ tiến trình & âm thanh
  await StorageService.instance.init();
  await AudioManager.instance.init();

  // Khóa hướng màn hình ngang (Landscape) cho trải nghiệm game thủ thành chuẩn
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Ẩn thanh điều hướng và thanh trạng thái của hệ điều hành (Chế độ tràn viền)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const TowerDefenseApp());
}

/// Trạng thái màn hình ứng dụng
enum AppScreen { mainMenu, gameplay }

class TowerDefenseApp extends StatefulWidget {
  const TowerDefenseApp({super.key});

  @override
  State<TowerDefenseApp> createState() => _TowerDefenseAppState();
}

class _TowerDefenseAppState extends State<TowerDefenseApp> {
  AppScreen _currentScreen = AppScreen.mainMenu;
  int _selectedLevel = 1;
  bool _showSettings = false;
  bool _showEncyclopedia = false;

  void _startGame(int level) {
    setState(() {
      _selectedLevel = level;
      _currentScreen = AppScreen.gameplay;
    });
    AudioManager.instance.playBattleBgm();
  }

  void _returnToMenu() {
    setState(() {
      _currentScreen = AppScreen.mainMenu;
    });
    AudioManager.instance.stopBgm();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plants vs Monsters: Tower Defense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1115),
      ),
      home: _currentScreen == AppScreen.mainMenu
          ? Scaffold(
              backgroundColor: const Color(0xFF0F1115),
              body: Stack(
                children: [
                  MainMenuScreen(
                    onStartGame: _startGame,
                    onOpenSettings: () {
                      setState(() {
                        _showSettings = true;
                      });
                    },
                    onOpenEncyclopedia: () {
                      setState(() {
                        _showEncyclopedia = true;
                      });
                    },
                  ),
                  if (_showSettings)
                    SettingsModal(
                      onClose: () {
                        setState(() {
                          _showSettings = false;
                        });
                      },
                      onProgressReset: () {
                        setState(() {});
                      },
                    ),
                  if (_showEncyclopedia)
                    EncyclopediaModal(
                      onClose: () {
                        setState(() {
                          _showEncyclopedia = false;
                        });
                      },
                    ),
                ],
              ),
            )
          : GameScreen(
              initialLevel: _selectedLevel,
              onReturnToMenu: _returnToMenu,
            ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.initialLevel = 1,
    this.onReturnToMenu,
  });

  final int initialLevel;
  final VoidCallback? onReturnToMenu;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final TowerDefenseGame _game;
  bool _showGrid = false;
  bool _showLevelSelect = false;
  bool _showSettings = false;
  bool _showEncyclopedia = false;

  @override
  void initState() {
    super.initState();
    _game = TowerDefenseGame(initialLevel: widget.initialLevel);
  }

  void _toggleGrid() {
    setState(() {
      _showGrid = !_showGrid;
      _game.mapRenderer.showGrid = _showGrid;
    });
  }

  void _quickSpawn(EnemyType type) {
    _game.waveSpawner.spawnEnemy(type);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Khu vực Game Flame chính (căn giữa và giữ chuẩn tỷ lệ 640x352)
          Center(
            child: AspectRatio(
              aspectRatio: 640 / 352,
              child: ClipRect(
                child: GameWidget(game: _game),
              ),
            ),
          ),

          // 1. THANH HUD TRÊN CÙNG: Máu, Vàng, Mana, Wave, Quái, Nút Chọn Màn & Tiện Ích
          Positioned(
            top: 6,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nhóm chỉ số chính
                Flexible(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Nút Chọn Màn Chơi (Level Selector Trigger)
                      ValueListenableBuilder<int>(
                        valueListenable: _game.currentLevelNotifier,
                        builder: (context, lvl, _) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _showLevelSelect = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B3A4B),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: const Color(0xFF00E5FF), width: 1.2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.map, color: Color(0xFF00E5FF), size: 12),
                                  const SizedBox(width: 3),
                                  Text(
                                    'MÀN $lvl',
                                    style: const TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down, color: Color(0xFF00E5FF), size: 14),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Máu Nhà Chính
                      ValueListenableBuilder<int>(
                        valueListenable: _game.baseHpNotifier,
                        builder: (context, hp, _) {
                          return _buildStatBadge(
                            icon: Icons.favorite,
                            iconColor: const Color(0xFFE53935),
                            label: '$hp HP',
                            bgColor: const Color(0xFF2C1517),
                            borderColor: const Color(0xFFE53935),
                          );
                        },
                      ),

                      // Vàng
                      ValueListenableBuilder<int>(
                        valueListenable: _game.goldNotifier,
                        builder: (context, gold, _) {
                          return _buildStatBadge(
                            icon: Icons.monetization_on,
                            iconColor: const Color(0xFFFFD54F),
                            label: '$gold G',
                            bgColor: const Color(0xFF2C2515),
                            borderColor: const Color(0xFFFFD54F),
                          );
                        },
                      ),

                      // Mana
                      ValueListenableBuilder<double>(
                        valueListenable: _game.manaNotifier,
                        builder: (context, mana, _) {
                          return _buildStatBadge(
                            icon: Icons.water_drop,
                            iconColor: const Color(0xFF29B6F6),
                            label: '${mana.toInt()}/100 MP',
                            bgColor: const Color(0xFF0D2538),
                            borderColor: const Color(0xFF29B6F6),
                          );
                        },
                      ),

                      // Wave
                      ValueListenableBuilder<int>(
                        valueListenable: _game.waveNotifier,
                        builder: (context, wave, _) {
                          return _buildStatBadge(
                            icon: Icons.waves,
                            iconColor: const Color(0xFF00E5FF),
                            label: 'WAVE $wave/4',
                            bgColor: const Color(0xFF152A2C),
                            borderColor: const Color(0xFF00E5FF),
                          );
                        },
                      ),

                      // Số lượng quái trên sân
                      ValueListenableBuilder<int>(
                        valueListenable: _game.enemyCountNotifier,
                        builder: (context, count, _) {
                          return _buildStatBadge(
                            icon: Icons.bug_report,
                            iconColor: const Color(0xFFAEEA00),
                            label: 'Quái: $count',
                            bgColor: const Color(0xFF222C15),
                            borderColor: const Color(0xFFAEEA00),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Nhóm nút tiện ích: Spawn thử nghiệm & Bật/Tắt Lưới
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => _quickSpawn(EnemyType.greenSlime),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        '+Slime',
                        style: TextStyle(fontSize: 9, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 3),
                    ElevatedButton(
                      onPressed: () => _quickSpawn(EnemyType.basicZombie),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A148C),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        '+Zombie',
                        style: TextStyle(fontSize: 9, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 3),
                    ElevatedButton(
                      onPressed: () => _quickSpawn(EnemyType.darkTitan),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB71C1C),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        '+Boss',
                        style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 3),
                    ElevatedButton.icon(
                      onPressed: _toggleGrid,
                      icon: Icon(
                        _showGrid ? Icons.grid_on : Icons.grid_off,
                        size: 11,
                        color: _showGrid ? Colors.cyanAccent : Colors.grey,
                      ),
                      label: Text(
                        _showGrid ? 'Lưới: BẬT' : 'Lưới: TẮT',
                        style: TextStyle(
                          fontSize: 8.5,
                          color: _showGrid ? Colors.cyanAccent : Colors.white70,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.8),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(
                            color: _showGrid ? Colors.cyanAccent : Colors.white24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    // Nút Tốc độ Game (1x / 2x)
                    ValueListenableBuilder<double>(
                      valueListenable: _game.gameSpeedNotifier,
                      builder: (context, speed, _) {
                        final isFast = speed > 1.0;
                        return ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _game.toggleSpeed();
                            });
                          },
                          icon: Icon(
                            isFast ? Icons.fast_forward : Icons.play_arrow,
                            size: 11,
                            color: isFast ? const Color(0xFFFFD54F) : Colors.white70,
                          ),
                          label: Text(
                            '${speed.toStringAsFixed(0)}x',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: isFast ? const Color(0xFFFFD54F) : Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFast
                                ? const Color(0xFFE65100)
                                : Colors.black.withValues(alpha: 0.8),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                              side: BorderSide(
                                color: isFast ? const Color(0xFFFFD54F) : Colors.white24,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 3),
                    // Nút Tạm Dừng Game (Pause)
                    ValueListenableBuilder<bool>(
                      valueListenable: _game.isPausedNotifier,
                      builder: (context, isPaused, _) {
                        return ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _game.togglePause();
                            });
                          },
                          icon: Icon(
                            isPaused ? Icons.play_arrow : Icons.pause,
                            size: 11,
                            color: isPaused ? const Color(0xFF00E5FF) : Colors.white70,
                          ),
                          label: Text(
                            isPaused ? 'TIẾP TỤC' : 'DỪNG',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: isPaused ? const Color(0xFF00E5FF) : Colors.white70,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPaused
                                ? const Color(0xFF004D40)
                                : Colors.black.withValues(alpha: 0.8),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                              side: BorderSide(
                                color: isPaused ? const Color(0xFF00E5FF) : Colors.white24,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 3),
                    // Nút Bách Khoa Toàn Thư (Encyclopedia Modal Trigger)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showEncyclopedia = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.8),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: const BorderSide(color: Color(0xFFFFD54F), width: 1.0),
                        ),
                      ),
                      child: const Icon(
                        Icons.menu_book,
                        size: 13,
                        color: Color(0xFFFFD54F),
                      ),
                    ),
                    const SizedBox(width: 3),
                    // Nút Cài Đặt (Settings Modal Trigger)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showSettings = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.8),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.0),
                        ),
                      ),
                      child: const Icon(
                        Icons.settings,
                        size: 13,
                        color: Color(0xFF00E5FF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. DÒNG THÔNG BÁO FEEDBACK (Nằm dưới HUD)
          Positioned(
            top: 38,
            left: 8,
            child: ValueListenableBuilder<String>(
              valueListenable: _game.placementFeedbackNotifier,
              builder: (context, msg, _) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    msg,
                    style: const TextStyle(
                      color: Color(0xFFB0BEC5),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. BẢNG ĐIỀU KHIỂN TRỤ (PLANT INSPECTOR PANEL)
          Positioned(
            top: 38,
            right: 8,
            child: ValueListenableBuilder<PlantComponent?>(
              valueListenable: _game.selectedPlantNotifier,
              builder: (context, selectedPlant, _) {
                if (selectedPlant == null) return const SizedBox.shrink();

                return ValueListenableBuilder<int>(
                  valueListenable: _game.goldNotifier,
                  builder: (context, gold, _) {
                    return _buildPlantInspectorPanel(selectedPlant, gold);
                  },
                );
              },
            ),
          ),

          // 4. THANH KỸ NĂNG & THANH CHỌN TRỤ (Tự động lọc theo Màn chơi)
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Center(
              child: ValueListenableBuilder<int>(
                valueListenable: _game.currentLevelNotifier,
                builder: (context, currentLevel, _) {
                  final config = _game.currentLevelConfig;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Chỉ hiện thanh kỹ năng nếu màn này có kỹ năng mở khóa
                      if (config.unlockedSkills.isNotEmpty) ...[
                        _buildSkillBar(config.unlockedSkills),
                        const SizedBox(height: 3),
                      ],
                      // Khay thẻ bài chỉ hiện các trụ mở khóa của màn này
                      _buildPlantDeck(config.unlockedPlants),
                    ],
                  );
                },
              ),
            ),
          ),

          // 5. MODAL CHỌN MÀN CHƠI (LEVEL SELECTOR OVERLAY)
          if (_showLevelSelect)
            _buildLevelSelectModal(),

          // 6. OVERLAY MÀN HÌNH THẤT BẠI (DEFEAT DIALOG)
          ValueListenableBuilder<bool>(
            valueListenable: _game.isGameOverNotifier,
            builder: (context, isDefeat, _) {
              if (!isDefeat) return const SizedBox.shrink();
              return _buildEndGameDialog(
                isVictory: false,
                title: 'THẤT BẠI!',
                subtitle: 'Căn cứ nhà chính của ${_game.currentLevelConfig.title} đã sụp đổ!',
                icon: Icons.dangerous_outlined,
                iconColor: const Color(0xFFE53935),
                borderColor: const Color(0xFFE53935),
              );
            },
          ),

          // 7. OVERLAY MÀN HÌNH CHIẾN THẮNG (VICTORY DIALOG)
          ValueListenableBuilder<bool>(
            valueListenable: _game.isVictoryNotifier,
            builder: (context, isVictory, _) {
              if (!isVictory) return const SizedBox.shrink();
              return _buildEndGameDialog(
                isVictory: true,
                title: 'CHIẾN THẮNG HUY HOÀNG!',
                subtitle: 'Đã hoàn thành xuất sắc ${_game.currentLevelConfig.title}!',
                icon: Icons.emoji_events,
                iconColor: const Color(0xFFFFD54F),
                borderColor: const Color(0xFFFFD54F),
              );
            },
          ),

          // 8. OVERLAY MENU TẠM DỪNG (PAUSE MENU DIALOG)
          ValueListenableBuilder<bool>(
            valueListenable: _game.isPausedNotifier,
            builder: (context, isPaused, _) {
              if (!isPaused || _game.isGameOver || _game.isVictory) {
                return const SizedBox.shrink();
              }
              return _buildPauseDialog();
            },
          ),

          // 9. OVERLAY CÀI ĐẶT (SETTINGS MODAL OVERLAY)
          if (_showSettings)
            SettingsModal(
              onClose: () {
                setState(() {
                  _showSettings = false;
                });
              },
              onProgressReset: () async {
                _game.maxUnlockedLevelNotifier.value = 1;
                await _game.loadLevel(1);
                if (mounted) setState(() {});
              },
            ),

          // 10. OVERLAY BÁCH KHOA TOÀN THƯ (ENCYCLOPEDIA MODAL OVERLAY)
          if (_showEncyclopedia)
            EncyclopediaModal(
              onClose: () {
                setState(() {
                  _showEncyclopedia = false;
                });
              },
            ),
        ],
      ),
    );
  }

  /// Khay Kỹ Năng (Chỉ hiển thị các kỹ năng được mở khóa ở màn hiện tại)
  Widget _buildSkillBar(List<SkillType> unlockedSkills) {
    return ValueListenableBuilder<double>(
      valueListenable: _game.manaNotifier,
      builder: (context, mana, _) {
        return ValueListenableBuilder<SkillType?>(
          valueListenable: _game.selectedSkillForTargetingNotifier,
          builder: (context, targetingSkill, _) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xCC0E131C),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0x4429B6F6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: unlockedSkills.map((skillType) {
                  final skill = _game.skills[skillType]!;
                  final canAfford = mana >= skill.manaCost;
                  final isTargeting = targetingSkill == skillType;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _buildSkillButton(
                      skill: skill,
                      canAfford: canAfford,
                      isTargeting: isTargeting,
                      onTap: () {
                        setState(() {
                          _game.castSkill(skillType);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSkillButton({
    required SkillData skill,
    required bool canAfford,
    required bool isTargeting,
    required VoidCallback onTap,
  }) {
    final isReady = skill.isReady;
    final enabled = isReady && canAfford;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 42,
        padding: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isTargeting
              ? const Color(0xFFBF360C)
              : enabled
                  ? const Color(0xFF1E2838)
                  : const Color(0x6615171C),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isTargeting
                ? const Color(0xFFFF5722)
                : enabled
                    ? const Color(0xFF29B6F6)
                    : Colors.white24,
            width: isTargeting ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/${skill.iconAssetPath}',
                  width: 20,
                  height: 20,
                  errorBuilder: (_, __, ___) => const Icon(Icons.flash_on, size: 16, color: Colors.blue),
                ),
                if (!isReady)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${skill.currentCooldown.toInt()}s',
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              '${skill.manaCost.toInt()} MP',
              style: TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.bold,
                color: canAfford ? const Color(0xFF29B6F6) : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Khay Thẻ Bài Đặt Trụ (Chỉ hiển thị các trụ mở khóa ở màn hiện tại)
  Widget _buildPlantDeck(List<PlantType> unlockedPlants) {
    return ValueListenableBuilder<PlantType?>(
      valueListenable: _game.selectedPlantTypeNotifier,
      builder: (context, selectedType, _) {
        return ValueListenableBuilder<int>(
          valueListenable: _game.goldNotifier,
          builder: (context, gold, _) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xE6141820),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x6600E5FF), width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: unlockedPlants.map((plantType) {
                  final data = PlantData.fromType(plantType);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: _buildPlantCard(
                      type: plantType,
                      name: data.name,
                      cost: data.cost,
                      iconAsset: 'assets/${data.headSpritePath}',
                      isSelected: selectedType == plantType,
                      canAfford: gold >= data.cost,
                      onTap: () => _selectPlant(plantType),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  /// Modal Chọn Màn Chơi (Level Select Screen)
  Widget _buildLevelSelectModal() {
    return ValueListenableBuilder<int>(
      valueListenable: _game.maxUnlockedLevelNotifier,
      builder: (context, maxUnlocked, _) {
        return Container(
          color: Colors.black.withValues(alpha: 0.85),
          alignment: Alignment.center,
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141923),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x6600E5FF),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.map, color: Color(0xFF00E5FF), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'CHIẾN DỊCH: CHỌN MÀN CHƠI (1 - 8)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00E5FF),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showLevelSelect = false;
                        });
                      },
                      child: const Icon(Icons.close, size: 18, color: Colors.white70),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 16),
                // Lưới 8 Màn chơi (2 hàng x 4 cột)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: List.generate(8, (index) {
                    final lvl = index + 1;
                    final config = LevelConfig.getLevel(lvl);
                    final isUnlocked = lvl <= maxUnlocked;
                    final isCurrent = lvl == _game.currentLevelNumber;

                    return GestureDetector(
                      onTap: isUnlocked
                          ? () {
                              setState(() {
                                _showLevelSelect = false;
                                _game.loadLevel(lvl);
                              });
                            }
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 100,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFF004D40)
                              : isUnlocked
                                  ? const Color(0xFF1E2838)
                                  : const Color(0xFF151820),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isCurrent
                                ? const Color(0xFF00E5FF)
                                : isUnlocked
                                    ? const Color(0xFF4CAF50)
                                    : Colors.white12,
                            width: isCurrent ? 2.0 : 1.0,
                          ),
                        ),
                        child: Opacity(
                          opacity: isUnlocked ? 1.0 : 0.35,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isUnlocked ? Icons.play_arrow : Icons.lock,
                                    size: 13,
                                    color: isCurrent ? const Color(0xFF00E5FF) : Colors.amber,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'MÀN $lvl',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isCurrent ? const Color(0xFF00E5FF) : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                config.title.split(': ').last,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 8.5, color: Color(0xFFB0BEC5)),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '+${config.unlockedPlants.last.label.split(' (').first}',
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Color(0xFF81C784),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Bảng Điều Khiển Trụ (Plant Inspector Panel)
  Widget _buildPlantInspectorPanel(PlantComponent plant, int currentGold) {
    final data = plant.data;
    final canUpgrade = !data.isMaxLevel && currentGold >= data.upgradeCost;
    final upgradeCostText = data.isMaxLevel ? 'MAX' : '${data.upgradeCost} 🪙';

    return Container(
      width: 190,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xF2121722),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Image.asset(
                      'assets/${data.levelBadgePath}',
                      width: 15,
                      height: 15,
                      errorBuilder: (_, __, ___) => const Icon(Icons.star, size: 13, color: Colors.amber),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${data.name} (Lv.${data.level})',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00E5FF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  plant.isSelected = false;
                  _game.selectedPlantNotifier.value = null;
                },
                child: const Icon(Icons.close, size: 15, color: Colors.white70),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 8, thickness: 1),
          if (data.canAttack) ...[
            _buildInspectorStatRow('Sát thương:', '${data.damage.toInt()} dmg'),
            _buildInspectorStatRow(
              'Tốc độ bắn:',
              '${(1.0 / data.attackInterval).toStringAsFixed(1)} phát/s',
            ),
            _buildInspectorStatRow(
              'Tầm bắn:',
              '${data.rangeInTiles} ô (${data.rangeInPixels.toInt()} px)',
            ),
          ] else if (data.isProducer) ...[
            _buildInspectorStatRow('Sản lượng:', '+${data.goldProduceAmount} vàng'),
            _buildInspectorStatRow('Chu kỳ:', 'Mỗi ${data.goldProduceInterval}s'),
          ],
          _buildInspectorStatRow('Đã đầu tư:', '${data.totalInvestedGold} 🪙'),
          const SizedBox(height: 5),
          ElevatedButton(
            onPressed: canUpgrade
                ? () {
                    setState(() {
                      final ok = plant.upgrade();
                      if (ok) {
                        _game.placementFeedbackNotifier.value =
                            '🎉 Đã nâng cấp ${data.name} lên Level ${data.level}!';
                      }
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: data.isMaxLevel
                  ? const Color(0xFF424242)
                  : const Color(0xFF00897B),
              disabledBackgroundColor: const Color(0xFF2E3842),
              padding: const EdgeInsets.symmetric(vertical: 5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  data.isMaxLevel ? Icons.verified : Icons.arrow_upward,
                  size: 12,
                  color: Colors.white,
                ),
                const SizedBox(width: 3),
                Text(
                  data.isMaxLevel ? 'CẤP TỐI ĐA (MAX)' : 'Nâng cấp: $upgradeCostText',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: canUpgrade || data.isMaxLevel ? Colors.white : Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          OutlinedButton(
            onPressed: () {
              setState(() {
                final refund = plant.sell();
                _game.placementFeedbackNotifier.value =
                    '💰 Đã bán ${data.name} và thu hồi +$refund vàng (70%)!';
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE53935), width: 1),
              backgroundColor: const Color(0x33E53935),
              padding: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.delete_outline, size: 12, color: Color(0xFFFF8A80)),
                const SizedBox(width: 3),
                Text(
                  'Bán: +${data.sellRefund} 🪙 (Hoàn 70%)',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8A80),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog kết thúc trận đấu (Thắng / Thua) với điều hướng chọn màn
  Widget _buildEndGameDialog({
    required bool isVictory,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
  }) {
    final hasNextLevel = isVictory && _game.currentLevelNumber < 8;

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      alignment: Alignment.center,
      child: Container(
        width: 330,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF141923),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.35),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: iconColor),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: iconColor,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFFB0BEC5),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'Vàng tích lũy: ${_game.playerGold} 🪙',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD54F),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Nút Màn tiếp theo (Nếu Thắng và chưa hết màn 8)
                if (hasNextLevel) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _game.nextLevel();
                      });
                    },
                    icon: const Icon(Icons.arrow_forward, size: 14),
                    label: const Text('MÀN KẾ TIẾP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Nút Chơi Lại / Thử lại
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _game.restartCurrentLevel();
                    });
                  },
                  icon: const Icon(Icons.replay, size: 14),
                  label: Text(isVictory ? 'CHƠI LẠI' : 'THỬ LẠI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isVictory ? const Color(0xFF00897B) : const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),

                // Nút Chọn Màn khác
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _game.restartCurrentLevel();
                      _showLevelSelect = true;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00E5FF),
                    side: const BorderSide(color: Color(0xFF00E5FF)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  child: const Text('CHỌN MÀN'),
                ),

                // Nút Về Menu chính
                if (widget.onReturnToMenu != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: widget.onReturnToMenu,
                    icon: const Icon(Icons.home, size: 14),
                    label: const Text('MENU CHÍNH'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFD54F),
                      side: const BorderSide(color: Color(0xFFFFD54F)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Menu Tạm Dừng Trận Đấu (Pause Menu)
  Widget _buildPauseDialog() {
    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      alignment: Alignment.center,
      child: Container(
        width: 290,
        padding: const EdgeInsets.all(16),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause_circle_outline, size: 40, color: Color(0xFF00E5FF)),
            const SizedBox(height: 6),
            const Text(
              'TẠM DỪNG TRẬN ĐẤU',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00E5FF),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _game.currentLevelConfig.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFFB0BEC5),
              ),
            ),
            const Divider(color: Colors.white24, height: 16),
            // Nút Tiếp tục chơi
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _game.resume();
                });
              },
              icon: const Icon(Icons.play_arrow, size: 15),
              label: const Text('TIẾP TỤC CHƠI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
            ),
            const SizedBox(height: 6),
            // Nút Chơi lại màn này
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _game.restartCurrentLevel();
                });
              },
              icon: const Icon(Icons.replay, size: 14),
              label: const Text('CHƠI LẠI MÀN NÀY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF37474F),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
            ),
            const SizedBox(height: 6),
            // Nút Danh sách màn
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _game.resume();
                  _showLevelSelect = true;
                });
              },
              icon: const Icon(Icons.map, size: 14),
              label: const Text('DANH SÁCH MÀN'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00E5FF),
                side: const BorderSide(color: Color(0xFF00E5FF)),
                minimumSize: const Size.fromHeight(32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
            ),
            if (widget.onReturnToMenu != null) ...[
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _confirmReturnToMenu,
                icon: const Icon(Icons.home, size: 14),
                label: const Text('VỀ MENU CHÍNH'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFD54F),
                  side: const BorderSide(color: Color(0xFFFFD54F)),
                  minimumSize: const Size.fromHeight(32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmReturnToMenu() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141923),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.home, color: Color(0xFF00E5FF), size: 20),
            SizedBox(width: 8),
            Text(
              'Rời Khỏi Trận Đấu?',
              style: TextStyle(fontSize: 14, color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn rời trận đấu hiện tại để trở về Menu Chính? Tiến trình trận đấu này sẽ không được lưu.',
          style: TextStyle(fontSize: 11, color: Color(0xFFB0BEC5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('TIẾP TỤC CHƠI', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onReturnToMenu?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
            ),
            child: const Text('VỀ MENU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF90A4AE)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _selectPlant(PlantType type) {
    _game.selectedPlantNotifier.value?.isSelected = false;
    _game.selectedPlantNotifier.value = null;
    _game.selectedSkillForTargetingNotifier.value = null;

    if (_game.selectedPlantTypeNotifier.value == type) {
      _game.selectedPlantTypeNotifier.value = null;
      _game.placementFeedbackNotifier.value = 'Đã bỏ chọn trụ. Nhấn thẻ bên dưới để chọn!';
    } else {
      _game.selectedPlantTypeNotifier.value = type;
      final data = PlantData.fromType(type);
      _game.placementFeedbackNotifier.value = 'Đang chọn ${data.name} (${data.cost}G) - Chạm ô cỏ để đặt!';
    }
  }

  Widget _buildPlantCard({
    required PlantType type,
    required String name,
    required int cost,
    required String iconAsset,
    required bool isSelected,
    required bool canAfford,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected
        ? const Color(0xFF00E5FF)
        : canAfford
            ? const Color(0xFF4CAF50)
            : Colors.white24;

    return GestureDetector(
      onTap: canAfford ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF004D40)
              : canAfford
                  ? const Color(0xFF1E2430)
                  : const Color(0x6615171C),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Opacity(
          opacity: canAfford ? 1.0 : 0.45,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                iconAsset,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.shield, size: 16, color: Colors.green),
              ),
              const SizedBox(height: 1),
              Text(
                name,
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? const Color(0xFF00E5FF) : Colors.white,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, size: 8, color: Color(0xFFFFD54F)),
                  const SizedBox(width: 1),
                  Text(
                    '${cost}G',
                    style: const TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD54F),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 11),
          const SizedBox(width: 2.5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
