// Paket fiyatı ve fiyat geçmişi.
//
// Neden "geçmiş"? Sigara fiyatları yılda birkaç kez değişebiliyor. Tek bir
// fiyat saklasaydık, zam gelip fiyatı güncellediğinde GEÇMİŞ günlerin
// harcaması da yeni fiyatla hesaplanırdı (yanlış!). Bu yüzden her fiyatı
// "ne zamandan beri geçerli" bilgisiyle saklıyoruz; her sigara kendi
// tarihindeki fiyatla hesaplanır.

/// Belli bir tarihten itibaren geçerli paket fiyatı.
class PackPrice {
  const PackPrice({
    required this.since,
    required this.price,
    this.perPack = 20,
  });

  /// Bu fiyat bu andan itibaren geçerli.
  final DateTime since;

  /// Bir paketin fiyatı (₺).
  final double price;

  /// Pakette kaç sigara var (Türkiye'de çoğu paket 20'li).
  final int perPack;

  /// Bir sigaranın fiyatı (₺).
  double get perCigarette => price / perPack;

  Map<String, dynamic> toJson() => {
    's': since.millisecondsSinceEpoch,
    'p': price,
    'n': perPack,
  };

  /// JSON'dan okur; bozuk kayıtsa null döner (uygulama çökmez).
  static PackPrice? fromJson(Map<String, dynamic> json) {
    final s = json['s'], p = json['p'], n = json['n'];
    if (s is! int || p is! num || p <= 0) return null;
    return PackPrice(
      since: DateTime.fromMillisecondsSinceEpoch(s),
      price: p.toDouble(),
      perPack: n is int && n > 0 ? n : 20,
    );
  }
}

/// Tüm fiyatlar, eskiden yeniye sıralı.
class PriceHistory {
  PriceHistory([List<PackPrice> entries = const []])
    : entries = List.unmodifiable(
        [...entries]..sort((a, b) => a.since.compareTo(b.since)),
      );

  final List<PackPrice> entries;

  bool get isEmpty => entries.isEmpty;

  /// Şu anki (en son girilen) fiyat. Hiç fiyat yoksa null.
  PackPrice? get current => entries.isEmpty ? null : entries.last;

  /// [time] anında geçerli olan fiyat.
  ///
  /// İlk fiyattan ÖNCEKİ bir an için ilk fiyatı kullanırız: kullanıcı fiyatı
  /// genelde takibe başlarken girer; ondan önceki birkaç kayıt için en iyi
  /// tahmin budur. Hiç fiyat yoksa null.
  PackPrice? at(DateTime time) {
    if (entries.isEmpty) return null;
    var result = entries.first;
    for (final entry in entries) {
      if (entry.since.isAfter(time)) break;
      result = entry;
    }
    return result;
  }

  List<Map<String, dynamic>> toJson() => [for (final e in entries) e.toJson()];

  factory PriceHistory.fromJson(Object? json) {
    if (json is! List) return PriceHistory();
    return PriceHistory(
      json
          .whereType<Map<String, dynamic>>()
          .map(PackPrice.fromJson)
          .whereType<PackPrice>() // bozuk satırları atla
          .toList(),
    );
  }
}
