import 'dart:async';

import 'package:flutter/foundation.dart';

import 'logic/quests.dart';
import 'logic/rewards.dart';
import 'logic/stats.dart';
import 'models/activity_log.dart';
import 'models/smoking_event.dart';
import 'models/user_profile.dart';
import 'services/device_service.dart';
import 'services/storage_service.dart';

/// Uygulamanın "beyni": profil, sigara kayıtları ve etkinlikler burada durur.
///
/// - Kılıftan ([DeviceService]) gelen olayları dinler ve kaydeder.
/// - Kullanıcının olumlu eylemlerini (check-in, erteleme...) kaydeder ve
///   kazandığı XP'yi hesaplar. Bu metotlar bir [Reward] döndürür; ekran da
///   buna bakıp kutlama gösterir.
/// - Her değişiklikte [notifyListeners] çağırır; ekranlar
///   `ListenableBuilder` ile dinleyip kendini yeniler.
/// - Kalıcı kayıt için [StorageService] kullanır (sadece bu cihaz).
class AppState extends ChangeNotifier {
  AppState({
    required this.storage,
    required this.device,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final StorageService storage;
  final DeviceService device;

  /// Şu anki zaman (testlerde sahte saat verilebilir).
  final DateTime Function() _clock;
  DateTime get now => _clock();

  UserProfile _profile = UserProfile();
  bool _onboardingDone = false;
  List<SmokingEvent> _events = [];
  ActivityLog _activity = ActivityLog();
  DateTime? _trackingStartedAt;
  StreamSubscription<SmokingEvent>? _subscription;

  UserProfile get profile => _profile;
  bool get onboardingDone => _onboardingDone;

  /// Tüm sigara kayıtları, eskiden yeniye sıralı. (Sadece okunabilir.)
  List<SmokingEvent> get events => List.unmodifiable(_events);

  /// Etkinlik kayıtları (ruh hali, erteleme, nefes, XP).
  /// Değiştirmek için AppState'in metotlarını kullan, doğrudan değiştirme.
  ActivityLog get activity => _activity;

  /// Takibin başladığı an (ölçüm haftası buradan sayılır).
  DateTime? get trackingStartedAt => _trackingStartedAt;

  // ---------- Hesaplanan bilgiler (ekranlar için kısayollar) ----------

  StreakInfo get streak => computeStreak(_activity.xp, now);
  int get totalXp => _activity.totalXp;
  int get todayXp => xpOnDay(_activity, now);

  List<QuestStatus> get todayQuests => questStatuses(
    day: now,
    trackingStart: _trackingStartedAt,
    events: _events,
    activity: _activity,
  );

  /// Ölçüm haftasının kaçıncı günü (bittiyse null).
  int? get measurementDay => measurementDayNumber(now, _trackingStartedAt);

  /// Bugün seçilen son ruh hali (yoksa null).
  Mood? get todayMood {
    final today = _activity.moods.where(
      (m) => startOfDay(m.time) == startOfDay(now),
    );
    return today.isEmpty ? null : today.last.mood;
  }

  /// Başarılı ertelemelerin toplam sayısı.
  int get successfulDelays =>
      _activity.delays.where((d) => d.outcome == DelayOutcome.success).length;

  // ---------- Başlangıç ----------

  /// Uygulama açılırken bir kez çağrılır.
  Future<void> start() async {
    _profile = storage.loadProfile();
    _onboardingDone = storage.onboardingDone;
    _events = storage.loadEvents()..sort(_byTime);
    _activity = storage.loadActivity();
    _trackingStartedAt = storage.trackingStartedAt;

    // Eski sürümden gelen kullanıcı: takip başlangıcı kayıtlı değilse
    // ilk sigara kaydını (yoksa bugünü) başlangıç say.
    if (_onboardingDone && _trackingStartedAt == null) {
      _trackingStartedAt = _events.isNotEmpty ? _events.first.time : now;
      await storage.setTrackingStartedAt(_trackingStartedAt!);
    }

    // ÖNCE dinlemeye başla, SONRA bağlan; yoksa bağlanırken gelen
    // birikmiş olayları kaçırırız.
    _subscription = device.events.listen(_onDeviceEvent);
    await device.connect();
  }

  /// Kılıftan yeni bir olay geldi.
  ///
  /// Not: Sigara içmek XP götürmez, seriyi bozmaz, mesaj da göstermez.
  void _onDeviceEvent(SmokingEvent event) {
    // Aynı olay iki kez gelirse (ör. bağlantı koptu-bağlandı) tekrar sayma.
    final duplicate = _events.any((e) => e.time == event.time);
    if (duplicate) return;

    _events.add(event);
    _events.sort(_byTime);
    unawaited(storage.saveEvents(_events)); // Kaydı arka planda yap.
    notifyListeners();
  }

  // ---------- Profil ----------

  /// Onboarding bitti (ya da atlandı). Hoş geldin XP'si verilir.
  Future<Reward> completeOnboarding(UserProfile profile) async {
    _profile = profile;
    _onboardingDone = true;
    _trackingStartedAt ??= now;
    await storage.saveProfile(profile);
    await storage.setOnboardingDone(true);
    await storage.setTrackingStartedAt(_trackingStartedAt!);

    final alreadyWelcomed = _activity.xp.any(
      (x) => x.reason == XpReason.welcome,
    );
    return _collect([
      if (!alreadyWelcomed)
        XpEntry(time: now, amount: xpWelcome, reason: XpReason.welcome),
    ]);
  }

  /// Ayarlardan "Bilgilerimi düzenle" ile profil güncellendi.
  Future<void> updateProfile(UserProfile profile) async {
    _profile = profile;
    await storage.saveProfile(profile);
    notifyListeners();
  }

  // ---------- Olumlu eylemler (her biri ödül döndürür) ----------

  /// Günlük check-in: ruh halini kaydet.
  Future<Reward> logMood(Mood mood) {
    _activity.moods.add(MoodEntry(time: now, mood: mood));
    return _collect();
  }

  /// Bir sigaranın nedenini işaretle (ya da [trigger] null ise kaldır).
  Future<Reward> tagEvent(SmokingEvent event, SmokingTrigger? trigger) async {
    final index = _events.indexWhere((e) => e.time == event.time);
    if (index < 0) return Reward.none;
    _events[index] = _events[index].withTrigger(trigger);
    await storage.saveEvents(_events);
    return _collect();
  }

  /// Nefes egzersizi tamamlandı.
  Future<Reward> logBreathing() {
    _activity.breaths.add(now);
    return _collect();
  }

  /// Şu an süren erteleme varsa başlangıç zamanı.
  DateTime? get activeDelayStart => _activity.activeDelayStart;

  /// "Canım sigara istiyor" → erteleme sayacını başlat.
  Future<void> startDelay() async {
    _activity.activeDelayStart ??= now;
    await storage.saveActivity(_activity);
    notifyListeners();
  }

  /// Ertelemeyi bitir. Sonuç ne olursa olsun bir şey kazanılır:
  /// başardıysan büyük ödül, yine de içtiysen "denedin" ödülü.
  Future<Reward> finishDelay(DelayOutcome outcome) {
    final start = _activity.activeDelayStart ?? now;
    _activity.activeDelayStart = null;
    _activity.delays.add(
      DelayAttempt(start: start, end: now, outcome: outcome),
    );
    final success = outcome == DelayOutcome.success;
    return _collect([
      if (canRewardDelay(_activity, now))
        XpEntry(
          time: now,
          amount: success ? xpDelaySuccess : xpDelayTry,
          reason: success ? XpReason.delaySuccess : XpReason.delayTry,
        ),
    ]);
  }

  /// Ertelemeyi sonuç kaydetmeden iptal et (ör. yanlışlıkla başlatıldı).
  Future<void> cancelDelay() async {
    _activity.activeDelayStart = null;
    await storage.saveActivity(_activity);
    notifyListeners();
  }

  /// Eylemin kendi kazancını + yeni tamamlanan görevlerin ödüllerini ekler,
  /// kaydeder ve kutlama için sonucu döndürür.
  Future<Reward> _collect([List<XpEntry> actionGains = const []]) async {
    final wasActiveToday = streak.activeToday;
    _activity.xp.addAll(actionGains);
    final questGains = pendingQuestRewards(
      now: now,
      trackingStart: _trackingStartedAt,
      events: _events,
      activity: _activity,
    );
    _activity.xp.addAll(questGains);
    await storage.saveActivity(_activity);
    notifyListeners();

    final gains = [...actionGains, ...questGains];
    return Reward(
      gains: gains,
      streak: streak.current,
      streakExtended: !wasActiveToday && gains.isNotEmpty,
    );
  }

  // ---------- Veri yönetimi ----------

  /// Tüm verileri verilenlerle değiştirir (demo verisi üretirken).
  Future<void> replaceAll({
    required List<SmokingEvent> events,
    required ActivityLog activity,
    required DateTime trackingStartedAt,
  }) async {
    _events = [...events]..sort(_byTime);
    _activity = activity;
    _trackingStartedAt = trackingStartedAt;
    await storage.saveEvents(_events);
    await storage.saveActivity(_activity);
    await storage.setTrackingStartedAt(trackingStartedAt);
    notifyListeners();
  }

  /// Sigara kayıtlarını ve tüm ilerlemeyi siler; profil (cevaplar) kalır.
  /// Takip bugünden yeniden başlar.
  Future<void> resetEventsAndProgress() =>
      replaceAll(events: [], activity: ActivityLog(), trackingStartedAt: now);

  /// Profil dahil HER ŞEYİ siler; uygulama ilk açılış haline döner.
  Future<void> deleteAllData() async {
    await storage.clearAll();
    _profile = UserProfile();
    _onboardingDone = false;
    _events = [];
    _activity = ActivityLog();
    _trackingStartedAt = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    device.dispose();
    super.dispose();
  }

  static int _byTime(SmokingEvent a, SmokingEvent b) =>
      a.time.compareTo(b.time);
}
