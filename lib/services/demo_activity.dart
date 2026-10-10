// Demo modu: geçmiş günler için sahte "etkinlik" üretir.
//
// "Demo verisi üret" butonuna basınca sadece sigara kayıtları değil,
// gerçek bir kullanıcının yapacağı olumlu şeyler de oluşur: ruh hali
// check-in'leri, sigara nedenleri, nefes molaları, ertelemeler ve bunların
// XP'leri. Böylece seri, XP ve görevler sunumda dolu görünür.
//
// Bugün bilerek boş bırakılır: bugünün görevlerini kullanıcı kendisi yapsın.

import 'dart:math';

import '../app_state.dart';
import '../logic/quests.dart';
import '../logic/rewards.dart';
import '../logic/stats.dart';
import '../models/activity_log.dart';
import '../models/pack_price.dart';
import '../models/smoking_event.dart';
import '../models/user_profile.dart';
import 'demo_device_service.dart';

/// Demo kılıftan son iki haftalık veri üretir ve uygulamaya yükler.
Future<void> loadDemoHistory(AppState state, DemoDeviceService demo) async {
  final events = await demo.generateHistory();
  final now = state.now;
  final start = events.isEmpty ? now : startOfDay(events.first.time);
  final result = buildDemoActivity(
    events: events,
    trackingStart: start,
    now: now,
    random: Random(),
  );
  await state.replaceAll(
    events: result.events,
    activity: result.activity,
    trackingStartedAt: start,
    // Hiç fiyat girilmemişse örnek bir fiyat geçmişi ekle (5 gün önce "zam"
    // gelmiş gibi). Kullanıcının girdiği fiyata ASLA dokunma.
    prices: state.prices.isEmpty ? demoPrices(start: start, now: now) : null,
  );
}

/// Demo için örnek fiyat geçmişi: başta 105 ₺, 5 gün önce 115 ₺'ye "zam".
/// (Sahte veridir; sadece fiyat geçmişi özelliğini göstermek için.)
PriceHistory demoPrices({required DateTime start, required DateTime now}) {
  return PriceHistory([
    PackPrice(since: start, price: 105),
    PackPrice(since: addDays(startOfDay(now), -5), price: 115),
  ]);
}

/// Geçmiş her gün için gerçekçi etkinlik üretir (bugün hariç).
({List<SmokingEvent> events, ActivityLog activity}) buildDemoActivity({
  required List<SmokingEvent> events,
  required DateTime trackingStart,
  required DateTime now,
  required Random random,
}) {
  final tagged = [...events];
  final activity = ActivityLog(
    xp: [
      XpEntry(time: trackingStart, amount: xpWelcome, reason: XpReason.welcome),
    ],
  );
  DateTime at(DateTime day, int hour, int minute) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  final today = startOfDay(now);
  var dayIndex = 0;
  for (
    var day = startOfDay(trackingStart);
    day.isBefore(today);
    day = addDays(day, 1), dayIndex++
  ) {
    // 10. gün hiçbir şey yapılmamış olsun: "dinlenme günü" seriyi korur.
    if (dayIndex == 9) continue;

    // 1) Ruh hali: demo kullanıcısı her gün check-in yapar. (Böylece her
    //    gün en az bir görev tamamlanır ve seri tutarlı şekilde dolu olur.)
    activity.moods.add(
      MoodEntry(
        time: at(day, 9 + random.nextInt(3), random.nextInt(60)),
        mood: _randomMood(random),
      ),
    );

    // 2) O günün 1–3 sigarasının nedenini işaretle
    final indexes = [
      for (var i = 0; i < tagged.length; i++)
        if (startOfDay(tagged[i].time) == day) i,
    ]..shuffle(random);
    for (final i in indexes.take(1 + random.nextInt(3))) {
      tagged[i] = tagged[i].withTrigger(_guessTrigger(tagged[i].time, random));
    }

    // 3) Nefes molası (bazı günler)
    if (random.nextDouble() < 0.6) {
      activity.breaths.add(at(day, 14 + random.nextInt(6), random.nextInt(60)));
    }

    // 4) Erteleme (ölçüm haftasından sonra, çoğu gün)
    if (!isMeasurementDay(day, trackingStart) && random.nextDouble() < 0.8) {
      final start = at(day, 11 + random.nextInt(8), random.nextInt(50));
      final success = random.nextDouble() < 0.75;
      final end = start.add(
        Duration(minutes: success ? delayMinutes : 3 + random.nextInt(6)),
      );
      activity.delays.add(
        DelayAttempt(
          start: start,
          end: end,
          outcome: success ? DelayOutcome.success : DelayOutcome.gaveIn,
        ),
      );
      activity.xp.add(
        XpEntry(
          time: end,
          amount: success ? xpDelaySuccess : xpDelayTry,
          reason: success ? XpReason.delaySuccess : XpReason.delayTry,
        ),
      );
    }

    // 5) O gün tamamlanan görevlerin XP'si (uygulamadaki kuralla aynı)
    activity.xp.addAll(
      pendingQuestRewards(
        now: at(day, 22, 0),
        trackingStart: trackingStart,
        events: tagged,
        activity: activity,
      ),
    );
  }
  return (events: tagged, activity: activity);
}

Mood _randomMood(Random random) {
  final r = random.nextDouble();
  if (r < 0.15) return Mood.great;
  if (r < 0.50) return Mood.good;
  if (r < 0.80) return Mood.okay;
  if (r < 0.95) return Mood.hard;
  return Mood.veryHard;
}

/// Saate göre olası bir neden tahmin eder (sabah kahve, öğlen yemek...).
SmokingTrigger _guessTrigger(DateTime time, Random random) {
  if (random.nextDouble() < 0.15) return SmokingTrigger.stress;
  final weekend =
      time.weekday == DateTime.saturday || time.weekday == DateTime.sunday;
  final options = switch (time.hour) {
    < 10 => [SmokingTrigger.coffee, SmokingTrigger.tea],
    < 12 => [SmokingTrigger.tea, SmokingTrigger.breakTime],
    < 15 => [SmokingTrigger.meal],
    < 18 => [
      SmokingTrigger.tea,
      SmokingTrigger.coffee,
      SmokingTrigger.breakTime,
    ],
    < 21 => [SmokingTrigger.meal, SmokingTrigger.phone],
    _ when weekend => [SmokingTrigger.friends, SmokingTrigger.alcohol],
    _ => [SmokingTrigger.boredom, SmokingTrigger.phone],
  };
  return options[random.nextInt(options.length)];
}
