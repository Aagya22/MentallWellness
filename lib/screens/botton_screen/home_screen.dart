import 'package:flutter/material.dart';

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
          children: 
          [
            _topBar()
            
          ]
        ),
      )),
    );
  }
  Widget _topBar(){
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: const Icon(Icons.face_2, color: Colors.black),
            ),],
    )
    ],
  );
  }
}