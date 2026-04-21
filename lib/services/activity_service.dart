import 'dart:async';
import 'dart:math';
import 'package:pedometer/pedometer.dart';
import 'package:geolocator/geolocator.dart';

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

class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  int _steps = 0;
  int _initialSteps = 0;
  double _distanceKm = 0;
  double _calories = 0;
  String _activityType = 'standing';
  double _speed = 0;
  int _durationMinutes = 0;
  double _weight = 70;
  double _strideLength = 0.75;
  
  DateTime _startTime;
  StreamSubscription<StepCount> _stepSubscription;
  bool _isPedometerAvailable = false;
  bool _isTracking = false;

  Timer _activityTimer;
  Timer _saveTimer;

  int get steps => _steps;
  double get distanceKm => _distanceKm;
  double get calories => _calories;
  String get activityType => _activityType;
  double get speed => _speed;
  int get durationMinutes => _durationMinutes;
  bool get isTracking => _isTracking;

  void setWeight(double weight) {
    _weight = weight > 0 ? weight : 70;
    _strideLength = _calculateStrideLength();
  }

  double _calculateStrideLength() {
    return _weight * 0.415 / 100;
  }

  Future<bool> init() async {
    _strideLength = _calculateStrideLength();
    return await _initPedometer();
  }

  Future<bool> _initPedometer() async {
    try {
      _stepSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
      );
      _isPedometerAvailable = true;
      return true;
    } catch (e) {
      _isPedometerAvailable = false;
      return false;
    }
  }

  void _onStepCount(StepCount event) {
    if (_initialSteps == 0) {
      _initialSteps = event.steps;
    }
    _steps = event.steps - _initialSteps;
    _calculateDistance();
    _calculateCalories();
    _detectActivity();
  }

  void _onStepCountError(error) {
    _isPedometerAvailable = false;
    _startAccelerometerTracking();
  }

  

  void _calculateDistance() {
    _distanceKm = (_steps * _strideLength) / 1000;
  }

  void _calculateCalories() {
    double met;
    switch (_activityType) {
      case 'running':
        met = 9.8;
        break;
      case 'walking':
        met = 3.5;
        break;
      case 'standing':
        met = 1.3;
        break;
      default:
        met = 1.0;
    }
    
    double hours = _durationMinutes / 60.0;
    _calories = met * _weight * hours;
  }

  void _detectActivity() {
    if (_speed > 6) {
      _activityType = 'running';
    } else if (_speed > 1) {
      _activityType = 'walking';
    } else {
      _activityType = 'standing';
    }
  }

  Future<void> startTracking() async {
    if (_isTracking) return;
    
    _isTracking = true;
    _startTime = DateTime.now();
    _steps = 0;
    _initialSteps = 0;
    _distanceKm = 0;
    _calories = 0;
    _durationMinutes = 0;
    
    if (!_isPedometerAvailable) {
      _startAccelerometerTracking();
    }

    _activityTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _durationMinutes = DateTime.now().difference(_startTime).inMinutes;
      _calculateCalories();
    });
  }

  void stopTracking() {
    _isTracking = false;
    _activityTimer?.cancel();
    _activityTimer = null;
  }

  Future<Position> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  ActivityData getCurrentData() {
    return ActivityData(
      steps: _steps,
      distanceKm: _distanceKm,
      calories: _calories,
      activityType: _activityType,
      speed: _speed,
      durationMinutes: _durationMinutes,
    );
  }

  Map<String, dynamic> getActivityStats() {
    return {
      'steps': _steps,
      'distance': _distanceKm,
      'calories': _calories,
      'activityType': _activityType,
      'speed': _speed,
      'duration': _durationMinutes,
    };
  }

  void dispose() {
    stopTracking();
    _stepSubscription?.cancel();
    _saveTimer?.cancel();
  }
}

class ActivityStats {
  final int totalSteps;
  final double totalDistance;
  final double totalCalories;
  final int activeMinutes;
  final String dominantActivity;
  final List<ActivityData> history;

  ActivityStats({
    this.totalSteps = 0,
    this.totalDistance = 0,
    this.totalCalories = 0,
    this.activeMinutes = 0,
    this.dominantActivity = 'standing',
    this.history = const [],
  });

  factory ActivityStats.fromJson(Map<String, dynamic> json) {
    return ActivityStats(
      totalSteps: json['totalSteps'] ?? 0,
      totalDistance: (json['totalDistance'] ?? 0).toDouble(),
      totalCalories: (json['totalCalories'] ?? 0).toDouble(),
      activeMinutes: json['activeMinutes'] ?? 0,
      dominantActivity: json['dominantActivity'] ?? 'standing',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSteps': totalSteps,
      'totalDistance': totalDistance,
      'totalCalories': totalCalories,
      'activeMinutes': activeMinutes,
      'dominantActivity': dominantActivity,
    };
  }
}
