// "Paket fiyatı" penceresi (alttan açılır).
//
// Fiyatı değiştirmenin TEK yeri burası (onboarding'de ilk kez sorulur).
// Yeni fiyat bugünden itibaren geçerli olur; önceki günler eski fiyatla
// hesaplanmaya devam eder. "Yanlış girmiştim" seçilirse tüm geçmiş yeni
// fiyatla hesaplanır.

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../logic/stats.dart';
import '../models/pack_price.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'chunky.dart';
import 'onboarding_inputs.dart';

/// Pencereyi açar. Kaydedilirse true döner.
Future<bool> showPriceSheet(BuildContext context, AppState state) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true, // klavye açılınca pencere yukarı kayabilsin
    builder: (_) => _PriceSheet(state: state),
  );
  return saved ?? false;
}

class _PriceSheet extends StatefulWidget {
  const _PriceSheet({required this.state});
  final AppState state;

  @override
  State<_PriceSheet> createState() => _PriceSheetState();
}

class _PriceSheetState extends State<_PriceSheet> {
  late final PackPrice? _current = widget.state.prices.current;
  late final _controller = TextEditingController(
    text: _current == null ? '' : priceToInput(_current.price),
  );
  late int _perPack = _current?.perPack ?? 20;
  late bool _showPerPack = _perPack != 20;
  bool _correctPast = false;

  double? get _price => parsePrice(_controller.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final price = _price;
    if (price == null) return;
    await widget.state.setPackPrice(
      price: price,
      perPack: _perPack,
      correctPast: _correctPast,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    final text = _controller.text.trim();
    final invalid = text.isNotEmpty && _price == null;
    final history = widget.state.prices.entries;

    return Padding(
      // Klavye açılınca içerik klavyenin üstünde kalsın.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Paket fiyatı', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                _current == null
                    ? 'Harcadığın parayı hesaplamak için bir paketin fiyatını '
                          'yaz.'
                    : 'Zam geldiyse yeni fiyatı yaz. Yeni fiyat bugünden '
                          'itibaren geçerli olur; önceki günler eski fiyatla '
                          'hesaplanmaya devam eder.',
                style: theme.textTheme.bodyMedium?.copyWith(color: c.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: _current == null,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: theme.textTheme.headlineSmall,
                decoration: InputDecoration(
                  hintText: 'Örneğin 110',
                  suffixText: '₺',
                  errorText: invalid
                      ? 'Geçerli bir fiyat gir (ör. 95,50)'
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              if (_showPerPack) ...[
                Text(
                  'Pakette kaç sigara var?',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                ChipChoice<int>(
                  options: const [10, 20, 25],
                  selected: _perPack,
                  labelOf: perPackLabel,
                  onChanged: (v) => setState(() => _perPack = v ?? 20),
                ),
              ] else
                TextButton(
                  onPressed: () => setState(() => _showPerPack = true),
                  child: Text('Paketin ${perPackLabel(20)} değil mi?'),
                ),
              if (_current != null) ...[
                const SizedBox(height: 4),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _correctPast,
                  onChanged: (v) => setState(() => _correctPast = v ?? false),
                  title: const Text('Yanlış girmiştim'),
                  subtitle: const Text(
                    'Önceki günler de bu fiyatla hesaplansın.',
                  ),
                ),
              ],
              if (history.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Fiyat geçmişi', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                for (var i = history.length - 1; i >= 0; i--)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${_periodText(history, i)}:  '
                      '${formatMoney(history[i].price)} '
                      '(${perPackLabel(history[i].perPack)})',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: i == history.length - 1 ? c.text : c.textMuted,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              ChunkyButton(
                label: 'KAYDET',
                onPressed: _price == null ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "5 Ekim’den beri" ya da "1 Ekim – 4 Ekim"
  String _periodText(List<PackPrice> history, int i) {
    if (i == history.length - 1) return formatSince(history[i].since);
    final start = startOfDay(history[i].since);
    final end = addDays(startOfDay(history[i + 1].since), -1);
    if (!end.isAfter(start)) return formatDayMonth(start); // tek günlük fiyat
    return '${formatDayMonth(start)} – ${formatDayMonth(end)}';
  }
}
