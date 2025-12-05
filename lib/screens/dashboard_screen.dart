import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Screen'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Text('Welcome to the Dashboard Screen!'),
    
      
    );
  }
}
