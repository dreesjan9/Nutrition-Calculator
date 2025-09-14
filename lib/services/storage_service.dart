import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _nutritionDataKey = 'nutrition_data';
  static const String _sportSettingsKey = 'sport_settings';

  // Save nutrition data to local storage
  static Future<void> saveNutritionData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data);
      await prefs.setString(_nutritionDataKey, jsonString);
    } catch (e) {
      // Handle error silently for production
    }
  }

  // Load nutrition data from local storage
  static Future<Map<String, dynamic>?> loadNutritionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_nutritionDataKey);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      // Handle error silently for production
    }
    return null;
  }

  // Save sport settings (target values, durations)
  static Future<void> saveSportSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(settings);
      await prefs.setString(_sportSettingsKey, jsonString);
    } catch (e) {
      // Handle error silently for production
    }
  }

  // Load sport settings
  static Future<Map<String, dynamic>?> loadSportSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_sportSettingsKey);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      // Handle error silently for production
    }
    return null;
  }

  // Clear all stored data
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_nutritionDataKey);
      await prefs.remove(_sportSettingsKey);
    } catch (e) {
      // Handle error silently for production
    }
  }
}