import 'package:flutter/material.dart';

import '../theme.dart';
import 'chunky.dart';

/// Bilgi kartı: renkli ikon + başlık + büyük değer + dipnot.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.footnote,
    this.onTap,
    this.onInfo,
  });

  final IconData icon;

  /// İkonun rengi (kutusu bu rengin açığıyla boyanır).
  final Color color;
  final String title;
  final String value;

  /// Değerin altındaki küçük açıklama (varsayım, kaynak vb.).
  final String footnote;

  /// Karta dokununca ne olsun? (ör. eksik bilgiyi doldurmaya git)
  final VoidCallback? onTap;

  /// Doluysa sağ üstte bir "bilgi" (i) butonu çıkar.
  final VoidCallback? onInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = AppColors.of(context);

    return ChunkyCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  footnote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (onInfo != null)
            IconButton(
              onPressed: onInfo,
              icon: const Icon(Icons.info_outline),
              tooltip: 'Bu sayı nasıl hesaplanıyor?',
              color: c.textMuted,
            ),
        ],
      ),
    );
  }
}
