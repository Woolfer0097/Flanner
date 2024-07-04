import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CalorieGainScreen extends StatefulWidget {
  @override
  _CalorieGainScreenState createState() => _CalorieGainScreenState();
}

class _CalorieGainScreenState extends State<CalorieGainScreen> {
  String? selectedFood;
  double caloriesGained = 0.0;
  TextEditingController foodController = TextEditingController();
  TextEditingController caloriesController = TextEditingController();

  late AppLocalizations localizations; // Changed to non-nullable

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localizations = AppLocalizations.of(context)!; // Ensure non-null value
  }

  final List<String> foods = [
    'Apple',
    'Banana',
    'Sandwich',
    'Pizza',
    'Orange',
    'Burger',
    'Salad',
    'Steak',
    // Add more foods
  ];

  final Map<String, double> foodCalories = {
    'Apple': 52.0,
    'Banana': 89.0,
    'Sandwich': 200.0,
    'Pizza': 285.0,
    'Orange': 47.0,
    'Burger': 354.0,
    'Salad': 150.0,
    'Steak': 679.0,
    // Add more food and their calorie values
  };

  Future<void> saveCaloriesGained(double calories) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final key = 'calories_gained_$today';
    double totalCalories = (prefs.getDouble(key) ?? 0) + calories;
    await prefs.setDouble(key, totalCalories);
  }

  Future<double> getCaloriesGainedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final key = 'calories_gained_$today';
    return prefs.getDouble(key) ?? 0;
  }

  Future<double> getTotalCaloriesBurnedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final key = 'calories_burned_$today';
    return prefs.getDouble(key) ?? 0;
  }

  Future<double> getTotalCalories() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('totalCalories') ?? 0;
  }

  Future<void> setTotalCalories(double totalCalories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('totalCalories', totalCalories);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Builder(
          builder: (context) => Column(
            children: [
              DropdownButton<String>(
                value: selectedFood,
                hint: Text(localizations.select_food), // Localize hint
                onChanged: (newValue) {
                  setState(() {
                    selectedFood = newValue;
                    caloriesGained = foodCalories[newValue]!;
                  });
                },
                items: foods.map((food) {
                  return DropdownMenuItem(
                    child: Text(food),
                    value: food,
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              TextField(
                controller: foodController,
                decoration: InputDecoration(
                  labelText: localizations.enter_food, // Localize label
                ),
              ),
              TextField(
                controller: caloriesController,
                decoration: InputDecoration(
                  labelText: localizations.enter_calories, // Localize label
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    String food = foodController.text;
                    double calories = double.parse(caloriesController.text);
                    if (!foods.contains(food)) {
                      foods.add(food);
                    }
                    foodCalories[food] = calories;
                    selectedFood = food;
                    caloriesGained = calories;
                  });
                  foodController.clear();
                  caloriesController.clear();
                },
                child: Text(localizations.add_food), // Localize button text
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await saveCaloriesGained(caloriesGained);
                  double totalCaloriesGainedToday = await getCaloriesGainedToday();
                  double totalCaloriesBurnedToday = await getTotalCaloriesBurnedToday();
                  double currentTotalCalories = await getTotalCalories();

                  double newTotalCalories = currentTotalCalories - totalCaloriesBurnedToday + totalCaloriesGainedToday;
                  await setTotalCalories(newTotalCalories);

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: Text(
                        '${localizations.calories}: ${caloriesGained.toStringAsFixed(2)}\n'
                        '${localizations.total_calories_gained}: ${totalCaloriesGainedToday.toStringAsFixed(2)}\n'
                        '${localizations.new_total_calories}: ${newTotalCalories.toStringAsFixed(2)}',
                      ),
                    ),
                  );
                },
                child: Text(localizations.calculate), // Localize button text
              ),
            ],
          ),
        ),
      ),
    );
  }
}
