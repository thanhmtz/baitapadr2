import 'package:bp_notepad/db/water_databaseProvider.dart';

class WaterReminder {
  int id;
  int targetAmount;
  int currentAmount;
  int lastDrinkAmount;
  String unit;
  DateTime date;

  WaterReminder({
    this.id,
    this.targetAmount,
    this.currentAmount,
    this.lastDrinkAmount,
    this.unit,
    this.date,
  });

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      WaterDataBaseProvider.COLUMN_ID: id,
      WaterDataBaseProvider.COLUMN_TARGET_AMOUNT: targetAmount,
      WaterDataBaseProvider.COLUMN_CURRENT_AMOUNT: currentAmount,
      WaterDataBaseProvider.COLUMN_LAST_DRINK_AMOUNT: lastDrinkAmount,
      WaterDataBaseProvider.COLUMN_UNIT: unit,
      WaterDataBaseProvider.COLUMN_DATE: date.toIso8601String(),
    };
    if (id != null) {
      map[WaterDataBaseProvider.COLUMN_ID] = id;
    }
    return map;
  }

  WaterReminder.fromMap(Map<String, dynamic> map) {
    id = map[WaterDataBaseProvider.COLUMN_ID];
    targetAmount = map[WaterDataBaseProvider.COLUMN_TARGET_AMOUNT];
    currentAmount = map[WaterDataBaseProvider.COLUMN_CURRENT_AMOUNT];
    lastDrinkAmount = map[WaterDataBaseProvider.COLUMN_LAST_DRINK_AMOUNT];
    unit = map[WaterDataBaseProvider.COLUMN_UNIT];
    date = DateTime.parse(map[WaterDataBaseProvider.COLUMN_DATE]);
  }
}