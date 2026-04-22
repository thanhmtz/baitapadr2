import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../../services/heart_rate_service.dart';
import '../ResultScreen/hrResultScreen.dart';

// ─── Colour tokens ───────────────────────────────────────────────────────────
const Color _kBgDark     = Color(0xFF5A0000);
const Color _kBgMid      = Color(0xFF8B0000);
const Color _kBgInner    = Color(0xFFB00000);
const Color _kWhite      = Colors.white;
const Color _kWhite70    = Color(0xB3FFFFFF);
const Color _kProgressBg = Color(0x33FFFFFF);

// ─────────────────────────────────────────────────────────────────────────────

class HeartRateScreen extends StatefulWidget {
  @override
  _HeartRateScreenState createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen>
    with TickerProviderStateMixin {

  // ── Services / camera ─────────────────────────────────
  final HeartRateService _heartRateService = HeartRateService();
  CameraController _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;

  // ── Measurement state ─────────────────────────────────
  HeartRateMeasurementState _state = HeartRateMeasurementState.idle;
  int          _measuredHR    = 0;
  List<double> _displayValues = [];
  Timer        _measurementTimer;
  int          _currentMs    = 0;
  String       _errorMessage = '';
  bool         _isDisposed   = false;
  bool         _isStreaming  = false;
  bool         _isStopping   = false;
  bool         _manualStart  = false;

  // ── Animations ────────────────────────────────────────
  AnimationController _heartBeatController;
  Animation<double>   _heartBeatAnim;
  AnimationController _ecgController;
  Animation<double>   _ecgAnim;

  // ── Insight cycling ───────────────────────────────────
  static const List<String> _insights = [
    'Nhịp tim trung bình khi nghỉ ngơi là 60–100 nhịp/phút.',
    'Tim đập khoảng 100,000 lần mỗi ngày.',
    'Tín hiệu điện tim truyền nhanh hơn tín hiệu thần kinh.',
    'Vận động đều đặn giúp giảm nhịp tim khi nghỉ ngơi.',
    'Nhịp tim thấp hơn thường là dấu hiệu tim khỏe mạnh hơn.',
  ];
  int   _insightIndex = 0;
  Timer _insightTimer;

  // ─────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeCamera();
    _startInsightCycle();
  }

  void _initAnimations() {
    _heartBeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heartBeatAnim = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.0, end: 1.25),
          weight: 30,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.25, end: 1.0),
          weight: 70,
        ),
      ],
    ).animate(CurvedAnimation(
      parent: _heartBeatController,
      curve: Curves.easeOut,
    ));

    _ecgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _ecgAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_ecgController);
  }

  void _startInsightCycle() {
    _insightTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isDisposed && mounted) {
        setState(() =>
        _insightIndex = (_insightIndex + 1) % _insights.length);
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _measurementTimer?.cancel();
    _insightTimer?.cancel();
    _heartBeatController.dispose();
    _ecgController.dispose();
    _isStreaming = false;
    _turnOffFlash();

    final CameraController ctrl = _cameraController;
    _cameraController = null;
    if (ctrl != null && ctrl.value.isInitialized) {
      try {
        if (ctrl.value.isStreamingImages) ctrl.stopImageStream();
      } catch (_) {}
      ctrl.dispose();
    }
    super.dispose();
  }

  // ── Camera ────────────────────────────────────────────

  Future<void> _initializeCamera() async {
    if (!mounted) return;
    try {
      _cameras = await availableCameras();
      CameraDescription back;
      for (final CameraDescription c in _cameras) {
        if (c.lensDirection == CameraLensDirection.back) {
          back = c;
          break;
        }
      }
      if (back == null && _cameras.isNotEmpty) back = _cameras[0];
      if (back == null) throw Exception('No camera available');

      _cameraController = CameraController(
        back,
        ResolutionPreset.low,
        enableAudio: false,
      );
      await _cameraController.initialize();
      await _cameraController.setFlashMode(FlashMode.torch);

      if (mounted && !_isDisposed) {
        setState(() {
          _isCameraInitialized = true;
          _isFlashOn = true;
          _state = HeartRateMeasurementState.waitingForFinger;
        });
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      setState(() {
        _state = HeartRateMeasurementState.error;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _turnOffFlash() async {
    try {
      if (_cameraController != null &&
          _cameraController.value.isInitialized) {
        await _cameraController.setFlashMode(FlashMode.off);
      }
    } catch (_) {}
  }

  // ── Measurement ──────────────────────────────────────

  void _startMeasurementManual() {
    _manualStart = true;
    _startMeasurement();
  }

  void _startMeasurement() {
    if (!_isCameraInitialized) return;
    if (_cameraController == null || !_cameraController.value.isInitialized)
      return;
    if (_isStreaming || _isStopping) return;

    _heartRateService.reset();
    _displayValues = [];
    _measuredHR    = 0;
    _currentMs     = 0;
    _errorMessage  = '';

    _heartBeatController.repeat();

    setState(() {
      _isStreaming = true;
      _state = HeartRateMeasurementState.measuring;
    });

    _cameraController.startImageStream((CameraImage image) {
      if (_isDisposed || !_isStreaming) return;
      if (_state != HeartRateMeasurementState.measuring) return;
      final int now = DateTime.now().millisecondsSinceEpoch;
      if (!_heartRateService.shouldProcessFrame(now)) return;
      _processImage(image);
    }).catchError((Object e) {
      if (!_isDisposed && mounted) {
        setState(() {
          _isStreaming = false;
          _state = HeartRateMeasurementState.error;
          _errorMessage = 'Camera error: $e';
        });
      }
    });

    _measurementTimer?.cancel();
    _measurementTimer =
        Timer.periodic(const Duration(milliseconds: 100), (Timer t) {
          if (_isDisposed || !mounted) { t.cancel(); return; }
          if (_state != HeartRateMeasurementState.measuring) { t.cancel(); return; }
          _currentMs += 100;
          if (_currentMs >= 20000) {
            t.cancel();
            _completeMeasurement();
          } else {
            setState(() {});
          }
        });
  }

  Future<void> _safeStopStream() async {
    if (_isStopping || !_isStreaming) return;
    if (_cameraController == null || !_cameraController.value.isInitialized) {
      _isStreaming = false;
      return;
    }
    _isStopping = true;
    _heartBeatController.stop();
    _heartBeatController.reset();
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isDisposed &&
          _cameraController != null &&
          _cameraController.value.isInitialized &&
          _cameraController.value.isStreamingImages) {
        await _cameraController.stopImageStream();
      }
    } catch (_) {}
    _isStreaming = false;
    _isStopping  = false;
  }

  Future<void> _completeMeasurement() async {
    if (_isDisposed) return;
    await _safeStopStream();
    await _turnOffFlash();
    if (_isDisposed || !mounted) return;
    setState(() => _state = HeartRateMeasurementState.processing);

    final HeartRateResult result = _heartRateService.calculateHeartRate();
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

  void _processImage(CameraImage image) {
    if (_isDisposed || image.planes.isEmpty) return;
    final Plane plane = image.planes[0];
    final int   bpr   = plane.bytesPerRow;
    final int   h     = image.height;
    final       bytes = plane.bytes;

    double gSum = 0, rSum = 0;
    int    count = 0;
    final int cy  = h ~/ 2;
    final int reg = h ~/ 3;
    final int sy  = cy - reg;
    final int ey  = cy + reg;

    for (int y = sy; y < ey; y++) {
      for (int x = 0; x < bpr; x += 4) {
        final int idx = y * bpr + x;
        if (idx + 2 < bytes.length) {
          rSum += bytes[idx];
          gSum += bytes[idx + 1];
          count++;
        }
      }
    }
    if (count == 0) return;

    final double avgG = gSum / count;
    final double avgR = rSum / count;

    // Gọi addSample với 1 tham số (phù hợp HeartRateService cơ bản)
    // Nếu service của bạn có thêm tham số, hãy thêm vào đây
    _heartRateService.addSample(avgR * 0.6 + avgG * 0.4);

    if (!_manualStart && !_heartRateService.isFingerDetected()) {
      if (_state == HeartRateMeasurementState.measuring && mounted) {
        setState(
                () => _state = HeartRateMeasurementState.waitingForFinger);
      }
    } else if (_state == HeartRateMeasurementState.waitingForFinger &&
        mounted) {
      setState(() => _state = HeartRateMeasurementState.measuring);
    }

    final List<double> buf = _heartRateService.getSignalBuffer();
    if (buf.length > 1 && mounted) {
      setState(() {
        _displayValues =
            buf.sublist(buf.length > 80 ? buf.length - 80 : 0);
      });
    }
  }

  int get _progressPercent =>
      ((_currentMs / 20000) * 100).clamp(0, 100).round();

  // ── Save ─────────────────────────────────────────────

  void _saveHeartRate() async {
    if (_measuredHR < 30 || _measuredHR > 220) return;
    final bool ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Lưu kết quả'),
        content: Text('Lưu kết quả $_measuredHR BPM?'),
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
    ) ??
        false;
    if (ok && mounted) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => HRResultScreen(hr: _measuredHR),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgDark,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _buildBackground(),
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: CameraPreview(_cameraController),
              ),
            ),
          SafeArea(child: _buildUI()),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.1),
          radius: 0.9,
          colors: <Color>[_kBgInner, _kBgMid, _kBgDark],
          stops: <double>[0.0, 0.45, 1.0],
        ),
      ),
    );
  }

  Widget _buildUI() {
    return Column(
      children: <Widget>[
        _buildTopBar(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          if (_isFlashOn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const <Widget>[
                  Icon(Icons.flash_on, color: Colors.amber, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Flash',
                    style: TextStyle(color: Colors.amber, fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case HeartRateMeasurementState.waitingForFinger:
        return _buildWaiting();
      case HeartRateMeasurementState.measuring:
      case HeartRateMeasurementState.processing:
        return _buildMeasuring();
      case HeartRateMeasurementState.completed:
        return _buildResult();
      case HeartRateMeasurementState.error:
        return _buildError();
      default:
        return _buildWaiting();
    }
  }

  // ── Waiting ──────────────────────────────────────────

  Widget _buildWaiting() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.touch_app, color: _kWhite, size: 72),
          const SizedBox(height: 28),
          const Text(
            'Đặt ngón tay lên camera',
            style: TextStyle(
              color: _kWhite,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Phủ kín camera sau và đèn flash\nbằng ngón tay trỏ của bạn',
            style: TextStyle(
              color: _kWhite.withOpacity(0.7),
              fontSize: 15,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _PillButton(
            label: 'Bắt đầu đo',
            onTap: _manualStart ? null : _startMeasurementManual,
            color: Colors.white,
            textColor: _kBgDark,
          ),
          const SizedBox(height: 12),
          Text(
            'Nhấn nếu camera không nhận ngón tay',
            style: TextStyle(
              color: _kWhite.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── Measuring ────────────────────────────────────────

  Widget _buildMeasuring() {
    final bool fingerOk    = _heartRateService.isFingerDetected();
    final int  sampleCount = _heartRateService.sampleCount;

    return Column(
      children: <Widget>[
        const SizedBox(height: 12),
        _buildBpmDisplay(sampleCount, fingerOk),
        const Spacer(),
        _buildEcgWave(),
        const Spacer(),
        _buildInsight(),
        const SizedBox(height: 24),
        _buildProgress(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildBpmDisplay(int sampleCount, bool fingerOk) {
    return Column(
      children: <Widget>[
        AnimatedBuilder(
          animation: _heartBeatAnim,
          builder: (BuildContext ctx, Widget child) => Transform.scale(
            scale: _state == HeartRateMeasurementState.measuring
                ? _heartBeatAnim.value
                : 1.0,
            child: const Icon(Icons.favorite, color: _kWhite, size: 36),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              _displayValues.isNotEmpty && fingerOk
                  ? '${_estimateLiveBpm()}'
                  : '--',
              style: const TextStyle(
                color: _kWhite,
                fontSize: 88,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 14, left: 6),
              child: Text(
                'bpm',
                style: TextStyle(
                  color: _kWhite70,
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: fingerOk
                ? Colors.white.withOpacity(0.15)
                : Colors.orange.withOpacity(0.25),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: fingerOk
                  ? Colors.white24
                  : Colors.orange.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                fingerOk ? Icons.favorite : Icons.warning_amber_rounded,
                color: fingerOk ? _kWhite : Colors.orangeAccent,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                fingerOk
                    ? 'Đang đo nhịp tim...'
                    : 'Đặt ngón tay vào camera',
                style: TextStyle(
                  color: fingerOk ? _kWhite : Colors.orangeAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _estimateLiveBpm() {
    if (_displayValues.length < 20) return 0;
    final HeartRateResult res = _heartRateService.calculateHeartRate();
    return res.isValid ? res.bpm : 0;
  }

  Widget _buildEcgWave() {
    return SizedBox(
      height: 100,
      child: AnimatedBuilder(
        animation: _ecgAnim,
        builder: (BuildContext ctx, Widget child) => CustomPaint(
          painter: _EcgPainter(
            progress: _ecgAnim.value,
            signal: _displayValues,
            isActive: _state == HeartRateMeasurementState.measuring,
          ),
          size: Size(MediaQuery.of(context).size.width, 100),
        ),
      ),
    );
  }

  Widget _buildInsight() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: Text(
          'Science Insight: ${_insights[_insightIndex]}',
          key: ValueKey<int>(_insightIndex),
          style: const TextStyle(
            color: _kWhite70,
            fontSize: 15,
            height: 1.55,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildProgress() {
    final double frac        = _progressPercent / 100.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double barWidth    = screenWidth - 64;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 10,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: <Widget>[
                Container(
                  height: 3,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _kProgressBg,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  height: 3,
                  width: barWidth * frac.clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    color: _kWhite,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Positioned(
                  left: (barWidth * frac.clamp(0.0, 1.0) - 5)
                      .clamp(0.0, barWidth - 10),
                  child: Container(
                    width:  10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: _kWhite,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$_progressPercent%',
            style: const TextStyle(
              color: _kWhite,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Result ───────────────────────────────────────────

  Widget _buildResult() {
    String label;
    Color  labelColor;
    if (_measuredHR < 60) {
      label      = 'Nhịp tim thấp';
      labelColor = Colors.blueAccent;
    } else if (_measuredHR <= 100) {
      label      = 'Bình thường';
      labelColor = Colors.greenAccent;
    } else {
      label      = 'Nhịp tim cao';
      labelColor = Colors.redAccent;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Icon(Icons.favorite, color: _kWhite, size: 48),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              '$_measuredHR',
              style: const TextStyle(
                color: _kWhite,
                fontSize: 96,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 14, left: 8),
              child: Text(
                'bpm',
                style: TextStyle(color: _kWhite70, fontSize: 22),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: labelColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: labelColor.withOpacity(0.5)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _PillButton(
              icon: Icons.refresh_rounded,
              label: 'Đo lại',
              color: Colors.white24,
              textColor: _kWhite,
              onTap: () async {
                await _turnOffFlash();
                _heartRateService.reset();
                setState(() {
                  _state         = HeartRateMeasurementState.waitingForFinger;
                  _measuredHR    = 0;
                  _displayValues = [];
                  _currentMs     = 0;
                  _manualStart   = false;
                });
                await _initializeCamera();
              },
            ),
            const SizedBox(width: 16),
            _PillButton(
              icon: Icons.bookmark_rounded,
              label: 'Lưu',
              color: Colors.greenAccent.withOpacity(0.25),
              textColor: Colors.greenAccent,
              borderColor: Colors.greenAccent.withOpacity(0.5),
              onTap: _saveHeartRate,
            ),
          ],
        ),
      ],
    );
  }

  // ── Error ────────────────────────────────────────────

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.error_outline, color: _kWhite70, size: 64),
          const SizedBox(height: 20),
          Text(
            _errorMessage.isNotEmpty ? _errorMessage : 'Đã xảy ra lỗi.',
            style: const TextStyle(
              color: _kWhite70,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          _PillButton(
            label: 'Thử lại',
            color: Colors.white24,
            textColor: _kWhite,
            onTap: () {
              _heartRateService.reset();
              setState(() {
                _state         = HeartRateMeasurementState.waitingForFinger;
                _measuredHR    = 0;
                _displayValues = [];
                _currentMs     = 0;
                _errorMessage  = '';
                _manualStart   = false;
              });
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ECG Painter
// ─────────────────────────────────────────────────────────────────────────────

class _EcgPainter extends CustomPainter {
  final double       progress;
  final List<double> signal;
  final bool         isActive;

  // Dart 2.13: dùng @required từ package:meta
  _EcgPainter({
    @required this.progress,
    @required this.signal,
    @required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color       = Colors.white.withOpacity(0.9)
      ..strokeWidth = 2.2
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;

    final Paint glowPaint = Paint()
      ..color       = Colors.white.withOpacity(0.18)
      ..strokeWidth = 6
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round
      ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 4);

    final int  n       = signal.length;
    final bool useReal = n > 10;
    final Path path     = Path();
    final Path glowPath = Path();

    if (useReal) {
      double mn = signal.reduce(min);
      double mx = signal.reduce(max);
      if ((mx - mn) < 1e-6) { mn -= 1; mx += 1; }
      final double norm = mx - mn;

      for (int i = 0; i < n; i++) {
        final double x = i / (n - 1) * size.width;
        final double y = size.height -
            ((signal[i] - mn) / norm) * size.height * 0.8 -
            size.height * 0.1;
        if (i == 0) {
          path.moveTo(x, y);
          glowPath.moveTo(x, y);
        } else {
          path.lineTo(x, y);
          glowPath.lineTo(x, y);
        }
      }
    } else {
      _buildSyntheticEcg(path, glowPath, size);
    }

    canvas.drawPath(glowPath, glowPaint);
    canvas.drawPath(path, linePaint);

    if (isActive) {
      final double scanX    = progress * size.width;
      final Paint scanPaint = Paint()
        ..color       = Colors.white.withOpacity(0.5)
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(scanX, 0),
        Offset(scanX, size.height),
        scanPaint,
      );
    }
  }

  void _buildSyntheticEcg(Path path, Path glow, Size size) {
    const int    pts = 300;
    final double cy  = size.height / 2;
    final double amp = size.height * 0.38;

    for (int i = 0; i <= pts; i++) {
      final double t     = i / pts;
      final double x     = t * size.width;
      final double phase = (t * 3) % 1.0;
      double y = cy;

      if (phase < 0.10) {
        y = cy - amp * 0.12 * sin(phase / 0.10 * pi);
      } else if (phase < 0.18) {
        y = cy + amp * 0.05 * sin((phase - 0.10) / 0.08 * pi);
      } else if (phase < 0.23) {
        y = cy - amp * 1.0  * sin((phase - 0.18) / 0.05 * pi);
      } else if (phase < 0.30) {
        y = cy + amp * 0.30 * sin((phase - 0.23) / 0.07 * pi);
      } else if (phase < 0.50) {
        y = cy - amp * 0.18 * sin((phase - 0.30) / 0.20 * pi);
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
  bool shouldRepaint(covariant _EcgPainter old) =>
      old.progress != progress ||
          old.signal   != signal   ||
          old.isActive != isActive;
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData     icon;
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
        width:  40,
        height: 40,
        decoration: BoxDecoration(
          color:  Colors.white.withOpacity(0.15),
          shape:  BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final Color        color;
  final Color        textColor;
  final Color        borderColor;
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
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color:        color,
          borderRadius: BorderRadius.circular(32),
          border: borderColor != null
              ? Border.all(color: borderColor)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color:      textColor,
                fontSize:   16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}