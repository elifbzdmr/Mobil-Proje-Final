import 'package:flutter/material.dart';

import '../models/mood.dart';

class MoodCard extends StatelessWidget {
  const MoodCard({
    super.key,
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  final Mood mood;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final moodColor = Color(mood.colorHex);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected
              ? moodColor.withValues(alpha: 0.18)
              : Theme.of(context).cardTheme.color,
          border: Border.all(
            color: isSelected
                ? moodColor
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(mood.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              mood.label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
