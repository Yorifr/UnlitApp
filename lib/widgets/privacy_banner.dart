import 'package:flutter/material.dart';

import '../theme.dart';

/// "Bilgilerin sadece bu telefonda kalır" uyarısı.
/// Onboarding'in en üstünde ve ayarlarda gösterilir.
class PrivacyBanner extends StatelessWidget {
  const PrivacyBanner({super.key, this.compact = false});

  /// true: tek satırlık küçük hali (onboarding sayfalarında).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 6 : 10),
      decoration: BoxDecoration(
        color: c.greenLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: compact ? 16 : 20, color: c.greenText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bilgilerin sadece bu telefonda kalır, kimseyle paylaşılmaz.',
              style:
                  (compact
                          ? theme.textTheme.bodySmall
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(
                        color: c.greenText,
                        fontWeight: FontWeight.w700,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
