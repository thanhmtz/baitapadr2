import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:bp_notepad/db/hr_databaseProvider.dart';
import 'package:bp_notepad/db/bs_databaseProvider.dart';
import 'package:bp_notepad/db/bp_databaseProvider.dart';
import 'package:bp_notepad/db/body_databaseProvider.dart';

enum HealthMetricType { heartRate, bloodSugar, bloodPressure, bmi }

class HealthSingleChart extends StatefulWidget {
  final HealthMetricType metricType;

  HealthSingleChart({@required this.metricType});

  @override
  State<HealthSingleChart> createState() => _HealthSingleChartState();
}

class _HealthSingleChartState extends State<HealthSingleChart> {
  List<Map<String, dynamic>> _chartData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final data = await _fetchDailyData();
    setState(() {
      _chartData = data;
      _isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchDailyData() {
    switch (widget.metricType) {
      case HealthMetricType.heartRate:
        return _fetchHeartRate();
      case HealthMetricType.bloodSugar:
        return _fetchBloodSugar();
      case HealthMetricType.bloodPressure:
        return _fetchBloodPressure();
      case HealthMetricType.bmi:
        return _fetchBMI();
      default:
        return Future.value([]);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchHeartRate() async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: 30));
    final startDateStr = startDate.toIso8601String().split('T')[0];

    final datas = await HeartRateDataBaseProvider.db.getData();

    Map<String, int> dailyData = {};
    for (var element in datas) {
      if (element.date == null) continue;
      String day = element.date.substring(0, 10);
      if (day.compareTo(startDateStr) >= 0) {
        dailyData[day] = element.hr;
      }
    }

    var result = dailyData.entries.map((e) => {'date': e.key, 'value': e.value.toDouble()}).toList();
    result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    return result;
  }

  Future<List<Map<String, dynamic>>> _fetchBloodSugar() async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: 30));
    final startDateStr = startDate.toIso8601String().split('T')[0];

    final datas = await BsDataBaseProvider.db.getData();

    Map<String, double> dailyData = {};
    for (var element in datas) {
      if (element.date == null) continue;
      String day = element.date.substring(0, 10);
      if (day.compareTo(startDateStr) >= 0) {
        dailyData[day] = element.glu;
      }
    }

    var result = dailyData.entries.map((e) => {'date': e.key, 'value': e.value}).toList();
    result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    return result;
  }

  Future<List<Map<String, dynamic>>> _fetchBloodPressure() async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: 30));
    final startDateStr = startDate.toIso8601String().split('T')[0];

    final datas = await BpDataBaseProvider.db.getData();

    Map<String, int> dailyData = {};
    for (var element in datas) {
      if (element.date == null) continue;
      String day = element.date.substring(0, 10);
      if (day.compareTo(startDateStr) >= 0) {
        dailyData[day] = element.sbp;
      }
    }

    var result = dailyData.entries.map((e) => {'date': e.key, 'value': e.value.toDouble()}).toList();
    result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    return result;
  }

  Future<List<Map<String, dynamic>>> _fetchBMI() async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: 30));
    final startDateStr = startDate.toIso8601String().split('T')[0];

    final datas = await BodyDataBaseProvider.db.getData();

    Map<String, double> dailyData = {};
    for (var element in datas) {
      if (element.date == null) continue;
      String day = element.date.substring(0, 10);
      if (day.compareTo(startDateStr) >= 0) {
        dailyData[day] = element.bmi;
      }
    }

    var result = dailyData.entries.map((e) => {'date': e.key, 'value': e.value}).toList();
    result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    return result;
  }

  Color get _chartColor {
    switch (widget.metricType) {
      case HealthMetricType.heartRate:
        return Color(0xFFFF6B6B);
      case HealthMetricType.bloodSugar:
        return Color(0xFF4ECDC4);
      case HealthMetricType.bloodPressure:
        return Color(0xFFFF8E53);
      case HealthMetricType.bmi:
        return Color(0xFF45B7D1);
      default:
        return CupertinoColors.systemGrey;
    }
  }

  String get _chartUnit {
    switch (widget.metricType) {
      case HealthMetricType.heartRate:
        return 'bpm';
      case HealthMetricType.bloodSugar:
        return 'mg/dL';
      case HealthMetricType.bloodPressure:
        return 'mmHg';
      case HealthMetricType.bmi:
        return '';
      default:
        return '';
    }
  }

  IconData get _chartIcon {
    switch (widget.metricType) {
      case HealthMetricType.heartRate:
        return CupertinoIcons.heart_fill;
      case HealthMetricType.bloodSugar:
        return CupertinoIcons.drop_fill;
      case HealthMetricType.bloodPressure:
        return CupertinoIcons.heart_circle_fill;
      case HealthMetricType.bmi:
        return CupertinoIcons.person_fill;
      default:
        return CupertinoIcons.chart_bar_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(radius: 14),
            SizedBox(height: 12),
            Text(
              'Đang tải dữ liệu...',
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (_chartData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _chartColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _chartIcon,
                size: 36,
                color: _chartColor.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Chưa có dữ liệu',
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Bắt đầu theo dõi để xem biểu đồ',
              style: TextStyle(
                color: CupertinoColors.systemGrey2,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildStatsHeader(),
        SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: 16, bottom: 8, left: 8),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: _getMaxY() * 1.3,
                minY: 0,
                groupsSpace: _getGroupsSpace(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    tooltipMargin: 8,
                    tooltipBgColor: _chartColor.withOpacity(0.95),
                    tooltipRoundedRadius: 10,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (groupIndex >= _chartData.length) return null;
                      final data = _chartData[groupIndex];
                      final date = DateTime.parse(data['date']);
                      return BarTooltipItem(
                        '${DateFormat('dd MMM').format(date)}\n',
                        TextStyle(
                          color: CupertinoColors.white.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                        children: [
                          TextSpan(
                            text: '${data['value'].toStringAsFixed(1)}',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: ' $_chartUnit',
                            style: TextStyle(
                              color: CupertinoColors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: SideTitles(
                    showTitles: true,
                    getTitles: (value) {
                      final index = value.toInt();
                      if (index >= _chartData.length) return '';
                      final date = DateTime.parse(_chartData[index]['date']);
                      return DateFormat('d/M').format(date);
                    },
                    margin: 12,
                  ),
                  leftTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitles: (value) {
                      if (value == 0) return '';
                      return value.toInt().toString();
                    },
                    margin: 12,
                  ),
                  topTitles: SideTitles(showTitles: false),
                  rightTitles: SideTitles(showTitles: false),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getHorizontalInterval(),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: CupertinoColors.systemGrey.withOpacity(0.15),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: _buildBarGroups(),
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        _buildLegend(),
      ],
    );
  }

  Widget _buildStatsHeader() {
    if (_chartData.isEmpty) return SizedBox.shrink();

    double avg = 0;
    double min = 0;
    double max = 0;
    
    if (_chartData.isNotEmpty) {
      final values = _chartData.map((e) => e['value'] as double).toList();
      avg = values.reduce((a, b) => a + b) / values.length;
      min = values.reduce((a, b) => a < b ? a : b);
      max = values.reduce((a, b) => a > b ? a : b);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatItem('TB', avg, _chartColor),
          SizedBox(width: 24),
          _buildStatItem('Cao', max, Color(0xFFFF6B6B)),
          SizedBox(width: 24),
          _buildStatItem('Thấp', min, Color(0xFF4ECDC4)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, double value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: CupertinoColors.systemGrey,
            ),
          ),
          SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(width: 2),
              Padding(
                padding: EdgeInsets.only(bottom: 1),
                child: Text(
                  _chartUnit,
                  style: TextStyle(
                    fontSize: 10,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _chartColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Giá trị theo ngày (30 ngày gần nhất)',
            style: TextStyle(
              fontSize: 11,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(_chartData.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            y: double.parse(_chartData[index]['value'].toString()),
            width: _getBarWidth(),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    });
  }

  double _getBarWidth() {
    final count = _chartData.length;
    if (count <= 5) return 24;
    if (count <= 10) return 18;
    if (count <= 15) return 14;
    if (count <= 20) return 10;
    return 8;
  }

  double _getGroupsSpace() {
    final count = _chartData.length;
    if (count <= 5) return 40;
    if (count <= 10) return 25;
    if (count <= 15) return 15;
    if (count <= 20) return 10;
    return 6;
  }

  double _getMaxY() {
    if (_chartData.isEmpty) return 100;
    double maxVal = _chartData.map((e) => e['value'] as double).reduce((a, b) => a > b ? a : b);
    return maxVal;
  }

  double _getHorizontalInterval() {
    final range = _getMaxY();
    if (range <= 20) return 5;
    if (range <= 50) return 10;
    if (range <= 100) return 20;
    if (range <= 200) return 40;
    return (range / 5).ceilToDouble();
  }
}