import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator;
import 'package:bp_notepad/models/mealModel.dart';
import 'package:bp_notepad/db/nutrition_databaseProvider.dart';
import 'package:bp_notepad/services/food_service.dart';
import 'package:bp_notepad/localization/appLocalization.dart';

class NutritionScreen extends StatefulWidget {
  @override
  _NutritionScreenState createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final TextEditingController _foodNameController = TextEditingController();
  List<FoodItem> _searchResults = [];
  bool _isSearching = false;
  String _selectedMealType = 'lunch';
  List<MealModel> _todayMeals = [];
  bool _showAddForm = false;

  @override
  void initState() {
    super.initState();
    _loadTodayMeals();
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayMeals() async {
    var meals = await NutritionDatabaseProvider.getMealsByDate(DateTime.now());
    setState(() {
      _todayMeals = meals;
    });
  }

  double get _totalCalories => _todayMeals.fold(0, (sum, meal) => sum + meal.calories);
  double get _totalProtein => _todayMeals.fold(0, (sum, meal) => sum + meal.protein);
  double get _totalCarbs => _todayMeals.fold(0, (sum, meal) => sum + meal.carbs);
  double get _totalFat => _todayMeals.fold(0, (sum, meal) => sum + meal.fat);

  Future<void> _searchFood() async {
    if (_foodNameController.text.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    var results = await FoodService.searchFoods(_foodNameController.text.trim());

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  Future<void> _saveMeal(FoodItem food) async {
    final meal = MealModel(
      name: food.name,
      calories: food.calories,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
      date: DateTime.now(),
      mealType: _selectedMealType,
      imageUrl: food.imageUrl,
    );

    await NutritionDatabaseProvider.insertMeal(meal);

    _foodNameController.clear();
    setState(() {
      _searchResults = [];
      _showAddForm = false;
    });
    _loadTodayMeals();
  }

  Future<void> _deleteMeal(int id) async {
    await NutritionDatabaseProvider.deleteMeal(id);
    _loadTodayMeals();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppLocalization.of(context).translate('nutrition_page') ?? 'Dinh Dưỡng'),
      ),
      child: SafeArea(
        child: _showAddForm ? _buildAddForm() : _buildDashboard(),
      ),
    );
  }

  Widget _buildDashboard() {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCaloriesCard(),
                    SizedBox(height: 16),
                    _buildMacroCards(),
                    SizedBox(height: 20),
                    Text(
                      'Hôm nay',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            _todayMeals.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(CupertinoIcons.doc_text, size: 50, color: CupertinoColors.systemGrey),
                            SizedBox(height: 12),
                            Text(
                              AppLocalization.of(context).translate('no_meals') ?? 'Chưa có bữa ăn',
                              style: TextStyle(color: CupertinoColors.systemGrey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        var meal = _todayMeals[index];
                        return _buildMealItem(meal);
                      },
                      childCount: _todayMeals.length,
                    ),
                  ),
            SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                _showAddForm = true;
              });
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: CupertinoColors.activeGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(CupertinoIcons.add, color: CupertinoColors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaloriesCard() {
    double progress = (_totalCalories / 2000).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [CupertinoColors.activeGreen, Color(0xFF34C759)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.activeGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calories',
                style: TextStyle(
                  color: CupertinoColors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                _totalCalories.toStringAsFixed(0),
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '/ 2000 kcal',
                style: TextStyle(
                  color: CupertinoColors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(
            width: 70,
            height: 70,
            child: CustomPaint(
              painter: _CircularProgressPainter(progress, CupertinoColors.white),
              child: Center(
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCards() {
    return Row(
      children: [
        Expanded(child: _buildMacroCard('Protein', _totalProtein, 50, CupertinoColors.systemRed, CupertinoIcons.bolt_fill)),
        SizedBox(width: 8),
        Expanded(child: _buildMacroCard('Carbs', _totalCarbs, 250, CupertinoColors.systemOrange, CupertinoIcons.circle_fill)),
        SizedBox(width: 8),
        Expanded(child: _buildMacroCard('Fat', _totalFat, 65, CupertinoColors.systemBlue, CupertinoIcons.drop_fill)),
      ],
    );
  }

  Widget _buildMacroCard(String label, double value, double target, Color color, IconData icon) {
    double progress = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text('${value.toStringAsFixed(0)}g', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
          SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealItem(MealModel meal) {
    return Dismissible(
      key: Key(meal.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: CupertinoColors.destructiveRed,
        child: Icon(CupertinoIcons.delete, color: CupertinoColors.white),
      ),
      onDismissed: (_) => _deleteMeal(meal.id),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(10),
              ),
              child: meal.imageUrl != null && meal.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        meal.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey),
                      ),
                    )
                  : Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text(
                    '${meal.calories.toStringAsFixed(0)} kcal',
                    style: TextStyle(fontSize: 13, color: CupertinoColors.systemOrange, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getMealTypeColor(meal.mealType),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getMealTypeLabel(meal.mealType),
                style: TextStyle(color: CupertinoColors.white, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType) {
      case 'breakfast': return CupertinoColors.systemOrange;
      case 'lunch': return CupertinoColors.systemBlue;
      case 'dinner': return CupertinoColors.systemPurple;
      case 'snack': return CupertinoColors.systemPink;
      default: return CupertinoColors.systemGrey;
    }
  }

  String _getMealTypeLabel(String mealType) {
    switch (mealType) {
      case 'breakfast': return 'Sáng';
      case 'lunch': return 'Trưa';
      case 'dinner': return 'Tối';
      case 'snack': return 'Snack';
      default: return mealType;
    }
  }

  Widget _buildAddForm() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _showAddForm = false;
                      _searchResults = [];
                    });
                  },
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.back, size: 20),
                      SizedBox(width: 4),
                      Text('Quay lại'),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text('Thêm món ăn', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                CupertinoTextField(
                  controller: _foodNameController,
                  placeholder: 'Nhập tên món (VD: phở bò, cơm gà)',
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSubmitted: (_) => _searchFood(),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _searchFood,
                    child: Text('Tìm kiếm'),
                  ),
                ),
                SizedBox(height: 24),
                if (_isSearching)
                  Center(child: CupertinoActivityIndicator(radius: 20)),
                if (_searchResults.isNotEmpty) ...[
                  Text('Kết quả (${_searchResults.length} món)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        if (_searchResults.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                var food = _searchResults[index];
                return _buildFoodResultItem(food);
              },
              childCount: _searchResults.length,
            ),
          ),
      ],
    );
  }

  Widget _buildFoodResultItem(FoodItem food) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.all(12),
        onPressed: () => _showAddMealDialog(food),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(12),
              ),
              child: food.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        food.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey, size: 30),
                      ),
                    )
                  : Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey, size: 30),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(CupertinoIcons.flame_fill, color: CupertinoColors.systemOrange, size: 14),
                      SizedBox(width: 4),
                      Text(
                        '${food.calories.toStringAsFixed(0)} kcal',
                        style: TextStyle(fontSize: 13, color: CupertinoColors.systemOrange, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  if (food.protein > 0 || food.carbs > 0 || food.fat > 0)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'P: ${food.protein.toStringAsFixed(1)}g | C: ${food.carbs.toStringAsFixed(1)}g | F: ${food.fat.toStringAsFixed(1)}g',
                        style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey),
                      ),
                    ),
                ],
              ),
            ),
            Icon(CupertinoIcons.plus_circle_fill, color: CupertinoColors.activeGreen, size: 28),
          ],
        ),
      ),
    );
  }

  void _showAddMealDialog(FoodItem food) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text('Hủy'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      food.name,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text('Thêm'),
                      onPressed: () {
                        Navigator.pop(context);
                        _saveMeal(food);
                      },
                    ),
                  ],
                ),
              ),
              if (food.imageUrl.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      food.imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: CupertinoColors.systemGrey5,
                        child: Icon(CupertinoIcons.photo, size: 50, color: CupertinoColors.systemGrey),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildNutrientInfo('Calories', '${food.calories.toStringAsFixed(0)} kcal', CupertinoColors.systemOrange, CupertinoIcons.flame_fill),
                    _buildNutrientInfo('Protein', '${food.protein.toStringAsFixed(1)}g', CupertinoColors.systemRed, CupertinoIcons.bolt_fill),
                    _buildNutrientInfo('Carbs', '${food.carbs.toStringAsFixed(1)}g', CupertinoColors.systemOrange, CupertinoIcons.circle_fill),
                    _buildNutrientInfo('Fat', '${food.fat.toStringAsFixed(1)}g', CupertinoColors.systemBlue, CupertinoIcons.drop_fill),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CupertinoSlidingSegmentedControl<String>(
                  groupValue: _selectedMealType,
                  children: {
                    'breakfast': Text('Sáng'),
                    'lunch': Text('Trưa'),
                    'dinner': Text('Tối'),
                    'snack': Text('Snack'),
                  },
                  onValueChanged: (value) => setState(() => _selectedMealType = value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientInfo(String label, String value, Color color, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 15))),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularProgressPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    Paint bgPaint = Paint()
      ..color = CupertinoColors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    Paint fgPaint = Paint()
      ..color = CupertinoColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    double center = size.width / 2;
    double radius = center - 3;

    canvas.drawCircle(Offset(center, center), radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(center, center), radius: radius),
      -3.14159 / 2,
      2 * 3.14159 * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}