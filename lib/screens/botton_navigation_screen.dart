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
  int _selectedIndex = 0;

  final List<Widget> lstBottomScreen = [
    const HomeScreen(),
    const CalendarScreen(),
    const TimerScreen(),
    const ProfileScreen(),
  ];

  final List<IconData> _icons = [
    Icons.home,
    Icons.calendar_today,
    Icons.timer,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: lstBottomScreen[_selectedIndex],

      bottomNavigationBar: SizedBox(
        height: 65, 
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 65,
              color: const Color(0xFFB71C1C),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(4, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    child: Icon(
                      _icons[index],
                      size: 28,
                      color: _selectedIndex == index
                          ? Colors.transparent
                          : Colors.white,
                    ),
                  );
                }),
              ),
            ),

            Positioned(
              left: _getSelectedIconPosition(context),
              top: -25,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  _icons[_selectedIndex],
                  color: Colors.black,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getSelectedIconPosition(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double itemWidth = width / 4;
    return itemWidth * _selectedIndex + itemWidth / 2 - 30;
  }
}
