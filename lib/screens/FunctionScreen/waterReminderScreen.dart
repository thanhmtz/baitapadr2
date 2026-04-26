import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bp_notepad/db/alarm_databaseProvider.dart';
import 'package:bp_notepad/models/alarmModel.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:math' as math;

class WaterReminderScreen extends StatefulWidget {
  @override
  _WaterReminderScreenState createState() => _WaterReminderScreenState();
}

class _WaterReminderScreenState extends State<WaterReminderScreen> with TickerProviderStateMixin {
  List<AlarmDB> _reminders = [];
  bool _isLoading = true;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  int _selectedGlasses = 1;
  AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: Duration(seconds: 2))..repeat();
    tz_data.initializeTimeZones();
    _initNotifications();
    _loadReminders();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    var android = AndroidInitializationSettings('@mipmap/ic_launcher');
    var initSettings = InitializationSettings(android: android);
    await _notifications.initialize(initSettings);
  }

  Future<void> _loadReminders() async {
    var data = await AlarmDataBaseProvider.db.getData();
    setState(() {
      _reminders = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Color(0xFFF0F4F8),
      child: Stack(
        children: [
          Container(
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF64B5F6), Color(0xFF90CAF9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Container(
            height: 280,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: WavePainter(_waveController.value),
                  size: Size.infinite,
                );
              },
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(child: _buildWaterProgress()),
                SliverToBoxAdapter(child: _buildQuickAdd()),
                SliverToBoxAdapter(child: _buildRemindersList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text('Water Reminder', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: CupertinoColors.white)),
          Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: CupertinoColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Icon(CupertinoIcons.plus, color: CupertinoColors.white, size: 24),
            ),
            onPressed: () => _showAddReminderDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterProgress() {
    int totalToday = _reminders.where((r) => r.state == '1').fold(0, (sum, r) => sum + (int.tryParse(r.dosage ?? '1') ?? 1));
    int goal = 8;
    double progress = (totalToday / goal).clamp(0.0, 1.0);

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Color(0xFF2196F3).withOpacity(0.15), blurRadius: 25, offset: Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's Progress", style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
                  SizedBox(height: 4),
                  Text('$totalToday / $goal glasses', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2196F3))),
                ],
              ),
              _WaterGlass(fillPercent: progress),
            ],
          ),
          SizedBox(height: 20),
          Container(
            height: 10,
            decoration: BoxDecoration(color: Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(5)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF64B5F6)]),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAdd() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF1976D2)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Color(0xFF2196F3).withOpacity(0.3), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: CupertinoColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
            child: Icon(CupertinoIcons.lightbulb_fill, color: CupertinoColors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Goal', style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text('2L (8 glasses) recommended', style: TextStyle(color: CupertinoColors.white.withOpacity(0.8), fontSize: 13)),
              ],
            ),
          ),
          Icon(CupertinoIcons.arrow_right, color: CupertinoColors.white.withOpacity(0.6)),
        ],
      ),
    );
  }

  Widget _buildRemindersList() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reminders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('${_reminders.length} active', style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
            ],
          ),
          SizedBox(height: 16),
          if (_reminders.isEmpty)
            _buildEmptyCard()
          else
            ..._reminders.map((reminder) => _buildReminderCard(reminder)),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: CupertinoColors.systemGrey.withOpacity(0.08), blurRadius: 15)]),
      child: Column(
        children: [
          Icon(CupertinoIcons.drop, size: 60, color: Color(0xFF90CAF9)),
          SizedBox(height: 16),
          Text('No reminders yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('Tap + to add your first water reminder', style: TextStyle(color: CupertinoColors.systemGrey)),
        ],
      ),
    );
  }

  Widget _buildReminderCard(AlarmDB reminder) {
    bool isEnabled = reminder.state == '1';
    int glasses = int.tryParse(reminder.dosage ?? '1') ?? 1;
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: CupertinoColors.systemGrey.withOpacity(0.06), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: isEnabled ? [Color(0xFF2196F3), Color(0xFF64B5F6)] : [Color(0xFFBDBDBD), Color(0xFFE0E0E0)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.drop_fill, color: CupertinoColors.white, size: 20),
                Text('$glasses', style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.date, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isEnabled ? CupertinoColors.label : CupertinoColors.systemGrey)),
                Text('$glasses glass${glasses > 1 ? 'es' : ''} of water', style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
              ],
            ),
          ),
          CupertinoSwitch(
            value: isEnabled,
            activeColor: Color(0xFF2196F3),
            onChanged: (val) => _toggleReminder(reminder, val),
          ),
        ],
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    DateTime _selectedTime = DateTime.now();
    _selectedGlasses = 1;
    showCupertinoModalPopup(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF64B5F6)]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text('Cancel', style: TextStyle(color: CupertinoColors.white.withOpacity(0.8))),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text('New Reminder', style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text('Save', style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold)),
                      onPressed: () => _saveReminder(_selectedTime),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Time', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey)),
                      SizedBox(height: 12),
                      Container(
                        height: 120,
                        decoration: BoxDecoration(color: Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(18)),
                        child: CupertinoDatePicker(mode: CupertinoDatePickerMode.time, use24hFormat: true, onDateTimeChanged: (date) => _selectedTime = date),
                      ),
                      SizedBox(height: 20),
                      Text('Glasses', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey)),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(18)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _GlassSelector(icon: CupertinoIcons.minus, onTap: () => setDialogState(() { if (_selectedGlasses > 1) _selectedGlasses--; })),
                            SizedBox(width: 20),
                            _LiquidGlass(percent: _selectedGlasses / 10),
                            SizedBox(width: 20),
                            _GlassSelector(icon: CupertinoIcons.plus, onTap: () => setDialogState(() { if (_selectedGlasses < 10) _selectedGlasses++; })),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveReminder(DateTime dateTime) async {
    String time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    AlarmDB alarm = AlarmDB(medicine: 'Drink water', date: time, state: '1', dosage: _selectedGlasses.toString());
    await AlarmDataBaseProvider.db.insert(alarm);
    await _scheduleNotification(alarm.id, time, _selectedGlasses);
    Navigator.pop(context);
    _loadReminders();
  }

  Future<void> _toggleReminder(AlarmDB reminder, bool enabled) async {
    AlarmDB updated = AlarmDB(id: reminder.id, medicine: reminder.medicine, date: reminder.date, state: enabled ? '1' : '0', dosage: reminder.dosage);
    await AlarmDataBaseProvider.db.update(updated);
    if (enabled) await _scheduleNotification(reminder.id, reminder.date, int.tryParse(reminder.dosage ?? '1') ?? 1);
    _loadReminders();
  }

  Future<void> _scheduleNotification(int id, String time, int glasses) async {
    var parts = time.split(':');
    var hour = int.parse(parts[0]);
    var minute = int.parse(parts[1]);
    var androidDetails = AndroidNotificationDetails('1', 'Water Reminder', 'Reminds you to drink water');
    var details = NotificationDetails(android: androidDetails);
    var scheduledDate = tz.TZDateTime(tz.local, DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, minute);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) scheduledDate = scheduledDate.add(Duration(days: 1));
    String message = glasses == 1 ? 'Drink 1 glass of water' : 'Drink $glasses glasses of water';
    await _notifications.zonedSchedule(id, 'Time to Drink Water!', message, scheduledDate, details, matchDateTimeComponents: DateTimeComponents.time, androidAllowWhileIdle: true);
  }
}

class WavePainter extends CustomPainter {
  final double wavePhase;
  WavePainter(this.wavePhase);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = CupertinoColors.white.withOpacity(0.1);
    var path = Path();
    path.moveTo(0, size.height * 0.7);
    for (double i = 0; i <= size.width; i++) {
      path.lineTo(i, size.height * 0.6 + math.sin((i / size.width * 2 * math.pi) + (wavePhase * 2 * math.pi)) * 15);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => wavePhase != oldDelegate.wavePhase;
}

class _WaterGlass extends StatelessWidget {
  final double fillPercent;
  _WaterGlass({this.fillPercent = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 90,
      child: Stack(
        children: [
          Container(
            width: 70,
            height: 90,
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFF2196F3), width: 3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 500),
              height: 84 * fillPercent,
              width: 64,
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF64B5F6).withOpacity(0.6), Color(0xFF2196F3).withOpacity(0.6)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidGlass extends StatelessWidget {
  final double percent;
  _LiquidGlass({this.percent = 0.5});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 90,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 70,
            height: 90,
            decoration: BoxDecoration(
              color: Color(0xFFE3F2FD),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7)),
            child: Container(
              height: 84 * percent,
              width: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFBBDEFB), Color(0xFF2196F3)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(width: 15, height: 8, decoration: BoxDecoration(color: CupertinoColors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(4))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSelector extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  _GlassSelector({this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF64B5F6)]),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Color(0xFF2196F3).withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Icon(icon, color: CupertinoColors.white, size: 24),
      ),
    );
  }
}