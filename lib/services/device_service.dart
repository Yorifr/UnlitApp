import 'package:flutter/foundation.dart';

import '../models/smoking_event.dart';

/// Kılıfla bağlantının durumu.
enum DeviceStatus {
  disconnected('Bağlı değil'),
  connecting('Bağlanıyor…'),
  connected('Bağlı');

  const DeviceStatus(this.label);
  final String label;
}

/// Akıllı kılıfla konuşan her şeyin uyması gereken "sözleşme" (arayüz).
///
/// Uygulamanın geri kalanı kılıfın gerçek mi yoksa demo mu olduğunu bilmez;
/// sadece bu sınıftaki özellikleri kullanır. Böylece:
/// - Şimdi: [DemoDeviceService] sahte olaylar üretir.
/// - Sonra: `BleDeviceService` (flutter_blue_plus ile) aynı sözleşmeyi
///   uygulayıp gerçek kılıftan veri okuyacak. Ekranlarda hiçbir şeyi
///   değiştirmemiz gerekmeyecek.
///
/// Gerçek kılıf bağlı değilken de sigaraları sayıp hafızasında tutacak;
/// telefon bağlanınca birikmiş olayları zaman damgalarıyla birlikte
/// [events] akışından gönderecek. Demo kılıf da aynı şekilde davranır.
abstract class DeviceService {
  /// Ekranda gösterilecek cihaz adı (ör. "Demo kılıf").
  String get name;

  /// Bağlantı durumu. Ekranlar `ValueListenableBuilder` ile dinleyebilir.
  ValueListenable<DeviceStatus> get status;

  /// Kılıftan gelen sigara alma olayları. Bağlanınca önce kılıfın
  /// hafızasında birikmiş olaylar, sonra canlı olaylar gelir.
  Stream<SmokingEvent> get events;

  /// Kılıfa bağlanır.
  Future<void> connect();

  /// Bağlantıyı keser.
  Future<void> disconnect();

  /// Servisi tamamen kapatır (uygulama kapanırken).
  void dispose();
}
