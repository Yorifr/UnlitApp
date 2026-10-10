import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unlit/models/activity_log.dart';
import 'package:unlit/models/pack_price.dart';
import 'package:unlit/models/smoking_event.dart';
import 'package:unlit/models/user_profile.dart';
import 'package:unlit/services/storage_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('profil kaydedilip aynen geri okunur', () async {
    final storage = await StorageService.create();
    final profile = UserProfile(
      cigarettesPerDay: 18,
      firstCigarette: FirstCigaretteTime.within30Min,
      triggers: {SmokingTrigger.coffee, SmokingTrigger.stress},
      reasonNote: 'Merdivenleri rahat çıkmak istiyorum.',
    );
    await storage.saveProfile(profile);

    final loaded = storage.loadProfile();
    expect(loaded.toJson(), profile.toJson());
  });

  test('eski sürümün artık sorulmayan cevapları okunmaz', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.profile':
          '{"cigarettesPerDay": 12, "gender": "male", "ageRange": "from18to24",'
          ' "yearsSmoking": 4, "motivators": ["child"], "reasonNote": "  "}',
    });
    final storage = await StorageService.create();
    final loaded = storage.loadProfile();
    expect(loaded.cigarettesPerDay, 12);
    // Yeniden kaydedilince eski alanlar kayıttan da silinir.
    expect(loaded.toJson().keys, {
      'cigarettesPerDay',
      'firstCigarette',
      'triggers',
      'reasonNote',
    });
    // Sadece boşluktan oluşan not, not sayılmaz.
    expect(loaded.reasonNote, isNull);
  });

  test('fiyat geçmişi kaydedilip sıralı geri okunur', () async {
    final storage = await StorageService.create();
    await storage.savePrices(
      PriceHistory([
        PackPrice(since: DateTime(2026, 10, 8), price: 115),
        PackPrice(since: DateTime(2026, 10, 1), price: 105, perPack: 25),
      ]),
    );
    final loaded = storage.loadPrices();
    expect(loaded.entries.length, 2);
    expect(loaded.entries.first.perPack, 25);
    expect(loaded.current!.price, 115);
  });

  test('bozuk fiyat satırları atlanır', () {
    final prices = PriceHistory.fromJson([
      {'s': 1, 'p': 100},
      {'s': 2, 'p': -5}, // negatif fiyat → geçersiz
      'yanlış tip',
    ]);
    expect(prices.entries.length, 1);
    expect(prices.current!.perPack, 20); // adet yoksa 20
  });

  test('eski sürümün profildeki fiyatı okunabilir (taşıma için)', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.profile': '{"packPrice": 95.5, "cigarettesPerPack": 10}',
    });
    final storage = await StorageService.create();
    final legacy = storage.loadLegacyPackPrice();
    expect(legacy?.price, 95.5);
    expect(legacy?.perPack, 10);
  });

  test('tanınmayan değerler uygulamayı çökertmez', () {
    final profile = UserProfile.fromJson({
      'firstCigarette': 'boyle_bir_secenek_yok',
      'triggers': ['coffee', 'bilinmeyen'],
      'cigarettesPerDay': 'yanlış tip',
    });
    expect(profile.firstCigarette, isNull);
    expect(profile.triggers, {SmokingTrigger.coffee});
    expect(profile.cigarettesPerDay, isNull);
  });

  test('olaylar kaydedilip geri okunur', () async {
    final storage = await StorageService.create();
    final events = [
      SmokingEvent(time: DateTime(2026, 10, 10, 8), source: EventSource.demo),
      SmokingEvent(time: DateTime(2026, 10, 10, 9), source: EventSource.device),
    ];
    await storage.saveEvents(events);

    final loaded = storage.loadEvents();
    expect(loaded.length, 2);
    expect(loaded[0].time, events[0].time);
    expect(loaded[1].source, EventSource.device);
  });

  test('bozuk kayıt boş liste döndürür', () async {
    SharedPreferences.setMockInitialValues({'events': '{bozuk json'});
    final storage = await StorageService.create();
    expect(storage.loadEvents(), isEmpty);
  });

  test('clearAll her şeyi siler', () async {
    final storage = await StorageService.create();
    await storage.setOnboardingDone(true);
    await storage.saveProfile(UserProfile(cigarettesPerDay: 10));
    await storage.clearAll();
    expect(storage.onboardingDone, isFalse);
    expect(storage.loadProfile().cigarettesPerDay, isNull);
  });

  test('etkinlik günlüğü ve sigara nedeni saklanır', () async {
    final storage = await StorageService.create();
    final t = DateTime(2026, 10, 10, 9);
    await storage.saveEvents([
      SmokingEvent(
        time: t,
        source: EventSource.demo,
        trigger: SmokingTrigger.tea,
      ),
    ]);
    await storage.saveActivity(
      ActivityLog(
        moods: [MoodEntry(time: t, mood: Mood.okay)],
        delays: [
          DelayAttempt(
            start: t,
            end: t.add(const Duration(minutes: 10)),
            outcome: DelayOutcome.success,
          ),
        ],
        breaths: [t],
        xp: [XpEntry(time: t, amount: 15, reason: XpReason.delaySuccess)],
        activeDelayStart: t,
      ),
    );

    expect(storage.loadEvents().single.trigger, SmokingTrigger.tea);
    final a = storage.loadActivity();
    expect(a.moods.single.mood, Mood.okay);
    expect(a.delays.single.minutes, 10);
    expect(a.breaths.single, t);
    expect(a.totalXp, 15);
    expect(a.activeDelayStart, t);
  });

  test('bozuk etkinlik satırları atlanır', () {
    final a = ActivityLog.fromJson({
      'moods': [
        {'t': 1, 'm': 'yok_boyle'},
        {'t': 2, 'm': 'good'},
      ],
      'xp': 'yanlış tip',
    });
    expect(a.moods.length, 1);
    expect(a.xp, isEmpty);
  });
}
