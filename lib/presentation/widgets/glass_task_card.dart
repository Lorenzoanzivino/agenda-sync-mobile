import 'dart:ui';
import 'package:flutter/material.dart';

class GlassTaskCard extends StatelessWidget {
  final String title;
  final String description;
  final String colorHex;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isShared;
  final bool isSelectedMode;
  final bool isSelected;

  const GlassTaskCard({
    super.key,
    required this.title,
    required this.description,
    required this.colorHex,
    this.onTap,
    this.onLongPress,
    this.isShared = false,
    this.isSelectedMode = false,
    this.isSelected = false,
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
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? taskColor.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.25),
              blurRadius: isSelected ? 25 : 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected
                    ? taskColor.withValues(alpha: 0.25)
                    : taskColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : (isShared
                            ? taskColor.withValues(alpha: 0.6)
                            : taskColor.withValues(alpha: 0.2)),
                  width: isSelected ? 2.5 : (isShared ? 2.0 : 1.5),
                ),
              ),
              child: Row(
                children: [
                  if (isSelectedMode) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 15),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: isSelected
                          ? Icon(Icons.check, size: 16, color: taskColor)
                          : null,
                    ),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!isSelectedMode)
                              Icon(
                                isShared ? Icons.people_alt : Icons.circle,
                                color: taskColor,
                                size: 18,
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // Fix Punto 4: troncamento della descrizione ad una riga con i puntini (...)
                        Text(
                          description,
                          style: const TextStyle(color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
