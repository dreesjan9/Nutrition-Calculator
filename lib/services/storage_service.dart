import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _nutritionDataKey = 'nutrition_data';
  static const String _sportSettingsKey = 'sport_settings';
  static const String _savedConfigurationsKey = 'saved_configurations';
  static const String _lastConfigurationKey = 'last_configuration';

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

  static Future<List<Map<String, dynamic>>> loadSavedConfigurations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_savedConfigurationsKey);
      if (jsonString == null) {
        return [];
      }

      final decoded = jsonDecode(jsonString);
      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => item.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveConfiguration(
    Map<String, dynamic> configuration,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configurations = await loadSavedConfigurations();
      final id = configuration['id'];

      configurations.removeWhere((item) => item['id'] == id);
      configurations.insert(0, configuration);

      await prefs.setString(
        _savedConfigurationsKey,
        jsonEncode(configurations),
      );
    } catch (e) {
      // Handle error silently for production
    }
  }

  static Future<void> deleteConfiguration(String configurationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configurations = await loadSavedConfigurations();
      configurations.removeWhere((item) => item['id'] == configurationId);
      await prefs.setString(
        _savedConfigurationsKey,
        jsonEncode(configurations),
      );
    } catch (e) {
      // Handle error silently for production
    }
  }

  static Future<void> saveLastConfiguration(
    Map<String, dynamic> configuration,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastConfigurationKey, jsonEncode(configuration));
    } catch (e) {
      // Handle error silently for production
    }
  }

  static Future<Map<String, dynamic>?> loadLastConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_lastConfigurationKey);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      // Handle error silently for production
    }
    return null;
  }

  static const String _crashCheckKey = 'crash_check';

  static Future<void> checkSafetyMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_crashCheckKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // If the app crashed within 5 seconds of the last start
      if (now - lastCheck < 5000) {
        debugPrint('CRASH LOOP DETECTED: Clearing all local data for safety.');
        await clearAllData();
      }
      
      await prefs.setInt(_crashCheckKey, now);
    } catch (e) {
      // Ignore errors in safety check
    }
  }

  // Clear all stored data
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_nutritionDataKey);
      await prefs.remove(_sportSettingsKey);
      await prefs.remove(_savedConfigurationsKey);
      await prefs.remove(_lastConfigurationKey);
    } catch (e) {
      // Handle error silently for production
    }
  }
}
