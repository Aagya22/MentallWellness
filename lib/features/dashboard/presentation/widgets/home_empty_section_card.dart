import 'package:flutter/material.dart';

class HomeEmptySectionCard extends StatelessWidget {
  const HomeEmptySectionCard({
    super.key,
    required this.icon,
    required this.message,
    required this.ctaText,
    required this.onTap,
  });

  final IconData icon;
  final String message;
  final String ctaText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1ED),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: const Color(0xFF2D5A44), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'Inter Medium',
                      fontSize: 13,
                      color: Color(0xFF1F2A22),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1ED),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ctaText,
                      style: const TextStyle(
                        fontFamily: 'Inter Bold',
                        fontSize: 11,
                        color: Color(0xFF2D5A44),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF7B8A7E),
            ),
          ],
        ),
      ),
    );
  }
}
