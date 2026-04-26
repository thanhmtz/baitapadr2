import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bp_notepad/db/bp_databaseProvider.dart';
import 'package:bp_notepad/db/bs_databaseProvider.dart';
import 'package:bp_notepad/db/body_databaseProvider.dart';
import 'package:bp_notepad/db/hr_databaseProvider.dart';
import 'package:bp_notepad/db/sleep_databaseProvider.dart';
import 'package:bp_notepad/models/bpDBModel.dart';
import 'package:bp_notepad/models/bsDBModel.dart';
import 'package:bp_notepad/models/bodyModel.dart';
import 'package:bp_notepad/models/hrDBModel.dart';
import 'package:bp_notepad/models/sleepDBModel.dart';
import 'package:bp_notepad/screens/FunctionScreen/bpScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/bsScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/bmiScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/heartRateScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/nutritionScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/waterReminderScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/healthTrackingScreen.dart';

// ─── Color tokens ─────────────────────────────────────────────────────────────
final Color _green         = const Color(0xFF3DAA72);
final Color _greenBg       = const Color(0xFFEAF7F0);
final Color _redAccent     = const Color(0xFFFF6B6B);
final Color _blueAccent    = const Color(0xFF4A9EFF);
final Color _orangeAccent  = const Color(0xFFFF9F43);
final Color _purpleAccent  = const Color(0xFF9B59B6);
final Color _pageBg        = const Color(0xFFF4F6F9);
final Color _cardBg        = const Color(0xFFFFFFFF);
final Color _textPrimary   = const Color(0xFF1A2332);
final Color _textSec       = const Color(0xFF7A8699);

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isLoading = true;

  // Dùng kiểu nullable kiểu cũ (không có ?)
  BloodPressureDB _latestBP;
  BloodSugarDB    _latestBS;
  BodyDB          _latestBMI;
  int             _latestHR;
  double          _latestSleep;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final bpList    = await BpDataBaseProvider.db.getData();
    final bsList    = await BsDataBaseProvider.db.getData();
    final bodyList  = await BodyDataBaseProvider.db.getData();
    final hrList    = await HeartRateDataBaseProvider.db.getData();
    final sleepList = await SleepDataBaseProvider.db.getData();

    if (bpList != null && bpList.isNotEmpty) {
      bpList.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
      _latestBP = bpList.first;
    }
    if (bsList != null && bsList.isNotEmpty) {
      bsList.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
      _latestBS = bsList.first;
    }
    if (bodyList != null && bodyList.isNotEmpty) {
      bodyList.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
      _latestBMI = bodyList.first;
    }
    if (hrList != null && hrList.isNotEmpty) {
      hrList.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
      _latestHR = hrList.first.hr;
    }
    if (sleepList != null && sleepList.isNotEmpty) {
      sleepList.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
      _latestSleep = sleepList.first.sleep;
    }

    setState(() => _isLoading = false);
  }

  String _fmt(String date) {
    try {
      final d = DateTime.parse(date);
      return '${d.day}/${d.month}';
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    value: _latestBP != null ? '${_latestBP.sbp}/${_latestBP.dbp}' : '--/--',
                    unit: 'mmHg',
                    sub: _latestBP != null ? _fmt(_latestBP.date) : 'Chưa có dữ liệu',
                    accentColor: _redAccent,
                    bgColor: Color(0xFFFFF0F0),
                    imagePath: 'assets/images/bp_device.png',
                    onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => BloodPressure())),
                  ),
                  _buildHealthCard(
                    title: 'Đường huyết',
                    value: _latestBS != null ? _latestBS.glu.toStringAsFixed(1) : '--',
                    unit: 'mmol/L',
                    sub: _latestBS != null ? _fmt(_latestBS.date) : 'Chưa có dữ liệu',
                    accentColor: _redAccent,
                    bgColor: Color(0xFFFFF5F5),
                    imagePath: 'assets/images/bs_device.png',
                    onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => BloodSugar())),
                  ),
                  _buildHealthCard(
                    title: 'Cân nặng & chỉ số BMI',
                    value: _latestBMI != null ? _latestBMI.weight.toStringAsFixed(1) : '--',
                    unit: 'KG',
                    sub: _latestBMI != null ? 'BMI: ${_latestBMI.bmi.toStringAsFixed(1)}' : 'Chưa có dữ liệu',
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
                Text(
                  '26°C',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
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
                Container(
                  width: 60,
                  height: 60,
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
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context, CupertinoPageRoute(builder: (_) => BloodPressure())),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Đo ngay',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _green,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(CupertinoIcons.arrow_right, size: 13, color: _green),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context, CupertinoPageRoute(builder: (_) => HealthTrackingScreen())),
                      child: Text(
                        'Lịch sử >',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section label ────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  // ─── Health card ──────────────────────────────────────────────────────────
  // Dùng @required thay vì required (Dart cũ)
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
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
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSec,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              sub,
              style: TextStyle(fontSize: 10.5, color: _textSec),
            ),
          ],
        ),
      ),
    );
  }
}