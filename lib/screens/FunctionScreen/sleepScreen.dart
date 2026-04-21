import 'package:bp_notepad/db/sleep_databaseProvider.dart';
import 'package:bp_notepad/localization/appLocalization.dart';
import 'package:bp_notepad/models/sleepDBModel.dart';
import 'package:bp_notepad/screens/ResultScreen/sleepResultScreen.dart';
import 'package:bp_notepad/services/sleep_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum SleepScreenState {
  idle,
  loading,
  result,
  error,
}

class SleepScreen extends StatefulWidget {
  @override
  _SleepScreenState createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  final SleepService _sleepService = SleepService();
  
  DateTime _sleepTime = DateTime.now().subtract(Duration(hours: 8));
  DateTime _wakeTime = DateTime.now();
  
  SleepScreenState _screenState = SleepScreenState.idle;
  SleepAnalysisResult _result;
  String _errorMessage = '';

  double get _sleepDuration {
    Duration difference = _wakeTime.difference(_sleepTime);
    if (difference.isNegative) {
      difference = difference + Duration(hours: 24);
    }
    return difference.inMinutes / 60.0;
  }

  Future<void> _analyzeSleep() async {
    if (!_sleepService.validateSleepInput(_sleepTime, _wakeTime)) {
      _showValidationError();
      return;
    }

    setState(() {
      _screenState = SleepScreenState.loading;
    });

    final result = await _sleepService.analyzeSleep(
      bedtime: _sleepTime,
      wakeTime: _wakeTime,
    );

    setState(() {
      if (result != null) {
        _result = result;
        _screenState = SleepScreenState.result;
      } else {
        _screenState = SleepScreenState.error;
        _errorMessage = 'Failed to analyze sleep';
      }
    });
  }

  void _showValidationError() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(AppLocalization.of(context).translate('invalid_input')),
        content: Text('Please enter valid sleep times (0-24 hours)'),
        actions: <Widget>[
          CupertinoDialogAction(
            child: Text(AppLocalization.of(context).translate('ok')),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSleep() async {
    final bool confirmed = await _showSaveConfirmation();
    if (!confirmed) return;
    
    var date = new DateTime.now().toLocal();
    String time = "${date.year.toString()}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    
    SleepDB sleepDB = SleepDB(
      sleep: _sleepDuration,
      state: _result.quality,
      date: time,
    );
    
    await SleepDataBaseProvider.db.insert(sleepDB);
    
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => SleepResultScreen(
          sleep: _sleepDuration,
          state: _result.quality,
        ),
      ),
    );
  }

  Future<bool> _showSaveConfirmation() async {
    return await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Save Sleep Record'),
        content: Text('Do you want to save this sleep record?'),
        actions: <Widget>[
          CupertinoDialogAction(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Save'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ) ?? false;
  }

  void _reset() {
    setState(() {
      _screenState = SleepScreenState.idle;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Color(0xFF0A0A0A),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Color(0xFF1C1C1E),
        middle: Text(
          AppLocalization.of(context).translate('sleep_record'),
          style: TextStyle(color: CupertinoColors.white),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: _buildCurrentView(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_screenState) {
      case SleepScreenState.idle:
        return _buildInputView();
      case SleepScreenState.loading:
        return _buildLoadingView();
      case SleepScreenState.result:
        return _buildResultsView();
      case SleepScreenState.error:
        return _buildErrorView();
      default:
        return _buildInputView();
    }
  }

  Widget _buildLoadingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        CupertinoActivityIndicator(radius: 20),
        SizedBox(height: 24),
        Text(
          'Analyzing your sleep...',
          style: TextStyle(
            fontSize: 16,
            color: CupertinoColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          CupertinoIcons.exclamationmark_triangle,
          size: 60,
          color: CupertinoColors.systemRed,
        ),
        SizedBox(height: 16),
        Text(
          'Error',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          _errorMessage,
          style: TextStyle(
            fontSize: 14,
            color: CupertinoColors.systemGrey,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        CupertinoButton(
          color: CupertinoColors.systemBlue,
          borderRadius: BorderRadius.circular(30),
          onPressed: _reset,
          child: Text('Try Again'),
        ),
      ],
    );
  }

  Widget _buildInputView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          AppLocalization.of(context).translate('sleep_tracker') ?? 'Sleep Tracker',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          AppLocalization.of(context).translate('set_sleep_wake_times') ?? 'Set your sleep and wake times',
          style: TextStyle(
            fontSize: 14,
            color: CupertinoColors.systemGrey,
          ),
        ),
        SizedBox(height: 32),
        _buildTimePicker(
          label: AppLocalization.of(context).translate('bedtime') ?? 'Bedtime',
          icon: CupertinoIcons.moon_fill,
          time: _sleepTime,
          onTap: () => _showTimePicker(isSleepTime: true),
        ),
        SizedBox(height: 16),
        Icon(
          CupertinoIcons.arrow_down,
          color: CupertinoColors.systemGrey,
          size: 24,
        ),
        SizedBox(height: 16),
        _buildTimePicker(
          label: AppLocalization.of(context).translate('wake_time') ?? 'Wake time',
          icon: CupertinoIcons.sun_max_fill,
          time: _wakeTime,
          onTap: () => _showTimePicker(isSleepTime: false),
        ),
        SizedBox(height: 16),
        _buildDurationCard(),
        SizedBox(height: 32),
        CupertinoButton(
          color: CupertinoColors.systemPurple,
          borderRadius: BorderRadius.circular(30),
          padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          onPressed: _analyzeSleep,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(CupertinoIcons.sparkles, color: CupertinoColors.white),
              SizedBox(width: 8),
              Text(
                AppLocalization.of(context).translate('analyze_sleep') ?? 'Analyze Sleep',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationCard() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            CupertinoIcons.clock,
            color: CupertinoColors.systemBlue,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            '${AppLocalization.of(context).translate('duration') ?? 'Duration'}: ${_sleepDuration.toStringAsFixed(1)} ${AppLocalization.of(context).translate('hours') ?? 'hours'}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    return _SleepResultView(
      result: _result,
      sleepDuration: _sleepDuration,
      onSave: _saveSleep,
      onReset: _reset,
    );
  }

  Widget _buildTimePicker({
    String label,
    IconData icon,
    DateTime time,
    Function onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: CupertinoColors.systemPurple, size: 28),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatTime(time),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.white,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showTimePicker({bool isSleepTime}) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        DateTime tempTime = isSleepTime ? _sleepTime : _wakeTime;
        return Container(
          height: 300,
          color: Color(0xFF1C1C1E),
          child: Column(
            children: <Widget>[
              Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppLocalization.of(context).translate('cancel') ?? 'Cancel',
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(
                        AppLocalization.of(context).translate('done') ?? 'Done',
                        style: TextStyle(color: CupertinoColors.systemPurple),
                      ),
                      onPressed: () {
                        setState(() {
                          if (isSleepTime) {
                            _sleepTime = tempTime;
                          } else {
                            _wakeTime = tempTime;
                          }
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: tempTime,
                  onDateTimeChanged: (DateTime newTime) {
                    tempTime = newTime;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SleepResultView extends StatelessWidget {
  final SleepAnalysisResult result;
  final double sleepDuration;
  final VoidCallback onSave;
  final VoidCallback onReset;

  const _SleepResultView({
    this.result,
    this.sleepDuration,
    this.onSave,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    Color qualityColor;
    IconData qualityIcon;
    
    switch (result.quality) {
      case 0:
        qualityColor = CupertinoColors.systemRed;
        qualityIcon = CupertinoIcons.heart_slash;
        break;
      case 1:
        qualityColor = CupertinoColors.systemOrange;
        qualityIcon = CupertinoIcons.heart;
        break;
      case 2:
        qualityColor = CupertinoColors.systemYellow;
        qualityIcon = CupertinoIcons.heart;
        break;
      case 3:
      case 4:
        qualityColor = CupertinoColors.systemGreen;
        qualityIcon = CupertinoIcons.heart_fill;
        break;
      default:
        qualityColor = CupertinoColors.systemGrey;
        qualityIcon = CupertinoIcons.heart;
    }
    
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (result.isFromLocal)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemOrange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    CupertinoIcons.info,
                    color: CupertinoColors.systemOrange,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Calculated locally',
                    style: TextStyle(
                      color: CupertinoColors.systemOrange,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            AppLocalization.of(context).translate('sleep_quality') ?? 'Sleep Quality',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.white,
            ),
          ),
          SizedBox(height: 24),
          Icon(qualityIcon, size: 80, color: qualityColor),
          SizedBox(height: 16),
          Text(
            result.feedback,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: qualityColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${sleepDuration.toStringAsFixed(1)} ${AppLocalization.of(context).translate('hours') ?? 'hours'} of sleep',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemGrey,
            ),
          ),
          SizedBox(height: 32),
          _buildSuggestionsCard(context),
          SizedBox(height: 32),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                CupertinoIcons.lightbulb,
                color: CupertinoColors.systemYellow,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                AppLocalization.of(context).translate('suggestions') ?? 'Suggestions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            result.suggestions,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: <Widget>[
        CupertinoButton(
          color: CupertinoColors.systemGreen,
          borderRadius: BorderRadius.circular(30),
          padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          onPressed: onSave,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(CupertinoIcons.checkmark_alt, color: CupertinoColors.white),
              SizedBox(width: 8),
              Text(
                AppLocalization.of(context).translate('save') ?? 'Save',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        CupertinoButton(
          color: Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(30),
          padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          onPressed: onReset,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(CupertinoIcons.refresh, color: CupertinoColors.white),
              SizedBox(width: 8),
              Text(
                AppLocalization.of(context).translate('try_again') ?? 'Try Again',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
