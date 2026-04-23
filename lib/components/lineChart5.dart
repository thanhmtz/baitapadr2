import 'package:bp_notepad/db/hr_databaseProvider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HRLineChart extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HRLineChartState();
}

class _HRLineChartState extends State<HRLineChart> {
  static const double minx = 0;
  static const double maxx = 9;

  int segmentedControlGroupValue = 10;

  double hrAvg = 0;
  int max = 120;
  int min = 60;

  List<FlSpot> hrSpotsData = [];
  bool showAvg = false;

  final List<Color> gradientColors = [CupertinoColors.systemPink, CupertinoColors.systemPink];

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
        aspectRatio: 1,
        child: FutureBuilder<List>(
          future: HeartRateDataBaseProvider.db.getGraphData(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              int showLength = 0;
              int addLength = 0;
              if ((snapshot.data[0].length - segmentedControlGroupValue) > 0) {
                showLength = maxx.toInt() + 1;
                addLength = maxx.toInt() + 1;
              } else {
                showLength = snapshot.data[0].length;
                addLength = snapshot.data[0].length;
              }

              for (int i = 0; i < showLength; i++) {
                hrSpotsData.add(FlSpot(i.toDouble(), (snapshot.data[0][i]).toDouble()));
              }

              double sum = 0;
              for (int i = 0; i < snapshot.data[0].length; i++) {
                sum += (snapshot.data[0][i]).toDouble();
              }
              if (snapshot.data[0].length > 0) {
                hrAvg = sum / snapshot.data[0].length;
              }

              return Padding(
                padding: EdgeInsets.only(right: 10, left: 0, top: 10, bottom: 0),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: CupertinoColors.systemGrey5,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitles: (value) {
                          if (value.toInt() == 0 || value.toInt() == addLength - 1 || value.toInt() == (addLength - 1) ~/ 2) {
                            return value.toInt().toString();
                          }
                          return '';
                        },
                      ),
                      leftTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 38,
                        getTitles: (value) {
                          return value.toInt().toString();
                        },
                      ),
                      topTitles: SideTitles(showTitles: false),
                      rightTitles: SideTitles(showTitles: false),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: minx,
                    maxX: maxx,
                    minY: _getMinY(),
                    maxY: _getMaxY(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: hrSpotsData,
                        isCurved: true,
                        colors: gradientColors,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: gradientColors[0],
                              strokeWidth: 1,
                              strokeColor: CupertinoColors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          colors: gradientColors.map((color) => color.withOpacity(0.2)).toList(),
                        ),
                      ),
                      if (showAvg)
                        LineChartBarData(
                          spots: getHRAvgData(),
                          isCurved: false,
                          colors: [CupertinoColors.systemGreen, CupertinoColors.systemGreen],
                          barWidth: 2,
                          dotData: FlDotData(show: false),
                          dashArray: [5, 5],
                        ),
                    ],
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((touchedSpot) {
                            return LineTooltipItem(
                              '${touchedSpot.y.toInt()}',
                              TextStyle(
                                color: touchedSpot.bar.colors[0],
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              );
            } else {
              return Center(child: CupertinoActivityIndicator());
            }
          },
        ));
  }

  List<FlSpot> getHRAvgData() {
    List<FlSpot> avgHRSpotDatas = [];
    for (int x = 0; x <= maxx; x++) {
      avgHRSpotDatas.add(FlSpot(x.toDouble(), hrAvg));
    }
    return avgHRSpotDatas;
  }

  double _getMinY() {
    if (hrSpotsData.isEmpty) return min.toDouble();
    final dataMin = hrSpotsData.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final dataMax = hrSpotsData.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    if (dataMax <= dataMin) return dataMin - 5;
    return dataMin;
  }

  double _getMaxY() {
    if (hrSpotsData.isEmpty) return max.toDouble();
    final dataMin = hrSpotsData.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final dataMax = hrSpotsData.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    if (dataMax <= dataMin) return dataMax + 5;
    return dataMax;
  }
}