import 'package:flutter/material.dart';

import '../app_state.dart';
import '../logic/goal.dart';
import '../logic/mascot_messages.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/chunky.dart';
import '../widgets/mascot.dart';
import 'goal_setup_screen.dart';

/// "Hedefim": tek bakışta ne kadar ilerlediğini gösteren sayfa.
///
/// Bilerek sade: üstte Nefes'in cümlesi, sonra iki kart.
/// 1. Yol: başlangıç → şimdi → hedef ve ilerleme çubuğu.
/// 2. Bu hafta: günlük sınır ve haftanın günleri (hedefinde kaldığın günler
///    nane renkli ve onaylı; diğerleri nötr gri, kırmızı ya da yorum yok).
/// Bırakma hedefinde ayrıca ALO 171 ve poliklinik bilgisi.
///
/// Tek giriş noktası: Bugün sekmesindeki "Hedefim" kartı.
class GoalScreen extends StatelessWidget {
  const GoalScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final status = state.goalStatus;
        return Scaffold(
          appBar: AppBar(title: const Text('Hedefim')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: status == null
                    ? const Center(child: Text('Henüz bir hedefin yok.'))
                    : _content(context, status),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, GoalStatus status) {
    final line = goalLine(status);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        MascotSpeech(text: line.text, mood: line.mood, mascotSize: 76),
        const SizedBox(height: 16),
        _PathCard(status: status),
        const SizedBox(height: 12),
        _WeekCard(status: status),
        if (status.goal.isQuit) ...[
          const SizedBox(height: 12),
          const _SupportCard(),
        ],
        const SizedBox(height: 20),
        // Süre dolduysa yeni hedef ana eylem; değilse sakin bir bağlantı.
        if (status.ended)
          ChunkyButton(
            label: 'YENİ HEDEF SEÇ',
            icon: Icons.flag_outlined,
            onPressed: () => GoalSetupScreen.open(context, state),
          )
        else
          Center(
            child: TextButton(
              onPressed: () => GoalSetupScreen.open(context, state),
              child: const Text('HEDEFİ DEĞİŞTİR'),
            ),
          ),
      ],
    );
  }
}

/// Başlangıçtan hedefe giden yol: ilerleme çubuğu + üç sayı.
class _PathCard extends StatelessWidget {
  const _PathCard({required this.status});
  final GoalStatus status;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    final goal = status.goal;
    final percentText = '%${(status.progress * 100).round()}';

    return ChunkyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goal.isQuit ? 'Bırakmak' : '%${goal.percent} azaltmak',
            style: theme.textTheme.titleLarge,
          ),
          Text(
            '${goal.amount} ${goal.unit.label} · Bitiş: '
            '${formatDayMonth(status.end)}',
            style: theme.textTheme.bodySmall?.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: 14),
          Semantics(
            label: 'İlerleme $percentText',
            child: ChunkyProgressBar(value: status.progress, height: 20),
          ),
          const SizedBox(height: 6),
          Text(
            'Yolun $percentText kadarını yürüdün',
            style: theme.textTheme.labelMedium?.copyWith(color: c.mintText),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Figure(label: 'Başlangıç', value: formatDecimal(goal.baseline)),
              _Figure(
                label: 'Şimdi',
                value: formatDecimal(status.currentLevel),
              ),
              _Figure(
                label: 'Hedef',
                value: '${status.target}',
                color: c.mintText,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Günde ortalama sigara. “Şimdi”, son 7 günün ortalaması '
            '(bugün sayılmaz).',
            style: theme.textTheme.bodySmall?.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Yol kartındaki tek sayı ("Şimdi 11").
class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(color: c.textMuted),
          ),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color ?? c.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bu haftanın günlük sınırı ve 7 günlük şerit.
class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.status});
  final GoalStatus status;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    return ChunkyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status.ended
                ? 'Hedef süren doldu'
                : 'Bu hafta · ${status.week}. hafta / ${status.steps}',
            style: theme.textTheme.labelMedium?.copyWith(color: c.textMuted),
          ),
          Text(
            'Günde en fazla ${status.limit} sigara',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final day in status.days) Expanded(child: _DayDot(day)),
            ],
          ),
          if (status.daysOnTarget > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.check_circle, color: c.mint, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hedefinde kaldığın gün: ${status.daysOnTarget}',
                    style: theme.textTheme.titleSmall,
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

/// Şeritteki bir gün: hedefinde kaldıysan nane renkli + onay, değilse
/// nötr gri; bugün mavi çerçeve içinde bugünkü sayı; gelecek günler boş.
class _DayDot extends StatelessWidget {
  const _DayDot(this.day);
  final GoalDay day;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    const size = 34.0;

    Color fill;
    Color border;
    Widget? inside;
    String meaning;
    switch (day.state) {
      case GoalDayState.onTarget:
        fill = c.mint;
        border = c.mint;
        inside = const Icon(Icons.check_rounded, color: Colors.white, size: 22);
        meaning = 'hedefinde';
      case GoalDayState.over:
        fill = c.disabled;
        border = c.disabled;
        meaning = 'bitti';
      case GoalDayState.today:
        fill = c.surface;
        border = c.blue;
        inside = Text(
          '${day.count}',
          style: theme.textTheme.labelMedium?.copyWith(color: c.blueText),
        );
        meaning = 'bugün, ${day.count} sigara';
      case GoalDayState.future:
        fill = c.surface;
        border = c.border;
        meaning = 'henüz gelmedi';
    }

    return Semantics(
      label: '${weekdayShort(day.day)}: $meaning',
      excludeSemantics: true,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(color: border, width: 2.5),
            ),
            child: inside,
          ),
          const SizedBox(height: 4),
          // Dar ekranda / büyük yazıda gün adı küçülsün, taşmasın.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              weekdayShort(day.day),
              style: theme.textTheme.labelSmall?.copyWith(color: c.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bırakma hedefinde: nereden destek alınabileceği (kaynak: T.C. Sağlık
/// Bakanlığı; bkz. SPEC.md Bölüm 9).
class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    return ChunkyCard(
      color: c.blueLight,
      borderColor: c.blue,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.support_agent, color: c.blueText, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bırakırken yalnız değilsin',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'ALO 171 Sigara Bırakma Danışma Hattı’nı arayabilir ya da '
                  'MHRS’den sigara bırakma polikliniğine randevu '
                  'alabilirsin.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
