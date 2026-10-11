import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unlit/app_state.dart';
import 'package:unlit/logic/rewards.dart';
import 'package:unlit/models/activity_log.dart';
import 'package:unlit/models/goal.dart';
import 'package:unlit/models/mascot_look.dart';
import 'package:unlit/models/smoking_event.dart';
import 'package:unlit/models/user_profile.dart';
import 'package:unlit/services/device_service.dart';
import 'package:unlit/services/storage_service.dart';

/// Testler için sahte kılıf: olayları elle göndeririz, zamanlayıcı yok.
/// (DeviceService arayüzü sayesinde AppState farkı anlamaz.)
class FakeDevice implements DeviceService {
  final _events = StreamController<SmokingEvent>.broadcast();
  final _status = ValueNotifier(DeviceStatus.disconnected);

  void emit(DateTime time) =>
      _events.add(SmokingEvent(time: time, source: EventSource.device));

  @override
  String get name => 'Sahte kılıf';
  @override
  ValueListenable<DeviceStatus> get status => _status;
  @override
  Stream<SmokingEvent> get events => _events.stream;
  @override
  Future<void> connect() async => _status.value = DeviceStatus.connected;
  @override
  Future<void> disconnect() async => _status.value = DeviceStatus.disconnected;
  @override
  void dispose() => _events.close();
}

void main() {
  late DateTime now;
  late FakeDevice device;
  late AppState state;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 10, 10, 10);
    device = FakeDevice();
    state = AppState(
      storage: await StorageService.create(),
      device: device,
      clock: () => now,
    );
    await state.start();
  });

  test('onboarding hoş geldin XP\'si verir ve seriyi başlatır', () async {
    final reward = await state.completeOnboarding(UserProfile());
    expect(reward.totalXp, xpWelcome);
    expect(reward.streakExtended, isTrue);
    expect(state.streak.current, 1);
    expect(state.trackingStartedAt, now);
    expect(state.measurementDay, 1);

    // İkinci kez (ör. veri silmeden tekrar) hoş geldin XP'si verilmez.
    final again = await state.completeOnboarding(UserProfile());
    expect(again.isEmpty, isTrue);
  });

  test('"Kendini dinle" görevi bir kez ödüllendirilir', () async {
    await state.completeOnboarding(UserProfile());
    final first = await state.logMood(Mood.good);
    expect(first.has(XpReason.questCheckIn), isTrue);
    expect(first.streakExtended, isFalse); // hoş geldin ile zaten aktifti

    final second = await state.logMood(Mood.great);
    expect(second.isEmpty, isTrue);
    expect(state.todayMood, Mood.great);
  });

  test('sigara içmek XP götürmez, seriyi bozmaz', () async {
    await state.completeOnboarding(UserProfile());
    final xpBefore = state.totalXp;
    device.emit(now);
    await Future<void>.delayed(Duration.zero);
    expect(state.events.length, 1);
    expect(state.totalXp, xpBefore);
    expect(state.streak.current, 1);
  });

  test('neden işaretlemek görevi tamamlar ve kaydedilir', () async {
    await state.completeOnboarding(UserProfile());
    device.emit(now);
    await Future<void>.delayed(Duration.zero);
    final reward = await state.tagEvent(
      state.events.first,
      SmokingTrigger.coffee,
    );
    expect(reward.has(XpReason.questTag), isTrue);
    expect(state.events.first.trigger, SmokingTrigger.coffee);
  });

  test('erteleme: başarı da deneme de ödüllü', () async {
    await state.completeOnboarding(UserProfile());
    // Ölçüm haftası bitsin ki erteleme görevi de olsun.
    now = DateTime(2026, 10, 20, 10);

    await state.startDelay();
    expect(state.activeDelayStart, now);
    now = now.add(const Duration(minutes: 10));
    final success = await state.finishDelay(DelayOutcome.success);
    expect(success.has(XpReason.delaySuccess), isTrue);
    expect(success.has(XpReason.questDelay), isTrue);
    expect(state.activeDelayStart, isNull);
    expect(state.successfulDelays, 1);

    await state.startDelay();
    now = now.add(const Duration(minutes: 3));
    final tried = await state.finishDelay(DelayOutcome.gaveIn);
    expect(tried.totalXp, xpDelayTry);
  });

  test('tüm veriler silinince her şey sıfırlanır', () async {
    await state.completeOnboarding(UserProfile(cigarettesPerDay: 10));
    await state.logMood(Mood.good);
    await state.deleteAllData();
    expect(state.onboardingDone, isFalse);
    expect(state.totalXp, 0);
    expect(state.profile.cigarettesPerDay, isNull);
    expect(state.trackingStartedAt, isNull);
  });

  test('etkinlikler kalıcı olarak saklanır', () async {
    await state.completeOnboarding(UserProfile());
    await state.logMood(Mood.hard);
    await state.logBreathing();

    final reloaded = AppState(
      storage: await StorageService.create(),
      device: FakeDevice(),
      clock: () => now,
    );
    await reloaded.start();
    expect(reloaded.todayMood, Mood.hard);
    expect(reloaded.activity.breaths.length, 1);
    expect(reloaded.totalXp, state.totalXp);
  });

  group('ölçüm haftası özeti', () {
    test('hafta bitince bir kez çıkar, görülünce kaybolur', () async {
      await state.completeOnboarding(UserProfile());
      device.emit(DateTime(2026, 10, 10, 11));
      await Future<void>.delayed(Duration.zero);
      expect(state.measurementSummaryPending, isFalse); // hafta sürüyor
      expect(state.gains, isNull);

      now = DateTime(2026, 10, 17, 9); // 8. gün
      expect(state.measurementDay, isNull);
      expect(state.measurementSummaryPending, isTrue);
      expect(state.measurementSummary!.total, 1);
      expect(state.gains, isNotNull);

      await state.markMeasurementSummarySeen();
      expect(state.measurementSummaryPending, isFalse);

      // Uygulama yeniden açılınca da görülmüş sayılır.
      final reloaded = AppState(
        storage: await StorageService.create(),
        device: FakeDevice(),
        clock: () => now,
      );
      await reloaded.start();
      expect(reloaded.measurementSummaryPending, isFalse);

      // Takip sıfırlanınca yeni ölçüm haftasının özeti yeniden çıkar.
      await state.resetEventsAndProgress();
      device.emit(now);
      await Future<void>.delayed(Duration.zero);
      now = DateTime(2026, 10, 25, 9);
      expect(state.measurementSummaryPending, isTrue);
    });

    test('ölçüm haftasında hiç kayıt yoksa özet çıkmaz', () async {
      await state.completeOnboarding(UserProfile());
      now = DateTime(2026, 10, 20, 9);
      expect(state.measurementSummaryPending, isFalse);
      expect(state.gains, isNull);
    });
  });

  test('kendine not kaydedilir, boş not silinir', () async {
    await state.completeOnboarding(UserProfile());
    await state.setReasonNote('  Kızımla koşabilmek için  ');
    expect(state.profile.reasonNote, 'Kızımla koşabilmek için');
    await state.setReasonNote('   ');
    expect(state.profile.reasonNote, isNull);
  });

  test(
    'açılışta eski, artık kullanılmayan cevaplar kayıttan silinir',
    () async {
      SharedPreferences.setMockInitialValues({
        'flutter.onboarding_done': true,
        'flutter.profile':
            '{"cigarettesPerDay": 12, "gender": "female", "quitDesire": 7}',
      });
      final storage = await StorageService.create();
      final old = AppState(
        storage: storage,
        device: FakeDevice(),
        clock: () => now,
      );
      await old.start();
      expect(old.profile.cigarettesPerDay, 12);
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('profile')!;
      expect(saved.contains('gender'), isFalse);
      expect(saved.contains('quitDesire'), isFalse);
    },
  );

  group('Nefes\'in dolabı', () {
    /// Takibi başlatır ve dünkü tarihe [xp] puan yazar (eşiklere hızlı
    /// yaklaşmak için).
    Future<void> startWithXp(int xp) async {
      await state.completeOnboarding(UserProfile());
      await state.replaceAll(
        events: [],
        activity: ActivityLog(
          xp: [
            XpEntry(
              time: now.subtract(const Duration(days: 1)),
              amount: xp,
              reason: XpReason.welcome,
            ),
          ],
        ),
        trackingStartedAt: now,
      );
    }

    test('100 puanı geçince gözlük açılır, kutlanır ve takılır', () async {
      await startWithXp(95);
      expect(state.unlockedAccessories, isEmpty);
      final reward = await state.logMood(Mood.good); // +10 görev
      expect(reward.newAccessories, [Accessory.gozluk]);
      expect(state.mascotLook.wears(Accessory.gozluk), isTrue);
      // Aynı eşya bir daha "yeni" diye kutlanmaz.
      final again = await state.logBreathing();
      expect(again.newAccessories, isEmpty);
    });

    test('300 puanda filiz büyür; puan düşmediği için hiç küçülmez', () async {
      await startWithXp(290);
      expect(state.sproutStage, 1);
      final reward = await state.logMood(Mood.okay);
      expect(reward.grownToStage, 2);
      expect(state.sproutStage, 2);
      // Sigara içmek hiçbir şeyi değiştirmez.
      device.emit(now);
      await Future<void>.delayed(Duration.zero);
      expect(state.sproutStage, 2);
      expect(state.unlockedAccessories, contains(Accessory.gozluk));
    });

    test('takılan eşya kaydedilir; kilitli eşya takılamaz', () async {
      await startWithXp(600);
      await state.toggleOutfit(Accessory.kulaklik);
      await state.toggleOutfit(Accessory.bere); // 1000 puan: kilitli
      expect(state.mascotLook.accessories, {Accessory.kulaklik});

      final reloaded = AppState(
        storage: await StorageService.create(),
        device: FakeDevice(),
        clock: () => now,
      );
      await reloaded.start();
      expect(reloaded.mascotLook.accessories, {Accessory.kulaklik});
    });

    test(
      'ölçüm haftası özeti görülünce kep takılır (sadece ilk sefer)',
      () async {
        await state.completeOnboarding(UserProfile());
        now = DateTime(2026, 10, 18, 9); // ölçüm haftası bitti
        expect(state.unlockedAccessories, contains(Accessory.kep));
        await state.markMeasurementSummarySeen();
        expect(state.mascotLook.wears(Accessory.kep), isTrue);

        // Kullanıcı kepi çıkarır; özeti tekrar açması kepi geri takmaz.
        await state.toggleOutfit(Accessory.kep);
        await state.markMeasurementSummarySeen();
        expect(state.mascotLook.wears(Accessory.kep), isFalse);
      },
    );

    test('taç bir gün önce takılmış olsa da özette kep takılır', () async {
      await state.completeOnboarding(UserProfile());
      for (var day = 11; day <= 16; day++) {
        now = DateTime(2026, 10, day, 9);
        device.emit(now); // ölçüm haftasında kayıt var: özet çıkacak
        await Future<void>.delayed(Duration.zero);
        await state.logMood(Mood.good);
      }
      expect(state.mascotLook.wears(Accessory.tac), isTrue); // 7 günlük seri
      now = DateTime(2026, 10, 17, 9);
      expect(state.measurementSummaryPending, isTrue);
      await state.markMeasurementSummarySeen();
      expect(state.mascotLook.wears(Accessory.kep), isTrue);
      expect(state.mascotLook.wears(Accessory.tac), isFalse);
      expect(state.unlockedAccessories, contains(Accessory.tac)); // kaybolmaz
    });

    test(
      'ölçüm haftasında hiç kayıt yoksa kep ilk kutlamada haber verilir',
      () async {
        await state.completeOnboarding(UserProfile());
        now = DateTime(2026, 10, 18, 9);
        expect(
          state.measurementSummaryPending,
          isFalse,
        ); // özetlenecek kayıt yok
        final reward = await state.logMood(Mood.good);
        expect(reward.newAccessories, contains(Accessory.kep));
        expect(state.mascotLook.wears(Accessory.kep), isTrue);
        // Bir kez: sonraki eylemde tekrar haber yok.
        final again = await state.logBreathing();
        expect(again.newAccessories, isEmpty);
      },
    );

    test('eski sürümden gelen kullanıcıda açılmış eşyalar bir kez takılır', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.onboarding_done': true,
        'flutter.tracking_started_at': now.millisecondsSinceEpoch,
        'flutter.activity':
            '{"xp": [{"t": ${now.millisecondsSinceEpoch}, "a": 300, "r": "welcome"}]}',
      });
      final old = AppState(
        storage: await StorageService.create(),
        device: FakeDevice(),
        clock: () => now,
      );
      await old.start();
      expect(old.mascotLook.accessories, {Accessory.gozluk, Accessory.atki});
    });

    test('kayıtlar sıfırlanınca dolap ve filiz de baştan başlar', () async {
      await startWithXp(1200);
      await state.toggleOutfit(Accessory.bere);
      expect(state.sproutStage, 3);
      await state.resetEventsAndProgress();
      expect(state.mascotLook, MascotLook.plain);
      expect(state.storage.loadOutfit(), isEmpty); // bayat kayıt kalmasın
    });

    test('tüm veriler silinince dolap da boşalır', () async {
      await startWithXp(600);
      await state.toggleOutfit(Accessory.atki);
      await state.deleteAllData();
      expect(state.mascotLook, MascotLook.plain);
    });
  });

  group('paket fiyatı', () {
    test(
      'zam: yeni fiyat bugünden geçerli, eski günler eski fiyatla',
      () async {
        await state.setPackPrice(price: 100);
        now = DateTime(2026, 10, 15, 9);
        await state.setPackPrice(price: 120);

        expect(state.prices.entries.length, 2);
        expect(state.prices.at(DateTime(2026, 10, 12))!.price, 100);
        expect(state.prices.at(DateTime(2026, 10, 15, 8))!.price, 120);
        expect(state.prices.current!.since, DateTime(2026, 10, 15));
      },
    );

    test('aynı gün tekrar değişirse bugünkü kayıt düzeltilir', () async {
      await state.setPackPrice(price: 100);
      await state.setPackPrice(price: 110, perPack: 25);
      expect(state.prices.entries.length, 1);
      expect(state.prices.current!.price, 110);
      expect(state.prices.current!.perPack, 25);
    });

    test('"yanlış girmiştim": tüm geçmiş yeni fiyatla hesaplanır', () async {
      await state.setPackPrice(price: 1000); // yazım hatası
      now = DateTime(2026, 10, 20, 9);
      await state.setPackPrice(price: 100, correctPast: true);
      expect(state.prices.entries.length, 1);
      expect(state.prices.at(DateTime(2026, 10, 10))!.price, 100);
    });

    test(
      'fiyat uzun süre aynıysa nazikçe sorulur; "aynı" deyince susar',
      () async {
        await state.setPackPrice(price: 100);
        expect(state.shouldAskPriceStillSame, isFalse);

        now = now.add(AppState.priceCheckAfter);
        expect(state.shouldAskPriceStillSame, isTrue);

        await state.confirmPriceStillSame();
        expect(state.shouldAskPriceStillSame, isFalse);
        expect(state.prices.entries.length, 1); // fiyat değişmedi
      },
    );

    test('eski sürümdeki profil fiyatı tarihli geçmişe taşınır', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.profile': '{"cigarettesPerDay": 12, "packPrice": 95.5, "cigarettesPerPack": 20}',
        'flutter.onboarding_done': true,
        'flutter.tracking_started_at': DateTime(
          2026,
          9,
          1,
          8,
        ).millisecondsSinceEpoch,
      });
      final storage = await StorageService.create();
      final migrated = AppState(
        storage: storage,
        device: FakeDevice(),
        clock: () => now,
      );
      await migrated.start();

      expect(migrated.prices.entries.length, 1);
      expect(migrated.prices.current!.price, 95.5);
      expect(migrated.prices.current!.since, DateTime(2026, 9, 1));
      expect(migrated.profile.cigarettesPerDay, 12); // diğer cevaplar kaldı
      // Taşıma bir kez yapılır: eski alan profilden silindi.
      expect(storage.loadLegacyPackPrice(), isNull);
    });

    test('tüm veriler silinince fiyat da silinir', () async {
      await state.setPackPrice(price: 100);
      await state.deleteAllData();
      expect(state.prices.isEmpty, isTrue);
    });
  });

  group('haftalık rapor', () {
    /// [from] gününden [days] gün boyunca her gün 10 sigara ve bir görev.
    Future<void> fill(DateTime from, int days) async {
      final events = <SmokingEvent>[];
      final activity = ActivityLog();
      for (var i = 0; i < days; i++) {
        final day = DateTime(from.year, from.month, from.day + i);
        for (var h = 0; h < 10; h++) {
          events.add(
            SmokingEvent(
              time: DateTime(day.year, day.month, day.day, 8 + h),
              source: EventSource.demo,
            ),
          );
        }
        activity.xp.add(
          XpEntry(
            time: DateTime(day.year, day.month, day.day, 9),
            amount: 10,
            reason: XpReason.questCheckIn,
          ),
        );
      }
      await state.replaceAll(
        events: events,
        activity: activity,
        trackingStartedAt: from,
      );
    }

    test(
      'önce ölçüm özeti; sonra sadece en son biten hafta, bir kez',
      () async {
        await state.completeOnboarding(UserProfile());
        // 19 Eylül'den 9 Ekim'e 3 tam hafta; bugün (10 Ekim) 22. gün.
        await fill(DateTime(2026, 9, 19), 21);
        expect(state.trackingDay, 22);
        expect(state.completedWeeks, 3);

        // Ölçüm haftası özeti beklerken haftalık rapor duyurulmaz.
        expect(state.measurementSummaryPending, isTrue);
        expect(state.pendingWeeklyReport, isNull);
        await state.markMeasurementSummarySeen();

        // Üç rapor üst üste gelmez: sadece en son biten hafta (3.).
        expect(state.pendingWeeklyReport, 3);
        expect(state.weeklyReport(2), isNotNull); // eskisi İstatistik'te
        await state.markWeeklyReportSeen(3);
        expect(state.pendingWeeklyReport, isNull);

        // Bir hafta sonra 4. haftanın raporu (o hafta görev yapılmıştı).
        await fill(DateTime(2026, 9, 19), 28);
        await state.markMeasurementSummarySeen();
        now = DateTime(2026, 10, 17, 10);
        expect(state.completedWeeks, 4);
        expect(state.pendingWeeklyReport, 4);
      },
    );

    test('hiçbir şey olmayan hafta duyurulmaz', () async {
      await state.completeOnboarding(UserProfile());
      await fill(DateTime(2026, 9, 26), 7); // sadece ölçüm haftası dolu
      await state.markMeasurementSummarySeen();
      expect(state.completedWeeks, 2);
      expect(state.weeklyReport(2)!.isEmpty, isTrue);
      expect(state.pendingWeeklyReport, isNull);
    });

    test(
      'takip baştan başlarsa raporlar yeniden çıkar; sürerse çıkmaz',
      () async {
        await state.completeOnboarding(UserProfile());
        await fill(DateTime(2026, 9, 26), 14);
        await state.markMeasurementSummarySeen();
        await state.markWeeklyReportSeen(2);

        // "Bir gün ilerlet" gibi: aynı takip sürüyor, görülenler görülmüş.
        await state.replaceAll(
          events: state.events,
          activity: state.activity,
          trackingStartedAt: state.trackingStartedAt!,
          newTracking: false,
        );
        expect(state.measurementSummaryPending, isFalse);
        expect(state.pendingWeeklyReport, isNull);

        // Yeni takip (demo verisi üret / sıfırla): hepsi yeniden çıkar.
        await fill(DateTime(2026, 9, 26), 14);
        expect(state.measurementSummaryPending, isTrue);
        await state.markMeasurementSummarySeen();
        expect(state.pendingWeeklyReport, 2);
      },
    );
  });

  group('azaltma hedefi', () {
    /// Ölçüm haftası (10–16 Ekim): her gün [perDay] sigara.
    Future<void> measure(int perDay) async {
      await state.completeOnboarding(UserProfile());
      await state.replaceAll(
        events: [
          for (var d = 0; d < 7; d++)
            for (var h = 0; h < perDay; h++)
              SmokingEvent(
                time: DateTime(2026, 10, 10 + d, 8 + h),
                source: EventSource.demo,
              ),
        ],
        activity: state.activity,
        trackingStartedAt: DateTime(2026, 10, 10, 9),
      );
    }

    test('ölçüm haftası bitmeden ve özet görülmeden seçilemez', () async {
      await measure(10);
      expect(state.baseline, isNull);
      expect(state.canSetGoal, isFalse);
      final reward = await state.setGoal(
        percent: 50,
        amount: 4,
        unit: GoalUnit.week,
      );
      expect(reward.isEmpty, isTrue);
      expect(state.goal, isNull);

      now = DateTime(2026, 10, 17, 9); // 8. gün
      expect(state.baseline, 10);
      expect(state.canSetGoal, isFalse); // önce özet
      await state.markMeasurementSummarySeen();
      expect(state.canSetGoal, isTrue);
    });

    test('ilk hedef bir kez puan kazandırır; hedef kaydedilir', () async {
      await measure(10);
      now = DateTime(2026, 10, 17, 9);
      await state.markMeasurementSummarySeen();

      final first = await state.setGoal(
        percent: 50,
        amount: 4,
        unit: GoalUnit.week,
      );
      expect(first.has(XpReason.goalSet), isTrue);
      expect(first.totalXp, xpGoalSet);
      expect(state.goal!.start, DateTime(2026, 10, 17));
      expect(state.goal!.from, 10); // son 7 gün = ölçüm haftası
      expect(state.goalStatus!.target, 5);
      expect(state.goalStatus!.limit, 9); // 5 + 5 × 3/4 → 9

      // Değiştirmek puan kazandırmaz (değiştirip durarak puan toplanmasın).
      final change = await state.setGoal(
        percent: 75,
        amount: 2,
        unit: GoalUnit.month,
      );
      expect(change.has(XpReason.goalSet), isFalse);

      final reloaded = AppState(
        storage: await StorageService.create(),
        device: FakeDevice(),
        clock: () => now,
      );
      await reloaded.start();
      expect(reloaded.goal!.percent, 75);
      expect(reloaded.goal!.unit, GoalUnit.month);
    });

    test(
      'takip sıfırlanınca ya da her şey silinince hedef de silinir',
      () async {
        await measure(10);
        now = DateTime(2026, 10, 17, 9);
        await state.markMeasurementSummarySeen();
        await state.setGoal(percent: 50, amount: 4, unit: GoalUnit.week);

        await state.resetEventsAndProgress();
        expect(state.goal, isNull);

        await measure(10);
        await state.markMeasurementSummarySeen();
        await state.setGoal(percent: 25, amount: 2, unit: GoalUnit.week);
        expect(state.goal, isNotNull);
        await state.deleteAllData();
        expect(state.goal, isNull);
      },
    );
  });
}
