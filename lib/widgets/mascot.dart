// Uygulamanın maskotu: "Nefes" (Nefes 2.0).
//
// Nane renkli, yuvarlak bir karakter; başındaki filiz kullanıcı puan
// topladıkça büyür (4 aşama) ve "Nefes'in dolabı"ndan açılan eşyaları
// takabilir. Resim dosyası yok; tamamen kodla çiziliyor (bkz.
// mascot_painter.dart, tasarım: docs/maskot/1-nefes-2.svg), bu yüzden her
// boyutta net.
//
// Kural: Nefes ASLA üzgün, kızgın ya da hayal kırıklığına uğramış
// görünmez. Kullanıcıyı suçlamak yok; sadece neşeli, sakin ya da düşünceli.

import 'dart:math';

import 'package:flutter/material.dart';

import '../models/mascot_look.dart';
import '../theme.dart';
import 'mascot_painter.dart';

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

  /// Düşünüyor: soru sorarken (gözler yukarıda, yanında üç nokta).
  think,
}

/// Uygulamanın her yerindeki maskota "şu an nasıl göründüğünü" (filiz aşaması,
/// takılı eşyalar) söyler. Uygulamanın kökünde bir kez konur (bkz. app.dart);
/// böylece her ekrana ayrıca bilgi geçirmek gerekmez.
class MascotAppearance extends InheritedWidget {
  const MascotAppearance({super.key, required this.look, required super.child});

  final MascotLook look;

  /// En yakın görünüş; yoksa sade görünüş.
  static MascotLook of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MascotAppearance>()?.look ??
      MascotLook.plain;

  @override
  bool updateShouldNotify(MascotAppearance old) => old.look != look;
}

/// Maskot. Ekrana gelince (ya da ruh hali/görünüşü değişince) küçük bir
/// zıplama animasyonu yapar.
///
/// [look] verilmezse uygulamanın şu anki görünüşü kullanılır
/// ([MascotAppearance]); dolap ekranında bir eşyayı önizlemek için
/// verilebilir.
class Mascot extends StatefulWidget {
  const Mascot({
    super.key,
    this.mood = MascotMood.happy,
    this.size = 96,
    this.look,
  });

  final MascotMood mood;
  final double size;
  final MascotLook? look;

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
    // Ruh hali ya da görünüş değişince tekrar zıpla.
    if (old.mood != widget.mood || old.look != widget.look) {
      _bounce.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final look = widget.look ?? MascotAppearance.of(context);
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
          painter: MascotPainter(mood: widget.mood, look: look),
        ),
      ),
    );
  }
}

/// Maskot + konuşma balonu.
class MascotSpeech extends StatelessWidget {
  const MascotSpeech({
    super.key,
    required this.text,
    this.mood = MascotMood.happy,
    this.mascotSize = 84,
    this.mascotScale = 1,
  });

  final String text;
  final MascotMood mood;
  final double mascotSize;

  /// Maskotun gövdesini ayaklarının hizasından büyütür/küçültür. Nefes
  /// egzersizinde "seninle nefes alıyor" hissi için (1.00 – 1.06).
  final double mascotScale;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final style = Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.w700, height: 1.3);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Transform.scale(
          scale: mascotScale,
          alignment: Alignment.bottomCenter,
          child: Mascot(mood: mood, size: mascotSize),
        ),
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
