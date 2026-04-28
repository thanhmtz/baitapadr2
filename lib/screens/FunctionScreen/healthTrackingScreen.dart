import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bp_notepad/db/bp_databaseProvider.dart';
import 'package:bp_notepad/db/hr_databaseProvider.dart';
import 'package:bp_notepad/db/bs_databaseProvider.dart';
import 'package:bp_notepad/db/body_databaseProvider.dart';
import 'package:bp_notepad/models/bpDBModel.dart';
import 'package:bp_notepad/models/hrDBModel.dart';
import 'package:bp_notepad/models/bsDBModel.dart';
import 'package:bp_notepad/models/bodyModel.dart';

class HealthTrackingScreen extends StatefulWidget {
  @override
  _HealthTrackingScreenState createState() => _HealthTrackingScreenState();
}

class _HealthTrackingScreenState extends State<HealthTrackingScreen> {
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _metrics = [
    {'name': 'Huyết áp', 'icon': CupertinoIcons.heart_fill, 'color': Color(0xFFFF5252), 'type': 'bp'},
    {'name': 'Nhịp tim', 'icon': CupertinoIcons.waveform_path_ecg, 'color': Color(0xFFFF6B6B), 'type': 'hr'},
    {'name': 'Đường huyết', 'icon': CupertinoIcons.drop_fill, 'color': Color(0xFF4CAF50), 'type': 'bs'},
    {'name': 'BMI', 'icon': CupertinoIcons.person_fill, 'color': Color(0xFF2196F3), 'type': 'bmi'},
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Color(0xFFF5F7FA),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        border: null,
        middle: Text(
          'Health Tracking',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.back, color: Color(0xFF4CAF50)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildTabBar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_metrics.length, (index) {
            final metric = _metrics[index];
            final isSelected = _selectedTab == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: 12),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [metric['color'], metric['color'].withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : CupertinoColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [BoxShadow(color: metric['color'].withOpacity(0.4), blurRadius: 12, offset: Offset(0, 4))]
                      : [BoxShadow(color: CupertinoColors.systemGrey.withOpacity(0.1), blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    Icon(metric['icon'], size: 20, color: isSelected ? CupertinoColors.white : metric['color']),
                    SizedBox(width: 8),
                    Text(
                      metric['name'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? CupertinoColors.white : CupertinoColors.label,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildBpContent();
      case 1:
        return _buildHrContent();
      case 2:
        return _buildBsContent();
      case 3:
        return _buildBmiContent();
      default:
        return _buildBpContent();
    }
  }

  Widget _buildBpContent() {
    return FutureBuilder(
      future: BpDataBaseProvider.db.getData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data.isEmpty) {
          return _buildEmptyState('No blood pressure data', 'Add your first reading');
        }
        final data = snapshot.data;
        final latest = data.first;
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildMainCard(
                '${latest.sbp}/${latest.dbp}',
                'mmHg',
                _getBpCategory(latest.sbp, latest.dbp),
                _getBpColor(latest.sbp, latest.dbp),
                'Pulse: ${latest.hr} bpm',
              ),
              SizedBox(height: 20),
              _buildChartPlaceholder(),
              SizedBox(height: 20),
              _buildRecentList(data.take(10).toList()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHrContent() {
    return FutureBuilder(
      future: HeartRateDataBaseProvider.db.getData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data.isEmpty) {
          return _buildEmptyState('No heart rate data', 'Add your first reading');
        }
        final data = snapshot.data;
        final latest = data.first;
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildMainCard('${latest.hr}', 'bpm', _getHrCategory(latest.hr), Color(0xFFFF6B6B), latest.date.toString().substring(0, 16)),
              SizedBox(height: 20),
              _buildRecentList(data.take(10).toList()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBsContent() {
    return FutureBuilder(
      future: BsDataBaseProvider.db.getData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data.isEmpty) {
          return _buildEmptyState('No blood sugar data', 'Add your first reading');
        }
        final data = snapshot.data;
        final latest = data.first;
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildMainCard('${latest.glu}', 'mmol/L', _getBsCategory(latest.glu), Color(0xFF4CAF50), latest.date.toString().substring(0, 16)),
              SizedBox(height: 20),
              _buildRecentList(data.take(10).toList()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBmiContent() {
    return FutureBuilder(
      future: BodyDataBaseProvider.db.getData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data.isEmpty) {
          return _buildEmptyState('No BMI data', 'Add your first reading');
        }
        final data = snapshot.data;
        final latest = data.first;
        final bmi = latest.bmi;
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildMainCard(bmi.toStringAsFixed(1), '', _getBmiCategory(bmi), Color(0xFF2196F3), latest.date.toString().substring(0, 16)),
              SizedBox(height: 20),
              _buildRecentList(data.take(10).toList()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainCard(String value, String unit, String status, Color color, String subtitle) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: CupertinoColors.white)),
              if (unit.isNotEmpty) ...[
                SizedBox(width: 4),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(unit, style: TextStyle(fontSize: 16, color: CupertinoColors.white.withOpacity(0.8))),
                ),
              ],
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: CupertinoColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(status, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.white)),
          ),
          SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 12, color: CupertinoColors.white.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder() {
    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(20), boxShadow: [
        BoxShadow(color: CupertinoColors.systemGrey.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4)),
      ]),
      child: Center(child: Text('Chart Coming Soon', style: TextStyle(color: CupertinoColors.systemGrey))),
    );
  }

  Widget _buildRecentList(List data) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(20), boxShadow: [
        BoxShadow(color: CupertinoColors.systemGrey.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4)),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          ...data.map((item) => _buildRecentItem(item)),
        ],
      ),
    );
  }

  Widget _buildRecentItem(dynamic item) {
    String value;
    if (item is BloodPressureDB) value = '${item.sbp}/${item.dbp} mmHg';
    if (item is HeartRateDB) value = '${item.hr} bpm';
    if (item is BloodSugarDB) value = '${item.glu} mmol/L';
    if (item is BodyDB) value = item.bmi.toStringAsFixed(1);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(item.date.toString().substring(0, 16), style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
          Text(value ?? '-', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.chart_bar_alt_fill, size: 60, color: CupertinoColors.systemGrey4),
          SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: CupertinoColors.systemGrey)),
        ],
      ),
    );
  }

  String _getBpCategory(int sbp, int dbp) {
    if (sbp >= 180 || dbp >= 120) return 'Hypertensive Crisis';
    if (sbp >= 140 || dbp >= 90) return 'High BP Stage 2';
    if (sbp >= 130 || dbp >= 80) return 'High BP Stage 1';
    if (sbp >= 120) return 'Elevated';
    if (sbp < 90) return 'Low';
    return 'Normal';
  }

  Color _getBpColor(int sbp, int dbp) {
    if (sbp >= 180 || dbp >= 120) return Color(0xFFB71C1C);
    if (sbp >= 140 || dbp >= 90) return Color(0xFFEF5350);
    if (sbp >= 130 || dbp >= 80) return Color(0xFFFF9800);
    if (sbp >= 120) return Color(0xFFFFEB3B);
    if (sbp < 90) return Color(0xFF2196F3);
    return Color(0xFF4CAF50);
  }

  String _getHrCategory(int hr) {
    if (hr > 100) return 'Tachycardia';
    if (hr < 60) return 'Bradycardia';
    return 'Normal';
  }

  String _getBsCategory(double glu) {
    if (glu >= 7.0) return 'High';
    if (glu < 4.0) return 'Low';
    return 'Normal';
  }

  String _getBmiCategory(double bmi) {
    if (bmi >= 30) return 'Obese';
    if (bmi >= 25) return 'Overweight';
    if (bmi >= 18.5) return 'Normal';
    return 'Underweight';
  }
}