import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/models.dart';

class AiService {
  // ⚠️ TODO: Replace this key before production deployment
  // Move to Firebase Cloud Function or Remote Config for security
  static const String _apiKey = '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';

  /// Generate a workout plan using Claude
  Future<WorkoutPlan?> generateWorkoutPlan({
    required String goal,
    required String level,
    required int durationMins,
    required List<String> equipment,
    String? focusArea,
    String? injuries,
  }) async {
    final prompt = '''
Generate a workout plan in JSON format. Requirements:
- Goal: $goal
- Level: $level
- Duration: $durationMins minutes
- Equipment: ${equipment.join(', ')}
${focusArea != null ? '- Focus: $focusArea' : ''}
${injuries != null ? '- Injuries/Limitations: $injuries' : ''}

Return ONLY valid JSON (no markdown, no explanation) in this exact format:
{
  "name": "Plan Name",
  "aiNotes": "Brief tip or motivation",
  "exercises": [
    {
      "name": "Exercise Name",
      "sets": 3,
      "reps": 12,
      "durationSecs": 0,
      "restSecs": 60,
      "notes": "Form tip",
      "caloriesPerMin": 5
    }
  ]
}

Include warm-up and cool-down. Use durationSecs>0 for timed exercises (planks, cardio), reps>0 for rep-based.
Generate 6-10 exercises total that fit within $durationMins minutes.
''';

    try {
      final data = await _callClaude(prompt);
      if (data == null) return null;

      final json = jsonDecode(data);
      return WorkoutPlan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        name: json['name'] ?? 'AI Workout',
        goal: goal,
        level: level,
        durationMins: durationMins,
        exercises: (json['exercises'] as List)
            .map((e) => WorkoutExercise.fromMap(e))
            .toList(),
        createdAt: DateTime.now(),
        aiNotes: json['aiNotes'],
      );
    } catch (e) {
      print('AI Workout Error: $e');
      return null;
    }
  }

  /// Generate a meal plan using Claude
  Future<MealPlan?> generateMealPlan({
    required String dietType,
    required int targetCalories,
    required double proteinPct,
    required double carbsPct,
    required double fatPct,
    String? allergies,
    String? cuisine,
    int meals = 4,
  }) async {
    final proteinG = (targetCalories * proteinPct / 100 / 4).round();
    final carbsG = (targetCalories * carbsPct / 100 / 4).round();
    final fatG = (targetCalories * fatPct / 100 / 9).round();

    final prompt = '''
Generate a full day meal plan in JSON format. Requirements:
- Diet Type: $dietType
- Target: $targetCalories calories
- Macros: ${proteinG}g protein, ${carbsG}g carbs, ${fatG}g fat
- Number of meals: $meals (breakfast, lunch, dinner${meals > 3 ? ', snack' : ''})
${allergies != null ? '- Allergies/Avoid: $allergies' : ''}
${cuisine != null ? '- Preferred Cuisine: $cuisine' : ''}

Return ONLY valid JSON (no markdown, no explanation):
{
  "name": "Plan Name",
  "aiNotes": "Nutrition tip",
  "meals": [
    {
      "type": "breakfast",
      "name": "Meal Name",
      "calories": 500,
      "proteinG": 30,
      "carbsG": 50,
      "fatG": 15,
      "fiberG": 8,
      "ingredients": ["ingredient 1 - amount", "ingredient 2 - amount"],
      "recipe": "Brief cooking instructions"
    }
  ]
}

Make meals practical, tasty, and easy to prepare. Include specific amounts.
''';

    try {
      final data = await _callClaude(prompt);
      if (data == null) return null;

      final json = jsonDecode(data);
      return MealPlan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        name: json['name'] ?? 'AI Meal Plan',
        dietType: dietType,
        targetCalories: targetCalories,
        meals: (json['meals'] as List).map((m) => Meal.fromMap(m)).toList(),
        date: DateTime.now(),
        macros: MacroTargets(
          proteinPct: proteinPct,
          carbsPct: carbsPct,
          fatPct: fatPct,
        ),
        aiNotes: json['aiNotes'],
      );
    } catch (e) {
      print('AI Meal Error: $e');
      return null;
    }
  }

  /// Analyze food photo using Claude Vision
  Future<FoodScanResult?> analyzeFood(String base64Image) async {
    try {
      final url = '${AppConstants.geminiApiUrl}/${AppConstants.geminiModel}:generateContent?key=${AppConstants.geminiApiKey}';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image,
                  }
                },
                {
                  'text': '''Analyze this food photo. Return ONLY JSON (no markdown, no explanations):
{
  "foodName": "Name of food",
  "estimatedCalories": 500,
  "proteinG": 25,
  "carbsG": 50,
  "fatG": 15,
  "servingSize": "1 plate (~350g)",
  "confidence": "high/medium/low",
  "ingredients": ["ingredient1", "ingredient2"]
}
Be as accurate as possible with calorie estimation based on portion size visible.'''
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        String text = result['candidates'][0]['content']['parts'][0]['text'];
        // Strip markdown fences
        text = text.replaceAll(RegExp(r'```json\s*'), '');
        text = text.replaceAll(RegExp(r'```\s*'), '');
        text = text.trim();
        
        final json = jsonDecode(text);
        return FoodScanResult(
          foodName: json['foodName'] ?? 'Unknown',
          estimatedCalories: json['estimatedCalories'] ?? 0,
          proteinG: (json['proteinG'] ?? 0).toDouble(),
          carbsG: (json['carbsG'] ?? 0).toDouble(),
          fatG: (json['fatG'] ?? 0).toDouble(),
          servingSize: json['servingSize'],
          confidence: json['confidence'],
          ingredients: List<String>.from(json['ingredients'] ?? []),
        );
      } else {
        print('Gemini Vision Error: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      print('Food Scan Error: $e');
      return null;
    }
  }

  /// Generate weekly progress report
  Future<String?> generateWeeklyReport({
    required int workoutsCompleted,
    required int caloriesBurned,
    required double avgWaterMl,
    required List<double> weights,
    required int streakDays,
  }) async {
    final prompt = '''
Generate a brief, motivational weekly fitness progress report. Data:
- Workouts completed: $workoutsCompleted
- Calories burned: $caloriesBurned
- Average daily water: ${avgWaterMl.round()}ml
- Weight trend: ${weights.map((w) => '${w}kg').join(' → ')}
- Current streak: $streakDays days

Write 3-4 sentences: summary, highlight, area to improve, motivation.
Keep it personal and encouraging. No JSON, just plain text.
''';

    return await _callClaude(prompt);
  }

  /// Generate grocery list from meal plan
  Future<List<GroceryItem>> generateGroceryList(MealPlan plan) async {
    final allIngredients =
        plan.meals.expand((m) => m.ingredients).toList().join('\n- ');

    final prompt = '''
From this ingredient list, create an organized grocery list. Ingredients:
- $allIngredients

Return ONLY JSON array (no markdown):
[
  {"name": "Item name", "category": "produce/dairy/protein/grains/pantry/frozen/other", "quantity": "500g"}
]

Combine duplicate ingredients, round up quantities. Sort by category.
''';

    try {
      final data = await _callClaude(prompt);
      if (data == null) return [];

      final list = jsonDecode(data) as List;
      return list
          .map((item) => GroceryItem(
                name: item['name'],
                category: item['category'] ?? 'other',
                quantity: item['quantity'] ?? '',
              ))
          .toList();
    } catch (e) {
      print('Grocery List Error: $e');
      return [];
    }
  }

  /// Core Gemini API call (text generation)
  Future<String?> _callClaude(String prompt) async {
    try {
      final url = '${AppConstants.geminiApiUrl}/${AppConstants.geminiModel}:generateContent?key=${AppConstants.geminiApiKey}';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 2048,
            'topP': 0.95,
          },
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // Gemini response structure
        String text = result['candidates'][0]['content']['parts'][0]['text'];
        // Strip markdown code fences if present
        text = text.replaceAll(RegExp(r'```json\s*'), '');
        text = text.replaceAll(RegExp(r'```\s*'), '');
        return text.trim();
      } else {
        print('Gemini API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Gemini API Exception: $e');
      return null;
    }
  }
}
