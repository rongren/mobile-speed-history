import 'package:flutter/material.dart';

class GoalScreen extends StatelessWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('목표',
            style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Text('목표 화면 준비 중',
            style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}