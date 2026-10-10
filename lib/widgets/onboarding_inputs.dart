// Onboarding sorularında kullanılan küçük giriş bileşenleri.
//
// Hepsinin ortak özelliği: "cevap yok" (null) durumunu destekler. Kullanıcı
// bir soruyu hiç cevaplamadan geçebilir; biz de varsayılan bir değer
// uydurmayız.

import 'package:flutter/material.dart';

/// Bir soru + "Neden soruyoruz?" açıklaması + cevap alanı.
class QuestionBlock extends StatefulWidget {
  const QuestionBlock({
    super.key,
    required this.question,
    required this.why,
    required this.child,
  });

  final String question;

  /// "Neden soruyoruz?"a dokununca açılan açıklama.
  final String why;

  /// Cevap alanı (seçenekler, sayı seçici vb.).
  final Widget child;

  @override
  State<QuestionBlock> createState() => _QuestionBlockState();
}

class _QuestionBlockState extends State<QuestionBlock> {
  bool _showWhy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.question,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(() => _showWhy = !_showWhy),
            icon: Icon(
              _showWhy ? Icons.expand_less : Icons.help_outline,
              size: 18,
            ),
            label: const Text('Neden soruyoruz?'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ),
          ),
          // Açıklama kutusu, açılıp kapanırken yumuşakça büyür/küçülür.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _showWhy
                ? Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.why,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 8),
          widget.child,
        ],
      ),
    );
  }
}

/// – / + butonlarıyla sayı seçici. Başta "Seçilmedi" yazar.
class NumberStepper extends StatelessWidget {
  const NumberStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    required this.startValue,
    required this.unit,
    this.zeroLabel,
  });

  final int? value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  /// İlk dokunuşta gösterilecek değer (ör. günlük sigara için 15).
  final int startValue;

  /// Sayının yanındaki birim ("sigara", "yıl").
  final String unit;

  /// Değer 0 iken sayının yerine yazılacak metin ("1 yıldan az" gibi).
  final String? zeroLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = value;

    String text;
    if (current == null) {
      text = 'Seçilmedi';
    } else if (current == 0 && zeroLabel != null) {
      text = zeroLabel!;
    } else {
      text = '$current $unit';
    }

    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: () => onChanged(
            current == null ? startValue : (current - 1).clamp(min, max),
          ),
          icon: const Icon(Icons.remove),
          tooltip: 'Azalt',
        ),
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: current == null
                ? theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                : theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
          ),
        ),
        IconButton.filledTonal(
          onPressed: () => onChanged(
            current == null ? startValue : (current + 1).clamp(min, max),
          ),
          icon: const Icon(Icons.add),
          tooltip: 'Artır',
        ),
      ],
    );
  }
}

/// Alt alta seçenek kartları (tek seçim). Seçili olana tekrar dokunmak
/// seçimi kaldırır.
class OptionList<T> extends StatelessWidget {
  const OptionList({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> options;
  final T? selected;
  final String Function(T option) labelOf;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              button: true,
              selected: option == selected,
              inMutuallyExclusiveGroup: true,
              child: Material(
                color: option == selected
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: option == selected
                        ? scheme.primary
                        : scheme.outlineVariant,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onChanged(option == selected ? null : option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(labelOf(option))),
                        Icon(
                          option == selected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: option == selected
                              ? scheme.primary
                              : scheme.outline,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Yan yana "çip"lerle tek seçim (yaş aralığı, cinsiyet gibi kısa seçenekler).
class ChipChoice<T> extends StatelessWidget {
  const ChipChoice({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> options;
  final T? selected;
  final String Function(T option) labelOf;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(labelOf(option)),
            selected: option == selected,
            onSelected: (isSelected) => onChanged(isSelected ? option : null),
          ),
      ],
    );
  }
}

/// Yan yana "çip"lerle çoklu seçim (tetikleyiciler, aktiviteler gibi).
class ChipMultiChoice<T> extends StatelessWidget {
  const ChipMultiChoice({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> options;
  final Set<T> selected;
  final String Function(T option) labelOf;

  /// Yeni seçili küme ile çağrılır.
  final ValueChanged<Set<T>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          FilterChip(
            label: Text(labelOf(option)),
            selected: selected.contains(option),
            onSelected: (isSelected) {
              final updated = {...selected};
              isSelected ? updated.add(option) : updated.remove(option);
              onChanged(updated);
            },
          ),
      ],
    );
  }
}

/// 1'den 10'a kadar ölçek (bırakma isteği için).
class ScalePicker extends StatelessWidget {
  const ScalePicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.lowLabel,
    required this.highLabel,
  });

  final int? value;
  final ValueChanged<int?> onChanged;
  final String lowLabel;
  final String highLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hintStyle = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Column(
      children: [
        Row(
          children: [
            for (var i = 1; i <= 10; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Semantics(
                      button: true,
                      selected: value == i,
                      label: '$i / 10',
                      child: Material(
                        shape: const CircleBorder(),
                        color: value == i
                            ? scheme.primary
                            : scheme.surfaceContainerHighest,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => onChanged(value == i ? null : i),
                          child: Center(
                            child: Text(
                              '$i',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: value == i
                                    ? scheme.onPrimary
                                    : scheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(lowLabel, style: hintStyle),
            Text(highLabel, style: hintStyle),
          ],
        ),
      ],
    );
  }
}
