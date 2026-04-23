import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bp_notepad/db/nutrition_databaseProvider.dart';
import 'package:bp_notepad/models/mealModel.dart';
import 'package:bp_notepad/screens/FunctionScreen/nutritionScreen.dart';

class NutritionCard extends StatefulWidget {
  @override
  _NutritionCardState createState() => _NutritionCardState();
}

class _NutritionCardState extends State<NutritionCard> {
  List<MealModel> _todayMeals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    var meals = await NutritionDatabaseProvider.getMealsByDate(DateTime.now());
    setState(() {
      _todayMeals = meals;
      _isLoading = false;
    });
  }

  double get _totalCalories => _todayMeals.fold(0, (sum, meal) => sum + meal.calories);
  double get _totalProtein => _todayMeals.fold(0, (sum, meal) => sum + meal.protein);
  double get _totalCarbs => _todayMeals.fold(0, (sum, meal) => sum + meal.carbs);
  double get _totalFat => _todayMeals.fold(0, (sum, meal) => sum + meal.fat);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 160,
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    double progress = (_totalCalories / 2000).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => NutritionScreen()),
        );
        _loadData();
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              CupertinoColors.activeGreen,
              Color(0xFF30D158),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.activeGreen.withOpacity(0.4),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.flame_fill,
                          color: CupertinoColors.white,
                          size: 22,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Dinh Dưỡng Hôm Nay',
                          style: TextStyle(
                            color: CupertinoColors.white.withOpacity(0.95),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '${_totalCalories.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '/ 2000 kcal',
                      style: TextStyle(
                        color: CupertinoColors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: CupertinoColors.white.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation(CupertinoColors.white),
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroItem('Protein', _totalProtein, 50, CupertinoIcons.bolt_fill),
                _buildMacroItem('Carbs', _totalCarbs, 250, CupertinoIcons.circle_fill),
                _buildMacroItem('Fat', _totalFat, 65, CupertinoIcons.drop_fill),
              ],
            ),
            if (_todayMeals.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: CupertinoColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_todayMeals.length} món hôm nay',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      CupertinoIcons.chevron_right,
                      color: CupertinoColors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMacroItem(String label, double value, double target, IconData icon) {
    double progress = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      children: [
        Icon(icon, color: CupertinoColors.white, size: 20),
        SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(0)}g',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '/ ${target.toStringAsFixed(0)}g',
          style: TextStyle(
            color: CupertinoColors.white.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
        SizedBox(height: 4),
        SizedBox(
          width: 50,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: CupertinoColors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation(CupertinoColors.white),
              minHeight: 4,
            ),
          ),
        ),
      ],
    );
  }
}