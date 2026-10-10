import 'package:flutter/material.dart';

import '../app_state.dart';
import '../logic/stats.dart';
import '../models/smoking_event.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/bar_chart.dart';
import '../widgets/chunky.dart';
import '../widgets/price_sheet.dart';
import '../widgets/stat_tile.dart';
import 'measurement_summary_screen.dart';

/// "Harcanan para" hangi dönem için hesaplansın?
enum _Period {
  today('Bugün'),
  week('7 gün'),
  month('30 gün');

  const _Period(this.label);
  final String label;
}

/// "İstatistik" sekmesi: bugünkü sayı, geçen haftayla karşılaştırma,
/// son 7 günün grafiği, "Kazandıkların" ve harcanan para.
///
/// Bilerek SADE: sayfada tek bir dönem seçici var (para için). "Kaybedilen
/// yaşam süresi" gibi sadece büyüyen bir kayıp sayısı göstermiyoruz; aynı
/// kaynağı "içmediğin sigaralarla korunan süre" olarak, ölçüm haftasından
/// sonra gösteriyoruz (gerekçe: docs/SPEC.md → Bölüm 11).
class StatsTab extends StatefulWidget {
  const StatsTab({super.key, required this.state});

  final AppState state;

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  _Period _period = _Period.today;

  AppState get state => widget.state;

  /// "Paket fiyatı" penceresini açar.
  void _openPriceSheet() => showPriceSheet(context, state);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final now = state.now;
        final events = state.events;
        // Haftalık karşılaştırma ancak 2 haftalık kayıt varsa anlamlı;
        // yoksa kartı hiç göstermiyoruz (boş kart kalabalık yapar).
        final canCompareWeeks =
            hasDataSince(events, addDays(now, -13)) &&
            compareWeeks(events, now).changePercent != null;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              'İstatistik',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _TodayCard(events: events, now: now),
            if (canCompareWeeks) ...[
              const SizedBox(height: 16),
              _WeekCard(events: events, now: now),
            ],
            const SizedBox(height: 16),
            _ChartCard(events: events, now: now),
            const SizedBox(height: 28),
            _GainsSection(state: state, onAddPrice: _openPriceSheet),
            const SizedBox(height: 28),
            _buildMoney(context, events, now),
          ],
        );
      },
    );
  }

  /// Harcanan para: paket fiyatı kartı + dönem seçici + tutar.
  Widget _buildMoney(
    BuildContext context,
    List<SmokingEvent> events,
    DateTime now,
  ) {
    final theme = Theme.of(context);
    final c = AppColors.of(context);
    // Dönemin başlangıcı: bugün gece yarısı / 7 gün önce / 30 gün önce
    final from = switch (_period) {
      _Period.today => startOfDay(now),
      _Period.week => addDays(now, -7),
      _Period.month => addDays(now, -30),
    };
    final to = untilNow(now);
    final count = countBetween(events, from, to);
    final prices = state.prices;
    final money = moneyBetween(events, from, to, prices);
    final currentPrice = prices.current;
    final periodText = _period == _Period.today
        ? 'Bugün'
        : 'Son ${_period.label}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Para', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          '$periodText: $count sigara',
          style: theme.textTheme.bodyMedium?.copyWith(color: c.textMuted),
        ),
        const SizedBox(height: 12),
        _PriceCard(state: state, onEdit: _openPriceSheet),
        const SizedBox(height: 12),
        SegmentedButton<_Period>(
          segments: [
            for (final p in _Period.values)
              ButtonSegment(value: p, label: Text(p.label)),
          ],
          selected: {_period},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _period = s.first),
        ),
        const SizedBox(height: 12),
        StatTile(
          icon: Icons.payments_outlined,
          color: c.blue,
          title: 'Harcanan para',
          value: money == null ? '—' : formatMoney(money),
          footnote: currentPrice == null
              ? 'Hesaplamak için dokun ve paket fiyatını ekle'
              : priceChangedBetween(prices, from, to)
              // Dönem içinde zam olduysa: her sigara kendi fiyatıyla
              ? 'Her sigara kendi tarihindeki fiyatla hesaplandı'
              : 'Paket fiyatı ${formatMoney(currentPrice.price)} '
                    '(${perPackLabel(currentPrice.perPack)}) üzerinden',
          onTap: currentPrice == null ? _openPriceSheet : null,
        ),
      ],
    );
  }
}

/// "Kazandıkların": ölçüm haftasındaki ortalamaya göre içilmeyen sigaralar,
/// cepte kalan para ve korunan yaşam süresi. Ölçüm haftası bitince açılır.
class _GainsSection extends StatelessWidget {
  const _GainsSection({required this.state, required this.onAddPrice});

  final AppState state;
  final VoidCallback onAddPrice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = AppColors.of(context);

    // Ölçüm haftası sürüyor: bölüm henüz kapalı, ne zaman açılacağını söyle.
    if (state.measurementDay != null) {
      return ChunkyCard(
        color: c.surfaceAlt,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.savings_outlined, color: c.textMuted, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kazandıkların', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    'Ölçüm haftası bitince burada açılacak: ortalamanın '
                    'altında kaldıkça içmediğin sigaralar ve cebinde kalan '
                    'para birikir.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final gains = state.gains;
    // Ölçüm haftasında hiç kayıt yoksa karşılaştıracak bir başlangıç yok.
    if (gains == null) return const SizedBox.shrink();
    final money = gains.money;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Kazandıkların', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Başlangıç noktan: ölçüm haftasında günde '
          '${formatDecimal(gains.baseline)} sigara.',
          style: theme.textTheme.bodyMedium?.copyWith(color: c.textMuted),
        ),
        const SizedBox(height: 12),
        if (gains.days == 0)
          ChunkyCard(
            child: Text(
              'İlk gün bitince burada içmediğin sigaralar görünecek. Gün '
              'bitmeden hesap yapmıyoruz.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else ...[
          StatTile(
            icon: Icons.smoke_free,
            color: c.mint,
            title: 'İçmediğin sigara',
            value: '${gains.notSmoked}',
            footnote: gains.notSmoked == 0
                ? 'Henüz birikmedi. Ortalamanın altında kaldıkça burada '
                      'birikir.'
                : 'Ölçüm haftasından sonraki ${gains.days} günde (dün dahil)',
          ),
          const SizedBox(height: 12),
          StatTile(
            icon: Icons.savings_outlined,
            color: c.blue,
            title: 'Cebinde kalan para',
            value: money == null ? '—' : formatMoney(money),
            footnote: money == null
                ? 'Paket fiyatını eklersen hesaplanır'
                : 'Her gün, o günün paket fiyatıyla',
            onTap: money == null ? onAddPrice : null,
          ),
          const SizedBox(height: 12),
          StatTile(
            icon: Icons.favorite_outline,
            color: c.purple,
            title: 'Korunan yaşam süresi',
            value: formatDuration(gains.lifeMinutes),
            footnote:
                'Ortalama tahmin: içilmeyen sigara başına '
                '~$lifeMinutesPerCigarette dk (UCL, 2024)',
            onInfo: () => _showLifeInfo(context),
          ),
        ],
        const SizedBox(height: 4),
        Align(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MeasurementSummaryScreen(state: state),
              ),
            ),
            child: const Text('ÖLÇÜM HAFTASI ÖZETİM'),
          ),
        ),
      ],
    );
  }

  void _showLifeInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bu sayı nasıl hesaplanıyor?'),
        content: const Text(
          'University College London (UCL) araştırmacılarının 2024’te '
          'Addiction dergisinde yayımladığı çalışmaya göre bir sigara, '
          'ortalama olarak yaklaşık 20 dakika yaşam süresine mal oluyor '
          '(erkeklerde ~17, kadınlarda ~22 dk).\n\n'
          'Burada bunu tersinden kullanıyoruz: ölçüm haftandaki ortalamaya '
          'göre İÇMEDİĞİN her sigara için ~20 dk.\n\n'
          'Bu bir ORTALAMA TAHMİNDİR; senin sağlığına dair kişisel bir '
          'ölçüm değildir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ANLADIM'),
          ),
        ],
      ),
    );
  }
}

// ---------- Kartlar ----------

/// Bugünkü sigara sayısı.
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.events, required this.now});
  final List<SmokingEvent> events;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = AppColors.of(context);
    final today = countToday(events, now);
    final first = firstEventOfDay(events, now);
    final last = events.isEmpty ? null : events.last.time;
    final weekAgo = addDays(now, -7);
    final canCompare = hasDataSince(events, weekAgo);
    final lastWeekSameTime = countSameDayLastWeek(events, now);

    return ChunkyCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatLongDate(now),
            style: theme.textTheme.labelLarge?.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$today',
                style: theme.textTheme.displayLarge?.copyWith(
                  color: c.mintText,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'sigara\nbugün',
                  style: theme.textTheme.titleMedium?.copyWith(height: 1.15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (canCompare)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Geçen ${weekdayLower(weekAgo)} bu saate kadar: '
                  '$lastWeekSameTime',
                  style: theme.textTheme.bodyMedium,
                ),
                ChangeChip(difference: today - lastWeekSameTime),
              ],
            )
          else
            Text(
              'Geçen haftayla karşılaştırma, 1 haftalık kayıttan sonra '
              'burada görünecek.',
              style: theme.textTheme.bodyMedium?.copyWith(color: c.textMuted),
            ),
          if (last != null) ...[
            const SizedBox(height: 10),
            Text(
              [
                if (first != null) 'Bugünkü ilk sigara: ${formatClock(first)}',
                'Son: ${formatTimeAgo(last, now)}',
              ].join('  ·  '),
              style: theme.textTheme.bodySmall?.copyWith(color: c.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

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

/// Son 7 gün ile önceki 7 günün karşılaştırması. (Sadece 2 haftalık kayıt
/// varken gösterilir; bkz. StatsTab.)
class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.events, required this.now});
  final List<SmokingEvent> events;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = AppColors.of(context);
    final comparison = compareWeeks(events, now);
    final percent = comparison.changePercent ?? 0;
    final less = percent.round() < 0;

    return ChunkyCard(
      padding: const EdgeInsets.all(20),
      // Azalma varsa kart nane renkli bir kutlama havasına bürünür.
      color: less ? c.mintLight : null,
      borderColor: less ? c.mint : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Geçen haftayla karşılaştırma',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _NumberWithLabel(
                  number: '${comparison.thisWeek}',
                  label: 'Son 7 gün',
                  emphasized: true,
                ),
              ),
              Expanded(
                child: _NumberWithLabel(
                  number: '${comparison.lastWeek}',
                  label: 'Önceki 7 gün',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ChangeChip(
            // Yüzde %0'a yuvarlanıyorsa "aynı" ikonu gösterilsin.
            difference: percent.round() == 0
                ? 0
                : comparison.thisWeek - comparison.lastWeek,
            text: percent.round() == 0
                ? 'Neredeyse aynı'
                : '${formatPercent(percent)} '
                      '${percent < 0 ? 'daha az. Harika!' : 'daha fazla'}',
          ),
        ],
      ),
    );
  }
}

class _NumberWithLabel extends StatelessWidget {
  const _NumberWithLabel({
    required this.number,
    required this.label,
    this.emphasized = false,
  });

  final String number;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: emphasized ? c.text : c.textMuted,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: c.textMuted),
        ),
      ],
    );
  }
}

/// Son 7 günün grafiği. (Saatlik görünüm bilerek yok: tek grafik, tek
/// seçici daha az kafa karıştırır. En yoğun saat ölçüm haftası özetinde.)
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.events, required this.now});

  final List<SmokingEvent> events;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = dailyCounts(events, now, days: 7);
    final description =
        'Son 7 gün: ${days.map((d) => '${weekdayLower(d.day)} '
            '${d.count}').join(', ')}';

    return ChunkyCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Son 7 gün', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          SimpleBarChart(
            items: [
              for (final d in days)
                BarChartItem(
                  label: d.day == startOfDay(now)
                      ? 'Bugün'
                      : weekdayShort(d.day),
                  value: d.count,
                  highlight: d.day == startOfDay(now),
                ),
            ],
            showValues: true,
            semanticsLabel: description,
          ),
        ],
      ),
    );
  }
}

/// Paket fiyatı kartı: şu anki fiyat + "DEĞİŞTİR". Fiyatın TEK yeri burası.
/// Fiyat uzun süredir aynıysa nazikçe "hâlâ aynı mı?" diye sorar.
class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.state, required this.onEdit});

  final AppState state;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    final current = state.prices.current;

    return ChunkyCard(
      onTap: onEdit,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sell_outlined, color: c.mint, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Paket fiyatı', style: theme.textTheme.titleSmall),
                    Text(
                      current == null
                          ? 'Henüz girilmedi'
                          : '${formatMoney(current.price)} · '
                                '${perPackLabel(current.perPack)} · '
                                '${formatSince(current.since)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onEdit,
                child: Text(current == null ? 'EKLE' : 'DEĞİŞTİR'),
              ),
            ],
          ),
          if (current != null && state.shouldAskPriceStillSame) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
              decoration: BoxDecoration(
                color: c.blueLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Paket fiyatın hâlâ ${formatMoney(current.price)} mı?',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: state.confirmPriceStillSame,
                    child: const Text('AYNI'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
