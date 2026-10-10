import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../logic/quests.dart';
import '../models/activity_log.dart';
import '../models/user_profile.dart';
import '../services/effects.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/mascot.dart';
import 'breathing_screen.dart';
import 'celebration_screen.dart';

/// "Canım sigara istiyor" → 10 dakikalık erteleme.
///
/// Fikir: Sigara isteği gelip geçer. Birlikte 10 dakika bekleyelim, sonra
/// karar senin. İki sonuç da ödüllü:
/// - "İSTEK GEÇTİ" → büyük kutlama.
/// - "YİNE DE İÇECEĞİM" → suçlama yok; beklediğin süre ve fark etmen takdir
///   edilir, küçük bir XP verilir.
///
/// Ekrandan çıkarsan sayaç durmaz; ana ekrandan geri dönebilirsin.
class DelayScreen extends StatefulWidget {
  const DelayScreen({super.key, required this.state});

  final AppState state;

  @override
  State<DelayScreen> createState() => _DelayScreenState();
}

class _DelayScreenState extends State<DelayScreen> {
  Timer? _ticker;
  int _tipIndex = 0;
  bool _finishing = false;

  /// "Süre doldu" zili çaldı mı? (Bir kez çalsın.)
  bool _bellRung = false;

  AppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    if (state.activeDelayStart == null) state.startDelay();
    _tipIndex = Random().nextInt(_tips(state.profile).length);
    // Her saniye ekranı yenile (geri sayım için).
    // Ekran açıldığında süre zaten dolmuşsa zil tekrar çalmasın.
    _bellRung = _timeIsUp();
    // Her saniye ekranı yenile (geri sayım için); süre dolunca zil çal.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_bellRung && _timeIsUp()) {
        _bellRung = true;
        Effects.timerDone();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// 10 dakika doldu mu?
  bool _timeIsUp() {
    final start = state.activeDelayStart ?? state.now;
    return state.now.difference(start) >= const Duration(minutes: delayMinutes);
  }

  Future<void> _finish(DelayOutcome outcome) async {
    if (_finishing) return;
    _finishing = true;
    final start = state.activeDelayStart ?? state.now;
    final minutes = state.now.difference(start).inMinutes;
    final reward = await state.finishDelay(outcome);
    if (!mounted) return;

    if (outcome == DelayOutcome.success) {
      await CelebrationScreen.show(
        context,
        reward,
        replace: true,
        title: 'Başardın!',
        message: minutes >= delayMinutes
            ? '$delayMinutes dakika bekledin ve istek geçti. Bu gerçek bir güç!'
            : 'İstek geçti! Kendini dinledin ve erteledin.',
      );
    } else {
      await CelebrationScreen.show(
        context,
        reward,
        replace: true,
        calm: true,
        title: 'Sorun değil',
        message: minutes >= 1
            ? '$minutes dakika bekledin ve isteğini fark ettin. Bu da bir '
                  'adım. Bir dahaki sefere yine buradayım.'
            : 'İsteğini fark edip durdun ve düşündün. Bu da bir adım. '
                  'Bir dahaki sefere yine buradayım.',
      );
    }
  }

  Future<void> _cancel() async {
    await state.cancelDelay();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    final start = state.activeDelayStart ?? state.now;
    const total = Duration(minutes: delayMinutes);
    final elapsed = state.now.difference(start);
    final remaining = elapsed >= total ? Duration.zero : total - elapsed;
    final done = remaining == Duration.zero;
    final progress = (elapsed.inSeconds / total.inSeconds).clamp(0.0, 1.0);
    final tips = _tips(state.profile);

    final minutesText = remaining.inMinutes.toString().padLeft(2, '0');
    final secondsText = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: const Text('İsteği ertele'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Kapat (sayaç devam eder)',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                MascotSpeech(
                  text: done
                      ? '$delayMinutes dakika doldu! Harika iş çıkardın. '
                            'İstek geçti mi?'
                      : 'Bu istek geçici. Birlikte $delayMinutes dakika '
                            'bekleyelim, sonra karar senin.',
                  mood: done ? MascotMood.cheer : MascotMood.calm,
                  mascotSize: 76,
                ),
                const SizedBox(height: 20),
                // Geri sayım halkası
                Center(
                  child: SizedBox.square(
                    dimension: 210,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: progress,
                        track: c.disabled,
                        fill: done ? c.mint : c.blue,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              done ? 'Tamam!' : '$minutesText:$secondsText',
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: done ? c.mintText : c.blueText,
                              ),
                            ),
                            if (!done)
                              Text(
                                'kaldı',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: c.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Bu sırada ne yapabilirim?
                ChunkyCard(
                  color: c.blueLight,
                  borderColor: c.blue,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: c.blueText),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bu sırada şunu dene',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: c.blueText,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(
                              () => _tipIndex = (_tipIndex + 1) % tips.length,
                            ),
                            child: const Text('BAŞKA ÖNERİ'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tips[_tipIndex % tips.length],
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ChunkyButton(
                  label: 'NEFES EGZERSİZİ YAP',
                  icon: Icons.air,
                  variant: ChunkyVariant.secondary,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BreathingScreen(state: state),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ChunkyButton(
                  label: 'İSTEK GEÇTİ',
                  icon: Icons.check_circle_outline,
                  onPressed: () => _finish(DelayOutcome.success),
                ),
                const SizedBox(height: 10),
                ChunkyButton(
                  label: 'YİNE DE İÇECEĞİM',
                  variant: ChunkyVariant.secondary,
                  onPressed: () => _finish(DelayOutcome.gaveIn),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _cancel,
                    child: const Text('Yanlışlıkla başlattım'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Erteleme sırasında önerilen somut eylemler (sayısal iddia yok).
/// Kullanıcının sevdiği aktivitelere göre biraz kişiselleşir.
List<String> _tips(UserProfile profile) {
  final likesMoving = profile.activities.any(
    (a) =>
        a == Activity.walking ||
        a == Activity.running ||
        a == Activity.hiking ||
        a == Activity.cycling,
  );
  return [
    'Bir bardak su iç.',
    likesMoving
        ? 'Kısa bir yürüyüşe çık. Hareket etmeyi seviyorsun!'
        : 'Kalk ve birkaç dakika yürü.',
    'Birine mesaj at ya da birini ara.',
    'Ellerini meşgul et: bir şey karala ya da bir şeyi düzenle.',
    'Sakız çiğne ya da bir meyve ye.',
    'Ortamı değiştir: başka bir odaya ya da dışarı çık.',
  ];
}

/// Geri sayım halkası: gri iz + dolan renkli yay.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.fill,
  });

  final double progress;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, 2 * pi, false, base);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -pi / 2, // en üstten başla
        2 * pi * progress,
        false,
        base
          ..color = fill
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.fill != fill || old.track != track;
}
