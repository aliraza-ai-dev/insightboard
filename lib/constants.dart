class AppConstants {
  // App Info
  static const String appName = 'FitGenius';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCol = 'users';
  static const String workoutsCol = 'workouts';
  static const String mealsCol = 'meals';
  static const String exercisesCol = 'exercises';
  static const String progressCol = 'progress';
  static const String waterCol = 'waterIntake';
  static const String weightCol = 'weightLogs';
  static const String streaksCol = 'streaks';
  static const String challengesCol = 'challenges';
  static const String badgesCol = 'badges';
  static const String groceryCol = 'groceryLists';
  static const String aiLimitsCol = 'aiLimits';

  // AI Config — GEMINI (Primary AI)
  static const String geminiApiKey = 'AIzaSyCxZvdU9umEKNVYQDhvLS9whKEdIKCBKlM';
  static const String geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const String geminiModel = 'gemini-2.0-flash';
  static const int dailyAiLimit = 20;

  // Legacy Claude (fallback/backup)
  static const String anthropicApiUrl = 'https://api.anthropic.com/v1/messages';
  static const String claudeModel = 'claude-sonnet-4-20250514';

  // ExerciseDB API (RapidAPI)
  // ⚠️ TODO: Replace this key before production deployment
  static const String rapidApiKey = '3040219cd1mshecd7052cad6f163p145823jsna167a6959204';
  static const String exerciseDbHost = 'exercisedb.p.rapidapi.com';
  static const String exerciseDbUrl = 'https://exercisedb.p.rapidapi.com';

  // Admin
  static const List<String> adminEmails = [
    'anasali7061@gmail.com',
  ];

  // Exercise Categories
  static const List<String> muscleGroups = [
    'Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core', 'Cardio', 'Full Body',
  ];

  // Equipment Types
  static const List<String> equipmentTypes = [
    'None (Bodyweight)', 'Dumbbells', 'Barbell', 'Resistance Bands',
    'Kettlebell', 'Pull-up Bar', 'Bench', 'Cable Machine', 'Full Gym',
  ];

  // Fitness Goals
  static const List<String> fitnessGoals = [
    'Lose Weight', 'Build Muscle', 'Get Stronger', 'Improve Endurance',
    'Stay Active', 'Flexibility', 'Athletic Performance',
  ];

  // Diet Types
  static const List<String> dietTypes = [
    'Balanced', 'Keto', 'Vegan', 'Vegetarian', 'Paleo',
    'Mediterranean', 'High Protein', 'Low Carb', 'Intermittent Fasting',
  ];

  // Experience Levels
  static const List<String> experienceLevels = [
    'Beginner', 'Intermediate', 'Advanced',
  ];

  // Water Goals (ml)
  static const int defaultWaterGoal = 3000;
  static const int waterGlassSize = 250;

  // Badges
  static const Map<String, Map<String, dynamic>> badges = {
    'first_workout': {'name': 'First Step', 'desc': 'Complete your first workout', 'icon': '🏃'},
    'streak_7': {'name': 'Week Warrior', 'desc': '7-day workout streak', 'icon': '🔥'},
    'streak_30': {'name': 'Monthly Beast', 'desc': '30-day workout streak', 'icon': '💪'},
    'streak_100': {'name': 'Centurion', 'desc': '100-day streak', 'icon': '🏆'},
    'water_master': {'name': 'Hydration King', 'desc': 'Hit water goal 7 days straight', 'icon': '💧'},
    'meal_planner': {'name': 'Nutrition Pro', 'desc': 'Generate 10 meal plans', 'icon': '🥗'},
    'weight_loss_5': {'name': '5kg Down', 'desc': 'Lost 5kg from start', 'icon': '⚖️'},
    'muscle_builder': {'name': 'Iron Pumper', 'desc': '50 strength workouts', 'icon': '🏋️'},
    'cardio_king': {'name': 'Cardio Machine', 'desc': '30 cardio sessions', 'icon': '❤️'},
    'early_bird': {'name': 'Early Bird', 'desc': '10 workouts before 7am', 'icon': '🌅'},
    'social_butterfly': {'name': 'Social Star', 'desc': 'Share 5 progress updates', 'icon': '⭐'},
    'scanner': {'name': 'Food Detective', 'desc': 'Scan 20 food photos', 'icon': '📷'},
  };
}
