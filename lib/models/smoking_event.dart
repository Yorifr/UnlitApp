/// Bir "sigara alma" olayı.
///
/// Kılıfın kapağı açılıp bir sigara çıkarıldığında kılıf bu olayı üretir ve
/// Bluetooth ile telefona gönderir. Demo modunda bu olayları
/// DemoDeviceService üretir.
class SmokingEvent {
  const SmokingEvent({required this.time, required this.source});

  /// Sigaranın alındığı an (telefonun yerel saatiyle).
  final DateTime time;

  /// Olayın nereden geldiği: demo verisi mi, gerçek kılıf mı?
  /// Gerçek kılıfa geçince demo kayıtlarını ayırt edip silebilmek için tutuyoruz.
  final EventSource source;

  /// Kayıt için olayı kısa bir JSON nesnesine çevirir.
  /// Örnek: {"t": 1760083200000, "s": "demo"}
  /// (Anahtarları kısa tutuyoruz çünkü binlerce kayıt birikebilir.)
  Map<String, dynamic> toJson() => {
    't': time.millisecondsSinceEpoch,
    's': source.name,
  };

  /// JSON'dan olayı geri oluşturur. Tanımadığımız bir kaynak adı gelirse
  /// uygulama çökmesin diye "device" (gerçek kılıf) kabul ederiz.
  factory SmokingEvent.fromJson(Map<String, dynamic> json) {
    return SmokingEvent(
      time: DateTime.fromMillisecondsSinceEpoch(json['t'] as int),
      source: EventSource.values.asNameMap()[json['s']] ?? EventSource.device,
    );
  }
}

/// Olayın kaynağı.
enum EventSource {
  /// Demo modunun ürettiği sahte olay.
  demo,

  /// Gerçek akıllı kılıftan gelen olay.
  device,
}
