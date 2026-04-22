import 'dart:async';
import 'dart:math';
import '../../services/activity_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ActivityScreen extends StatefulWidget {
  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  final ActivityService _activityService = ActivityService();

  bool _isTracking = false;
  bool _isBackground = false;
  bool _pedometerReady = false;
  int _steps = 0;
  double _distanceKm = 0;
  double _calories = 0;
  double _sessionCalories = 0;
  String _activityType = 'standing';
  double _speed = 0;
  int _durationMinutes = 0;
  int _dailyGoal = 10000;
  Timer _updateTimer;
  String _debugInfo = '';

  AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _initActivity();
  }

  Future<void> _initActivity() async {
    final ready = await _activityService.init();
    _activityService.setWeight(70);
    setState(() {
      _pedometerReady = ready;
      _dailyGoal = _activityService.dailyGoal;
      _debugInfo = ready ? 'Pedometer: OK' : 'Pedometer: Không khả dụng';
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startTracking() {
    setState(() => _isTracking = true);
    _activityService.startTracking();
    if (_activityType == 'running') {
      _animationController.repeat(reverse: true);
    }
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final data = _activityService.getCurrentData();
      final todayStats = _activityService.getTodayStats();
      setState(() {
        _steps = data.steps;
        _distanceKm = data.distanceKm;
        _calories = todayStats['calories'];
        _sessionCalories = data.calories;
        _activityType = data.activityType;
        _speed = data.speed;
        _durationMinutes = data.durationMinutes;
      });
      if (_activityType == 'running' && !_animationController.isAnimating) {
        _animationController.repeat(reverse: true);
      } else if (_activityType != 'running' && _animationController.isAnimating) {
        _animationController.stop();
        _animationController.reset();
      }
    });
  }

  void _stopTracking() async {
    _animationController.stop();
    _animationController.reset();
    _updateTimer?.cancel();
    await _activityService.stopTracking();
    setState(() {
      _isTracking = false;
      _isBackground = false;
    });
    final todayStats = _activityService.getTodayStats();
    setState(() {
      _steps = todayStats['steps'];
      _distanceKm = todayStats['distance'];
      _calories = todayStats['calories'];
      _durationMinutes = 0;
    });
  }

  void _toggleBackground() async {
    if (_isBackground) {
      await _activityService.stopBackgroundTracking();
      setState(() {
        _isBackground = false;
        _isTracking = false;
      });
    } else {
      await _activityService.startBackgroundTracking();
      setState(() {
        _isBackground = true;
        _isTracking = true;
      });
      _animationController.repeat(reverse: true);
    }
  }

  void _showGoalDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        int newGoal = _dailyGoal;
        return CupertinoAlertDialog(
          title: const Text('Đặt mục tiêu'),
          content: Column(
            children: [
              const SizedBox(height: 16),
              CupertinoTextField(
                placeholder: 'Số bước',
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  newGoal = int.tryParse(value) ?? 10000;
                },
                controller: TextEditingController(text: _dailyGoal.toString()),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Lưu'),
              onPressed: () {
                _activityService.setDailyGoal(newGoal);
                setState(() => _dailyGoal = newGoal);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  String _getActivityEmoji() {
    switch (_activityType) {
      case 'running':
        return '🏃';
      case 'walking':
        return '🚶';
      default:
        return '🧍';
    }
  }

  String _getActivityLabel() {
    switch (_activityType) {
      case 'running':
        return 'Đang chạy';
      case 'walking':
        return 'Đang đi bộ';
      default:
        return 'Đứng yên';
    }
  }

  Color _getActivityColor() {
    switch (_activityType) {
      case 'running':
        return const Color(0xFFFF9500);
      case 'walking':
        return const Color(0xFF30D158);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  Widget _buildAnimatedActivityIcon() {
    if (_activityType == 'running' && _isTracking) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, sin(_animationController.value * pi * 4) * 8),
            child: const Text('🏃', style: TextStyle(fontSize: 72)),
          );
        },
      );
    }
    return Text(_getActivityEmoji(), style: const TextStyle(fontSize: 72));
  }

  @override
  Widget build(BuildContext context) {
    final todayStats = _activityService.getTodayStats();
    final goalProgress = (todayStats['goalProgress'] as double).clamp(0.0, 1.0);
    final currentSteps = _isTracking ? _steps : todayStats['steps'] as int;
    final currentCalories =
    _isTracking ? _sessionCalories : todayStats['calories'] as double;
    final activeMinutes =
    _isTracking ? _durationMinutes : todayStats['activeMinutes'] as int;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.directions_run,
                color: Color(0xFFFF9500), size: 22),
            SizedBox(width: 8),
            Text(
              'Hoạt động thể chất',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.white, size: 22),
            onPressed: _showGoalDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildGoalCard(currentSteps, goalProgress),
              const SizedBox(height: 14),
              _buildActivityCard(),
              const SizedBox(height: 14),
              _buildStatsGrid(currentCalories, activeMinutes),
              const SizedBox(height: 14),
              if (_isTracking) _buildSpeedRow(),
              if (_isTracking) const SizedBox(height: 14),
              _buildPrimaryButton(),
              if (_isTracking) ...[
                const SizedBox(height: 10),
                _buildBackgroundButton(),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Goal Card ──────────────────────────────────────────────────────────────

  Widget _buildGoalCard(int steps, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mục tiêu hôm nay',
                  style: TextStyle(color: Colors.white, fontSize: 15)),
              Text(
                '${_formatNumber(_dailyGoal)} bước',
                style: const TextStyle(
                    color: Color(0xFF8E8E93), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF3A3A3C),
              valueColor: AlwaysStoppedAnimation(
                progress >= 1.0
                    ? const Color(0xFF30D158)
                    : const Color(0xFFFF9500),
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatNumber(steps)} / ${_formatNumber(_dailyGoal)} bước',
                style: const TextStyle(
                    color: Color(0xFF8E8E93), fontSize: 13),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: progress >= 1.0
                      ? const Color(0xFF30D158)
                      : const Color(0xFFFF9500),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Activity Card ──────────────────────────────────────────────────────────

  Widget _buildActivityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildAnimatedActivityIcon(),
          const SizedBox(height: 12),
          Text(
            _getActivityLabel(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: _getActivityColor(),
            ),
          ),
          if (_isTracking) ...[
            const SizedBox(height: 6),
            Text(
              '$_durationMinutes phút',
              style: const TextStyle(
                  fontSize: 15, color: Color(0xFF8E8E93)),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _pedometerReady
                  ? const Color(0xFF1E3A2A)
                  : const Color(0xFF3A1E1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _pedometerReady
                        ? const Color(0xFF30D158)
                        : const Color(0xFFFF3B30),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _debugInfo,
                  style: TextStyle(
                    fontSize: 12,
                    color: _pedometerReady
                        ? const Color(0xFF30D158)
                        : const Color(0xFFFF3B30),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats 2×2 Grid ─────────────────────────────────────────────────────────

  Widget _buildStatsGrid(double calories, int activeMinutes) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _buildStatCard(
          dotColor: const Color(0xFF0A84FF),
          label: 'Bước chân',
          value: _formatNumber(_steps),
          valueColor: const Color(0xFF0A84FF),
        ),
        _buildStatCard(
          dotColor: const Color(0xFF30D158),
          label: 'Khoảng cách',
          value: _distanceKm.toStringAsFixed(2),
          unit: 'km',
          valueColor: const Color(0xFF30D158),
        ),
        _buildStatCard(
          dotColor: const Color(0xFFFF9500),
          label: 'Calo đốt',
          value: calories.toStringAsFixed(0),
          unit: 'kcal',
          valueColor: const Color(0xFFFF9500),
        ),
        _buildStatCard(
          dotColor: const Color(0xFFBF5AF2),
          label: 'Thời gian',
          value: activeMinutes.toString(),
          unit: 'phút',
          valueColor: const Color(0xFFBF5AF2),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    Color dotColor,
    String label,
    String value,
    String unit,
    Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: dotColor),
              ),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFF8E8E93), fontSize: 12)),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 3),
                Text(unit,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF8E8E93))),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Speed Row ──────────────────────────────────────────────────────────────

  Widget _buildSpeedRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tốc độ hiện tại',
                  style: TextStyle(
                      color: Color(0xFF8E8E93), fontSize: 12)),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _speed.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  const Text('km/h',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF8E8E93))),
                ],
              ),
            ],
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2A1A00),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getActivityLabel(),
              style: const TextStyle(
                  color: Color(0xFFFF9500),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── Buttons ────────────────────────────────────────────────────────────────

  Widget _buildPrimaryButton() {
    final isStop = _isTracking;
    return GestureDetector(
      onTap: isStop ? _stopTracking : _startTracking,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isStop
              ? const Color(0xFFFF3B30)
              : const Color(0xFF30D158),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isStop ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              isStop ? 'Dừng lại' : 'Bắt đầu',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundButton() {
    return GestureDetector(
      onTap: _toggleBackground,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _isBackground
                ? const Color(0xFF30D158)
                : const Color(0xFF3A3A3C),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isBackground
                  ? Icons.pause_circle_outline_rounded
                  : Icons.play_circle_outline_rounded,
              color: _isBackground
                  ? const Color(0xFF30D158)
                  : const Color(0xFF8E8E93),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _isBackground ? 'Background: Bật' : 'Background: Tắt',
              style: TextStyle(
                color: _isBackground
                    ? const Color(0xFF30D158)
                    : const Color(0xFF8E8E93),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatNumber(int n) {
    if (n >= 1000) {
      return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
      );
    }
    return n.toString();
  }
}