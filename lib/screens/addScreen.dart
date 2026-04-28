import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bp_notepad/screens/FunctionScreen/bpTrackingScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/bpScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/bsScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/bmiScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/heartRateScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/sleepScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/activityScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/nutritionScreen.dart';
import 'package:bp_notepad/screens/FunctionScreen/waterReminderScreen.dart';
import 'package:bp_notepad/theme.dart';

class AddScreen extends StatefulWidget {
  @override
  _AddScreenState createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  @override
  void initState() {
    super.initState();
    isDarkModeGlobal.addListener(_onDarkModeChanged);
  }

  void _onDarkModeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    isDarkModeGlobal.removeListener(_onDarkModeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode;
    return Scaffold(
      backgroundColor: AppTheme.background(),
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text('Thêm mới', style: TextStyle(color: AppTheme.textPrimary())),
            backgroundColor: AppTheme.background(),
            border: null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategorySection(
                    context,
                    title: 'Sức khỏe',
                    icon: CupertinoIcons.heart_fill,
                    color: CupertinoColors.systemRed,
                    items: [
                      _CategoryItem(
                        icon: CupertinoIcons.heart_fill,
                        title: 'Huyết áp',
                        subtitle: 'Đo huyết áp',
                        color: CupertinoColors.systemRed,
                        onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => BpTrackingScreen())),
                      ),
                      _CategoryItem(
                        icon: CupertinoIcons.drop_fill,
                        title: 'Đường huyết',
                        subtitle: 'Đo đường huyết',
                        color: CupertinoColors.systemGreen,
                        onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => BloodSugar())),
                      ),
                      _CategoryItem(
                        icon: CupertinoIcons.person_fill,
                        title: 'BMI',
                        subtitle: 'Tính chỉ số BMI',
                        color: CupertinoColors.systemBlue,
                        onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => BmiScreen())),
                      ),
                      _CategoryItem(
                        icon: CupertinoIcons.waveform_path_ecg,
                        title: 'Nhịp tim',
                        subtitle: 'Đo nhịp tim',
                        color: CupertinoColors.systemPink,
                        onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => HeartRateScreen())),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  _buildCategorySection(
                    context,
                    title: 'Giấc ngủ & Thư giãn',
                    icon: CupertinoIcons.moon_fill,
                    color: CupertinoColors.systemIndigo,
                    items: [
                      _CategoryItem(
                        icon: CupertinoIcons.moon_fill,
                        title: 'Theo dõi giấc ngủ',
                        subtitle: 'Ghi lại thời gian ngủ',
                        color: CupertinoColors.systemIndigo,
                        onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => SleepScreen())),
                      ),
                      _CategoryItem(
                        icon: CupertinoIcons.music_note,
                        title: 'Âm thanh thư giãn',
                        subtitle: 'Nhạc giúp ngủ ngon',
                        color: CupertinoColors.systemPurple,
                        onTap: () => _showRelaxSoundDialog(context),
                      ),
                      _CategoryItem(
                        icon: CupertinoIcons.wind,
                        title: 'Thở thư giãn',
                        subtitle: 'Bài tập hít thở',
                        color: CupertinoColors.systemTeal,
                        onTap: () => _showBreathingDialog(context),
                      ),
                      _CategoryItem(
                        icon: CupertinoIcons.sparkles,
                        title: 'Meditation',
                        subtitle: 'Thiền định',
                        color: CupertinoColors.systemYellow,
                        onTap: () => _showMeditationDialog(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  _buildCategorySection(
                    context,
                    title: 'Hoạt động',
                    icon: CupertinoIcons.flame_fill,
                    color: CupertinoColors.systemOrange,
                    items: [
                      _CategoryItem(
                        icon: CupertinoIcons.flame_fill,
                        title: 'Bước chân',
                        subtitle: 'Đếm số bước đi',
                        color: CupertinoColors.systemOrange,
                        onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => ActivityScreen())),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  _buildCategorySection(
                    context,
                    title: 'Dinh dưỡng',
                    icon: CupertinoIcons.chart_bar_fill,
                    color: CupertinoColors.activeGreen,
                    items: [
                      _CategoryItem(
                        icon: CupertinoIcons.chart_bar_fill,
                        title: 'Dinh dưỡng',
                        subtitle: 'Thêm món ăn & calories',
                        color: CupertinoColors.activeGreen,
                        onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => NutritionScreen())),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  _buildCategorySection(
                    context,
                    title: 'Giữ gìn sức khỏe',
                    icon: CupertinoIcons.drop_fill,
                    color: CupertinoColors.systemTeal,
                    items: [
                      _CategoryItem(
                        icon: CupertinoIcons.drop_fill,
                        title: 'Nhắc uống nước',
                        subtitle: 'Theo dõi lượng nước',
                        color: CupertinoColors.systemTeal,
                        onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => WaterReminderScreen()))),
                    ],
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context, {
    String title,
    IconData icon,
    Color color,
    List<_CategoryItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.label,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        ...items.map((item) => _buildCategoryItem(context, item)),
      ],
    );
  }

  Widget _buildCategoryItem(BuildContext context, _CategoryItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    item.subtitle,
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

  void _showRelaxSoundDialog(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Âm thanh thư giãn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(CupertinoIcons.xmark_circle_fill, color: CupertinoColors.systemGrey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildSoundItem(context, 'Tiếng mưa', CupertinoIcons.cloud_rain, CupertinoColors.systemBlue),
                    _buildSoundItem(context, 'Tiếng sóng biển', CupertinoIcons.wind, CupertinoColors.systemTeal),
                    _buildSoundItem(context, 'Tiếng chim hót', CupertinoIcons.leaf_arrow_circlepath, CupertinoColors.systemGreen),
                    _buildSoundItem(context, 'Tiếng lửa campfire', CupertinoIcons.flame, CupertinoColors.systemOrange),
                    _buildSoundItem(context, 'Tiếng rừng', CupertinoIcons.tree, CupertinoColors.systemGreen),
                    _buildSoundItem(context, 'Nhạc piano nhẹ', CupertinoIcons.music_note, CupertinoColors.systemPurple),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoundItem(BuildContext context, String title, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          SizedBox(width: 12),
          Expanded(child: Text(title, style: TextStyle(fontSize: 16))),
          Icon(CupertinoIcons.play_circle, color: color, size: 28),
        ],
      ),
    );
  }

  void _showBreathingDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Thở thư giãn'),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: Column(
            children: [
              Icon(CupertinoIcons.wind, size: 50, color: CupertinoColors.systemTeal),
              SizedBox(height: 12),
              Text('Bài tập hít thở 4-7-8:\n\nHít vào: 4 giây\nGiữ: 7 giây\nThở ra: 8 giây\n\nGiúp giảm stress và ngủ ngon hơn!'),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Bắt đầu'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Đóng'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showMeditationDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Meditation'),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: Column(
            children: [
              Icon(CupertinoIcons.sparkles, size: 50, color: CupertinoColors.systemYellow),
              SizedBox(height: 12),
              Text('Thiền định giúp:\n• Giảm stress\n• Tăng tập trung\n• Cải thiện giấc ngủ\n\nChọn thời gian phù hợp và bắt đầu hành trình thiền định!'),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('5 phút'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: Text('10 phút'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Đóng'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  _CategoryItem({
    this.icon,
    this.title,
    this.subtitle,
    this.color,
    this.onTap,
  });
}