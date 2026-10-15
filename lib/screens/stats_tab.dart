import 'package:flutter/material.dart';

import '../app_state.dart';
import '../logic/progress.dart';
import '../logic/stats.dart';
import '../logic/weekly_report.dart';
import '../models/smoking_event.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/bar_chart.dart';
import '../widgets/change_chip.dart';
import '../widgets/chunky.dart';
import '../widgets/price_sheet.dart';
import '../widgets/stat_tile.dart';
import 'measurement_summary_screen.dart';
import 'weekly_report_screen.dart';

/// "Harcanan para" hangi dönem için hesaplansın?
enum _Period {
  today('Bugün'),
  week('7 gün'),
  month('30 gün');

  const _Period(this.label);
  final String label;
}

/// "İstatistik" sekmesi: "Başladığından beri" (tek bakışta durum), bugünkü
/// sayı, son 7 günün grafiği, haftalık raporlar, "Kazandıkların" ve harcanan
/// para.
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
        // Ölçüm haftasından 7 gün sonra açılır; öncesinde hiç görünmez
        // (boş kart kalabalık yapar). 0.11.0'a kadar burada "geçen haftayla
        // karşılaştırma" vardı; haftadan haftaya fark artık haftalık raporda.
        final progress = state.progress;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              'İstatistik',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (progress != null) ...[
              _SinceStartCard(progress: progress),
              const SizedBox(height: 16),
            ],
            _TodayCard(events: events, now: now),
            const SizedBox(height: 16),
            _ChartCard(events: events, now: now),
            // Ölçüm haftası bitince açılır (öncesinde hiç görünmez).
            if (state.completedWeeks > 0) ...[
              const SizedBox(height: 28),
              _ReportsSection(state: state),
            ],
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
          // Korunan yaşam süresi sadece SİGARASIZ günlerden hesaplanır
          // (0.11.0; gerekçe logic/measurement.dart → Gains.lifeMinutes).
          // Henüz sigarasız gün yoksa "0 dk" kartı yerine nasıl
          // hesaplandığını anlatan küçük bir bağlantı.
          if (gains.smokeFreeDays > 0)
            StatTile(
              icon: Icons.favorite_outline,
              color: c.purple,
              title: 'Korunan yaşam süresi',
              value: formatDuration(gains.lifeMinutes),
              footnote:
                  'Sigarasız ${gains.smokeFreeDays} gününde · ortalama '
                  'tahmin (UCL, 2024)',
              onInfo: () => _showLifeInfo(context),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _showLifeInfo(context),
                icon: const Icon(Icons.info_outline, size: 20),
                label: const Text('Korunan yaşam süresi nasıl hesaplanır?'),
                style: TextButton.styleFrom(foregroundColor: c.textMuted),
              ),
            ),
        ],
      ],
    );
  }

  void _showLifeInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bu sayı nasıl hesaplanıyor?'),
        content: const SingleChildScrollView(
          child: Text(
            'University College London (UCL) araştırmacılarının 2024’te '
            'Addiction dergisinde yayımladığı çalışmaya göre bir sigara, '
            'ortalama olarak yaklaşık $lifeMinutesPerCigarette dakika yaşam '
            'süresine mal oluyor (erkeklerde ~17, kadınlarda ~22 dk).\n\n'
            'Bu süreyi sadece hiç sigara içmediğin günler için hesaplıyoruz: '
            'sigarasız her gün, başlangıç noktan kadar sigara × '
            '~$lifeMinutesPerCigarette dk.\n\n'
            'Neden azalttığın günler sayılmıyor? Sağlığa etkisi sigara '
            'sayısıyla orantılı değil; az sayıda sigara bile riskin önemli '
            'bir kısmını taşıyor (Hackshaw ve ark., BMJ, 2018). Azalttığın '
            'günlerde içmediğin sigaralar ve cebinde kalan para yine burada '
            'birikiyor.\n\n'
            'Bu bir ORTALAMA TAHMİNDİR; senin sağlığına dair kişisel bir '
            'ölçüm değildir.',
          ),
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

/// "Haftalık raporların": biten haftaların listesi, en yenisi üstte.
/// 1. hafta ölçüm haftasıdır (onun raporu ölçüm haftası özeti). Raporların
/// kalıcı yeri burası; "Bugün"deki "RAPORUMU GÖR" sadece yeni raporu bir
/// kez duyurur.
class _ReportsSection extends StatefulWidget {
  const _ReportsSection({required this.state});
  final AppState state;

  @override
  State<_ReportsSection> createState() => _ReportsSectionState();
}

class _ReportsSectionState extends State<_ReportsSection> {
  /// Kapalıyken en son kaç hafta görünsün? (Pilot uzadıkça liste uzamasın.)
  static const _collapsedCount = 4;
  bool _expanded = false;

  AppState get state => widget.state;

  void _open(int week) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => week == 1
          ? MeasurementSummaryScreen(state: state)
          : WeeklyReportScreen(state: state, week: week),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = AppColors.of(context);
    final start = state.trackingStartedAt!;
    final completed = state.completedWeeks;
    // Ölçüm haftasında hiç kayıt yoksa özetlenecek bir şey yok (özet de
    // hiç gösterilmedi); listede 1. hafta olmaz.
    final hasMeasurement = (state.measurementSummary?.total ?? 0) > 0;
    final weeks = [
      for (var w = completed; w >= 1; w--)
        if (w > 1 || hasMeasurement) w,
    ];
    final visible = _expanded ? weeks : weeks.take(_collapsedCount).toList();
    final nextReady = weekStart(start, completed + 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Haftalık raporların', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Her hafta bitince kısa bir rapor gelir. Sıradaki: '
          '${formatDayMonth(nextReady)}.',
          style: theme.textTheme.bodyMedium?.copyWith(color: c.textMuted),
        ),
        if (weeks.isNotEmpty) ...[
          const SizedBox(height: 12),
          ChunkyCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0) Divider(height: 2, color: c.border),
                  _ReportRow(
                    week: visible[i],
                    start: weekStart(start, visible[i]),
                    onTap: () => _open(visible[i]),
                  ),
                ],
                if (weeks.length > _collapsedCount)
                  TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      _expanded
                          ? 'DAHA AZ GÖSTER'
                          : 'TÜMÜNÜ GÖSTER (${weeks.length})',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Rapor listesinde tek satır: "3. hafta · 15–21 Ekim".
class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.week,
    required this.start,
    required this.onTap,
  });

  final int week;
  final DateTime start;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = AppColors.of(context);
    final range = formatDayRange(start, addDays(start, daysPerWeek - 1));

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            Icon(
              week == 1 ? Icons.school_outlined : Icons.event_note_outlined,
              color: week == 1 ? c.purple : c.blue,
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$week. hafta', style: theme.textTheme.titleSmall),
                  Text(
                    week == 1 ? 'Ölçüm haftası · $range' : range,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textMuted),
          ],
        ),
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
          // "Son sigaradan beri geçen süre" burada değil, Bugün sekmesindeki
          // sayaçta (aynı bilgi iki yerde olmasın).
          if (first != null) ...[
            const SizedBox(height: 10),
            Text(
              'Bugünkü ilk sigara: ${formatClock(first)}',
              style: theme.textTheme.bodySmall?.copyWith(color: c.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Başladığından beri": tek bakışta ne durumdayım? Başlangıç noktası
/// (ölçüm haftası) ile şimdi (son 7 gün) ve hafta hafta günlük ortalama.
/// Ölçüm haftasından 7 gün sonra görünür (bkz. logic/progress.dart).
/// Azalma nane renkli; artış nötr (kırmızı ya da mesaj yok).
class _SinceStartCard extends StatelessWidget {
  const _SinceStartCard({required this.progress});
  final StartProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = AppColors.of(context);
    final percent = progress.changePercent;
    final less = percent.round() < 0;
    final headline = percent.round() == 0
        ? 'Başlangıç noktana yakın'
        : '${formatPercent(percent)} ${less ? 'daha az' : 'daha fazla'}';
    final weeks = progress.weeks;
    final description =
        'Hafta hafta günde ortalama: ${weeks.map((w) => '${w.week}. hafta '
            '${formatDecimal(w.average)}').join(', ')}';

    return ChunkyCard(
      padding: const EdgeInsets.all(20),
      // Azalma varsa kart nane renkli bir kutlama havasına bürünür.
      color: less ? c.mintLight : null,
      borderColor: less ? c.mint : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Başladığından beri', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            headline,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: less ? c.mintText : c.text,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _NumberWithLabel(
                  number: formatDecimal(progress.baseline),
                  label: 'Başlangıçta günde',
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, color: c.textMuted),
              ),
              Expanded(
                child: _NumberWithLabel(
                  number: formatDecimal(progress.current),
                  label: 'Şimdi günde',
                  emphasized: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SimpleBarChart(
            height: 130,
            items: [
              for (final w in weeks)
                BarChartItem(
                  label: '${w.week}.',
                  value: w.average,
                  valueLabel: formatDecimal(w.average),
                  highlight: w == weeks.last,
                ),
            ],
            semanticsLabel: description,
          ),
          const SizedBox(height: 8),
          Text(
            'Hafta hafta, günde ortalama sigara. Başlangıç: ölçüm haftası '
            '(1. hafta). Şimdi: son 7 gün.',
            style: theme.textTheme.bodySmall?.copyWith(color: c.textMuted),
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
