import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class GoalScreen extends StatelessWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<SettingsProvider>().appTheme == 'dark';
    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F4F7),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: Text(
            '목표 화면 준비 중',
            style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}
