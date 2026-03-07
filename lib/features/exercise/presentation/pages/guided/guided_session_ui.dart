import 'package:flutter/material.dart';

class GuidedProgressHeader extends StatelessWidget {
  const GuidedProgressHeader({
    super.key,
    required this.progress,
    required this.statusText,
    required this.trailingText,
    this.progressColor = const Color(0xFF2D5A44),
  });

  final double progress;
  final String statusText;
  final String trailingText;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    final normalized = progress.clamp(0.0, 1.0);
    final percent = (normalized * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE7E1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F2A22).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontFamily: 'Inter Bold',
                    fontSize: 13,
                    color: Color(0xFF1F2A22),
                  ),
                ),
              ),
              Text(
                trailingText,
                style: const TextStyle(
                  fontFamily: 'Inter Medium',
                  fontSize: 12,
                  color: Color(0xFF5A6B60),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontFamily: 'Inter Bold',
                  fontSize: 12,
                  color: Color(0xFF2D5A44),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: normalized,
              minHeight: 8,
              color: progressColor,
              backgroundColor: const Color(0xFFEAF1ED),
            ),
          ),
        ],
      ),
    );
  }
}

class GuidedHeroCard extends StatelessWidget {
  const GuidedHeroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.highlightText,
    required this.footerText,
    required this.gradientColors,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String highlightText;
  final String footerText;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors.length >= 2
        ? gradientColors
        : const [Color(0xFF2D5A44), Color(0xFF4E7A64)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors[0], colors[1]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F2A22).withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter Bold',
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Inter Regular',
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            highlightText,
            style: const TextStyle(
              fontFamily: 'Inter Bold',
              fontSize: 30,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            footerText,
            style: TextStyle(
              fontFamily: 'Inter Medium',
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class GuidedSectionCard extends StatelessWidget {
  const GuidedSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE7E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2D5A44)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter Bold',
                  fontSize: 14,
                  color: Color(0xFF1F2A22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
