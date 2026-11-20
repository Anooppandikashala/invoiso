import 'package:flutter/material.dart';

/// Rounded-square initials badge for a company (login picker, Manage
/// Companies). Colour is picked from the company id, so it stays the same
/// across runs and renames.
class CompanyAvatar extends StatelessWidget {
  final String id;
  final String name;
  final double size;

  const CompanyAvatar(
      {super.key, required this.id, required this.name, this.size = 40});

  static const _colors = [
    Color(0xFF2563EB),
    Color(0xFF0E7490),
    Color(0xFF7C3AED),
    Color(0xFFB45309),
    Color(0xFF15803D),
    Color(0xFFBE185D),
  ];

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final colorIndex = id.codeUnits.fold(0, (a, b) => a + b) % _colors.length;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _colors[colorIndex],
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Text(
        initials,
        style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.36),
      ),
    );
  }
}
