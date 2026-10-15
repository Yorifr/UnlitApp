// Ölçüm haftası: özet ve "Kazandıkların".
//
// İlk 7 gün (ölçüm haftası) kullanıcının başlangıç alışkanlığını ölçeriz.
// Hafta bitince:
// 1. Kısa bir ÖZET gösterilir: günde ortalama, ilk sigara saati, en yoğun
//    saat, en sık işaretlenen neden.
// 2. Bu ortalama "başlangıç noktası" olur. Sonraki günlerde İÇİLMEYEN
//    sigaralar ve cepte kalan para buna göre hesaplanır ("Kazandıkların").
//    Korunan yaşam süresi ise sadece SİGARASIZ günler için hesaplanır
//    (0.11.0; gerekçe [Gains.lifeMinutes]).
//
// Aynı özet ve kazanç hesapları haftalık raporda da kullanılır (bkz.
// weekly_report.dart); bu yüzden herhangi bir gün aralığı için yazıldılar.
//
// Her sayı kullanıcının KENDİ verisinden gelir (uydurma yok). Yaşam süresi
// için tek kaynaklı sabit stats.dart'taki [lifeMinutesPerCigarette].

import '../models/pack_price.dart';
import '../models/smoking_event.dart';
import '../models/user_profile.dart';
import 'quests.dart';
import 'stats.dart';

/// Ölçüm haftasının ilk günü (00:00).
DateTime measurementStart(DateTime trackingStart) => startOfDay(trackingStart);

/// Ölçüm haftasının bittiği an: 8. günün gece yarısı.
DateTime measurementEnd(DateTime trackingStart) =>
    addDays(startOfDay(trackingStart), measurementDays);

/// Ölçüm haftası bitti mi? (Takip başlamadıysa bitmemiş sayılır.)
bool measurementOver(DateTime now, DateTime? trackingStart) =>
    trackingStart != null && !isMeasurementDay(now, trackingStart);

/// Gece bu saatten önce içilen sigaralar "günün ilk sigarası" sayılmaz;
/// bir önceki gecenin devamıdır (ör. 00:40'ta yatmadan önce içilen).
const int dayStartsAtHour = 4;

/// Birkaç günün (ör. bir haftanın) özeti: toplam, en yoğun saat, en sık
/// neden, günün ilk sigarasının ortalama saati.
class PeriodSummary {
  const PeriodSummary({
    required this.days,
    required this.total,
    required this.peakHour,
    required this.topTrigger,
    required this.topTriggerCount,
    required this.averageFirstMinute,
  });

  /// Özetlenen gün sayısı (bir hafta için 7).
  final int days;

  /// Bu günlerde toplam sigara.
  final int total;

  /// En çok sigara içilen saat (ör. 10 → 10:00–11:00). Kayıt yoksa null.
  final int? peakHour;

  /// En sık işaretlenen neden. Hiç neden işaretlenmediyse null.
  final SmokingTrigger? topTrigger;

  /// [topTrigger] kaç kez işaretlendi?
  final int topTriggerCount;

  /// Günün ilk sigarasının ortalama saati, gece yarısından beri dakika
  /// (ör. 465 → 07:45). Kayıt yoksa null.
  final int? averageFirstMinute;

  /// Günde ortalama sigara. (Ölçüm haftası için bu "başlangıç noktası".)
  double get dailyAverage => days == 0 ? 0 : total / days;
}

/// [from] (00:00, dahil) ile [to] (00:00, hariç) arasındaki günlerin özeti.
/// [events] eskiden yeniye sıralı olmalı.
PeriodSummary summarizePeriod(
  List<SmokingEvent> events,
  DateTime from,
  DateTime to,
) {
  final start = startOfDay(from);
  final end = startOfDay(to);
  final period = [
    for (final e in events)
      if (!e.time.isBefore(start) && e.time.isBefore(end)) e,
  ];

  // 1) En yoğun saat: her saate düşen sigaraları say, en büyüğünü bul.
  //    (Eşitlikte daha erken saat seçilir.)
  final perHour = List<int>.filled(24, 0);
  for (final e in period) {
    perHour[e.time.hour]++;
  }
  int? peakHour;
  for (var h = 0; h < 24; h++) {
    if (perHour[h] > 0 &&
        (peakHour == null || perHour[h] > perHour[peakHour])) {
      peakHour = h;
    }
  }

  // 2) En sık neden.
  final perTrigger = <SmokingTrigger, int>{};
  for (final e in period) {
    final trigger = e.trigger;
    if (trigger != null) perTrigger[trigger] = (perTrigger[trigger] ?? 0) + 1;
  }
  SmokingTrigger? topTrigger;
  var topCount = 0;
  for (final trigger in SmokingTrigger.values) {
    final count = perTrigger[trigger] ?? 0;
    if (count > topCount) {
      topTrigger = trigger;
      topCount = count;
    }
  }

  // 3) Günün ilk sigarasının ortalama saati. Her gün için 04:00'ten sonraki
  //    ilk sigarayı bul, sonra bu saatlerin ortalamasını al.
  final firstMinutes = <int>[];
  for (var day = start; day.isBefore(end); day = addDays(day, 1)) {
    final dayStart = day.add(const Duration(hours: dayStartsAtHour));
    final nextDay = addDays(day, 1);
    for (final e in period) {
      // Liste sıralı: koşula uyan ilk olay o günün ilk sigarasıdır.
      if (!e.time.isBefore(dayStart) && e.time.isBefore(nextDay)) {
        firstMinutes.add(e.time.hour * 60 + e.time.minute);
        break;
      }
    }
  }
  final averageFirst = firstMinutes.isEmpty
      ? null
      : (firstMinutes.reduce((a, b) => a + b) / firstMinutes.length).round();

  return PeriodSummary(
    days: daysBetween(start, end),
    total: period.length,
    peakHour: peakHour,
    topTrigger: topTrigger,
    topTriggerCount: topCount,
    averageFirstMinute: averageFirst,
  );
}

/// Ölçüm haftasının özeti. [events] eskiden yeniye sıralı olmalı.
PeriodSummary summarizeMeasurementWeek(
  List<SmokingEvent> events,
  DateTime trackingStart,
) => summarizePeriod(
  events,
  measurementStart(trackingStart),
  measurementEnd(trackingStart),
);

/// "Kazandıkların": ölçüm haftasındaki ortalamaya göre içilmeyen sigaralar.
class Gains {
  const Gains({
    required this.baseline,
    required this.days,
    required this.notSmoked,
    required this.money,
    this.smokeFreeDays = 0,
  });

  /// Başlangıç noktası: ölçüm haftasında günde ortalama sigara.
  final double baseline;

  /// Hesaba katılan TAMAMLANMIŞ gün sayısı (ölçüm haftasından sonra, dün
  /// dahil). 0 ise henüz hesaplanacak gün yok.
  final int days;

  /// İçilmeyen sigara sayısı (NET; en az 0).
  final int notSmoked;

  /// Cepte kalan para (₺, en az 0). Paket fiyatı hiç girilmediyse null.
  final double? money;

  /// Hiç sigara içilmeyen (tamamlanmış) gün sayısı.
  final int smokeFreeDays;

  /// Korunan tahmini yaşam süresi (dakika, ortalama tahmin): SADECE
  /// sigarasız günler için. Her sigarasız gün, başlangıç noktası kadar
  /// sigara × ~20 dk sayılır.
  ///
  /// Neden azaltılan günler sayılmıyor? UCL'nin "sigara başına ~20 dk"
  /// tahmini bırakmak için yapılmış bir ortalama. Azaltmanın etkisi sigara
  /// sayısıyla orantılı değil: günde 1 sigara bile kalp hastalığı riskinin
  /// yaklaşık yarısını taşıyor (Hackshaw ve ark., BMJ 2018); azaltmanın
  /// sağlık kazancı belirsiz (Pisinger ve Godtfredsen, 2007). Azaltılan
  /// günlerde içilmeyen sigaralar ve para yine [notSmoked] ve [money]'de.
  int get lifeMinutes => lifeMinutesFor((baseline * smokeFreeDays).round());
}

/// Ölçüm haftasından sonraki tamamlanmış günlerin kazancı.
///
/// Neden NET hesap? Her günü ayrı ayrı "ortalamanın altında kaldıysa
/// ekle, üstündeyse sıfır say" diye toplasaydık, hiç azaltmayan birinin
/// günlük dalgalanması bile (bir gün 15, bir gün 19) sahte bir kazanç
/// gösterirdi. Bu yüzden ortalamanın üstündeki günler, altındaki günleri
/// dengeler. Toplam sıfırın altına inmez (eksi sayı göstermeyiz; fazla içilen
/// günler zaten "Harcanan para"da görünüyor).
///
/// BUGÜN hesaba katılmaz: gün bitmeden "bugün 15 sigara içmedin" demek
/// yanlış olurdu. Böylece sayı gün içinde, sigaradan hemen sonra değişmez;
/// sadece gece yarısı güncellenir.
///
/// null döner: ölçüm haftası bitmediyse ya da ölçüm haftasında hiç kayıt
/// yoksa (karşılaştıracak bir başlangıç noktası yok).
Gains? computeGains({
  required List<SmokingEvent> events,
  required DateTime? trackingStart,
  required DateTime now,
  required PriceHistory prices,
}) {
  if (trackingStart == null || !measurementOver(now, trackingStart)) {
    return null;
  }
  final baseline = summarizeMeasurementWeek(events, trackingStart).dailyAverage;
  if (baseline == 0) return null;
  return gainsBetween(
    events: events,
    baseline: baseline,
    from: measurementEnd(trackingStart),
    to: startOfDay(now),
    prices: prices,
  );
}

/// [from] (00:00, dahil) ile [to] (00:00, hariç) arasındaki günlerin NET
/// kazancı, [baseline]'a (günde ortalama) göre. Hesap kuralları için bkz.
/// [computeGains]. Haftalık rapor da bunu tek bir hafta için kullanır.
Gains gainsBetween({
  required List<SmokingEvent> events,
  required double baseline,
  required DateTime from,
  required DateTime to,
  required PriceHistory prices,
}) {
  final start = startOfDay(from);
  final end = startOfDay(to);

  // Önce aralıktaki sigaraları güne göre say (tek geçiş; bir yıllık kayıtta
  // bile hızlı kalsın).
  final perDay = <DateTime, int>{};
  for (final e in events) {
    if (e.time.isBefore(start) || !e.time.isBefore(end)) continue;
    final day = startOfDay(e.time);
    perDay[day] = (perDay[day] ?? 0) + 1;
  }

  var net = 0.0; // içilmeyen sigara (kesirli: ortalama 17,3 olabilir)
  var money = 0.0;
  var days = 0;
  var smokeFree = 0;
  for (var day = start; day.isBefore(end); day = addDays(day, 1)) {
    final count = perDay[day] ?? 0;
    if (count == 0) smokeFree++;
    final difference = baseline - count;
    net += difference;
    // Para, o GÜNÜN fiyatıyla hesaplanır: zam gelince geçmişte biriken
    // para değişmesin.
    final price = prices.at(day);
    if (price != null) money += difference * price.perCigarette;
    days++;
  }

  final notSmoked = net > 0 ? net.round() : 0;
  return Gains(
    baseline: baseline,
    days: days,
    notSmoked: notSmoked,
    money: prices.isEmpty
        ? null
        // İçilmeyen sigara yoksa para da yok (yuvarlama farkı kalmasın).
        : (notSmoked == 0 || money < 0 ? 0 : money),
    smokeFreeDays: smokeFree,
  );
}
