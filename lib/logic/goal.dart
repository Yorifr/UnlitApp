// Azaltma hedefi: haftalık sınırlar, ilerleme ve zorluk.
//
// Nasıl çalışır?
// - Kullanıcı ölçüm haftasından sonra bir hedef seçer: "%50 azalt, 8 hafta".
// - Hedef sayısı = başlangıç noktası (ölçüm haftasında günde ortalama) ×
//   (100 − yüzde) / 100. Örn. günde 15 → %50 → günde en fazla 8 (yuvarlanır).
// - Bir anda değil, HAFTA HAFTA azaltılır: her hafta için bir günlük sınır
//   var. İlk hafta sınır başlangıca yakındır, son hafta hedefe eşittir.
// - İlerleme = başlangıçtan hedefe giden yolun ne kadarı yüründü; "şimdi"
//   için son 7 TAMAMLANMIŞ günün ortalaması kullanılır (bugün sayılmaz,
//   böylece sayı sigaradan hemen sonra değişmez).
//
// Kurallar (CLAUDE.md):
// - Sınırın üstüne çıkmak ceza getirmez: puan düşmez, seri bozulmaz, mesaj
//   ya da kırmızı renk yok. Ekranda sadece nötr gri görünür.
// - "Hedefinde kaldığın gün" sayısı sadece artar.
// - Zorluk etiketleri bilimsel bir ölçüm değil, ekibin kaba bir tahminidir
//   (haftada ne kadar azaltılacağına bakar; bkz. SPEC.md Bölüm 11).
//
// Bırakma hedefi (0.12.0): süre yerine bir BIRAKMA GÜNÜ seçilir.
// - "O güne kadar azaltarak": günlük sınır her hafta biraz iner, bırakma
//   gününde 0 olur.
// - "O gün birden": bırakma gününe kadar sınır yok; o gün 0.
// - Bırakma gününden sonra hedef "bitmez": sigarasız günler sayılır (sadece
//   artar). Sigara içilen gün nötr gri; suçlama yok.

import '../models/goal.dart';
import '../models/smoking_event.dart';
import 'stats.dart';

// ---------- Hedef sayısı ve süre ----------

/// Hedefte günde en fazla kaç sigara? (Başlangıç × kalan yüzde, yuvarlanır.)
int goalTarget(double baseline, int percent) =>
    (baseline * (100 - percent) / 100).round();

/// Bir hedefin günlük hedef sayısı.
int targetOf(Goal goal) => goalTarget(goal.baseline, goal.percent);

/// Hedefin bittiği gün (00:00; bu gün artık hedef süresinin dışında).
/// "Ay" takvim ayıdır: 10 Ekim + 2 ay = 10 Aralık.
DateTime goalEndFrom(DateTime start, int amount, GoalUnit unit) {
  final day = startOfDay(start);
  return switch (unit) {
    GoalUnit.week => addDays(day, 7 * amount),
    GoalUnit.month => DateTime(day.year, day.month + amount, day.day),
  };
}

/// Bir hedefin bitiş günü. Bırakma hedefinde bu, bırakma günüdür.
DateTime goalEnd(Goal goal) => goal.isQuit
    ? quitDayOf(goal)
    : goalEndFrom(goal.start, goal.amount, goal.unit);

// ---------- Bırakma günü ----------

/// Önerilen bırakma günü: kaç gün sonra? Rehberler bırakma gününü yakın
/// seçmeyi öneriyor: "en fazla bir iki hafta sonra" (NCI Smokefree), "önümüzdeki
/// iki hafta içinde" (Avustralya Quit, quit.org.au). Uzak bir tarih motivasyonu
/// azaltabilir. (Kaynaklar: SPEC.md Bölüm 9.)
const int suggestedQuitDays = 14;

/// Bırakma günü bundan uzaksa nazik bir not gösterilir (aynı kaynaklar).
const int quitDayNoteAfterDays = 14;

/// Bir bırakma hedefinin bırakma günü (00:00). 0.12.0'dan önceki bırakma
/// hedeflerinde bırakma günü yoktu; onlarda süre bitişi bırakma günü sayılır.
DateTime quitDayOf(Goal goal) =>
    startOfDay(goal.quitDay ?? goalEndFrom(goal.start, goal.amount, goal.unit));

/// Bırakma yolu. Eski bırakma hedeflerinde boştur: onlar azaltarak
/// ilerliyordu.
QuitMethod quitMethodOf(Goal goal) => goal.quitMethod ?? QuitMethod.gradual;

/// Hedef kaç haftalık adıma bölünür? Süre tam hafta değilse (ör. "1 ay" =
/// 30 gün) artan birkaç gün son haftaya eklenir: 30 gün → 4 adım.
int goalStepCount(DateTime start, DateTime end) {
  final steps = daysBetween(start, end) ~/ 7;
  return steps < 1 ? 1 : steps;
}

/// [day], hedefin kaçıncı haftası? (1'den başlar. Süre bittiyse son hafta.)
int goalWeekOf(Goal goal, DateTime day) {
  final steps = goalStepCount(goal.start, goalEnd(goal));
  final week = daysBetween(goal.start, day) ~/ 7 + 1;
  return week.clamp(1, steps);
}

/// [week]. haftada günde en fazla kaç sigara?
///
/// Sınır, hedef konduğundaki seviyeden ([Goal.from]) hedefe doğru eşit
/// adımlarla iner; son hafta hedefe eşittir. Yukarı yuvarlanır ("en fazla"
/// sınırı küçük adımlarla, rahat başlasın).
///
/// Bırakma hedefinde ("azaltarak") hedefe (0) bırakma GÜNÜNDE ulaşılır;
/// ondan önceki haftalar eşit adımlarla iner. Örn. günde 15, 2 hafta:
/// 1. hafta 10, 2. hafta 5, bırakma günü 0.
int weeklyLimit(Goal goal, int week) {
  final target = targetOf(goal);
  final steps = goalStepCount(goal.start, goalEnd(goal));
  if (goal.from <= target) return target;
  final value = goal.isQuit
      ? goal.from * (steps - week + 1) / (steps + 1)
      : target + (goal.from - target) * (steps - week) / steps;
  // Küçük bir pay: 10.0000001 gibi bir küsurat 11'e yuvarlanmasın.
  return (value - 1e-9).ceil();
}

/// [day] günü için günlük sınır. Süre bittiyse hedefin kendisi.
///
/// Bırakma hedefinde: bırakma gününden itibaren 0. "O gün birden" yolunda
/// bırakma gününden önce sınır YOK (null).
int? limitOn(Goal goal, DateTime day) {
  if (goal.isQuit) {
    if (!startOfDay(day).isBefore(quitDayOf(goal))) return 0;
    if (quitMethodOf(goal) == QuitMethod.abrupt) return null;
  }
  return weeklyLimit(goal, goalWeekOf(goal, day));
}

// ---------- Zorluk ----------

/// Hedefin zorluğu: haftada başlangıcın yüzde kaçı kadar azaltılacağına
/// göre kaba bir tahmin. Etiketler bilerek cesaret kırmayan kelimeler.
enum GoalPace {
  relaxed('Rahat', 1),
  balanced('Dengeli', 2),
  ambitious('İddialı', 3),
  veryAmbitious('Çok iddialı', 4);

  const GoalPace(this.label, this.level);
  final String label;

  /// 1–4: ekranda kaç çubuğun dolu olacağı.
  final int level;
}

/// Haftada en fazla yüzde kaç azaltılırsa "Rahat", "Dengeli", "İddialı"?
/// (Ekibin varsayımı; kaynaklı bir sayı değil. Ekranda sayı olarak
/// gösterilmez, sadece etiketi seçer.)
const double relaxedMaxPerWeek = 10;
const double balancedMaxPerWeek = 20;
const double ambitiousMaxPerWeek = 35;

/// [percent] azaltmayı [start]–[end] arasında yapmanın zorluğu.
GoalPace goalPace(int percent, DateTime start, DateTime end) {
  final weeks = daysBetween(start, end) / 7;
  final perWeek = percent / (weeks <= 0 ? 1 : weeks);
  if (perWeek <= relaxedMaxPerWeek) return GoalPace.relaxed;
  if (perWeek <= balancedMaxPerWeek) return GoalPace.balanced;
  if (perWeek <= ambitiousMaxPerWeek) return GoalPace.ambitious;
  return GoalPace.veryAmbitious;
}

/// Önerilen süre (hafta): "Dengeli" bir hız (haftada ~%12,5).
/// %25 → 2, %50 → 4, %75 → 6, %100 → 8 hafta.
int suggestedWeeks(int percent) => (percent / 12.5).ceil();

/// Haftada günde yaklaşık kaç sigara azaltılacak? ([from]'dan hedefe.)
double reductionPerWeek(double from, int target, int steps) =>
    from <= target ? 0 : (from - target) / steps;

// ---------- Hedefin durumu (Hedefim sayfası için) ----------

/// Haftalık şeritteki bir günün durumu.
enum GoalDayState {
  /// Gün bitti, sınırın içinde kalındı.
  onTarget,

  /// Gün bitti, sınırın üstünde. (Nötr gri; ceza ya da kırmızı yok.)
  over,

  /// Bugün: henüz bitmedi, yorum yapılmaz.
  today,

  /// Henüz gelmedi.
  future,

  /// Gün bitti ama o gün sınır yoktu ("o gün birden" yolunda bırakma
  /// gününden önceki hazırlık günleri). Nötr; yorum yapılmaz.
  noLimit,
}

class GoalDay {
  const GoalDay({
    required this.day,
    required this.count,
    required this.limit,
    required this.state,
  });

  final DateTime day;
  final int count;

  /// O günün sınırı (sınır yoksa null).
  final int? limit;
  final GoalDayState state;
}

/// Hedefin şu anki durumu: hedefim sayfası ve Bugün'deki kart bunu gösterir.
class GoalStatus {
  const GoalStatus({
    required this.goal,
    required this.target,
    required this.end,
    required this.steps,
    required this.week,
    required this.limit,
    required this.ended,
    required this.daysSinceStart,
    required this.currentLevel,
    required this.progress,
    required this.daysOnTarget,
    required this.days,
    this.daysToQuit,
    this.smokeFreeDays = 0,
  });

  final Goal goal;

  /// Günlük hedef (son haftanın sınırı).
  final int target;

  /// Hedefin bittiği gün.
  final DateTime end;

  /// Toplam hafta (adım) sayısı.
  final int steps;

  /// Şu an kaçıncı hafta (1..steps).
  final int week;

  /// Bugünün (bu haftanın) günlük sınırı. "O gün birden" yolunda bırakma
  /// gününden önce sınır yok: null.
  final int? limit;

  /// Hedef süresi doldu mu? (Bırakma hedefi hiç "dolmaz": bırakma gününden
  /// sonra sigarasız günler sayılır.)
  final bool ended;

  /// Hedef konalı kaç gün oldu? (Bugün konduysa 0.)
  final int daysSinceStart;

  /// Son 7 tamamlanmış günde günde ortalama sigara ("şimdi").
  final double currentLevel;

  /// Başlangıçtan hedefe giden yolun ne kadarı yüründü (0–1).
  final double progress;

  /// Hedef konalı beri sınırın içinde kalınan (biten) gün sayısı.
  /// Sadece artar.
  final int daysOnTarget;

  /// Bu 7 günlük dilimin günleri (şerit için).
  final List<GoalDay> days;

  /// Bırakma gününe kaç gün var? (Bugünse 0, geçtiyse eksi. Bırakma hedefi
  /// değilse null.)
  final int? daysToQuit;

  /// Bırakma gününden sonraki BİTEN günlerden kaçında hiç sigara yok.
  /// Sadece artar (sigara içilen bir gün sayıyı düşürmez, sadece eklenmez).
  final int smokeFreeDays;

  /// Hedefe ulaşıldı mı? (Son 7 günün ortalaması hedefte ya da altında.)
  bool get reached => currentLevel <= target;

  /// Bırakma günü geldi mi (bugün ya da geçti)?
  bool get quitStarted => daysToQuit != null && daysToQuit! <= 0;
}

/// Hedefin [now] anındaki durumu. [events] eskiden yeniye sıralı olmalı.
GoalStatus goalStatus({
  required Goal goal,
  required List<SmokingEvent> events,
  required DateTime now,
}) {
  final today = startOfDay(now);
  final start = startOfDay(goal.start);
  final end = goalEnd(goal);
  final target = targetOf(goal);
  final sinceStart = daysBetween(start, today);

  // Her günün sigara sayısı (hedefin başından bugüne kadar), tek geçişte.
  final perDay = <DateTime, int>{};
  for (final e in events) {
    final day = startOfDay(e.time);
    if (day.isBefore(start) || day.isAfter(today)) continue;
    perDay[day] = (perDay[day] ?? 0) + 1;
  }

  // "Şimdi": son 7 tamamlanmış gün (dün dahil, bugün hariç).
  final current = lastSevenDaysAverage(events, now);

  // İlerleme: başlangıçtan hedefe yolun ne kadarı yüründü.
  final span = goal.baseline - target;
  final progress = span <= 0
      ? (current <= target ? 1.0 : 0.0)
      : ((goal.baseline - current) / span).clamp(0.0, 1.0);

  // Hedefinde kaldığın günler: hedef konduktan sonra BİTEN günler.
  // (Sınırın olmadığı günler sayılmaz.)
  var onTarget = 0;
  for (var i = 0; i < sinceStart; i++) {
    final day = addDays(start, i);
    final limit = limitOn(goal, day);
    if (limit != null && (perDay[day] ?? 0) <= limit) onTarget++;
  }

  // Bırakma hedefi: bırakma gününe kaç gün var, o günden beri kaç biten
  // gün sigarasız geçti?
  int? daysToQuit;
  var smokeFree = 0;
  if (goal.isQuit) {
    final quitDay = quitDayOf(goal);
    daysToQuit = daysBetween(today, quitDay);
    for (var day = quitDay; day.isBefore(today); day = addDays(day, 1)) {
      if ((perDay[day] ?? 0) == 0) smokeFree++;
    }
  }

  // Şerit: hedefin başından itibaren 7'şer günlük dilimlerden bugününki.
  final window = addDays(start, 7 * (sinceStart ~/ 7));
  final days = [
    for (var i = 0; i < 7; i++)
      _goalDay(goal, addDays(window, i), today, perDay),
  ];

  return GoalStatus(
    goal: goal,
    target: target,
    end: end,
    steps: goalStepCount(start, end),
    week: goalWeekOf(goal, today),
    limit: limitOn(goal, today),
    ended: !goal.isQuit && !today.isBefore(end),
    daysSinceStart: sinceStart,
    currentLevel: current,
    progress: progress,
    daysOnTarget: onTarget,
    days: days,
    daysToQuit: daysToQuit,
    smokeFreeDays: smokeFree,
  );
}

GoalDay _goalDay(
  Goal goal,
  DateTime day,
  DateTime today,
  Map<DateTime, int> perDay,
) {
  final count = perDay[day] ?? 0;
  final limit = limitOn(goal, day);
  GoalDayState state;
  if (day.isAfter(today)) {
    state = GoalDayState.future;
  } else if (day == today) {
    state = GoalDayState.today;
  } else if (limit == null) {
    state = GoalDayState.noLimit;
  } else if (count <= limit) {
    state = GoalDayState.onTarget;
  } else {
    state = GoalDayState.over;
  }
  return GoalDay(day: day, count: count, limit: limit, state: state);
}
