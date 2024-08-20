import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    // Define other light theme properties here
  );

  static ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.grey,
    brightness: Brightness.dark,
    textTheme: ThemeData.dark().textTheme.copyWith(
          // Set the text color to white in dark mode
          bodyLarge: const TextStyle(color: Colors.white),
          bodyMedium: const TextStyle(color: Colors.white),
        ),
    // Define other dark theme properties here
  );

  static Future<bool> getThemePreference() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isDarkMode = prefs.getBool('isDarkMode') ?? false;
  print('Theme preference retrieved: $isDarkMode');
  return isDarkMode;
}

static Future<void> setThemePreference(bool isDarkMode) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isDarkMode', isDarkMode);
  print('Theme preference set: $isDarkMode');
}


  static Future<ThemeData> getSavedTheme() async {
    bool isDarkMode = await getThemePreference();
    return getTheme(isDarkMode);
  }

  static ThemeData getTheme(bool isDarkMode) {
    return isDarkMode ? darkTheme : lightTheme;
  }

  static Future<void> onUserLogin() async {
    bool isDarkMode = await getThemePreference();
    // Set the theme based on the saved preference
    if (isDarkMode) {
      // Set dark mode theme
      return;
    } else {
      // Set light mode theme
      return;
    }
  }

  static Future<void> onUserLogout() async {
    // Preserve the current theme preference
    bool isDarkMode = await getThemePreference();
    // Do not change the theme preference when logging out
  }
}
