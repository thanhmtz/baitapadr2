
import 'package:bp_notepad/models/bsDBModel.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class BsDataBaseProvider {
  static const String TABLE_NAME = 'bloodsugarDB';
  static const String COLUMN_ID = "id";
  static const String COLUMN_TIME = 'date';
  static const String COLUMN_GLU = 'glu';
  static const String COLUMN_STATE = 'state';

  BsDataBaseProvider._();
  static final BsDataBaseProvider db = BsDataBaseProvider._();

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
      join(dbPath, 'bloodsugarDB.db'),
      version: 1,
      onCreate: (Database database, int version) async {
        print('CREATING bloodsugarDB table');
        await database.execute("CREATE TABLE $TABLE_NAME ("
            "$COLUMN_ID INTEGER PRIMARY KEY,"
            "$COLUMN_TIME TEXT,"
            "$COLUMN_GLU REAL,"
            "$COLUMN_STATE INTEGER"
            ")");
      },
    );
  }

  Future<List> getGraphData() async {
    List dataList = [];
    final db = await database;
    var datas = await db.query(
      TABLE_NAME,
      columns: [COLUMN_GLU],
    );
    datas.forEach((element) {
      BloodSugarDB bloodSugarDB = BloodSugarDB.fromMap(element);
      dataList.add(bloodSugarDB.glu);
    });
    return dataList;
  }

  Future<List<BloodSugarDB>> getData() async {
    final db = await database;

    var datas = await db.query(
      TABLE_NAME,
      columns: [COLUMN_ID, COLUMN_TIME, COLUMN_GLU, COLUMN_STATE],
    );

    List<BloodSugarDB> dataList = [];

    datas.forEach((element) {
      BloodSugarDB bloodSugarDB = BloodSugarDB.fromMap(element);

      dataList.add(bloodSugarDB);
    });

    return dataList.reversed.toList();
  }

  Future<BloodSugarDB> insert(BloodSugarDB bloodSugarDB) async {
    final db = await database;
    bloodSugarDB.id = await db.insert(TABLE_NAME, bloodSugarDB.toMap());
    return bloodSugarDB;
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


