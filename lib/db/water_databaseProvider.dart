import 'package:bp_notepad/models/waterReminderModel.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class WaterDataBaseProvider {
  static const String TABLE_NAME = 'WaterReminder';
  static const String COLUMN_ID = "id";
  static const String COLUMN_TARGET_AMOUNT = "targetAmount";
  static const String COLUMN_CURRENT_AMOUNT = "currentAmount";
  static const String COLUMN_LAST_DRINK_AMOUNT = "lastDrinkAmount";
  static const String COLUMN_UNIT = "unit";
  static const String COLUMN_DATE = "date";

  WaterDataBaseProvider._();
  static final WaterDataBaseProvider db = WaterDataBaseProvider._();

  Database _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database;
    }
    _database = await createDatabase();
    return _database;
  }

  Future<Database> createDatabase() async {
    String dbPath = await getDatabasesPath();
    return await openDatabase(
      join(dbPath, 'waterReminder.db'),
      version: 2,
      onUpgrade: (Database database, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await database.execute("ALTER TABLE $TABLE_NAME ADD COLUMN $COLUMN_LAST_DRINK_AMOUNT INTEGER DEFAULT 0");
        }
      },
      onCreate: (Database database, int version) async {
        await database.execute("CREATE TABLE $TABLE_NAME ("
            "$COLUMN_ID INTEGER PRIMARY KEY,"
            "$COLUMN_TARGET_AMOUNT INTEGER,"
            "$COLUMN_CURRENT_AMOUNT INTEGER,"
            "$COLUMN_LAST_DRINK_AMOUNT INTEGER,"
            "$COLUMN_UNIT TEXT,"
            "$COLUMN_DATE TEXT"
            ")");
      },
    );
  }

  Future<List<WaterReminder>> getData() async {
    final db = await database;
    var datas = await db.query(TABLE_NAME);
    List<WaterReminder> dataList = [];
    datas.forEach((element) {
      WaterReminder waterReminder = WaterReminder.fromMap(element);
      dataList.add(waterReminder);
    });
    return dataList;
  }

  Future<WaterReminder> getTodayData() async {
    final db = await database;
    String today = DateTime.now().toIso8601String().substring(0, 10);
    var datas = await db.query(
      TABLE_NAME,
      where: "date LIKE ?",
      whereArgs: ['$today%'],
    );
    if (datas.isNotEmpty) {
      return WaterReminder.fromMap(datas.first);
    }
    return null;
  }

  Future<WaterReminder> insert(WaterReminder waterReminder) async {
    final db = await database;
    waterReminder.id = await db.insert(TABLE_NAME, waterReminder.toMap());
    return waterReminder;
  }

  Future<int> update(WaterReminder waterReminder) async {
    final db = await database;
    return await db.update(
      TABLE_NAME,
      waterReminder.toMap(),
      where: "id = ?",
      whereArgs: [waterReminder.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(
      TABLE_NAME,
      where: "id = ?",
      whereArgs: [id],
    );
  }
}