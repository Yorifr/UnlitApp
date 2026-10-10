// Uygulamanın maskotu: "Nefes".
//
// Başında küçük, yeşil bir filiz olan yuvarlak, nane renkli bir karakter. Resim dosyası
// yok; tamamen kodla (CustomPainter) çiziliyor, bu yüzden her boyutta net.
//
// Kural: Nefes ASLA üzgün, kızgın ya da hayal kırıklığına uğramış
// görünmez. Kullanıcıyı suçlamak yok; sadece neşeli, sakin ya da düşünceli.

import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Maskotun adı. Ekip değiştirmek isterse sadece burayı değiştirsin.
const String mascotName = 'Nefes';

/// Maskotun ruh hali (yüz ifadesi).
enum MascotMood {
  /// Gülümsüyor (varsayılan).
  happy,

  /// Kollar havada, ağzı açık: kutlama.
  cheer,

  /// Gözler kapalı, huzurlu: nefes egzersizi, zor anlar.
  calm,

  /// Düşünüyor: soru sorarken.
  think,
}

/// Maskot. Ekrana gelince küçük bir zıplama animasyonu yapar.
class Mascot extends StatefulWidget {
  const Mascot({super.key, this.mood = MascotMood.happy, this.size = 96});

  final MascotMood mood;
  final double size;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void didUpdateWidget(Mascot old) {
    super.didUpdateWidget(old);
    // Ruh hali değişince tekrar zıpla.
    if (old.mood != widget.mood) _bounce.forward(from: 0);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      label: 'Maskot $mascotName',
      child: AnimatedBuilder(
        animation: _bounce,
        builder: (context, child) {
          // 0.85'ten 1.0'a "esneyerek" büyü.
          final scale =
              0.85 + 0.15 * Curves.elasticOut.transform(_bounce.value);
          return Transform.scale(scale: scale, child: child);
        },
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _MascotPainter(widget.mood, c),
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  _MascotPainter(this.mood, this.colors);

  final MascotMood mood;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width; // Tüm ölçüler boyuta göre oranlı
    Paint fill(Color color) => Paint()..color = color;

    // Maskotun kendi renkleri (açık ve koyu temada aynı).
    const body = Color(0xFF2EC4B6); // Nane gövde
    const bodyDark = Color(0xFF1A9C90);
    const belly = Color(0xFFC9F3EC);
    const sprout = Color(0xFF6BCB3B); // Filiz yeşili: büyümeyi anlatır
    const sproutDark = Color(0xFF4AA32A);
    const ink = Color(0xFF233A3A);

    // Yerdeki gölge
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.5, s * 0.93),
        width: s * 0.55,
        height: s * 0.07,
      ),
      fill(Colors.black.withValues(alpha: 0.10)),
    );

    // Ayaklar
    for (final x in [0.38, 0.62]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s * x, s * 0.88),
          width: s * 0.16,
          height: s * 0.08,
        ),
        fill(bodyDark),
      );
    }

    // Kollar (kutlamada havada)
    final armUp = mood == MascotMood.cheer;
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(s * (0.5 + side * 0.33), s * (armUp ? 0.42 : 0.62));
      canvas.rotate(side * (armUp ? -0.7 : 0.5));
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: s * 0.11, height: s * 0.22),
        fill(bodyDark),
      );
      canvas.restore();
    }

    // Gövde
    final bodyRect = Rect.fromCenter(
      center: Offset(s * 0.5, s * 0.58),
      width: s * 0.70,
      height: s * 0.64,
    );
    canvas.drawOval(bodyRect.shift(Offset(0, s * 0.025)), fill(bodyDark));
    canvas.drawOval(bodyRect, fill(body));

    // Karın
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.5, s * 0.70),
        width: s * 0.40,
        height: s * 0.30,
      ),
      fill(belly),
    );

    // Başındaki filiz: sap + iki yaprak
    final stem = Paint()
      ..color = sproutDark
      ..strokeWidth = s * 0.03
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(s * 0.5, s * 0.28), Offset(s * 0.5, s * 0.17), stem);
    _leaf(canvas, Offset(s * 0.5, s * 0.18), s * 0.15, -0.6, fill(sprout));
    _leaf(
      canvas,
      Offset(s * 0.5, s * 0.20),
      s * 0.12,
      pi + 0.5,
      fill(sproutDark),
    );

    // Yanaklar
    for (final x in [0.29, 0.71]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s * x, s * 0.60),
          width: s * 0.10,
          height: s * 0.06,
        ),
        fill(const Color(0xFFFF9EAA).withValues(alpha: 0.7)),
      );
    }

    // Gözler
    final eyeY = s * 0.49;
    for (final x in [0.38, 0.62]) {
      final center = Offset(s * x, eyeY);
      if (mood == MascotMood.calm) {
        // Kapalı, gülen gözler: "^ ^"
        final path = Path()
          ..moveTo(center.dx - s * 0.06, center.dy + s * 0.01)
          ..quadraticBezierTo(
            center.dx,
            center.dy - s * 0.06,
            center.dx + s * 0.06,
            center.dy + s * 0.01,
          );
        canvas.drawPath(
          path,
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.03
            ..strokeCap = StrokeCap.round,
        );
      } else {
        canvas.drawCircle(center, s * 0.085, fill(Colors.white));
        // Düşünürken gözler yukarı bakar
        final look = mood == MascotMood.think
            ? Offset(s * 0.015, -s * 0.025)
            : Offset(s * 0.01, s * 0.01);
        canvas.drawCircle(center + look, s * 0.05, fill(ink));
        canvas.drawCircle(
          center + look + Offset(-s * 0.018, -s * 0.018),
          s * 0.016,
          fill(Colors.white),
        );
      }
    }

    // Ağız
    final mouthCenter = Offset(s * 0.5, s * 0.60);
    switch (mood) {
      case MascotMood.cheer:
        // Kocaman açık gülüş
        final mouth = Path()
          ..moveTo(mouthCenter.dx - s * 0.09, mouthCenter.dy - s * 0.01)
          ..quadraticBezierTo(
            mouthCenter.dx,
            mouthCenter.dy + s * 0.14,
            mouthCenter.dx + s * 0.09,
            mouthCenter.dy - s * 0.01,
          )
          ..close();
        canvas.drawPath(mouth, fill(const Color(0xFF8A2E3B)));
        canvas.drawOval(
          Rect.fromCenter(
            center: mouthCenter + Offset(0, s * 0.045),
            width: s * 0.08,
            height: s * 0.04,
          ),
          fill(const Color(0xFFFF8A9A)),
        );
      case MascotMood.think:
        canvas.drawCircle(
          mouthCenter + Offset(s * 0.02, s * 0.02),
          s * 0.025,
          fill(ink),
        );
      case MascotMood.happy:
      case MascotMood.calm:
        final smile = Path()
          ..moveTo(mouthCenter.dx - s * 0.07, mouthCenter.dy)
          ..quadraticBezierTo(
            mouthCenter.dx,
            mouthCenter.dy + s * 0.07,
            mouthCenter.dx + s * 0.07,
            mouthCenter.dy,
          );
        canvas.drawPath(
          smile,
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.03
            ..strokeCap = StrokeCap.round,
        );
    }
  }

  /// Bir yaprak çizer: [base] noktasından [angle] yönüne doğru.
  void _leaf(Canvas canvas, Offset base, double length, double angle, Paint p) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.5, -length * 0.45, length, 0)
      ..quadraticBezierTo(length * 0.5, length * 0.45, 0, 0);
    canvas.drawPath(path, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MascotPainter old) =>
      old.mood != mood || old.colors != colors;
}

/// Maskot + konuşma balonu.
class MascotSpeech extends StatelessWidget {
  const MascotSpeech({
    super.key,
    required this.text,
    this.mood = MascotMood.happy,
    this.mascotSize = 84,
  });

  final String text;
  final MascotMood mood;
  final double mascotSize;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final style = Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.w700, height: 1.3);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Mascot(mood: mood, size: mascotSize),
        const SizedBox(width: 6),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.border, width: 2),
                ),
                child: Text(text, style: style),
              ),
              // Balonun maskota bakan küçük "kuyruğu"
              Positioned(
                left: -7,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Transform.rotate(
                    angle: pi / 4,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: c.surface,
                        border: Border(
                          left: BorderSide(color: c.border, width: 2),
                          bottom: BorderSide(color: c.border, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
