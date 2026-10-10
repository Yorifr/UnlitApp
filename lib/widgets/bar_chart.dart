import 'dart:math';

import 'package:flutter/material.dart';

/// Grafikteki tek bir çubuk.
class BarChartItem {
  const BarChartItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  /// Çubuğun altındaki yazı ("Pzt", "09" gibi). Boş bırakılabilir.
  final String label;

  /// Çubuğun değeri (sigara sayısı).
  final int value;

  /// Vurgulu çubuk (ör. bugün) koyu renkte çizilir.
  final bool highlight;
}

/// Basit bir çubuk grafik.
///
/// Bir grafik paketi (fl_chart vb.) kullanmak yerine, Flutter'ın kendi
/// kutularıyla (Container) çizdik: her çubuk, yüksekliği değere göre
/// hesaplanan renkli bir kutu. Az kod, sıfır ek paket.
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({
    super.key,
    required this.items,
    this.height = 170,
    this.showValues = true,
    this.semanticsLabel,
  });

  final List<BarChartItem> items;
  final double height;

  /// Çubukların üstünde sayıları göster (çok çubuk varsa kapat).
  final bool showValues;

  /// Ekran okuyucular için grafiğin sözlü açıklaması.
  final String? semanticsLabel;

  static const double _labelHeight = 18;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: scheme.onSurfaceVariant);
    // En büyük değer, çubukların ölçeğini belirler (en az 1, sıfıra bölme olmasın).
    final maxValue = max(1, items.fold<int>(0, (m, i) => max(m, i.value)));
    final gap = items.length > 12 ? 1.5 : 5.0;

    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Çubuklara kalan yükseklik = toplam - üst ve alt yazılar.
              final barArea = constraints.maxHeight - 2 * _labelHeight - 8;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final item in items)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: gap),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: _labelHeight,
                              child: showValues && item.value > 0
                                  ? _CenteredLabel('${item.value}', textStyle)
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 450),
                              curve: Curves.easeOutCubic,
                              // Değer 0 olsa bile ince bir çizgi görünsün.
                              height: max(3, barArea * item.value / maxValue),
                              decoration: BoxDecoration(
                                color: item.highlight
                                    ? scheme.primary
                                    : scheme.primary.withValues(alpha: 0.3),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                  bottom: Radius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: _labelHeight,
                              child: _CenteredLabel(
                                item.label,
                                item.highlight
                                    ? textStyle?.copyWith(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w700,
                                      )
                                    : textStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dar sütunlara sığmayan yazıları bile ortalı gösteren küçük yardımcı.
class _CenteredLabel extends StatelessWidget {
  const _CenteredLabel(this.text, this.style);
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      maxWidth: 48,
      child: Text(text, style: style, maxLines: 1, textAlign: TextAlign.center),
    );
  }
}
