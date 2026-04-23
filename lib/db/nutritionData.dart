class NutritionData {
  static Map<String, Map<String, dynamic>> vietnameseFoods = {
    'Phở bò': {
      'calories': 350,
      'protein': 20,
      'carbs': 40,
      'fat': 10,
    },
    'Phở gà': {
      'calories': 300,
      'protein': 18,
      'carbs': 38,
      'fat': 8,
    },
    'Cơm': {
      'calories': 130,
      'protein': 2.7,
      'carbs': 28,
      'fat': 0.3,
    },
    'Cơm trắng': {
      'calories': 130,
      'protein': 2.7,
      'carbs': 28,
      'fat': 0.3,
    },
    'Cơm gà': {
      'calories': 280,
      'protein': 15,
      'carbs': 45,
      'fat': 6,
    },
    'Cơm tấm': {
      'calories': 320,
      'protein': 12,
      'carbs': 55,
      'fat': 8,
    },
    'Bánh mì': {
      'calories': 265,
      'protein': 9,
      'carbs': 49,
      'fat': 3.2,
    },
    'Bánh mì thịt': {
      'calories': 350,
      'protein': 15,
      'carbs': 45,
      'fat': 12,
    },
    'Trứng': {
      'calories': 155,
      'protein': 13,
      'carbs': 1.1,
      'fat': 11,
    },
    'Trứng chiên': {
      'calories': 196,
      'protein': 14,
      'carbs': 1.3,
      'fat': 15,
    },
    'Bún': {
      'calories': 100,
      'protein': 2,
      'carbs': 24,
      'fat': 0.5,
    },
    'Mì': {
      'calories': 138,
      'protein': 4,
      'carbs': 25,
      'fat': 2,
    },
    'Miến': {
      'calories': 110,
      'protein': 1,
      'carbs': 26,
      'fat': 0.5,
    },
    'Thịt bò': {
      'calories': 250,
      'protein': 26,
      'carbs': 0,
      'fat': 15,
    },
    'Thịt heo': {
      'calories': 242,
      'protein': 27,
      'carbs': 0,
      'fat': 14,
    },
    'Thịt gà': {
      'calories': 165,
      'protein': 31,
      'carbs': 0,
      'fat': 3.6,
    },
    'Cá': {
      'calories': 136,
      'protein': 20,
      'carbs': 0,
      'fat': 5,
    },
    'Tôm': {
      'calories': 99,
      'protein': 24,
      'carbs': 0.2,
      'fat': 0.3,
    },
    'Gạo': {
      'calories': 130,
      'protein': 2.7,
      'carbs': 28,
      'fat': 0.3,
    },
    'Rau muống': {
      'calories': 23,
      'protein': 2.5,
      'carbs': 3.3,
      'fat': 0.2,
    },
    'Canh chua': {
      'calories': 50,
      'protein': 4,
      'carbs': 6,
      'fat': 1,
    },
    'Bún chả': {
      'calories': 400,
      'protein': 18,
      'carbs': 50,
      'fat': 15,
    },
    'Bánh cuốn': {
      'calories': 150,
      'protein': 6,
      'carbs': 25,
      'fat': 3,
    },
    'Bánh bao': {
      'calories': 220,
      'protein': 8,
      'carbs': 38,
      'fat': 4,
    },
    'Xôi': {
      'calories': 230,
      'protein': 5,
      'carbs': 48,
      'fat': 3,
    },
    'Cháo': {
      'calories': 70,
      'protein': 2,
      'carbs': 14,
      'fat': 0.5,
    },
    'Bánh xèo': {
      'calories': 300,
      'protein': 10,
      'carbs': 35,
      'fat': 14,
    },
    'Gỏi cuốn': {
      'calories': 120,
      'protein': 5,
      'carbs': 18,
      'fat': 3,
    },
    'Cà phê': {
      'calories': 2,
      'protein': 0.3,
      'carbs': 0,
      'fat': 0,
    },
    'Sinh tố bơ': {
      'calories': 180,
      'protein': 4,
      'carbs': 22,
      'fat': 10,
    },
  };

  static Map<String, Map<String, dynamic>> getLocalFoodData(String name) {
    String queryLower = name.toLowerCase();
    for (var foodName in vietnameseFoods.keys) {
      if (foodName.toLowerCase().contains(queryLower) ||
          queryLower.contains(foodName.toLowerCase())) {
        return vietnameseFoods[foodName];
      }
    }
    return null;
  }
}