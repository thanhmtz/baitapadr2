import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator, RefreshIndicator, Scaffold, CircularProgressIndicator;
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
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
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

    int activeReminders = alarmList.where((alarm) => alarm.state == '1').length;

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
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      body: _isLoading
          ? Center(child: CupertinoActivityIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: CupertinoColors.activeGreen,
              child: CustomScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildHeader(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNutritionCard(),
                          SizedBox(height: 24),
                          _buildQuickAddSection(),
                          SizedBox(height: 24),
                          _buildHealthMetricsSection(),
                          SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return CupertinoSliverNavigationBar(
      largeTitle: Text('Health'),
      backgroundColor: CupertinoColors.systemGroupedBackground.withOpacity(0.9),
      border: null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CupertinoColors.activeGreen.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(CupertinoIcons.person_fill, color: CupertinoColors.activeGreen, size: 22),
            ),
            onPressed: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => UserScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard() {
    double progress = (_totalCalories / 2000).clamp(0.0, 1.0);
    double remaining = 2000 - _totalCalories;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF34C759),
            Color(0xFF30D158),
            Color(0xFF28CD41),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF34C759).withOpacity(0.4),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(CupertinoIcons.flame_fill, color: CupertinoColors.white, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Calories',
                        style: TextStyle(
                          color: CupertinoColors.white.withOpacity(0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _totalCalories.toStringAsFixed(0),
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      SizedBox(width: 4),
                      Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text(
                          '/ 2000',
                          style: TextStyle(
                            color: CupertinoColors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      remaining > 0 ? '${remaining.toStringAsFixed(0)} kcal còn lại' : 'Đã đạt mục tiêu!',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: CupertinoColors.white.withOpacity(0.25),
                      valueColor: AlwaysStoppedAnimation(CupertinoColors.white),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Hoàn thành',
                        style: TextStyle(
                          color: CupertinoColors.white.withOpacity(0.8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroItem('Protein', _totalProtein, 50, CupertinoIcons.bolt_fill),
                _buildDivider(),
                _buildMacroItem('Carbs', _totalCarbs, 250, CupertinoIcons.circle_fill),
                _buildDivider(),
                _buildMacroItem('Fat', _totalFat, 65, CupertinoIcons.drop_fill),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, double value, double target, IconData icon) {
    double progress = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: CupertinoColors.white, size: 18),
          SizedBox(height: 6),
          Text(
            '${value.toStringAsFixed(0)}g',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '/ ${target.toStringAsFixed(0)}g',
            style: TextStyle(
              color: CupertinoColors.white.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
          SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: CupertinoColors.white.withOpacity(0.25),
              valueColor: AlwaysStoppedAnimation(CupertinoColors.white),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 50,
      width: 1,
      color: CupertinoColors.white.withOpacity(0.3),
    );
  }

  Widget _buildQuickAddSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thêm nhanh',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
        ),
        SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickAddButton(
                icon: CupertinoIcons.chart_bar_fill,
                label: 'Dinh dưỡng',
                color: CupertinoColors.activeGreen,
                onTap: () => _navigateToAdd(6),
              ),
              _buildQuickAddButton(
                icon: CupertinoIcons.heart_fill,
                label: 'Huyết áp',
                color: CupertinoColors.systemRed,
                onTap: () => _navigateToAdd(0),
              ),
              _buildQuickAddButton(
                icon: CupertinoIcons.drop_fill,
                label: 'Đường huyết',
                color: CupertinoColors.systemGreen,
                onTap: () => _navigateToAdd(1),
              ),
              _buildQuickAddButton(
                icon: CupertinoIcons.person_fill,
                label: 'BMI',
                color: CupertinoColors.systemBlue,
                onTap: () => _navigateToAdd(2),
              ),
              _buildQuickAddButton(
                icon: CupertinoIcons.waveform_path_ecg,
                label: 'Nhịp tim',
                color: CupertinoColors.systemPink,
                onTap: () => _navigateToAdd(3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToAdd(int index) {
    Navigator.push(context, CupertinoPageRoute(builder: (_) => AddScreen()));
  }

  Widget _buildQuickAddButton({
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: EdgeInsets.only(right: 12),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.label,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chỉ số sức khỏe',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
        ),
        SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _buildMetricCard(
              icon: CupertinoIcons.heart_fill,
              color: CupertinoColors.systemRed,
              title: 'Huyết áp',
              value: _latestBP != null ? '${_latestBP.sbp}/${_latestBP.dbp}' : '--/--',
              unit: 'mmHg',
              subtitle: _latestBP != null ? _formatDate(_latestBP.date) : 'Chưa có',
            ),
            _buildMetricCard(
              icon: CupertinoIcons.drop_fill,
              color: CupertinoColors.systemGreen,
              title: 'Đường huyết',
              value: _latestBS != null ? _latestBS.glu.toStringAsFixed(1) : '--',
              unit: 'mmol/L',
              subtitle: _latestBS != null ? _formatDate(_latestBS.date) : 'Chưa có',
            ),
            _buildMetricCard(
              icon: CupertinoIcons.person_fill,
              color: CupertinoColors.systemBlue,
              title: 'BMI',
              value: _latestBMI != null ? _latestBMI.bmi.toStringAsFixed(1) : '--',
              unit: '',
              subtitle: _latestBMI != null ? _formatDate(_latestBMI.date) : 'Chưa có',
            ),
            _buildMetricCard(
              icon: CupertinoIcons.waveform_path_ecg,
              color: CupertinoColors.systemPink,
              title: 'Nhịp tim',
              value: _latestHR != null ? '$_latestHR' : '--',
              unit: 'bpm',
              subtitle: _latestHR != null ? 'Đo gần nhất' : 'Chưa có',
            ),
            _buildMetricCard(
              icon: CupertinoIcons.moon_fill,
              color: CupertinoColors.systemIndigo,
              title: 'Giấc ngủ',
              value: _latestSleep != null && _latestSleep > 0 ? _latestSleep.toStringAsFixed(1) : '--',
              unit: 'giờ',
              subtitle: _latestSleep != null && _latestSleep > 0 ? 'Ngủ hôm qua' : 'Chưa có',
            ),
            _buildMetricCard(
              icon: CupertinoIcons.flame_fill,
              color: CupertinoColors.systemOrange,
              title: 'Bước chân',
              value: _steps > 0 ? '$_steps' : '--',
              unit: 'bước',
              subtitle: _steps > 0 ? 'Hôm nay' : 'Chưa có',
            ),
            _buildMetricCard(
              icon: CupertinoIcons.bell_fill,
              color: CupertinoColors.systemYellow,
              title: 'Nhắc thuốc',
              value: '$_reminderCount',
              unit: 'lịch',
              subtitle: 'Đang hoạt động',
            ),
            _buildMetricCard(
              icon: CupertinoIcons.leaf_arrow_circlepath,
              color: CupertinoColors.systemTeal,
              title: 'Calories',
              value: _totalCalories.toInt().toString(),
              unit: 'kcal',
              subtitle: 'Hôm nay',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    IconData icon,
    Color color,
    String title,
    String value,
    String unit,
    String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label,
                ),
              ),
              if (unit.isNotEmpty) ...[
                SizedBox(width: 2),
                Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 10,
                      color: CupertinoColors.tertiaryLabel,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: CupertinoColors.tertiaryLabel,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}