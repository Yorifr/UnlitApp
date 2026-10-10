import 'package:flutter/material.dart';

/// Ana ekrandaki küçük bilgi kartı: ikon + başlık + büyük değer + dipnot.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.footnote,
    this.onTap,
    this.onInfo,
  });

  final IconData icon;
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
    final scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Renkli yuvarlak içinde ikon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      footnote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
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
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
