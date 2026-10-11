import 'package:flutter/material.dart';

import '../app_state.dart';
import '../logic/mascot_messages.dart';
import '../logic/stats.dart';
import '../logic/weekly_report.dart';
import '../services/effects.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/bar_chart.dart';
import '../widgets/change_chip.dart';
import '../widgets/chunky.dart';
import '../widgets/mascot.dart';

/// Haftalık rapor: biten bir haftanın kısa özeti.
///
/// Sıra bilerek böyle:
/// 1. Nefes'in kişisel cümlesi (önce olumlu olan söylenir).
/// 2. Sigara: bu hafta ve önceki hafta, günlük grafik.
/// 3. Örüntün: en yoğun saat, günün ilk sigarası, en sık neden.
/// 4. Kendine iyi baktığın anlar: görev günleri, ertelemeler, nefes, ruh
///    hali. (Her gün topladığımız veri burada kullanıcıya geri döner.)
/// 5. Bu hafta kazandıkların: SADECE içilmeyen sigara varsa ("0" yazmayız).
/// 6. Gelecek hafta için tek, somut bir fikir.
///
/// Sadece kullanıcının kendi verisi; artış nötr renkle (bkz. ChangeChip).
/// Konfeti yok: rapor bir ödül değil, bir ayna. İlk açılışta sadece hafif
/// bir "ding" çalar.
class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({
    super.key,
    required this.state,
    required this.week,
  });

  final AppState state;

  /// Kaçıncı haftanın raporu (2, 3, ...).
  final int week;

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  AppState get state => widget.state;

  /// "Bugün"den yeni rapor olarak mı açıldı? (Ses sadece o zaman.)
  late final bool _firstTime = state.pendingWeeklyReport == widget.week;

  @override
  void initState() {
    super.initState();
    // Bu ekran bir dokunuşla açılır; ses izni sorunu yok.
    if (_firstTime) Effects.celebrate();
  }

  Future<void> _done() async {
    await state.markWeeklyReportSeen(widget.week);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    final report = state.weeklyReport(widget.week);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Kapat',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: report == null
                ? const Center(child: Text('Bu rapor henüz hazır değil.'))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      Text(
                        '${report.week}. haftanın raporu',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: c.mintText,
                        ),
                      ),
                      Text(
                        formatDayRange(report.start, report.lastDay),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: c.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          final line = weeklyReportLine(report);
                          return MascotSpeech(text: line.text, mood: line.mood);
                        },
                      ),
                      const _Title('Sigara'),
                      _CigarettesCard(report: report),
                      const _Title('Örüntün'),
                      _PatternCard(report: report),
                      const _Title('Kendine iyi baktığın anlar'),
                      _SelfCareCard(report: report),
                      if (report.notSmoked > 0) ...[
                        const _Title('Bu hafta kazandıkların'),
                        _GainsCard(report: report),
                      ],
                      const _Title('Gelecek hafta için bir fikir'),
                      ChunkyCard(
                        color: c.blueLight,
                        borderColor: c.blue,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: c.blueText,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                weeklyTip(report),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ChunkyButton(label: 'DEVAM', onPressed: _done),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Bölüm başlığı.
class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

/// Bu hafta ve önceki hafta + 7 günün grafiği.
class _CigarettesCard extends StatelessWidget {
  const _CigarettesCard({required this.report});
  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = AppColors.of(context);
    final change = report.changeFromPrevious;
    final baseline = report.gains?.baseline;
    final description =
        'Günlük: ${report.days.map((d) => '${weekdayLower(d.day)} '
            '${d.count}').join(', ')}';

    return ChunkyCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Number(
                  number: '${report.total}',
                  label: 'Bu hafta',
                  emphasized: true,
                ),
              ),
              Expanded(
                child: _Number(
                  number: '${report.previous.total}',
                  label: report.previousIsMeasurement
                      ? 'Ölçüm haftası'
                      : 'Önceki hafta',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ChangeChip(difference: change),
          const SizedBox(height: 10),
          Text(
            [
              'Günde ortalama ${formatDecimal(report.summary.dailyAverage)}',
              if (baseline != null)
                'başlangıç noktan ${formatDecimal(baseline)}',
            ].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: 16),
          SimpleBarChart(
            items: [
              for (final d in report.days)
                BarChartItem(label: weekdayShort(d.day), value: d.count),
            ],
            showValues: true,
            semanticsLabel: description,
          ),
        ],
      ),
    );
  }
}

class _Number extends StatelessWidget {
  const _Number({
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

/// Bu haftanın örüntüsü: en yoğun saat, ilk sigara, en sık neden.
class _PatternCard extends StatelessWidget {
  const _PatternCard({required this.report});
  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final summary = report.summary;
    final peak = summary.peakHour;
    final first = summary.averageFirstMinute;
    final previousFirst = report.previous.averageFirstMinute;
    final trigger = summary.topTrigger;

    return ChunkyCard(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.schedule,
            color: c.purple,
            title: 'En yoğun saatin',
            value: peak == null ? '—' : formatHourRange(peak),
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.wb_twilight,
            color: c.gold,
            title: 'Günün ilk sigarası (ortalama)',
            value: first == null ? '—' : formatMinuteOfDay(first),
            footnote: first == null || previousFirst == null
                ? null
                : '${report.previousIsMeasurement ? 'Ölçüm haftası' : 'Önceki hafta'}: '
                      '${formatMinuteOfDay(previousFirst)}',
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.label_outline,
            color: c.mint,
            title: 'En sık neden',
            value: trigger?.label ?? '—',
            footnote: trigger == null
                ? 'Bu hafta neden işaretlemedin. İstersen sigaraların '
                      'yanındaki "Neden?" ile işaretleyebilirsin.'
                : '${summary.topTriggerCount} kez işaretledin.',
          ),
        ],
      ),
    );
  }
}

/// İkon + başlık + değer (+ dipnot) satırı.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    this.footnote,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(color: c.textMuted),
              ),
              Text(value, style: theme.textTheme.titleMedium),
              if (footnote != null)
                Text(
                  footnote!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: c.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Kendine iyi baktığın anlar: görev günleri, ertelemeler, nefes, puan ve
/// ruh hali kayıtları.
class _SelfCareCard extends StatelessWidget {
  const _SelfCareCard({required this.report});
  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);

    return ChunkyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            icon: streakIcon,
            color: c.leaf,
            title: 'Görev yaptığın gün',
            value: '${report.activeDays} / $daysPerWeek',
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.timer_outlined,
            color: c.blue,
            title: 'Ertelenen istek',
            value: '${report.successfulDelays}',
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.air,
            color: c.mint,
            title: 'Nefes molası',
            value: '${report.breaths}',
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.bolt,
            color: c.gold,
            title: 'Kazandığın puan',
            value: '${report.xp}',
          ),
          if (report.moods.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Kendini dinlediğin anlar',
              style: theme.textTheme.bodySmall?.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: 6),
            // Soldan sağa olumsuzdan olumluya (Mood sırası).
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in report.moods.entries)
                  Tooltip(
                    message: entry.key.label,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: c.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(entry.key.icon, size: 20, color: c.blueText),
                          const SizedBox(width: 6),
                          Text(
                            '${entry.key.label}: ${entry.value}',
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Bu haftanın kazancı (başlangıç noktasına göre, net). Sadece içilmeyen
/// sigara varsa gösterilir.
class _GainsCard extends StatelessWidget {
  const _GainsCard({required this.report});
  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    final gains = report.gains!;
    final money = gains.money;

    return ChunkyCard(
      color: c.mintLight,
      borderColor: c.mint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            icon: Icons.smoke_free,
            color: c.mintText,
            title: 'İçmediğin sigara',
            value: '${gains.notSmoked}',
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.savings_outlined,
            color: c.blue,
            title: 'Cebinde kalan para',
            value: money == null ? '—' : formatMoney(money),
            footnote: money == null
                ? 'Paket fiyatını İstatistik’e eklersen hesaplanır.'
                : null,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.favorite_outline,
            color: c.purple,
            title: 'Korunan yaşam süresi',
            value: formatDuration(gains.lifeMinutes),
          ),
          const SizedBox(height: 12),
          Text(
            'Başlangıç noktana (ölçüm haftasında günde '
            '${formatDecimal(gains.baseline)}) göre. Yaşam süresi ortalama '
            'tahmin: içilmeyen sigara başına ~$lifeMinutesPerCigarette dk '
            '(UCL, 2024).',
            style: theme.textTheme.bodySmall?.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
