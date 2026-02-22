import 'package:flutter/material.dart';
import 'package:mentalwellness/features/mood/presentation/widgets/mood_shared.dart';

class MoodPickerGrid extends StatelessWidget {
  const MoodPickerGrid({
    super.key,
    required this.selectedLabel,
    required this.onSelect,
  });

  final String? selectedLabel;
  final void Function(String label, int score) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: kMoodOptions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 92,
        ),
        itemBuilder: (context, index) {
          final option = kMoodOptions[index];
          final selected = selectedLabel == option.label;
          return _MoodPickItem(
            option: option,
            selected: selected,
            onTap: () => onSelect(option.label, option.score),
          );
        },
      ),
    );
  }
}

class _MoodPickItem extends StatelessWidget {
  const _MoodPickItem({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final MoodOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F1EA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF2D5A44) : const Color(0xFFEAF1ED),
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEAF1ED), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(option.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 10),
            Text(
              option.label,
              style: const TextStyle(
                fontFamily: 'Inter Medium',
                fontSize: 11,
                color: Color(0xFF1F2A22),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
