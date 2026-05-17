import 'package:flutter/material.dart';

class AppAtmospheres {
  // Privato (Viola Melanzana profondo)
  static const Color privateBg = Color(0xFF2A1B38);
  static const List<Color> privateCircles = [
    Color(0xFF3B264D),
    Color(0xFF4C3363),
    Color(0xFF5E407A)
  ];

  // Condiviso 1 (Verde Petrolio scuro)
  static const Color sharedBg = Color(0xFF003B36);
  static const List<Color> sharedCircles = [
    Color(0xFF00524B),
    Color(0xFF006B62),
    Color(0xFF008579)
  ];

  // Condiviso 2 (Rosso Mattone scuro / Ruggine spento)
  static const Color sharedBg2 = Color(0xFF3E1C1A);
  static const List<Color> sharedCircles2 = [
    Color(0xFF542825),
    Color(0xFF6E3632),
    Color(0xFF8B4540)
  ];

  // Condiviso 3 (Blu Notte profondo)
  static const Color sharedBg3 = Color(0xFF162032);
  static const List<Color> sharedCircles3 = [
    Color(0xFF21304A),
    Color(0xFF2D4063),
    Color(0xFF39527C)
  ];

  // Condiviso 4 (Verde Muschio scuro)
  static const Color sharedBg4 = Color(0xFF203324);
  static const List<Color> sharedCircles4 = [
    Color(0xFF2C4732),
    Color(0xFF3A5C41),
    Color(0xFF497352)
  ];

  static Color getSharedBg(int index) {
    final colors = [sharedBg, sharedBg2, sharedBg3, sharedBg4];
    return colors[index % colors.length];
  }

  static List<Color> getSharedCircles(int index) {
    final circles = [sharedCircles, sharedCircles2, sharedCircles3, sharedCircles4];
    return circles[index % circles.length];
  }
}