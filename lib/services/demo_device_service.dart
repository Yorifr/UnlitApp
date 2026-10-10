import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/smoking_event.dart';
import 'demo_day_planner.dart';
import 'device_service.dart';
import 'storage_service.dart';

/// Kılıf henüz yokken kullandığımız "sanal kılıf".
///
/// Gerçek kılıf gibi davranır:
/// - Her gün için gerçekçi bir sigara planı vardır (bkz. [planDemoDay]).
/// - Uygulama kapalıyken geçen sürede "içilen" sigaraları, uygulama
///   açılıp bağlanınca toplu olarak gönderir (gerçek kılıfın hafızası gibi).
/// - Uygulama açıkken saati gelen sigaraları canlı olarak gönderir.
///
/// Böylece ekip web sürümünü günlerce takip ederken veriler gerçek bir
/// kullanıcınınki gibi birikir.
class DemoDeviceService implements DeviceService {
  DemoDeviceService({
    required this.storage,
    DateTime Function()? clock,
    this.tickInterval = const Duration(seconds: 30),
  }) : _clock = clock ?? DateTime.now;

  /// Demo kılıfın küçük hafızası (son senkronizasyon, tohum) burada durur.
  final StorageService storage;

  /// Şu anki zamanı veren fonksiyon. Testlerde sahte saat verebilmek için
  /// doğrudan DateTime.now() yerine bunu kullanıyoruz.
  final DateTime Function() _clock;

  /// Yeni sigara var mı diye ne sıklıkla kontrol edilsin?
  final Duration tickInterval;

  /// Uygulama uzun süre açılmazsa en fazla bu kadar geriye dönük veri üret.
  static const maxBackfill = Duration(days: 30);

  final _events = StreamController<SmokingEvent>.broadcast();
  final _status = ValueNotifier(DeviceStatus.disconnected);
  Timer? _timer;
  DateTime? _lastSync;

  @override
  String get name => 'Demo kılıf';

  @override
  ValueListenable<DeviceStatus> get status => _status;

  @override
  Stream<SmokingEvent> get events => _events.stream;

  @override
  Future<void> connect() async {
    if (_status.value != DeviceStatus.disconnected) return;
    _status.value = DeviceStatus.connecting;

    // İlk kez bağlanıyorsak geçmiş yok; şu andan itibaren saymaya başla.
    _lastSync = storage.demoLastSync ?? _clock();
    await _sync(); // Uygulama kapalıyken birikenleri gönder.

    _status.value = DeviceStatus.connected;
    _timer = Timer.periodic(tickInterval, (_) => _sync());
  }

  @override
  Future<void> disconnect() async {
    _timer?.cancel();
    _timer = null;
    _status.value = DeviceStatus.disconnected;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _events.close();
    _status.dispose();
  }

  /// Son senkronizasyondan bu yana saati gelmiş sigaraları gönderir.
  Future<void> _sync() async {
    final now = _clock();
    var from = _lastSync ?? now;
    final oldest = now.subtract(maxBackfill);
    if (from.isBefore(oldest)) from = oldest;

    for (final time in plannedBetween(from, now)) {
      _events.add(SmokingEvent(time: time, source: EventSource.demo));
    }
    _lastSync = now;
    await storage.setDemoLastSync(now);
  }

  /// (from, to] aralığına düşen planlanmış sigara saatleri.
  /// Aralığın kapsadığı her gün için o günün planını çıkarıp süzer.
  ///
  /// [trackingStart] verilmezse kayıttaki takip başlangıcı kullanılır (demo
  /// kullanıcısı ölçüm haftasından sonra yavaşça azaltır).
  List<DateTime> plannedBetween(
    DateTime from,
    DateTime to, {
    DateTime? trackingStart,
  }) {
    final seed = _seed();
    final profile = storage.loadProfile(); // Demo, profile benzesin.
    final start = trackingStart ?? storage.trackingStartedAt;
    final result = <DateTime>[];

    var day = DateTime(from.year, from.month, from.day);
    while (!day.isAfter(to)) {
      // Her günün kendi tohumu var: aynı gün hep aynı planı üretir.
      final random = Random(
        seed + day.year * 10000 + day.month * 100 + day.day,
      );
      final plan = planDemoDay(
        day,
        random,
        usualPerDay: profile.cigarettesPerDay,
        firstCigarette: profile.firstCigarette,
        reduction: demoReduction(day, start),
      );
      for (final time in plan) {
        if (time.isAfter(from) && !time.isAfter(to)) result.add(time);
      }
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return result;
  }

  /// Kayıtlı tohumu döndürür; yoksa yeni bir tane oluşturup kaydeder.
  int _seed() {
    final saved = storage.demoSeed;
    if (saved != null) return saved;
    final seed = Random().nextInt(1 << 30);
    unawaited(storage.setDemoSeed(seed));
    return seed;
  }

  // ---------- Ayarlar ekranındaki demo butonları ----------

  /// "Demo verisi üret": son [days] günün sahte kayıtlarını baştan üretir.
  /// Her basışta yeni bir tohum seçilir, yani farklı bir veri çıkar.
  /// Varsayılan 15 gün: "son 7 gün / önceki 7 gün" karşılaştırması için
  /// iki tam hafta (+1 gün pay) gerekiyor.
  Future<List<SmokingEvent>> generateHistory({int days = 15}) async {
    await storage.setDemoSeed(Random().nextInt(1 << 30));
    final now = _clock();
    final from = DateTime(now.year, now.month, now.day - (days - 1));

    // Üretilen geçmişin ilk günü, takibin (ölçüm haftasının) başlangıcı olur
    // (bkz. loadDemoHistory).
    final times = plannedBetween(from, now, trackingStart: from);
    _lastSync = now;
    await storage.setDemoLastSync(now);
    return [
      for (final time in times)
        SmokingEvent(time: time, source: EventSource.demo),
    ];
  }

  /// Kapağın şu an açılıp bir sigara alındığını taklit eder.
  void simulatePickup() {
    _events.add(SmokingEvent(time: _clock(), source: EventSource.demo));
  }
}
