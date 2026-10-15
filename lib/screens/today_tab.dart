import 'package:flutter/material.dart';

import '../app_state.dart';
import '../logic/goal.dart';
import '../logic/mascot_messages.dart';
import '../logic/quests.dart';
import '../logic/rewards.dart';
import '../logic/stats.dart';
import '../models/activity_log.dart';
import '../models/smoking_event.dart';
import '../services/demo_activity.dart';
import '../services/demo_device_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/chunky.dart';
import '../widgets/mascot.dart';
import '../widgets/pickers.dart';
import '../widgets/since_last_counter.dart';
import 'breathing_screen.dart';
import 'celebration_screen.dart';
import 'delay_screen.dart';
import 'goal_screen.dart';
import 'goal_setup_screen.dart';
import 'measurement_summary_screen.dart';
import 'weekly_report_screen.dart';

/// "Bugün" sekmesi: maskot, "son sigarandan beri" sayacı, erteleme butonu,
/// günlük görevler ve bugünkü sigaralar. Uygulamanın kalbi burası.
///
/// Sade tutuyoruz: her iş için TEK bir giriş noktası var (ör. ruh hali sadece
/// "Kendini dinle" görevinden seçilir). Üst çubukta sadece seri var; puan
/// kutlamalarda ve Profil'de görünür.
class TodayTab extends StatelessWidget {
  const TodayTab({super.key, required this.state});

  final AppState state;

  DemoDeviceService? get _demo {
    final device = state.device;
    return device is DemoDeviceService ? device : null;
  }

  // ---------- Eylemler ----------

  void _openDelay(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => DelayScreen(state: state)));

  void _openBreathing(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => BreathingScreen(state: state)),
  );

  void _openGoal(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => GoalScreen(state: state)));

  void _openMeasurementSummary(BuildContext context) => Navigator.of(context)
      .push(
        MaterialPageRoute<void>(
          builder: (_) => MeasurementSummaryScreen(state: state),
        ),
      );

  void _openWeeklyReport(BuildContext context, int week) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WeeklyReportScreen(state: state, week: week),
        ),
      );

  Future<void> _checkIn(BuildContext context, Mood mood) async {
    final reward = await state.logMood(mood);
    if (!context.mounted) return;
    if (reward.isEmpty) {
      _snack(context, 'Kaydedildi: ${mood.label}');
      return;
    }
    await CelebrationScreen.show(
      context,
      reward,
      calm: mood.isHard,
      title: mood.isHard ? 'Paylaştığın için teşekkürler' : null,
      message: mood.isHard
          ? 'Zor günler de geçer. Bugün kendine nazik ol; ben yanındayım.'
          : 'Kendini dinlemek güzel bir başlangıç!',
    );
  }

  Future<void> _tag(BuildContext context, SmokingEvent event) async {
    final choice = await showTriggerSheet(
      context,
      event,
      preferred: state.profile.triggers,
    );
    if (choice == null || !context.mounted) return;
    if (choice.notMine) {
      await _removeEvent(context, event);
      return;
    }
    final reward = await state.tagEvent(event, choice.trigger);
    if (!context.mounted) return;
    if (reward.isEmpty) {
      _snack(
        context,
        choice.trigger == null ? 'Neden kaldırıldı.' : 'Kaydedildi.',
      );
    } else {
      await CelebrationScreen.show(context, reward);
    }
  }

  /// "Bu sigarayı ben içmedim": onay alıp kaydı sil. Sadece bir düzeltme;
  /// puan, ses ya da kutlama yok.
  Future<void> _removeEvent(BuildContext context, SmokingEvent event) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bu kaydı silelim mi?'),
        content: Text(
          'Saat ${formatClock(event.time)} kaydı silinir. Kılıf bazen yanlış '
          'sayabilir; örneğin sigarayı bir arkadaşına verdiysen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('VAZGEÇ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('SİL'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await state.removeEvent(event);
    if (context.mounted) _snack(context, 'Kayıt silindi.');
  }

  /// Kılıfın görmediği bir sigarayı elle ekle: saati sor (varsayılan şimdi).
  /// Gelecek bir saat seçilemez. Sigara içmek gibi bu da hiçbir ses, puan ya
  /// da kutlama tetiklemez; sadece kısa bir "kaydedildi" yazısı çıkar.
  Future<void> _addManual(BuildContext context) async {
    final now = state.now;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      helpText: 'Bu sigarayı ne zaman içtin?',
    );
    if (picked == null || !context.mounted) return;
    final time = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );
    if (time.isAfter(now)) {
      _snack(context, 'Henüz gelmemiş bir saat seçilemez.');
      return;
    }
    // Şu anki dakika seçildiyse saniyeyi de koru (sayaç 0'dan başlasın).
    final sameMinute = time.hour == now.hour && time.minute == now.minute;
    await state.addManualEvent(sameMinute ? now : time);
    if (context.mounted) _snack(context, 'Kaydedildi: ${formatClock(time)}');
  }

  /// Göreve dokununca o görevi yapmaya götür.
  Future<void> _onQuestTap(BuildContext context, QuestStatus quest) async {
    switch (quest.type) {
      case QuestType.checkIn:
        final mood = await showMoodSheet(context);
        if (mood != null && context.mounted) await _checkIn(context, mood);
      case QuestType.tagTrigger:
        final today = _todayEvents();
        final untagged = today.where((e) => e.trigger == null);
        if (today.isEmpty) {
          _snack(context, 'Bugün henüz sigara kaydın yok. Ne güzel!');
        } else {
          await _tag(context, untagged.isEmpty ? today.first : untagged.first);
        }
      case QuestType.breathe:
        _openBreathing(context);
      case QuestType.delay:
        _openDelay(context);
    }
  }

  List<SmokingEvent> _todayEvents() {
    final today = startOfDay(state.now);
    return state.events
        .where((e) => startOfDay(e.time) == today)
        .toList()
        .reversed // en yeni üstte
        .toList();
  }

  void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // ---------- Ekran ----------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final now = state.now;
        final quests = state.todayQuests;
        final doneCount = quests.where((q) => q.done).length;
        final reportWeek = state.pendingWeeklyReport;
        final greeting = mascotGreeting(
          now: now,
          questsDone: doneCount,
          questsTotal: quests.length,
          measurementDay: state.measurementDay,
          week: compareWeeks(state.events, now),
          canCompareWeeks: hasDataSince(state.events, addDays(now, -13)),
          hardDay: state.todayMood?.isHard ?? false,
          delayActive: state.activeDelayStart != null,
          measurementSummaryPending: state.measurementSummaryPending,
          weeklyReportWeek: reportWeek,
          daysToQuit: state.goalStatus?.daysToQuit,
        );
        final todayEvents = _todayEvents();
        final events = state.events;
        final lastTime = events.isEmpty ? null : events.last.time;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _TopBar(state: state),
            const SizedBox(height: 8),
            if (_demo != null) ...[
              _DemoBanner(onSimulate: _demo!.simulatePickup),
              const SizedBox(height: 16),
            ],
            MascotSpeech(text: greeting.text, mood: greeting.mood),
            if (state.measurementSummaryPending) ...[
              const SizedBox(height: 12),
              ChunkyButton(
                label: 'SONUÇLARIMI GÖR',
                icon: Icons.insights,
                onPressed: () => _openMeasurementSummary(context),
              ),
            ],
            // Yeni haftalık rapor: açılır pencere değil, maskotun altında
            // bir buton (rapor görülünce kaybolur; kalıcı yeri İstatistik).
            if (reportWeek != null) ...[
              const SizedBox(height: 12),
              ChunkyButton(
                label: 'RAPORUMU GÖR',
                icon: Icons.event_note_outlined,
                onPressed: () => _openWeeklyReport(context, reportWeek),
              ),
            ],
            // "Son sigarandan beri" sayacı: ilk kayıttan sonra görünür (öncesinde
            // sayacak bir şey yok). Erteleme butonunun hemen üstünde: istek
            // geldiğinde ne kadar zamandır içmediğini görürsün.
            if (lastTime != null) ...[
              const SizedBox(height: 20),
              SinceLastCounter(last: lastTime, clock: () => state.now),
            ],
            const SizedBox(height: 20),
            _DelayEntry(state: state, onOpen: () => _openDelay(context)),
            const SizedBox(height: 24),
            // Hedef kartı: ölçüm haftası bitip özet görülünce çıkar.
            if (state.goal != null || state.canSetGoal) ...[
              _GoalEntry(
                state: state,
                onOpen: () => _openGoal(context),
                onChoose: () => GoalSetupScreen.open(context, state),
              ),
              const SizedBox(height: 24),
            ],
            _QuestsCard(quests: quests, onTap: (q) => _onQuestTap(context, q)),
            const SizedBox(height: 24),
            _TodayCigarettes(
              events: todayEvents,
              now: now,
              onTag: (e) => _tag(context, e),
              // Sadece "kılıfın göremeyeceği sigaralar olur" diyene görünür
              // (onboarding sorusu; Bilgilerimi düzenle'den değişir).
              onAdd: state.profile.smokesOutsideCase == true
                  ? () => _addManual(context)
                  : null,
              onGenerateDemo: state.events.isEmpty && _demo != null
                  ? () => loadDemoHistory(state, _demo!)
                  : null,
            ),
          ],
        );
      },
    );
  }
}

// ---------- Parçalar ----------

/// Üst çubuk: ölçüm haftası rozeti + seri. (Puan burada yok: harcanacağı
/// bir yer olmadığı için sürekli göz önünde durması gereksiz kalabalık.)
class _TopBar extends StatelessWidget {
  const _TopBar({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final streak = state.streak;
    final day = state.measurementDay;

    return Row(
      children: [
        // Expanded: dar ekranda bu yazı kısalsın, sağdaki sayaçlar taşmasın.
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: day != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: c.purpleLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      day == 0
                          ? 'Ölçüm yarın başlıyor'
                          : 'Ölçüm: $day. gün / $measurementDays',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: c.text),
                    ),
                  )
                : Text(
                    'Unlit',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: c.mintText),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        StatPill(
          icon: streakIcon,
          // Bugün henüz bir şey yapılmadıysa yaprak gri (ama seri bozulmaz).
          color: streak.activeToday ? c.leaf : c.disabledText,
          value: '${streak.current}',
          tooltip: 'Seri: ${streak.current} gün',
        ),
      ],
    );
  }
}

/// "Demo modu" uyarısı + test için "+1 sigara" butonu.
class _DemoBanner extends StatelessWidget {
  const _DemoBanner({required this.onSimulate});
  final VoidCallback onSimulate;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.science_outlined, size: 18, color: c.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Demo modu: veriler sahte.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: c.textMuted),
            ),
          ),
          TextButton(onPressed: onSimulate, child: const Text('+1 sigara')),
        ],
      ),
    );
  }
}

/// Erteleme butonu (ya da süren ertelemeye dönüş kartı).
class _DelayEntry extends StatelessWidget {
  const _DelayEntry({required this.state, required this.onOpen});
  final AppState state;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final start = state.activeDelayStart;
    if (start != null) {
      final left = delayMinutes - state.now.difference(start).inMinutes;
      return ChunkyCard(
        color: c.blueLight,
        borderColor: c.blue,
        onTap: onOpen,
        child: Row(
          children: [
            Icon(Icons.timer_outlined, color: c.blueText, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                left > 0
                    ? 'Ertelemen sürüyor: yaklaşık $left dk kaldı'
                    : 'Erteleme süren doldu! Nasıl geçtiğini söyle.',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: c.blueText),
              ),
            ),
            Icon(Icons.chevron_right, color: c.blueText),
          ],
        ),
      );
    }
    return Column(
      children: [
        ChunkyButton(
          label: 'CANIM SİGARA İSTİYOR',
          icon: Icons.timer_outlined,
          variant: ChunkyVariant.blue,
          height: 60,
          onPressed: onOpen,
        ),
        const SizedBox(height: 6),
        Text(
          '$delayMinutes dakika birlikte bekleyelim, sonra karar senin.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: c.textMuted),
        ),
      ],
    );
  }
}

/// "Hedefim" kartı: bu haftanın sınırı ve ilerleme çubuğu; dokununca
/// Hedefim sayfası açılır. Hedef yoksa küçük bir davet (seçmek isteğe
/// bağlı).
class _GoalEntry extends StatelessWidget {
  const _GoalEntry({
    required this.state,
    required this.onOpen,
    required this.onChoose,
  });

  final AppState state;
  final VoidCallback onOpen;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    final status = state.goalStatus;

    if (status == null) {
      return ChunkyCard(
        onTap: onChoose,
        child: Row(
          children: [
            Icon(Icons.flag_outlined, color: c.mintText, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bir hedef seç', style: theme.textTheme.titleSmall),
                  Text(
                    'İstersen ölçüm haftana göre bir azaltma hedefi koy.',
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
      );
    }

    return ChunkyCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: c.mintText, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Hedefim', style: theme.textTheme.titleSmall),
              ),
              Text(
                '%${(status.progress * 100).round()}',
                style: theme.textTheme.titleSmall?.copyWith(color: c.mintText),
              ),
              Icon(Icons.chevron_right, color: c.textMuted),
            ],
          ),
          const SizedBox(height: 4),
          Text(_goalText(status), style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          ChunkyProgressBar(value: status.progress),
        ],
      ),
    );
  }
}

/// "Hedefim" kartındaki tek cümle.
String _goalText(GoalStatus status) {
  if (status.goal.isQuit) {
    final days = status.daysToQuit ?? 0;
    if (days == 0) return 'Bugün bırakma günün';
    if (days == 1) return 'Yarın bırakma günün';
    if (days > 1) {
      final limit = status.limit;
      return limit == null
          ? 'Bırakma gününe $days gün'
          : 'Bırakma gününe $days gün · bu hafta günde en fazla $limit';
    }
    // Bırakma gününden sonra: sigarasız günler (sadece artar).
    return status.smokeFreeDays > 0
        ? 'Sigarasız gün: ${status.smokeFreeDays}'
        : 'Her sigarasız gün burada sayılır';
  }
  return status.ended
      ? 'Hedef süren doldu; yeni bir süre seçebilirsin.'
      : 'Bu hafta günde en fazla ${status.limit} sigara';
}

/// Günlük görevler kartı.
class _QuestsCard extends StatelessWidget {
  const _QuestsCard({required this.quests, required this.onTap});
  final List<QuestStatus> quests;
  final ValueChanged<QuestStatus> onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    final done = quests.where((q) => q.done).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Günlük görevler', style: theme.textTheme.titleLarge),
            ),
            Text(
              '$done / ${quests.length}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: done == quests.length ? c.mintText : c.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ChunkyCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < quests.length; i++) ...[
                if (i > 0) Divider(height: 2, color: c.border),
                _QuestRow(quest: quests[i], onTap: () => onTap(quests[i])),
              ],
            ],
          ),
        ),
        if (done == quests.length) ...[
          const SizedBox(height: 10),
          Text(
            'Hepsi tamam! Yeni görevler gece yarısı gelecek. '
            '+$xpAllQuestsBonus puan bonus kazandın.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: c.mintText),
          ),
        ],
      ],
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({required this.quest, required this.onTap});
  final QuestStatus quest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    final type = quest.type;

    return InkWell(
      onTap: quest.done ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: quest.done ? c.mintLight : c.goldLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                quest.done ? Icons.check_rounded : type.icon,
                color: quest.done ? c.mintText : c.goldShadow,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.title, style: theme.textTheme.titleSmall),
                  Text(
                    type.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              quest.done ? 'Tamam' : '+$xpPerQuest puan',
              style: theme.textTheme.labelMedium?.copyWith(
                color: quest.done ? c.mintText : c.goldShadow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bugünkü sigaralar ve nedenleri.
class _TodayCigarettes extends StatefulWidget {
  const _TodayCigarettes({
    required this.events,
    required this.now,
    required this.onTag,
    required this.onAdd,
    required this.onGenerateDemo,
  });

  /// Bugünkü olaylar, en yeni üstte.
  final List<SmokingEvent> events;
  final DateTime now;
  final ValueChanged<SmokingEvent> onTag;

  /// "Elle sigara ekle" (null ise buton yok).
  final VoidCallback? onAdd;
  final VoidCallback? onGenerateDemo;

  @override
  State<_TodayCigarettes> createState() => _TodayCigarettesState();
}

class _TodayCigarettesState extends State<_TodayCigarettes> {
  static const _collapsedCount = 5;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    final events = widget.events;
    final visible = _expanded ? events : events.take(_collapsedCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Bugünkü sigaraların',
                style: theme.textTheme.titleLarge,
              ),
            ),
            Text(
              '${events.length}',
              style: theme.textTheme.titleMedium?.copyWith(color: c.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Nedenini işaretlemek isteğe bağlı; alışkanlığını tanımana yardım '
          'eder.',
          style: theme.textTheme.bodySmall?.copyWith(color: c.textMuted),
        ),
        const SizedBox(height: 10),
        ChunkyCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: events.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        widget.onGenerateDemo == null
                            ? 'Bugün henüz kayıt yok.'
                            : 'Henüz hiç kayıt yok. Uygulamayı denemek için '
                                  'son iki haftanın demo verisini '
                                  'oluşturabilirsin.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (widget.onGenerateDemo != null) ...[
                        const SizedBox(height: 14),
                        ChunkyButton(
                          label: 'DEMO VERİSİ ÜRET',
                          icon: Icons.auto_awesome,
                          variant: ChunkyVariant.gold,
                          onPressed: widget.onGenerateDemo,
                        ),
                      ],
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < visible.length; i++) ...[
                      if (i > 0) Divider(height: 2, color: c.border),
                      _CigaretteRow(
                        event: visible[i],
                        now: widget.now,
                        onTag: () => widget.onTag(visible[i]),
                      ),
                    ],
                    if (events.length > _collapsedCount)
                      TextButton(
                        onPressed: () => setState(() => _expanded = !_expanded),
                        child: Text(
                          _expanded
                              ? 'DAHA AZ GÖSTER'
                              : 'TÜMÜNÜ GÖSTER (${events.length})',
                        ),
                      ),
                  ],
                ),
        ),
        if (widget.onAdd != null) ...[
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add),
              label: const Text('ELLE SİGARA EKLE'),
            ),
          ),
        ],
      ],
    );
  }
}

class _CigaretteRow extends StatelessWidget {
  const _CigaretteRow({
    required this.event,
    required this.now,
    required this.onTag,
  });

  final SmokingEvent event;
  final DateTime now;
  final VoidCallback onTag;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    final trigger = event.trigger;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.smoking_rooms, color: c.textMuted, size: 22),
          const SizedBox(width: 10),
          Text(formatClock(event.time), style: theme.textTheme.titleSmall),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              // Elle eklenen sigara ayırt edilsin (kılıf görmedi).
              event.source == EventSource.manual
                  ? '${formatTimeAgo(event.time, now)} · elle'
                  : formatTimeAgo(event.time, now),
              style: theme.textTheme.bodySmall?.copyWith(color: c.textMuted),
            ),
          ),
          // Flexible: uzun neden adı ("Telefonda konuşurken") dar ekranda
          // kısaltılsın, satır taşmasın.
          Flexible(
            child: ActionChip(
              avatar: Icon(
                trigger == null ? Icons.add : Icons.label_outline,
                size: 18,
                color: trigger == null ? c.blueText : c.purple,
              ),
              label: Text(
                trigger?.label ?? 'Neden?',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                color: trigger == null ? c.blueText : c.text,
              ),
              side: BorderSide(
                color: trigger == null ? c.blue : c.purple,
                width: 2,
              ),
              backgroundColor: trigger == null ? c.surface : c.purpleLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onPressed: onTag,
            ),
          ),
        ],
      ),
    );
  }
}
