// İstatistik ekranındaki temel hesaplamalar.
//
// Buradaki fonksiyonlar "saf" (pure) fonksiyonlardır: aynı girdiye her zaman
// aynı sonucu verirler, ekranla ya da kayıtla uğraşmazlar. Şu anki zamanı
// bile parametre olarak ([now]) alırlar. Bu sayede test etmeleri çok kolay
// (bkz. test/stats_test.dart).

import '../models/pack_price.dart';
import '../models/smoking_event.dart';

// ---------- Kaynaklı sabitler ----------

/// İçilmeyen bir sigaranın korunan ortalama yaşam süresi (dakika).
///
/// Kaynak: Jackson SE, Jarvis MJ, West R. "The price of a cigarette:
/// 20 minutes of life?" Addiction, 2024 (University College London).
/// doi:10.1111/add.16757
/// Bu yazıya göre bir sigara ortalama olarak erkeklerde ~17 dk, kadınlarda
/// ~22 dk yaşam süresine mal oluyor; genel ortalama ~20 dk. Cinsiyet
/// sormadığımız için herkes için genel ortalamayı kullanıyoruz. Bu kişiye
/// özel değil, ORTALAMA bir tahmindir; ekranda da böyle yazmalıyız.
///
/// Not: Bu sayıyı sadece "KAZANILAN" tarafta (içilmeyen sigaralar) gösteriyoruz;
/// "kaybedilen yaşam" diye sürekli büyüyen bir sayı göstermiyoruz (gerekçesi
/// docs/SPEC.md → Bölüm 3 ve 11).
///
/// 0.11.0'dan beri sadece SİGARASIZ GÜNLER için kullanılır (bkz.
/// measurement.dart → [Gains.lifeMinutes]). Neden? Sağlığa etkisi sigara
/// sayısıyla orantılı değil: günde 1 sigara bile kalp hastalığı riskinin
/// yaklaşık yarısını taşıyor (Hackshaw ve ark., BMJ 2018). "Azalttığın her
/// sigara 20 dk" demek abartılı olurdu.
const int lifeMinutesPerCigarette = 20;

// ---------- Tarih yardımcıları ----------

/// Verilen anın gece yarısı (00:00).
DateTime startOfDay(DateTime time) => DateTime(time.year, time.month, time.day);

/// [days] gün önceki/sonraki aynı saat. (Duration(days:) yerine takvim
/// günüyle hesaplıyoruz ki yaz saati uygulanan ülkelerde de doğru çalışsın.)
DateTime addDays(DateTime time, int days) => DateTime(
  time.year,
  time.month,
  time.day + days,
  time.hour,
  time.minute,
  time.second,
  time.millisecond,
);

/// [from] gününden [to] gününe kaç takvim günü var? (Aynı gün → 0.)
/// Saat farkını 24'e bölüp yuvarlıyoruz: yaz saati geçişinde bir gün 23 ya
/// da 25 saat sürse de doğru gün sayısı çıksın.
int daysBetween(DateTime from, DateTime to) =>
    (startOfDay(to).difference(startOfDay(from)).inHours / 24).round();

// ---------- Sayma ----------

/// [from] (dahil) ile [to] (hariç) arasındaki sigara sayısı.
int countBetween(List<SmokingEvent> events, DateTime from, DateTime to) {
  return events
      .where((e) => !e.time.isBefore(from) && e.time.isBefore(to))
      .length;
}

/// [now] anını da kapsayan bitiş zamanı. (countBetween/moneyBetween'de
/// bitiş hariç olduğu için, tam şu ana denk gelen kaydı da saymak için 1 sn
/// ekliyoruz.)
DateTime untilNow(DateTime now) => now.add(const Duration(seconds: 1));

/// Kayıtlar verilen andan önce başlamış mı?
/// Karşılaştırmanın anlamlı olması için gerekli: kullanıcı uygulamayı
/// 3 gün önce kurduysa "geçen hafta 0 sigara" demek yanlış olur.
bool hasDataSince(List<SmokingEvent> events, DateTime time) =>
    events.isNotEmpty && !events.first.time.isAfter(time);

/// Bugün (gece yarısından şu ana kadar) içilen sigara sayısı.
int countToday(List<SmokingEvent> events, DateTime now) =>
    countBetween(events, startOfDay(now), untilNow(now));

/// Son [days] günde (şu andan geriye days×24 saat) içilen sigara sayısı.
int countLastDays(List<SmokingEvent> events, DateTime now, int days) =>
    countBetween(events, addDays(now, -days), untilNow(now));

/// Geçen haftanın aynı gününde, aynı saate kadar içilen sigara sayısı.
/// Örn. bugün cumartesi 15:00 ise: geçen cumartesi 00:00–15:00.
/// (Yarım günü tam günle karşılaştırmak haksız olurdu.)
int countSameDayLastWeek(List<SmokingEvent> events, DateTime now) {
  final weekAgo = addDays(now, -7);
  return countBetween(events, startOfDay(weekAgo), weekAgo);
}

/// Son 7 gün ile ondan önceki 7 günün karşılaştırması.
class WeekComparison {
  const WeekComparison({required this.thisWeek, required this.lastWeek});

  /// Son 7 gün (şu andan geriye 7×24 saat).
  final int thisWeek;

  /// Ondan önceki 7 gün.
  final int lastWeek;

  /// Yüzde değişim. Negatifse azalma var demektir.
  /// Önceki haftanın verisi yoksa hesaplanamaz → null.
  double? get changePercent {
    if (lastWeek == 0) return null;
    return (thisWeek - lastWeek) / lastWeek * 100;
  }
}

WeekComparison compareWeeks(List<SmokingEvent> events, DateTime now) {
  final weekAgo = addDays(now, -7);
  final twoWeeksAgo = addDays(now, -14);
  return WeekComparison(
    thisWeek: countBetween(events, weekAgo, untilNow(now)),
    lastWeek: countBetween(events, twoWeeksAgo, weekAgo),
  );
}

/// Bir günün sigara sayısı (grafik için).
class DayCount {
  const DayCount(this.day, this.count);
  final DateTime day;
  final int count;
}

/// Bugün dahil son [days] günün günlük sayıları, eskiden yeniye.
List<DayCount> dailyCounts(
  List<SmokingEvent> events,
  DateTime now, {
  int days = 7,
}) {
  final today = startOfDay(now);
  return [
    for (var i = days - 1; i >= 0; i--)
      DayCount(
        addDays(today, -i),
        countBetween(events, addDays(today, -i), addDays(today, -i + 1)),
      ),
  ];
}

/// Verilen günün saat saat sigara sayısı (24 elemanlı liste).
List<int> hourlyCounts(List<SmokingEvent> events, DateTime day) {
  final counts = List<int>.filled(24, 0);
  final start = startOfDay(day);
  final end = addDays(start, 1);
  for (final e in events) {
    if (!e.time.isBefore(start) && e.time.isBefore(end)) {
      counts[e.time.hour]++;
    }
  }
  return counts;
}

/// Verilen günün ilk sigarası (yoksa null).
DateTime? firstEventOfDay(List<SmokingEvent> events, DateTime day) {
  final start = startOfDay(day);
  final end = addDays(start, 1);
  for (final e in events) {
    // Liste sıralı olduğu için ilk bulduğumuz en erken olandır.
    if (!e.time.isBefore(start) && e.time.isBefore(end)) return e.time;
  }
  return null;
}

// ---------- Para ve yaşam ----------

/// [from] (dahil) ile [to] (hariç) arasındaki sigaraların tutarı (₺).
///
/// Her sigara KENDİ TARİHİNDEKİ fiyatla hesaplanır: zam gelip fiyat
/// güncellenince eski günlerin harcaması değişmez. Hiç fiyat girilmemişse
/// null döner (ekranda "—" gösterilir, uydurma yok).
double? moneyBetween(
  List<SmokingEvent> events,
  DateTime from,
  DateTime to,
  PriceHistory prices,
) {
  if (prices.isEmpty) return null;
  var total = 0.0;
  for (final e in events) {
    if (e.time.isBefore(from) || !e.time.isBefore(to)) continue;
    total += prices.at(e.time)!.perCigarette;
  }
  return total;
}

/// [from]–[to] arasında birden fazla fiyat geçerli olmuş mu?
/// (Ekranda "her gün kendi fiyatıyla hesaplandı" demek için.)
bool priceChangedBetween(PriceHistory prices, DateTime from, DateTime to) {
  return prices.entries.length > 1 &&
      prices.entries
          .skip(1)
          .any((p) => p.since.isAfter(from) && p.since.isBefore(to));
}

/// İçilmeyen [count] sigaranın korunan tahmini yaşam süresi (dakika).
int lifeMinutesFor(int count) => count * lifeMinutesPerCigarette;

// ---------- "Şimdi" ----------

/// Son 7 TAMAMLANMIŞ günde (dün dahil, bugün hariç) günde ortalama sigara.
///
/// Uygulamadaki her "Şimdi" bu sayıdır (Hedefim, "Başladığından beri"); iki
/// ekran farklı sayı göstermesin diye tek yerden hesaplanır. Bugün sayılmaz:
/// sayı gün içinde, sigaradan hemen sonra değişmesin.
double lastSevenDaysAverage(List<SmokingEvent> events, DateTime now) {
  final today = startOfDay(now);
  return countBetween(events, addDays(today, -7), today) / 7;
}
