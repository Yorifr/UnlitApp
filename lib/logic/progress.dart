// "Başladığından beri": tek bakışta ne durumdayım?
//
// İstatistik sekmesinin en üstündeki kart bunu gösterir:
// - Başlangıç = ölçüm haftasında günde ortalama sigara.
// - Şimdi     = son 7 tamamlanmış günde günde ortalama (Hedefim'deki
//               "Şimdi" ile AYNI sayı; bkz. stats.dart → lastSevenDaysAverage).
// - Fark      = Şimdi, başlangıca göre yüzde kaç değişti.
// - Hafta hafta: takibin her BİTEN haftasında günde ortalama (küçük grafik).
//
// Bu yüzde, pilot çalışmanın da ana sonuç sayısıdır ("başlangıca göre günlük
// sigara sayısındaki değişim"); kullanıcı ile araştırma aynı sayıya bakar.
//
// Kurallar (CLAUDE.md): her sayı kullanıcının kendi verisi. Artış kırmızı
// değil nötr gösterilir ve mesaj tetiklemez.

import '../models/smoking_event.dart';
import 'measurement.dart';
import 'stats.dart';
import 'weekly_report.dart';

/// Kartın gösterdiği bilgiler.
class StartProgress {
  const StartProgress({
    required this.baseline,
    required this.current,
    required this.weeks,
  });

  /// Başlangıç noktası: ölçüm haftasında günde ortalama sigara (> 0).
  final double baseline;

  /// Şimdi: son 7 tamamlanmış günde günde ortalama sigara.
  final double current;

  /// Biten her haftanın günlük ortalaması, 1. haftadan (ölçüm haftası)
  /// başlayarak. En az 2 hafta vardır.
  final List<WeekAverage> weeks;

  /// Başlangıca göre değişim (yüzde). Eksi = azalma.
  /// Örnek: başlangıç 15, şimdi 11 → yaklaşık -27.
  double get changePercent => (current - baseline) / baseline * 100;
}

/// Bir haftanın günlük ortalaması.
class WeekAverage {
  const WeekAverage({required this.week, required this.average});

  /// Kaçıncı hafta (1 = ölçüm haftası).
  final int week;

  /// O hafta günde ortalama sigara.
  final double average;
}

/// Grafikte en fazla kaç hafta gösterilsin? (1. hafta hep gösterilir; pilot
/// uzarsa grafik kalabalıklaşmasın diye sonra en yeni 7 hafta gelir.)
const int maxChartWeeks = 8;

/// "Başladığından beri" bilgisi. Henüz anlamlı değilse null:
/// - ölçüm haftası bitmediyse ya da ölçüm haftasında hiç kayıt yoksa
///   (karşılaştıracak bir başlangıç yok),
/// - ölçüm haftasından sonra henüz 7 gün TAMAMLANMADIYSA ("Şimdi" ölçüm
///   haftasının kendisi olurdu; %0 göstermek yanıltıcı).
///
/// [events] eskiden yeniye sıralı olmalı.
StartProgress? progressSinceStart({
  required List<SmokingEvent> events,
  required DateTime? trackingStart,
  required DateTime now,
}) {
  if (trackingStart == null || !measurementOver(now, trackingStart)) {
    return null;
  }
  final baseline = summarizeMeasurementWeek(events, trackingStart).dailyAverage;
  if (baseline == 0) return null;

  // Ölçüm haftasından sonra en az 7 gün bitmiş olmalı.
  final readyFrom = addDays(measurementEnd(trackingStart), daysPerWeek);
  if (startOfDay(now).isBefore(readyFrom)) return null;

  // Biten haftaların ortalamaları: 1. hafta + en yeni haftalar.
  final completed = completedWeeks(now, trackingStart);
  final firstShown = completed - (maxChartWeeks - 2);
  final weeks = [
    for (var w = 1; w <= completed; w++)
      if (w == 1 || w >= firstShown)
        WeekAverage(
          week: w,
          average:
              countBetween(
                events,
                weekStart(trackingStart, w),
                weekStart(trackingStart, w + 1),
              ) /
              daysPerWeek,
        ),
  ];

  return StartProgress(
    baseline: baseline,
    current: lastSevenDaysAverage(events, now),
    weeks: weeks,
  );
}
