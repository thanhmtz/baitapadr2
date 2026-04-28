import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:bp_notepad/models/waterReminderModel.dart';
import 'package:bp_notepad/db/water_databaseProvider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _waterReminderChannelId = 'water_reminder_channel';
const String _waterReminderChannelName = 'Nhắc nhở uống nước';
const String _waterReminderChannelDesc = 'Nhắc nhở uống nước định kỳ';
const int _waterAlarmId = 100;

class WaterReminderScreen extends StatefulWidget {
  const WaterReminderScreen({Key key}) : super(key: key);

=======
import 'package:bp_notepad/db/alarm_databaseProvider.dart';
import 'package:bp_notepad/models/alarmModel.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:math' as math;

class WaterReminderScreen extends StatefulWidget {
>>>>>>> c433f0958c7b131a6e19678efbcfbebc3e6d3df1
  @override
  _WaterReminderScreenState createState() => _WaterReminderScreenState();
}

<<<<<<< HEAD
class _WaterReminderScreenState extends State<WaterReminderScreen>
    with SingleTickerProviderStateMixin {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  int _targetAmount = 2000;
  int _currentAmount = 0;
  int _lastDrinkAmount = 0;
  int _reminderInterval = 60;
  bool _reminderEnabled = true;
  WaterReminder _todayReminder;
  Timer _countdownTimer;
  int _countdownSeconds = 0;
  Timer _notificationTimer;

  List<WaterHistory> _history = [];
  int _selectedDrinkSize = 250;

  AnimationController _waveBackgroundController;

  static const Color _primaryBlue = Color(0xFF007AFF);
=======
class _WaterReminderScreenState extends State<WaterReminderScreen> with TickerProviderStateMixin {
  List<AlarmDB> _reminders = [];
  bool _isLoading = true;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  int _selectedGlasses = 1;
  AnimationController _waveController;
>>>>>>> c433f0958c7b131a6e19678efbcfbebc3e6d3df1

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _waveBackgroundController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 6000),
    )..repeat();
    _loadTodayData();
    _initNotifications();
    _loadSettings();
    _loadHistory();
=======
    _waveController = AnimationController(vsync: this, duration: Duration(seconds: 2))..repeat();
    tz_data.initializeTimeZones();
    _initNotifications();
    _loadReminders();
>>>>>>> c433f0958c7b131a6e19678efbcfbebc3e6d3df1
  }

  @override
  void dispose() {
<<<<<<< HEAD
    _waveBackgroundController.dispose();
    _countdownTimer?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    var allData = await WaterDataBaseProvider.db.getData();
    if (allData.isNotEmpty) {
      List<WaterHistory> historyList = [];
      for (var data in allData.reversed) {
        if (data.currentAmount > 0) {
          historyList.add(WaterHistory(
            amount: data.currentAmount,
            date: data.date,
          ));
        }
      }
      setState(() {
        _history = historyList.take(20).toList();
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _reminderInterval = prefs.getInt('water_reminder_interval') ?? 60;
      _reminderEnabled = prefs.getBool('water_reminder_enabled') ?? true;
    });
    if (_reminderEnabled) {
      _startNotificationTimer();
    }
  }

  void _initNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var android = AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOS = IOSInitializationSettings(
      requestSoundPermission: true,
      requestAlertPermission: true,
    );
    var initSettings = InitializationSettings(android: android, iOS: iOS);
    flutterLocalNotificationsPlugin.initialize(initSettings,
        onSelectNotification: _onNotificationTap);
  }

  Future<void> _onNotificationTap(String payload) async {
    if (payload == 'water_reminder') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WaterReminderScreen()),
      );
    }
  }

  void _startNotificationTimer() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(Duration(minutes: _reminderInterval), (timer) {
      if (_reminderEnabled && _currentAmount < _targetAmount) {
        _showReminderNotification();
      }
    });
  }

  Future<void> _showReminderNotification() async {
    var androidDetails = AndroidNotificationDetails(
      _waterReminderChannelId,
      _waterReminderChannelName,
      _waterReminderChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    var iOSDetails = IOSNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    var details = NotificationDetails(android: androidDetails, iOS: iOSDetails);

    await flutterLocalNotificationsPlugin.show(
      _waterAlarmId,
      'Nhắc nhở uống nước',
      'Đã uống $_currentAmount / $_targetAmount ml. Hãy uống thêm nước nhé!',
      details,
    );
  }

  bool get _goalReached => _currentAmount >= _targetAmount;
  int get _progressPercent => ((_currentAmount / _targetAmount) * 100).round();
  int get _totalCups => _currentAmount ~/ 250;
  int get _remaining => (_targetAmount - _currentAmount).clamp(0, _targetAmount);
  double get _progress => _currentAmount / _targetAmount;

  Future<void> _loadTodayData() async {
    var todayData = await WaterDataBaseProvider.db.getTodayData();
    if (todayData != null) {
      setState(() {
        _todayReminder = todayData;
        _targetAmount = todayData.targetAmount;
        _currentAmount = todayData.currentAmount;
        _lastDrinkAmount = todayData.lastDrinkAmount ?? 0;
      });
    } else {
      _createNewReminder();
    }
  }

  Future<void> _createNewReminder() async {
    WaterReminder newReminder = WaterReminder(
      targetAmount: _targetAmount,
      currentAmount: 0,
      unit: 'ml',
      date: DateTime.now(),
    );
    var inserted = await WaterDataBaseProvider.db.insert(newReminder);
    setState(() {
      _todayReminder = inserted;
    });
  }

  Future<void> _addWater(int amount) async {
    if (amount < 0 && _currentAmount + amount < 0) {
      amount = -_currentAmount;
    }
    setState(() {
      _currentAmount = (_currentAmount + amount).clamp(0, _targetAmount * 2);
      if (amount > 0) {
        _lastDrinkAmount = amount;
      }
    });
    if (_todayReminder != null) {
      _todayReminder.currentAmount = _currentAmount;
      _todayReminder.lastDrinkAmount = _lastDrinkAmount;
      await WaterDataBaseProvider.db.update(_todayReminder);
    }
    if (_currentAmount >= _targetAmount && _currentAmount - amount < _targetAmount) {
      _showGoalReachedNotification();
    }
    _loadHistory();
  }

  Future<void> _showGoalReachedNotification() async {
    var androidDetails = AndroidNotificationDetails(
      _waterReminderChannelId,
      'Hoàn thành mục tiêu',
      'Thông báo khi đạt mục tiêu',
      importance: Importance.high,
      priority: Priority.high,
    );
    var iOSDetails = IOSNotificationDetails();
    var details = NotificationDetails(android: androidDetails, iOS: iOSDetails);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Đã đạt mục tiêu!',
      'Bạn đã uống đủ $_targetAmount ml nước hôm nay!',
      details,
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _buildMainSection(),
          Positioned(
            left: 0,
            right: 0,
            top: screenHeight * 0.2,
            child: Container(
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                bottom: false,
                child: _buildQuickStats(),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: _buildControls(),
          ),
          _buildPercent(),
        ],
        
=======
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
>>>>>>> c433f0958c7b131a6e19678efbcfbebc3e6d3df1
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildMainSection() {
    return AnimatedBuilder(
      animation: _waveBackgroundController,
      builder: (context, child) {
        double minWaterLevel = MediaQuery.of(context).size.height * 0.15;
        double maxWaterLevel = MediaQuery.of(context).size.height * 0.85;
        double waterLevel = minWaterLevel + (maxWaterLevel - minWaterLevel) * (1 - _progress.clamp(0.0, 1.0));
        
        double waveOffset = math.sin(_waveBackgroundController.value * 2 * math.pi * 1.5) * 12;
        double percentY = waterLevel + waveOffset - 50;

        return SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Stack(
            children: [
              CustomPaint(
                painter: _FullScreenWavePainter(
                  wavePhase: _waveBackgroundController.value * 2 * math.pi,
                  progress: _progress.clamp(0.0, 1.0),
                ),
                size: Size(double.infinity, double.infinity),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(CupertinoIcons.back, color: _primaryBlue, size: 22),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(CupertinoIcons.clock, color: _primaryBlue, size: 22),
                            ),
                            onPressed: () => _showIntervalPicker(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showTargetPicker(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.flag_fill, color: _primaryBlue, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Mục tiêu: ${_targetAmount}ml',
                                style: TextStyle(
                                  color: _primaryBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(CupertinoIcons.pencil, color: _primaryBlue.withOpacity(0.6), size: 14),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 40),
                      Text(
                        '${_currentAmount}',
                        style: TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: _primaryBlue,
                          height: 1,
                        ),
                      ),
                      Text(
                        'ml',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w400,
                          color: _primaryBlue,
                        ),
                      ),
                      const Spacer(),
=======
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
>>>>>>> c433f0958c7b131a6e19678efbcfbebc3e6d3df1
                    ],
                  ),
                ),
              ),
            ],
          ),
<<<<<<< HEAD
        );
      },
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () {
            if (_currentAmount > 0) {
              _addWater(-_selectedDrinkSize);
            }
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.minus,
                color: Color(0xFFFF3B30),
                size: 22,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _addWater(_selectedDrinkSize),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF007AFF).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const FaIcon(
                  FontAwesomeIcons.tint,
                  color: CupertinoColors.white,
                  size: 32,
                ),
                Positioned(
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_selectedDrinkSize ml',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _showDrinkSizePicker(),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: _primaryBlue, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_selectedDrinkSize',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _primaryBlue,
                  ),
                ),
                Text(
                  'ml',
                  style: TextStyle(
                    fontSize: 8,
                    color: _primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(icon, color: _primaryBlue, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.black,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildInfoRow('Mục tiêu hàng ngày', '${_targetAmount} ml', FontAwesomeIcons.flag),
          const SizedBox(height: 12),
          _buildInfoRow('Lần uống gần nhất', _lastDrinkAmount > 0 ? '${_lastDrinkAmount} ml' : 'Chưa uống', FontAwesomeIcons.clock),
          const SizedBox(height: 12),
          _buildInfoRow('Tổng số lần uống', '$_totalCups cốc', FontAwesomeIcons.tint),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showHistoryBottomSheet(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: _primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(FontAwesomeIcons.chartLine, color: CupertinoColors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Lịch sử và Thống kê',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.chevron_right, color: CupertinoColors.white, size: 16),
                ],
),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercent() {
  double screenHeight = MediaQuery.of(context).size.height;

  double minWaterLevel = screenHeight * 0.15;
  double maxWaterLevel = screenHeight * 0.85;

  double waterLevel =
      minWaterLevel + (maxWaterLevel - minWaterLevel) * (1 - _progress.clamp(0.0, 1.0));

  double waveOffset =
      math.sin(_waveBackgroundController.value * 2 * math.pi * 1.5) * 12;

  double percentY = waterLevel + waveOffset - 50;

  return Positioned(
    left: 16,
    top: percentY.clamp(120.0, screenHeight * 0.9),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _primaryBlue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(FontAwesomeIcons.tint, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            '$_progressPercent%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
  void _showTargetPicker() {
    final targetOptions = [1500, 2000, 2500, 3000, 3500, 4000];
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 280,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Hủy'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Chọn mục tiêu',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Xong'),
                    onPressed: () {
                      _saveSettings();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 44,
                scrollController: FixedExtentScrollController(
                  initialItem: targetOptions.indexOf(_targetAmount) != -1
                      ? targetOptions.indexOf(_targetAmount)
                      : 1,
                ),
                onSelectedItemChanged: (index) {
                  setState(() {
                    _targetAmount = targetOptions[index];
                  });
                },
                children: targetOptions
                    .map((e) => Center(child: Text('$e ml')))
                    .toList(),
              ),
            ),
          ],
=======
>>>>>>> c433f0958c7b131a6e19678efbcfbebc3e6d3df1
        ),
      ),
    );
  }

<<<<<<< HEAD
  void _showIntervalPicker() {
    final intervalOptions = [15, 30, 45, 60, 90, 120, 180];
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 320,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Hủy'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Cài đặt nhắc nhở',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Lưu'),
                    onPressed: () {
                      _saveSettings();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Bật nhắc nhở'),
                  CupertinoSwitch(
                    value: _reminderEnabled,
                    onChanged: (value) {
                      setState(() {
                        _reminderEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 44,
                scrollController: FixedExtentScrollController(
                  initialItem: intervalOptions.indexOf(_reminderInterval) != -1
                      ? intervalOptions.indexOf(_reminderInterval)
                      : 3,
                ),
                onSelectedItemChanged: (index) {
                  setState(() {
                    _reminderInterval = intervalOptions[index];
                  });
                },
                children: intervalOptions
                    .map((e) => Center(child: Text('Nhắc sau $e phút')))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDrinkSizePicker() {
    final sizes = [100, 150, 200, 250, 300, 350, 400, 500];
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 280,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Hủy'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Chọn lượng nước',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Xong'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 44,
                scrollController: FixedExtentScrollController(
                  initialItem: sizes.indexOf(_selectedDrinkSize) != -1
                      ? sizes.indexOf(_selectedDrinkSize)
                      : 3,
                ),
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedDrinkSize = sizes[index];
                  });
                },
                children: sizes
                    .map((e) => Center(child: Text('$e ml')))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistoryBottomSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                  padding: EdgeInsets.zero,
                    child: const Text('Đóng'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Lịch sử uống nước',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Đặt lại'),
                    onPressed: () {
                      Navigator.pop(context);
                      _resetToday();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _history.isEmpty
                  ? const Center(
                      child: Text(
                        'Chưa có lịch sử uống nước hôm nay',
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: CupertinoColors.systemGrey5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _primaryBlue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${item.amount} ml',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatTime(item.date),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetToday() async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Đặt lại hôm nay'),
        content: const Text('Bạn có muốn đặt lại lượng nước hôm nay không?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Hủy'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              setState(() {
                _currentAmount = 0;
                _lastDrinkAmount = 0;
              });
              if (_todayReminder != null) {
                _todayReminder.currentAmount = 0;
                _todayReminder.lastDrinkAmount = 0;
                await WaterDataBaseProvider.db.update(_todayReminder);
              }
              Navigator.pop(context);
            },
            child: const Text('Đặt lại'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('water_reminder_interval', _reminderInterval);
    await prefs.setBool('water_reminder_enabled', _reminderEnabled);
    await prefs.setInt('water_target_amount', _targetAmount);

    _countdownSeconds = _reminderInterval * 60;

    if (_reminderEnabled) {
      _startNotificationTimer();
    } else {
      _notificationTimer?.cancel();
    }
  }
}

class _FullScreenWavePainter extends CustomPainter {
  final double wavePhase;
  final double progress;

  _FullScreenWavePainter({
    this.wavePhase = 0,
    this.progress = 0,
  });

@override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.white);

    double minWaterLevel = size.height * 0.15;
    double maxWaterLevel = size.height * 0.85;
    double waterLevel = minWaterLevel + (maxWaterLevel - minWaterLevel) * (1 - progress.clamp(0.0, 1.0));

    List<Color> waterColors = [
      const Color(0xFF007AFF),
      const Color(0xFF2196F3),
      const Color(0xFF64B5F6),
    ];

    Path waterPathDark = Path();
    waterPathDark.moveTo(0, size.height);
    waterPathDark.lineTo(0, waterLevel);

    for (double x = 0; x <= size.width; x += 2) {
      double y = waterLevel + math.sin(x * 1.2 * 0.008 + wavePhase * 0.8) * 5;
      y += math.sin(x * 2.0 * 0.006 + wavePhase * 0.5) * 3;
      waterPathDark.lineTo(x, y);
    }

    waterPathDark.lineTo(size.width, size.height);
    waterPathDark.close();

    Paint darkPaint = Paint()
      ..color = waterColors[0].withOpacity(0.6);

    canvas.drawPath(waterPathDark, darkPaint);

    Path waterPathLight = Path();
    waterPathLight.moveTo(0, size.height);
    waterPathLight.lineTo(0, waterLevel + 20);

    for (double x = 0; x <= size.width; x += 2) {
      double y = waterLevel + 20 + math.sin(x * 1.8 * 0.01 + wavePhase * 1.1 + 0.8) * 4;
      y += math.sin(x * 2.5 * 0.008 + wavePhase * 0.7 + 1.2) * 3;
      waterPathLight.lineTo(x, y);
    }

    waterPathLight.lineTo(size.width, size.height);
    waterPathLight.close();

    Paint lightPaint = Paint()
      ..color = waterColors[1].withOpacity(0.4);

    canvas.drawPath(waterPathLight, lightPaint);

    Path waterPathFront = Path();
    waterPathFront.moveTo(0, size.height);
    waterPathFront.lineTo(0, waterLevel + 35);

    for (double x = 0; x <= size.width; x += 2) {
      double y = waterLevel + 35 + math.sin(x * 2.2 * 0.012 + wavePhase * 1.4 + 1.5) * 3;
      y += math.sin(x * 3.0 * 0.009 + wavePhase * 0.9 + 2) * 2;
      waterPathFront.lineTo(x, y);
    }

    waterPathFront.lineTo(size.width, size.height);
    waterPathFront.close();

    Paint frontPaint = Paint()
      ..color = waterColors[2].withOpacity(0.3);

    canvas.drawPath(waterPathFront, frontPaint);

    Paint waveLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    Path waveLinePath = Path();
    for (double x = 0; x <= size.width; x += 2) {
      double y = waterLevel + math.sin(x * 1.2 * 0.008 + wavePhase * 0.8) * 5;
      y += math.sin(x * 2.0 * 0.006 + wavePhase * 0.5) * 3;
      if (x == 0) {
        waveLinePath.moveTo(x, y);
      } else {
        waveLinePath.lineTo(x, y);
      }
    }
    canvas.drawPath(waveLinePath, waveLinePaint);
  }

  @override
  bool shouldRepaint(_FullScreenWavePainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase ||
        oldDelegate.progress != progress;
  }
}

class WaterHistory {
  final int amount;
  final DateTime date;

  WaterHistory({this.amount = 0, this.date});
=======
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
>>>>>>> c433f0958c7b131a6e19678efbcfbebc3e6d3df1
}