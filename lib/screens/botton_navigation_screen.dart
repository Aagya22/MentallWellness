import 'package:flutter/material.dart';
import 'package:mentalwellness/screens/botton_screen/calendar_screen.dart';
import 'package:mentalwellness/screens/botton_screen/home_screen.dart';
import 'package:mentalwellness/screens/botton_screen/profile_screen.dart';
import 'package:mentalwellness/screens/botton_screen/timer_screen.dart';

class BottomNavigationScreen extends StatefulWidget {
  const BottomNavigationScreen({super.key});

  @override
  State<BottomNavigationScreen> createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigationScreen> {
int _selectedIndex=0;

  List<Widget> lstBottomScreen=[
    const HomeScreen (),
    const CalendarScreen(),
    const TimerScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DashboardScreen'),
        centerTitle: true,
      ),
      body: lstBottomScreen[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const[
          BottomNavigationBarItem(
            icon:Icon(Icons.home),
           label: 'Home'),
           BottomNavigationBarItem(icon: Icon(Icons.calendar_today),
           label: 'Calendar',
           ),
          BottomNavigationBarItem(
            icon:Icon(Icons.timer),
           label: 'Timer'),
           BottomNavigationBarItem(
            icon:Icon(Icons.person),
           label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: (index){
          setState(() {
            _selectedIndex=index;
          });
        },
      ),

    );
  }
}