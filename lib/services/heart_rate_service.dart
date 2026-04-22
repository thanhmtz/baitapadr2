import 'dart:math';

// ─────────────────────────────────────────────────────────────────────────────
// Data classes
// ─────────────────────────────────────────────────────────────────────────────

class HeartRateResult {
  final int bpm;
  final bool isValid;
  final String errorMessage;
  final double signalQuality;

  HeartRateResult({
    this.bpm = 0,
    this.isValid = false,
    this.errorMessage = '',
    this.signalQuality = 0,
  });
}

enum HeartRateMeasurementState {
  idle,
  initializing,
  waitingForFinger,
  measuring,
  processing,
  completed,
  error,
}

class HeartRateException implements Exception {
  final String message;
  final String code;

  HeartRateException(this.message, [this.code = 'UNKNOWN']);

  @override
  String toString() => 'HeartRateException: $message ($code)';
}

// ─────────────────────────────────────────────────────────────────────────────
// HeartRateService
//
// Pipeline:
//   raw red channel
//     → mean-subtraction (remove DC)
//     → 2nd-order Butterworth bandpass  0.5–4 Hz  (30–240 BPM)
//     → adaptive peak detection (Pan-Tompkins inspired)
//     → RR-interval outlier rejection  (IQR filter)
//     → median BPM from clean RR intervals
// ─────────────────────────────────────────────────────────────────────────────

class HeartRateService {
  // ── tunables ────────────────────────────────────────────────────────────────

  /// Frames per second the caller delivers (approximate).
  static const double _fps = 30.0;

  /// We keep at most this many samples in memory (≈ 20 s @ 30 fps).
  static const int _bufferSize = 600;

  /// We need at least this many samples before attempting a BPM calculation.
  static const int _minSamplesForCalculation = 150; // ≈ 5 s

  /// Physiological BPM limits.
  static const double _minBpm = 40.0;
  static const double _maxBpm = 200.0;

  /// Minimum allowed RR interval in seconds (200 ms → 300 BPM ceiling).
  static const double _minRrSeconds = 60.0 / _maxBpm;

  /// Maximum allowed RR interval in seconds (1.5 s → 40 BPM floor).
  static const double _maxRrSeconds = 60.0 / _minBpm;

  // ── state ───────────────────────────────────────────────────────────────────

  final List<double> _rawBuffer = [];
  final List<int> _timestamps = []; // milliseconds

  // Butterworth filter state (2 biquad sections)
  final List<_BiquadState> _bpStates = [_BiquadState(), _BiquadState()];

  double _dcLevel = 0; // exponential moving average of raw signal
  double _signalQuality = 0;

  // ── public API ───────────────────────────────────────────────────────────────

  void reset() {
    _rawBuffer.clear();
    _timestamps.clear();
    for (final s in _bpStates) {
      s.reset();
    }
    _dcLevel = 0;
    _signalQuality = 0;
  }

  /// Returns true when enough time has passed since the last sample.
  /// Throttles to ~30 fps even if the camera delivers faster.
  bool shouldProcessFrame(int currentTimeMs) {
    if (_timestamps.isEmpty) return true;
    return (currentTimeMs - _timestamps.last) >= (1000 / _fps).round();
  }

  /// Feed one red-channel intensity value (0–255 range typical).
  void addSample(double redIntensity, {int timestamp}) {
    final int ts = timestamp ?? DateTime.now().millisecondsSinceEpoch;

    // Update DC tracking (slow EMA, α ≈ 0.02)
    if (_rawBuffer.isEmpty) {
      _dcLevel = redIntensity;
    } else {
      _dcLevel = 0.98 * _dcLevel + 0.02 * redIntensity;
    }

    _rawBuffer.add(redIntensity);
    _timestamps.add(ts);

    if (_rawBuffer.length > _bufferSize) {
      _rawBuffer.removeAt(0);
      _timestamps.removeAt(0);
    }

    _updateSignalQuality();
  }

  bool isFingerDetected() {
    // Finger on lens: mean red value is high, variance moderate
    if (_rawBuffer.length < 30) return false;
    return _dcLevel > 60 && _signalQuality > 0;
  }

  bool isSignalValid() {
    return _rawBuffer.length >= _minSamplesForCalculation &&
        _signalQuality > 0.05;
  }

  double get signalQuality => _signalQuality;

  HeartRateResult calculateHeartRate() {
    if (!isSignalValid()) {
      return HeartRateResult(
        isValid: false,
        errorMessage: 'Tín hiệu yếu. Đặt ngón tay chắc hơn và giữ yên.',
        signalQuality: _signalQuality,
      );
    }

    // 1. Compute actual sample rate from timestamps
    final double fs = _estimateSampleRate();
    if (fs < 10 || fs > 120) {
      return HeartRateResult(
        isValid: false,
        errorMessage: 'Tần suất lấy mẫu không ổn định. Thử lại.',
        signalQuality: _signalQuality,
      );
    }

    // 2. Remove DC
    final List<double> centered = _removeDc(List.from(_rawBuffer));

    // 3. Bandpass filter: 0.5–4 Hz (30–240 BPM)
    final List<double> filtered = _butterworthBandpass(centered, fs);

    // 4. Detect peaks (Pan-Tompkins adaptive threshold)
    final List<int> peakIndices = _detectPeaks(filtered, fs);

    if (peakIndices.length < 3) {
      return HeartRateResult(
        isValid: false,
        errorMessage: 'Không nhận diện được nhịp tim rõ ràng. Thử lại.',
        signalQuality: _signalQuality,
      );
    }

    // 5. Convert peak indices → RR intervals (seconds)
    final List<double> rrIntervals =
    _peaksToRrIntervals(peakIndices, fs);

    // 6. Reject outlier RR intervals (IQR filter)
    final List<double> cleanRr = _filterRrOutliers(rrIntervals);

    if (cleanRr.isEmpty) {
      return HeartRateResult(
        isValid: false,
        errorMessage: 'Nhịp tim không ổn định. Giữ ngón tay yên hơn.',
        signalQuality: _signalQuality,
      );
    }

    // 7. BPM = 60 / median(RR)
    final double medianRr = _median(cleanRr);
    final int bpm = (60.0 / medianRr).round();

    if (bpm < _minBpm.round() || bpm > _maxBpm.round()) {
      return HeartRateResult(
        isValid: false,
        errorMessage: 'Kết quả ngoài phạm vi ($bpm BPM). Thử lại.',
        signalQuality: _signalQuality,
      );
    }

    return HeartRateResult(
      bpm: bpm,
      isValid: true,
      signalQuality: _signalQuality,
    );
  }

  List<double> getSignalBuffer() => List.unmodifiable(_rawBuffer);
  int get sampleCount => _rawBuffer.length;

  // ── private helpers ──────────────────────────────────────────────────────────

  /// Estimate the actual fps from the stored timestamps.
  double _estimateSampleRate() {
    if (_timestamps.length < 2) return _fps;
    final double elapsedMs =
    (_timestamps.last - _timestamps.first).toDouble();
    if (elapsedMs <= 0) return _fps;
    return (_timestamps.length - 1) / (elapsedMs / 1000.0);
  }

  /// Subtract the per-window mean (high-pass: removes DC & very slow drift).
  List<double> _removeDc(List<double> signal) {
    if (signal.isEmpty) return signal;
    double mean = signal.reduce((a, b) => a + b) / signal.length;
    return signal.map((v) => v - mean).toList();
  }

  // ── Butterworth 2nd-order bandpass ──────────────────────────────────────────
  //
  // Implemented as two cascaded biquad sections:
  //   Section 0 — low-pass  at 4 Hz  (kills motion artifacts above 240 BPM)
  //   Section 1 — high-pass at 0.5 Hz (kills respiration / slow drift)
  //
  // Coefficients are pre-computed for fs = 30 Hz.
  // For other fs values we use the bilinear-transform formula at runtime.

  List<double> _butterworthBandpass(List<double> signal, double fs) {
    // --- Low-pass biquad: fc = 4 Hz, Q = 0.7071 ---
    final _BiquadCoeffs lp = _designLowPass(4.0, fs);
    // --- High-pass biquad: fc = 0.5 Hz, Q = 0.7071 ---
    final _BiquadCoeffs hp = _designHighPass(0.5, fs);

    final _BiquadState stateLP = _BiquadState();
    final _BiquadState stateHP = _BiquadState();

    List<double> out = List.filled(signal.length, 0.0);
    for (int i = 0; i < signal.length; i++) {
      final double afterLP = _biquadProcess(signal[i], lp, stateLP);
      out[i] = _biquadProcess(afterLP, hp, stateHP);
    }
    return out;
  }

  _BiquadCoeffs _designLowPass(double fc, double fs) {
    final double w0 = 2 * pi * fc / fs;
    final double cosW = cos(w0);
    final double sinW = sin(w0);
    final double alpha = sinW / (2 * 0.7071);

    final double b0 = (1 - cosW) / 2;
    final double b1 = 1 - cosW;
    final double b2 = (1 - cosW) / 2;
    final double a0 = 1 + alpha;
    final double a1 = -2 * cosW;
    final double a2 = 1 - alpha;

    return _BiquadCoeffs(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0);
  }

  _BiquadCoeffs _designHighPass(double fc, double fs) {
    final double w0 = 2 * pi * fc / fs;
    final double cosW = cos(w0);
    final double sinW = sin(w0);
    final double alpha = sinW / (2 * 0.7071);

    final double b0 = (1 + cosW) / 2;
    final double b1 = -(1 + cosW);
    final double b2 = (1 + cosW) / 2;
    final double a0 = 1 + alpha;
    final double a1 = -2 * cosW;
    final double a2 = 1 - alpha;

    return _BiquadCoeffs(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0);
  }

  double _biquadProcess(double x, _BiquadCoeffs c, _BiquadState s) {
    final double y =
        c.b0 * x + c.b1 * s.x1 + c.b2 * s.x2 - c.a1 * s.y1 - c.a2 * s.y2;
    s.x2 = s.x1;
    s.x1 = x;
    s.y2 = s.y1;
    s.y1 = y;
    return y;
  }

  // ── Peak detection (Pan-Tompkins adaptive threshold) ────────────────────────
  //
  // 1. Square the signal to emphasise peaks.
  // 2. Maintain a running adaptive threshold (75% of recent peak amplitude).
  // 3. Enforce a refractory period of _minRrSeconds after each detected peak.

  List<int> _detectPeaks(List<double> signal, double fs) {
    if (signal.length < 5) return [];

    // Square to make peaks stand out
    final List<double> squared = signal.map((v) => v * v).toList();

    final int refractorySamples = (fs * _minRrSeconds).round();
    final List<int> peaks = [];

    double adaptiveThreshold = _computeInitialThreshold(squared);
    int lastPeakIdx = -refractorySamples;

    for (int i = 2; i < squared.length - 2; i++) {
      // Refractory check
      if (i - lastPeakIdx < refractorySamples) continue;

      // Local maximum check (5-point window)
      final bool isLocalMax = squared[i] > squared[i - 1] &&
          squared[i] > squared[i + 1] &&
          squared[i] > squared[i - 2] &&
          squared[i] > squared[i + 2];

      if (!isLocalMax) continue;

      if (squared[i] > adaptiveThreshold) {
        peaks.add(i);
        lastPeakIdx = i;
        // Update threshold: 75% of the detected peak amplitude
        adaptiveThreshold =
            0.75 * adaptiveThreshold + 0.25 * squared[i];
      } else {
        // Slowly decay threshold so we don't get stuck
        adaptiveThreshold *= 0.99;
      }
    }

    return peaks;
  }

  double _computeInitialThreshold(List<double> squared) {
    // Use the mean + 0.5×stddev of the first 2 seconds as the seed
    final int window = min(squared.length, (_fps * 2).round());
    final List<double> slice = squared.sublist(0, window);
    double mean = slice.reduce((a, b) => a + b) / slice.length;
    double variance =
        slice.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            slice.length;
    return mean + 0.5 * sqrt(variance);
  }

  // ── RR-interval helpers ───────────────────────────────────────────────────

  List<double> _peaksToRrIntervals(List<int> peaks, double fs) {
    final List<double> rr = [];
    for (int i = 1; i < peaks.length; i++) {
      final double rrSec = (peaks[i] - peaks[i - 1]) / fs;
      if (rrSec >= _minRrSeconds && rrSec <= _maxRrSeconds) {
        rr.add(rrSec);
      }
    }
    return rr;
  }

  /// Remove RR intervals that fall outside  [Q1 - 1.5×IQR, Q3 + 1.5×IQR].
  List<double> _filterRrOutliers(List<double> rr) {
    if (rr.length < 4) return rr;

    final List<double> sorted = List.from(rr)..sort();
    final double q1 = _percentile(sorted, 25);
    final double q3 = _percentile(sorted, 75);
    final double iqr = q3 - q1;

    final double lower = q1 - 1.5 * iqr;
    final double upper = q3 + 1.5 * iqr;

    return rr.where((v) => v >= lower && v <= upper).toList();
  }

  double _percentile(List<double> sorted, double p) {
    final double idx = (p / 100) * (sorted.length - 1);
    final int lo = idx.floor();
    final int hi = idx.ceil();
    if (lo == hi) return sorted[lo];
    return sorted[lo] + (sorted[hi] - sorted[lo]) * (idx - lo);
  }

  double _median(List<double> values) {
    if (values.isEmpty) return 0;
    final List<double> s = List.from(values)..sort();
    final int mid = s.length ~/ 2;
    return s.length.isOdd ? s[mid] : (s[mid - 1] + s[mid]) / 2;
  }

  // ── Signal quality ────────────────────────────────────────────────────────

  void _updateSignalQuality() {
    if (_rawBuffer.length < 30) {
      _signalQuality = 0;
      return;
    }

    // Use last 90 samples (~3 s)
    final int window = min(_rawBuffer.length, 90);
    final List<double> slice =
    _rawBuffer.sublist(_rawBuffer.length - window);

    double mean = slice.reduce((a, b) => a + b) / slice.length;
    double varianceSum = 0;
    for (double v in slice) {
      varianceSum += (v - mean) * (v - mean);
    }
    double stdDev = sqrt(varianceSum / slice.length);

    // SNR proxy: coefficient of variation (CV = σ/μ × 100 %)
    // Heart-rate signal with finger on lens: CV typically 2–20 %
    double cv = mean > 0 ? (stdDev / mean) * 100 : 0;

    if (cv > 1.5 && cv < 30 && mean > 50 && stdDev > 2) {
      _signalQuality = (cv / 15).clamp(0.0, 1.0);
    } else {
      _signalQuality = 0;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal DSP helpers
// ─────────────────────────────────────────────────────────────────────────────

class _BiquadCoeffs {
  final double b0, b1, b2, a1, a2;
  _BiquadCoeffs(this.b0, this.b1, this.b2, this.a1, this.a2);
}

class _BiquadState {
  double x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  void reset() {
    x1 = x2 = y1 = y2 = 0;
  }
}