import 'package:flutter/material.dart';

class StationeryTheme {
  final String id;
  final String name;
  final String emoji;
  final Color background;
  final Color textColor;
  final Color accentColor;
  final Color cardBorderColor;

  const StationeryTheme({
    required this.id,
    required this.name,
    required this.emoji,
    required this.background,
    required this.textColor,
    required this.accentColor,
    required this.cardBorderColor,
  });

  static const List<StationeryTheme> all = [
    StationeryTheme(
      id: 'blush',
      name: 'Blush Pink',
      emoji: '🌸',
      background: Color(0xFFFFF0F3),
      textColor: Color(0xFF4A1521),
      accentColor: Color(0xFFFF6B81),
      cardBorderColor: Color(0xFFFFCCD5),
    ),
    StationeryTheme(
      id: 'parchment',
      name: 'Vintage Parchment',
      emoji: '📜',
      background: Color(0xFFFBF6EB),
      textColor: Color(0xFF3B2F22),
      accentColor: Color(0xFFD4A373),
      cardBorderColor: Color(0xFFE9DAC1),
    ),
    StationeryTheme(
      id: 'midnight',
      name: 'Midnight Sky',
      emoji: '🌙',
      background: Color(0xFF1E1E2E),
      textColor: Color(0xFFF0F0FF),
      accentColor: Color(0xFF9B8AFB),
      cardBorderColor: Color(0xFF3E3B5B),
    ),
    StationeryTheme(
      id: 'sunset',
      name: 'Sunset Glow',
      emoji: '🌅',
      background: Color(0xFFFFF4EC),
      textColor: Color(0xFF4A2511),
      accentColor: Color(0xFFFF8A5C),
      cardBorderColor: Color(0xFFFFD5C2),
    ),
  ];

  static StationeryTheme getById(String? id) {
    return all.firstWhere(
      (theme) => theme.id == id,
      orElse: () => all.first,
    );
  }
}
