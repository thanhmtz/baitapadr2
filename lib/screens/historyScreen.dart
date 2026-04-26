import 'package:bp_notepad/db/bp_databaseProvider.dart';
import 'package:bp_notepad/db/bs_databaseProvider.dart';
import 'package:bp_notepad/db/body_databaseProvider.dart';
import 'package:bp_notepad/db/hr_databaseProvider.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedIndex = 0;
  
  final List<Map<String, dynamic>> _metrics = [
    {'key': 'hr', 'title': 'Nhịp tim', 'unit': 'BPM', 'color': CupertinoColors.systemRed},
    {'key': 'bs', 'title': 'Đường huyết', 'unit': 'mmol/L', 'color': CupertinoColors.systemGreen},
    {'key': 'bp', 'title': 'Huyết áp', 'unit': 'mmHg', 'color': CupertinoColors.systemBlue},
    {'key': 'bmi', 'title': 'BMI', 'unit': '', 'color': CupertinoColors.systemOrange},
  ];
  
  List<BarChartGroupData> _barGroups = [];
  List<FlSpot> _spots = [];
  List<FlSpot> _spots2 = [];
  List<String> _dates = [];
  bool _isLoading = true;
  double _avgValue = 0;
  double _minValue = 0;
  double _maxValue = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final key = _metrics[_selectedIndex]['key'];
    List<dynamic> data = [];
    List<String> dateList = [];
    
    switch (key) {
      case 'hr':
        data = await HeartRateDataBaseProvider.db.getData();
        dateList = data.map((e) => e.date ?? '').toList();
        _spots = data.asMap().entries.map((e) => 
          FlSpot(e.key.toDouble(), e.value.hr.toDouble())).toList();
        break;
      case 'bs':
        data = await BsDataBaseProvider.db.getData();
        dateList = data.map((e) => e.date ?? '').toList();
        _spots = data.asMap().entries.map((e) => 
          FlSpot(e.key.toDouble(), e.value.bs.toDouble())).toList();
        break;
      case 'bp':
        final bpData = await BpDataBaseProvider.db.getData();
        dateList = bpData.map((e) => e.date ?? '').toList();
        _spots = bpData.asMap().entries.map((e) => 
          FlSpot(e.key.toDouble(), e.value.sbp.toDouble())).toList();
        _spots2 = bpData.asMap().entries.map((e) => 
          FlSpot(e.key.toDouble(), e.value.dbp.toDouble())).toList();
        break;
      case 'bmi':
        data = await BodyDataBaseProvider.db.getData();
        dateList = data.map((e) => e.date ?? '').toList();
        _spots = data.asMap().entries.map((e) => 
          FlSpot(e.key.toDouble(), e.value.bmi.toDouble())).toList();
        break;
    }
    
    // Format dates
    _dates = dateList.map((d) {
      try {
        final dt = DateTime.parse(d);
        return DateFormat('dd/MM').format(dt);
      } catch (_) {
        return '';
      }
    }).toList();
    
    // Create bar groups (last 7 days)
    final limit = _spots.length > 7 ? 7 : _spots.length;
    _barGroups = [];
    for (int i = 0; i < limit; i++) {
      final showSecondLine = _selectedIndex == 2 && _spots2.isNotEmpty;
      _barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              y: _spots[i].y,
              width: showSecondLine ? 12 : 20,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            if (showSecondLine)
              BarChartRodData(
                y: _spots2[i].y,
                width: 12,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
          ],
        ),
      );
    }
    
    if (_spots.isNotEmpty) {
      final values = _spots.map((s) => s.y).toList();
      _avgValue = values.reduce((a, b) => a + b) / values.length;
      _minValue = values.reduce((a, b) => a < b ? a : b);
      _maxValue = values.reduce((a, b) => a > b ? a : b);
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final metric = _metrics[_selectedIndex];
    
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text('Lịch sử'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header card
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    metric['color'],
                    (metric['color'] as Color).withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: metric['color'].withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getIcon(_selectedIndex),
                        color: CupertinoColors.white,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        metric['title'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderStat('TB', _avgValue, metric['unit']),
                      _buildHeaderStat('Min', _minValue, metric['unit']),
                      _buildHeaderStat('Max', _maxValue, metric['unit']),
                    ],
                  ),
                ],
              ),
            ),
            
            // Tab chọn
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoSlidingSegmentedControl(
                groupValue: _selectedIndex,
                children: {
                  0: _buildTab('❤️', 'HR'),
                  1: _buildTab('🩸', 'BS'),
                  2: _buildTab('💊', 'BP'),
                  3: _buildTab('⚖️', 'BMI'),
                },
                onValueChanged: (value) {
                  setState(() => _selectedIndex = value);
                  _loadData();
                },
              ),
            ),
            
            SizedBox(height: 16),
            
            // Biểu đồ cột
            Expanded(
              child: _isLoading 
                  ? Center(child: CupertinoActivityIndicator())
                  : _barGroups.isEmpty 
                      ? Center(child: Text('Chưa có dữ liệu', style: TextStyle(color: CupertinoColors.systemGrey)))
                      : Padding(
                          padding: EdgeInsets.all(16),
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: _maxValue * 1.2,
                              barGroups: _barGroups,
                              titlesData: FlTitlesData(
                                show: true,
                                leftTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 35,
                                  getTitles: (value) => 
                                    value.toInt().toString(),
                                ),
                                bottomTitles: SideTitles(
                                  showTitles: true,
                                  getTitles: (value) {
                                    final idx = value.toInt();
                                    if (idx >= 0 && idx < _dates.length) {
                                      return _dates[idx];
                                    }
                                    return '';
                                  },
                                ),
                                topTitles: SideTitles(showTitles: false),
                                rightTitles: SideTitles(showTitles: false),
                              ),
                              gridData: FlGridData(
                                show: true,
                                horizontalInterval: (_maxValue * 1.2) / 5,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: CupertinoColors.systemGrey.withOpacity(0.2),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTab(String emoji, String label) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(label, style: TextStyle(fontSize: 12)),
    );
  }
  
  Widget _buildHeaderStat(String label, double value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: CupertinoColors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)} $unit',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  IconData _getIcon(int index) {
    switch (index) {
      case 0: return CupertinoIcons.heart_fill;
      case 1: return CupertinoIcons.drop_fill;
      case 2: return CupertinoIcons.bandage_fill;
      case 3: return CupertinoIcons.person_fill;
      default: return CupertinoIcons.chart_bar_fill;
    }
  }
}