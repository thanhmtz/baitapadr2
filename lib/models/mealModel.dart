class MealModel {
  int id;
  String name;
  double calories;
  double protein;
  double carbs;
  double fat;
  double quantity;
  String unit;
  DateTime date;
  String mealType;
  String imageUrl;

  MealModel({
    this.id,
    this.name,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.quantity = 100,
    this.unit = 'g',
    DateTime date,
    this.mealType = 'breakfast',
    this.imageUrl,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'quantity': quantity,
      'unit': unit,
      'date': date.toIso8601String(),
      'mealType': mealType,
      'imageUrl': imageUrl,
    };
  }

  factory MealModel.fromMap(Map<String, dynamic> map) {
    return MealModel(
      id: map['id'],
      name: map['name'],
      calories: map['calories'].toDouble(),
      protein: map['protein'].toDouble(),
      carbs: map['carbs'].toDouble(),
      fat: map['fat'].toDouble(),
      quantity: map['quantity'].toDouble(),
      unit: map['unit'],
      date: DateTime.parse(map['date']),
      mealType: map['mealType'],
      imageUrl: map['imageUrl'],
    );
  }

  MealModel copyWith({
    int id,
    String name,
    double calories,
    double protein,
    double carbs,
    double fat,
    double quantity,
    String unit,
    DateTime date,
    String mealType,
    String imageUrl,
  }) {
    return MealModel(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class NutritionTarget {
  double calories;
  double protein;
  double carbs;
  double fat;

  NutritionTarget({
    this.calories = 2000,
    this.protein = 50,
    this.carbs = 250,
    this.fat = 65,
  });

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  factory NutritionTarget.fromMap(Map<String, dynamic> map) {
    return NutritionTarget(
      calories: map['calories'].toDouble(),
      protein: map['protein'].toDouble(),
      carbs: map['carbs'].toDouble(),
      fat: map['fat'].toDouble(),
    );
  }
}

class DailySummary {
  double totalCalories;
  double totalProtein;
  double totalCarbs;
  double totalFat;
  NutritionTarget target;
  List<MealModel> meals;

  DailySummary({
    this.totalCalories = 0,
    this.totalProtein = 0,
    this.totalCarbs = 0,
    this.totalFat = 0,
    NutritionTarget target,
    this.meals,
  }) : target = target ?? NutritionTarget();

  double get caloriesProgress => target.calories > 0 ? (totalCalories / target.calories * 100).clamp(0, 150) : 0;
  double get proteinProgress => target.protein > 0 ? (totalProtein / target.protein * 100).clamp(0, 150) : 0;
  double get carbsProgress => target.carbs > 0 ? (totalCarbs / target.carbs * 100).clamp(0, 150) : 0;
  double get fatProgress => target.fat > 0 ? (totalFat / target.fat * 100).clamp(0, 150) : 0;
}