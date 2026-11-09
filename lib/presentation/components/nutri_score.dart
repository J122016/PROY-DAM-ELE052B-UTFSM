import 'package:flutter/material.dart';

const nutriScoreColors = {
  'a': Color(0xFF038141),
  'b': Color(0xFF85BB2F),
  'c': Color(0xFFFECB02),
  'd': Color(0xFFEE8100),
  'e': Color(0xFFE63E11),
};

Color nutriScoreTextColor(String grade) =>
    grade == 'c' ? const Color(0xFF1E293B) : Colors.white;

class NutriScoreBadge extends StatelessWidget {
  const NutriScoreBadge({required this.grade, super.key});

  final String grade;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: nutriScoreColors[grade],
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      'Nutri ${grade.toUpperCase()}',
      style: TextStyle(
        color: nutriScoreTextColor(grade),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class NutriScoreScale extends StatelessWidget {
  const NutriScoreScale({required this.grade, super.key});

  final String grade;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final entry in nutriScoreColors.entries)
        Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Opacity(
            opacity: entry.key == grade ? 1 : 0.35,
            child: Container(
              width: entry.key == grade ? 32 : 20,
              height: entry.key == grade ? 32 : 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: entry.value,
                borderRadius: BorderRadius.circular(6),
                border: entry.key == grade
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              child: Text(
                entry.key.toUpperCase(),
                style: TextStyle(
                  color: nutriScoreTextColor(entry.key),
                  fontSize: entry.key == grade ? 15 : 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
