import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/mascot.dart';
import 'celebration_screen.dart';

/// Yaklaşık 1 dakikalık nefes egzersizi.
///
/// Daire 4 saniyede büyür ("Nefes al"), 4 saniyede küçülür ("Nefes ver").
/// 6 tur = 48 saniye. Bitince "Nefes molası" görevi tamamlanır.
/// İstediğin an çıkabilirsin; yarım bırakmanın hiçbir cezası yok.
class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key, required this.state});

  final AppState state;

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  static const int rounds = 6;
  static const int secondsPerHalf = 4; // 4 sn al + 4 sn ver

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: rounds * secondsPerHalf * 2),
  )..addStatusListener(_onStatus);

  bool _started = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    setState(() => _started = true);
    _controller.forward(from: 0);
  }

  Future<void> _onStatus(AnimationStatus status) async {
    if (status != AnimationStatus.completed) return;
    final reward = await widget.state.logBreathing();
    if (!mounted) return;
    // Bu ekranın yerine kutlamayı aç.
    await CelebrationScreen.show(
      context,
      reward,
      replace: true,
      title: 'Nefes molası tamam!',
      message: 'Kendine bir dakika ayırdın. Çok iyi!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nefes molası'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Kapat',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              // Şu an hangi turdayız, nefes mi alıyoruz veriyor muyuz?
              final elapsed = _controller.value * rounds * secondsPerHalf * 2;
              final round = (elapsed ~/ (secondsPerHalf * 2)) + 1;
              final inRound = elapsed % (secondsPerHalf * 2);
              final inhale = inRound < secondsPerHalf;
              final half = inhale
                  ? inRound / secondsPerHalf
                  : (inRound - secondsPerHalf) / secondsPerHalf;
              final eased = Curves.easeInOut.transform(half.clamp(0.0, 1.0));
              final scale = !_started
                  ? 0.7
                  : inhale
                  ? 0.6 + 0.4 * eased
                  : 1.0 - 0.4 * eased;

              return Column(
                children: [
                  MascotSpeech(
                    text: _started
                        ? 'Daireyi takip et. Ben de seninle nefes alıyorum.'
                        : 'Rahat bir yere otur. Hazır olunca başlayalım.',
                    mood: MascotMood.calm,
                    mascotSize: 72,
                  ),
                  Expanded(
                    child: Center(
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            color: c.blueLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.blue, width: 6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            !_started
                                ? 'Hazır mısın?'
                                : inhale
                                ? 'Nefes al'
                                : 'Nefes ver',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: c.blueText,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_started) ...[
                    Text(
                      'Tur ${round.clamp(1, rounds)} / $rounds',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    ChunkyProgressBar(value: _controller.value, color: c.blue),
                  ] else
                    ChunkyButton(
                      label: 'BAŞLA',
                      variant: ChunkyVariant.blue,
                      onPressed: _start,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
