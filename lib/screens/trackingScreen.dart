import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bp_notepad/components/lineChart1.dart';
import 'package:bp_notepad/components/lineChart2.dart';
import 'package:bp_notepad/components/lineChart3.dart';
import 'package:bp_notepad/components/lineChart4.dart';
import 'package:bp_notepad/components/lineChart5.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:bp_notepad/theme.dart';

class TrackingScreen extends StatefulWidget {
  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  DateTime _selectedDay = DateTime.now();
  CalendarController _calendarController = CalendarController();
  int _selectedChart = 0;

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(),
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text('Theo dõi', style: TextStyle(color: AppTheme.textPrimary())),
            backgroundColor: AppTheme.background(),
            border: null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCalendar(),
                  SizedBox(height: 20),
                  _buildChartSelector(),
                  SizedBox(height: 16),
                  _buildSelectedChart(),
                  SizedBox(height: 20),
                  Text(
                    'Tổng quan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.label,
                    ),
                  ),
                  SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _buildSummaryCards(),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        calendarController: _calendarController,
        initialCalendarFormat: CalendarFormat.week,
        startingDayOfWeek: StartingDayOfWeek.monday,
        availableCalendarFormats: {
          CalendarFormat.week: '',
          CalendarFormat.month: '',
        },
        calendarStyle: CalendarStyle(
          selectedColor: CupertinoColors.activeGreen,
          todayColor: CupertinoColors.activeGreen.withOpacity(0.3),
          markersColor: CupertinoColors.activeGreen,
          outsideDaysVisible: false,
        ),
        headerStyle: HeaderStyle(
          centerHeaderTitle: true,
          formatButtonVisible: true,
          formatButtonDecoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.activeGreen),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onDaySelected: (date, events, holidays) {
          setState(() {
            _selectedDay = date;
          });
        },
      ),
    );
  }

  Widget _buildChartSelector() {
    final charts = [
      {'icon': CupertinoIcons.heart_fill, 'label': 'Huyết áp', 'color': CupertinoColors.systemRed},
      {'icon': CupertinoIcons.drop_fill, 'label': 'Đường huyết', 'color': CupertinoColors.systemGreen},
      {'icon': CupertinoIcons.person_fill, 'label': 'BMI', 'color': CupertinoColors.systemBlue},
      {'icon': CupertinoIcons.moon_fill, 'label': 'Giấc ngủ', 'color': CupertinoColors.systemIndigo},
      {'icon': CupertinoIcons.flame_fill, 'label': 'Calories', 'color': CupertinoColors.systemOrange},
      {'icon': CupertinoIcons.heart, 'label': 'Nhịp tim', 'color': CupertinoColors.systemPink},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(charts.length, (index) {
          final chart = charts[index];
          final isSelected = _selectedChart == index;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedChart = index),
            child: Container(
              margin: EdgeInsets.only(right: 10),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (chart['color'] as Color) 
                    : CupertinoColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected 
                      ? (chart['color'] as Color) 
                      : CupertinoColors.systemGrey4,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    chart['icon'] as IconData,
                    size: 18,
                    color: isSelected 
                        ? CupertinoColors.white 
                        : (chart['color'] as Color),
                  ),
                  SizedBox(width: 6),
                  Text(
                    chart['label'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected 
                          ? CupertinoColors.white 
                          : CupertinoColors.label,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectedChart() {
    final key = _selectedDay.toIso8601String();
    switch (_selectedChart) {
      case 0:
        return _buildChartCard(Builder(key: ValueKey('bp$key'), builder: (_) => BPLineChart()), 'Huyết áp', CupertinoColors.systemRed);
      case 1:
        return _buildChartCard(Builder(key: ValueKey('bs$key'), builder: (_) => BSLineChart()), 'Đường huyết', CupertinoColors.systemGreen);
      case 2:
        return _buildChartCard(Builder(key: ValueKey('bmi$key'), builder: (_) => BmiLineChart()), 'BMI', CupertinoColors.systemBlue);
      case 3:
        return _buildChartCard(Builder(key: ValueKey('sleep$key'), builder: (_) => SleepLineChart()), 'Giấc ngủ', CupertinoColors.systemIndigo);
      case 4:
        return _buildChartCard(_buildCaloriesPlaceholder(), 'Calories', CupertinoColors.systemOrange);
      case 5:
        return _buildChartCard(Builder(key: ValueKey('hr$key'), builder: (_) => HRLineChart()), 'Nhịp tim', CupertinoColors.systemPink);
      default:
        return _buildChartCard(Builder(key: ValueKey('bp$key'), builder: (_) => BPLineChart()), 'Huyết áp', CupertinoColors.systemRed);
    }
  }

  Widget _buildChartCard(Widget chart, String title, Color color) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
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
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(CupertinoIcons.chart_bar_alt_fill, color: color, size: 20),
                ),
                SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: chart),
        ],
      ),
    );
  }

  Widget _buildCaloriesPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.flame_fill, size: 40, color: CupertinoColors.systemOrange),
          SizedBox(height: 8),
          Text('Biểu đồ Calories', style: TextStyle(color: CupertinoColors.systemGrey)),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Huyết áp',
                '120/80',
                'mmHg',
                CupertinoColors.systemRed,
                CupertinoIcons.heart_fill,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Đường huyết',
                '5.5',
                'mmol/L',
                CupertinoColors.systemGreen,
                CupertinoIcons.drop_fill,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'BMI',
                '22.5',
                '',
                CupertinoColors.systemBlue,
                CupertinoIcons.person_fill,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Giấc ngủ',
                '7.5',
                'giờ',
                CupertinoColors.systemIndigo,
                CupertinoIcons.moon_fill,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, String unit, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label,
                ),
              ),
              if (unit.isNotEmpty) ...[
                SizedBox(width: 4),
                Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}