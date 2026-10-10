import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_log.dart';
import '../models/pack_price.dart';
import '../models/smoking_event.dart';
import '../models/user_profile.dart';

/// Tüm verileri SADECE bu cihazda saklayan servis.
///
/// Arka planda `shared_preferences` paketini kullanır:
/// - Android/iOS'ta telefonun kendi ayar dosyasına,
/// - Web'de tarayıcının localStorage alanına yazar.
/// Hiçbir veri internete gönderilmez. (Gizlilik vaadimiz bu!)
///
/// Veriler JSON metni olarak saklanır. Sigara olayları için bu yöntem
/// birkaç bin kayda kadar rahat çalışır; pilot çalışmada kayıt sayısı çok
/// artarsa SQLite gibi bir veritabanına geçebiliriz (bkz. docs/SPEC.md).
class StorageService {
  StorageService(this._prefs);

  /// Uygulama açılırken bir kez çağrılır.
  static Future<StorageService> create() async {
    return StorageService(await SharedPreferences.getInstance());
  }

  final SharedPreferences _prefs;

  // Kayıt anahtarları. Bir anahtarın adını değiştirirsen eski veriler
  // okunamaz hale gelir, dikkat!
  static const _kProfile = 'profile';
  static const _kOnboardingDone = 'onboarding_done';
  static const _kEvents = 'events';
  static const _kDemoLastSync = 'demo_last_sync';
  static const _kDemoSeed = 'demo_seed';
  static const _kActivity = 'activity';
  static const _kTrackingStartedAt = 'tracking_started_at';
  static const _kPrices = 'prices';
  static const _kPriceConfirmedAt = 'price_confirmed_at';

  // ---------- Profil ----------

  UserProfile loadProfile() {
    final text = _prefs.getString(_kProfile);
    if (text == null) return UserProfile();
    try {
      return UserProfile.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (_) {
      // Kayıt bozulmuşsa boş profille devam et, uygulama çökmesin.
      return UserProfile();
    }
  }

  Future<void> saveProfile(UserProfile profile) =>
      _prefs.setString(_kProfile, jsonEncode(profile.toJson()));

  /// ESKİ SÜRÜM (0.3.0 ve öncesi) fiyatı profilin içinde saklıyordu.
  /// Taşıma (migration) için o eski değerleri okur; yoksa null döner.
  ({double price, int perPack})? loadLegacyPackPrice() {
    final text = _prefs.getString(_kProfile);
    if (text == null) return null;
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      final price = json['packPrice'];
      if (price is! num || price <= 0) return null;
      final perPack = json['cigarettesPerPack'];
      return (
        price: price.toDouble(),
        perPack: perPack is int && perPack > 0 ? perPack : 20,
      );
    } catch (_) {
      return null;
    }
  }

  // ---------- Onboarding ----------

  /// Kullanıcı onboarding'i bitirdi mi (ya da atladı mı)?
  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;

  Future<void> setOnboardingDone(bool value) =>
      _prefs.setBool(_kOnboardingDone, value);

  // ---------- Sigara olayları ----------

  List<SmokingEvent> loadEvents() {
    final text = _prefs.getString(_kEvents);
    if (text == null) return [];
    try {
      final list = jsonDecode(text) as List;
      return list
          .map((e) => SmokingEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEvents(List<SmokingEvent> events) => _prefs.setString(
    _kEvents,
    jsonEncode(events.map((e) => e.toJson()).toList()),
  );

  // ---------- Etkinlikler (ruh hali, erteleme, nefes, XP) ----------

  ActivityLog loadActivity() {
    final text = _prefs.getString(_kActivity);
    if (text == null) return ActivityLog();
    try {
      return ActivityLog.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (_) {
      return ActivityLog();
    }
  }

  Future<void> saveActivity(ActivityLog activity) =>
      _prefs.setString(_kActivity, jsonEncode(activity.toJson()));

  // ---------- Paket fiyatı geçmişi ----------

  PriceHistory loadPrices() {
    final text = _prefs.getString(_kPrices);
    if (text == null) return PriceHistory();
    try {
      return PriceHistory.fromJson(jsonDecode(text));
    } catch (_) {
      return PriceHistory();
    }
  }

  Future<void> savePrices(PriceHistory prices) =>
      _prefs.setString(_kPrices, jsonEncode(prices.toJson()));

  /// Kullanıcının "fiyat hâlâ aynı" dediği son an.
  DateTime? get priceConfirmedAt {
    final ms = _prefs.getInt(_kPriceConfirmedAt);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setPriceConfirmedAt(DateTime time) =>
      _prefs.setInt(_kPriceConfirmedAt, time.millisecondsSinceEpoch);

  // ---------- Takibin başladığı gün ----------

  /// Kullanıcının takibe başladığı an (ölçüm haftası buradan sayılır).
  DateTime? get trackingStartedAt {
    final ms = _prefs.getInt(_kTrackingStartedAt);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setTrackingStartedAt(DateTime time) =>
      _prefs.setInt(_kTrackingStartedAt, time.millisecondsSinceEpoch);

  // ---------- Demo kılıfın küçük hafızası ----------

  /// Demo kılıfın en son ne zaman "senkronize" olduğu.
  DateTime? get demoLastSync {
    final ms = _prefs.getInt(_kDemoLastSync);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setDemoLastSync(DateTime time) =>
      _prefs.setInt(_kDemoLastSync, time.millisecondsSinceEpoch);

  /// Demo verisini üreten rastgele sayı üretecinin tohumu (seed).
  int? get demoSeed => _prefs.getInt(_kDemoSeed);

  Future<void> setDemoSeed(int seed) => _prefs.setInt(_kDemoSeed, seed);

  // ---------- Küçük ayarlar (ses açık mı vb.) ----------

  bool? readBool(String key) => _prefs.getBool(key);

  Future<void> writeBool(String key, bool value) => _prefs.setBool(key, value);

  // ---------- Hepsini sil ----------

  /// Bu uygulamanın sakladığı her şeyi siler.
  Future<void> clearAll() => _prefs.clear();
}
