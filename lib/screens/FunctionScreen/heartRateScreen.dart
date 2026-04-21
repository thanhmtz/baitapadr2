import 'dart:async';
import 'package:camera/camera.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../components/resusableCard.dart';
import '../../components/buttonButton.dart';
import '../../components/constants.dart';
import '../../db/hr_databaseProvider.dart';
import '../../models/hrDBModel.dart';
import '../../localization/appLocalization.dart';
import '../../services/heart_rate_service.dart';
import '../ResultScreen/hrResultScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HeartRate extends StatefulWidget {
  @override
  _HeartRateState createState() => _HeartRateState();
}

class _HeartRateState extends State<HeartRate> {
  final HeartRateService _heartRateService = HeartRateService();

  CameraController _cameraController;
  List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool _hasPermission = false;

  HeartRateMeasurementState _state = HeartRateMeasurementState.idle;
  int _measuredHR = 0;
  List<double> _displayValues = [];
  Timer _measurementTimer;
  int _currentSeconds = 0;
  String _errorMessage = '';
  bool _isDisposed = false;
  bool _isStreaming = false;
  bool _isStopping = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // ─── Camera Init ────────────────────────────────────────────────────────────

  Future<void> _initializeCamera() async {
    if (!mounted) return;
    setState(() {
      _state = HeartRateMeasurementState.initializing;
    });

    try {
      _cameras = await availableCameras();

      CameraDescription backCamera;
      for (var camera in _cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          backCamera = camera;
          break;
        }
      }
      backCamera ??= _cameras.isNotEmpty ? _cameras[0] : null;

      if (backCamera == null) {
        throw HeartRateException('No camera available', 'NO_CAMERA');
      }

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.low,
        enableAudio: false,
      );

      await _cameraController.initialize();

      if (mounted && !_isDisposed) {
        setState(() {
          _isCameraInitialized = true;
          _hasPermission = true;
          _state = HeartRateMeasurementState.waitingForFinger;
        });
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      if (e is CameraException) {
        if (e.code == 'CameraAccessDenied') {
          _handleCameraError(
              HeartRateException('Camera permission denied', 'PERMISSION_DENIED'));
        } else {
          _handleCameraError(HeartRateException(
              e.description ?? 'Camera error', 'CAMERA_ERROR'));
        }
      } else if (e is HeartRateException) {
        _handleCameraError(e);
      } else {
        setState(() {
          _state = HeartRateMeasurementState.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _handleCameraError(HeartRateException e) {
    if (!mounted || _isDisposed) return;
    setState(() {
      _state = HeartRateMeasurementState.error;
      if (e.code == 'PERMISSION_DENIED') {
        _errorMessage = 'Camera permission denied';
      } else if (e.code == 'NO_CAMERA') {
        _errorMessage = 'No camera available';
      } else {
        _errorMessage = 'Camera error: ${e.message}';
      }
    });
  }

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _isDisposed = true;

    _measurementTimer?.cancel();
    _measurementTimer = null;

    // Synchronously mark streaming as stopped so in-flight callbacks bail out
    _isStreaming = false;

    if (_cameraController != null) {
      final ctrl = _cameraController;
      _cameraController = null;

      if (ctrl.value.isInitialized) {
        try {
          if (ctrl.value.isStreamingImages) {
            ctrl.stopImageStream();
          }
        } catch (_) {}
        ctrl.dispose();
      }
    }

    super.dispose();
  }

  // ─── Measurement Control ─────────────────────────────────────────────────────

  void _startMeasurement() {
    if (!_isCameraInitialized) return;
    if (_cameraController == null || !_cameraController.value.isInitialized) return;
    if (_isStreaming || _isStopping) return;

    _heartRateService.reset();
    _displayValues = [];
    _measuredHR = 0;
    _currentSeconds = 0;
    _errorMessage = '';

    // Set _isStreaming BEFORE calling startImageStream to block re-entry
    setState(() {
      _isStreaming = true;
      _state = HeartRateMeasurementState.measuring;
    });

    _cameraController.startImageStream((CameraImage image) {
      if (_isDisposed || !_isStreaming) return;
      if (_state != HeartRateMeasurementState.measuring) return;

      final int currentTime = DateTime.now().millisecondsSinceEpoch;
      if (!_heartRateService.shouldProcessFrame(currentTime)) return;

      _processImage(image);
    }).catchError((Object e) {
      if (!_isDisposed && mounted) {
        setState(() {
          _isStreaming = false;
          _state = HeartRateMeasurementState.error;
          _errorMessage = 'Camera stream error: ${e.toString()}';
        });
      }
    });

    _measurementTimer?.cancel();
    _measurementTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed || !mounted) {
        timer.cancel();
        return;
      }
      if (_state != HeartRateMeasurementState.measuring) {
        timer.cancel();
        return;
      }

      _currentSeconds++;

      if (_currentSeconds >= 20) {
        timer.cancel();
        _completeMeasurement();
      } else {
        setState(() {});
      }
    });
  }

  void _stopMeasurement() {
    _measurementTimer?.cancel();
    _measurementTimer = null;

    if (mounted && !_isDisposed) {
      setState(() {
        _state = HeartRateMeasurementState.waitingForFinger;
        _currentSeconds = 0;
        _displayValues = [];
      });
    }

    _safeStopStream();
  }

  Future<void> _safeStopStream() async {
    if (_isStopping || !_isStreaming) return;
    if (_cameraController == null || !_cameraController.value.isInitialized) {
      _isStreaming = false;
      return;
    }

    _isStopping = true;

    try {
      // Give any in-flight frame callbacks time to finish
      await Future.delayed(const Duration(milliseconds: 100));

      if (!_isDisposed &&
          _cameraController != null &&
          _cameraController.value.isInitialized &&
          _cameraController.value.isStreamingImages) {
        await _cameraController.stopImageStream();
      }
    } catch (e) {
      debugPrint('stopImageStream error (safe to ignore): $e');
    } finally {
      _isStreaming = false;
      _isStopping = false;
    }
  }

  Future<void> _completeMeasurement() async {
    if (_isDisposed) return;

    // Stop stream first, THEN process result
    await _safeStopStream();

    if (_isDisposed || !mounted) return;

    setState(() {
      _state = HeartRateMeasurementState.processing;
    });

    final result = _heartRateService.calculateHeartRate();

    if (_isDisposed || !mounted) return;

    setState(() {
      if (result.isValid) {
        _measuredHR = result.bpm;
        _state = HeartRateMeasurementState.completed;
      } else {
        _errorMessage = result.errorMessage;
        _state = HeartRateMeasurementState.error;
      }
    });
  }

  // ─── Image Processing ────────────────────────────────────────────────────────

  void _processImage(CameraImage image) {
    if (_isDisposed) return;
    if (image.planes.isEmpty) return;

    final plane = image.planes[0];
    final int totalPixels = plane.bytesPerRow * image.height;
    final List<int> pixelData = plane.bytes;

    int redSum = 0;
    int pixelCount = 0;

    for (int i = 0; i < totalPixels; i += 4) {
      if (i + 2 < pixelData.length) {
        redSum += pixelData[i + 2];
        pixelCount++;
      }
    }

    if (pixelCount == 0) return;

    final double avgRed = redSum / pixelCount;
    _heartRateService.addSample(avgRed);

    if (!_heartRateService.isFingerDetected()) {
      if (_state == HeartRateMeasurementState.measuring &&
          !_isDisposed &&
          mounted) {
        setState(() {
          _state = HeartRateMeasurementState.waitingForFinger;
        });
      }
    } else if (_state == HeartRateMeasurementState.waitingForFinger &&
        !_isDisposed &&
        mounted) {
      setState(() {
        _state = HeartRateMeasurementState.measuring;
      });
    }

    final List<double> buffer = _heartRateService.getSignalBuffer();
    if (!_isDisposed && buffer.length > 1 && mounted) {
      setState(() {
        _displayValues =
            buffer.sublist(buffer.length > 50 ? buffer.length - 50 : 0);
      });
    }
  }

  // ─── Save ────────────────────────────────────────────────────────────────────

  Future<void> _saveHeartRate() async {
    if (_measuredHR < 30 || _measuredHR > 220) return;

    final bool confirmed = await _showSaveConfirmation();
    if (!confirmed) return;

    final date = DateTime.now().toLocal();
    final String time =
        "${date.year.toString()}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    final HeartRateDB heartRateDB = HeartRateDB(hr: _measuredHR, date: time);
    await HeartRateDataBaseProvider.db.insert(heartRateDB);

    if (mounted && !_isDisposed) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => HRResultScreen(hr: _measuredHR),
        ),
      );
    }
  }

  Future<bool> _showSaveConfirmation() async {
    return await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
            AppLocalization.of(context).translate('save_record') ??
                'Save Heart Rate'),
        content: Text('Save measurement of $_measuredHR BPM?'),
        actions: <Widget>[
          CupertinoDialogAction(
            child: Text(
                AppLocalization.of(context).translate('cancel') ??
                    'Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(
                AppLocalization.of(context).translate('save') ?? 'Save'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ) ??
        false;
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

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
            const Icon(Icons.favorite, color: CupertinoColors.systemRed, size: 24),
            const SizedBox(width: 8),
            Text(
              AppLocalization.of(context).translate('heart_rate_monitor') ??
                  'Heart Rate Monitor',
              style: const TextStyle(color: CupertinoColors.white, fontSize: 18),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _buildFingerGuide(),
            _buildCameraPreview(),
            _buildBPMDisplay(),
            _buildPPGGraph(),
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  // ─── Widgets ─────────────────────────────────────────────────────────────────

  Widget _buildFingerGuide() {
    if (_state == HeartRateMeasurementState.measuring ||
        _state == HeartRateMeasurementState.completed) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.touch_app,
              color: CupertinoColors.systemRed,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppLocalization.of(context).translate('place_finger') ??
                      'Place your finger on the camera',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalization.of(context).translate('keep_steady') ??
                      'Keep your finger steady for 20 seconds',
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized ||
        _cameraController == null ||
        _state == HeartRateMeasurementState.completed) {
      return const SizedBox.shrink();
    }

    final bool fingerDetected = _heartRateService.isFingerDetected();

    return Container(
      height: 100,
      width: 100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: fingerDetected
              ? CupertinoColors.systemGreen
              : CupertinoColors.systemGrey,
          width: 3,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(47),
        child: CameraPreview(_cameraController),
      ),
    );
  }

  Widget _buildBPMDisplay() {
    Color bpmColor;
    String bpmStatus;

    switch (_state) {
      case HeartRateMeasurementState.completed:
        if (_measuredHR > 0 && _measuredHR < 60) {
          bpmColor = CupertinoColors.systemBlue;
          bpmStatus = AppLocalization.of(context).translate('low') ?? 'Low';
        } else if (_measuredHR >= 60 && _measuredHR <= 100) {
          bpmColor = CupertinoColors.systemGreen;
          bpmStatus =
              AppLocalization.of(context).translate('normal') ?? 'Normal';
        } else if (_measuredHR > 100 && _measuredHR <= 120) {
          bpmColor = CupertinoColors.systemOrange;
          bpmStatus =
              AppLocalization.of(context).translate('elevated') ?? 'Elevated';
        } else if (_measuredHR > 120) {
          bpmColor = CupertinoColors.systemRed;
          bpmStatus =
              AppLocalization.of(context).translate('high') ?? 'High';
        } else {
          bpmColor = CupertinoColors.systemGrey;
          bpmStatus = '--';
        }
        break;
      case HeartRateMeasurementState.waitingForFinger:
        bpmColor = CupertinoColors.systemYellow;
        bpmStatus =
            AppLocalization.of(context).translate('place_finger') ??
                'Place finger';
        break;
      case HeartRateMeasurementState.measuring:
        bpmColor = CupertinoColors.systemRed;
        bpmStatus =
            AppLocalization.of(context).translate('measuring') ?? 'Measuring...';
        break;
      case HeartRateMeasurementState.processing:
        bpmColor = CupertinoColors.systemOrange;
        bpmStatus =
            AppLocalization.of(context).translate('processing') ?? 'Processing...';
        break;
      case HeartRateMeasurementState.error:
        bpmColor = CupertinoColors.systemRed;
        bpmStatus = _errorMessage.isNotEmpty ? _errorMessage : 'Error';
        break;
      default:
        bpmColor = CupertinoColors.systemGrey;
        bpmStatus =
            AppLocalization.of(context).translate('ready') ?? 'Ready';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: <Widget>[
          Text(
            _state == HeartRateMeasurementState.completed
                ? _measuredHR.toString()
                : '--',
            style: TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: bpmColor,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'BPM',
                style: TextStyle(
                  fontSize: 24,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              if (_state == HeartRateMeasurementState.measuring) ...[
                const SizedBox(width: 16),
                Text(
                  '${_currentSeconds}s / 20s',
                  style: const TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: bpmColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              bpmStatus,
              style: TextStyle(
                color: bpmColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPPGGraph() {
    if (_state != HeartRateMeasurementState.measuring ||
        _displayValues.isEmpty) {
      return Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            AppLocalization.of(context).translate('ppg_signal') ?? 'PPG Signal',
            style: const TextStyle(color: CupertinoColors.systemGrey),
          ),
        ),
      );
    }

    final List<FlSpot> spots = List.generate(
      _displayValues.length,
          (i) => FlSpot(i.toDouble(), _displayValues[i]),
    );

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(right: 16, top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              colors: [CupertinoColors.systemRed],
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                colors: [CupertinoColors.systemRed.withOpacity(0.2)],
              ),
            ),
          ],
          lineTouchData: LineTouchData(enabled: false),
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          if (_state == HeartRateMeasurementState.measuring)
            _buildButton(
              icon: Icons.stop,
              label: AppLocalization.of(context).translate('stop') ?? 'Stop',
              color: CupertinoColors.systemRed,
              onPressed: _stopMeasurement,
            )
          else if (_state == HeartRateMeasurementState.completed) ...[
            _buildButton(
              icon: Icons.save,
              label: AppLocalization.of(context).translate('save') ?? 'Save',
              color: CupertinoColors.systemGreen,
              onPressed: _saveHeartRate,
            ),
            _buildButton(
              icon: Icons.refresh,
              label:
              AppLocalization.of(context).translate('reset') ?? 'Reset',
              color: CupertinoColors.systemBlue,
              onPressed: () {
                _heartRateService.reset();
                if (mounted) {
                  setState(() {
                    _state = HeartRateMeasurementState.waitingForFinger;
                    _measuredHR = 0;
                    _displayValues = [];
                    _currentSeconds = 0;
                    _errorMessage = '';
                  });
                }
              },
            ),
          ] else if (_state == HeartRateMeasurementState.error) ...[
            _buildButton(
              icon: Icons.refresh,
              label:
              AppLocalization.of(context).translate('retry') ?? 'Retry',
              color: CupertinoColors.systemOrange,
              onPressed: () {
                _heartRateService.reset();
                if (mounted) {
                  setState(() {
                    _state = HeartRateMeasurementState.waitingForFinger;
                    _measuredHR = 0;
                    _displayValues = [];
                    _currentSeconds = 0;
                    _errorMessage = '';
                    _isStreaming = false;
                  });
                }
              },
            ),
          ] else
            _buildButton(
              icon: Icons.play_arrow,
              label:
              AppLocalization.of(context).translate('start') ?? 'Start',
              color: CupertinoColors.systemGreen,
              onPressed: _isCameraInitialized ? _startMeasurement : null,
            ),
        ],
      ),
    );
  }

  Widget _buildButton({
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: onPressed != null ? color : CupertinoColors.systemGrey,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: CupertinoColors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}