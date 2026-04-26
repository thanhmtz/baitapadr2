import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bp_notepad/components/healthSingleChart.dart';
import 'package:table_calendar/table_calendar.dart';

class TrackingScreen extends StatefulWidget {
  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  DateTime _selectedDay = DateTime.now();
  CalendarController _calendarController = CalendarController();
  int _selectedMetric = 0;

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text('Theo dõi sức khỏe'),
            backgroundColor: CupertinoColors.systemGroupedBackground,
            border: null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCalendar(),
                  SizedBox(height: 24),
                  _buildMetricSelector(),
                  SizedBox(height: 20),
                  _buildSelectedChart(),
                  SizedBox(height: 24),
                ],
              ),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.08),
            blurRadius: 20,
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
          selectedColor: Color(0xFF4ECDC4),
          todayColor: Color(0xFF4ECDC4).withOpacity(0.2),
          markersColor: Color(0xFF4ECDC4),
          outsideDaysVisible: false,
        ),
        headerStyle: HeaderStyle(
          centerHeaderTitle: true,
          formatButtonVisible: false,
          leftChevronIcon: Icon(
            CupertinoIcons.chevron_left,
            color: Color(0xFF4ECDC4),
            size: 20,
          ),
          rightChevronIcon: Icon(
            CupertinoIcons.chevron_right,
            color: Color(0xFF4ECDC4),
            size: 20,
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

  Widget _buildMetricSelector() {
    final metrics = [
      {
        'icon': CupertinoIcons.heart_fill,
        'label': 'Nhịp tim',
        'subLabel': 'Heart Rate',
        'color': Color(0xFFFF6B6B),
        'gradient': [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
      },
      {
        'icon': CupertinoIcons.drop_fill,
        'label': 'Đường huyết',
        'subLabel': 'Blood Sugar',
        'color': Color(0xFF4ECDC4),
        'gradient': [Color(0xFF4ECDC4), Color(0xFF6EE7DE)],
      },
      {
        'icon': CupertinoIcons.heart_circle_fill,
        'label': 'Huyết áp',
        'subLabel': 'Blood Pressure',
        'color': Color(0xFFFF8E53),
        'gradient': [Color(0xFFFF8E53), Color(0xFFFFAB76)],
      },
      {
        'icon': CupertinoIcons.person_fill,
        'label': 'BMI',
        'subLabel': 'Body Mass Index',
        'color': Color(0xFF45B7D1),
        'gradient': [Color(0xFF45B7D1), Color(0xFF7DD3E8)],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn chỉ số',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
          ),
        ),
        SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(metrics.length, (index) {
              final metric = metrics[index];
              final isSelected = _selectedMetric == index;
              
              return GestureDetector(
                onTap: () => setState(() => _selectedMetric = index),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: 12),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: metric['gradient'] as List<Color>,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : CupertinoColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? null
                        : Border.all(color: CupertinoColors.systemGrey5),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (metric['color'] as Color).withOpacity(0.4),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: CupertinoColors.systemGrey.withOpacity(0.05),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? CupertinoColors.white.withOpacity(0.2)
                              : (metric['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          metric['icon'] as IconData,
                          size: 18,
                          color: isSelected
                              ? CupertinoColors.white
                              : metric['color'] as Color,
                        ),
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            metric['label'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? CupertinoColors.white
                                  : CupertinoColors.label,
                            ),
                          ),
                          if (isSelected)
                            Text(
                              metric['subLabel'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                color: CupertinoColors.white.withOpacity(0.8),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedChart() {
    final metricTypes = [
      HealthMetricType.heartRate,
      HealthMetricType.bloodSugar,
      HealthMetricType.bloodPressure,
      HealthMetricType.bmi,
    ];

    final colors = [
      Color(0xFFFF6B6B),
      Color(0xFF4ECDC4),
      Color(0xFFFF8E53),
      Color(0xFF45B7D1),
    ];

    final titles = ['Nhịp tim', 'Đường huyết', 'Huyết áp', 'BMI'];
    final icons = [
      CupertinoIcons.heart_fill,
      CupertinoIcons.drop_fill,
      CupertinoIcons.heart_circle_fill,
      CupertinoIcons.person_fill,
    ];

    return _buildChartCard(
      HealthSingleChart(metricType: metricTypes[_selectedMetric]),
      titles[_selectedMetric],
      icons[_selectedMetric],
      colors[_selectedMetric],
    );
  }

  Widget _buildChartCard(Widget chart, String title, IconData icon, Color color) {
    return Container(
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
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: CupertinoColors.white, size: 22),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.label,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '30 ngày gần nhất',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.chart_bar_fill,
                        size: 14,
                        color: color,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Bar Chart',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          SizedBox(height: 8),
          SizedBox(
            height: 320,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: chart,
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}