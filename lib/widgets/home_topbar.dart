import 'package:flutter/material.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.orangeAccent,
              child: const Icon(Icons.face_2, color: Colors.black),
            ),
            const SizedBox(width: 8),
            const Text(
              "Welcome",
              style: TextStyle(
                fontFamily: 'PlayfairDisplay Regular',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const Icon(Icons.local_fire_department, size: 28,color:Colors.amber),
        

      ],
    );
  }
}
