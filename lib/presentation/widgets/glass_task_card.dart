import 'dart:ui';
import 'package:flutter/material.dart';

class GlassTaskCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool isShared;

  const GlassTaskCard({
    super.key,
    required this.title,
    required this.description,
    this.onTap,
    this.isShared = false,
  });

  @override
  Widget build(BuildContext context) {
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
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
                // Se è condiviso, mettiamo un bordo visibile colorato (es. Ciano) per indicare collaborazione
                border: Border.all(
                    color: isShared ? Colors.cyanAccent.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.2),
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
                      if (isShared) const Icon(Icons.people_alt, color: Colors.cyanAccent, size: 18),
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