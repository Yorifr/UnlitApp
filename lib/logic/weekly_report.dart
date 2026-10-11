// Haftalık rapor.
//
// Ölçüm haftasından sonra her 7 günde bir, BİTEN haftanın kısa bir raporu
// çıkar. Haftalar takibin başladığı günden sayılır (takvim haftası değil):
// - 1. hafta = ölçüm haftası (takibin 1.–7. günü). Onun raporu zaten
//   "Ölçüm haftası özeti" (measurement.dart).
// - 2. hafta = 8.–14. gün, 3. hafta = 15.–21. gün...
//
// Neden takvim haftası (pazartesi–pazar) değil? Kullanıcı çarşamba
// başladıysa ilk takvim haftası yarım kalırdı. Ölçüm haftasıyla aynı
// ritimde gitmek, her haftayı tam 7 günle karşılaştırmayı sağlar.
//
// Kurallar (CLAUDE.md):
// - Her sayı kullanıcının KENDİ verisi; uydurma yok.
// - Sadece biten haftalar raporlanır: hafta bitmeden yorum yapılmaz.
// - Artış nötr dille gösterilir; suçlama yok. İçilmeyen sigara yoksa "0"
//   diye göstermeyiz, o bölümü hiç açmayız.
// - Rapor, toplanan verinin kullanıcıya geri döndüğü yer: ruh hali,
//   işaretlenen nedenler ve ertelemeler burada haftalık olarak görünür.

import '../models/activity_log.dart';
import '../models/pack_price.dart';
import '../models/smoking_event.dart';
import 'measurement.dart';
import 'quests.dart';
import 'stats.dart';

/// Bir hafta kaç gün? (Ölçüm haftası da 7 gün; 1. hafta = ölçüm haftası.)
const int daysPerWeek = measurementDays;

/// İlk haftalık rapor 2. haftanın raporudur (1. haftanınki ölçüm özeti).
const int firstWeeklyReport = 2;

/// [day], takibin kaçıncı günü? (Takibin başladığı gün = 1.)
int trackingDayNumber(DateTime day, DateTime trackingStart) =>
    daysBetween(trackingStart, day) + 1;

/// [week]. haftanın ilk günü (00:00).
DateTime weekStart(DateTime trackingStart, int week) =>
    addDays(startOfDay(trackingStart), (week - 1) * daysPerWeek);

/// Bugüne kadar kaç hafta BİTTİ? (0 = henüz hiçbiri; ölçüm haftası
/// bitince 1.) Takip başlamadıysa 0.
int completedWeeks(DateTime now, DateTime? trackingStart) {
  if (trackingStart == null) return 0;
  final day = trackingDayNumber(now, trackingStart);
  return day < 1 ? 0 : (day - 1) ~/ daysPerWeek;
}

/// Bir haftanın raporu.
class WeeklyReport {
  const WeeklyReport({
    required this.week,
    required this.start,
    required this.days,
    required this.summary,
    required this.previous,
    required this.gains,
    required this.activeDays,
    required this.successfulDelays,
    required this.breaths,
    required this.xp,
    required this.moods,
  });

  /// Kaçıncı hafta (2, 3, ...).
  final int week;

  /// Haftanın ilk günü (00:00).
  final DateTime start;

  /// Haftanın son günü (00:00).
  DateTime get lastDay => addDays(start, daysPerWeek - 1);

  /// Haftanın 7 günü ve o günlerin sigara sayıları (eskiden yeniye).
  final List<DayCount> days;

  /// Bu haftanın özeti: toplam, en yoğun saat, en sık neden, ilk sigara.
  final PeriodSummary summary;

  /// Önceki haftanın özeti (2. hafta için bu, ölçüm haftasıdır).
  final PeriodSummary previous;

  /// Bu haftanın kazancı, başlangıç noktasına (ölçüm haftası ortalaması)
  /// göre NET hesap. Ölçüm haftasında hiç kayıt yoksa null (karşılaştıracak
  /// bir başlangıç yok).
  final Gains? gains;

  /// En az bir görev yapılan (puan kazanılan) gün sayısı (0–7).
  final int activeDays;

  /// Başarılı ertelemeler ("İSTEK GEÇTİ").
  final int successfulDelays;

  /// Tamamlanan nefes egzersizleri.
  final int breaths;

  /// Bu hafta kazanılan puan.
  final int xp;

  /// "Kendini dinle" kayıtları: her ruh hali kaç kez seçildi. Sıra, [Mood]
  /// sırasıdır (soldan sağa olumsuzdan olumluya); hiç seçilmeyenler yok.
  final Map<Mood, int> moods;

  /// Bu haftaki toplam sigara.
  int get total => summary.total;

  /// Önceki haftaya göre fark (negatif = azalma).
  int get changeFromPrevious => summary.total - previous.total;

  /// İçilmeyen sigara (başlangıç noktasına göre; yoksa 0).
  int get notSmoked => gains?.notSmoked ?? 0;

  /// Önceki hafta ölçüm haftası mı? (Ekranda "ölçüm haftana göre" demek
  /// için.)
  bool get previousIsMeasurement => week == firstWeeklyReport;

  /// Bu hafta hiçbir şey olmadı mı? (Ne sigara kaydı ne görev ne ruh hali.)
  bool get isEmpty => total == 0 && xp == 0 && moods.isEmpty;
}

/// [week]. haftanın raporu. Hafta henüz bitmediyse, [week] 2'den küçükse ya
/// da takip başlamadıysa null.
WeeklyReport? buildWeeklyReport({
  required int week,
  required List<SmokingEvent> events,
  required ActivityLog activity,
  required DateTime? trackingStart,
  required DateTime now,
  required PriceHistory prices,
}) {
  if (trackingStart == null ||
      week < firstWeeklyReport ||
      week > completedWeeks(now, trackingStart)) {
    return null;
  }
  final start = weekStart(trackingStart, week);
  final end = addDays(start, daysPerWeek);
  bool inWeek(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  final baseline = summarizeMeasurementWeek(events, trackingStart).dailyAverage;

  final moods = <Mood, int>{};
  for (final mood in Mood.values) {
    final count = activity.moods
        .where((m) => m.mood == mood && inWeek(m.time))
        .length;
    if (count > 0) moods[mood] = count;
  }
  final weekXp = activity.xp.where((x) => inWeek(x.time)).toList();

  return WeeklyReport(
    week: week,
    start: start,
    days: [
      for (var i = 0; i < daysPerWeek; i++)
        DayCount(
          addDays(start, i),
          countBetween(events, addDays(start, i), addDays(start, i + 1)),
        ),
    ],
    summary: summarizePeriod(events, start, end),
    previous: summarizePeriod(
      events,
      weekStart(trackingStart, week - 1),
      start,
    ),
    gains: baseline == 0
        ? null
        : gainsBetween(
            events: events,
            baseline: baseline,
            from: start,
            to: end,
            prices: prices,
          ),
    activeDays: weekXp.map((x) => startOfDay(x.time)).toSet().length,
    successfulDelays: activity.delays
        .where((d) => inWeek(d.end) && d.outcome == DelayOutcome.success)
        .length,
    breaths: activity.breaths.where(inWeek).length,
    xp: weekXp.fold(0, (sum, x) => sum + x.amount),
    moods: moods,
  );
}
