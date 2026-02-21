import 'package:flutter/material.dart';

class MoodScreen extends StatelessWidget {
  const MoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(title: const Text('Mood')),
      body: const Center(
        child: Text(
          'Mood tracking coming soon',
          style: TextStyle(fontFamily: 'Inter Medium'),
        ),
      ),
    );
  }
}
