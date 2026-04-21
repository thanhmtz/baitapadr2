import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SleepAnalysisResult {
  final int quality;
  final String feedback;
  final String suggestions;
  final bool isFromLocal;

  SleepAnalysisResult({
    this.quality,
    this.feedback,
    this.suggestions,
    this.isFromLocal = false,
  });
}

class SleepService {
  static const String _baseUrl = 'https://your-sleep-api.com';
  static const String _analyzeEndpoint = '/analyze';

  Future<SleepAnalysisResult> analyzeSleep({
    DateTime bedtime,
    DateTime wakeTime,
  }) async {
    final double hours = _calculateSleepDuration(bedtime, wakeTime);
    
    try {
      final response = await _callApi(bedtime, wakeTime, hours);
      return response;
    } on TimeoutException {
      return _getLocalResult(hours, isFromLocal: true, reason: 'timeout');
    } on http.ClientException {
      return _getLocalResult(hours, isFromLocal: true, reason: 'network');
    } catch (e) {
      return _getLocalResult(hours, isFromLocal: true, reason: 'error');
    }
  }

  double _calculateSleepDuration(DateTime sleepTime, DateTime wakeTime) {
    Duration difference = wakeTime.difference(sleepTime);
    if (difference.isNegative) {
      difference = difference + Duration(hours: 24);
    }
    return difference.inMinutes / 60.0;
  }

  Future<SleepAnalysisResult> _callApi(DateTime sleep, DateTime wake, double hours) async {
    final String apiUrl = _baseUrl + _analyzeEndpoint;
    
    final Map<String, dynamic> requestBody = {
      'bedtime': sleep.toIso8601String(),
      'wakeTime': wake.toIso8601String(),
      'duration': hours,
    };
    
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    ).timeout(Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return SleepAnalysisResult(
        quality: data['quality'] as int,
        feedback: data['feedback'] as String,
        suggestions: data['suggestions'] as String,
      );
    } else {
      throw Exception('API request failed with status: ${response.statusCode}');
    }
  }

  SleepAnalysisResult _getLocalResult(double hours, {bool isFromLocal = false, String reason = ''}) {
    final quality = _calculateQuality(hours);
    final feedback = _getFeedback(quality);
    final suggestions = _getSuggestions(hours);
    
    return SleepAnalysisResult(
      quality: quality,
      feedback: feedback,
      suggestions: suggestions,
      isFromLocal: isFromLocal,
    );
  }

  int _calculateQuality(double hours) {
    if (hours < 1) return 0;
    if (hours < 4) return 1;
    if (hours < 6) return 2;
    if (hours >= 7 && hours <= 9) return 4;
    return 3;
  }

  String _getFeedback(int quality) {
    switch (quality) {
      case 0:
        return 'Very Poor';
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Excellent';
      default:
        return 'Unknown';
    }
  }

  String _getSuggestions(double hours) {
    if (hours < 6) {
      return 'Try to get at least 7 hours of sleep. Avoid screens before bed and maintain a consistent sleep schedule.';
    } else if (hours > 9) {
      return 'Oversleeping may reduce energy. Aim for 7-9 hours for optimal health.';
    } else if (hours >= 7 && hours <= 9) {
      return 'Great sleep duration! Maintain your current sleep schedule and avoid caffeine in the evening.';
    }
    return 'Try to maintain a consistent sleep schedule and create a relaxing bedtime routine.';
  }

  bool validateSleepInput(DateTime sleepTime, DateTime wakeTime) {
    final double hours = _calculateSleepDuration(sleepTime, wakeTime);
    return hours > 0 && hours <= 24;
  }
}
