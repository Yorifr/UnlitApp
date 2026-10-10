import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_log.dart';
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

  // ---------- Hepsini sil ----------

  /// Bu uygulamanın sakladığı her şeyi siler.
  Future<void> clearAll() => _prefs.clear();
}
