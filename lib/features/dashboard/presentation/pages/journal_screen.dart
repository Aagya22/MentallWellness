import 'package:flutter/material.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(title: const Text('Journal')),
      body: const Center(
        child: Text(
          'Journaling coming soon',
          style: TextStyle(fontFamily: 'Inter Medium'),
        ),
      ),
    );
  }
}
