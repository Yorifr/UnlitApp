import 'package:flutter/material.dart';

import '../theme.dart';

/// Fark rozeti: "2 az" (nane) / "3 fazla" (nötr gri) / "aynı".
///
/// Bilerek kırmızı/uyarı rengi kullanmıyoruz: artış olduğunda kullanıcıyı
/// suçlamak değil, sadece bilgi vermek istiyoruz.
class ChangeChip extends StatelessWidget {
  const ChangeChip({super.key, required this.difference, this.text});

  /// Negatif = azalma (iyi), pozitif = artış.
  final int difference;

  /// Boş bırakılırsa "2 az" / "3 fazla" yazılır.
  final String? text;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (icon, label, background, foreground) = switch (difference) {
      < 0 => (
        Icons.south,
        text ?? '${-difference} az',
        c.mintLight,
        c.mintText,
      ),
      > 0 => (
        Icons.north,
        text ?? '$difference fazla',
        c.surfaceAlt,
        c.textMuted,
      ),
      _ => (Icons.drag_handle, text ?? 'aynı', c.surfaceAlt, c.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          // Flexible: yer kalmazsa yazı alt satıra geçsin, taşmasın.
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
