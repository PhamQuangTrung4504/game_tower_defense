import 'package:flutter/material.dart';
import '../models/enemy_type.dart';
import '../models/plant_data.dart';

/// Hộp thoại Bách Khoa Toàn Thư (Encyclopedia / Almanac Modal)
///
/// Cho phép người chơi tra cứu chi tiết thông số, điểm mạnh, điểm yếu và cơ chế
/// của 8 loại Trụ phòng thủ (Plants) và 10 loại Quái vật (Monsters).
class EncyclopediaModal extends StatefulWidget {
  const EncyclopediaModal({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  State<EncyclopediaModal> createState() => _EncyclopediaModalState();
}

class _EncyclopediaModalState extends State<EncyclopediaModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  PlantType _selectedPlant = PlantType.peashooter;
  EnemyType _selectedEnemy = EnemyType.greenSlime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final modalWidth = (screenSize.width * 0.92).clamp(320.0, 580.0);
    final modalHeight = (screenSize.height * 0.92).clamp(260.0, 330.0);

    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black.withValues(alpha: 0.88),
        alignment: Alignment.center,
        child: Container(
          width: modalWidth,
          height: modalHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            // Thanh tiêu đề và nút Đóng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.menu_book, color: Color(0xFF00E5FF), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'BÁCH KHOA TOÀN THƯ CHIẾN THUẬT',
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
            const SizedBox(height: 6),

            // Tab bar chọn Trụ / Quái
            Container(
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: const Color(0xFF00897B),
                  borderRadius: BorderRadius.circular(5),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF90A4AE),
                labelStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'TRỤ PHÒNG THỦ (8 LOÀI)'),
                  Tab(text: 'QUÁI VẬT TẤN CÔNG (10 LOÀI)'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Nội dung tab
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPlantsTab(),
                  _buildMonstersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  /// Tab tra cứu Trụ phòng thủ
  Widget _buildPlantsTab() {
    final plantData = PlantData.fromType(_selectedPlant);

    final info = _getPlantEncyclopediaInfo(_selectedPlant);

    return Row(
      children: [
        // Danh sách chọn nhanh 8 trụ (Cột trái)
        SizedBox(
          width: 170,
          child: ListView.separated(
            itemCount: PlantType.values.length,
            separatorBuilder: (_, __) => const SizedBox(height: 3),
            itemBuilder: (context, index) {
              final type = PlantType.values[index];
              final data = PlantData.fromType(type);
              final isSelected = type == _selectedPlant;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPlant = type;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF004D40) : const Color(0xFF1B2230),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF00E5FF) : Colors.white12,
                      width: isSelected ? 1.4 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/${data.headSpritePath}',
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.shield, size: 16, color: Colors.green),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.name,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFF00E5FF) : Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${data.cost} Gold',
                              style: const TextStyle(fontSize: 8, color: Color(0xFFFFD54F)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const VerticalDivider(color: Colors.white24, width: 14),

        // Khung chi tiết chỉ số & cơ chế đặc trưng (Cột phải)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white12),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/${plantData.headSpritePath}',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.shield, size: 24, color: Colors.green),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plantData.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00E5FF),
                              ),
                            ),
                            Text(
                              'Vai trò: ${info.role} • Cấp tối đa: Lv3',
                              style: const TextStyle(fontSize: 9, color: Color(0xFFB0BEC5)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2515),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFFFD54F)),
                        ),
                        child: Text(
                          '${plantData.cost} G',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD54F),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 12),

                  // Lưới chỉ số
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _buildStatRow('Sát thương:', plantData.damage > 0 ? '${plantData.damage.toInt()}' : 'Không'),
                      _buildStatRow('Tầm bắn:', '${plantData.rangeInTiles} ô'),
                      _buildStatRow('Tốc độ bắn:', '${plantData.attackInterval}s / phát'),
                      if (plantData.isProducer)
                        _buildStatRow('Kinh tế:', '+${plantData.goldProduceAmount}G / ${plantData.goldProduceInterval}s'),
                      if (plantData.slowDuration > 0)
                        _buildStatRow('Làm chậm:', '-${((1.0 - plantData.slowFactor) * 100).toInt()}% trong ${plantData.slowDuration}s'),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Đặc tính và chiến thuật
                  const Text(
                    'Đặc tính chiến đấu:',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    info.description,
                    style: const TextStyle(fontSize: 9, color: Color(0xFFCFD8DC), height: 1.25),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Mẹo chiến thuật:',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFFFD54F)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    info.tip,
                    style: const TextStyle(fontSize: 9, color: Color(0xFFFFE082), height: 1.25),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Tab tra cứu Quái vật
  Widget _buildMonstersTab() {
    final monster = MonsterData.fromType(_selectedEnemy);
    final info = _getMonsterEncyclopediaInfo(_selectedEnemy);

    return Row(
      children: [
        // Danh sách chọn nhanh 10 quái vật (Cột trái)
        SizedBox(
          width: 170,
          child: ListView.separated(
            itemCount: EnemyType.values.length,
            separatorBuilder: (_, __) => const SizedBox(height: 3),
            itemBuilder: (context, index) {
              final type = EnemyType.values[index];
              final data = MonsterData.fromType(type);
              final isSelected = type == _selectedEnemy;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedEnemy = type;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (data.isBoss ? const Color(0xFF5D1212) : const Color(0xFF311B92))
                        : const Color(0xFF1B2230),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isSelected ? (data.isBoss ? Colors.redAccent : const Color(0xFF00E5FF)) : Colors.white12,
                      width: isSelected ? 1.4 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/${data.spritePath}',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.bug_report, size: 16, color: Colors.red),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.name,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? (data.isBoss ? const Color(0xFFFF8A80) : const Color(0xFF00E5FF))
                                    : Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${data.maxHp.toInt()} HP • ${data.goldReward}G',
                              style: const TextStyle(fontSize: 8, color: Color(0xFF90A4AE)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const VerticalDivider(color: Colors.white24, width: 14),

        // Khung chi tiết quái vật (Cột phải)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: monster.isBoss ? const Color(0xFFE53935) : Colors.white12,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/${monster.spritePath}',
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.bug_report, size: 28, color: Colors.red),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              monster.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: monster.isBoss ? const Color(0xFFFF5252) : const Color(0xFF00E5FF),
                              ),
                            ),
                            Text(
                              monster.isBoss ? 'Cấp Độ: ĐẠI TRÙM CHIẾN DỊCH' : 'Phân loại: Quái Vật Tấn Công',
                              style: TextStyle(
                                fontSize: 9,
                                color: monster.isBoss ? const Color(0xFFFF8A80) : const Color(0xFFB0BEC5),
                                fontWeight: monster.isBoss ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C1517),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFE53935)),
                        ),
                        child: Text(
                          '${monster.maxHp.toInt()} HP',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 12),

                  // Lưới chỉ số quái
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _buildStatRow('Máu cơ bản:', '${monster.maxHp.toInt()} HP'),
                      _buildStatRow('Vận tốc:', '${monster.speed} (${monster.basePixelSpeed.toStringAsFixed(0)} px/s)'),
                      _buildStatRow('Phần thưởng:', '+${monster.goldReward} Gold'),
                      _buildStatRow('Sát thương nhà chính:', monster.isBoss ? '5 HP' : '1 HP'),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Đặc tính và cách khắc chế
                  const Text(
                    'Đặc tính sinh học:',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    info.traits,
                    style: const TextStyle(fontSize: 9, color: Color(0xFFCFD8DC), height: 1.25),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Chiến thuật khắc chế:',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFFF5252)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    info.counter,
                    style: const TextStyle(fontSize: 9, color: Color(0xFFFFAB91), height: 1.25),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 8.5, color: Color(0xFF90A4AE)),
        ),
        const SizedBox(width: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  _PlantExtraInfo _getPlantEncyclopediaInfo(PlantType type) {
    return switch (type) {
      PlantType.peashooter => const _PlantExtraInfo(
          role: 'Tấn Công Cơ Bản',
          description: 'Bắn những viên đạn đậu xanh bay thẳng với tốc độ ổn định. Là lá chắn đầu tiên của mọi chiến dịch.',
          tip: 'Xây dựng sớm ở đầu trận để tích lũy hỏa lực giá rẻ, dễ nâng cấp lên Lv2.',
        ),
      PlantType.sunflower => const _PlantExtraInfo(
          role: 'Kinh Tế Nông Nghiệp',
          description: 'Không tham gia tấn công trực tiếp. Tự động tích lũy năng lượng mặt trời và sản xuất 25 Gold mỗi 8 giây.',
          tip: 'Nên đặt ở các ô đất phía sau hoặc góc khuất để bảo đảm nguồn thu kinh tế liên tục.',
        ),
      PlantType.clover => const _PlantExtraInfo(
          role: 'Bắn Tỏa Đa Hướng / Xuyên Mục Tiêu',
          description: 'Phóng ra 3 tia lá phong sắc bén theo hình quạt, có khả năng xuyên qua nhiều kẻ thù cùng lúc.',
          tip: 'Rất hiệu quả khi đặt ở các khúc cua chữ U hoặc đoạn đường quái tập trung đi đông đảo.',
        ),
      PlantType.iceShroom => const _PlantExtraInfo(
          role: 'Khống Chế Làm Chậm',
          description: 'Bắn những bông tuyết băng giá làm giảm 50% tốc độ di chuyển của mục tiêu trong 2.5 giây.',
          tip: 'Kết hợp hoàn hảo với các trụ sát thương lớn như Melon-pult để quái dính trọn vùng nổ.',
        ),
      PlantType.firePeashooter => const _PlantExtraInfo(
          role: 'Sát Thương Đơn Mục Tiêu & Thiêu Đốt',
          description: 'Bắn ra những quả cầu lửa rực cháy, gây sát thương trực diện lớn và kích hoạt hiệu ứng thiêu đốt kéo dài.',
          tip: 'Đặc biệt mạnh mẽ khi đối đầu quái trâu máu hoặc phá giáp Armored Scorpion.',
        ),
      PlantType.electricShroom => const _PlantExtraInfo(
          role: 'Phóng Điện Dây Chuyền (Chain Lightning)',
          description: 'Phóng ra luồng điện cực mạnh gián tiếp truyền sang các mục tiêu lân cận, triệt tiêu đội hình bầy đàn.',
          tip: 'Cực kỳ lợi hại khi dọn dẹp các đợt quái bay dơi (Red-eyed Bat) hoặc bầy chó săn (Purple Hound).',
        ),
      PlantType.starfruit => const _PlantExtraInfo(
          role: 'Bắn 5 Hướng Tinh Tú',
          description: 'Bắn đồng thời 5 phi tiêu ngôi sao tỏa ra 5 hướng không gian, bao quát diện tích rộng lớn của bản đồ.',
          tip: 'Đặt ở các giao lộ trung tâm nơi quái vật di chuyển qua lại nhiều lần quanh trụ.',
        ),
      PlantType.melonPult => const _PlantExtraInfo(
          role: 'Pháo Binh Diện Rộng (Splash Damage)',
          description: 'Bắn những quả dưa hấu nặng trịch phát nổ khi chạm đất, gây chấn động toàn bộ kẻ địch trong bán kính 60px.',
          tip: 'Vũ khí hạng nặng đắt đỏ nhất. Nâng cấp lên Lv3 có thể hủy diệt cả một đạo quân chỉ trong vài phát bắn.',
        ),
    };
  }

  _MonsterExtraInfo _getMonsterEncyclopediaInfo(EnemyType type) {
    return switch (type) {
      EnemyType.greenSlime => const _MonsterExtraInfo(
          traits: 'Khối chất nhầy màu xanh lá, tốc độ và lượng máu ở mức trung bình. Thường xuất hiện ở các Wave đầu tiên.',
          counter: 'Bất kỳ loại trụ nào cũng có thể tiêu diệt dễ dàng. Chỉ cần 1-2 Peashooter là đủ phòng ngự.',
        ),
      EnemyType.purpleSnake => const _MonsterExtraInfo(
          traits: 'Rắn độc tím bò uốn lượn với tốc độ khá nhanh, có phản xạ lách người để né các loại đạn bay thẳng chậm chạp.',
          counter: 'Sử dụng Ice-shroom để làm chậm hoặc dùng Clover có góc bắn tỏa rộng để không bị né.',
        ),
      EnemyType.redEyedBat => const _MonsterExtraInfo(
          traits: 'Dơi mắt đỏ bay trên không trung với tốc độ cao, thường xuất hiện theo bầy đàn đông đúc.',
          counter: 'Ưu tiên sử dụng Clover bắn tỏa hoặc Electric-shroom phóng điện lan truyền để quét sạch bầy dơi.',
        ),
      EnemyType.purpleHound => const _MonsterExtraInfo(
          traits: 'Chó săn bóng tối sở hữu tốc độ nước rút cực nhanh (1.6 ô/giây). Có thể đột phá phòng tuyến nếu thiếu hỏa lực tức thì.',
          counter: 'Bắt buộc phải có Ice-shroom chặn đầu hoặc dùng Kỹ Năng Trói Ma Thuật (Magic Bind) để giam chân.',
        ),
      EnemyType.armoredScorpion => const _MonsterExtraInfo(
          traits: 'Bọ cạp thiết giáp sở hữu lớp vỏ cứng cáp, tự nhiên giảm 50% sát thương từ các loại đạn vật lý thông thường.',
          counter: 'Khắc chế bằng sát thương nguyên tố: Đậu Lửa (Fire Peashooter) hoặc Nấm Sét (Electric-shroom).',
        ),
      EnemyType.basicZombie => const _MonsterExtraInfo(
          traits: 'Xác sống lầm lũi tiến về phía trước. Lượng máu dồi dào (150 HP), bước đi đều đặn không biết mệt mỏi.',
          counter: 'Nâng cấp trụ lên Cấp 2 hoặc Cấp 3 để bảo đảm mật độ sát thương đủ tiêu diệt trước khi chạm căn cứ.',
        ),
      EnemyType.cyborgRunner => const _MonsterExtraInfo(
          traits: 'Người máy sinh học chạy nhanh. Khi máu tụt xuống dưới 30%, hệ thống khẩn cấp sẽ kích hoạt trạng thái cuồng nộ tăng tốc.',
          counter: 'Dồn sát thương kết liễu nhanh chóng bằng đạn nổ Melon-pult hoặc dùng Thiên Thạch (Meteorite).',
        ),
      EnemyType.capZombie => const _MonsterExtraInfo(
          traits: 'Zombie đội mũ bảo hộ cứng cáp, có lượng máu lên tới 260 HP, là khiên chắn sống cho các quái vật đi sau.',
          counter: 'Dùng Clover và Melon-pult để gây sát thương xuyên qua hoặc quét sạch những kẻ địch đi nấp phía sau.',
        ),
      EnemyType.whitePhantom => const _MonsterExtraInfo(
          traits: 'Bóng ma quỷ quái lướt đi trong hư vô, có khả năng tàng hình và tự hồi phục dần thể lực theo thời gian.',
          counter: 'Kỹ năng Bão Vàng hoặc sét đánh liên hồi từ Electric-shroom sẽ làm lộ diện và triệt tiêu khả năng hồi phục.',
        ),
      EnemyType.darkTitan => const _MonsterExtraInfo(
          traits: 'ĐẠI TRÙM CHIẾN DỊCH (Boss) sở hữu 3000 HP! Hoàn toàn kháng làm chậm từ băng tuyết, giảm 50% thời gian trói ma thuật và trừ 5 HP nếu đột nhập nhà chính.',
          counter: 'Phối hợp toàn diện: Nâng cấp dàn trụ hỏa lực tối đa (Lv3), sử dụng Thiên Thạch Rơi liên tục và căn chuẩn thời gian kích hoạt Bão Vàng để gia tăng ngân sách!',
        ),
    };
  }
}

class _PlantExtraInfo {
  const _PlantExtraInfo({
    required this.role,
    required this.description,
    required this.tip,
  });

  final String role;
  final String description;
  final String tip;
}

class _MonsterExtraInfo {
  const _MonsterExtraInfo({
    required this.traits,
    required this.counter,
  });

  final String traits;
  final String counter;
}
