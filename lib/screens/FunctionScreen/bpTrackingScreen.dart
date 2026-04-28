import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bp_notepad/db/bp_databaseProvider.dart';
import 'package:bp_notepad/models/bpDBModel.dart';
import 'package:bp_notepad/screens/FunctionScreen/bpScreen.dart';

class BpTrackingScreen extends StatefulWidget {
  @override
  _BpTrackingScreenState createState() => _BpTrackingScreenState();
}

class _BpTrackingScreenState extends State<BpTrackingScreen> {
  String _selectedRange = 'thg 4 23,2025 - thg 4 23,2026';
  bool _showAverage24h = true;
  int _currentIndex = 0;

  int _latestSbp = 100;
  int _latestDbp = 76;
  int _latestPulse = 70;
  String _latestDate = '2026-04-22 22:52';
  String _healthStatus = 'Bình thường';

  @override
  void initState() {
    super.initState();
    _loadLatestData();
  }

  Future<void> _loadLatestData() async {
    final data = await BpDataBaseProvider.db.getData();
    if (data.isNotEmpty) {
      final latest = data.first;
      setState(() {
        _latestSbp = latest.sbp;
        _latestDbp = latest.dbp;
        _latestPulse = latest.hr;
        _latestDate = latest.date;
        _healthStatus = _getHealthStatus(latest.sbp, latest.dbp);
      });
    }
  }

  String _getHealthStatus(int sbp, int dbp) {
    if (sbp < 120 && dbp < 80) {
      return 'Bình thường';
    } else if (sbp >= 140 || dbp >= 90) {
      return 'Cao huyết áp';
    } else if (sbp >= 120 || dbp >= 80) {
      return 'Tiền cao huyết áp';
    } else if (sbp < 90 || dbp < 60) {
      return 'Thấp huyết áp';
    }
    return 'Bình thường';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Bình thường':
        return Color(0xFF24D876);
      case 'Cao huyết áp':
        return Color(0xFFEF5350);
      case 'Tiền cao huyết áp':
        return Color(0xFFFF9800);
      case 'Thấp huyết áp':
        return Color(0xFF2196F3);
      default:
        return Color(0xFF24D876);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Color(0xFFF5F7FA),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        border: null,
        middle: Text(
          'TRACKING HUYET AP MOI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF4CAF50),
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: Color(0xFF4CAF50),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTimeFilter(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(height: 16),
                    _buildMainCard(),
                    SizedBox(height: 16),
                    _buildHealthStatusCard(),
                    SizedBox(height: 16),
                    _buildButtons(),
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
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CupertinoIcons.heart_fill,
                  size: 16,
                  color: Color(0xFF4ECDC4),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                CupertinoIcons.wifi,
                size: 18,
                color: CupertinoColors.systemGrey,
              ),
              SizedBox(width: 8),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.battery_full,
                    size: 18,
                    color: CupertinoColors.systemGrey,
),
                  SizedBox(width: 4),
                  Text(
                    '72%',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Huyết áp',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(0xFF4CAF50).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CupertinoIcons.heart_fill,
                  size: 18,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                CupertinoIcons.clock,
                size: 20,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTitleBar(),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemGrey.withOpacity(0.08),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chi tiết',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _selectedRange,
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            CupertinoIcons.line_horizontal_3_decrease,
                            size: 14,
                            color: Color(0xFF4CAF50),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.chevron_left,
                  size: 16,
                  color: Color(0xFF4CAF50),
                ),
                SizedBox(width: 12),
                Text(
                  'trung bình 24h',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                SizedBox(width: 12),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: Color(0xFF4CAF50),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricColumn('Tâm thu', '${_latestSbp}', 'mmHg', Color(0xFF4CAF50)),
              Container(
                height: 50,
                width: 1,
                color: CupertinoColors.systemGrey5,
              ),
              _buildMetricColumn('Tâm trương', '${_latestDbp}', 'mmHg', Color(0xFF4CAF50)),
              Container(
                height: 50,
                width: 1,
                color: CupertinoColors.systemGrey5,
              ),
              _buildMetricColumn('Xung', '${_latestPulse}', 'BPM', Color(0xFFFF7043)),
            ],
          ),
          SizedBox(height: 24),
          Divider(height: 1),
          SizedBox(height: 24),
          _buildBarChart(),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.systemGrey,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 12,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    final minValue = 70;
    final maxValue = 120;
    final range = maxValue - minValue;
    final sbpHeight = ((_latestSbp - minValue) / range * 120).clamp(10.0, 120.0);
    final dbpHeight = ((_latestDbp - minValue) / range * 120).clamp(10.0, 120.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '70',
              style: TextStyle(
                fontSize: 10,
                color: CupertinoColors.systemGrey3,
              ),
            ),
            Text(
              '85',
              style: TextStyle(
                fontSize: 10,
                color: CupertinoColors.systemGrey3,
              ),
            ),
            Text(
              '100',
              style: TextStyle(
                fontSize: 10,
                color: CupertinoColors.systemGrey3,
              ),
            ),
            Text(
              '115',
              style: TextStyle(
                fontSize: 10,
                color: CupertinoColors.systemGrey3,
              ),
            ),
            Text(
              '120',
              style: TextStyle(
                fontSize: 10,
                color: CupertinoColors.systemGrey3,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          height: 140,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: CupertinoColors.systemGrey5,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < 5; i++)
                Positioned(
                  bottom: i * 30.0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    color: CupertinoColors.systemGrey5.withOpacity(0.5),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildPillBar(sbpHeight, Color(0xFF4CAF50)),
                  _buildPillBar(dbpHeight, Color(0xFF81C784)),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '${_latestSbp}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Color(0xFF81C784),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '${_latestDbp}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF81C784),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 8),
        Center(
          child: Text(
            '4.22',
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPillBar(double height, Color color) {
    return Container(
      width: 40,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildHealthStatusCard() {
    final statusColor = _getStatusColor(_healthStatus);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              CupertinoIcons.heart_fill,
              size: 24,
              color: statusColor,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$_latestSbp / $_latestDbp',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.label,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'mmHg',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _healthStatus,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Pulse: $_latestPulse BPM',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  _latestDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            CupertinoIcons.chevron_right,
            size: 20,
            color: CupertinoColors.systemGrey3,
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey.withOpacity(0.08),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.clock,
                    size: 18,
                    color: CupertinoColors.systemGrey,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tất cả lịch sử',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => BloodPressure(),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF4CAF50),
                    Color(0xFF66BB6A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF4CAF50).withOpacity(0.4),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.plus,
                    size: 18,
                    color: CupertinoColors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Thêm bản ghi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}