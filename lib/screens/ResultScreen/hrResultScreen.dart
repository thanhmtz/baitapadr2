import 'dart:ui';
import '../../localization/appLocalization.dart';
import '../../services/heart_rate_report_service.dart';
import '../../db/hr_databaseProvider.dart';
import '../../models/hrDBModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HRResultScreen extends StatefulWidget {
  HRResultScreen({this.hr, this.onSave});

  final int hr;
  final Function(int) onSave;

  @override
  _HRResultScreenState createState() => _HRResultScreenState();
}

class _HRResultScreenState extends State<HRResultScreen> {
  final HeartRateReportService _reportService = HeartRateReportService();
  HeartRateReportResult _reportResult;
  bool _isLoading = true;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final result = await _reportService.getHeartRateReport(widget.hr);
    if (mounted) {
      setState(() {
        _reportResult = result;
        _isLoading = false;
      });
    }
  }

  void _saveHeartRate() async {
    if (_isSaved) return;
    
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final hrData = HeartRateDB(hr: widget.hr, date: dateStr);
    await HeartRateDataBaseProvider.db.insert(hrData);
    
    if (mounted) {
      setState(() => _isSaved = true);
      if (widget.onSave != null) {
        widget.onSave(widget.hr);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context).locale.languageCode;
    
    String category = _reportResult != null 
        ? _reportService.getLocalizedCategory(_reportResult, locale)
        : _getLocalCategory();
    String description = _reportResult != null
        ? _reportService.getLocalizedDescription(_reportResult, locale)
        : _getLocalDescription();
    String healthTip = _reportResult != null
        ? _reportService.getLocalizedHealthTip(_reportResult, locale)
        : _getLocalHealthTip();
    
    Color resultColor = _getResultColor();
    IconData resultIcon = _getResultIcon();

    return CupertinoPageScaffold(
      backgroundColor: Color(0xFF0A0A0A),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Color(0xFF1C1C1E),
        middle: Text(
          AppLocalization.of(context).translate('index_report'),
          style: TextStyle(color: CupertinoColors.white),
        ),
        trailing: _isSaved 
            ? null 
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _saveHeartRate,
                child: Text(
                  'Lưu',
                  style: TextStyle(color: CupertinoColors.activeGreen),
                ),
              ),
      ),
      child: SafeArea(
        child: _isLoading
            ? Center(child: CupertinoActivityIndicator(radius: 20))
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildMainCard(category, resultColor, resultIcon),
                    SizedBox(height: 16),
                    _buildCategoryCard(category, resultColor, resultIcon),
                    SizedBox(height: 16),
                    _buildDetailsCard(description),
                    SizedBox(height: 16),
                    _buildHealthTipCard(healthTip, resultColor),
                    SizedBox(height: 16),
                    _buildApiBadge(),
                    SizedBox(height: 16),
                    _buildRangeGuideCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMainCard(String category, Color resultColor, IconData resultIcon) {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: resultColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(resultIcon, size: 60, color: resultColor),
          ),
          SizedBox(height: 24),
          Text(
            category.toUpperCase(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: resultColor,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                widget.hr.toString(),
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.white,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'BPM',
                style: TextStyle(fontSize: 24, color: CupertinoColors.systemGrey),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _getDateTime(),
            style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String category, Color resultColor, IconData resultIcon) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: resultColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(resultIcon, color: resultColor, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppLocalization.of(context).translate('category') ?? 'Category',
                  style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                ),
                SizedBox(height: 4),
                Text(
                  category,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CupertinoColors.white),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: resultColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusText(),
              style: TextStyle(color: resultColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(String description) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(CupertinoIcons.info_circle, color: CupertinoColors.systemGrey, size: 20),
              SizedBox(width: 8),
              Text(
                AppLocalization.of(context).translate('details') ?? 'Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.white),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTipCard(String healthTip, Color resultColor) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: resultColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: resultColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(CupertinoIcons.lightbulb, color: resultColor, size: 20),
              SizedBox(width: 8),
              Text(
                AppLocalization.of(context).translate('health_tip') ?? 'Health Tip',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: resultColor),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            healthTip,
            style: TextStyle(fontSize: 14, color: CupertinoColors.white, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildApiBadge() {
    if (_reportResult == null || _reportResult.isFromApi) return SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: CupertinoColors.systemOrange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(CupertinoIcons.info, color: CupertinoColors.systemOrange, size: 14),
          SizedBox(width: 4),
          Text(
            AppLocalization.of(context).translate('calculated_locally') ?? 'Calculated locally',
            style: TextStyle(color: CupertinoColors.systemOrange, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeGuideCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(CupertinoIcons.chart_bar, color: CupertinoColors.systemGrey, size: 20),
              SizedBox(width: 8),
              Text(
                'Heart Rate Guide',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.white),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildRangeRow('Low', '< 60 BPM', CupertinoColors.systemBlue),
          _buildRangeRow('Normal', '60 - 100 BPM', CupertinoColors.systemGreen),
          _buildRangeRow('Elevated', '100 - 120 BPM', CupertinoColors.systemOrange),
          _buildRangeRow('High', '> 120 BPM', CupertinoColors.systemRed),
        ],
      ),
    );
  }

  Widget _buildRangeRow(String label, String range, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
          SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: CupertinoColors.white))),
          Text(range, style: TextStyle(color: CupertinoColors.systemGrey)),
        ],
      ),
    );
  }

  Color _getResultColor() {
    if (widget.hr < 60) return CupertinoColors.systemBlue;
    if (widget.hr <= 100) return CupertinoColors.systemGreen;
    if (widget.hr <= 120) return CupertinoColors.systemOrange;
    return CupertinoColors.systemRed;
  }

  IconData _getResultIcon() => CupertinoIcons.heart_fill;

  String _getLocalCategory() {
    if (widget.hr < 60) return 'Low';
    if (widget.hr <= 100) return 'Normal';
    if (widget.hr <= 120) return 'Elevated';
    return 'High';
  }

  String _getLocalDescription() {
    if (widget.hr < 60) return 'Your heart rate is below normal range.';
    if (widget.hr <= 100) return 'Your heart rate is normal.';
    if (widget.hr <= 120) return 'Your heart rate is slightly elevated.';
    return 'Your heart rate is high.';
  }

  String _getLocalHealthTip() {
    if (widget.hr < 60) return 'Consult a doctor if you feel dizzy.';
    if (widget.hr <= 100) return 'Keep up the good work!';
    if (widget.hr <= 120) return 'Try relaxation techniques.';
    return 'Please consult a healthcare provider.';
  }

  String _getStatusText() {
    if (widget.hr < 60) return 'Low';
    if (widget.hr <= 100) return 'Good';
    if (widget.hr <= 120) return 'Warning';
    return 'High';
  }

  String _getDateTime() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[now.month - 1]} ${now.day}, ${now.year} at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}