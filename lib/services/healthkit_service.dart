import 'dart:io';

class HealthKitService {
  static final HealthKitService _instance = HealthKitService._internal();
  factory HealthKitService() => _instance;
  HealthKitService._internal();

  bool _isAuthorized = false;

  bool get isAuthorized => _isAuthorized;

  Future<bool> requestPermission() async {
    if (!Platform.isIOS) {
      _isAuthorized = false;
      return false;
    }
    try {
      _isAuthorized = true;
      return true;
    } catch (e) {
      print('HealthKit permission error: $e');
      return false;
    }
  }

  Future<int> getLatestHeartRate() async {
    if (!Platform.isIOS) {
      return -1;
    }
    try {
      if (!_isAuthorized) {
        final granted = await requestPermission();
        if (!granted) return -1;
      }
      return -1;
    } catch (e) {
      print('Error getting heart rate: $e');
      return -1;
    }
  }

  Future<bool> saveHeartRate(int heartRate) async {
    if (!Platform.isIOS) {
      return true;
    }
    try {
      if (!_isAuthorized) {
        final granted = await requestPermission();
        if (!granted) return false;
      }
      return true;
    } catch (e) {
      print('Error saving heart rate: $e');
      return false;
    }
  }
}
