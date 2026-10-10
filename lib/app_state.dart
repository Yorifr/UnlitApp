import 'dart:async';

import 'package:flutter/foundation.dart';

import 'logic/quests.dart';
import 'logic/rewards.dart';
import 'logic/stats.dart';
import 'models/activity_log.dart';
import 'models/pack_price.dart';
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
  PriceHistory _prices = PriceHistory();
  DateTime? _priceConfirmedAt;
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

  /// Paket fiyatı geçmişi (her fiyat "ne zamandan beri" bilgisiyle).
  PriceHistory get prices => _prices;

  /// Fiyat uzun süredir değişmediyse nazikçe "hâlâ aynı mı?" diye sorarız.
  /// (Bu bir uyarı değil; sadece hesapların doğru kalması için.)
  static const priceCheckAfter = Duration(days: 90);

  /// "Paket fiyatın hâlâ aynı mı?" sorusu gösterilsin mi?
  bool get shouldAskPriceStillSame {
    final current = _prices.current;
    if (current == null) return false;
    final confirmed = _priceConfirmedAt;
    final lastTouched = confirmed != null && confirmed.isAfter(current.since)
        ? confirmed
        : current.since;
    return now.difference(lastTouched) >= priceCheckAfter;
  }

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
    _prices = storage.loadPrices();
    _priceConfirmedAt = storage.priceConfirmedAt;

    // Eski sürümden gelen kullanıcı: takip başlangıcı kayıtlı değilse
    // ilk sigara kaydını (yoksa bugünü) başlangıç say.
    if (_onboardingDone && _trackingStartedAt == null) {
      _trackingStartedAt = _events.isNotEmpty ? _events.first.time : now;
      await storage.setTrackingStartedAt(_trackingStartedAt!);
    }

    // Eski sürümden gelen kullanıcı: fiyat profilin içindeydi. Onu, takibin
    // başladığı günden geçerli tek bir fiyat olarak taşı (bir kez).
    final legacy = storage.loadLegacyPackPrice();
    if (_prices.isEmpty && legacy != null) {
      _prices = PriceHistory([
        PackPrice(
          since: startOfDay(_trackingStartedAt ?? now),
          price: legacy.price,
          perPack: legacy.perPack,
        ),
      ]);
      await storage.savePrices(_prices);
    }
    if (legacy != null) {
      // Profili eski alanlar olmadan tekrar kaydet: taşıma bir daha olmasın.
      await storage.saveProfile(_profile);
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

  // ---------- Paket fiyatı ----------

  /// Yeni paket fiyatını kaydet.
  ///
  /// - Normalde fiyat BUGÜNDEN itibaren geçerli olur; önceki günler eski
  ///   fiyatla hesaplanmaya devam eder (zam geldiyse doğrusu bu).
  /// - Aynı gün içinde tekrar değiştirilirse bugünkü kayıt düzeltilir.
  /// - [correctPast] true ise ("yanlış girmiştim") tüm geçmiş bu fiyatla
  ///   hesaplanır: eski fiyatlar silinir.
  Future<void> setPackPrice({
    required double price,
    int perPack = 20,
    bool correctPast = false,
  }) async {
    final today = startOfDay(now);
    final current = _prices.current;
    final unchanged =
        current != null &&
        current.price == price &&
        current.perPack == perPack &&
        !correctPast;
    if (!unchanged) {
      final kept = correctPast
          ? <PackPrice>[]
          : _prices.entries.where((p) => p.since != today).toList();
      _prices = PriceHistory([
        ...kept,
        PackPrice(since: today, price: price, perPack: perPack),
      ]);
      await storage.savePrices(_prices);
    }
    // Fiyatı yeni girdi/onayladı: "hâlâ aynı mı?" sorusu bir süre sorulmasın.
    await confirmPriceStillSame();
  }

  /// "Fiyat hâlâ aynı" → bir süre bir daha sorma.
  Future<void> confirmPriceStillSame() async {
    _priceConfirmedAt = now;
    await storage.setPriceConfirmedAt(now);
    notifyListeners();
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
  /// [prices] verilirse fiyat geçmişi de değişir (verilmezse dokunulmaz).
  Future<void> replaceAll({
    required List<SmokingEvent> events,
    required ActivityLog activity,
    required DateTime trackingStartedAt,
    PriceHistory? prices,
  }) async {
    _events = [...events]..sort(_byTime);
    _activity = activity;
    _trackingStartedAt = trackingStartedAt;
    await storage.saveEvents(_events);
    await storage.saveActivity(_activity);
    await storage.setTrackingStartedAt(trackingStartedAt);
    if (prices != null) {
      _prices = prices;
      await storage.savePrices(prices);
    }
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
    _prices = PriceHistory();
    _priceConfirmedAt = null;
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
