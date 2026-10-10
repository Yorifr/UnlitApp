import 'package:flutter/material.dart';

import '../app_state.dart';
import '../logic/stats.dart';
import '../models/smoking_event.dart';
import '../models/user_profile.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/bar_chart.dart';
import '../widgets/chunky.dart';
import '../widgets/stat_tile.dart';
import 'onboarding_screen.dart';

/// Grafikte ne gösterilsin?
enum _ChartRange { week, today }

/// Para / süre / yaşam kartları hangi dönem için hesaplansın?
enum _Period {
  today('Bugün'),
  week('7 gün'),
  month('30 gün');

  const _Period(this.label);
  final String label;
}

/// "İstatistik" sekmesi: bugünkü sayı, geçen haftayla karşılaştırma,
/// grafik ve tahminler (para, süre, yaşam süresi).
class StatsTab extends StatefulWidget {
  const StatsTab({super.key, required this.state});

  final AppState state;

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  _ChartRange _chartRange = _ChartRange.week;
  _Period _period = _Period.today;

  AppState get state => widget.state;

  /// Paket fiyatı sorusunu doğrudan açar.
  void _openPriceEditor() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingScreen(
          state: state,
          editMode: true,
          initialStep: OnboardingStep.packPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final now = state.now;
        final events = state.events;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              'İstatistik',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _TodayCard(events: events, now: now),
            const SizedBox(height: 16),
            _WeekCard(events: events, now: now),
            const SizedBox(height: 16),
            _ChartCard(
              events: events,
              now: now,
              range: _chartRange,
              onRangeChanged: (r) => setState(() => _chartRange = r),
            ),
            const SizedBox(height: 28),
            _buildEstimates(context, events, now),
          ],
        );
      },
    );
  }

  /// Para, süre ve yaşam süresi kartları.
  Widget _buildEstimates(
    BuildContext context,
    List<SmokingEvent> events,
    DateTime now,
  ) {
    final theme = Theme.of(context);
    final c = AppColors.of(context);
    final profile = state.profile;
    final count = switch (_period) {
      _Period.today => countToday(events, now),
      _Period.week => countLastDays(events, now, 7),
      _Period.month => countLastDays(events, now, 30),
    };
    final money = moneyFor(count, profile);
    final perCigarette = lifeMinutesPerCigarette(profile.gender);
    final periodText = _period == _Period.today
        ? 'Bugün'
        : 'Son ${_period.label}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Sigaranın sana maliyeti', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          '$periodText: $count sigara',
          style: theme.textTheme.bodyMedium?.copyWith(color: c.textMuted),
        ),
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
          color: c.green,
          title: 'Harcanan para',
          value: money == null ? '—' : formatMoney(money),
          footnote: money == null
              ? 'Hesaplamak için dokun ve paket fiyatını ekle'
              : 'Paket fiyatı ${formatMoney(profile.packPrice!)} '
                    '(${profile.cigarettesPerPack} sigara) üzerinden',
          onTap: money == null ? _openPriceEditor : null,
        ),
        const SizedBox(height: 12),
        StatTile(
          icon: Icons.schedule,
          color: c.blue,
          title: 'Sigaraya giden süre',
          value: formatDuration(smokingMinutesFor(count)),
          footnote: 'Varsayım: bir sigara ~$minutesPerCigarette dk sürer',
        ),
        const SizedBox(height: 12),
        StatTile(
          icon: Icons.favorite_outline,
          color: c.purple,
          title: 'Tahmini kaybedilen yaşam süresi',
          value: formatDuration(lifeMinutesFor(count, profile.gender)),
          footnote:
              'Ortalama tahmin: sigara başına ~$perCigarette dk '
              '(UCL, 2024)',
          onInfo: () => _showLifeInfo(context, profile.gender),
        ),
        const SizedBox(height: 16),
        Text(
          'Bu sayılar kişiye özel ölçümler değil, ortalamalara dayanan '
          'tahminlerdir.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: c.textMuted),
        ),
      ],
    );
  }

  void _showLifeInfo(BuildContext context, Gender? gender) {
    final usedFor = switch (gender) {
      Gender.male => 'Sen "erkek" seçtiğin için 17 dk kullanıyoruz.',
      Gender.female => 'Sen "kadın" seçtiğin için 22 dk kullanıyoruz.',
      _ =>
        'Cinsiyet belirtilmediği için genel ortalama olan 20 dk\'yı '
            'kullanıyoruz.',
    };
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bu sayı nasıl hesaplanıyor?'),
        content: Text(
          'University College London (UCL) araştırmacılarının 2024’te '
          'Addiction dergisinde yayımladığı çalışmaya göre bir sigara, '
          'ortalama olarak erkeklerde yaklaşık 17 dakika, kadınlarda '
          'yaklaşık 22 dakika yaşam süresine mal oluyor (genel ortalama '
          '~20 dk).\n\n'
          '$usedFor\n\n'
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
                  color: c.greenText,
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

/// Fark rozeti: "2 az" (yeşil) / "3 fazla" (nötr gri) / "aynı".
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
        c.greenLight,
        c.greenText,
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

/// Son 7 gün ile önceki 7 günün karşılaştırması.
class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.events, required this.now});
  final List<SmokingEvent> events;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = AppColors.of(context);
    final comparison = compareWeeks(events, now);
    // Önceki 7 günün neredeyse tamamı kayıtlı mı? (1 gün tolerans)
    final canCompare = hasDataSince(events, addDays(now, -13));
    final percent = comparison.changePercent;
    final less = canCompare && percent != null && percent.round() < 0;

    return ChunkyCard(
      padding: const EdgeInsets.all(20),
      // Azalma varsa kart yeşil bir kutlama havasına bürünür.
      color: less ? c.greenLight : null,
      borderColor: less ? c.green : null,
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
                  number: canCompare ? '${comparison.lastWeek}' : '—',
                  label: 'Önceki 7 gün',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (canCompare && percent != null)
            ChangeChip(
              // Yüzde %0'a yuvarlanıyorsa "aynı" ikonu gösterilsin.
              difference: percent.round() == 0
                  ? 0
                  : comparison.thisWeek - comparison.lastWeek,
              text: percent.round() == 0
                  ? 'Neredeyse aynı'
                  : '${formatPercent(percent)} '
                        '${percent < 0 ? 'daha az. Harika!' : 'daha fazla'}',
            )
          else
            Text(
              'Karşılaştırma için en az 2 haftalık kayıt gerekiyor.',
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

/// Günlük (7 gün) veya saatlik (bugün) grafik kartı.
class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.events,
    required this.now,
    required this.range,
    required this.onRangeChanged,
  });

  final List<SmokingEvent> events;
  final DateTime now;
  final _ChartRange range;
  final ValueChanged<_ChartRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<BarChartItem> items;
    final String description;
    if (range == _ChartRange.week) {
      final days = dailyCounts(events, now, days: 7);
      items = [
        for (final d in days)
          BarChartItem(
            label: d.day == startOfDay(now) ? 'Bugün' : weekdayShort(d.day),
            value: d.count,
            highlight: d.day == startOfDay(now),
          ),
      ];
      description =
          'Son 7 gün: ${days.map((d) => '${weekdayLower(d.day)} '
              '${d.count}').join(', ')}';
    } else {
      final hours = hourlyCounts(events, now);
      items = [
        for (var h = 0; h < 24; h++)
          BarChartItem(
            // Her saatin altına yazı sığmaz; 3 saatte bir yazıyoruz.
            label: h % 3 == 0 ? h.toString().padLeft(2, '0') : '',
            value: hours[h],
            highlight: h == now.hour,
          ),
      ];
      description = 'Bugün saat saat sigara sayıları';
    }

    return ChunkyCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  range == _ChartRange.week
                      ? 'Günlük sigara'
                      : 'Bugün saat saat',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              SegmentedButton<_ChartRange>(
                segments: const [
                  ButtonSegment(value: _ChartRange.week, label: Text('7 gün')),
                  ButtonSegment(value: _ChartRange.today, label: Text('Bugün')),
                ],
                selected: {range},
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                onSelectionChanged: (s) => onRangeChanged(s.first),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SimpleBarChart(
            items: items,
            showValues: range == _ChartRange.week,
            semanticsLabel: description,
          ),
        ],
      ),
    );
  }
}
