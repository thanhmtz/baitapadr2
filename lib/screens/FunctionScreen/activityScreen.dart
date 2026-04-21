import 'dart:async';
import 'package:camera/camera.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../components/resusableCard.dart';
import '../../components/buttonButton.dart';
import '../../components/constants.dart';
import '../../db/hr_databaseProvider.dart';
import '../../models/hrDBModel.dart';
import '../../localization/appLocalization.dart';
import '../../services/activity_service.dart';
import '../ResultScreen/hrResultScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ActivityScreen extends StatefulWidget {
  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final ActivityService _activityService = ActivityService();

  bool _isTracking = false;
  int _steps = 0;
  double _distanceKm = 0;
  double _calories = 0;
  String _activityType = 'standing';
  double _speed = 0;
  int _durationMinutes = 0;
  Timer _updateTimer;

  @override
  void initState() {
    super.initState();
    _initActivity();
  }

  Future<void> _initActivity() async {
    await _activityService.init();
    _activityService.setWeight(70);
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startTracking() {
    setState(() {
      _isTracking = true;
    });

    _activityService.startTracking();

    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final data = _activityService.getCurrentData();
      setState(() {
        _steps = data.steps;
        _distanceKm = data.distanceKm;
        _calories = data.calories;
        _activityType = data.activityType;
        _speed = data.speed;
        _durationMinutes = data.durationMinutes;
      });
    });
  }

  void _stopTracking() {
    _activityService.stopTracking();
    _updateTimer?.cancel();

    setState(() {
      _isTracking = false;
    });
  }

  String _getActivityIcon() {
    switch (_activityType) {
      case 'running':
        return '🏃';
      case 'walking':
        return '🚶';
      default:
        return '🧍';
    }
  }

  String _getActivityText() {
    switch (_activityType) {
      case 'running':
        return 'Đang chạy';
      case 'walking':
        return 'Đang đi bộ';
      default:
        return 'Đứng yên';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.directions_run, color: CupertinoColors.systemOrange, size: 24),
            const SizedBox(width: 8),
            Text(
              'Hoạt động thể chất',
              style: const TextStyle(color: CupertinoColors.white, fontSize: 18),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildActivityCard(),
              const SizedBox(height: 16),
              _buildStatsGrid(),
              const SizedBox(height: 16),
              _buildControlButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            _getActivityIcon(),
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 16),
          Text(
            _getActivityText(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _activityType == 'running'
                  ? CupertinoColors.systemOrange
                  : _activityType == 'walking'
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemGrey,
            ),
          ),
          if (_isTracking) ...[
            const SizedBox(height: 8),
            Text(
              '${_durationMinutes} phút',
              style: const TextStyle(
                fontSize: 18,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.directions_walk,
            value: _steps.toString(),
            label: 'Bước chân',
            color: CupertinoColors.systemBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.straighten,
            value: _distanceKm.toStringAsFixed(2),
            label: 'Km',
            color: CupertinoColors.systemGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    IconData icon,
    String value,
    String label,
    Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton() {
    return GestureDetector(
      onTap: _isTracking ? _stopTracking : _startTracking,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isTracking ? CupertinoColors.systemRed : CupertinoColors.systemGreen,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isTracking ? Icons.stop : Icons.play_arrow,
              color: CupertinoColors.white,
            ),
            const SizedBox(width: 8),
            Text(
              _isTracking ? 'Dừng' : 'Bắt đầu',
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}