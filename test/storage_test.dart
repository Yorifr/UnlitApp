import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unlit/models/activity_log.dart';
import 'package:unlit/models/smoking_event.dart';
import 'package:unlit/models/user_profile.dart';
import 'package:unlit/services/storage_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('profil kaydedilip aynen geri okunur', () async {
    final storage = await StorageService.create();
    final profile = UserProfile(
      cigarettesPerDay: 18,
      yearsSmoking: 0,
      firstCigarette: FirstCigaretteTime.within30Min,
      packPrice: 95.5,
      triggers: {SmokingTrigger.coffee, SmokingTrigger.stress},
      goal: QuitGoal.reduce,
      quitDesire: 7,
      gender: Gender.unspecified,
      motivators: {Motivator.child},
      activities: {Activity.running, Activity.football},
    );
    await storage.saveProfile(profile);

    final loaded = storage.loadProfile();
    expect(loaded.toJson(), profile.toJson());
    expect(loaded.pricePerCigarette, closeTo(95.5 / 20, 0.0001));
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
    expect(profile.cigarettesPerPack, 20);
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
