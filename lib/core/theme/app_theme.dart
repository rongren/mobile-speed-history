import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static ThemeData dark = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ).copyWith(
      surface: Colors.black,
      surfaceContainer: Colors.grey[900]!,
      surfaceContainerHighest: Colors.grey[800]!,
      onSurface: Colors.white,
      onSurfaceVariant: Colors.grey,
      outline: Colors.grey[500]!,
      outlineVariant: Colors.grey[700]!,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.black,
      indicatorColor: Colors.blue.withOpacity(0.2),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Colors.blue);
        }
        return const IconThemeData(color: Colors.grey);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: Colors.blue, fontSize: 12);
        }
        return const TextStyle(color: Colors.grey, fontSize: 12);
      }),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.blue,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Colors.blue,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.grey[900],
    ),
  );

  static ThemeData light = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFF2F4F7),
      surfaceContainer: Colors.white,
      surfaceContainerHighest: Colors.grey[200]!,
      onSurface: Colors.black87,
      onSurfaceVariant: Colors.grey[600]!,
      outline: Colors.grey[500]!,
      outlineVariant: Colors.grey[300]!,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Colors.blue.withOpacity(0.2),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Colors.blue);
        }
        return IconThemeData(color: Colors.grey[600]!);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: Colors.blue, fontSize: 12);
        }
        return TextStyle(color: Colors.grey[600]!, fontSize: 12);
      }),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: Colors.blue,
      unselectedLabelColor: Colors.grey[500],
      indicatorColor: Colors.blue,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
    ),
  );
}
