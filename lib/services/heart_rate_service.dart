// @dart=2.10
import 'dart:math';

// Giữ enum để tương thích nếu project còn file khác tham chiếu.
enum HeartRateMeasurementState {
  idle,
  detectingFinger,
  countdown,
  collecting,
  stable,
  error,
}

class HeartRateResult {
  final int bpm;
  final bool isValid;
  final String errorMessage;
  final double signalQuality;

  /// Screen easy_tuned đang dùng field này.
  final int peakCount;

  /// Giữ lại để tương thích với code cũ nếu còn nơi khác dùng tên cũ.
  final int validPeakCount;

  final int analysisDurationMs;

  const HeartRateResult({
    this.bpm = 0,
    this.isValid = false,
    this.errorMessage = '',
    this.signalQuality = 0.0,
    this.peakCount = 0,
    this.validPeakCount = 0,
    this.analysisDurationMs = 0,
  });
}

class HeartRateException implements Exception {
  final String message;
  final String code;

  const HeartRateException(this.message, [this.code = 'UNKNOWN']);

  @override
  String toString() {
    return 'HeartRateException: $message ($code)';
  }
}

class HeartRateService {
  static const int _maxBufferSize = 900; // ~30 s @ 30 fps
  static const int _minSamplesForCalc = 100; // ~3.3 s @ 30 fps
  static const int _minAnalysisMs = 3200;
  static const double _targetResampleHz = 30.0;
  static const double _analysisWindowSec = 6.5;

  static const double _minBpm = 40.0;
  static const double _maxBpm = 180.0;

  static const double _bpLowHz = 0.7;
  static const double _bpHighHz = 3.0;

  static const double _refractorySec = 0.30;
  static const int _minValidPeakCount = 4;
  static const double _peakThresholdBias = 0.05;

  static const int _bpmHistoryMax = 10;
  static const double _smoothingOldWeight = 0.80;
  static const double _smoothingNewWeight = 0.20;

  // Nới nhẹ để khớp với heartRateScreen_easy_tuned.dart.
  static const double _fingerDcMin = 65.0;
  static const double _fingerDcMax = 253.0;
  static const double _fingerRatioMin = 0.85;
  static const double _minQualityForValid = 0.34;

  final List<double> _rawBuffer = <double>[];
  final List<int> _timestamps = <int>[];
  final List<double> _greenBuffer = <double>[];
  final List<double> _redBuffer = <double>[];

  final List<double> _filteredBuffer = <double>[];
  double _emaPrev = 0.0;
  double _dcPrev = 0.0;
  bool _hasRealtimeSeed = false;

  final List<int> _bpmHistory = <int>[];
  int _lastValidBpm = 0;
  int _lastPeakCount = 0;
  int _analysisDurationMs = 0;
  double _signalQuality = 0.0;
  bool _forceStart = false;

  void reset() {
    _rawBuffer.clear();
    _timestamps.clear();
    _greenBuffer.clear();
    _redBuffer.clear();
    _filteredBuffer.clear();
    _bpmHistory.clear();

    _emaPrev = 0.0;
    _dcPrev = 0.0;
    _hasRealtimeSeed = false;

    _lastValidBpm = 0;
    _lastPeakCount = 0;
    _analysisDurationMs = 0;
    _signalQuality = 0.0;
    _forceStart = false;
  }

  void enableForceStart() {
    _forceStart = true;
  }

  bool shouldProcessFrame(int currentTimeMs) {
    if (_timestamps.isEmpty) return true;
    return (currentTimeMs - _timestamps.last) >= 33;
  }

void addSample(
      double intensity, {
      int timestamp = 0,
      double greenValue = 0.0,
      double redValue = 0.0,
    }) {
    final int ts = timestamp != null
        ? timestamp
        : DateTime.now().millisecondsSinceEpoch;

    if (_timestamps.isNotEmpty && ts <= _timestamps.last) {
      _appendSample(
        intensity,
        _timestamps.last + 1,
        greenValue,
        redValue,
      );
      return;
    }

    _appendSample(intensity, ts, greenValue, redValue);
  }

  HeartRateResult calculateHeartRate() {
    if (_rawBuffer.length < _minSamplesForCalc ||
        _timestamps.length < _minSamplesForCalc) {
      return HeartRateResult(
        isValid: false,
        errorMessage: 'Đang thu tín hiệu…',
        signalQuality: _signalQuality,
        peakCount: _lastPeakCount,
        validPeakCount: _lastPeakCount,
        analysisDurationMs: _analysisDurationMs,
      );
    }

    if (!_forceStart && !isFingerDetected()) {
      _signalQuality = 0.0;
      _lastPeakCount = 0;
      return HeartRateResult(
        isValid: false,
        errorMessage: 'Chưa nhận được tín hiệu ngón tay ổn định.',
        signalQuality: _signalQuality,
        peakCount: _lastPeakCount,
        validPeakCount: _lastPeakCount,
        analysisDurationMs: _analysisDurationMs,
      );
    }

    if (_timestamps.length >= 2) {
      _analysisDurationMs = _timestamps.last - _timestamps.first;
    } else {
      _analysisDurationMs = 0;
    }

    if (_analysisDurationMs < _minAnalysisMs) {
      return HeartRateResult(
        isValid: false,
        errorMessage: 'Cần thêm vài giây tín hiệu ổn định.',
        signalQuality: _signalQuality,
        peakCount: _lastPeakCount,
        validPeakCount: _lastPeakCount,
        analysisDurationMs: _analysisDurationMs,
      );
    }

    final _PreparedSignal prepared = _prepareAnalysisSignal();
    if (prepared == null || prepared.values.length < 120) {
      _signalQuality = 0.0;
      _lastPeakCount = 0;
      return HeartRateResult(
        isValid: false,
        errorMessage: 'Dữ liệu chưa đủ ổn định để phân tích.',
        signalQuality: _signalQuality,
        peakCount: _lastPeakCount,
        validPeakCount: _lastPeakCount,
        analysisDurationMs: _analysisDurationMs,
      );
    }

    final List<double> filtered = _bandpassZeroPhase(
      prepared.values,
      prepared.sampleRateHz,
      _bpLowHz,
      _bpHighHz,
    );
    final List<double> normalized = _robustNormalize(filtered);

    final _PeakResult peakResult =
    _detectPeaks(normalized, prepared.sampleRateHz);
    _lastPeakCount = peakResult.peakTimesSec.length;

    final int bpmFromPeaks = _bpmFromPeakTimes(peakResult.peakTimesSec);
    final _AcfResult acfResult =
    _bpmFromAutocorrelation(normalized, prepared.sampleRateHz);

    final double quality = _evaluateQuality(
      signal: normalized,
      peakTimesSec: peakResult.peakTimesSec,
      peakProminences: peakResult.prominences,
      bpmFromPeaks: bpmFromPeaks,
      acf: acfResult,
    );
    _signalQuality = quality;

    if (_lastPeakCount < _minValidPeakCount) {
      return HeartRateResult(
        isValid: false,
        errorMessage: 'Chưa đủ nhịp hợp lệ để hiển thị BPM.',
        signalQuality: _signalQuality,
        peakCount: _lastPeakCount,
        validPeakCount: _lastPeakCount,
        analysisDurationMs: _analysisDurationMs,
      );
    }

    if (quality < _minQualityForValid) {
      return HeartRateResult(
        isValid: false,
        errorMessage: 'Tín hiệu chưa đủ sạch. Giữ yên tay và che kín camera.',
        signalQuality: _signalQuality,
        peakCount: _lastPeakCount,
        validPeakCount: _lastPeakCount,
        analysisDurationMs: _analysisDurationMs,
      );
    }

    final int bpm = _pickFinalBpm(
      bpmFromPeaks: bpmFromPeaks,
      acfResult: acfResult,
      quality: quality,
    );

    if (bpm < _minBpm || bpm > _maxBpm) {
      return HeartRateResult(
        isValid: false,
        errorMessage: 'Không xác định được nhịp tim đáng tin cậy.',
        signalQuality: _signalQuality,
        peakCount: _lastPeakCount,
        validPeakCount: _lastPeakCount,
        analysisDurationMs: _analysisDurationMs,
      );
    }

    final int stableBpm = _smoothBpm(bpm);
    _lastValidBpm = stableBpm;
    _bpmHistory.add(stableBpm);
    _trimList(_bpmHistory, _bpmHistoryMax);

    return HeartRateResult(
      bpm: stableBpm,
      isValid: true,
      signalQuality: _signalQuality,
      peakCount: _lastPeakCount,
      validPeakCount: _lastPeakCount,
      analysisDurationMs: _analysisDurationMs,
    );
  }

  bool isFingerDetected() {
    if (_forceStart) return true;
    if (_rawBuffer.length < 20) return false;

    final int n = min(20, _rawBuffer.length);
    final double dc = _mean(_rawBuffer.sublist(_rawBuffer.length - n));
    if (dc < _fingerDcMin || dc >= _fingerDcMax) return false;

    if (_greenBuffer.length >= 20 && _redBuffer.length >= 20) {
      final int m = min(20, min(_greenBuffer.length, _redBuffer.length));
      final double g = _mean(_greenBuffer.sublist(_greenBuffer.length - m));
      final double r = _mean(_redBuffer.sublist(_redBuffer.length - m));
      if (r / (g + 1.0) < _fingerRatioMin) return false;
    }

    return true;
  }

  bool isSignalValid() {
    if (_rawBuffer.length < _minSamplesForCalc) return false;
    if (_forceStart) return true;
    return _signalQuality >= _minQualityForValid &&
        _lastPeakCount >= _minValidPeakCount;
  }

  double get signalQuality => _signalQuality;
  int get sampleCount => _rawBuffer.length;
  int get bufferLength => _rawBuffer.length;
  int get validPeakCount => _lastPeakCount;
  int get peakCount => _lastPeakCount;
  int get analysisDurationMs => _analysisDurationMs;
  int get lastValidBpm => _lastValidBpm;
  List<double> getSignalBuffer() => List<double>.unmodifiable(_rawBuffer);
  List<double> getFilteredBuffer() => List<double>.unmodifiable(_filteredBuffer);

  void _appendSample(
      double intensity,
      int ts,
      double greenValue,
      double redValue,
      ) {
    _rawBuffer.add(intensity);
    _timestamps.add(ts);
    _trimList(_rawBuffer, _maxBufferSize);
    _trimList(_timestamps, _maxBufferSize);

    if (greenValue != null && redValue != null) {
      _greenBuffer.add(greenValue);
      _redBuffer.add(redValue);
      _trimList(_greenBuffer, _maxBufferSize);
      _trimList(_redBuffer, _maxBufferSize);
    }

    _updateRealtimeFilter(intensity);
    _signalQuality = _quickRealtimeQuality();
    if (_timestamps.length >= 2) {
      _analysisDurationMs = _timestamps.last - _timestamps.first;
    }
  }

  // Filter realtime tối thiểu theo yêu cầu: 0.85 * prev + 0.15 * current.
  // Sau đó trừ DC chậm để lấy thành phần nhịp.
  void _updateRealtimeFilter(double x) {
    if (!_hasRealtimeSeed) {
      _emaPrev = x;
      _dcPrev = x;
      _hasRealtimeSeed = true;
    } else {
      _emaPrev = 0.85 * _emaPrev + 0.15 * x;
      _dcPrev = 0.95 * _dcPrev + 0.05 * x;
    }

    final double band = _emaPrev - _dcPrev;
    _filteredBuffer.add(band);
    _trimList(_filteredBuffer, _maxBufferSize);
  }

  double _quickRealtimeQuality() {
    if (_filteredBuffer.length < 45) return 0.0;
    final int n = min(120, _filteredBuffer.length);
    final List<double> recent =
    _filteredBuffer.sublist(_filteredBuffer.length - n);

    final double mn = _mean(recent);
    final double sd = _stdDev(recent, mn);
    final double mad = _medianAbsoluteDeviation(recent);
    final double p05 = _percentile(recent, 0.05);
    final double p95 = _percentile(recent, 0.95);
    final double amplitude = (p95 - p05).abs();

    final double score = _clampDouble(amplitude / 1.8, 0.0, 1.0) * 0.45 +
        _clampDouble(sd / 0.40, 0.0, 1.0) * 0.35 +
        _clampDouble(mad / 0.18, 0.0, 1.0) * 0.20;
    return _clampDouble(score, 0.0, 1.0);
  }

  _PreparedSignal _prepareAnalysisSignal() {
    if (_rawBuffer.length < 20 || _timestamps.length < 20) return null;

    final int endTs = _timestamps.last;
    final int startTs = endTs - (_analysisWindowSec * 1000.0).round();

    int startIndex = 0;
    while (startIndex < _timestamps.length - 1 &&
        _timestamps[startIndex] < startTs) {
      startIndex++;
    }

    final List<int> ts = _timestamps.sublist(startIndex);
    final List<double> x = _rawBuffer.sublist(startIndex);
    if (ts.length < 20 || x.length != ts.length) return null;

    final List<int> cleanTs = <int>[];
    final List<double> cleanX = <double>[];
    int i;
    for (i = 0; i < ts.length; i++) {
      if (cleanTs.isEmpty || ts[i] > cleanTs.last) {
        cleanTs.add(ts[i]);
        cleanX.add(x[i]);
      }
    }
    if (cleanTs.length < 20) return null;

    final List<double> detrended = _removeLinearTrend(cleanTs, cleanX);
    final _ResampledSignal resampled = _resampleLinear(
      cleanTs,
      detrended,
      _targetResampleHz,
    );
    if (resampled == null || resampled.values.length < 120) return null;

    return _PreparedSignal(
      values: resampled.values,
      sampleRateHz: resampled.sampleRateHz,
    );
  }

  List<double> _bandpassZeroPhase(
      List<double> signal,
      double sampleRateHz,
      double lowHz,
      double highHz,
      ) {
    if (signal.length < 6) return List<double>.from(signal);

    final int pad = min(
      signal.length - 1,
      max(12, (sampleRateHz * 1.2).round()),
    );
    final List<double> padded = _reflectPad(signal, pad);

    List<double> y = _applyHighPass(
      padded,
      _highPassAlpha(lowHz, sampleRateHz),
    );
    y = _applyHighPass(
      y.reversed.toList(),
      _highPassAlpha(lowHz, sampleRateHz),
    ).reversed.toList();
    y = _applyLowPass(y, _lowPassAlpha(highHz, sampleRateHz));
    y = _applyLowPass(
      y.reversed.toList(),
      _lowPassAlpha(highHz, sampleRateHz),
    ).reversed.toList();

    return y.sublist(pad, pad + signal.length);
  }

  List<double> _applyHighPass(List<double> s, double alpha) {
    final List<double> out = List<double>.filled(s.length, 0.0);
    out[0] = 0.0;
    int i;
    for (i = 1; i < s.length; i++) {
      out[i] = alpha * (out[i - 1] + s[i] - s[i - 1]);
    }
    return out;
  }

  List<double> _applyLowPass(List<double> s, double alpha) {
    final List<double> out = List<double>.filled(s.length, 0.0);
    out[0] = s[0];
    int i;
    for (i = 1; i < s.length; i++) {
      out[i] = alpha * s[i] + (1.0 - alpha) * out[i - 1];
    }
    return out;
  }

  static List<double> _reflectPad(List<double> s, int pad) {
    if (pad <= 0 || s.length < 2) return List<double>.from(s);
    final List<double> out = <double>[];
    int i;

    for (i = pad; i >= 1; i--) {
      final int idx = min(i, s.length - 1);
      out.add(s[idx]);
    }
    out.addAll(s);
    for (i = s.length - 2; i >= max(0, s.length - 1 - pad); i--) {
      out.add(s[i]);
    }
    return out;
  }

  static double _highPassAlpha(double cutoffHz, double sampleRateHz) {
    final double rc = 1.0 / (2.0 * pi * cutoffHz);
    final double dt = 1.0 / sampleRateHz;
    return rc / (rc + dt);
  }

  static double _lowPassAlpha(double cutoffHz, double sampleRateHz) {
    final double rc = 1.0 / (2.0 * pi * cutoffHz);
    final double dt = 1.0 / sampleRateHz;
    return dt / (rc + dt);
  }

  _PeakResult _detectPeaks(List<double> signal, double sampleRateHz) {
    final List<int> peaks = <int>[];
    final List<double> prominences = <double>[];

    if (signal.length < 5) {
      return _PeakResult(
        indices: peaks,
        peakTimesSec: const <double>[],
        prominences: prominences,
      );
    }

    final List<double> smooth = _medianSmooth3(signal);
    final int refractorySamples =
    max(1, (sampleRateHz * _refractorySec).round());
    final double mn = _mean(smooth);
    final double sd = _stdDev(smooth, mn);
    final double threshold = mn + max(_peakThresholdBias, sd * 0.12);

    int lastAccepted = -refractorySamples * 2;
    int i;
    for (i = 1; i < smooth.length - 1; i++) {
      final double prev = smooth[i - 1];
      final double curr = smooth[i];
      final double next = smooth[i + 1];

      if (!(curr > prev && curr >= next)) continue;
      if (curr < threshold) continue;

      final double leftBase = i >= 2 ? min(prev, smooth[i - 2]) : prev;
      final double rightBase = i <= smooth.length - 3
          ? min(next, smooth[i + 2])
          : next;
      final double prominence = curr - max(leftBase, rightBase);
      if (prominence < 0.04) continue;

      if (peaks.isNotEmpty && i - lastAccepted < refractorySamples) {
        if (curr > smooth[peaks.last]) {
          peaks[peaks.length - 1] = i;
          prominences[prominences.length - 1] = prominence;
          lastAccepted = i;
        }
        continue;
      }

      peaks.add(i);
      prominences.add(prominence);
      lastAccepted = i;
    }

    final List<double> peakTimesSec = <double>[];
    for (i = 0; i < peaks.length; i++) {
      peakTimesSec.add(peaks[i] / sampleRateHz);
    }

    return _PeakResult(
      indices: peaks,
      peakTimesSec: peakTimesSec,
      prominences: prominences,
    );
  }

  int _bpmFromPeakTimes(List<double> peakTimesSec) {
    if (peakTimesSec.length < 3) return 0;

    final List<double> ibis = <double>[];
    int i;
    for (i = 1; i < peakTimesSec.length; i++) {
      final double ibi = peakTimesSec[i] - peakTimesSec[i - 1];
      if (ibi <= 0) continue;
      final double bpm = 60.0 / ibi;
      if (bpm >= _minBpm && bpm <= _maxBpm && ibi >= _refractorySec) {
        ibis.add(ibi);
      }
    }

    if (ibis.length < 2) return 0;
    final List<double> cleaned = _trimOutliersIqr(ibis);
    final List<double> src = cleaned.length >= 2 ? cleaned : ibis;
    final double meanIbi = _mean(src);
    if (meanIbi <= 0) return 0;
    return (60.0 / meanIbi).round();
  }

  _AcfResult _bpmFromAutocorrelation(List<double> signal, double sampleRateHz) {
    if (signal.length < 90) {
      return const _AcfResult(bpm: 0, periodicity: 0.0);
    }

    final int lagMin = max(1, (sampleRateHz * 60.0 / _maxBpm).round());
    final int lagMax = min(
      (sampleRateHz * 60.0 / _minBpm).round(),
      signal.length ~/ 2,
    );
    if (lagMin >= lagMax) {
      return const _AcfResult(bpm: 0, periodicity: 0.0);
    }

    final double mn = _mean(signal);
    double variance = 0.0;
    int i;
    for (i = 0; i < signal.length; i++) {
      final double d = signal[i] - mn;
      variance += d * d;
    }
    if (variance <= 1e-12) {
      return const _AcfResult(bpm: 0, periodicity: 0.0);
    }

    int bestLag = lagMin;
    double bestVal = -1.0;
    int lag;
    for (lag = lagMin; lag <= lagMax; lag++) {
      double sum = 0.0;
      final int n = signal.length - lag;
      for (i = 0; i < n; i++) {
        sum += (signal[i] - mn) * (signal[i + lag] - mn);
      }
      final double val = sum / variance;
      if (val > bestVal) {
        bestVal = val;
        bestLag = lag;
      }
    }

    if (bestVal < 0.10) {
      return _AcfResult(
        bpm: 0,
        periodicity: _clampDouble(bestVal, 0.0, 1.0),
      );
    }

    final double bpm = 60.0 * sampleRateHz / bestLag;
    if (bpm < _minBpm || bpm > _maxBpm) {
      return _AcfResult(
        bpm: 0,
        periodicity: _clampDouble(bestVal, 0.0, 1.0),
      );
    }

    return _AcfResult(
      bpm: bpm.round(),
      periodicity: _clampDouble(bestVal, 0.0, 1.0),
    );
  }

  double _evaluateQuality({
    List<double> signal,
    List<double> peakTimesSec,
    List<double> peakProminences,
    int bpmFromPeaks,
    _AcfResult acf,
  }) {
    final double amplitude =
        _percentile(signal, 0.95) - _percentile(signal, 0.05);
    final double amplitudeScore = _clampDouble(amplitude / 1.2, 0.0, 1.0);

    double peakCountScore = 0.0;
    double ibiStabilityScore = 0.0;
    double prominenceScore = 0.0;

    if (peakTimesSec.length >= 3) {
      final List<double> ibis = <double>[];
      int i;
      for (i = 1; i < peakTimesSec.length; i++) {
        final double ibi = peakTimesSec[i] - peakTimesSec[i - 1];
        if (ibi > 0) ibis.add(ibi);
      }

      final List<double> cleanIbis = _trimOutliersIqr(ibis);
      final List<double> src = cleanIbis.length >= 2 ? cleanIbis : ibis;
      if (src.isNotEmpty) {
        final double meanIbi = _mean(src);
        final double sdIbi = _stdDev(src, meanIbi);
        final double cv = meanIbi > 0 ? sdIbi / meanIbi : 1.0;
        ibiStabilityScore = _clampDouble(1.0 - (cv / 0.25), 0.0, 1.0);
      }

      peakCountScore =
          _clampDouble((peakTimesSec.length - 2).toDouble() / 4.0, 0.0, 1.0);
    }

    if (peakProminences.isNotEmpty) {
      final double medProm = _medianDouble(peakProminences);
      prominenceScore = _clampDouble(medProm / 0.22, 0.0, 1.0);
    }

    double agreementScore = 0.0;
    if (bpmFromPeaks > 0 && acf.bpm > 0) {
      final double diff = (bpmFromPeaks - acf.bpm).abs().toDouble();
      agreementScore = _clampDouble(1.0 - diff / 12.0, 0.0, 1.0);
    } else if (bpmFromPeaks > 0 || acf.bpm > 0) {
      agreementScore = 0.40;
    }

    final double periodicityScore = _clampDouble(acf.periodicity, 0.0, 1.0);

    final double score =
        amplitudeScore * 0.18 +
            peakCountScore * 0.22 +
            ibiStabilityScore * 0.23 +
            prominenceScore * 0.17 +
            periodicityScore * 0.12 +
            agreementScore * 0.08;

    return _clampDouble(score, 0.0, 1.0);
  }

  int _pickFinalBpm({
    int bpmFromPeaks,
    _AcfResult acfResult,
    double quality,
  }) {
    final bool peakOk = bpmFromPeaks >= _minBpm && bpmFromPeaks <= _maxBpm;
    final bool acfOk =
        acfResult.bpm >= _minBpm && acfResult.bpm <= _maxBpm;

    if (!peakOk && !acfOk) return 0;
    if (peakOk && !acfOk) return bpmFromPeaks;
    if (!peakOk && acfOk) return acfResult.bpm;

    final int peakBpm = bpmFromPeaks;
    final int acfBpm = acfResult.bpm;

    if ((peakBpm - acfBpm).abs() <= 6) {
      return ((peakBpm + acfBpm) / 2.0).round();
    }

    if (_bpmHistory.isNotEmpty) {
      final double hist = _medianInt(_bpmHistory).toDouble();
      final double dPeak = (peakBpm - hist).abs().toDouble();
      final double dAcf = (acfBpm - hist).abs().toDouble();
      if ((dPeak - dAcf).abs() >= 4.0) {
        return dPeak <= dAcf ? peakBpm : acfBpm;
      }
    }

    if (quality >= 0.75) return peakBpm;
    return peakBpm;
  }

  int _smoothBpm(int rawBpm) {
    if (rawBpm < _minBpm || rawBpm > _maxBpm) return 0;
    if (_bpmHistory.isEmpty) return rawBpm;

    final double prev = _bpmHistory.last.toDouble();
    final double blended =
        prev * _smoothingOldWeight + rawBpm * _smoothingNewWeight;
    return _clampInt(
      blended.round(),
      _minBpm.round(),
      _maxBpm.round(),
    );
  }

  static _ResampledSignal _resampleLinear(
      List<int> timestampsMs,
      List<double> values,
      double sampleRateHz,
      ) {
    if (timestampsMs.length < 2 || values.length != timestampsMs.length) {
      return null;
    }

    final double startSec = timestampsMs.first / 1000.0;
    final double endSec = timestampsMs.last / 1000.0;
    final double durationSec = endSec - startSec;
    if (durationSec <= 1.0) return null;

    final double dt = 1.0 / sampleRateHz;
    final int outCount = (durationSec / dt).floor() + 1;
    if (outCount < 30) return null;

    final List<double> out = List<double>.filled(outCount, 0.0);
    int j = 0;
    int i;
    for (i = 0; i < outCount; i++) {
      final double t = startSec + i * dt;
      while (j < timestampsMs.length - 2 &&
          timestampsMs[j + 1] / 1000.0 < t) {
        j++;
      }
      final double t0 = timestampsMs[j] / 1000.0;
      final double t1 = timestampsMs[j + 1] / 1000.0;
      final double x0 = values[j];
      final double x1 = values[j + 1];
      if ((t1 - t0).abs() < 1e-9) {
        out[i] = x0;
      } else {
        final double w = _clampDouble((t - t0) / (t1 - t0), 0.0, 1.0);
        out[i] = x0 + (x1 - x0) * w;
      }
    }

    return _ResampledSignal(values: out, sampleRateHz: sampleRateHz);
  }

  static List<double> _removeLinearTrend(
      List<int> timestampsMs,
      List<double> values,
      ) {
    if (timestampsMs.length != values.length || values.length < 2) {
      return List<double>.from(values);
    }

    final double t0 = timestampsMs.first / 1000.0;
    final List<double> t = <double>[];
    int i;
    for (i = 0; i < timestampsMs.length; i++) {
      t.add(timestampsMs[i] / 1000.0 - t0);
    }

    final double mt = _mean(t);
    final double mx = _mean(values);

    double cov = 0.0;
    double varT = 0.0;
    for (i = 0; i < values.length; i++) {
      final double dt = t[i] - mt;
      cov += dt * (values[i] - mx);
      varT += dt * dt;
    }

    final double slope = varT.abs() < 1e-12 ? 0.0 : cov / varT;
    final double intercept = mx - slope * mt;

    final List<double> out = List<double>.filled(values.length, 0.0);
    for (i = 0; i < values.length; i++) {
      final double trend = intercept + slope * t[i];
      out[i] = values[i] - trend;
    }
    return out;
  }

  static List<double> _robustNormalize(List<double> s) {
    if (s.isEmpty) return const <double>[];
    final double p05 = _percentile(s, 0.05);
    final double p95 = _percentile(s, 0.95);
    final double scale = (p95 - p05).abs();
    if (scale < 1e-9) return List<double>.filled(s.length, 0.0);
    final double center = _medianDouble(s);

    final List<double> out = List<double>.filled(s.length, 0.0);
    int i;
    for (i = 0; i < s.length; i++) {
      out[i] = _clampDouble((s[i] - center) / scale, -1.5, 1.5);
    }
    return out;
  }

  static List<double> _trimOutliersIqr(List<double> values) {
    if (values.length < 4) return List<double>.from(values);
    final List<double> s = List<double>.from(values)..sort();
    final double q1 = _percentileSorted(s, 0.25);
    final double q3 = _percentileSorted(s, 0.75);
    final double iqr = q3 - q1;
    final double lo = q1 - 1.5 * iqr;
    final double hi = q3 + 1.5 * iqr;

    final List<double> out = <double>[];
    int i;
    for (i = 0; i < s.length; i++) {
      if (s[i] >= lo && s[i] <= hi) out.add(s[i]);
    }
    return out;
  }

  static double _percentile(List<double> values, double p) {
    final List<double> s = List<double>.from(values)..sort();
    return _percentileSorted(s, p);
  }

  static double _percentileSorted(List<double> sortedValues, double p) {
    if (sortedValues.isEmpty) return 0.0;
    if (sortedValues.length == 1) return sortedValues.first;
    final double pos = (sortedValues.length - 1) * _clampDouble(p, 0.0, 1.0);
    final int lo = pos.floor();
    final int hi = pos.ceil();
    if (lo == hi) return sortedValues[lo];
    final double w = pos - lo;
    return sortedValues[lo] * (1.0 - w) + sortedValues[hi] * w;
  }

  static double _mean(List<double> s) {
    if (s.isEmpty) return 0.0;
    double sum = 0.0;
    int i;
    for (i = 0; i < s.length; i++) {
      sum += s[i];
    }
    return sum / s.length;
  }

  static double _stdDev(List<double> s, double mean) {
    if (s.length < 2) return 0.0;
    double sum = 0.0;
    int i;
    for (i = 0; i < s.length; i++) {
      final double d = s[i] - mean;
      sum += d * d;
    }
    return sqrt(sum / s.length);
  }

  static double _medianDouble(List<double> s) {
    if (s.isEmpty) return 0.0;
    final List<double> a = List<double>.from(s)..sort();
    final int mid = a.length ~/ 2;
    if (a.length.isOdd) return a[mid];
    return (a[mid - 1] + a[mid]) / 2.0;
  }

  static int _medianInt(List<int> s) {
    if (s.isEmpty) return 0;
    final List<int> a = List<int>.from(s)..sort();
    final int mid = a.length ~/ 2;
    if (a.length.isOdd) return a[mid];
    return ((a[mid - 1] + a[mid]) / 2.0).round();
  }

  static double _medianAbsoluteDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;
    final double med = _medianDouble(values);
    final List<double> dev = <double>[];
    int i;
    for (i = 0; i < values.length; i++) {
      dev.add((values[i] - med).abs());
    }
    return _medianDouble(dev);
  }

  static List<double> _medianSmooth3(List<double> s) {
    if (s.length < 3) return List<double>.from(s);
    final List<double> out = List<double>.from(s);
    int i;
    for (i = 1; i < s.length - 1; i++) {
      final List<double> w = <double>[s[i - 1], s[i], s[i + 1]]..sort();
      out[i] = w[1];
    }
    return out;
  }

  static void _trimList(List list, int maxSize) {
    if (maxSize <= 0) return;
    final int extra = list.length - maxSize;
    if (extra > 0) {
      list.removeRange(0, extra);
    }
  }

  static double _clampDouble(double value, double minValue, double maxValue) {
    if (value < minValue) return minValue;
    if (value > maxValue) return maxValue;
    return value;
  }

  static int _clampInt(int value, int minValue, int maxValue) {
    if (value < minValue) return minValue;
    if (value > maxValue) return maxValue;
    return value;
  }
}

class _PreparedSignal {
  final List<double> values;
  final double sampleRateHz;

  const _PreparedSignal({
    this.values,
    this.sampleRateHz,
  });
}

class _ResampledSignal {
  final List<double> values;
  final double sampleRateHz;

  const _ResampledSignal({
    this.values,
    this.sampleRateHz,
  });
}

class _PeakResult {
  final List<int> indices;
  final List<double> peakTimesSec;
  final List<double> prominences;

  const _PeakResult({
    this.indices,
    this.peakTimesSec,
    this.prominences,
  });
}

class _AcfResult {
  final int bpm;
  final double periodicity;

  const _AcfResult({
    this.bpm,
    this.periodicity,
  });
}
