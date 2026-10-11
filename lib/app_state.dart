import 'dart:async';

import 'package:flutter/foundation.dart';

import 'logic/goal.dart' as goals;
import 'logic/measurement.dart';
import 'logic/quests.dart';
import 'logic/rewards.dart';
import 'logic/stats.dart';
import 'logic/weekly_report.dart' as weekly;
// Getter adlarıyla (sproutStage, unlockedAccessories) karışmasın diye önekli.
import 'logic/wardrobe.dart' as wardrobe;
import 'models/activity_log.dart';
import 'models/goal.dart';
import 'models/mascot_look.dart';
import 'models/pack_price.dart';
import 'models/smoking_event.dart';
import 'models/user_profile.dart';
import 'services/device_service.dart';
import 'services/storage_service.dart';

/// Uygulamanın "beyni": profil, sigara kayıtları ve etkinlikler burada durur.
///
/// - Kılıftan ([DeviceService]) gelen olayları dinler ve kaydeder.
/// - Kullanıcının olumlu eylemlerini (ruh hali, erteleme...) kaydeder ve
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
  bool _measurementSummarySeen = false;
  int _weeklyReportSeen = 0;
  Set<Accessory> _outfit = {};
  Goal? _goal;
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

  /// Ölçüm haftasının özeti (takip başlamadıysa null).
  PeriodSummary? get measurementSummary {
    final start = _trackingStartedAt;
    return start == null ? null : summarizeMeasurementWeek(_events, start);
  }

  /// "Ölçüm haftan bitti!" kartı gösterilsin mi? Hafta bittiyse, özet henüz
  /// görülmediyse ve haftada en az bir kayıt varsa (yoksa özetlenecek bir şey
  /// yok).
  bool get measurementSummaryPending =>
      _onboardingDone &&
      !_measurementSummarySeen &&
      measurementOver(now, _trackingStartedAt) &&
      (measurementSummary?.total ?? 0) > 0;

  /// "Kazandıkların": ölçüm haftasına göre içilmeyen sigaralar, cepte kalan
  /// para, korunan yaşam süresi. Ölçüm haftası bitmediyse null.
  Gains? get gains => computeGains(
    events: _events,
    trackingStart: _trackingStartedAt,
    now: now,
    prices: _prices,
  );

  // ---------- Haftalık rapor (bkz. logic/weekly_report.dart) ----------

  /// Takibin kaçıncı günü (1 = başladığı gün). Takip başlamadıysa null.
  int? get trackingDay {
    final start = _trackingStartedAt;
    return start == null ? null : weekly.trackingDayNumber(now, start);
  }

  /// Bugüne kadar biten hafta sayısı (ölçüm haftası bitince 1).
  int get completedWeeks => weekly.completedWeeks(now, _trackingStartedAt);

  /// [week]. haftanın raporu (2. haftadan itibaren; hafta bitmediyse null).
  weekly.WeeklyReport? weeklyReport(int week) => weekly.buildWeeklyReport(
    week: week,
    events: _events,
    activity: _activity,
    trackingStart: _trackingStartedAt,
    now: now,
    prices: _prices,
  );

  /// "Bugün"de duyurulacak yeni haftalık raporun hafta numarası (yoksa
  /// null). Sadece EN SON biten hafta duyurulur: uygulama üç hafta
  /// açılmadıysa üç rapor üst üste gelmez; eskiler İstatistik'te durur.
  /// Ölçüm haftası özeti bekliyorsa önce o gösterilir. Haftada hiçbir şey
  /// olmadıysa (ne kayıt ne görev) duyurulacak bir şey yok.
  int? get pendingWeeklyReport {
    if (!_onboardingDone || measurementSummaryPending) return null;
    final week = completedWeeks;
    if (week < weekly.firstWeeklyReport || week <= _weeklyReportSeen) {
      return null;
    }
    final report = weeklyReport(week);
    return report == null || report.isEmpty ? null : week;
  }

  /// Haftalık rapor görüldü: "Bugün"deki duyuru kalksın.
  Future<void> markWeeklyReportSeen(int week) async {
    if (week <= _weeklyReportSeen) return;
    _weeklyReportSeen = week;
    await storage.setWeeklyReportSeen(week);
    notifyListeners();
  }

  // ---------- Azaltma hedefi (bkz. logic/goal.dart) ----------

  /// Kullanıcının seçtiği azaltma hedefi (seçmediyse null).
  Goal? get goal => _goal;

  /// Başlangıç noktası: ölçüm haftasında günde ortalama sigara. Ölçüm
  /// haftası bitmediyse ya da haftada hiç kayıt yoksa null (hedefin
  /// dayanacağı bir sayı yok; uydurmayız).
  double? get baseline {
    final summary = measurementSummary;
    if (!measurementOver(now, _trackingStartedAt) ||
        summary == null ||
        summary.total == 0) {
      return null;
    }
    return summary.dailyAverage;
  }

  /// Şu anki seviye: son 7 tamamlanmış günde günde ortalama sigara.
  /// Yeni bir hedefin haftalık sınırları buradan başlar.
  double get recentLevel {
    final today = startOfDay(now);
    return countBetween(_events, addDays(today, -7), today) / 7;
  }

  /// Hedef seçilebilir mi? (Ölçüm haftası bitti ve özeti görüldü.)
  bool get canSetGoal =>
      _onboardingDone &&
      baseline != null &&
      !measurementSummaryPending &&
      _measurementSummarySeen;

  /// Hedefin şu anki durumu (hedef yoksa null).
  goals.GoalStatus? get goalStatus {
    final current = _goal;
    return current == null
        ? null
        : goals.goalStatus(goal: current, events: _events, now: now);
  }

  /// Yeni hedefi kaydet (varsa eskisinin yerine; hedef bugünden başlar).
  /// İLK hedef bir kez +10 puan kazandırır; hedefi değiştirmek puan
  /// kazandırmaz (değiştirip durarak puan toplanmasın).
  Future<Reward> setGoal({
    required int percent,
    required int amount,
    required GoalUnit unit,
  }) async {
    final start = baseline;
    if (start == null) return Reward.none;
    _goal = Goal(
      start: startOfDay(now),
      baseline: start,
      from: recentLevel,
      percent: percent,
      amount: amount,
      unit: unit,
    );
    await storage.saveGoal(_goal);
    final first = !_activity.xp.any((x) => x.reason == XpReason.goalSet);
    return _collect([
      if (first)
        XpEntry(time: now, amount: xpGoalSet, reason: XpReason.goalSet),
    ]);
  }

  // ---------- Nefes'in dolabı (bkz. logic/wardrobe.dart) ----------

  /// Başındaki filizin aşaması (1–4); sadece toplam puanla büyür.
  int get sproutStage => wardrobe.sproutStage(totalXp);

  /// Açılmış eşyalar. Açılan eşya bir daha kaybolmaz: toplam puan, en uzun
  /// seri ve "ölçüm haftası bitti" bilgisi zamanla sadece artar.
  Set<Accessory> get unlockedAccessories => wardrobe.unlockedAccessories(
    totalXp: totalXp,
    bestStreak: streak.best,
    measurementDone: measurementOver(now, _trackingStartedAt),
  );

  /// Maskotun şu anki görünüşü (filiz aşaması + takılı eşyalar).
  MascotLook get mascotLook => MascotLook(
    stage: sproutStage,
    accessories: wardrobe.wearable(_outfit, unlockedAccessories),
  );

  /// Bir eşyayı tak ya da çıkar (aynı yerdeki eşya çıkar). Kilitli eşya
  /// takılamaz.
  Future<void> toggleOutfit(Accessory accessory) async {
    if (!unlockedAccessories.contains(accessory)) return;
    _outfit = wardrobe.toggleAccessory(mascotLook.accessories, accessory);
    await storage.saveOutfit(_outfit);
    notifyListeners();
  }

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
    _measurementSummarySeen = storage.measurementSummarySeen;
    _weeklyReportSeen = storage.weeklyReportSeen;
    _outfit = storage.loadOutfit();
    _goal = storage.loadGoal();
    // 0.6.0 ve öncesinden gelen kullanıcı: puanı zaten varsa açılmış
    // eşyaları (yerleri boşsa) bir kez tak; yoksa dolaptan habersiz kalır.
    if (_onboardingDone && !storage.hasOutfit) {
      _outfit = wardrobe.autoEquip({}, unlockedAccessories);
      await storage.saveOutfit(_outfit);
    }

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
    if (_onboardingDone || legacy != null) {
      // Profili yeniden kaydet: eski sürümlerden kalan ve artık kullanılmayan
      // alanlar (eski fiyat; yaş, cinsiyet, hedef gibi artık sorulmayan
      // cevaplar) böylece kayıttan silinir. Kullanmadığımız veriyi tutmayız.
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

  /// Kullanıcının kendine yazdığı notu kaydet (boşsa not silinir).
  Future<void> setReasonNote(String? note) async {
    final text = note?.trim() ?? '';
    _profile.reasonNote = text.isEmpty ? null : text;
    await storage.saveProfile(_profile);
    notifyListeners();
  }

  /// "Ölçüm haftan bitti!" özeti görüldü: kart bir daha çıkmasın.
  /// Ölçüm haftasıyla açılan kep takılır ("mezuniyet"); başta başka bir
  /// eşya (ör. bir gün önce açılan taç) varsa onun yerine. Kullanıcı
  /// dolaptan istediği zaman geri değiştirebilir.
  Future<void> markMeasurementSummarySeen() async {
    final firstTime = !_measurementSummarySeen;
    _measurementSummarySeen = true;
    await storage.setMeasurementSummarySeen(true);
    // Sadece ilk seferde: özet sonradan tekrar açılınca, kullanıcının
    // çıkardığı kepi geri takmayalım.
    if (firstTime && unlockedAccessories.contains(Accessory.kep)) {
      _outfit = wardrobe.wearCap(mascotLook.accessories);
      await storage.saveOutfit(_outfit);
    }
    notifyListeners();
  }

  // ---------- Olumlu eylemler (her biri ödül döndürür) ----------

  /// "Kendini dinle" görevi: ruh halini kaydet.
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
    final stageBefore = sproutStage;
    final unlockedBefore = unlockedAccessories;
    _activity.xp.addAll(actionGains);
    final questGains = pendingQuestRewards(
      now: now,
      trackingStart: _trackingStartedAt,
      events: _events,
      activity: _activity,
    );
    _activity.xp.addAll(questGains);
    await storage.saveActivity(_activity);

    // Puan arttı: dolapta yeni eşya açıldı mı, filiz büyüdü mü?
    final fresh = [
      for (final a in Accessory.values)
        if (unlockedAccessories.contains(a) && !unlockedBefore.contains(a)) a,
    ];
    // Kep zamanla (ölçüm haftası bitince) açılır ve normalde özet ekranında
    // verilir. Ölçüm haftasında hiç kayıt yoksa özet çıkmaz; o zaman kep
    // ilk olumlu eylemin kutlamasında bir kez haber verilsin.
    if (measurementOver(now, _trackingStartedAt) &&
        !_measurementSummarySeen &&
        (measurementSummary?.total ?? 0) == 0 &&
        unlockedAccessories.contains(Accessory.kep)) {
      fresh.add(Accessory.kep);
      _measurementSummarySeen = true;
      await storage.setMeasurementSummarySeen(true);
    }
    if (fresh.isNotEmpty) {
      // Yeri boşsa yeni eşyayı hemen tak: kullanıcı kutlamada görsün.
      _outfit = wardrobe.autoEquip(mascotLook.accessories, fresh);
      await storage.saveOutfit(_outfit);
    }
    final stageAfter = sproutStage;
    notifyListeners();

    final gains = [...actionGains, ...questGains];
    return Reward(
      gains: gains,
      streak: streak.current,
      streakExtended: !wasActiveToday && gains.isNotEmpty,
      newAccessories: fresh,
      grownToStage: stageAfter > stageBefore ? stageAfter : null,
    );
  }

  // ---------- Veri yönetimi ----------

  /// Tüm verileri verilenlerle değiştirir (demo verisi üretirken).
  /// [prices] verilirse fiyat geçmişi de değişir (verilmezse dokunulmaz).
  ///
  /// [newTracking]: takip baştan mı başlıyor? (Varsayılan evet: ölçüm
  /// haftası özeti ve haftalık raporlar yeniden çıkar, hedef silinir çünkü
  /// başlangıç noktası değişti.) Demo'daki "bir gün ilerlet" aynı takibi
  /// sürdürdüğü için false verir; görülen raporlar görülmüş kalır ve
  /// kaydırılmış hedef [goal] olarak verilir.
  Future<void> replaceAll({
    required List<SmokingEvent> events,
    required ActivityLog activity,
    required DateTime trackingStartedAt,
    PriceHistory? prices,
    bool newTracking = true,
    Goal? goal,
  }) async {
    _events = [...events]..sort(_byTime);
    _activity = activity;
    _trackingStartedAt = trackingStartedAt;
    await storage.saveEvents(_events);
    await storage.saveActivity(_activity);
    await storage.setTrackingStartedAt(trackingStartedAt);
    if (newTracking) {
      // Takip yeniden başladı: yeni ölçüm haftasının özeti ve haftalık
      // raporlar da yeniden çıksın.
      _measurementSummarySeen = false;
      _weeklyReportSeen = 0;
      await storage.setMeasurementSummarySeen(false);
      await storage.setWeeklyReportSeen(0);
      _goal = null;
      await storage.saveGoal(null);
    } else if (goal != null) {
      _goal = goal;
      await storage.saveGoal(goal);
    }
    if (prices != null) {
      _prices = prices;
      await storage.savePrices(prices);
    }
    notifyListeners();
  }

  /// Sigara kayıtlarını ve tüm ilerlemeyi siler; profil (cevaplar) kalır.
  /// Takip bugünden yeniden başlar.
  /// Puanlar sıfırlandığı için Nefes'in dolabı ve filiz de baştan başlar.
  Future<void> resetEventsAndProgress() async {
    _outfit = {};
    await storage.saveOutfit(_outfit);
    await replaceAll(
      events: [],
      activity: ActivityLog(),
      trackingStartedAt: now,
    );
  }

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
    _measurementSummarySeen = false;
    _weeklyReportSeen = 0;
    _outfit = {};
    _goal = null;
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
