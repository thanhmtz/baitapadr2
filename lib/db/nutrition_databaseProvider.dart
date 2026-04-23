import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:bp_notepad/models/mealModel.dart';

class NutritionDatabaseProvider {
  static Database _database;
  static final String _dbName = 'nutrition.db';
  static final String tableMeals = 'meals';

  static Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableMeals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        date TEXT NOT NULL,
        mealType TEXT NOT NULL,
        imageUrl TEXT
      )
    ''');
  }

  static Future<int> insertMeal(MealModel meal) async {
    final db = await database;
    return await db.insert(tableMeals, {
      'name': meal.name,
      'calories': meal.calories,
      'protein': meal.protein,
      'carbs': meal.carbs,
      'fat': meal.fat,
      'quantity': meal.quantity,
      'unit': meal.unit,
      'date': meal.date.toIso8601String(),
      'mealType': meal.mealType,
      'imageUrl': meal.imageUrl,
    });
  }

  static Future<List<MealModel>> getMealsByDate(DateTime date) async {
    final db = await database;
    String dateStr = date.toIso8601String().substring(0, 10);
    List<Map<String, dynamic>> maps = await db.query(
      tableMeals,
      where: "date LIKE ?",
      whereArgs: ['$dateStr%'],
    );
    return List.generate(maps.length, (i) => _mealFromMap(maps[i]));
  }

  static Future<List<MealModel>> getAllMeals() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(tableMeals, orderBy: 'date DESC');
    return List.generate(maps.length, (i) => _mealFromMap(maps[i]));
  }

  static Future<int> deleteMeal(int id) async {
    final db = await database;
    return await db.delete(
      tableMeals,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  static MealModel _mealFromMap(Map<String, dynamic> map) {
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
}