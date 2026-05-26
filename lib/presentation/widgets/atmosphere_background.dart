import 'package:flutter/material.dart';

class AtmosphereBackground extends StatelessWidget {
  final Color backgroundColor;
  final List<Color> circleColors;

  const AtmosphereBackground({
    super.key,
    required this.backgroundColor,
    required this.circleColors,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            color: backgroundColor,
          ),
        ),
        // Cerchio Grande In Alto a Destra
        Positioned(
          top: -100,
          right: -80,
          child: _Circle(color: circleColors[0], size: 400),
        ),
        // Cerchio Medio In Basso a Sinistra
        Positioned(
          bottom: 20,
          left: -100,
          child: _Circle(color: circleColors[1], size: 300),
        ),
        // Cerchio Piccolo Centrale (aggiunge profondità)
        Positioned(
          top: 200,
          left: -30,
          child: _Circle(color: circleColors[2], size: 200),
        ),
      ],
    );
  }
}

class _Circle extends StatelessWidget {
  final Color color;
  final double size;

  const _Circle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Aumentata l'opacità per renderli più visibili rispetto allo sfondo
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.75), color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
