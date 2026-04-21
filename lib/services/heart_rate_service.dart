import 'dart:math';

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

class HeartRateService {
  static const int _bufferSize = 450;
  static const double _minBpm = 35.0;
  static const double _maxBpm = 220.0;
  static const double _sampleRate = 10.0;
  static const int _minBufferForCalc = 200;

  final List<double> _rawBuffer = [];
  final List<double> _filteredBuffer = [];
  final List<int> _timestamps = [];
  final List<int> _bpmReadings = [];
  
  double _dcComponent = 0;
  double _acComponent = 0;
  double _signalQuality = 0;

  void reset() {
    _rawBuffer.clear();
    _filteredBuffer.clear();
    _timestamps.clear();
    _bpmReadings.clear();
    _dcComponent = 0;
    _acComponent = 0;
    _signalQuality = 0;
  }

  bool shouldProcessFrame(int currentTime) {
    if (_timestamps.isEmpty) return true;
    return currentTime - _timestamps.last >= 100;
  }

  void addSample(double greenIntensity, {int timestamp}) {
    _rawBuffer.add(greenIntensity);
    _timestamps.add(timestamp ?? DateTime.now().millisecondsSinceEpoch);

    if (_rawBuffer.length > _bufferSize) {
      _rawBuffer.removeAt(0);
      _timestamps.removeAt(0);
    }

    if (_rawBuffer.length >= 50) {
      _filteredBuffer.addAll(_applyAdvancedFilter(List.from(_rawBuffer)));
      if (_filteredBuffer.length > _bufferSize) {
        _filteredBuffer.removeRange(0, _filteredBuffer.length - _bufferSize);
      }
    }

    _calculateSignalQuality();
  }

  void _calculateSignalQuality() {
    if (_rawBuffer.length < 50) {
      _signalQuality = 0;
      return;
    }

    double sum = 0;
    for (double v in _rawBuffer) sum += v;
    double mean = sum / _rawBuffer.length;

    double varianceSum = 0;
    for (double v in _rawBuffer) {
      varianceSum += (v - mean) * (v - mean);
    }
    double stdDev = sqrt(varianceSum / _rawBuffer.length);

    double snr = stdDev > 0 ? (stdDev / mean) * 100 : 0;
    
    _dcComponent = mean;
    _acComponent = stdDev;

    if (snr > 2 && snr < 25 && mean > 60 && stdDev > 5) {
      _signalQuality = min(1.0, snr / 10);
    } else {
      _signalQuality = 0;
    }
  }

  bool isFingerDetected() {
    if (_rawBuffer.isEmpty) return false;
    return _dcComponent > 70 && _acComponent < 100;
  }

  bool isSignalValid() {
    return _rawBuffer.length >= _minBufferForCalc &&
           _dcComponent > 50 &&
           _acComponent > 3 &&
           _acComponent < 120 &&
           _signalQuality > 0.1;
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

    List<double> signal = List.from(_filteredBuffer);
    if (signal.length < 100) {
      return HeartRateResult(
        isValid: false,
        errorMessage: 'Chưa đủ dữ liệu. Tiếp tục giữ ngón tay.',
        signalQuality: _signalQuality,
      );
    }

    signal = _removeOutliers(signal);
    signal = _applyBandpassFilter(signal);

    int bpmFFT = _calculateHeartRateFFT(signal);
    int bpmPeak = 0;
    
    List<int> peaks = _findPeaksAdvanced(signal);
    if (peaks.length >= 3) {
      bpmPeak = _calculateBpmFromPeaks(peaks);
    }

    int finalBpm = _selectBestBpm(bpmFFT, bpmPeak);

    if (finalBpm > 0 && _validateBpm(finalBpm)) {
      _bpmReadings.add(finalBpm);
      if (_bpmReadings.length > 10) {
        _bpmReadings.removeAt(0);
      }
      int averagedBpm = _getAveragedBpm();
      
      return HeartRateResult(
        bpm: averagedBpm,
        isValid: true,
        signalQuality: _signalQuality,
      );
    }

    return HeartRateResult(
      isValid: false,
      errorMessage: 'Không tìm thấy nhịp tim hợp lệ. Thử lại.',
      signalQuality: _signalQuality,
    );
  }

  List<double> _applyAdvancedFilter(List<double> input) {
    if (input.length < 3) return input;
    
    List<double> output = [];
    double prev = input[0];
    
    for (int i = 0; i < input.length; i++) {
      double current = input[i];
      double alpha = 0.95;
      double filtered = alpha * prev + (1 - alpha) * current;
      output.add(filtered);
      prev = filtered;
    }
    
    return output;
  }

  List<double> _removeOutliers(List<double> signal) {
    if (signal.length < 30) return signal;
    
    List<double> result = List.from(signal);
    int windowSize = 5;
    
    for (int i = windowSize; i < result.length - windowSize; i++) {
      double sum = 0;
      for (int j = i - windowSize; j <= i + windowSize; j++) {
        sum += result[j];
      }
      double median = sum / (windowSize * 2 + 1);
      
      if ((result[i] - median).abs() > median * 0.3) {
        result[i] = median;
      }
    }
    
    return result;
  }

  List<double> _applyBandpassFilter(List<double> signal) {
    if (signal.length < 10) return signal;

    List<double> highPass = [];
    double prev = signal[0];
    double prev2 = signal[0];
    
    for (int i = 1; i < signal.length; i++) {
      double hp = 0.95 * (prev2 + signal[i] - prev);
      highPass.add(hp);
      prev2 = prev;
      prev = signal[i];
    }

    List<double> lowPass = [];
    prev = highPass.isNotEmpty ? highPass[0] : signal[0];
    
    for (int i = 0; i < highPass.length; i++) {
      double lp = 0.85 * prev + 0.15 * highPass[i];
      lowPass.add(lp);
      prev = lp;
    }

    return lowPass;
  }

  List<int> _findPeaksAdvanced(List<double> signal) {
    List<int> peaks = [];
    if (signal.length < 5) return peaks;

    double mean = 0;
    for (double v in signal) mean += v;
    mean /= signal.length;

    double threshold = mean + _acComponent * 0.3;

    for (int i = 2; i < signal.length - 2; i++) {
      bool isPeak = signal[i] > signal[i-1] && 
                    signal[i] > signal[i+1] &&
                    signal[i] > signal[i-2] &&
                    signal[i] > signal[i+2] &&
                    signal[i] > threshold;
      
      if (isPeak) {
        if (peaks.isEmpty || (i - peaks.last) > 10) {
          peaks.add(i);
        } else if (signal[i] > signal[peaks.last]) {
          peaks[peaks.length - 1] = i;
        }
      }
    }

    return peaks;
  }

  int _calculateBpmFromPeaks(List<int> peaks) {
    if (peaks.length < 3) return 0;

    List<double> intervals = [];
    for (int i = 1; i < peaks.length; i++) {
      double interval = (peaks[i] - peaks[i - 1]) / _sampleRate;
      if (interval >= 0.3 && interval <= 2.0) {
        intervals.add(interval);
      }
    }

    if (intervals.isEmpty) return 0;

    intervals.sort();
    int midIndex = intervals.length ~/ 2;
    double medianInterval;

    if (intervals.length % 2 == 0) {
      medianInterval = (intervals[midIndex - 1] + intervals[midIndex]) / 2;
    } else {
      medianInterval = intervals[midIndex];
    }

    return (60 / medianInterval).round();
  }

  int _calculateHeartRateFFT(List<double> signal) {
    if (signal.length < 128) return 0;

    int n = 256;
    while (n > signal.length) {
      n >>= 1;
    }

    List<double> padded = List.filled(n, 0);
    for (int i = 0; i < n && i < signal.length; i++) {
      double window = 0.5 * (1 - cos(2 * pi * i / (n - 1)));
      padded[i] = signal[i] * window;
    }

    List<double> real = List.filled(n, 0);
    List<double> imag = List.filled(n, 0);

    for (int k = 0; k < n ~/ 2; k++) {
      for (int t = 0; t < n; t++) {
        double angle = 2 * pi * k * t / n;
        real[k] += padded[t] * cos(angle);
        imag[k] -= padded[t] * sin(angle);
      }
    }

    List<double> magnitude = [];
    for (int k = 1; k < n ~/ 2; k++) {
      double mag = sqrt(real[k] * real[k] + imag[k] * imag[k]);
      magnitude.add(mag);
    }

    double minFreq = (_minBpm / 60.0);
    double maxFreq = (_maxBpm / 60.0);
    int minBin = (minFreq * n / _sampleRate).floor().clamp(1, magnitude.length - 1);
    int maxBin = (maxFreq * n / _sampleRate).ceil().clamp(1, magnitude.length - 1);

    if (minBin >= maxBin) return 0;

    double maxMagnitude = 0;
    int dominantBin = minBin;

    for (int i = minBin; i <= maxBin && i < magnitude.length; i++) {
      if (magnitude[i] > maxMagnitude) {
        maxMagnitude = magnitude[i];
        dominantBin = i;
      }
    }

    if (maxMagnitude < magnitude[0] * 0.3) return 0;

    double freq = dominantBin * _sampleRate / n;
    int bpm = (freq * 60).round();

    return bpm;
  }

  int _selectBestBpm(int fftBpm, int peakBpm) {
    if (fftBpm > 0 && peakBpm > 0) {
      int diff = (fftBpm - peakBpm).abs();
      if (diff <= 5) {
        return ((fftBpm + peakBpm) / 2).round();
      }
      return fftBpm;
    }
    return fftBpm > 0 ? fftBpm : peakBpm;
  }

  bool _validateBpm(int bpm) {
    return bpm >= _minBpm && bpm <= _maxBpm;
  }

  int _getAveragedBpm() {
    if (_bpmReadings.isEmpty) return 0;
    
    if (_bpmReadings.length <= 3) {
      int sum = 0;
      for (int bpm in _bpmReadings) sum += bpm;
      return (sum / _bpmReadings.length).round();
    }

    List<int> sorted = List.from(_bpmReadings)..sort();
    int midStart = sorted.length ~/ 4;
    int midEnd = (sorted.length * 3) ~/ 4;
    
    int sum = 0;
    int count = 0;
    for (int i = midStart; i < midEnd; i++) {
      sum += sorted[i];
      count++;
    }
    
    return count > 0 ? (sum / count).round() : sorted[sorted.length ~/ 2];
  }

  List<double> getSignalBuffer() => List.unmodifiable(_rawBuffer);
  List<double> getFilteredBuffer() => List.unmodifiable(_filteredBuffer);
  int get sampleCount => _rawBuffer.length;
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
