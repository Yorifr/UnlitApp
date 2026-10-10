import 'dart:math';

import '../models/user_profile.dart';

/// İki sigara arasındaki en kısa süre (dakika).
const int demoMinGapMinutes = 20;

/// Sahte ama gerçekçi bir günün sigara saatlerini planlar.
///
/// Gerçek bir sigara içicinin tipik gününe benzetmeye çalışıyoruz:
/// 1. Günde 10–25 sigara. Profilde günlük sayı varsa ona yakın bir sayı.
/// 2. İlk sigara uyandıktan kısa süre sonra (Fagerström cevabına göre).
/// 3. Kahve/çay ve yemeklerden sonra sigaralar sıklaşır.
/// 4. Hafta sonu daha geç uyanılır; cuma ve hafta sonu akşamları
///    (arkadaşlarla) biraz daha fazla içilir.
/// 5. İki sigara arasında en az 20 dakika vardır, uykuda sigara yoktur.
///
/// [random] dışarıdan verilir: aynı tohumla (seed) oluşturulan Random
/// her seferinde aynı günü üretir. Bu sayede testler tekrarlanabilir olur.
List<DateTime> planDemoDay(
  DateTime day,
  Random random, {
  int? usualPerDay,
  FirstCigaretteTime? firstCigarette,
}) {
  final weekend =
      day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
  final friday = day.weekday == DateTime.friday;

  // Saatleri "gece yarısından beri geçen dakika" olarak hesaplıyoruz.
  // Örnek: 7 * 60 + 30 = 450 → 07:30

  // -max ile +max arasında rastgele bir sayı (saatleri biraz oynatmak için).
  int jitter(int max) => random.nextInt(2 * max + 1) - max;

  // 1) Bugün kaç sigara?
  final base = (usualPerDay ?? 16).clamp(10, 25);
  final count = (base + jitter(3) + (weekend ? 2 : 0)).clamp(10, 25);

  // 2) Uyanma ve uyuma saati
  final wake = (weekend ? 9 * 60 : 7 * 60) + jitter(30);
  final sleep = (weekend ? 23 * 60 + 30 : 23 * 60) + jitter(25);

  // 3) İlk sigara: uyandıktan ne kadar sonra?
  final firstDelay = switch (firstCigarette) {
    FirstCigaretteTime.within5Min => 1 + random.nextInt(5), // 1–5 dk
    FirstCigaretteTime.within30Min => 6 + random.nextInt(25), // 6–30 dk
    FirstCigaretteTime.within60Min => 31 + random.nextInt(30), // 31–60 dk
    FirstCigaretteTime.after60Min => 61 + random.nextInt(60), // 61–120 dk
    null => 5 + random.nextInt(26), // bilinmiyorsa 5–30 dk
  };
  final first = wake + firstDelay;

  // 4) Sigaranın sıklaştığı anlar (kahve/çay ve yemekler)
  final peaks = <int>[
    wake + 30 + jitter(10), // kahvaltı ve sabah kahvesi/çayı
    10 * 60 + 30 + jitter(20), // öğleden önce çay molası
    13 * 60 + jitter(20), // öğle yemeği
    16 * 60 + jitter(30), // ikindi çayı / kahve
    20 * 60 + jitter(30), // akşam yemeği
    if (weekend || friday) 22 * 60 + jitter(30), // arkadaşlarla akşam
  ];

  // 5) Günün her dakikasına bir "ağırlık" veriyoruz: ağırlık ne kadar
  //    büyükse o dakikada sigara içilme ihtimali o kadar yüksek.
  //    Temel ağırlık 1; yoğun anlardan ~10 dk sonra bir tepe oluşur.
  final start = first + demoMinGapMinutes;
  final end = sleep;
  double weightAt(int minute) {
    var weight = 1.0;
    for (final peak in peaks) {
      final distance = minute - (peak + 10);
      weight += 5 * exp(-(distance * distance) / (2 * 15 * 15));
    }
    return weight;
  }

  // Ağırlıkları üst üste toplayarak "kümülatif" bir liste yapıyoruz.
  // Rastgele bir sayı seçip bu listede nereye düştüğüne bakınca,
  // ağırlığı büyük dakikalar daha sık seçilmiş olur.
  final cumulative = <double>[];
  var total = 0.0;
  for (var m = start; m <= end; m++) {
    total += weightAt(m);
    cumulative.add(total);
  }
  int pickMinute() {
    final r = random.nextDouble() * total;
    var i = 0;
    while (cumulative[i] < r) {
      i++;
    }
    return start + i;
  }

  // 6) Kalan sigaraları seç; öncekilere çok yakın olanları reddet.
  final minutes = <int>[first];
  var attempts = 0;
  while (minutes.length < count && attempts < 5000) {
    attempts++;
    final candidate = pickMinute();
    final farEnough = minutes.every(
      (m) => (m - candidate).abs() >= demoMinGapMinutes,
    );
    if (farEnough) minutes.add(candidate);
  }
  minutes.sort();

  // Dakikaları gerçek tarih-saate çevir (saniyeyi de rastgele ekle).
  return [
    for (final m in minutes)
      DateTime(day.year, day.month, day.day, 0, m, random.nextInt(60)),
  ];
}
