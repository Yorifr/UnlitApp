// Onboarding sorularında kullanılan giriş bileşenleri (Duolingo tarzı).
//
// Hepsinin ortak özelliği: "cevap yok" (null) durumunu destekler. Kullanıcı
// bir soruyu hiç cevaplamadan geçebilir; biz de varsayılan bir değer
// uydurmayız.

import 'package:flutter/material.dart';

import '../services/effects.dart';
import '../theme.dart';

/// "Neden soruyoruz?" bağlantısı; dokununca açıklama açılır.
class WhyToggle extends StatefulWidget {
  const WhyToggle({super.key, required this.text});
  final String text;

  @override
  State<WhyToggle> createState() => _WhyToggleState();
}

class _WhyToggleState extends State<WhyToggle> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _open = !_open),
          icon: Icon(_open ? Icons.expand_less : Icons.help_outline, size: 20),
          label: const Text('Neden soruyoruz?'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: _open
              ? Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.blueLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(widget.text, style: theme.textTheme.bodyMedium),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Seçilebilir, tok kutu. Seçilince mavi olur (Duolingo seçenekleri gibi).
class SelectableBox extends StatelessWidget {
  const SelectableBox({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final edge = selected ? c.blue : c.border;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () {
          Effects.select(); // en hafif "tık" titreşimi
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: padding,
          decoration: BoxDecoration(
            color: selected ? c.blueLight : c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: edge, width: 2),
            boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 3))],
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: selected ? c.blueText : c.text,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            child: child,
          ),
        ),
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
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    final current = value;

    final Widget center;
    if (current == null) {
      center = Text(
        'Seçilmedi',
        style: theme.textTheme.titleMedium?.copyWith(color: c.textMuted),
      );
    } else if (current == 0 && zeroLabel != null) {
      center = Text(zeroLabel!, style: theme.textTheme.headlineSmall);
    } else {
      center = Column(
        children: [
          Text(
            '$current',
            style: theme.textTheme.displaySmall?.copyWith(
              color: c.blueText,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(unit, style: theme.textTheme.titleSmall),
        ],
      );
    }

    return Row(
      children: [
        _RoundButton(
          icon: Icons.remove,
          tooltip: 'Azalt',
          onTap: () => onChanged(
            current == null ? startValue : (current - 1).clamp(min, max),
          ),
        ),
        Expanded(child: Center(child: center)),
        _RoundButton(
          icon: Icons.add,
          tooltip: 'Artır',
          onTap: () => onChanged(
            current == null ? startValue : (current + 1).clamp(min, max),
          ),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SelectableBox(
        selected: false,
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Icon(icon, size: 30, color: AppColors.of(context).blueText),
      ),
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
    return Column(
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SelectableBox(
              selected: option == selected,
              onTap: () => onChanged(option == selected ? null : option),
              child: SizedBox(
                width: double.infinity,
                child: Text(labelOf(option)),
              ),
            ),
          ),
      ],
    );
  }
}

/// Yan yana kutucuklarla tek seçim (yaş aralığı gibi kısa seçenekler).
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
      spacing: 10,
      runSpacing: 12,
      children: [
        for (final option in options)
          SelectableBox(
            selected: option == selected,
            onTap: () => onChanged(option == selected ? null : option),
            child: Text(labelOf(option)),
          ),
      ],
    );
  }
}

/// Yan yana kutucuklarla çoklu seçim (tetikleyiciler, aktiviteler gibi).
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
      spacing: 10,
      runSpacing: 12,
      children: [
        for (final option in options)
          SelectableBox(
            selected: selected.contains(option),
            onTap: () {
              final updated = {...selected};
              updated.contains(option)
                  ? updated.remove(option)
                  : updated.add(option);
              onChanged(updated);
            },
            child: Text(labelOf(option)),
          ),
      ],
    );
  }
}
