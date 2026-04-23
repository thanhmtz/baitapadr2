// @dart=2.10

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../../services/heart_rate_service.dart';
import '../../db/hr_databaseProvider.dart';
import '../../models/hrDBModel.dart';
import '../ResultScreen/hrResultScreen.dart';

const Color _kWhite = Colors.white;
const Color _kWhite70 = Color(0xB3FFFFFF);
const Color _kWhite40 = Color(0x66FFFFFF);
const Color _kPanel = Color(0x7A120000);
const Color _kPanelBorder = Color(0x33FFFFFF);

enum _MeasureStage {
  initializing,
  idle,
  detectingFinger,
  countdown,
  collecting,
  stable,
  error,
}

class HeartRateScreen extends StatefulWidget {
  @override
  _HeartRateScreenState createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen>
    with TickerProviderStateMixin {
  static const int _engineTickMs = 100;
  static const int _countdownTotalMs = 3000;
  static const int _minFingerStableMs = 500;
  static const int _fingerLostToleranceMs = 900;
  static const int _softLossKeepAliveMs = 2200;
  static const int _liveEstimateEveryMs = 700;
  static const int _minCollectionBeforeShowBpmMs = 3500;
  static const int _frameGateMs = 33;

  static const double _startPlacementThreshold = 0.40;
  static const double _keepPlacementThreshold = 0.34;
  static const double _minQualityToShowBpm = 0.34;

  static const int _minValidBpm = 40;
  static const int _maxValidBpm = 180;

  final HeartRateService _heartRateService = HeartRateService();

  CameraController _cameraController;
  List<CameraDescription> _cameras = <CameraDescription>[];

  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isDisposed = false;
  bool _isStreaming = false;
  bool _isStopping = false;

  _MeasureStage _stage = _MeasureStage.initializing;

  Timer _engineTimer;

  AnimationController _heartBeatController;
  Animation<double> _heartBeatAnim;
  AnimationController _scanController;
  Animation<double> _scanAnim;
  AnimationController _countdownController;
  Animation<double> _countdownScaleAnim;
  Animation<double> _countdownFadeAnim;

  int _liveBpm = 0;
  int _countdownRemainingMs = _countdownTotalMs;
  int _lastFrameProcessedMs = 0;
  int _fingerCandidateSinceMs = 0;
  int _fingerLostSinceMs = 0;
  int _countdownStartedAtMs = 0;
  int _signalStartedAtMs = 0;
  int _collectionStartedAtMs = 0;
  int _lastLiveEstimateAtMs = 0;

  bool _fingerCandidate = false;
  bool _fingerStable = false;
  bool _showLiveBpm = false;

  double _positionScore = 0.0;
  double _rawPlacementScore = 0.0;
  double _liveQuality = 0.0;

  String _errorMessage = '';
  List<double> _displayValues = <double>[];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeCamera();
  }

  void _initAnimations() {
    _heartBeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _heartBeatAnim = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.0, end: 1.16),
          weight: 34,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.16, end: 1.0),
          weight: 66,
        ),
      ],
    ).animate(CurvedAnimation(
      parent: _heartBeatController,
      curve: Curves.easeOut,
    ));

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _scanAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_scanController);

    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    _countdownScaleAnim = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.45, end: 1.14),
          weight: 45,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.14, end: 1.0),
          weight: 55,
        ),
      ],
    ).animate(CurvedAnimation(
      parent: _countdownController,
      curve: Curves.easeOut,
    ));
    _countdownFadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _countdownController,
        curve: const Interval(0.72, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _engineTimer?.cancel();
    _heartBeatController.dispose();
    _scanController.dispose();
    _countdownController.dispose();

    _turnOffFlash();

    final CameraController ctrl = _cameraController;
    _cameraController = null;
    _isStreaming = false;
    if (ctrl != null) {
      try {
        if (ctrl.value.isInitialized && ctrl.value.isStreamingImages) {
          ctrl.stopImageStream();
        }
      } catch (_) {}
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (_isDisposed || !mounted) return;

    try {
      _stage = _MeasureStage.initializing;
      _cameras = await availableCameras();

      CameraDescription back;
      for (final CameraDescription c in _cameras) {
        if (c.lensDirection == CameraLensDirection.back) {
          back = c;
          break;
        }
      }
      if (back == null && _cameras.isNotEmpty) {
        back = _cameras.first;
      }
      if (back == null) throw Exception('No camera available');

      if (_cameraController != null) {
        try {
          if (_cameraController.value.isInitialized &&
              _cameraController.value.isStreamingImages) {
            await _cameraController.stopImageStream();
          }
        } catch (_) {}
        await _cameraController.dispose();
      }

      _cameraController = CameraController(
        back,
        ResolutionPreset.low,
        enableAudio: false,
      );

      await _cameraController.initialize();
      await _cameraController.setFlashMode(FlashMode.torch);

      if (_isDisposed || !mounted) return;

      _isFlashOn = true;
      _isCameraInitialized = true;
      _resetMeasurementFlow(clearError: true);
      _stage = _MeasureStage.idle;
      setState(() {});

      await _startImageMonitoring();
      _startEngineLoop();
    } catch (e) {
      if (_isDisposed || !mounted) return;
      setState(() {
        _stage = _MeasureStage.error;
        _errorMessage = e.toString();
      });
    }
  }

  void _resetMeasurementFlow({bool clearError = false}) {
    _heartRateService.reset();
    _liveBpm = 0;
    _showLiveBpm = false;
    _countdownRemainingMs = _countdownTotalMs;
    _lastFrameProcessedMs = 0;
    _fingerCandidateSinceMs = 0;
    _fingerLostSinceMs = 0;
    _countdownStartedAtMs = 0;
    _signalStartedAtMs = 0;
    _collectionStartedAtMs = 0;
    _lastLiveEstimateAtMs = 0;
    _fingerCandidate = false;
    _fingerStable = false;
    _positionScore = 0.0;
    _rawPlacementScore = 0.0;
    _liveQuality = 0.0;
    _displayValues = <double>[];
    _heartBeatController.stop();
    _heartBeatController.reset();
    _countdownController.reset();
    if (clearError) {
      _errorMessage = '';
    }
  }

  void _syncHeartbeatAnimation() {
    int periodMs = 820;
    if (_liveBpm >= _minValidBpm && _liveBpm <= _maxValidBpm) {
      final int computed = (60000 / _liveBpm).round();
      periodMs = computed.clamp(380, 1400).toInt();
    }

    if (_heartBeatController.duration == null ||
        _heartBeatController.duration.inMilliseconds != periodMs) {
      final bool wasAnimating = _heartBeatController.isAnimating;
      _heartBeatController.duration = Duration(milliseconds: periodMs);
      if (wasAnimating ||
          _stage == _MeasureStage.collecting ||
          _stage == _MeasureStage.stable) {
        _heartBeatController.repeat();
      }
    }
  }

  Future<void> _startImageMonitoring() async {
    if (_cameraController == null || !_cameraController.value.isInitialized) {
      return;
    }
    if (_isStreaming) return;

    _isStreaming = true;
    try {
      await _cameraController.startImageStream((CameraImage image) {
        if (_isDisposed || !_isStreaming) return;
        if (_stage == _MeasureStage.error) {
          return;
        }

        final int now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastFrameProcessedMs < _frameGateMs) return;
        _lastFrameProcessedMs = now;
        _processImage(image, now);
      });
    } catch (e) {
      _isStreaming = false;
      if (_isDisposed || !mounted) return;
      setState(() {
        _stage = _MeasureStage.error;
        _errorMessage = 'Camera error: $e';
      });
    }
  }

  Future<void> _safeStopStream() async {
    if (_isStopping || !_isStreaming) return;
    if (_cameraController == null || !_cameraController.value.isInitialized) {
      _isStreaming = false;
      return;
    }

    _isStopping = true;
    try {
      if (_cameraController.value.isStreamingImages) {
        await _cameraController.stopImageStream();
      }
    } catch (_) {}
    _isStreaming = false;
    _isStopping = false;
  }

  Future<void> _turnOffFlash() async {
    try {
      if (_cameraController != null && _cameraController.value.isInitialized) {
        await _cameraController.setFlashMode(FlashMode.off);
      }
    } catch (_) {}
    _isFlashOn = false;
  }

  void _startEngineLoop() {
    _engineTimer?.cancel();
    _engineTimer = Timer.periodic(
      const Duration(milliseconds: _engineTickMs),
          (Timer timer) {
        if (_isDisposed || !mounted) {
          timer.cancel();
          return;
        }
        if (_stage == _MeasureStage.error || !_isCameraInitialized) {
          return;
        }

        final int now = DateTime.now().millisecondsSinceEpoch;

        if (_stage == _MeasureStage.countdown) {
          _tickCountdown(now);
        }

        if (_stage == _MeasureStage.collecting || _stage == _MeasureStage.stable) {
          if (_lastLiveEstimateAtMs == 0 ||
              now - _lastLiveEstimateAtMs >= _liveEstimateEveryMs) {
            _lastLiveEstimateAtMs = now;
            _updateLiveBpm(now);
          }
        }

        if (mounted) setState(() {});
      },
    );
  }

  void _tickCountdown(int now) {
    final int oldBucket = _countdownDisplay;
    final int remaining = _countdownTotalMs - (now - _countdownStartedAtMs);
    _countdownRemainingMs = remaining < 0 ? 0 : remaining;
    final int newBucket = _countdownDisplay;

    if (newBucket != oldBucket ||
        _countdownRemainingMs == _countdownTotalMs - _engineTickMs) {
      _countdownController.forward(from: 0.0);
    }

    if (_countdownRemainingMs == 0) {
      _startCollecting(now);
    }
  }

  void _startCollecting(int now) {
    if (_signalStartedAtMs <= 0) {
      _signalStartedAtMs = now;
      _heartRateService.reset();
      _displayValues = <double>[];
      _liveQuality = 0.0;
      _liveBpm = 0;
      _showLiveBpm = false;
    }

    if (_collectionStartedAtMs <= 0) {
      _collectionStartedAtMs = now;
    }

    _lastLiveEstimateAtMs = now;
    _stage = _MeasureStage.collecting;
    _syncHeartbeatAnimation();
    _heartBeatController.repeat();
  }

  void _resumeCollecting(int now) {
    if (_collectionStartedAtMs <= 0) {
      _collectionStartedAtMs = now;
    }
    _lastLiveEstimateAtMs = now;
    _stage = _showLiveBpm ? _MeasureStage.stable : _MeasureStage.collecting;
    _syncHeartbeatAnimation();
    _heartBeatController.repeat();
  }

  void _processImage(CameraImage image, int now) {
    if (_isDisposed || image == null || image.planes.isEmpty) return;

    final _FrameAverages frame = _extractFrameAverages(image);
    if (frame == null) return;

    final double placement = _computePlacementScore(
      avgRed: frame.avgRed,
      avgGreen: frame.avgGreen,
    );
    _rawPlacementScore = placement;

    if (_positionScore <= 0.0) {
      _positionScore = placement;
    } else if (placement >= _positionScore) {
      _positionScore = (_positionScore * 0.68 + placement * 0.32)
          .clamp(0.0, 1.0)
          .toDouble();
    } else {
      _positionScore = (_positionScore * 0.88 + placement * 0.12)
          .clamp(0.0, 1.0)
          .toDouble();
    }

    final bool placementOk = _isPlacementOkay(
      avgRed: frame.avgRed,
      avgGreen: frame.avgGreen,
      score: _positionScore,
      previousAligned: _fingerStable,
    );

    if (!placementOk) {
      if (_fingerLostSinceMs == 0) {
        _fingerLostSinceMs = now;
      }
      if (now - _fingerLostSinceMs >= _fingerLostToleranceMs) {
        _handleFingerLost(now);
      }
      return;
    }

    _fingerLostSinceMs = 0;

    if (!_fingerCandidate) {
      _fingerCandidate = true;
      _fingerCandidateSinceMs = now;
    }

    final int stableHeldMs = now - _fingerCandidateSinceMs;
    _fingerStable = stableHeldMs >= _minFingerStableMs;

    if (!_fingerStable) {
      if (_stage == _MeasureStage.idle || _stage == _MeasureStage.detectingFinger) {
        _stage = _MeasureStage.detectingFinger;
      }
      return;
    }

    if (_stage == _MeasureStage.idle || _stage == _MeasureStage.detectingFinger) {
      final bool canFastResume =
          _signalStartedAtMs > 0 && _heartRateService.sampleCount >= 45;

      if (canFastResume) {
        _resumeCollecting(now);
      } else {
        _stage = _MeasureStage.countdown;
        _countdownStartedAtMs = now;
        _countdownRemainingMs = _countdownTotalMs;
        if (_signalStartedAtMs <= 0) {
          _signalStartedAtMs = now;
          _heartRateService.reset();
          _displayValues = <double>[];
          _liveQuality = 0.0;
          _liveBpm = 0;
          _showLiveBpm = false;
        }
        _countdownController.forward(from: 0.0);
      }
    }

    if ((_stage == _MeasureStage.countdown ||
        _stage == _MeasureStage.collecting ||
        _stage == _MeasureStage.stable) &&
        _signalStartedAtMs > 0) {
      final int timestamp = now - _signalStartedAtMs;
      if (timestamp >= 0) {
        _heartRateService.addSample(
          frame.avgRed,
          timestamp: timestamp,
          greenValue: frame.avgGreen,
          redValue: frame.avgRed,
        );
        _updateWave();
      }
    }
  }

  void _handleFingerLost(int now) {
    final bool hasBufferedSignal =
        _signalStartedAtMs > 0 && _heartRateService.sampleCount >= 45;
    final bool canKeepWarm =
        hasBufferedSignal &&
            _fingerLostSinceMs > 0 &&
            (now - _fingerLostSinceMs) < _softLossKeepAliveMs;

    _fingerCandidate = false;
    _fingerStable = false;
    _fingerCandidateSinceMs = 0;
    _countdownStartedAtMs = 0;
    _countdownRemainingMs = _countdownTotalMs;
    _heartBeatController.stop();
    _countdownController.reset();

    if (canKeepWarm) {
      _stage = _MeasureStage.detectingFinger;
      if (mounted) {
        setState(() {});
      }
      return;
    }

    _heartRateService.reset();
    _liveBpm = 0;
    _showLiveBpm = false;
    _liveQuality = 0.0;
    _displayValues = <double>[];
    _fingerLostSinceMs = 0;
    _signalStartedAtMs = 0;
    _collectionStartedAtMs = 0;
    _lastLiveEstimateAtMs = 0;
    _positionScore = 0.0;
    _rawPlacementScore = 0.0;
    _heartBeatController.reset();

    _stage = _MeasureStage.detectingFinger;
    if (mounted) {
      setState(() {});
    }
  }

  void _updateWave() {
    final List<double> buf = _heartRateService.getFilteredBuffer();
    if (buf.isEmpty) {
      _displayValues = <double>[];
      return;
    }
    final int start = buf.length > 120 ? buf.length - 120 : 0;
    _displayValues = buf.sublist(start);
  }

  void _updateLiveBpm(int now) {
    if (_signalStartedAtMs <= 0) return;

    final int collectedMs = now - _signalStartedAtMs;
    _liveQuality = _heartRateService.signalQuality;
    if (collectedMs < _minCollectionBeforeShowBpmMs) {
      return;
    }

    final HeartRateResult result = _heartRateService.calculateHeartRate();
    _liveQuality = result.signalQuality;

    if (!result.isValid) {
      return;
    }
    if (result.bpm < _minValidBpm || result.bpm > _maxValidBpm) {
      return;
    }
    if (result.signalQuality < _minQualityToShowBpm) {
      return;
    }
    if (result.peakCount < 4) {
      return;
    }

    if (_liveBpm <= 0) {
      _liveBpm = result.bpm;
    } else {
      _liveBpm = (_liveBpm * 0.82 + result.bpm * 0.18).round();
    }

    _showLiveBpm = true;
    _stage = _MeasureStage.stable;
    _syncHeartbeatAnimation();
  }

  _FrameAverages _extractFrameAverages(CameraImage image) {
    try {
      double avgR = 0.0;
      double avgG = 0.0;

      if (image.planes.length == 1) {
        final Uint8List bytes = image.planes[0].bytes;
        final int bpr = image.planes[0].bytesPerRow;
        final int h = image.height;
        final int w = image.width;
        final int top = h ~/ 3;
        final int bottom = h - top;
        final int left = w ~/ 3;
        final int right = w - left;

        double rSum = 0.0;
        double gSum = 0.0;
        int count = 0;

        for (int row = top; row < bottom; row++) {
          final int rowStart = row * bpr;
          for (int col = left * 4; col < right * 4; col += 4) {
            final int idx = rowStart + col;
            if (idx + 2 >= bytes.length) continue;
            gSum += bytes[idx + 1];
            rSum += bytes[idx + 2];
            count++;
          }
        }

        if (count == 0) return null;
        avgR = rSum / count;
        avgG = gSum / count;
      } else if (image.planes.length >= 3) {
        final Uint8List yBytes = image.planes[0].bytes;
        final Uint8List vBytes = image.planes[2].bytes;
        final int yBpr = image.planes[0].bytesPerRow;
        final int vBpr = image.planes[2].bytesPerRow;
        final int h = image.height;
        final int w = image.width;

        final int top = h ~/ 3;
        final int bottom = h - top;
        final int left = w ~/ 3;
        final int right = w - left;

        double ySum = 0.0;
        int yCount = 0;
        for (int row = top; row < bottom; row++) {
          final int rowStart = row * yBpr;
          for (int col = left; col < right; col++) {
            final int idx = rowStart + col;
            if (idx >= 0 && idx < yBytes.length) {
              ySum += yBytes[idx] & 0xFF;
              yCount++;
            }
          }
        }
        if (yCount == 0) return null;

        final int uvTop = top ~/ 2;
        final int uvBottom = max(uvTop + 1, bottom ~/ 2);
        final int uvLeft = left ~/ 2;
        final int uvRight = max(uvLeft + 1, right ~/ 2);

        double vSum = 0.0;
        int vCount = 0;
        for (int row = uvTop; row < uvBottom; row++) {
          final int rowStart = row * vBpr;
          for (int col = uvLeft; col < uvRight; col++) {
            final int idx = rowStart + col;
            if (idx >= 0 && idx < vBytes.length) {
              vSum += vBytes[idx] & 0xFF;
              vCount++;
            }
          }
        }

        final double avgY = ySum / yCount;
        final double avgV = vCount > 0 ? vSum / vCount : 128.0;
        avgR = (avgY + 1.402 * (avgV - 128.0)).clamp(0.0, 255.0).toDouble();
        avgG = avgY.clamp(0.0, 255.0).toDouble();
      } else {
        final Uint8List bytes = image.planes[0].bytes;
        double sum = 0.0;
        int count = 0;
        for (int i = 0; i < bytes.length; i++) {
          sum += bytes[i] & 0xFF;
          count++;
        }
        if (count == 0) return null;
        avgR = sum / count;
        avgG = avgR;
      }

      return _FrameAverages(avgRed: avgR, avgGreen: avgG);
    } catch (_) {
      return null;
    }
  }

  double _computePlacementScore({double avgRed, double avgGreen}) {
    final double ratio = avgRed / (avgGreen + 1.0);
    final double redScore = ((avgRed - 68.0) / 88.0).clamp(0.0, 1.0).toDouble();
    final double ratioScore = ((ratio - 0.86) / 0.20).clamp(0.0, 1.0).toDouble();

    double saturationPenalty = 1.0;
    if (avgRed > 252.0) {
      saturationPenalty = 0.62;
    } else if (avgRed > 248.0) {
      saturationPenalty = 0.82;
    } else if (avgRed > 244.0) {
      saturationPenalty = 0.92;
    }

    final double score = redScore * 0.55 + ratioScore * 0.45;
    return (score * saturationPenalty).clamp(0.0, 1.0).toDouble();
  }

  bool _isPlacementOkay({
    double avgRed,
    double avgGreen,
    double score,
    bool previousAligned,
  }) {
    final double ratio = avgRed / (avgGreen + 1.0);
    final double threshold = previousAligned
        ? _keepPlacementThreshold
        : _startPlacementThreshold;

    if (avgRed < 68.0) return false;
    if (avgRed >= 253.0) return false;
    if (ratio < 0.86) return false;
    return score >= threshold;
  }

  int get _countdownDisplay {
    return ((_countdownRemainingMs + 999) / 1000).ceil().clamp(1, 3);
  }

  bool get _showCountdownOverlay {
    return _stage == _MeasureStage.countdown;
  }

  int get _positionPercent {
    return (_positionScore * 100.0).clamp(0.0, 100.0).round();
  }

  int get _collectionSeconds {
    if (_collectionStartedAtMs <= 0) return 0;
    final int ms = DateTime.now().millisecondsSinceEpoch - _collectionStartedAtMs;
    return ms <= 0 ? 0 : (ms / 1000.0).floor();
  }

  String get _stageChipText {
    switch (_stage) {
      case _MeasureStage.initializing:
        return 'Khởi tạo';
      case _MeasureStage.idle:
        return 'Đặt ngón tay';
      case _MeasureStage.detectingFinger:
        return 'Đang xác nhận';
      case _MeasureStage.countdown:
        return 'Giữ yên';
      case _MeasureStage.collecting:
        return 'Đang đo';
      case _MeasureStage.stable:
        return 'Realtime';
      case _MeasureStage.error:
      default:
        return 'Lỗi';
    }
  }

  String get _centerCaption {
    switch (_stage) {
      case _MeasureStage.initializing:
        return 'Khởi tạo';
      case _MeasureStage.idle:
        return 'Đặt tay';
      case _MeasureStage.detectingFinger:
        return 'Phát hiện';
      case _MeasureStage.countdown:
        return 'Giữ yên';
      case _MeasureStage.collecting:
        return 'Đang đo';
      case _MeasureStage.stable:
        return 'Ổn định';
      case _MeasureStage.error:
      default:
        return 'Lỗi';
    }
  }

  String get _statusText {
    switch (_stage) {
      case _MeasureStage.initializing:
        return 'Đang khởi tạo camera...';
      case _MeasureStage.idle:
        return 'Đặt ngón tay che kín camera và đèn flash.';
      case _MeasureStage.detectingFinger:
        return 'Đã phát hiện ngón tay. Giữ yên thêm khoảng nửa giây để xác nhận.';
      case _MeasureStage.countdown:
        return 'Giữ yên liên tục 3 giây. Lệch nhẹ sẽ không reset ngay để dễ đo hơn.';
      case _MeasureStage.collecting:
        return 'Đang thu tín hiệu. App sẽ giữ kết quả mượt và chỉ hiện BPM khi tín hiệu đủ tin cậy.';
      case _MeasureStage.stable:
        return 'Đang đo realtime. BPM được làm mượt để tránh nhảy số.';
      case _MeasureStage.error:
      default:
        return _errorMessage.isNotEmpty ? _errorMessage : 'Đã xảy ra lỗi.';
    }
  }

  String get _guideTitle {
    switch (_stage) {
      case _MeasureStage.initializing:
        return 'Đang chuẩn bị đo';
      case _MeasureStage.idle:
        return 'Đặt ngón tay vào camera';
      case _MeasureStage.detectingFinger:
        return 'Đang kiểm tra vị trí';
      case _MeasureStage.countdown:
        return 'Giữ yên để bắt đầu đo';
      case _MeasureStage.collecting:
        return 'Đang thu dữ liệu nhịp tim';
      case _MeasureStage.stable:
        return 'Đang đo nhịp tim realtime';
      case _MeasureStage.error:
      default:
        return 'Không thể tiếp tục';
    }
  }

  String get _guideSubtitle {
    switch (_stage) {
      case _MeasureStage.initializing:
        return 'Vui lòng chờ camera và đèn flash sẵn sàng.';
      case _MeasureStage.idle:
        return 'Che kín camera sau và đèn flash. Không bắt đầu đo ngay khi vừa chạm vào.';
      case _MeasureStage.detectingFinger:
        return 'Hệ thống đang xác nhận ngón tay. Chỉ cần giữ yên ngắn để vào đo.';
      case _MeasureStage.countdown:
        return 'Giữ yên đúng vị trí trong 3 giây. App đã bắt đầu làm ấm tín hiệu để lên BPM nhanh hơn.';
      case _MeasureStage.collecting:
        return 'BPM đang bị ẩn trong lúc app gom đủ tín hiệu sạch. Thường sẽ lên nhanh hơn app bản cũ.';
      case _MeasureStage.stable:
        return 'Bạn có thể giữ nguyên để theo dõi liên tục hoặc lưu kết quả hiện tại.';
      case _MeasureStage.error:
      default:
        return 'Hãy thử lại và đảm bảo camera sau không bị che khuất bởi vật khác.';
    }
  }

  Color get _ringColor {
    switch (_stage) {
      case _MeasureStage.countdown:
      case _MeasureStage.detectingFinger:
        return Colors.orangeAccent;
      case _MeasureStage.collecting:
      case _MeasureStage.stable:
        return Colors.greenAccent;
      case _MeasureStage.error:
        return Colors.redAccent;
      case _MeasureStage.initializing:
      case _MeasureStage.idle:
      default:
        return _kWhite70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _buildCameraPreview(),
          _buildCameraShade(),
          SafeArea(
            child: _stage == _MeasureStage.error
                ? _buildErrorOverlay()
                : _buildOverlayContent(),
          ),
          if (_showCountdownOverlay) _buildCountdownOverlay(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return Container(color: Colors.black);
    }

    final Size size = MediaQuery.of(context).size;
    final double deviceRatio = size.width / size.height;
    final double previewRatio = _cameraController.value.aspectRatio;
    double scale = previewRatio / deviceRatio;
    if (scale < 1.0) scale = 1.0 / scale;

    return Transform.scale(
      scale: scale,
      child: Center(
        child: CameraPreview(_cameraController),
      ),
    );
  }

  Widget _buildCameraShade() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.black.withOpacity(0.38),
            Colors.black.withOpacity(0.10),
            Colors.black.withOpacity(0.12),
            Colors.black.withOpacity(0.56),
          ],
          stops: const <double>[0.0, 0.24, 0.56, 1.0],
        ),
      ),
    );
  }

  Widget _buildOverlayContent() {
    return Column(
      children: <Widget>[
        _buildTopBar(),
        Expanded(
          child: Center(
            child: _buildGuideTarget(),
          ),
        ),
        _buildBottomPanel(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: <Widget>[
          _CircleBtn(
            icon: Icons.close,
            onTap: () async {
              await _safeStopStream();
              await _turnOffFlash();
              if (mounted) Navigator.pop(context);
            },
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.28),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: _isFlashOn ? Colors.amber : _kWhite70,
                  size: 16.0,
                ),
                const SizedBox(width: 6.0),
                Text(
                  _isFlashOn ? 'Flash bật' : 'Flash tắt',
                  style: TextStyle(
                    color: _isFlashOn ? Colors.amber : _kWhite70,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideTarget() {
    final bool isMeasuring =
        _stage == _MeasureStage.collecting || _stage == _MeasureStage.stable;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 216.0,
          height: 216.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _ringColor.withOpacity(0.95),
              width: 3.0,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: _ringColor.withOpacity(0.18),
                blurRadius: 28.0,
                spreadRadius: 8.0,
              ),
            ],
            gradient: RadialGradient(
              colors: <Color>[
                Colors.white.withOpacity(0.10),
                Colors.white.withOpacity(0.02),
                Colors.transparent,
              ],
              stops: const <double>[0.0, 0.6, 1.0],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              AnimatedBuilder(
                animation: _scanAnim,
                builder: (BuildContext context, Widget child) {
                  return CustomPaint(
                    size: const Size(216.0, 216.0),
                    painter: _GuidePulsePainter(
                      progress: _scanAnim.value,
                      color: _ringColor,
                    ),
                  );
                },
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  AnimatedBuilder(
                    animation: _heartBeatAnim,
                    builder: (BuildContext context, Widget child) {
                      return Transform.scale(
                        scale: isMeasuring ? _heartBeatAnim.value : 1.0,
                        child: Icon(
                          Icons.favorite,
                          size: 34.0,
                          color: _ringColor,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    _centerCaption,
                    style: const TextStyle(
                      color: _kWhite,
                      fontSize: 26.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    'Vị trí ${_positionPercent <= 0 ? 0 : _positionPercent}%',
                    style: TextStyle(
                      color: _ringColor,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28.0),
        Text(
          _guideTitle,
          style: const TextStyle(
            color: _kWhite,
            fontSize: 22.0,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34.0),
          child: Text(
            _guideSubtitle,
            style: const TextStyle(
              color: _kWhite70,
              fontSize: 15.0,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 18.0),
      padding: const EdgeInsets.fromLTRB(18.0, 18.0, 18.0, 16.0),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: _kPanelBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildBpmRow(),
          const SizedBox(height: 14.0),
          _buildSignalRow(),
          const SizedBox(height: 14.0),
          _buildWave(),
          const SizedBox(height: 14.0),
          Text(
            _statusText,
            style: const TextStyle(
              color: _kWhite70,
              fontSize: 14.0,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          if (_showLiveBpm) ...<Widget>[
            const SizedBox(height: 16.0),
            _PillButton(
              icon: Icons.bookmark_rounded,
              label: 'Lưu kết quả hiện tại',
              color: Colors.greenAccent.withOpacity(0.22),
              textColor: Colors.greenAccent,
              borderColor: Colors.greenAccent.withOpacity(0.5),
              onTap: _showReportScreen,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBpmRow() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Nhịp tim',
                style: TextStyle(
                  color: _kWhite70,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Text(
                      _showLiveBpm ? '$_liveBpm' : '--',
                      key: ValueKey<String>(_showLiveBpm ? 'bpm_$_liveBpm' : 'bpm_hidden'),
                      style: const TextStyle(
                        color: _kWhite,
                        fontSize: 54.0,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 6.0, bottom: 8.0),
                    child: Text(
                      'bpm',
                      style: TextStyle(
                        color: _kWhite70,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: _ringColor.withOpacity(0.14),
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(
              color: _ringColor.withOpacity(0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Tín hiệu',
                style: TextStyle(
                  color: _ringColor,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                '${(_liveQuality * 100.0).clamp(0.0, 100.0).round()}%',
                style: const TextStyle(
                  color: _kWhite,
                  fontSize: 22.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignalRow() {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: _ringColor.withOpacity(0.14),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: _ringColor.withOpacity(0.32)),
          ),
          child: Text(
            _stageChipText,
            style: TextStyle(
              color: _ringColor,
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        Text(
          _collectionStartedAtMs > 0 ? 'Thu ${_collectionSeconds}s' : 'Chưa thu dữ liệu',
          style: const TextStyle(
            color: _kWhite70,
            fontSize: 13.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildWave() {
    return SizedBox(
      height: 78.0,
      child: AnimatedBuilder(
        animation: _scanAnim,
        builder: (BuildContext context, Widget child) {
          return CustomPaint(
            painter: _EcgPainter(
              progress: _scanAnim.value,
              signal: _displayValues,
              isActive: _stage == _MeasureStage.collecting ||
                  _stage == _MeasureStage.stable,
            ),
            size: Size(MediaQuery.of(context).size.width, 78.0),
          );
        },
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.38),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Giữ yên để bắt đầu đo',
                style: TextStyle(
                  color: _kWhite70,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18.0),
              AnimatedBuilder(
                animation: _countdownController,
                builder: (BuildContext context, Widget child) {
                  return Opacity(
                    opacity: _countdownFadeAnim.value,
                    child: Transform.scale(
                      scale: _countdownScaleAnim.value,
                      child: child,
                    ),
                  );
                },
                child: Text(
                  '$_countdownDisplay',
                  style: const TextStyle(
                    color: _kWhite,
                    fontSize: 112.0,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 18.0),
              const Text(
                'Lệch ngón tay sẽ reset countdown và dữ liệu đo.',
                style: TextStyle(
                  color: _kWhite70,
                  fontSize: 13.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.62),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, color: _kWhite70, size: 64.0),
              const SizedBox(height: 18.0),
              Text(
                _errorMessage.isNotEmpty ? _errorMessage : 'Đã xảy ra lỗi.',
                style: const TextStyle(
                  color: _kWhite70,
                  fontSize: 16.0,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30.0),
              _PillButton(
                label: 'Thử lại',
                color: Colors.white24,
                textColor: _kWhite,
                onTap: () async {
                  await _initializeCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveHeartRate() async {
    if (!_showLiveBpm) return;
    if (_liveBpm < 30 || _liveBpm > 220) return;

    final bool confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Lưu kết quả'),
        content: Text('Lưu kết quả $_liveBpm BPM?'),
        actions: <Widget>[
          CupertinoDialogAction(
            child: const Text('Hủy'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Lưu'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ) ?? false;

    if (confirm && mounted) {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      final hrData = HeartRateDB(hr: _liveBpm, date: dateStr);
      await HeartRateDataBaseProvider.db.insert(hrData);
      
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text('Đã lưu'),
          content: Text('Nhịp tim $_liveBpm BPM đã được lưu.'),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      
      Navigator.pop(context);
    }
  }

  void _showReportScreen() {
    if (!_showLiveBpm) return;
    if (_liveBpm < 30 || _liveBpm > 220) return;
    
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => HRResultScreen(
          hr: _liveBpm,
          onSave: (int savedHr) {
            showCupertinoDialog(
              context: context,
              builder: (_) => CupertinoAlertDialog(
                title: Text('Đã lưu'),
                content: Text('Nhịp tim $savedHr BPM đã được lưu.'),
                actions: [
                  CupertinoDialogAction(
                    child: Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FrameAverages {
  final double avgRed;
  final double avgGreen;

  const _FrameAverages({
    @required this.avgRed,
    @required this.avgGreen,
  });
}

class _GuidePulsePainter extends CustomPainter {
  final double progress;
  final Color color;

  const _GuidePulsePainter({
    @required this.progress,
    @required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint ringPaint = Paint()
      ..color = color.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double radius = size.width / 2.0;
    final double pulse = (sin(progress * pi * 2.0) + 1.0) / 2.0;
    final double dynamicRadius = radius * (0.62 + pulse * 0.18);

    canvas.drawCircle(
      Offset(size.width / 2.0, size.height / 2.0),
      dynamicRadius,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GuidePulsePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _EcgPainter extends CustomPainter {
  final double progress;
  final List<double> signal;
  final bool isActive;

  _EcgPainter({
    @required this.progress,
    @required this.signal,
    @required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Colors.white.withOpacity(0.92)
      ..strokeWidth = 2.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final Path path = Path();
    final Path glow = Path();
    final bool useReal = signal != null && signal.length > 10;

    if (useReal) {
      double mn = signal.reduce(min);
      double mx = signal.reduce(max);
      if ((mx - mn).abs() < 1e-6) {
        mn -= 1.0;
        mx += 1.0;
      }
      final double range = mx - mn;

      for (int i = 0; i < signal.length; i++) {
        final double x = i / (signal.length - 1) * size.width;
        final double y = size.height -
            ((signal[i] - mn) / range) * size.height * 0.75 -
            size.height * 0.12;
        if (i == 0) {
          path.moveTo(x, y);
          glow.moveTo(x, y);
        } else {
          path.lineTo(x, y);
          glow.lineTo(x, y);
        }
      }
    } else {
      _buildSynthetic(path, glow, size);
    }

    canvas.drawPath(glow, glowPaint);
    canvas.drawPath(path, linePaint);

    if (isActive) {
      final double scanX = progress * size.width;
      final Paint scanPaint = Paint()
        ..color = Colors.white.withOpacity(0.45)
        ..strokeWidth = 2.0;
      canvas.drawLine(
        Offset(scanX, 0),
        Offset(scanX, size.height),
        scanPaint,
      );
    }
  }

  void _buildSynthetic(Path path, Path glow, Size size) {
    const int pts = 260;
    final double cy = size.height / 2.0;
    final double amp = size.height * 0.34;

    for (int i = 0; i <= pts; i++) {
      final double t = i / pts;
      final double x = t * size.width;
      final double phase = (t * 3.2) % 1.0;
      double y = cy;

      if (phase < 0.10) {
        y = cy - amp * 0.10 * sin(phase / 0.10 * pi);
      } else if (phase < 0.18) {
        y = cy + amp * 0.04 * sin((phase - 0.10) / 0.08 * pi);
      } else if (phase < 0.23) {
        y = cy - amp * 1.00 * sin((phase - 0.18) / 0.05 * pi);
      } else if (phase < 0.30) {
        y = cy + amp * 0.28 * sin((phase - 0.23) / 0.07 * pi);
      } else if (phase < 0.50) {
        y = cy - amp * 0.16 * sin((phase - 0.30) / 0.20 * pi);
      }

      if (i == 0) {
        path.moveTo(x, y);
        glow.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        glow.lineTo(x, y);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EcgPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.signal != signal ||
        oldDelegate.isActive != isActive;
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleBtn({
    Key key,
    @required this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.0,
        height: 40.0,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 20.0),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _PillButton({
    Key key,
    @required this.label,
    @required this.color,
    @required this.textColor,
    this.icon,
    this.borderColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30.0),
          border: borderColor != null ? Border.all(color: borderColor) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, color: textColor, size: 18.0),
              const SizedBox(width: 8.0),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 16.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
