import 'package:flutter/material.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(title: const Text('Exercises')),
      body: const Center(
        child: Text(
          'Exercise logs coming soon',
          style: TextStyle(fontFamily: 'Inter Medium'),
        ),
      ),
    );
  }
}
