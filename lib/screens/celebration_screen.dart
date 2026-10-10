import 'package:flutter/material.dart';

import '../logic/rewards.dart';
import '../models/activity_log.dart';
import '../services/effects.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/confetti.dart';
import '../widgets/mascot.dart';

/// Bir şey başarıldığında açılan tam ekran kutlama.
///
/// Konfeti yağar, maskot sevinir, XP sayarak artar ve seri uzadıysa alev
/// gösterilir. Bu, Duolingo'daki "ders bitti!" anının karşılığı: küçük ama
/// gerçek bir "başardım" hissi.
///
/// [calm] true ise konfeti yok, maskot sakin: zor anlarda (ör. erteleme
/// sonunda yine de sigara içildiyse) yine destekleyici ama abartısız.
class CelebrationScreen extends StatefulWidget {
  const CelebrationScreen({
    super.key,
    required this.reward,
    this.calm = false,
    this.title,
    this.message,
  });

  final Reward reward;
  final bool calm;
  final String? title;
  final String? message;

  /// Kutlama ekranını açar; kapanınca geri döner.
  /// [replace] true ise mevcut ekranın (ör. nefes egzersizi) yerine açılır.
  static Future<void> show(
    BuildContext context,
    Reward reward, {
    bool calm = false,
    bool replace = false,
    String? title,
    String? message,
  }) async {
    final route = PageRouteBuilder<void>(
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => CelebrationScreen(
        reward: reward,
        calm: calm,
        title: title,
        message: message,
      ),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(animation),
          child: child,
        ),
      ),
    );
    final navigator = Navigator.of(context);
    await (replace ? navigator.pushReplacement(route) : navigator.push(route));
  }

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen> {
  @override
  void initState() {
    super.initState();
    // Ses + titreşim: büyük başarıda "fanfar", görevde "ding-ding",
    // zor anlarda yumuşak bir çan.
    final big =
        reward.has(XpReason.allQuests) ||
        reward.has(XpReason.delaySuccess) ||
        reward.has(XpReason.welcome);
    Effects.celebrate(big: big, calm: widget.calm);
  }

  Reward get reward => widget.reward;

  String get _title {
    if (widget.title != null) return widget.title!;
    if (reward.has(XpReason.allQuests)) return 'Günün görevleri tamam!';
    if (reward.has(XpReason.delaySuccess)) return 'Başardın!';
    if (reward.has(XpReason.welcome)) return 'Yolculuk başladı!';
    return 'Görev tamamlandı!';
  }

  String get _message {
    if (widget.message != null) return widget.message!;
    if (reward.has(XpReason.allQuests)) {
      return 'Bugün kendine çok iyi baktın. Yarın yeni görevler seni bekliyor.';
    }
    if (reward.has(XpReason.delaySuccess)) {
      return 'İsteği erteledin ve geçmesine izin verdin. Bu gerçek bir güç!';
    }
    if (reward.has(XpReason.questTag)) {
      return 'Nedenini fark etmek, alışkanlığı değiştirmenin ilk adımı.';
    }
    if (reward.has(XpReason.questBreathe)) {
      return 'Kendine bir dakika ayırdın. Çok iyi!';
    }
    return 'Her küçük adım sayılır. Böyle devam!';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                // Küçük ekranda / büyük yazıda sığmazsa kaydırılabilsin;
                // sığıyorsa içerik ekranı doldurup ortalansın.
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 36,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const Spacer(),
                            Mascot(
                              mood: widget.calm
                                  ? MascotMood.calm
                                  : MascotMood.cheer,
                              size: 160,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: widget.calm ? c.blueText : c.greenText,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _message,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: c.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                if (reward.totalXp > 0)
                                  Expanded(
                                    child: _RewardTile(
                                      label: 'KAZANILAN XP',
                                      color: c.gold,
                                      icon: Icons.bolt,
                                      child: TweenAnimationBuilder<int>(
                                        tween: IntTween(
                                          begin: 0,
                                          end: reward.totalXp,
                                        ),
                                        duration: const Duration(
                                          milliseconds: 900,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        builder: (_, value, _) =>
                                            Text('+$value'),
                                      ),
                                    ),
                                  ),
                                if (reward.streakExtended) ...[
                                  if (reward.totalXp > 0)
                                    const SizedBox(width: 12),
                                  Expanded(
                                    child: _RewardTile(
                                      label: 'SERİ',
                                      color: c.orange,
                                      icon: Icons.local_fire_department,
                                      child: Text('${reward.streak} gün'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),
                            for (final gain in reward.gains)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '${gain.reason.label}  +${gain.amount} XP',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: c.textMuted,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            ChunkyButton(
                              label: 'DEVAM',
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!widget.calm) const Positioned.fill(child: ConfettiBurst()),
        ],
      ),
    );
  }
}

/// Renkli başlıklı ödül kutucuğu (Duolingo'nun ders sonu kutucukları gibi).
class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.label,
    required this.color,
    required this.icon,
    required this.child,
  });

  final String label;
  final Color color;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: appFontFamily,
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(width: 4),
                DefaultTextStyle(
                  style: TextStyle(
                    fontFamily: appFontFamily,
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
