import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Ekranın üstünden yağan renkli konfeti (kutlama anları için).
///
/// Paket kullanmadan yazdık: her konfeti parçası rastgele bir konumdan
/// başlar, yerçekimiyle düşer, sağa sola salınır ve döner.
/// Telefonda "animasyonları azalt" ayarı açıksa hiç gösterilmez.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.count = 90});

  /// Kaç parça konfeti?
  final int count;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 2800);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  )..forward();

  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _pieces = List.generate(widget.count, (_) => _Piece.random(random));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return const SizedBox.shrink();
    }
    final c = AppColors.of(context);
    final palette = [c.mint, c.blue, c.gold, c.leaf, c.purple];
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(
            pieces: _pieces,
            progress: _controller,
            palette: palette,
            seconds: _duration.inMilliseconds / 1000,
          ),
        ),
      ),
    );
  }
}

/// Tek bir konfeti parçasının başlangıç değerleri.
class _Piece {
  _Piece.random(Random r)
    : x = r.nextDouble(),
      y = -0.05 - r.nextDouble() * 0.35,
      speedX = (r.nextDouble() - 0.5) * 0.25,
      speedY = 0.25 + r.nextDouble() * 0.35,
      spin = (r.nextDouble() - 0.5) * 12,
      sway = r.nextDouble() * 2 * pi,
      size = 6 + r.nextDouble() * 7,
      colorIndex = r.nextInt(5),
      round = r.nextBool();

  final double x, y; // ekran oranı cinsinden (0–1)
  final double speedX, speedY; // saniyede ekran oranı
  final double spin, sway, size;
  final int colorIndex;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.pieces,
    required this.progress,
    required this.palette,
    required this.seconds,
  }) : super(repaint: progress);

  final List<_Piece> pieces;
  final Animation<double> progress;
  final List<Color> palette;
  final double seconds;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value * seconds; // geçen süre (saniye)
    // Son %25'lik kısımda yavaşça kaybol
    final fade = progress.value < 0.75 ? 1.0 : (1 - progress.value) / 0.25;

    for (final p in pieces) {
      final x = (p.x + p.speedX * t + 0.03 * sin(t * 3 + p.sway)) * size.width;
      final y = (p.y + p.speedY * t + 0.12 * t * t) * size.height;
      if (y > size.height + 20) continue;
      final paint = Paint()
        ..color = palette[p.colorIndex].withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size * 0.4, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.5,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
