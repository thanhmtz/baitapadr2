import 'package:flutter/cupertino.dart';
<<<<<<< HEAD
import 'package:flutter/material.dart'
    show LinearProgressIndicator, RefreshIndicator, Scaffold, CircularProgressIndicator, Colors;
import 'package:flutter/material.dart' show required;
import 'package:bp_notepad/db/nutrition_databaseProvider.dart';
=======
import 'package:flutter/material.dart';
>>>>>>> c433f0958c7b131a6e19678efbcfbebc3e6d3df1
import 'package:bp_notepad/db/bp_databaseProvider.dart';
import 'package:bp_notepad/db/bs_databaseProvider.dart';
import 'package:bp_notepad/db/body_databaseProvider.dart';
import 'package:bp_notepad/db/alarm_databaseProvider.dart';
import 'package:bp_notepad/db/hr_databaseProvider.dart';
import 'package:bp_notepad/db/sleep_databaseProvider.dart';
import 'package:bp_notepad/db/nutrition_databaseProvider.dart';
import 'package:bp_notepad/models/bpDBModel.dart';
import 'package:bp_notepad/models/bsDBModel.dart';
import 'package:bp_notepad/models/bodyModel.dart';
import 'package:bp_notepad/models/hrDBModel.dart';
import 'package:bp_notepad/models/sleepDBModel.dart';
<<<<<<< HEAD
import 'package:bp_notepad/screens/userScreen.dart';
import 'package:bp_notepad/screens/addScreen.dart';
import 'package:bp_notepad/theme.dart';
import 'package:bp_notepad/screens/FunctionScreen/aiDoctorScreen.dart';
=======
import 'package:bp_notepad/screens/FunctionScreen/bpScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/bsScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/bmiScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/heartRateScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/nutritionScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/waterReminderScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/healthTrackingScreen.dart';

// ─── Color tokens ─────────────────────────────────────────────────────────────
const _green       = Color(0xFF3DAA72);
const _greenLight  = Color(0xFF4EC98A);
const _greenBg     = Color(0xFFEAF7F0);
const _redAccent   = Color(0xFFFF6B6B);
const _blueAccent  = Color(0xFF4A9EFF);
const _orangeAccent= Color(0xFFFF9F43);
const _purpleAccent= Color(0xFF9B59B6);
const _pageBg      = Color(0xFFF4F6F9);
const _cardBg      = Color(0xFFFFFFFF);
const _textPrimary = Color(0xFF1A2332);
const _textSec     = Color(0xFF7A8699);
>>>>>>> c433f0958c7b131a6e19678efbcfbebc3e6d3df1

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
<<<<<<< HEAD
  double _totalCalories = 0;
  double _totalProtein = 0;
  double _totalCarbs = 0;
  double _totalFat = 0;
  int _mealCount = 0;
  int _reminderCount = 0;
  int _steps = 0;
=======
>>>>>>> c433f0958c7b131a6e19678efbcfbebc3e6d3df1

  BloodPressureDB _latestBP;
  BloodSugarDB    _latestBS;
  BodyDB          _latestBMI;
  int             _latestHR;
  double          _latestSleep;

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
    final bpList   = await BpDataBaseProvider.db.getData();
    final bsList   = await BsDataBaseProvider.db.getData();
    final bodyList = await BodyDataBaseProvider.db.getData();
    final hrList   = await HeartRateDataBaseProvider.db.getData();
    final sleepList= await SleepDataBaseProvider.db.getData();

    if (bpList.isNotEmpty)   { bpList.sort((a,b)=>DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));     _latestBP    = bpList.first; }
    if (bsList.isNotEmpty)   { bsList.sort((a,b)=>DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));     _latestBS    = bsList.first; }
    if (bodyList.isNotEmpty) { bodyList.sort((a,b)=>DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));   _latestBMI   = bodyList.first; }
    if (hrList.isNotEmpty)   { hrList.sort((a,b)=>DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));     _latestHR    = hrList.first.hr; }
    if (sleepList.isNotEmpty){ sleepList.sort((a,b)=>DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));  _latestSleep = sleepList.first.sleep; }

    setState(() => _isLoading = false);
  }

<<<<<<< HEAD
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
=======
  String _fmt(String date) {
    try { final d = DateTime.parse(date); return '${d.day}/${d.month}'; } catch (_) { return date; }
>>>>>>> c433f0958c7b131a6e19678efbcfbebc3e6d3df1
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode;
    return Scaffold(
<<<<<<< HEAD
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
=======
      backgroundColor: _pageBg,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _green))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: _green,
              child: CustomScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildSliverHeader(),
                  SliverToBoxAdapter(child: _buildBanner()),
                  SliverToBoxAdapter(child: _buildSectionLabel('📓 Nhật ký sức khỏe')),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverGrid(
                      delegate: SliverChildListDelegate([
                        _buildHealthCard(
                          title: 'Huyết áp',
                          value: _latestBP != null ? '${_latestBP.sbp}/${_latestBP!.dbp}' : '--/--',
                          unit: 'mmHg',
                          sub: _latestBP != null ? _fmt(_latestBP.date) : 'Chưa có dữ liệu',
                          accentColor: _redAccent,
                          bgColor: Color(0xFFFFF0F0),
                          imagePath: 'assets/images/bp_device.png',
                          onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => BloodPressure())),
                        ),
                        _buildHealthCard(
                          title: 'Đường huyết',
                          value: _latestBS != null ? _latestBS!.glu.toStringAsFixed(1) : '--',
                          unit: 'mmol/L',
                          sub: _latestBS != null ? _fmt(_latestBS!.date) : 'Chưa có dữ liệu',
                          accentColor: _redAccent,
                          bgColor: Color(0xFFFFF5F5),
                          imagePath: 'assets/images/bs_device.png',
                          onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => BloodSugar())),
                        ),
                        _buildHealthCard(
                          title: 'Cân nặng & chỉ số BMI',
                          value: _latestBMI != null ? '${_latestBMI!.weight.toStringAsFixed(1)}' : '--',
                          unit: 'KG',
                          sub: _latestBMI != null ? 'BMI: ${_latestBMI!.bmi.toStringAsFixed(1)}' : 'Chưa có dữ liệu',
                          accentColor: _blueAccent,
                          bgColor: Color(0xFFF0F5FF),
                          imagePath: 'assets/images/scale.png',
                          onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => BmiScreen())),
                        ),
                        _buildHealthCard(
                          title: 'Nhắc nhở uống nước',
                          value: '600',
                          unit: '/2000ml',
                          sub: 'Hôm nay',
                          accentColor: _orangeAccent,
                          bgColor: Color(0xFFFFF8EE),
                          imagePath: 'assets/images/water_bottle.png',
                          onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => WaterReminderScreen())),
                        ),
                        _buildHealthCard(
                          title: 'Nhịp tim',
                          value: _latestHR != null ? '$_latestHR' : '--',
                          unit: 'bpm',
                          sub: _latestHR != null ? 'Gần nhất' : 'Chưa có dữ liệu',
                          accentColor: _redAccent,
                          bgColor: Color(0xFFFFF0F0),
                          imagePath: 'assets/images/heart.png',
                          onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => HeartRateScreen())),
                        ),
                        _buildHealthCard(
                          title: 'Dinh dưỡng',
                          value: '--',
                          unit: 'kcal',
                          sub: 'Hôm nay',
                          accentColor: _purpleAccent,
                          bgColor: Color(0xFFF8F0FF),
                          imagePath: 'assets/images/nutrition.png',
                          onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => NutritionScreen())),
                        ),
                      ]),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.95,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              ),
            ),
    );
  }

  // ─── Sliver header ────────────────────────────────────────────────────────
  Widget _buildSliverHeader() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: _cardBg,
      toolbarHeight: 64,
      title: Row(
        children: [
          Text(
            'theo dõi',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          Spacer(),
          // Weather chip
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _greenBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.cloud_fill, size: 14, color: _green),
                SizedBox(width: 5),
                Text('26°C', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _green)),
              ],
            ),
          ),
        ],
>>>>>>> c433f0958c7b131a6e19678efbcfbebc3e6d3df1
      ),
    );
  }

<<<<<<< HEAD
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
=======
  // ─── Hero banner ──────────────────────────────────────────────────────────
  Widget _buildBanner() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
      height: 130,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2EAE6E), Color(0xFF4EC98A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _green.withOpacity(0.30),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20, top: -20,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 30, bottom: -30,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                // Left: heart icon
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(CupertinoIcons.heart_fill, color: Colors.white, size: 32),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Báo cáo cuối cùng: --',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Kiểm tra ngay!',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Right: CTA button
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => BloodPressure())),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Đo ngay', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _green)),
                            SizedBox(width: 4),
                            Icon(CupertinoIcons.arrow_right, size: 13, color: _green),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => HealthTrackingScreen())),
                      child: Text(
                        'Lịch sử >',
                        style: TextStyle(fontSize: 12, color: Colors.white, decoration: TextDecoration.underline, decorationColor: Colors.white54),
                      ),
                    ),
                  ],
                ),
              ],
>>>>>>> c433f0958c7b131a6e19678efbcfbebc3e6d3df1
            ),
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
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
=======
  // ─── Section label ────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary, letterSpacing: -0.2),
>>>>>>> c433f0958c7b131a6e19678efbcfbebc3e6d3df1
      ),
    );
  }

<<<<<<< HEAD
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
=======
  // ─── Health card ──────────────────────────────────────────────────────────
  Widget _buildHealthCard({
    @required String title,
    @required String value,
    @required String unit,
    @required String sub,
    @required Color accentColor,
    @required Color bgColor,
    @required String imagePath,
    @required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                  ),
                ),
              ],
            ),

            // Illustration (try image, fallback to icon)
            Align(
              alignment: Alignment.centerRight,
              child: Image.asset(
                imagePath,
                width: 54,
                height: 54,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(CupertinoIcons.heart_fill, color: accentColor, size: 24),
                ),
              ),
            ),

>>>>>>> c433f0958c7b131a6e19678efbcfbebc3e6d3df1
            // Value row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
<<<<<<< HEAD
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
=======
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    height: 1,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  SizedBox(width: 2),
                  Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Text(
                      unit,
                      style: TextStyle(fontSize: 11, color: _textSec, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ],
            ),

            // Sub text
            Text(
              sub,
              style: TextStyle(fontSize: 10.5, color: _textSec),
>>>>>>> c433f0958c7b131a6e19678efbcfbebc3e6d3df1
            ),
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD

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
=======
}
>>>>>>> c433f0958c7b131a6e19678efbcfbebc3e6d3df1
