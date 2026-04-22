import 'dart:async';
import 'dart:convert';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivitySession {
  final DateTime startTime;
  final DateTime endTime;
  final int steps;
  final double distanceKm;
  final double calories;
  final String activityType;

  ActivitySession({
    DateTime startTime,
    DateTime endTime,
    this.steps = 0,
    this.distanceKm = 0,
    this.calories = 0,
    this.activityType = 'standing',
  })  : startTime = startTime ?? DateTime.now(),
        endTime = endTime ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'steps': steps,
    'distanceKm': distanceKm,
    'calories': calories,
    'activityType': activityType,
  };

  factory ActivitySession.fromJson(Map<String, dynamic> json) => ActivitySession(
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null
        ? DateTime.parse(json['endTime'])
        : DateTime.now(),
    steps: json['steps'] ?? 0,
    distanceKm: (json['distanceKm'] ?? 0).toDouble(),
    calories: (json['calories'] ?? 0).toDouble(),
    activityType: json['activityType'] ?? 'standing',
  );
}

class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  // Raw steps từ pedometer (tích lũy từ lúc boot)
  int _rawStepsAtStart = -1;  // raw lúc bấm Start
  int _lastRawSteps = -1;     // raw mới nhất nhận được

  // Session hiện tại
  int _sessionSteps = 0;
  double _distanceKm = 0;
  double _sessionCalories = 0;
  String _activityType = 'standing';
  double _speed = 0;
  int _durationMinutes = 0;

  // Tính speed
  int _prevStepsForSpeed = 0;
  DateTime _prevTimeForSpeed;

  // Daily
  int _dailyStepsFromPastSessions = 0;

  double _weight = 70;
  final double _strideLength = 0.75; // mét
  int _dailyGoal = 10000;

  DateTime _startTime;
  StreamSubscription<StepCount> _stepSubscription;
  bool _isPedometerAvailable = false;
  bool _isTracking = false;
  bool _isBackgroundMode = false;

  Timer _minuteTimer;
  List<ActivitySession> _sessionHistory = [];
  ActivitySession _currentSession;

  static const String _historyKey = 'activity_history';
  static const String _goalKey = 'daily_goal';
  static const String _dailyStepsKey = 'today_steps_accumulated';
  static const String _lastDateKey = 'last_date';
  static const String _trackingStateKey = 'tracking_active';
  static const String _trackingStepsKey = 'tracking_current_steps';
  static const String _trackingDistanceKey = 'tracking_current_distance';
  static const String _trackingCaloriesKey = 'tracking_current_calories';
  static const String _trackingStartTimeKey = 'tracking_start_time';
  static const String _rawStepsAtStartKey = 'raw_steps_at_start';
  static const String _lastRawStepsKey = 'last_raw_steps';

  int get steps => _sessionSteps;
  double get distanceKm => _distanceKm;
  double get sessionCalories => _sessionCalories;
  String get activityType => _activityType;
  double get speed => _speed;
  int get durationMinutes => _durationMinutes;
  bool get isTracking => _isTracking;
  bool get isPedometerReady => _isPedometerAvailable;
  int get dailyGoal => _dailyGoal;
  int get dailyTotalSteps => _dailyStepsFromPastSessions + _sessionSteps;
  List<ActivitySession> get sessionHistory => _sessionHistory;

  void setWeight(double weight) {
    _weight = weight > 0 ? weight : 70;
  }

  void setDailyGoal(int goal) {
    _dailyGoal = goal > 0 ? goal : 10000;
    _saveGoal();
  }

  Future<bool> init() async {
    await _loadHistory();
    await _loadDailyData();
    return await _initPedometer();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _sessionHistory =
            decoded.map((e) => ActivitySession.fromJson(e)).toList();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        _sessionHistory = _sessionHistory.where((s) {
          final d = DateTime(
              s.startTime.year, s.startTime.month, s.startTime.day);
          return d.isAfter(today.subtract(const Duration(days: 7)));
        }).toList();
      }
      _dailyGoal = (await SharedPreferences.getInstance()).getInt(_goalKey) ?? 10000;
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  Future<void> _loadDailyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDate = prefs.getString(_lastDateKey);
      final now = DateTime.now();
      final today = '${now.year}-${now.month}-${now.day}';
      if (lastDate != today) {
        await prefs.setInt(_dailyStepsKey, 0);
        await prefs.setString(_lastDateKey, today);
        _dailyStepsFromPastSessions = 0;
        await _clearTrackingState(prefs);
      } else {
        _dailyStepsFromPastSessions = prefs.getInt(_dailyStepsKey) ?? 0;
        if (prefs.getBool(_trackingStateKey) == true) {
          _sessionSteps = prefs.getInt(_trackingStepsKey) ?? 0;
          _distanceKm = prefs.getDouble(_trackingDistanceKey) ?? 0;
          _sessionCalories = prefs.getDouble(_trackingCaloriesKey) ?? 0;
          _rawStepsAtStart = prefs.getInt(_rawStepsAtStartKey) ?? -1;
          _lastRawSteps = prefs.getInt(_lastRawStepsKey) ?? -1;
          if (_rawStepsAtStart >= 0 && _lastRawSteps >= 0) {
            _isTracking = true;
          }
        }
      }
    } catch (e) {
      print('Error loading daily data: $e');
    }
  }

  Future<void> _clearTrackingState(SharedPreferences prefs) async {
    await prefs.setBool(_trackingStateKey, false);
    await prefs.setInt(_trackingStepsKey, 0);
    await prefs.setDouble(_trackingDistanceKey, 0);
    await prefs.setDouble(_trackingCaloriesKey, 0);
    await prefs.setInt(_rawStepsAtStartKey, -1);
    await prefs.setInt(_lastRawStepsKey, -1);
  }

  Future<void> _saveDailyData(int totalSteps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dailyStepsKey, totalSteps);
      final now = DateTime.now();
      await prefs.setString(
          _lastDateKey, '${now.year}-${now.month}-${now.day}');
      if (_isTracking) {
        await prefs.setBool(_trackingStateKey, true);
        await prefs.setInt(_trackingStepsKey, _sessionSteps);
        await prefs.setDouble(_trackingDistanceKey, _distanceKm);
        await prefs.setDouble(_trackingCaloriesKey, _sessionCalories);
        await prefs.setInt(_rawStepsAtStartKey, _rawStepsAtStart);
        await prefs.setInt(_lastRawStepsKey, _lastRawSteps);
      }
    } catch (e) {
      print('Error saving daily data: $e');
    }
  }

  Future<void> _saveGoal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_goalKey, _dailyGoal);
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_sessionHistory.map((e) => e.toJson()).toList());
      await prefs.setString(_historyKey, json);
    } catch (e) {
      print('Error saving history: $e');
    }
  }

  Future<bool> _initPedometer() async {
    try {
      final status = await Permission.activityRecognition.request();
      print('Permission status: $status');
      if (!status.isGranted) {
        _isPedometerAvailable = false;
        return false;
      }

      _stepSubscription?.cancel();
      _stepSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: (error) {
          print('Pedometer error: $error');
          _isPedometerAvailable = false;
        },
        cancelOnError: false,
      );
      _isPedometerAvailable = true;
      return true;
    } catch (e) {
      print('Pedometer init error: $e');
      _isPedometerAvailable = false;
      return false;
    }
  }

  void _onStepCount(StepCount event) {
    final rawNow = event.steps;
    print('Raw pedometer: $rawNow | tracking: $_isTracking | startRaw: $_rawStepsAtStart');

    // Lưu raw mới nhất (dùng khi bấm Start)
    _lastRawSteps = rawNow;

    if (!_isTracking) return;

    // Lần đầu nhận event sau khi bấm Start
    if (_rawStepsAtStart < 0) {
      _rawStepsAtStart = rawNow;
      _prevStepsForSpeed = 0;
      _prevTimeForSpeed = DateTime.now();
      return; // bước = 0, chờ event tiếp theo
    }

    // Tính bước trong session
    final newSessionSteps = rawNow - _rawStepsAtStart;
    if (newSessionSteps < 0) {
      // Trường hợp máy reboot giữa session
      _rawStepsAtStart = rawNow;
      return;
    }

    // Tính speed (bước/giây → km/h)
    final now = DateTime.now();
    if (_prevTimeForSpeed != null) {
      final deltaSteps = newSessionSteps - _prevStepsForSpeed;
      final deltaMs = now.difference(_prevTimeForSpeed).inMilliseconds;
      if (deltaMs > 0 && deltaSteps > 0) {
        final stepsPerSec = deltaSteps / (deltaMs / 1000.0);
        _speed = stepsPerSec * _strideLength * 3.6; // km/h
        print('Speed: $_speed km/h | deltaSteps: $deltaSteps | deltaMs: $deltaMs');
      }
    }
    _prevStepsForSpeed = newSessionSteps;
    _prevTimeForSpeed = now;

    _sessionSteps = newSessionSteps;
    _distanceKm = (_sessionSteps * _strideLength) / 1000;
    _detectActivity();
    _calculateCalories();

    // Lưu tổng bước ngày hôm nay
    _saveDailyData(_dailyStepsFromPastSessions + _sessionSteps);
  }

  void _detectActivity() {
    // km/h: đi bộ ~3-6, chạy >6
    if (_speed >= 6.0) {
      _activityType = 'running';
    } else if (_speed >= 2.5) {
      _activityType = 'walking';
    } else if (_sessionSteps > 0) {
      // Có bước nhưng speed thấp → vẫn tính walking
      _activityType = 'walking';
    } else {
      _activityType = 'standing';
    }
  }

  void _calculateCalories() {
    double met;
    switch (_activityType) {
      case 'running': met = 9.8; break;
      case 'walking': met = 3.5; break;
      default:        met = 1.3; break;
    }
    final hours = _durationMinutes / 60.0;
    _sessionCalories = met * _weight * (hours > 0 ? hours : 1 / 60.0);
  }

  Future<void> startTracking() async {
    if (_isTracking) return;

    _isTracking = true;
    _startTime = DateTime.now();

    // Reset session
    _sessionSteps = 0;
    _distanceKm = 0;
    _sessionCalories = 0;
    _speed = 0;
    _durationMinutes = 0;
    _activityType = 'standing';
    _prevStepsForSpeed = 0;
    _prevTimeForSpeed = null;

    // Quan trọng: nếu đã có raw steps thì set luôn, không chờ event
    if (_lastRawSteps >= 0) {
      _rawStepsAtStart = _lastRawSteps;
    } else {
      _rawStepsAtStart = -1; // chờ event đầu tiên
    }

    _currentSession = ActivitySession(startTime: _startTime);

    _minuteTimer?.cancel();
    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!_isTracking) { timer.cancel(); return; }
      _durationMinutes = DateTime.now().difference(_startTime).inMinutes;
      _calculateCalories();
    });
  }

  Future<void> stopTracking() async {
    if (!_isTracking) return;

    _isTracking = false;
    _minuteTimer?.cancel();

    _durationMinutes = DateTime.now().difference(_startTime).inMinutes;
    _calculateCalories();

    if (_sessionSteps > 0) {
      _currentSession = ActivitySession(
        startTime: _startTime,
        endTime: DateTime.now(),
        steps: _sessionSteps,
        distanceKm: _distanceKm,
        calories: _sessionCalories,
        activityType: _activityType,
      );
      _sessionHistory.insert(0, _currentSession);
      if (_sessionHistory.length > 100) {
        _sessionHistory = _sessionHistory.sublist(0, 100);
      }
      await _saveHistory();
    }

    // Cộng session này vào daily
    _dailyStepsFromPastSessions += _sessionSteps;
    await _saveDailyData(_dailyStepsFromPastSessions);

    // Reset
    _sessionSteps = 0;
    _distanceKm = 0;
    _rawStepsAtStart = -1;
    _speed = 0;
    _activityType = 'standing';
  }

  Future<void> startBackgroundTracking() async {
    _isBackgroundMode = true;
    await startTracking();
  }

  Future<void> stopBackgroundTracking() async {
    _isBackgroundMode = false;
    await stopTracking();
  }

  Map<String, dynamic> getTodayStats() {
    final totalSteps =
        _dailyStepsFromPastSessions + (_isTracking ? _sessionSteps : 0);

    // Tính từ session history cho ngày hôm nay
    final now = DateTime.now();
    final todaySessions = _sessionHistory.where((s) {
      final d = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      return d == DateTime(now.year, now.month, now.day);
    }).toList();

    double totalDistance = _isTracking
        ? _distanceKm
        : todaySessions.fold(0.0, (sum, s) => sum + s.distanceKm);
    double totalCalories = _isTracking
        ? _sessionCalories
        : todaySessions.fold(0.0, (sum, s) => sum + s.calories);
    int activeMinutes = _isTracking
        ? _durationMinutes
        : todaySessions.fold(
        0, (sum, s) => sum + s.endTime.difference(s.startTime).inMinutes);

    return {
      'steps': totalSteps,
      'distance': totalDistance,
      'calories': totalCalories,
      'activeMinutes': activeMinutes,
      'goal': _dailyGoal,
      'goalProgress': _dailyGoal > 0 ? totalSteps / _dailyGoal : 0.0,
    };
  }

  ActivityData getCurrentData() {
    return ActivityData(
      steps: _sessionSteps,
      distanceKm: _distanceKm,
      calories: _sessionCalories,
      activityType: _activityType,
      speed: _speed,
      durationMinutes: _durationMinutes,
    );
  }

  void dispose() {
    _minuteTimer?.cancel();
    _stepSubscription?.cancel();
  }
}

class ActivityData {
  final int steps;
  final double distanceKm;
  final double calories;
  final String activityType;
  final double speed;
  final int durationMinutes;
  final DateTime timestamp;

  ActivityData({
    this.steps = 0,
    this.distanceKm = 0,
    this.calories = 0,
    this.activityType = 'standing',
    this.speed = 0,
    this.durationMinutes = 0,
    DateTime timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}