import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/format.dart';
import 'chunky.dart';

/// "Son sigarandan beri" sayacı (Bugün sekmesinde).
///
/// - 24 saatten az: saat / dakika / saniye (her saniye ilerler).
/// - 24 saat ve fazlası: gün / saat / dakika.
///
/// Süreyi kendimiz saymıyoruz; her saniye "şimdi − son sigara" farkını
/// yeniden hesaplıyoruz. Böylece uygulama arka planda kalsa ya da telefon
/// kilitlense bile sayaç hep doğru gösterir.
///
/// Kural (SPEC Bölüm 3): Bu bir seri DEĞİLDİR. Yeni bir sigara gelince sayaç
/// sessizce sıfırdan başlar: mesaj, ses, titreşim ya da renk değişimi yok;
/// puan vermez, rekor tutmaz.
class SinceLastCounter extends StatefulWidget {
  const SinceLastCounter({super.key, required this.last, required this.clock});

  /// Son sigaranın zamanı.
  final DateTime last;

  /// Şu anki zamanı verir (uygulamada `state.now`, testlerde sahte saat).
  final DateTime Function() clock;

  @override
  State<SinceLastCounter> createState() => _SinceLastCounterState();
}

class _SinceLastCounterState extends State<SinceLastCounter> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Her saniye yeniden çiz. (24 saatten sonra sayı dakikada bir değişir;
    // yine de her saniye bakmak hem basit hem de çok ucuz.)
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    final parts = sinceCounterParts(widget.clock().difference(widget.last));
    final spoken = parts.map((p) => '${p.value} ${p.unit}').join(' ');

    // Ekran okuyucu "02", "14" gibi kutuları tek tek okumasın; tek cümle
    // olarak okusun: "Son sigarandan beri 2 saat 14 dakika 5 saniye".
    return Semantics(
      label: 'Son sigarandan beri $spoken',
      excludeSemantics: true,
      child: ChunkyCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.hourglass_bottom_rounded,
                  color: c.mintText,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Son sigarandan beri',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < parts.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _PartBox(part: parts[i])),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Sayacın bir kutusu: büyük sayı + altında birimi.
class _PartBox extends StatelessWidget {
  const _PartBox({required this.part});
  final CounterPart part;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: c.mintLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // FittedBox: çok büyük sayı (ör. 1000 gün) ya da büyük yazı
          // boyutunda kutudan taşmasın, biraz küçülsün.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              part.text,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: c.mintText,
                fontWeight: FontWeight.w900,
                height: 1.1,
                // Rakamlar eşit genişlikte olsun, saniye değişirken titremesin.
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              part.unit,
              style: theme.textTheme.labelMedium?.copyWith(color: c.mintText),
            ),
          ),
        ],
      ),
    );
  }
}
