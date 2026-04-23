import 'package:bp_notepad/components/constants.dart';
import 'package:bp_notepad/db/alarm_databaseProvider.dart';
import 'package:bp_notepad/db/body_databaseProvider.dart';
import 'package:bp_notepad/db/bp_databaseProvider.dart';
import 'package:bp_notepad/db/bs_databaseProvider.dart';
import 'package:bp_notepad/db/sleep_databaseProvider.dart';
import 'package:bp_notepad/localization/appLocalization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:async/async.dart';
import 'dart:math';

class HistoryScreen extends StatefulWidget {
  HistoryScreen({Key key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Metrics: 0: Heart Rate, 1: Blood Sugar, 2: Blood Pressure, 3: BMI
  int _currentMetricIndex = 0;
  List<String> _metricNames = [
    'Heart Rate (BPM)',
    'Blood Sugar (mg/dL)',
    'Blood Pressure (mmHg)',
    'BMI'
  ];

  // Time range: 0: Today, 1: Week, 2: Month
  int _timeRangeIndex = 0;
  List<String> _timeRangeNames = ['Today', 'Week', 'Month'];

  AsyncMemoizer _memoizer;
  List<FlSpot> _heartRateSpots = [];
  List<FlSpot> _bloodSugarSpots = [];
  List<FlSpot> _bloodPressureSysSpots = [];
  List<FlSpot> _bloodPressureDiaSpots = [];
  List<FlSpot> _bmiSpots = [];

  double _latestValue = 0;
  double _averageValue = 0;

  @override
  void initState() {
    super.initState();
    _memoizer = AsyncMemoizer();
    _loadData();
  }

  Future<void> _loadData() async {
    return _memoizer.runOnce(() async {
      // Fetch all data from databases
      final bpList = await BpDataBaseProvider.db.getData();
      final bsList = await BsDataBaseProvider.db.getData();
      final bmiList = await BodyDataBaseProvider.db.getData();

      // Clear existing spots
      _heartRateSpots = [];
      _bloodSugarSpots = [];
      _bloodPressureSysSpots = [];
      _bloodPressureDiaSpots = [];
      _bmiSpots = [];

      // Get current date for filtering
      final now = DateTime.now();
      DateTime startDate;
      switch (_timeRangeIndex) {
        case 0: // Today
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 1: // Week
          startDate = now.subtract(Duration(days: 7));
          break;
        case 2: // Month
          startDate = DateTime(now.year, now.month - 1 >= 0 ? now.month - 1 : 12,
              now.year > 0 ? now.day : now.day,
              now.year > 0 && now.month - 1 < 0 ? now.year - 1 : now.year);
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day);
      }

      // Process blood pressure data (contains heart rate too)
      for (final item in bpList) {
        final date = DateTime.parse(item.date);
        if (date.isBefore(startDate)) continue;
        final x = date.millisecondsSinceEpoch.toDouble();
        // Heart rate
        _heartRateSpots.add(FlSpot(x, item.hr.toDouble()));
        // Blood pressure
        _bloodPressureSysSpots.add(FlSpot(x, item.sbp.toDouble()));
        _bloodPressureDiaSpots.add(FlSpot(x, item.dbp.toDouble()));
      }

      // Process blood sugar data (convert mmol/L to mg/dL: 1 mmol/L = 18 mg/dL)
      for (final item in bsList) {
        final date = DateTime.parse(item.date);
        if (date.isBefore(startDate)) continue;
        final x = date.millisecondsSinceEpoch.toDouble();
        final mgDL = item.glu * 18;
        _bloodSugarSpots.add(FlSpot(x, mgDL));
      }

      // Process BMI data
      for (final item in bmiList) {
        final date = DateTime.parse(item.date);
        if (date.isBefore(startDate)) continue;
        final x = date.millisecondsSinceEpoch.toDouble();
        _bmiSpots.add(FlSpot(x, item.bmi.toDouble()));
      }

      // Sort spots by x (time)
      _heartRateSpots.sort((a, b) => a.x.compareTo(b.x));
      _bloodSugarSpots.sort((a, b) => a.x.compareTo(b.x));
      _bloodPressureSysSpots.sort((a, b) => a.x.compareTo(b.x));
      _bloodPressureDiaSpots.sort((a, b) => a.x.compareTo(b.x));
      _bmiSpots.sort((a, b) => a.x.compareTo(b.x));

      // Calculate latest and average values for current metric
      _calculateStats();
    });
  }

  void _calculateStats() {
    List<FlSpot> spots;
    switch (_currentMetricIndex) {
      case 0:
        spots = _heartRateSpots;
        break;
      case 1:
        spots = _bloodSugarSpots;
        break;
      case 2:
        // For blood pressure, we'll show average of systolic? Or we can show both?
        // For simplicity, we'll use systolic for stats
        spots = _bloodPressureSysSpots;
        break;
      case 3:
        spots = _bmiSpots;
        break;
      default:
        spots = [];
    }

    if (spots.isNotEmpty) {
      _latestValue = spots.last.y;
      final sum = spots.fold(0.0, (sum, spot) => sum + spot.y);
      _averageValue = sum / spots.length;
    } else {
      _latestValue = 0;
      _averageValue = 0;
    }
  }

  void _changeMetric(int delta) {
    setState(() {
      _currentMetricIndex = (_currentMetricIndex + delta) % 4;
      if (_currentMetricIndex < 0) _currentMetricIndex += 4;
      _loadData(); // Reload data for new metric
    });
  }

  void _changeTimeRange(int delta) {
    setState(() {
      _timeRangeIndex = (_timeRangeIndex + delta) % 3;
      if (_timeRangeIndex < 0) _timeRangeIndex += 3;
      _loadData(); // Reload data for new time range
    });
  }

  Widget _buildMetricSwitchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: () => _changeMetric(-1),
            child: Icon(
              CupertinoIcons.chevron_left,
              color: CupertinoColors.activeBlue,
              size: 28,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _metricNames[_currentMetricIndex],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label,
              ),
            ),
          ),
          SizedBox(width: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: () => _changeMetric(1),
            child: Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.activeBlue,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Health History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label,
            ),
          ),
          Row(
            children: List.generate(_timeRangeNames.length, (index) {
              final isSelected = index == _timeRangeIndex;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(
                    _timeRangeNames[index],
                    style: TextStyle(
                      color: isSelected ? CupertinoColors.white : CupertinoColors.label,
                      fontSize: 14,
                    ),
                  ),
                  selected: isSelected,
                  backgroundColor: CupertinoColors.systemGroupedBackground,
                  selectedColor: CupertinoColors.activeBlue,
                  onSelected: (_) => _changeTimeRange(index - _timeRangeIndex),
                  labelPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    // Determine which spots to show based on current metric
    List<FlSpot> spots;
    List<FlSpot> spots2; // For second line in BP
    bool showSecondLine = false;
    Gradient gradient;

    switch (_currentMetricIndex) {
      case 0: // Heart Rate
        spots = _heartRateSpots;
        gradient = LinearGradient(
          colors: [
            CupertinoColors.systemRed.withOpacity(0.8),
            CupertinoColors.systemRed.withOpacity(0.3),
          ],
        );
        break;
      case 1: // Blood Sugar
        spots = _bloodSugarSpots;
        gradient = LinearGradient(
          colors: [
            CupertinoColors.systemGreen.withOpacity(0.8),
            CupertinoColors.systemGreen.withOpacity(0.3),
          ],
        );
        break;
      case 2: // Blood Pressure
        spots = _bloodPressureSysSpots;
        spots2 = _bloodPressureDiaSpots;
        showSecondLine = true;
        gradient = LinearGradient(
          colors: [
            CupertinoColors.systemBlue.withOpacity(0.8),
            CupertinoColors.systemBlue.withOpacity(0.3),
          ],
        );
        break;
      case 3: // BMI
        spots = _bmiSpots;
        gradient = LinearGradient(
          colors: [
            CupertinoColors.systemPurple.withOpacity(0.8),
            CupertinoColors.systemPurple.withOpacity(0.3),
          ],
        );
        break;
      default:
        spots = [];
        gradient = LinearGradient(
          colors: [CupertinoColors.label, CupertinoColors.label],
        );
    }

    // If no data, show empty state
    if (spots.isEmpty) {
      return Center(
        child: Text(
          'No data available for selected time range',
          style: TextStyle(
            color: CupertinoColors.label,
            fontSize: 16,
          ),
        ),
      );
    }

    // Calculate min and max for y-axis with some padding
    double minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    if (showSecondLine) {
      final minY2 = spots2.map((e) => e.y).reduce((a, b) => a < b ? a : b);
      final maxY2 = spots2.map((e) => e.y).reduce((a, b) => a > b ? a : b);
      minY = minY < minY2 ? minY : minY2;
      maxY = maxY > maxY2 ? maxY : maxY2;
    }
    if (maxY <= minY) {
      minY = minY - 10;
      maxY = maxY + 10;
    }
    final padding = (maxY - minY) * 0.15;
    final bottomY = (maxY - padding < 0) ? 0 : maxY - padding;
    final topY = maxY + padding;

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: EdgeInsets.only(right: 18, left: 12, top: 24, bottom: 12),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: (topY - bottomY) / 5,
              verticalInterval: (_getTimeIntervalSpots(spots) / 5),
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: CupertinoColors.systemGrey.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: CupertinoColors.systemGrey.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: SideTitles(showTitles: false),
              topTitles: SideTitles(showTitles: false),
              bottomTitles: SideTitles(
                showTitles: true,
                getTextStyles: (value) => TextStyle(
                  color: CupertinoColors.label,
                  fontSize: 10,
                ),
                margin: 8,
                getTitles: (value) {
                  // Convert milliseconds to date string
                  final date = DateTime.fromMillisecondsSinceEpoch(value.round());
                  switch (_timeRangeIndex) {
                    case 0: // Today
                      return DateFormat.Hm().format(date);
                    case 1: // Week
                      return DateFormat.Md().format(date);
                    case 2: // Month
                      return DateFormat.Md().format(date);
                    default:
                      return '';
                  }
                },
              ),
              leftTitles: SideTitles(
                showTitles: true,
                getTextStyles: (value) => TextStyle(
                  color: CupertinoColors.label,
                  fontSize: 10,
                ),
                margin: 12,
                interval: (topY - bottomY) / 5,
                getTitles: (value) {
                  return value.toStringAsFixed(0);
                },
                reservedSize: 30,
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: CupertinoColors.systemGrey.withOpacity(0.2)),
            ),
            minX: spots.first.x,
            maxX: spots.last.x,
            minY: bottomY,
            maxY: topY,
lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  colors: [gradient.colors.first],
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 4,
                      color: gradient.colors.first,
                      strokeWidth: 2,
                      strokeColor: CupertinoColors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    colors: [
                      gradient.colors.first.withOpacity(0.3),
                      gradient.colors.first.withOpacity(0.1),
                    ],
                  ),
                ),
                if (showSecondLine)
                  LineChartBarData(
                    spots: spots2,
                    isCurved: true,
                    colors: [CupertinoColors.systemRed.withOpacity(0.8)],
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: CupertinoColors.systemRed.withOpacity(0.8),
                        strokeWidth: 2,
                        strokeColor: CupertinoColors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      colors: [
                        CupertinoColors.systemRed.withOpacity(0.3),
                        CupertinoColors.systemRed.withOpacity(0.1),
                      ],
                    ),
                  ),
              ],
          ),
        ),
      ),
    );
  }

  double _getTimeIntervalSpots(List<FlSpot> spots) {
    if (spots.length < 2) return 1;
    final first = spots.first.x;
    final last = spots.last.x;
    return (last - first) / (spots.length - 1);
  }

  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                'Latest',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${_latestValue.toStringAsFixed(1)}',
                style: TextStyle(
                  color: CupertinoColors.label,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 30,
            color: CupertinoColors.systemGrey.withOpacity(0.2),
          ),
          Column(
            children: [
              Text(
                'Average',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${_averageValue.toStringAsFixed(1)}',
                style: TextStyle(
                  color: CupertinoColors.label,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          AppLocalization.of(context).translate('history_page'),
        ),
        backgroundColor: CupertinoColors.systemGroupedBackground,
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildTimeFilter(),
            SizedBox(height: 8),
            _buildMetricSwitchBar(),
            SizedBox(height: 12),
            Expanded(
              child: FutureBuilder(
                future: _memoizer.runOnce(() async {}),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CupertinoActivityIndicator());
                  }
                  return _buildChart();
                },
              ),
            ),
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }
}