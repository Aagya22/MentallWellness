import 'package:flutter/material.dart';
import 'home_favouritecard.dart';

class HomeFavouritesection extends StatelessWidget {
  const HomeFavouritesection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "USER’S FAVOURITES",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: const [
              HomeFavouriteCard(
                color: Color(0xFF4F6D54),
                title: "BREATHE",
                icon: Icons.self_improvement,
                onTap: _noop,
              ),
              SizedBox(width: 16),
              HomeFavouriteCard(
                color: Color(0xFFD8CFCF),
                title: "RELAX",
                icon: Icons.spa,
                onTap: _noop,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static void _noop() {}
}
