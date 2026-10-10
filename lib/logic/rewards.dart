// XP (puan) ödülleri ve seri (streak) hesabı.
//
// TEMEL KURALLAR (bkz. docs/SPEC.md → "Oyunlaştırma ilkeleri"):
// - XP sadece artar, asla düşmez. Sigara içmek XP götürmez.
// - Seri, "sigarasız gün" değil, "en az bir görev yaptığın gün" sayar.
//   Böylece bir sigara seriyi bozmaz ("zaten bozdum, boş ver" duygusu yok).
// - Haftada 1 gün kaçırırsan seri korunur ("dinlenme günü").

import 'dart:math';

import '../models/activity_log.dart';
import '../models/smoking_event.dart';
import 'quests.dart';
import 'stats.dart';

// ---------- XP miktarları (hepsi tek yerde, kolayca değiştirilebilir) ----------

const int xpWelcome = 10; // Onboarding'i bitirmek / atlamak
const int xpPerQuest = 10; // Her günlük görev
const int xpAllQuestsBonus = 20; // Günün 3 görevi de bitince bonus
const int xpDelaySuccess = 15; // Başarılı her erteleme
const int xpDelayTry = 5; // Erteleme denemesi (yine de içildiyse)
const int maxDelayRewardsPerDay = 5; // Günde en fazla kaç erteleme ödüllenir

/// Bir eylemden sonra kazanılanlar (kutlama ekranında gösterilir).
class Reward {
  const Reward({
    required this.gains,
    required this.streak,
    required this.streakExtended,
  });

  /// Boş ödül (hiçbir şey kazanılmadı).
  static const none = Reward(gains: [], streak: 0, streakExtended: false);

  final List<XpEntry> gains;

  /// Eylemden sonraki seri (gün).
  final int streak;

  /// Bu eylem bugünün ilk kazancı mıydı? (Öyleyse seri bir gün uzadı.)
  final bool streakExtended;

  int get totalXp => gains.fold(0, (sum, g) => sum + g.amount);
  bool get isEmpty => gains.isEmpty;

  bool has(XpReason reason) => gains.any((g) => g.reason == reason);
}

bool _sameDay(DateTime a, DateTime b) => startOfDay(a) == startOfDay(b);

/// Bugün tamamlanmış ama ödülü HENÜZ verilmemiş görevlerin XP'leri.
/// Aynı görev aynı gün iki kez ödüllendirilmez.
List<XpEntry> pendingQuestRewards({
  required DateTime now,
  required DateTime? trackingStart,
  required List<SmokingEvent> events,
  required ActivityLog activity,
}) {
  final alreadyRewarded = activity.xp
      .where((x) => _sameDay(x.time, now))
      .map((x) => x.reason)
      .toSet();
  final statuses = questStatuses(
    day: now,
    trackingStart: trackingStart,
    events: events,
    activity: activity,
  );

  final gains = <XpEntry>[
    for (final s in statuses)
      if (s.done && !alreadyRewarded.contains(s.type.reason))
        XpEntry(time: now, amount: xpPerQuest, reason: s.type.reason),
  ];
  final allDone = statuses.every((s) => s.done);
  if (allDone && !alreadyRewarded.contains(XpReason.allQuests)) {
    gains.add(
      XpEntry(time: now, amount: xpAllQuestsBonus, reason: XpReason.allQuests),
    );
  }
  return gains;
}

/// Bugün erteleme için daha XP verilebilir mi? (Günlük üst sınır)
bool canRewardDelay(ActivityLog activity, DateTime now) {
  final count = activity.xp
      .where(
        (x) =>
            _sameDay(x.time, now) &&
            (x.reason == XpReason.delaySuccess ||
                x.reason == XpReason.delayTry),
      )
      .length;
  return count < maxDelayRewardsPerDay;
}

/// Bugün kazanılan XP.
int xpOnDay(ActivityLog activity, DateTime day) => activity.xp
    .where((x) => _sameDay(x.time, day))
    .fold(0, (sum, x) => sum + x.amount);

// ---------- Seri ----------

/// Seri bilgisi.
class StreakInfo {
  const StreakInfo({
    required this.current,
    required this.best,
    required this.activeToday,
  });

  /// Şu anki seri (gün).
  final int current;

  /// Şimdiye kadarki en uzun seri.
  final int best;

  /// Bugün en az bir şey kazanıldı mı? (Değilse seri yaprağı gri görünür;
  /// ama seri BOZULMAZ, gün bitene kadar vakit var.)
  final bool activeToday;
}

/// XP kazanılan günlerden seriyi hesaplar.
///
/// Gün gün ilerleriz:
/// - XP kazanılan gün → seri +1
/// - Kazanılmayan gün → son 7 günde dinlenme günü kullanılmadıysa seri
///   korunur (dinlenme günü); kullanıldıysa seri sıfırlanır.
/// - Bugün henüz bir şey yapılmadıysa seri bozulmuş sayılmaz.
StreakInfo computeStreak(List<XpEntry> xp, DateTime now) {
  final activeDays = xp.map((x) => startOfDay(x.time)).toSet();
  final today = startOfDay(now);
  if (activeDays.isEmpty) {
    return const StreakInfo(current: 0, best: 0, activeToday: false);
  }

  final first = activeDays.reduce((a, b) => a.isBefore(b) ? a : b);
  var streak = 0;
  var best = 0;
  DateTime? lastRestDay;

  for (var day = first; !day.isAfter(today); day = addDays(day, 1)) {
    if (activeDays.contains(day)) {
      streak++;
      best = max(best, streak);
    } else if (day == today) {
      // Bugün henüz bitmedi: seriyi bozma.
    } else if (streak > 0 &&
        (lastRestDay == null || !day.isBefore(addDays(lastRestDay, 7)))) {
      lastRestDay = day; // Dinlenme günü: seri korunur ama artmaz.
    } else {
      streak = 0;
    }
  }

  return StreakInfo(
    current: streak,
    best: best,
    activeToday: activeDays.contains(today),
  );
}
