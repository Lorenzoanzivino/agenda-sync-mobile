import 'dart:ui';
import 'package:flutter/material.dart';

class GlassTaskCard extends StatelessWidget {
  final String title;
  final String description;
  final String colorHex; // Riceve la stringa esadecimale (es. #06B6D4)
  final VoidCallback? onTap;
  final bool isShared;

  const GlassTaskCard({
    super.key,
    required this.title,
    required this.description,
    required this.colorHex,
    this.onTap,
    this.isShared = false,
  });

  Color _parseColor(String hexStr) {
    try {
      final cleaned = hexStr.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return Colors.cyanAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskColor = _parseColor(colorHex);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                // Usa il colore specifico del task sfumato al 14% di opacità per lo sfondo glass
                color: taskColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
                // Il bordo sinistro o perimetrale prende la tinta accesa del task
                border: Border.all(
                    color: taskColor.withValues(alpha: 0.6),
                    width: isShared ? 2.0 : 1.5
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                      Icon(isShared ? Icons.people_alt : Icons.circle, color: taskColor, size: 18),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(description, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}