
import 'dart:convert';

import 'package:flanner/Pages/Theme/Theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Habit {
  String title;
  String description;
  DateTime startDate;
  DateTime endDate; // Track the end date for the habit goal
  Map<DateTime, bool> dates; // Track completed days
  bool isCompleted; // Flag to check if the habit's goal is completed
  List<Achievement> achievements; // List of achievements earned

  Habit({
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.dates,
    this.isCompleted = false,
    this.achievements = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'dates':
      dates.map((key, value) => MapEntry(key.toIso8601String(), value)),
      'is_completed': isCompleted,
      'achievements':
      achievements.map((achievement) => achievement.toMap()).toList(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      title: map['title'],
      description: map['description'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      dates: (map['dates'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(DateTime.parse(key), value as bool)),
      isCompleted: map['is_completed'],
      achievements: (map['achievements'] as List<dynamic>)
          .map((achievement) => Achievement.fromMap(achievement))
          .toList(),
    );
  }

  bool isPlannedFor(DateTime day) {
    // if (kDebugMode) {
    //   print(startDate);
    //   print(day);
    //   print(endDate);
    // }
    return (day.isAfter(startDate.subtract(Duration(days: 1))) &&
        day.isBefore(endDate.add(Duration(days: 1))));
  }

  int getCompletedDays() {
    return dates.values
        .where((value) => value == true)
        .length;
  }

  int getSkippedDays() {
    return dates.values
        .where((value) => value == false)
        .length;
  }

  double getProgress() {
    final totalPlannedDays = endDate
        .difference(DateTime.now())
        .inDays + 2;
    if (kDebugMode) {
      print('totalPlannedDays: $totalPlannedDays');
    }
    if (totalPlannedDays == 0) return 0;
    return getCompletedDays() / totalPlannedDays;
  }

  void completeGoal(context) {
    isCompleted = true;
    achievements.add(Achievement(
      title: AppLocalizations.of(context)!.completed(title),
      description: AppLocalizations.of(context)!.description(title),
      dateAchieved: endDate,
    ));
  }

  int getCurrentDays() {
    final totalPlannedDays = endDate
        .difference(DateTime.now())
        .inDays + 2;
    return totalPlannedDays - getSkippedDays();
  }
}

class Achievement {
  String title;
  String description;
  DateTime dateAchieved;

  Achievement({
    required this.title,
    required this.description,
    required this.dateAchieved,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date_achieved': dateAchieved.toIso8601String(),
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      title: map['title'],
      description: map['description'],
      dateAchieved: DateTime.parse(map['date_achieved']),
    );
  }
}


class HabitNotifier extends StateNotifier<List<Habit>> {

  HabitNotifier() : super([]);

  Future<void> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'habits';
    final habitsString = prefs.getString(key);
    if (habitsString != null) {
      final habits = (json.decode(habitsString) as List<dynamic>)
          .map((habit) => Habit.fromMap(habit))
          .toList();
      state = habits;
    }
  }

  Future<void> saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'habits';
    final habitsString = json.encode(state.map((habit) => habit.toMap()).toList());
    await prefs.setString(key, habitsString);
  }

  void addHabit(Habit habit) {
    state = [...state, habit];
  }

  void removeHabit(Habit habit) {
    state = state.where((element) => element.title != habit.title).toList();
  }

  void completeHabit(Habit habit) {
    state = state
        .where((element) => element.title != habit.title)
        .map((element) {
      if (element.title == habit.title) {
        element.completeGoal(habit);
      }
      return element;
    }).toList();
  }
}

final habitNotifierProvider = StateNotifierProvider<HabitNotifier, List<Habit>>((ref) => HabitNotifier());


