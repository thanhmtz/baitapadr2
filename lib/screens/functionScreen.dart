import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bp_notepad/localization/appLocalization.dart';
import 'package:bp_notepad/screens/FunctionScreen/bpTrackingScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/bsScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/bmiScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/heartRateScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/sleepScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/activityScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/nutritionScreen.dart';

class FunctionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(AppLocalization.of(context).translate('function_page')),
            backgroundColor: CupertinoColors.systemGroupedBackground,
            border: null,
          ),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildListDelegate([
                _buildFuncCard(
                  context,
                  icon: CupertinoIcons.heart_fill,
                  color: CupertinoColors.systemRed,
                  title: 'Huyết áp',
                  subtitle: 'Đo & theo dõi',
                  onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => BpTrackingScreen())),
                ),
                _buildFuncCard(
                  context,
                  icon: CupertinoIcons.drop_fill,
                  color: CupertinoColors.systemGreen,
                  title: 'Đường huyết',
                  subtitle: 'Đo đường huyết',
                  onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => BloodSugar())),
                ),
                _buildFuncCard(
                  context,
                  icon: CupertinoIcons.person_fill,
                  color: CupertinoColors.systemBlue,
                  title: 'BMI',
                  subtitle: 'Chỉ số cơ thể',
                  onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => BmiScreen())),
                ),
                _buildFuncCard(
                  context,
                  icon: CupertinoIcons.waveform_path_ecg,
                  color: CupertinoColors.systemPink,
                  title: 'Nhịp tim',
                  subtitle: 'Đo nhịp tim',
                  onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => HeartRateScreen())),
                ),
                _buildFuncCard(
                  context,
                  icon: CupertinoIcons.moon_fill,
                  color: CupertinoColors.systemIndigo,
                  title: 'Giấc ngủ',
                  subtitle: 'Theo dõi giấc ngủ',
                  onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => SleepScreen())),
                ),
                _buildFuncCard(
                  context,
                  icon: CupertinoIcons.flame_fill,
                  color: CupertinoColors.systemOrange,
                  title: 'Hoạt động',
                  subtitle: 'Đếm bước chân',
                  onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => ActivityScreen())),
                ),
                _buildFuncCard(
                  context,
                  icon: CupertinoIcons.chart_bar_fill,
                  color: CupertinoColors.activeGreen,
                  title: 'Dinh dưỡng',
                  subtitle: 'Calories & macros',
                  onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => NutritionScreen())),
                  fullWidth: true,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuncCard(
    BuildContext context, {
    IconData icon,
    Color color,
    String title,
    String subtitle,
    VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.1),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey3,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}