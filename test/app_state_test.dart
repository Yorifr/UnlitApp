import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unlit/app_state.dart';
import 'package:unlit/logic/rewards.dart';
import 'package:unlit/models/activity_log.dart';
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

  test('check-in görevi bir kez ödüllendirilir', () async {
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
}
