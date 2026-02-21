import 'package:flutter/material.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(title: const Text('Reminders')),
      body: const Center(
        child: Text(
          'Reminders coming soon',
          style: TextStyle(fontFamily: 'Inter Medium'),
        ),
      ),
    );
  }
}
