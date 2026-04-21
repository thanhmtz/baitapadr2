import 'dart:convert';
import 'package:http/http.dart' as http;

class HeartRateReportResult {
  final int bpm;
  final String category;
  final String categoryVi;
  final String categoryZh;
  final String description;
  final String descriptionVi;
  final String descriptionZh;
  final String healthTip;
  final String healthTipVi;
  final String healthTipZh;
  final bool isFromApi;
  final String errorMessage;

  HeartRateReportResult({
    this.bpm,
    this.category,
    this.categoryVi,
    this.categoryZh,
    this.description,
    this.descriptionVi,
    this.descriptionZh,
    this.healthTip,
    this.healthTipVi,
    this.healthTipZh,
    this.isFromApi = false,
    this.errorMessage = '',
  });

  factory HeartRateReportResult.fromJson(Map<String, dynamic> json) {
    return HeartRateReportResult(
      bpm: json['bpm'] != null ? json['bpm'] as int : 0,
      category: json['category'] != null ? json['category'] as String : '',
      categoryVi: json['category_vi'] != null ? json['category_vi'] as String : '',
      categoryZh: json['category_zh'] != null ? json['category_zh'] as String : '',
      description: json['description'] != null ? json['description'] as String : '',
      descriptionVi: json['description_vi'] != null ? json['description_vi'] as String : '',
      descriptionZh: json['description_zh'] != null ? json['description_zh'] as String : '',
      healthTip: json['health_tip'] != null ? json['health_tip'] as String : '',
      healthTipVi: json['health_tip_vi'] != null ? json['health_tip_vi'] as String : '',
      healthTipZh: json['health_tip_zh'] != null ? json['health_tip_zh'] as String : '',
      isFromApi: true,
    );
  }
}

class HeartRateReportService {
  static const String _baseUrl = 'https://your-health-api.com';
  static const String _analyzeEndpoint = '/api/heart-rate/analyze';

  Future<HeartRateReportResult> getHeartRateReport(int bpm) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl + _analyzeEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'bpm': bpm}),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return HeartRateReportResult.fromJson(data);
      } else {
        throw Exception('API request failed');
      }
    } catch (e) {
      return _getLocalResult(bpm);
    }
  }

  HeartRateReportResult _getLocalResult(int bpm) {
    if (bpm < 60) {
      return HeartRateReportResult(
        bpm: bpm,
        category: 'Bradycardia',
        categoryVi: 'Nhịp tim chậm',
        categoryZh: '心动过缓',
        description: 'Your heart rate is below the normal range. This may indicate an underlying condition or be due to certain medications.',
        descriptionVi: 'Nhịp tim của bạn thấp hơn mức bình thường. Điều này có thể cho thấy một tình trạng tiềm ẩn hoặc do một số loại thuốc.',
        descriptionZh: '您的心率低于正常范围。这可能表明存在潜在疾病或由于某些药物。',
        healthTip: 'Consult a doctor if you experience dizziness or fatigue. Consider increasing light physical activity.',
        healthTipVi: 'Hãy tham khảo bác sĩ nếu bạn cảm thấy chóng mặt hoặc mệt mỏi. Hãy tăng cường hoạt động thể chất nhẹ.',
        healthTipZh: '如果您感到头晕或疲劳，请咨询医生。考虑增加轻度体育活动。',
        isFromApi: false,
      );
    } else if (bpm >= 60 && bpm <= 100) {
      return HeartRateReportResult(
        bpm: bpm,
        category: 'Healthy',
        categoryVi: 'Khỏe mạnh',
        categoryZh: '健康',
        description: 'Your heart rate is within the normal healthy range. Great job maintaining your cardiovascular health!',
        descriptionVi: 'Nhịp tim của bạn nằm trong phạm vi khỏe mạnh bình thường. Tuyệt vời! Hãy tiếp tục duy trì sức khỏe tim mạch của bạn.',
        descriptionZh: '您的心率在正常健康范围内。做得好！请继续保持您的心血管健康！',
        healthTip: 'Keep up the good work! Maintain regular exercise and a balanced diet for heart health.',
        healthTipVi: 'Hãy tiếp tục duy trì! Tập thể dục đều đặn và ăn uống cân bằng để giữ sức khỏe tim.',
        healthTipZh: '继续保持！定期运动和均衡饮食以保持心脏健康。',
        isFromApi: false,
      );
    } else if (bpm > 100 && bpm <= 120) {
      return HeartRateReportResult(
        bpm: bpm,
        category: 'Tachycardia',
        categoryVi: 'Nhịp tim nhanh',
        categoryZh: '心动过速',
        description: 'Your heart rate is slightly elevated. This may be due to stress, caffeine, or physical activity.',
        descriptionVi: 'Nhịp tim của bạn hơi cao. Điều này có thể do căng thẳng, caffeine hoặc hoạt động thể chất.',
        descriptionZh: '您的心率略高。这可能是由于压力、咖啡因或体育活动。',
        healthTip: 'Try relaxation techniques. Limit caffeine intake and ensure adequate rest.',
        healthTipVi: 'Hãy thử các kỹ thuật thư giãn. Hạn chế caffeine và đảm bảo nghỉ ngơi đầy đủ.',
        healthTipZh: '尝试放松技巧。限制咖啡因摄入并确保充足的休息。',
        isFromApi: false,
      );
    } else {
      return HeartRateReportResult(
        bpm: bpm,
        category: 'High Heart Rate',
        categoryVi: 'Nhịp tim cao',
        categoryZh: '心率过高',
        description: 'Your heart rate is significantly elevated. This may indicate an underlying health issue.',
        descriptionVi: 'Nhịp tim của bạn cao đáng kể. Điều này có thể cho thấy một vấn đề sức khỏe tiềm ẩn.',
        descriptionZh: '您的心率明显过高。这可能表明存在潜在的健康问题。',
        healthTip: 'Please consult a healthcare provider. Avoid strenuous activity until evaluated.',
        healthTipVi: 'Hãy tham khảo bác sĩ. Tránh hoạt động mạnh cho đến khi được kiểm tra.',
        healthTipZh: '请咨询医疗保健提供者。在评估之前避免剧烈活动。',
        isFromApi: false,
      );
    }
  }

  String getLocalizedCategory(HeartRateReportResult result, String locale) {
    if (locale == 'vi') return result.categoryVi.isNotEmpty ? result.categoryVi : result.category;
    if (locale == 'zh') return result.categoryZh.isNotEmpty ? result.categoryZh : result.category;
    return result.category;
  }

  String getLocalizedDescription(HeartRateReportResult result, String locale) {
    if (locale == 'vi') return result.descriptionVi.isNotEmpty ? result.descriptionVi : result.description;
    if (locale == 'zh') return result.descriptionZh.isNotEmpty ? result.descriptionZh : result.description;
    return result.description;
  }

  String getLocalizedHealthTip(HeartRateReportResult result, String locale) {
    if (locale == 'vi') return result.healthTipVi.isNotEmpty ? result.healthTipVi : result.healthTip;
    if (locale == 'zh') return result.healthTipZh.isNotEmpty ? result.healthTipZh : result.healthTip;
    return result.healthTip;
  }
}