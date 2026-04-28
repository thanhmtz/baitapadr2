import '../models/hrDBModel.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class HeartRateDataBaseProvider {
  static const String TABLE_NAME = 'heartRateDB';
  static const String COLUMN_ID = "id";
  static const String COLUMN_TIME = 'date';
  static const String COLUMN_HR = 'hr';

  HeartRateDataBaseProvider._();
  static final HeartRateDataBaseProvider db = HeartRateDataBaseProvider._();

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
      join(dbPath, 'heartRateDB.db'),
      version: 1,
      onCreate: (Database database, int version) async {
        print('CREATING heartRateDB table');
        await database.execute("CREATE TABLE $TABLE_NAME ("
            "$COLUMN_ID INTEGER PRIMARY KEY,"
            "$COLUMN_TIME TEXT,"
            "$COLUMN_HR INTEGER"
            ")");
      },
    );
  }

  Future<List> getGraphData() async {
    List dataList = [];
    final db = await database;
    var datas = await db.query(
      TABLE_NAME,
      columns: [COLUMN_HR],
    );
    datas.forEach((element) {
      HeartRateDB heartRateDB = HeartRateDB.fromMap(element);
      dataList.add(heartRateDB.hr);
    });
    return dataList;
  }

  Future<List<HeartRateDB>> getData() async {
    final db = await database;
    var datas = await db.query(
      TABLE_NAME,
      columns: [COLUMN_ID, COLUMN_TIME, COLUMN_HR],
    );

    List<HeartRateDB> dataList = [];

    datas.forEach((element) {
      HeartRateDB heartRateDB = HeartRateDB.fromMap(element);
      dataList.add(heartRateDB);
    });

    return dataList.reversed.toList();
  }

  Future<HeartRateDB> insert(HeartRateDB heartRateDB) async {
    final db = await database;
    heartRateDB.id = await db.insert(TABLE_NAME, heartRateDB.toMap());
    return heartRateDB;
  }

  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(
      TABLE_NAME,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getDailyData({int days = 30}) async {
    final db = await database;
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final startDateStr = startDate.toIso8601String().split('T')[0];

    var datas = await db.query(
      TABLE_NAME,
      columns: [COLUMN_ID, COLUMN_TIME, COLUMN_HR],
      where: "SUBSTR($COLUMN_TIME, 1, 10) >= ?",
      whereArgs: [startDateStr],
      orderBy: "$COLUMN_TIME ASC",
    );

    Map<String, int> dailyData = {};
    datas.forEach((element) {
      HeartRateDB hrDB = HeartRateDB.fromMap(element);
      String day = hrDB.date.substring(0, 10);
      dailyData[day] = hrDB.hr;
    });

    return dailyData.entries.map((e) => {'date': e.key, 'value': e.value}).toList();
  }
}