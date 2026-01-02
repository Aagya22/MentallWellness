import 'package:flutter/material.dart';
import 'package:mentalwellness/widgets/home_favouritesection.dart';
import 'package:mentalwellness/widgets/home_topbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white12,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const
          [
            HomeTopBar(),
            const SizedBox(height: 20),
            HomeFavouritesection(),
          ]
        ),
      )),
    );
  }
}