import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bp_notepad/db/bp_databaseProvider.dart';
import 'package:bp_notepad/models/bpDBModel.dart';

class BloodPressure extends StatefulWidget {
  @override
  _BloodPressureState createState() => _BloodPressureState();
}

class _BloodPressureState extends State<BloodPressure> {
  int _selectedSbp = 120;
  int _selectedDbp = 80;
  int _selectedHr = 70;
  int _sbp = 120;
  int _dbp = 80;
  int _hr = 70;

  String _getBpCategory() {
    if (_sbp >= 180 || _dbp >= 120) return 'Hypertensive Crisis';
    if (_sbp >= 140 || _dbp >= 90) return 'High Blood Pressure Stage 2';
    if (_sbp >= 130 || _dbp >= 80) return 'High Blood Pressure Stage 1';
    if (_sbp >= 120 && _dbp < 80) return 'Elevated';
    if (_sbp >= 90 && _dbp < 60) return 'Low';
    return 'Normal';
  }

  Color _getBpColor() {
    if (_sbp >= 180 || _dbp >= 120) return Color(0xFFB71C1C);
    if (_sbp >= 140 || _dbp >= 90) return Color(0xFFEF5350);
    if (_sbp >= 130 || _dbp >= 80) return Color(0xFFFF9800);
    if (_sbp >= 120 && _dbp < 80) return Color(0xFFFFEB3B);
    if (_sbp >= 90 || _dbp < 60) return Color(0xFF2196F3);
    return Color(0xFF4CAF50);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Color(0xFFF5F7FA),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        border: null,
        middle: Text(
          'Blood Pressure',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF4CAF50),
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.back, color: Color(0xFF4CAF50)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMainCard(),
              SizedBox(height: 20),
              _buildInputCard(
                'Systolic (mmHg)',
                _sbp,
                70,
                200,
                (val) => setState(() => _sbp = val),
                Color(0xFFFF5252),
              ),
              SizedBox(height: 12),
              _buildInputCard(
                'Diastolic (mmHg)',
                _dbp,
                40,
                130,
                (val) => setState(() => _dbp = val),
                Color(0xFF4CAF50),
              ),
              SizedBox(height: 12),
              _buildInputCard(
                'Pulse (bpm)',
                _hr,
                40,
                150,
                (val) => setState(() => _hr = val),
                Color(0xFFFF9800),
              ),
              SizedBox(height: 24),
              _buildSaveButton(),
              SizedBox(height: 12),
              _buildReferenceTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getBpColor(), _getBpColor().withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getBpColor().withOpacity(0.4),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$_sbp / $_dbp',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.white,
            ),
          ),
          Text(
            'mmHg',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.white.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: CupertinoColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getBpCategory(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.white,
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Pulse: $_hr bpm',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(String label, int value, int min, int max, Function onChanged, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.2),
              thumbColor: color,
              overlayColor: color.withOpacity(0.1),
              trackHeight: 6,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              onChanged: (val) => onChanged(val.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$min', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey3)),
              Text('$max', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saveBloodPressure,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF4CAF50).withOpacity(0.4),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Save',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceTable() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Blood Pressure Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label,
            ),
          ),
          SizedBox(height: 12),
          _buildRefRow('Normal', '< 120', 'and', '< 80', Color(0xFF4CAF50)),
          _buildRefRow('Elevated', '120-129', 'and', '< 80', Color(0xFFFFEB3B)),
          _buildRefRow('High BP Stage 1', '130-139', 'or', '80-89', Color(0xFFFF9800)),
          _buildRefRow('High BP Stage 2', '≥ 140', 'or', '≥ 90', Color(0xFFEF5350)),
          _buildRefRow('Hypertensive Crisis', '> 180', 'or', '> 120', Color(0xFFB71C1C)),
        ],
      ),
    );
  }

  Widget _buildRefRow(String category, String sbp, String and, String dbp, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(category, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 2,
            child: Text(sbp, style: TextStyle(fontSize: 14), textAlign: TextAlign.center),
          ),
          SizedBox(width: 4),
          Text(and, style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
          SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Text(dbp, style: TextStyle(fontSize: 14), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBloodPressure() async {
    if (_sbp <= _dbp) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text('Error'),
          content: Text('Systolic must be greater than Diastolic'),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    var date = DateTime.now();
    String time = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    BloodPressureDB bp = BloodPressureDB(sbp: _sbp, dbp: _dbp, hr: _hr, date: time);
    await BpDataBaseProvider.db.insert(bp);

    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('Saved'),
        content: Text('Blood pressure $_sbp/$_dbp mmHg saved'),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}