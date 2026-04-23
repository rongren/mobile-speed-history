import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('설정',
            style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Text('설정 화면 준비 중',
            style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}