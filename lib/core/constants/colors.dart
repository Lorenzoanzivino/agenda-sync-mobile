import 'package:flutter/material.dart';

class AppAtmospheres {
  // Palette Autenticazione Dedicata (Neon Ciber-Cyan/Deep Ocean)
  static const Color authBg = Color(0xFF0F172A);
  static const List<Color> authCircles = [
    Color(0xFF0EA5E9),
    Color(0xFF2563EB),
    Color(0xFF1D4ED8),
  ];

  // Privato (Viola Elettrico Acceso)
  static const Color privateBg = Color(0xFF2E0854);
  static const List<Color> privateCircles = [
    Color(0xFF7B2CBF),
    Color(0xFF9D4EDD),
    Color(0xFFC77DFF),
  ];

  // Condiviso 1 (Verde Smeraldo Petrolio Brillante)
  static const Color sharedBg = Color(0xFF004B49);
  static const List<Color> sharedCircles = [
    Color(0xFF008B8B),
    Color(0xFF20B2AA),
    Color(0xFF00FFFF),
  ];

  // Condiviso 2 (Rosso Corallo Vivo / Fuoco)
  static const Color sharedBg2 = Color(0xFF5A0E1A);
  static const List<Color> sharedCircles2 = [
    Color(0xFF9B1C31),
    Color(0xFFD90429),
    Color(0xFFEF233C),
  ];

  // Condiviso 3 (Cobalto Notturno Neon)
  static const Color sharedBg3 = Color(0xFF0B2545);
  static const List<Color> sharedCircles3 = [
    Color(0xFF134074),
    Color(0xFF8DA9C4),
    Color(0xFFEEF4F8),
  ];

  // Condiviso 4 (Verde Lime Acido / Muschio Brillante)
  static const Color sharedBg4 = Color(0xFF132A13);
  static const List<Color> sharedCircles4 = [
    Color(0xFF31572C),
    Color(0xFF4F772D),
    Color(0xFF90A955),
  ];

  static Color getSharedBg(int index) {
    final colors = [sharedBg, sharedBg2, sharedBg3, sharedBg4];
    return colors[index % colors.length];
  }

  static List<Color> getSharedCircles(int index) {
    final circles = [
      sharedCircles,
      sharedCircles2,
      sharedCircles3,
      sharedCircles4,
    ];
    return circles[index % circles.length];
  }
}
