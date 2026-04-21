import '../db/hr_databaseProvider.dart';

class HeartRateDB {
  int id;
  int hr;
  String date;

  HeartRateDB({this.id, this.hr, this.date});

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      HeartRateDataBaseProvider.COLUMN_ID: id,
      HeartRateDataBaseProvider.COLUMN_HR: hr,
      HeartRateDataBaseProvider.COLUMN_TIME: date
    };
    if (id != null) {
      map[HeartRateDataBaseProvider.COLUMN_ID] = id;
    }
    return map;
  }

  HeartRateDB.fromMap(Map<String, dynamic> map) {
    id = map[HeartRateDataBaseProvider.COLUMN_ID];
    hr = map[HeartRateDataBaseProvider.COLUMN_HR];
    date = map[HeartRateDataBaseProvider.COLUMN_TIME];
  }
}