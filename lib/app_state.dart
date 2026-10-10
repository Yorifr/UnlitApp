import 'dart:async';

import 'package:flutter/foundation.dart';

import 'models/smoking_event.dart';
import 'models/user_profile.dart';
import 'services/device_service.dart';
import 'services/storage_service.dart';

/// Uygulamanın "beyni": profil ve sigara kayıtları burada durur.
///
/// - Kılıftan ([DeviceService]) gelen olayları dinler ve kaydeder.
/// - Her değişiklikte [notifyListeners] çağırır; ekranlar
///   `ListenableBuilder` ile dinleyip kendini yeniler.
/// - Kalıcı kayıt için [StorageService] kullanır (sadece bu cihaz).
class AppState extends ChangeNotifier {
  AppState({required this.storage, required this.device});

  final StorageService storage;
  final DeviceService device;

  UserProfile _profile = UserProfile();
  bool _onboardingDone = false;
  List<SmokingEvent> _events = [];
  StreamSubscription<SmokingEvent>? _subscription;

  UserProfile get profile => _profile;
  bool get onboardingDone => _onboardingDone;

  /// Tüm sigara kayıtları, eskiden yeniye sıralı. (Sadece okunabilir.)
  List<SmokingEvent> get events => List.unmodifiable(_events);

  /// Uygulama açılırken bir kez çağrılır.
  Future<void> start() async {
    _profile = storage.loadProfile();
    _onboardingDone = storage.onboardingDone;
    _events = storage.loadEvents()..sort(_byTime);

    // ÖNCE dinlemeye başla, SONRA bağlan; yoksa bağlanırken gelen
    // birikmiş olayları kaçırırız.
    _subscription = device.events.listen(_onDeviceEvent);
    await device.connect();
  }

  /// Kılıftan yeni bir olay geldi.
  void _onDeviceEvent(SmokingEvent event) {
    // Aynı olay iki kez gelirse (ör. bağlantı koptu-bağlandı) tekrar sayma.
    final duplicate = _events.any((e) => e.time == event.time);
    if (duplicate) return;

    _events.add(event);
    _events.sort(_byTime);
    unawaited(storage.saveEvents(_events)); // Kaydı arka planda yap.
    notifyListeners();
  }

  /// Onboarding bitti (ya da atlandı).
  Future<void> completeOnboarding(UserProfile profile) async {
    _profile = profile;
    _onboardingDone = true;
    await storage.saveProfile(profile);
    await storage.setOnboardingDone(true);
    notifyListeners();
  }

  /// Ayarlardan "Bilgilerimi düzenle" ile profil güncellendi.
  Future<void> updateProfile(UserProfile profile) async {
    _profile = profile;
    await storage.saveProfile(profile);
    notifyListeners();
  }

  /// Tüm sigara kayıtlarını verilen liste ile değiştirir (demo verisi üret).
  Future<void> replaceEvents(List<SmokingEvent> events) async {
    _events = [...events]..sort(_byTime);
    await storage.saveEvents(_events);
    notifyListeners();
  }

  /// Tüm sigara kayıtlarını siler (profil kalır).
  Future<void> clearEvents() => replaceEvents([]);

  /// Profil dahil HER ŞEYİ siler; uygulama ilk açılış haline döner.
  Future<void> deleteAllData() async {
    await storage.clearAll();
    _profile = UserProfile();
    _onboardingDone = false;
    _events = [];
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
