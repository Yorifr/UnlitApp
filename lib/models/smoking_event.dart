import 'user_profile.dart';

/// Bir "sigara alma" olayı.
///
/// Kılıfın kapağı açılıp bir sigara çıkarıldığında kılıf bu olayı üretir ve
/// Bluetooth ile telefona gönderir. Demo modunda bu olayları
/// DemoDeviceService üretir.
class SmokingEvent {
  const SmokingEvent({required this.time, required this.source, this.trigger});

  /// Sigaranın alındığı an (telefonun yerel saatiyle).
  final DateTime time;

  /// Olayın nereden geldiği: demo verisi mi, gerçek kılıf mı, elle mi?
  /// Gerçek kılıfa geçince demo kayıtlarını ayırt edip silebilmek için
  /// tutuyoruz. (Pilotta "kılıf ne kadarını gördü?" sorusu için de işe yarar.)
  final EventSource source;

  /// Kullanıcının işaretlediği neden (kahve, stres...). İsteğe bağlı.
  final SmokingTrigger? trigger;

  /// Aynı olayın, nedeni değiştirilmiş kopyası.
  /// (Olaylar değiştirilemez; değişiklik için yeni bir kopya oluştururuz.)
  SmokingEvent withTrigger(SmokingTrigger? newTrigger) =>
      SmokingEvent(time: time, source: source, trigger: newTrigger);

  /// Kayıt için olayı kısa bir JSON nesnesine çevirir.
  /// Örnek: {"t": 1760083200000, "s": "demo", "r": "coffee"}
  /// (Anahtarları kısa tutuyoruz çünkü binlerce kayıt birikebilir.)
  Map<String, dynamic> toJson() => {
    't': time.millisecondsSinceEpoch,
    's': source.name,
    if (trigger != null) 'r': trigger!.name,
  };

  /// JSON'dan olayı geri oluşturur. Tanımadığımız bir kaynak adı gelirse
  /// uygulama çökmesin diye "device" (gerçek kılıf) kabul ederiz.
  factory SmokingEvent.fromJson(Map<String, dynamic> json) {
    return SmokingEvent(
      time: DateTime.fromMillisecondsSinceEpoch(json['t'] as int),
      source: EventSource.values.asNameMap()[json['s']] ?? EventSource.device,
      trigger: SmokingTrigger.values.asNameMap()[json['r']],
    );
  }
}

/// Olayın kaynağı.
enum EventSource {
  /// Demo modunun ürettiği sahte olay.
  demo,

  /// Gerçek akıllı kılıftan gelen olay.
  device,

  /// Kullanıcının elle eklediği sigara: kılıfın göremediği (ör. arkadaşından
  /// aldığı ya da başka bir paketten) bir sigara. (0.11.0)
  manual,
}
