// Kullanıcının uygulamada yaptığı olumlu şeylerin kaydı:
// ruh hali kayıtları, ertelemeler, nefes egzersizleri ve kazanılan XP.
// (Ekranda XP'ye "puan" diyoruz; kodda kısa olsun diye adı XP.)
//
// ÖNEMLİ KURAL: Burada sigara içmekle ilgili hiçbir "ceza" yok. XP sadece
// artar, asla azalmaz.

import 'package:flutter/material.dart' show IconData, Icons;

/// "Kendini dinle" görevinde seçilen ruh hali.
///
/// SIRA ÖNEMLİ: Ekranda soldan sağa bu sırayla dizilir. Ölçeklerde alışılmış
/// olan "sola doğru olumsuz, sağa doğru olumlu" düzeni: en solda "Çok zor",
/// en sağda "Harika". (Kayıtta adıyla saklandığı için sırayı değiştirmek eski
/// kayıtları bozmaz.)
enum Mood {
  veryHard('Çok zor', Icons.sentiment_very_dissatisfied),
  hard('Zor', Icons.sentiment_dissatisfied),
  okay('İdare eder', Icons.sentiment_neutral),
  good('İyi', Icons.sentiment_satisfied),
  great('Harika', Icons.sentiment_very_satisfied);

  const Mood(this.label, this.icon);
  final String label;
  final IconData icon;

  /// Zor bir gün mü? (Maskot o gün daha sakin ve destekleyici konuşur.)
  bool get isHard => this == Mood.hard || this == Mood.veryHard;
}

class MoodEntry {
  const MoodEntry({required this.time, required this.mood});
  final DateTime time;
  final Mood mood;

  Map<String, dynamic> toJson() => {
    't': time.millisecondsSinceEpoch,
    'm': mood.name,
  };

  static MoodEntry? fromJson(Map<String, dynamic> json) {
    final mood = Mood.values.asNameMap()[json['m']];
    final t = json['t'];
    if (mood == null || t is! int) return null; // bozuk kayıt: atla
    return MoodEntry(time: DateTime.fromMillisecondsSinceEpoch(t), mood: mood);
  }
}

/// Bir ertelemenin sonucu.
enum DelayOutcome {
  /// İstek geçti, sigara içilmedi.
  success,

  /// Kullanıcı yine de içmeye karar verdi. (Bu bir "başarısızlık" değil;
  /// isteği fark edip beklemek de bir adım. Bu yüzden küçük bir XP var.)
  gaveIn,
}

/// Bir sigara isteğini erteleme denemesi.
class DelayAttempt {
  const DelayAttempt({
    required this.start,
    required this.end,
    required this.outcome,
  });

  final DateTime start;
  final DateTime end;
  final DelayOutcome outcome;

  /// Kaç dakika beklendi?
  int get minutes => end.difference(start).inMinutes;

  Map<String, dynamic> toJson() => {
    's': start.millisecondsSinceEpoch,
    'e': end.millisecondsSinceEpoch,
    'o': outcome.name,
  };

  static DelayAttempt? fromJson(Map<String, dynamic> json) {
    final outcome = DelayOutcome.values.asNameMap()[json['o']];
    final s = json['s'], e = json['e'];
    if (outcome == null || s is! int || e is! int) return null;
    return DelayAttempt(
      start: DateTime.fromMillisecondsSinceEpoch(s),
      end: DateTime.fromMillisecondsSinceEpoch(e),
      outcome: outcome,
    );
  }
}

/// XP'nin neden kazanıldığı.
enum XpReason {
  welcome('Yolculuğa başladın'),
  questCheckIn('Görev: Kendini dinle'),
  questTag('Görev: Nedenini keşfet'),
  questBreathe('Görev: Nefes molası'),
  questDelay('Görev: İsteği ertele'),
  allQuests('Günün tüm görevleri'),
  delaySuccess('İsteği erteledin'),
  delayTry('Ertelemeyi denedin');

  const XpReason(this.label);
  final String label;
}

/// Kazanılan bir XP (puan). Her kazanç ayrı bir satır olarak saklanır.
class XpEntry {
  const XpEntry({
    required this.time,
    required this.amount,
    required this.reason,
  });

  final DateTime time;
  final int amount;
  final XpReason reason;

  Map<String, dynamic> toJson() => {
    't': time.millisecondsSinceEpoch,
    'a': amount,
    'r': reason.name,
  };

  static XpEntry? fromJson(Map<String, dynamic> json) {
    final reason = XpReason.values.asNameMap()[json['r']];
    final t = json['t'], a = json['a'];
    if (reason == null || t is! int || a is! int) return null;
    return XpEntry(
      time: DateTime.fromMillisecondsSinceEpoch(t),
      amount: a,
      reason: reason,
    );
  }
}

/// Tüm etkinlik kayıtları bir arada. Tek bir JSON olarak saklanır.
class ActivityLog {
  ActivityLog({
    List<MoodEntry>? moods,
    List<DelayAttempt>? delays,
    List<DateTime>? breaths,
    List<XpEntry>? xp,
    this.activeDelayStart,
  }) : moods = moods ?? [],
       delays = delays ?? [],
       breaths = breaths ?? [],
       xp = xp ?? [];

  final List<MoodEntry> moods;
  final List<DelayAttempt> delays;

  /// Tamamlanan nefes egzersizlerinin zamanları.
  final List<DateTime> breaths;
  final List<XpEntry> xp;

  /// Şu an süren bir erteleme varsa başlangıç zamanı (yoksa null).
  /// Saklıyoruz ki uygulama kapanıp açılınca sayaç kaldığı yerden devam etsin.
  DateTime? activeDelayStart;

  /// Toplam XP.
  int get totalXp => xp.fold(0, (sum, entry) => sum + entry.amount);

  Map<String, dynamic> toJson() => {
    'moods': moods.map((m) => m.toJson()).toList(),
    'delays': delays.map((d) => d.toJson()).toList(),
    'breaths': breaths.map((b) => b.millisecondsSinceEpoch).toList(),
    'xp': xp.map((x) => x.toJson()).toList(),
    'activeDelayStart': activeDelayStart?.millisecondsSinceEpoch,
  };

  /// JSON'dan okur; bozuk satırları atlar, uygulama çökmez.
  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    List<T> parse<T>(Object? list, T? Function(Map<String, dynamic>) f) {
      if (list is! List) return [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(f)
          .whereType<T>()
          .toList();
    }

    final breaths = json['breaths'];
    final active = json['activeDelayStart'];
    return ActivityLog(
      moods: parse(json['moods'], MoodEntry.fromJson),
      delays: parse(json['delays'], DelayAttempt.fromJson),
      breaths: breaths is List
          ? breaths
                .whereType<int>()
                .map(DateTime.fromMillisecondsSinceEpoch)
                .toList()
          : [],
      xp: parse(json['xp'], XpEntry.fromJson),
      activeDelayStart: active is int
          ? DateTime.fromMillisecondsSinceEpoch(active)
          : null,
    );
  }
}
