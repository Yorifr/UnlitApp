// SVG "path" yazısını Flutter'ın Path nesnesine çeviren küçük okuyucu.
//
// Neden? Maskot önce SVG olarak tasarlandı (docs/maskot/1-nefes-2.svg).
// Şekilleri buraya elle tek tek çevirmek yerine SVG'deki `d="..."` yazısını
// aynen kullanıyoruz: kod ile tasarım dosyası yan yana konunca birebir
// karşılaştırılabiliyor. Paket eklemedik; sadece maskotun kullandığı
// komutları destekliyoruz:
//   M/m (git), L/l (çizgi), H/h, V/v (yatay/dikey çizgi),
//   Q/q (ikinci derece eğri), C/c (üçüncü derece eğri),
//   A/a (elips yayı), Z/z (kapat).
// Büyük harf = mutlak koordinat, küçük harf = bir önceki noktaya göre.

import 'dart:ui' show Offset, Path, Radius;

final Map<String, Path> _cache = {};

/// [d] yazısından bir Path üretir. Aynı yazı tekrar istenirse önceden
/// hesaplanmış olanı verir (maskot saniyede birçok kez çizilebilir).
Path svgPath(String d) => _cache.putIfAbsent(d, () => _parse(d));

/// Sayıları ve komut harflerini ayıklar: "M0 0 C5 -8" → [M, 0, 0, C, 5, -8]
/// (Her harf alınır; desteklemediğimiz bir komut sessizce atlanmasın,
/// aşağıda açıkça hata versin.)
final RegExp _token = RegExp(
  r'[A-Za-z]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?',
);

Path _parse(String d) {
  final tokens = [for (final m in _token.allMatches(d)) m.group(0)!];
  final path = Path();
  var i = 0;
  var x = 0.0, y = 0.0; // şu anki nokta
  var startX = 0.0, startY = 0.0; // "Z" ile dönülecek nokta
  String? command;

  bool isCommand(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
  double next() => double.parse(tokens[i++]);

  while (i < tokens.length) {
    // Komut harfi yoksa bir önceki komut tekrar eder (SVG kuralı).
    if (isCommand(tokens[i])) {
      command = tokens[i++];
    } else if (command == null) {
      throw FormatException('SVG yolu komutla başlamalı: $d');
    }
    final relative = command == command.toLowerCase();
    final dx = relative ? x : 0.0, dy = relative ? y : 0.0;

    switch (command.toUpperCase()) {
      case 'M':
        x = next() + dx;
        y = next() + dy;
        path.moveTo(x, y);
        startX = x;
        startY = y;
        // M'den sonra gelen sayılar "L" sayılır.
        command = relative ? 'l' : 'L';
      case 'L':
        x = next() + dx;
        y = next() + dy;
        path.lineTo(x, y);
      case 'H':
        x = next() + dx;
        path.lineTo(x, y);
      case 'V':
        y = next() + dy;
        path.lineTo(x, y);
      case 'Q':
        final x1 = next() + dx, y1 = next() + dy;
        x = next() + dx;
        y = next() + dy;
        path.quadraticBezierTo(x1, y1, x, y);
      case 'C':
        final x1 = next() + dx, y1 = next() + dy;
        final x2 = next() + dx, y2 = next() + dy;
        x = next() + dx;
        y = next() + dy;
        path.cubicTo(x1, y1, x2, y2, x, y);
      case 'A':
        final rx = next(), ry = next(), rotation = next();
        final largeArc = next() != 0, sweep = next() != 0;
        x = next() + dx;
        y = next() + dy;
        // SVG'de sweep=1, ekranda (y aşağı) saat yönü demek.
        path.arcToPoint(
          Offset(x, y),
          radius: Radius.elliptical(rx, ry),
          rotation: rotation,
          largeArc: largeArc,
          clockwise: sweep,
        );
      case 'Z':
        path.close();
        x = startX;
        y = startY;
        command = null; // Z'den sonra yeni bir komut gelmeli
      default:
        throw FormatException('Desteklenmeyen SVG komutu: $command');
    }
  }
  return path;
}
