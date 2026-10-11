// Maskot "Nefes"in çizimi (Nefes 2.0).
//
// Tasarım dosyası: docs/maskot/1-nefes-2.svg. Bu dosya o SVG'nin birebir
// kod hâlidir: aynı sıra, aynı koordinatlar. Çizim 200 × 200 birimlik bir
// alanda yapılır, sonra istenen boyuta büyütülür/küçültülür; bu yüzden
// her boyutta net görünür.
//
// Çizim sırası önemli (sonra çizilen üstte kalır):
//   kollar → ayaklar → gövde → gözler → ağız → atkı → gözlük → kulaklık →
//   kep (arka) → filiz → kep (ön) → bere → taç → düşünme noktaları →
//   kutlama parıltıları
//
// KURAL: Nefes ASLA üzgün, kızgın ya da hasta görünmez. Filiz asla solmaz.

import 'dart:math';

import 'package:flutter/material.dart';

import '../models/mascot_look.dart';
import 'mascot.dart' show MascotMood;
import 'svg_path.dart';

/// Maskotun renkleri (açık ve koyu temada aynı). Bir rengi değiştirmek
/// isterseniz sadece buradan değiştirin.
class MascotColors {
  MascotColors._();

  static const body = Color(0xFF2EC4B6); // Nane gövde
  static const bodyDark = Color(0xFF1A9C90); // Gövdenin alt tonu, kollar
  static const belly = Color(0xFFC9F3EC);
  static const cheek = Color(0xFFFF9EAA);
  static const ink = Color(0xFF233A3A); // Göz bebeği, çizgiler
  static const mouth = Color(0xFF8A2E3B);
  static const tongue = Color(0xFFFF8A9A);
  static const sprout = Color(0xFF4FB52C); // Filiz (açık yaprak)
  static const sproutDark = Color(0xFF4AA32A); // Filiz (sap, koyu yaprak)
  static const flower = Color(0xFFB27CF7); // 4. aşamadaki mor çiçek
  static const gold = Color(0xFFFFC21A);
  static const goldDark = Color(0xFFE09B00);
  static const blue = Color(0xFF3D7BF7);
  static const blueDark = Color(0xFF2457D6);
  static const blueDeep = Color(0xFF1C46B0);
  static const blueLight = Color(0xFFE2ECFF);
  static const frame = Color(0xFF8F57E0); // Gözlük çerçevesi
  static const calmLens = Color(0xFF9DBBFF); // Sakin moddaki açık cam
  static const beanie = Color(0xFFB27CF7);
  static const beanieBand = Color(0xFF8F57E0);
  static const beanieKnit = Color(0xFF7440C9);
  static const white = Colors.white;
}

/// Yaprak şekli (filizde ve tacta aynı şekil döndürülüp büyütülerek
/// kullanılır).
const _leafShape = 'M0 0 C5 -8 14 -9 20 0 C14 9 5 8 0 0 Z';

/// Kutlamadaki dört köşeli parıltı.
const _sparkleShape = 'M0 -10 Q2 -2 10 0 Q2 2 0 10 Q-2 2 -10 0 Q-2 -2 0 -10 Z';

class MascotPainter extends CustomPainter {
  const MascotPainter({required this.mood, required this.look});

  final MascotMood mood;
  final MascotLook look;

  bool get _happy => mood == MascotMood.happy;
  bool get _cheer => mood == MascotMood.cheer;
  bool get _calm => mood == MascotMood.calm;
  bool get _think => mood == MascotMood.think;
  bool _wears(Accessory a) => look.wears(a);

  @override
  void paint(Canvas canvas, Size size) {
    // 200 × 200'lük tasarım alanını istenen boyuta ölçekle.
    canvas.save();
    canvas.scale(size.width / 200, size.height / 200);

    _oval(canvas, 100, 186, 54, 6.5, Colors.black.withValues(alpha: 0.10));
    _drawArms(canvas);
    _drawBody(canvas);
    _drawEyes(canvas);
    _drawMouth(canvas);
    if (_wears(Accessory.atki)) _drawScarf(canvas);
    if (_wears(Accessory.gozluk)) _drawGlasses(canvas);
    if (_wears(Accessory.kulaklik)) _drawHeadphones(canvas);
    if (_wears(Accessory.kep)) _drawCapBack(canvas);
    _drawSprout(canvas);
    if (_wears(Accessory.kep)) _drawCapFront(canvas);
    if (_wears(Accessory.bere)) _drawBeanie(canvas);
    if (_wears(Accessory.tac)) _drawCrown(canvas);
    if (_think) _drawThinkDots(canvas);
    if (_cheer) _drawSparkles(canvas);

    canvas.restore();
  }

  // ---------- Gövde ----------

  /// Kollar (hepsi gövdenin ARKASINDA). Kutlamada havada, diğerlerinde
  /// yanlarda.
  void _drawArms(Canvas canvas) {
    if (_cheer) {
      final arm = _stroke(MascotColors.bodyDark, 17);
      canvas.drawPath(svgPath('M50 116 Q36 98 32 78'), arm);
      canvas.drawPath(svgPath('M150 116 Q164 98 168 78'), arm);
      _circle(canvas, 32, 72, 10.5, MascotColors.bodyDark);
      _circle(canvas, 168, 72, 10.5, MascotColors.bodyDark);
    } else {
      final arm = _stroke(MascotColors.bodyDark, 18);
      canvas.drawPath(svgPath('M48 128 Q38 140 32 150'), arm);
      canvas.drawPath(svgPath('M152 128 Q162 140 168 150'), arm);
    }
  }

  /// Ayaklar, gövde, parlaklık, karın, yanaklar.
  void _drawBody(Canvas canvas) {
    _oval(canvas, 76, 180, 16, 8, MascotColors.bodyDark);
    _oval(canvas, 124, 180, 16, 8, MascotColors.bodyDark);
    // Gövde: alttaki koyu ton (kenar/gölge), üstte asıl renk
    _oval(canvas, 100, 125, 67, 59, MascotColors.bodyDark);
    _oval(canvas, 100, 120, 67, 59, MascotColors.body);
    // Parlaklık (sol yan)
    _transformed(
      canvas,
      x: 54,
      y: 93,
      degrees: -56,
      draw: () {
        _oval(canvas, 0, 0, 11, 6, MascotColors.white.withValues(alpha: 0.28));
      },
    );
    _oval(canvas, 100, 146, 42, 30, MascotColors.belly);
    final cheek = MascotColors.cheek.withValues(alpha: 0.8);
    _oval(canvas, 55, 124, 10.5, 6.5, cheek);
    _oval(canvas, 145, 124, 10.5, 6.5, cheek);
  }

  // ---------- Yüz ----------

  /// Gözler. Güneş gözlüğü takılıyken açık gözler camın arkasında kalır,
  /// çizilmez. Sakin moddaki kapalı gözler her zaman çizilir (açık renkli
  /// camın arkasından görünür).
  void _drawEyes(Canvas canvas) {
    final glasses = _wears(Accessory.gozluk);
    if (!_calm && !glasses) {
      _circle(canvas, 78, 104, 16.5, MascotColors.white);
      _circle(canvas, 122, 104, 16.5, MascotColors.white);
    }
    if (_happy && !glasses) {
      // Göz bebekleri + iki parıltı
      _circle(canvas, 79, 105.5, 11, MascotColors.ink);
      _circle(canvas, 123, 105.5, 11, MascotColors.ink);
      _circle(canvas, 75, 101, 4.2, MascotColors.white);
      _circle(canvas, 119, 101, 4.2, MascotColors.white);
      _circle(canvas, 83, 109.5, 1.8, MascotColors.white);
      _circle(canvas, 127, 109.5, 1.8, MascotColors.white);
    }
    if (_cheer && !glasses) {
      // "Gülen gözler": büyük parıltı, alt kısmı gövde renginde kapakla örtülü
      _circle(canvas, 79, 105, 11, MascotColors.ink);
      _circle(canvas, 123, 105, 11, MascotColors.ink);
      _circle(canvas, 75, 100, 5, MascotColors.white);
      _circle(canvas, 119, 100, 5, MascotColors.white);
      _fill(
        canvas,
        'M63.8 113 Q78 103 92.2 113 A16.8 16.8 0 0 1 63.8 113 Z',
        MascotColors.body,
      );
      _fill(
        canvas,
        'M107.8 113 Q122 103 136.2 113 A16.8 16.8 0 0 1 107.8 113 Z',
        MascotColors.body,
      );
    }
    if (_think && !glasses) {
      // Gözler yukarı-sağa bakar
      _circle(canvas, 81, 99.5, 10.5, MascotColors.ink);
      _circle(canvas, 125, 99.5, 10.5, MascotColors.ink);
      _circle(canvas, 77.5, 95.5, 3.8, MascotColors.white);
      _circle(canvas, 121.5, 95.5, 3.8, MascotColors.white);
      _circle(canvas, 84.5, 103, 1.6, MascotColors.white);
      _circle(canvas, 128.5, 103, 1.6, MascotColors.white);
    }
    final hatOnBrows =
        _wears(Accessory.bere) ||
        _wears(Accessory.kep) ||
        _wears(Accessory.tac);
    if (_think && !hatOnBrows) {
      // Kaşlar: ikisi de yukarı kavisli (merak), sağdaki biraz daha yüksek.
      // Şapka ve taç kaşların yerini kapattığı için onlar takılıyken yok.
      final brow = _stroke(MascotColors.ink, 4.5);
      canvas.drawPath(svgPath('M67 80 Q78 72 89 79'), brow);
      canvas.drawPath(svgPath('M111 77 Q122 69 133 77'), brow);
    }
    if (_calm) {
      // Kapalı, huzurlu gözler
      final lid = _stroke(MascotColors.ink, 5.5);
      canvas.drawPath(svgPath('M65 107 Q78 96 91 107'), lid);
      canvas.drawPath(svgPath('M109 107 Q122 96 135 107'), lid);
    }
  }

  void _drawMouth(Canvas canvas) {
    switch (mood) {
      case MascotMood.happy:
        // Küçük açık gülüş
        _fill(
          canvas,
          'M88 124 Q100 127 112 124 Q111 139 100 139 Q89 139 88 124 Z',
          MascotColors.mouth,
        );
      case MascotMood.cheer:
        // Kocaman gülüş + dil
        _fill(
          canvas,
          'M81 122 Q100 126 119 122 Q117 144 100 144 Q83 144 81 122 Z',
          MascotColors.mouth,
        );
        _fill(
          canvas,
          'M90 138 Q100 131 110 138 Q100 144 90 138 Z',
          MascotColors.tongue,
        );
      case MascotMood.calm:
        // Yumuşak gülümseme
        canvas.drawPath(
          svgPath('M91 125 Q100 133 109 125'),
          _stroke(MascotColors.ink, 5),
        );
      case MascotMood.think:
        // Küçük, yana kaymış kapalı gülümseme
        canvas.drawPath(
          svgPath('M92 128 Q99 132 107 126'),
          _stroke(MascotColors.ink, 4.5),
        );
    }
  }

  // ---------- Aksesuarlar ----------

  /// Atkı: ağzın hemen altında, boyuna sarılı; solda sarkan uç. Kutlamada
  /// ağız aşağı uzadığı için biraz daha aşağıda.
  void _drawScarf(Canvas canvas) {
    if (_cheer) {
      _fill(
        canvas,
        'M39 141 Q100 161 161 141 L157 155 Q100 175 43 155 Z',
        MascotColors.blue,
      );
      _fill(
        canvas,
        'M43 155 Q100 175 157 155 L156 158 Q100 178 44 158 Z',
        MascotColors.blueDark,
      );
      _fill(canvas, 'M60 156 L78 159 L75 182 L57 179 Z', MascotColors.blue);
      _fill(
        canvas,
        'M58.7 166 L76.7 169 L76.2 173 L58.2 170 Z',
        MascotColors.blueLight,
      );
      _fill(
        canvas,
        'M57.9 174 L75.9 177 L75.5 181 L57.5 178 Z',
        MascotColors.blueLight,
      );
      _oval(canvas, 69, 156, 10, 7.5, MascotColors.blueDark);
    } else {
      _fill(
        canvas,
        'M38 133 Q100 155 162 133 L158 150 Q100 172 42 150 Z',
        MascotColors.blue,
      );
      _fill(
        canvas,
        'M42 150 Q100 172 158 150 L157 153 Q100 175 43 153 Z',
        MascotColors.blueDark,
      );
      // Sarkan uç (çizgili)
      _fill(canvas, 'M60 150 L78 153 L75 177 L57 174 Z', MascotColors.blue);
      _fill(
        canvas,
        'M58.7 160 L76.7 163 L76.2 167 L58.2 164 Z',
        MascotColors.blueLight,
      );
      _fill(
        canvas,
        'M57.9 168 L75.9 171 L75.5 175 L57.5 172 Z',
        MascotColors.blueLight,
      );
      // Düğüm
      _oval(canvas, 69, 150, 10, 7.5, MascotColors.blueDark);
    }
  }

  /// Güneş gözlüğü: renkli çerçeve, mavi cam. Sakin modda camlar AÇIK
  /// renkli; kapalı, huzurlu gözler arkadan görünür.
  void _drawGlasses(Canvas canvas) {
    final temple = _stroke(MascotColors.frame, 4);
    canvas.drawLine(const Offset(59, 100), const Offset(40, 97), temple);
    canvas.drawLine(const Offset(141, 100), const Offset(160, 97), temple);
    canvas.drawPath(svgPath('M96 100 Q100 96.5 104 100'), temple);
    final lens = _calm
        ? MascotColors.calmLens.withValues(alpha: 0.35)
        : MascotColors.blueDark.withValues(alpha: 0.9);
    for (final x in [59.0, 104.0]) {
      _roundRect(
        canvas,
        x,
        91,
        37,
        27,
        13,
        lens,
        stroke: MascotColors.frame,
        strokeWidth: 4,
      );
    }
    if (!_calm) {
      // Cam parlaması
      final glare = _stroke(MascotColors.white.withValues(alpha: 0.6), 3.5);
      canvas.drawPath(svgPath('M67 110 L76 97'), glare);
      canvas.drawPath(svgPath('M112 110 L121 97'), glare);
    }
  }

  /// Kulaklık: bant başa oturur (kepin ve filizin arkasında).
  void _drawHeadphones(Canvas canvas) {
    canvas.drawPath(
      svgPath('M36 96 A70 62 0 0 1 164 96'),
      _stroke(MascotColors.blue, 7),
    );
    _roundRect(canvas, 40, 92, 8, 24, 4, MascotColors.blueLight);
    _roundRect(canvas, 152, 92, 8, 24, 4, MascotColors.blueLight);
    _roundRect(canvas, 25, 88, 20, 32, 9, MascotColors.blue);
    _roundRect(canvas, 155, 88, 20, 32, 9, MascotColors.blue);
    final shine = MascotColors.white.withValues(alpha: 0.45);
    _oval(canvas, 31, 97, 2.5, 4, shine);
    _oval(canvas, 161, 97, 2.5, 4, shine);
  }

  /// Mezuniyet kepi, filizin ARKASINDAKİ kısım: başlık + tabla.
  void _drawCapBack(Canvas canvas) {
    _fill(
      canvas,
      'M62 60 L62 72 Q100 92 138 72 L138 60 Z',
      MascotColors.blueDeep,
    );
    _fill(
      canvas,
      'M48 58 L100 71 L152 58 L152 62 L100 75 L48 62 Z',
      MascotColors.blueDark,
    );
    _fill(canvas, 'M100 45 L152 58 L100 71 L48 58 Z', MascotColors.blue);
  }

  /// Kepin filizin ÖNÜNDEKİ kısmı: düğme + püskül.
  void _drawCapFront(Canvas canvas) {
    canvas.drawPath(
      svgPath('M100 58 L149 60 L149 74'),
      _stroke(MascotColors.gold, 2.5),
    );
    _roundRect(canvas, 145.5, 72, 7, 13, 3, MascotColors.gold);
    _circle(canvas, 100, 58, 4.5, MascotColors.gold);
  }

  /// Bere: filiz berenin tepesindeki delikten çıkar.
  void _drawBeanie(Canvas canvas) {
    _fill(
      canvas,
      'M60 73 C56 50 76 43 100 43 C124 43 144 50 140 73 Z',
      MascotColors.beanie,
    );
    _transformed(
      canvas,
      x: 80,
      y: 54,
      degrees: -30,
      draw: () {
        _oval(canvas, 0, 0, 10, 5, MascotColors.white.withValues(alpha: 0.25));
      },
    );
    _fill(
      canvas,
      'M60 70 Q100 62 140 70 L155 85 Q100 75 45 85 Z',
      MascotColors.beanieBand,
    );
    // Örgü çizgileri
    final knit = _stroke(MascotColors.beanieKnit.withValues(alpha: 0.6), 3.5);
    canvas.drawLine(const Offset(72, 70), const Offset(70, 79), knit);
    canvas.drawLine(const Offset(100, 68), const Offset(100, 77), knit);
    canvas.drawLine(const Offset(128, 70), const Offset(130, 79), knit);
    // Filizin çıktığı delik
    _oval(canvas, 100, 45.5, 6, 2.5, MascotColors.beanieBand);
  }

  /// Yaprak taç (7 günlük seri): altın yapraklar dala paralel, uçları yana
  /// bakar (yukarı sivri değil; alevi andırmasın).
  void _drawCrown(Canvas canvas) {
    canvas.drawPath(
      svgPath('M60 71 Q100 82 140 71'),
      _stroke(MascotColors.goldDark, 3.5),
    );
    // Her yaprak çifti: (x, y) noktasından sola ve sağa.
    const pairs = [(91.0, 76.2), (80.0, 75.1), (69.0, 73.2)];
    for (final (x, y) in pairs) {
      // Alt sıra (koyu altın, uçları yana ve hafif aşağı)
      _leaf(canvas, x, y, 162, 0.75, MascotColors.goldDark, scaleY: 0.55);
      _leaf(canvas, 200 - x, y, 18, 0.75, MascotColors.goldDark, scaleY: 0.55);
    }
    for (final (x, y) in pairs) {
      // Üst sıra (açık altın, uçları yana)
      _leaf(canvas, x, y, -152, 0.75, MascotColors.gold, scaleY: 0.55);
      _leaf(canvas, 200 - x, y, -28, 0.75, MascotColors.gold, scaleY: 0.55);
    }
    // Dalın uçlarında altın toplar, ortada taş
    _circle(canvas, 60, 71, 3, MascotColors.goldDark);
    _circle(canvas, 140, 71, 3, MascotColors.goldDark);
    _circle(canvas, 100, 76, 6.5, MascotColors.goldDark);
    _circle(canvas, 100, 76, 4.5, MascotColors.gold);
    _circle(
      canvas,
      98.5,
      74.5,
      1.6,
      MascotColors.white.withValues(alpha: 0.85),
    );
  }

  // ---------- Filiz (4 büyüme aşaması) ----------

  /// Başındaki filiz. Aşama sadece toplam puanla artar (bkz.
  /// logic/wardrobe.dart); asla küçülmez, asla solmaz.
  void _drawSprout(Canvas canvas) {
    switch (look.stage.clamp(1, 4)) {
      case 1:
        // Minik filiz, iki yaprak. Bere ya da kep takılıyken şapkanın
        // tepesinden görünsün diye biraz daha yukarıda.
        final hat = _wears(Accessory.bere) || _wears(Accessory.kep);
        final up = hat ? 8.0 : 0.0;
        canvas.drawPath(
          svgPath(hat ? 'M100 57 Q99 48 100 40' : 'M100 62 Q99 55 100 48'),
          _stroke(MascotColors.sproutDark, 5),
        );
        _leaf(canvas, 100, 49 - up, -155, 0.75, MascotColors.sproutDark);
        _leaf(canvas, 100, 49 - up, -25, 0.75, MascotColors.sprout);
      case 2:
        // Biraz büyümüş, 4 yaprak
        canvas.drawPath(
          svgPath('M100 62 Q98 50 100 40'),
          _stroke(MascotColors.sproutDark, 6),
        );
        _leaf(canvas, 99, 55, -168, 0.55, MascotColors.sproutDark);
        _leaf(canvas, 100, 52, -12, 0.6, MascotColors.sprout);
        _leaf(canvas, 100, 43, -150, 1, MascotColors.sproutDark);
        _leaf(canvas, 100, 41, -38, 1.4, MascotColors.sprout);
      case 3:
        _drawSaplingBase(canvas);
        // Tepede iki yaprak
        _leaf(canvas, 100, 28, -125, 0.95, MascotColors.sproutDark);
        _leaf(canvas, 100, 28, -62, 1.1, MascotColors.sprout);
      default:
        _drawSaplingBase(canvas);
        // Tepede beş yapraklı yuvarlak mor çiçek, altın göbek
        _leaf(canvas, 100, 34, -165, 0.6, MascotColors.sproutDark);
        _leaf(canvas, 100, 34, -15, 0.6, MascotColors.sprout);
        const petals = [
          (100.0, 16.0), (108.6, 22.2), (105.3, 32.3), (94.7, 32.3), //
          (91.4, 22.2),
        ];
        for (final (x, y) in petals) {
          _circle(canvas, x, y, 7.8, MascotColors.flower);
        }
        _circle(canvas, 100, 25, 6.5, MascotColors.gold);
        _circle(canvas, 98, 23, 2, MascotColors.white.withValues(alpha: 0.7));
    }
  }

  /// 3. ve 4. aşamanın ortak kısmı: uzun gövde ve iki dal.
  void _drawSaplingBase(Canvas canvas) {
    canvas.drawPath(
      svgPath('M100 62 C97 50 103 38 100 27'),
      _stroke(MascotColors.sproutDark, 6.5),
    );
    final branch = _stroke(MascotColors.sproutDark, 4);
    canvas.drawPath(svgPath('M100 50 Q91 47 85 40'), branch);
    canvas.drawPath(svgPath('M101 40 Q108 37 113 30'), branch);
    _leaf(canvas, 100, 56, -12, 0.55, MascotColors.sprout);
    _leaf(canvas, 100, 44, -172, 0.5, MascotColors.sproutDark);
    _leaf(canvas, 85, 40, -145, 1, MascotColors.sproutDark);
    _leaf(canvas, 113, 30, -35, 1, MascotColors.sprout);
  }

  // ---------- Ruh haline özel süsler ----------

  /// Düşünme noktaları (sağ üstte, küçükten büyüğe). Şapka takılıyken de
  /// görünür; düşündüğünü bunlar anlatır.
  void _drawThinkDots(Canvas canvas) {
    _circle(canvas, 156, 74, 3.5, MascotColors.blue);
    _circle(canvas, 166, 62, 5, MascotColors.blue);
    _circle(canvas, 178, 48, 6.5, MascotColors.blue);
  }

  /// Kutlama parıltıları (dört köşeli yıldız).
  void _drawSparkles(Canvas canvas) {
    const sparkles = [
      (22.0, 40.0, 0.8),
      (178.0, 42.0, 0.7),
      (160.0, 20.0, 0.5),
    ];
    for (final (x, y, scale) in sparkles) {
      _transformed(
        canvas,
        x: x,
        y: y,
        scale: scale,
        draw: () {
          _fill(canvas, _sparkleShape, MascotColors.gold);
        },
      );
    }
  }

  // ---------- Küçük çizim yardımcıları ----------

  void _fill(Canvas canvas, String d, Color color) =>
      canvas.drawPath(svgPath(d), Paint()..color = color);

  void _oval(
    Canvas canvas,
    double cx,
    double cy,
    double rx,
    double ry,
    Color color,
  ) => canvas.drawOval(
    Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
    Paint()..color = color,
  );

  void _circle(Canvas canvas, double cx, double cy, double r, Color color) =>
      canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color);

  void _roundRect(
    Canvas canvas,
    double x,
    double y,
    double width,
    double height,
    double radius,
    Color fill, {
    Color? stroke,
    double strokeWidth = 0,
  }) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, width, height),
      Radius.circular(radius),
    );
    canvas.drawRRect(rrect, Paint()..color = fill);
    if (stroke != null) canvas.drawRRect(rrect, _stroke(stroke, strokeWidth));
  }

  /// Uçları yuvarlak çizgi kalemi.
  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// SVG'deki transform="translate(x y) rotate(derece) scale(...)" karşılığı.
  void _transformed(
    Canvas canvas, {
    required double x,
    required double y,
    double degrees = 0,
    double scale = 1,
    double? scaleY,
    required void Function() draw,
  }) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(degrees * pi / 180);
    canvas.scale(scale, scaleY ?? scale);
    draw();
    canvas.restore();
  }

  /// Bir yaprak: (x, y) noktasından [degrees] yönüne, [scale] büyüklüğünde.
  void _leaf(
    Canvas canvas,
    double x,
    double y,
    double degrees,
    double scale,
    Color color, {
    double? scaleY,
  }) {
    _transformed(
      canvas,
      x: x,
      y: y,
      degrees: degrees,
      scale: scale,
      scaleY: scaleY,
      draw: () => _fill(canvas, _leafShape, color),
    );
  }

  @override
  bool shouldRepaint(MascotPainter old) => old.mood != mood || old.look != look;
}
