import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/task_board_screen.dart';

void main() {
  runApp(const ProviderScope(child: TaskFlowApp()));
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const TaskBoardScreen(),
    );
  }

  ThemeData _buildTheme() {
    const obsidian = Color(0xFF0A0A0F);
    const surface = Color(0xFF12121A);
    const surface2 = Color(0xFF1C1C28);
    const gold = Color(0xFFC9A84C);
    const goldLight = Color(0xFFE8C97A);
    const textColor = Color(0xFFF5F0E8);
    const textMuted = Color(0xFF8A8490);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: obsidian,
      colorScheme: ColorScheme.dark(
        primary: gold,
        secondary: goldLight,
        surface: surface,
        onSurface: textColor,
        onPrimary: obsidian,
        error: const Color(0xFFFF6B6B),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xEC0A0A0F),
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x0FF5F0E8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0x0FF5F0E8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0x0FF5F0E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: textMuted, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: obsidian,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: gold),
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
        headlineMedium: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
        titleLarge: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        titleMedium: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(color: textColor, fontSize: 15),
        bodyMedium: TextStyle(color: textMuted, fontSize: 13),
        labelSmall: TextStyle(
          color: textMuted,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
