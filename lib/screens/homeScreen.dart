import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show LinearProgressIndicator, RefreshIndicator, Scaffold, CircularProgressIndicator, Colors;
import 'package:flutter/material.dart' show required;
import 'package:bp_notepad/db/nutrition_databaseProvider.dart';
import 'package:bp_notepad/db/bp_databaseProvider.dart';
import 'package:bp_notepad/db/bs_databaseProvider.dart';
import 'package:bp_notepad/db/body_databaseProvider.dart';
import 'package:bp_notepad/db/alarm_databaseProvider.dart';
import 'package:bp_notepad/db/hr_databaseProvider.dart';
import 'package:bp_notepad/db/sleep_databaseProvider.dart';
import 'package:bp_notepad/models/bpDBModel.dart';
import 'package:bp_notepad/models/bsDBModel.dart';
import 'package:bp_notepad/models/bodyModel.dart';
import 'package:bp_notepad/models/hrDBModel.dart';
import 'package:bp_notepad/models/sleepDBModel.dart';
import 'package:bp_notepad/screens/userScreen.dart';
import 'package:bp_notepad/screens/addScreen.dart';
import 'package:bp_notepad/theme.dart';
import 'package:bp_notepad/screens/FunctionScreen/aiDoctorScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  double _totalCalories = 0;
  double _totalProtein = 0;
  double _totalCarbs = 0;
  double _totalFat = 0;
  int _mealCount = 0;
  int _reminderCount = 0;
  int _steps = 0;

  BloodPressureDB _latestBP;
  BloodSugarDB _latestBS;
  BodyDB _latestBMI;
  int _latestHR;
  double _latestSleep;

  // Color
  static const Color _primaryGreen = Color(0xFF00BFA5);
  static const Color _bpRed = Color(0xFFFF5252);
  static const Color _bsBlue = Color(0xFF448AFF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    
    isDarkModeGlobal.addListener(_onDarkModeChanged);
  }

  void _onDarkModeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    isDarkModeGlobal.removeListener(_onDarkModeChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    var meals = await NutritionDatabaseProvider.getMealsByDate(DateTime.now());
    var bpList = await BpDataBaseProvider.db.getData();
    var bsList = await BsDataBaseProvider.db.getData();
    var bodyList = await BodyDataBaseProvider.db.getData();
    var alarmList = await AlarmDataBaseProvider.db.getData();
    var hrList = await HeartRateDataBaseProvider.db.getData();
    var sleepList = await SleepDataBaseProvider.db.getData();

    double totalC = 0, totalP = 0, totalCarb = 0, totalF = 0;
    for (var meal in meals) {
      totalC += meal.calories;
      totalP += meal.protein;
      totalCarb += meal.carbs;
      totalF += meal.fat;
    }

    BloodPressureDB latestBP;
    if (bpList.isNotEmpty) {
      bpList.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
      latestBP = bpList.first;
    }

    BloodSugarDB latestBS;
    if (bsList.isNotEmpty) {
      bsList.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
      latestBS = bsList.first;
    }

    BodyDB latestBMI;
    if (bodyList.isNotEmpty) {
      bodyList.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
      latestBMI = bodyList.first;
    }

    HeartRateDB latestHRData;
    if (hrList.isNotEmpty) {
      hrList.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
      latestHRData = hrList.first;
    }

    SleepDB latestSleepData;
    if (sleepList.isNotEmpty) {
      sleepList.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
      latestSleepData = sleepList.first;
    }

    int activeReminders = alarmList.where((a) => a.state == '1').length;

    setState(() {
      _totalCalories = totalC;
      _totalProtein = totalP;
      _totalCarbs = totalCarb;
      _totalFat = totalF;
      _mealCount = meals.length;
      _latestBP = latestBP;
      _latestBS = latestBS;
      _latestBMI = latestBMI;
      _latestHR = latestHRData?.hr?.toInt();
      _latestSleep = latestSleepData?.sleep?.toDouble() ?? 0;
      _reminderCount = activeReminders;
      _steps = 0;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode;
    return Scaffold(
      backgroundColor: AppTheme.background(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(
              color: isDark ? Colors.white : _primaryGreen,
            ))
          : RefreshIndicator(
        onRefresh: _loadData,
        color: _primaryGreen,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroBanner(),
                  const SizedBox(height: 20),
                  _buildSectionHeader('Nhật ký sức khỏe'),
                  const SizedBox(height: 12),
                  _buildHealthJournalGrid(),
                  const SizedBox(height: 20),
                  _buildSectionHeader('Tính năng khác'),
                  const SizedBox(height: 12),
                  _buildExtraFeatures(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return CupertinoSliverNavigationBar(
      largeTitle: Text(
        'theo dõi',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary(),
        ),
      ),
      backgroundColor: AppTheme.background().withOpacity(0.95),
      border: null,
      trailing: _buildWeatherBadge(),
    );
  }

  Widget _buildWeatherBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _primaryGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(CupertinoIcons.cloud_fill, color: CupertinoColors.white, size: 14),
          SizedBox(width: 4),
          Text(
            '26°C',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Banner (green card) ─────────────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: _primaryGreen,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Decorative circle
            Positioned(
              left: -20,
              bottom: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: -10,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            // Heart + fingerprint icon area
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.heart_fill,
                    color: CupertinoColors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
            // Measure now button
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _navigateToAdd(0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Đo ngay',
                          style: TextStyle(
                            color: _primaryGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(CupertinoIcons.arrow_right, color: _primaryGreen, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom row
            Positioned(
              bottom: 14,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.doc_text, color: CupertinoColors.white, size: 13),
                      const SizedBox(width: 6),
                      Text(
                        'Báo cáo cuối cùng: ${_latestBP != null ? '${_latestBP.sbp}/${_latestBP.dbp}' : '--'}',
                        style: TextStyle(
                          color: CupertinoColors.white.withOpacity(0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Row(
                      children: [
                        Text(
                          'Lịch sử',
                          style: TextStyle(
                            color: CupertinoColors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                        Icon(CupertinoIcons.chevron_right,
                            color: CupertinoColors.white.withOpacity(0.85), size: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Header ───────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(CupertinoIcons.book_fill, color: _primaryGreen, size: 16),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Health Journal Grid (2 columns) ─────────────────────────────────────────
  Widget _buildHealthJournalGrid() {
    final items = [
      _JournalItem(
        title: 'Huyết áp',
        value: _latestBP != null ? '${_latestBP.sbp}/${_latestBP.dbp}' : '--/--',
        unit: 'mmHg',
        valueColor: _bpRed,
        bgColor: const Color(0xFFFFF0EF),
        icon: 'assets/icons/bp.png', // replace with actual asset
        onTap: () => _navigateToAdd(0),
        fallbackIcon: CupertinoIcons.heart_fill,
        iconColor: _bpRed,
      ),
      _JournalItem(
        title: 'Đường huyết',
        value: _latestBS != null ? _latestBS.glu.toStringAsFixed(1) : '--',
        unit: 'mmol/L',
        valueColor: const Color(0xFFFF9500),
        bgColor: const Color(0xFFFFF8EC),
        onTap: () => _navigateToAdd(1),
        fallbackIcon: CupertinoIcons.drop_fill,
        iconColor: const Color(0xFFFF9500),
      ),
      _JournalItem(
        title: 'Cân nặng & chỉ số BMI',
        value: _latestBMI != null ? '${_latestBMI.weight}' : '--',
        unit: 'KG',
        valueColor: _bsBlue,
        bgColor: const Color(0xFFEEF4FF),
        onTap: () => _navigateToAdd(2),
        fallbackIcon: CupertinoIcons.person_fill,
        iconColor: _bsBlue,
      ),
      _JournalItem(
        title: 'Nhắc nhở uống nước.',
        value: '600',
        unit: '/2000ml',
        valueColor: _primaryGreen,
        bgColor: const Color(0xFFEDF7F0),
        onTap: () {},
        fallbackIcon: CupertinoIcons.drop,
        iconColor: _primaryGreen,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) => _buildJournalCard(items[i]),
      ),
    );
  }

  Widget _buildJournalCard(_JournalItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.bgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(),
              ),
              maxLines: 2,
            ),
            const Spacer(),
            // Icon/illustration area
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: item.iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.fallbackIcon, color: item.iconColor, size: 26),
              ),
            ),
            const SizedBox(height: 8),
            // Value row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: item.valueColor,
                  ),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    item.unit,
                    style: TextStyle(
                      fontSize: 11,
                      color: item.valueColor.withOpacity(0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Extra Features (AI Doctor, Food Scanner) ─────────────────────────────────
  Widget _buildExtraFeatures() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
        children: [
          _buildFeatureCard(
            title: 'bác sĩ AI',
            bgColor: const Color(0xFFFFF0F5),
            iconColor: const Color(0xFFFF2D55),
            icon: CupertinoIcons.person_crop_circle_fill,
            onTap: () => _openAiDoctor(),
          ),
          _buildFeatureCard(
            title: 'Máy quét thực phẩm',
            bgColor: const Color(0xFFFFF8EC),
            iconColor: const Color(0xFFFF9500),
            icon: CupertinoIcons.barcode_viewfinder,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _openAiDoctor() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => AiDoctorScreen(),
      ),
    );
  }

  Widget _buildFeatureCard({
    String title,
    Color bgColor,
    Color iconColor,
    IconData icon,
    VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(),
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAdd(int index) {
    Navigator.push(context, CupertinoPageRoute(builder: (_) => AddScreen()));
  }

  String _formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }
}

// ── Data model for journal cards ─────────────────────────────────────────────
class _JournalItem {
  final String title;
  final String value;
  final String unit;
  final Color valueColor;
  final Color bgColor;
  final Color iconColor;
  final IconData fallbackIcon;
  final String icon;
  final VoidCallback onTap;

  _JournalItem({
    @required this.title,
    @required this.value,
    @required this.unit,
    @required this.valueColor,
    @required this.bgColor,
    @required this.iconColor,
    this.fallbackIcon,
    this.icon,
    this.onTap,
  });
}