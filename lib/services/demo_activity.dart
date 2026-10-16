// Demo modu: geçmiş günler için sahte "etkinlik" üretir.
//
// "Demo verisi üret" butonuna basınca sadece sigara kayıtları değil,
// gerçek bir kullanıcının yapacağı olumlu şeyler de oluşur: ruh hali
// kayıtları, sigara nedenleri, nefes molaları, ertelemeler ve bunların
// XP'leri. Böylece seri, XP ve görevler sunumda dolu görünür.
//
// Bugün bilerek boş bırakılır: bugünün görevlerini kullanıcı kendisi yapsın.
//
// "Bir günlük veri ekle" ([addDemoDay]) ise sanki bir gün geçmiş gibi
// davranır; ölçüm haftasını ve haftalık raporları gün gün izlemek için.

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

  final today = startOfDay(now);
  var dayIndex = 0;
  for (
    var day = startOfDay(trackingStart);
    day.isBefore(today);
    day = addDays(day, 1), dayIndex++
  ) {
    // 10. gün hiçbir şey yapılmamış olsun: "dinlenme günü" seriyi korur.
    if (dayIndex == 9) continue;
    addDemoDayActivity(
      day: day,
      trackingStart: trackingStart,
      events: tagged,
      activity: activity,
      random: random,
    );
  }
  return (events: tagged, activity: activity);
}

/// Demo kullanıcısının [day] günü yaptıkları: ruh hali, 1–3 sigaranın
/// nedeni, bazen nefes molası, ölçüm haftasından sonra erteleme ve bunların
/// puanları. [events] (nedenler) ve [activity] YERİNDE değiştirilir.
void addDemoDayActivity({
  required DateTime day,
  required DateTime trackingStart,
  required List<SmokingEvent> events,
  required ActivityLog activity,
  required Random random,
}) {
  DateTime at(int hour, int minute) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  // 1) Ruh hali: demo kullanıcısı her gün kendini dinler. (Böylece her gün
  //    en az bir görev tamamlanır ve seri tutarlı şekilde dolu olur.)
  activity.moods.add(
    MoodEntry(
      time: at(9 + random.nextInt(3), random.nextInt(60)),
      mood: _randomMood(random),
    ),
  );

  // 2) O günün 1–3 sigarasının nedenini işaretle
  final indexes = [
    for (var i = 0; i < events.length; i++)
      if (startOfDay(events[i].time) == day) i,
  ]..shuffle(random);
  for (final i in indexes.take(1 + random.nextInt(3))) {
    events[i] = events[i].withTrigger(_guessTrigger(events[i].time, random));
  }

  // 3) Nefes molası (bazı günler)
  if (random.nextDouble() < 0.6) {
    activity.breaths.add(at(14 + random.nextInt(6), random.nextInt(60)));
  }

  // 4) Erteleme (ölçüm haftasından sonra, çoğu gün)
  if (!isMeasurementDay(day, trackingStart) && random.nextDouble() < 0.8) {
    final start = at(11 + random.nextInt(8), random.nextInt(50));
    final success = random.nextDouble() < 0.75;
    // Başarılı ertelemede istek bazen 10 dakika dolmadan geçer (4–10 dk);
    // vazgeçilen ertelemede 3–8 dakika beklenir.
    final minutes = success
        ? 4 + random.nextInt(delayMinutes - 3)
        : 3 + random.nextInt(6);
    final end = start.add(Duration(minutes: minutes));
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
      now: at(22, 0),
      trackingStart: trackingStart,
      events: events,
      activity: activity,
    ),
  );
}

// ---------- "Bir günlük veri ekle" ----------

/// "Bir günlük veri ekle": sanki bir gün geçmiş gibi.
///
/// Gerçek saati ileri alamayız. Onun yerine her kaydı (sigaralar, ruh hali,
/// ertelemeler, puanlar, fiyatlar ve takibin başlangıcı) bir gün GERİYE
/// kaydırırız: bugün boşalır, takip bir gün "eskir". Sonra:
/// 1. Boşalan son 24 saate demo kılıfın yeni sigaraları eklenir.
/// 2. Dün (kaymadan önceki bugün) hiç görev yapılmadıysa, demo kullanıcısı
///    o günün görevlerini yapmış olur; seri ve haftalık rapor dolu görünür.
///
/// Geçmiş günler değişmez, sadece kayar. Böylece ölçüm haftası özeti ve
/// haftalık raporlar gün gün izlenebilir; görülen raporlar görülmüş kalır.
Future<void> addDemoDay(
  AppState state,
  DemoDeviceService demo, {
  Random? random,
}) async {
  final now = state.now;
  DateTime back(DateTime time) => addDays(time, -1);
  final start = back(state.trackingStartedAt ?? now);

  final events = [
    for (final e in state.events)
      SmokingEvent(time: back(e.time), source: e.source, trigger: e.trigger),
    ...await demo.generateLastDay(trackingStart: start),
  ]..sort((a, b) => a.time.compareTo(b.time));

  final old = state.activity;
  final activity = ActivityLog(
    moods: [
      for (final m in old.moods) MoodEntry(time: back(m.time), mood: m.mood),
    ],
    delays: [
      for (final d in old.delays)
        DelayAttempt(
          start: back(d.start),
          end: back(d.end),
          outcome: d.outcome,
        ),
    ],
    breaths: [for (final b in old.breaths) back(b)],
    xp: [
      for (final x in old.xp)
        XpEntry(time: back(x.time), amount: x.amount, reason: x.reason),
    ],
    // Süren bir erteleme "şu an"a ait; kaydırılmaz.
    activeDelayStart: old.activeDelayStart,
  );

  final yesterday = startOfDay(back(now));
  final anyQuestDone = questStatuses(
    day: yesterday,
    trackingStart: start,
    events: events,
    activity: activity,
  ).any((q) => q.done);
  if (!anyQuestDone) {
    addDemoDayActivity(
      day: yesterday,
      trackingStart: start,
      events: events,
      activity: activity,
      random: random ?? Random(),
    );
  }

  final prices = state.prices;
  final goal = state.goal;
  await state.replaceAll(
    events: events,
    activity: activity,
    trackingStartedAt: start,
    // Hedef de bir gün geriye kayar; yoksa haftaları bir gün kayardı.
    // (Bırakma günü de: "yarın" bırakacaksan bir gün sonra "bugün" olur.)
    goal: goal?.copyWith(
      start: back(goal.start),
      quitDay: goal.quitDay == null ? null : back(goal.quitDay!),
    ),
    prices: prices.isEmpty
        ? null
        : PriceHistory([
            for (final p in prices.entries)
              PackPrice(
                since: back(p.since),
                price: p.price,
                perPack: p.perPack,
              ),
          ]),
    newTracking: false,
  );
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
