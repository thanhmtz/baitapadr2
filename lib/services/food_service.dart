import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bp_notepad/db/nutritionData.dart';

class FoodItem {
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String imageUrl;
  final String brand;

  FoodItem({
    this.name,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.imageUrl,
    this.brand,
  });

  factory FoodItem.fromEdamam(Map<String, dynamic> json) {
    double caloriesVal = 0;
    double proteinVal = 0;
    double carbsVal = 0;
    double fatVal = 0;

    if (json.containsKey('nutrients')) {
      var nutrients = json['nutrients'];
      if (nutrients.containsKey('ENERC_KCAL')) {
        caloriesVal = (nutrients['ENERC_KCAL'] is int)
            ? (nutrients['ENERC_KCAL'] as int).toDouble()
            : nutrients['ENERC_KCAL'].toDouble();
      }
      if (nutrients.containsKey('PROCNT')) {
        proteinVal = (nutrients['PROCNT'] is int)
            ? (nutrients['PROCNT'] as int).toDouble()
            : nutrients['PROCNT'].toDouble();
      }
      if (nutrients.containsKey('CHOCDF')) {
        carbsVal = (nutrients['CHOCDF'] is int)
            ? (nutrients['CHOCDF'] as int).toDouble()
            : nutrients['CHOCDF'].toDouble();
      }
      if (nutrients.containsKey('FAT')) {
        fatVal = (nutrients['FAT'] is int)
            ? (nutrients['FAT'] as int).toDouble()
            : nutrients['FAT'].toDouble();
      }
    }

    String imageUrl = '';
    if (json['image'] != null && json['image'].toString().isNotEmpty) {
      imageUrl = json['image'];
    }

    return FoodItem(
      name: json['label'] ?? '',
      calories: caloriesVal,
      protein: proteinVal,
      carbs: carbsVal,
      fat: fatVal,
      imageUrl: imageUrl,
      brand: json['brand'] ?? '',
    );
  }

  factory FoodItem.fromLocal(Map<String, dynamic> data, String name) {
    return FoodItem(
      name: name,
      calories: (data['calories'] ?? 0).toDouble(),
      protein: (data['protein'] ?? 0).toDouble(),
      carbs: (data['carbs'] ?? 0).toDouble(),
      fat: (data['fat'] ?? 0).toDouble(),
      imageUrl: '',
      brand: '',
    );
  }
}

class FoodService {
  static const String _edamamAppId = '823f7761';
  static const String _edamamAppKey = 'abff9e906c57b14275ff4973d5993ebf';
  static const String _edamamApiUrl = 'https://api.edamam.com/api/food-database/v2/parser';

  static Future<List<FoodItem>> searchFoods(String foodName) async {
    List<FoodItem> results = [];
    
    try {
      var uri = Uri.parse('$_edamamApiUrl?ingr=${Uri.encodeComponent(foodName)}&app_id=$_edamamAppId&app_key=$_edamamAppKey&limit=20');
      var response = await http.get(uri);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var hints = data['hints'] as List;
        
        if (hints.isNotEmpty) {
          for (var hint in hints) {
            var food = hint['food'];
            if (food != null) {
              results.add(FoodItem.fromEdamam(food));
            }
          }
          
          if (results.isNotEmpty) {
            return results;
          }
        }
      }
    } catch (e) {
      print('Edamam API Error: $e');
    }

    var localData = NutritionData.getLocalFoodData(foodName);
    if (localData != null) {
      results.add(FoodItem.fromLocal(localData, foodName));
    } else {
      for (var foodName in NutritionData.vietnameseFoods.keys) {
        results.add(FoodItem.fromLocal(NutritionData.vietnameseFoods[foodName], foodName));
      }
    }

    return results;
  }

  static Future<FoodItem> getFoodByName(String foodName) async {
    List<FoodItem> results = await searchFoods(foodName);
    if (results.isNotEmpty) {
      return results.first;
    }
    
    return FoodItem(
      name: foodName,
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      imageUrl: '',
    );
  }
}