import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/mascot.dart';
import 'onboarding_screen.dart';
import 'settings_screen.dart';

/// "Profil" sekmesi: seri, puan ve başarılar. Sadece OLUMLU sayılar.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final c = AppColors.of(context);
        final theme = Theme.of(context);
        final streak = state.streak;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Profil', style: theme.textTheme.headlineSmall),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SettingsScreen(state: state),
                    ),
                  ),
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Ayarlar',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Mascot(
                mood: streak.activeToday ? MascotMood.cheer : MascotMood.happy,
                size: 130,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              streak.current > 0
                  ? '${streak.current} günlük serin var!'
                  : 'Bugün bir görev yap, serin başlasın!',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            // İki sıra hâlinde 4 kutu. Kutular içeriğe göre uzar; büyük yazı
            // boyutunda da taşmaz (sabit oranlı ızgara yerine).
            _StatRow(
              left: _StatBox(
                icon: streakIcon,
                color: c.leaf,
                value: '${streak.current}',
                label: 'Günlük seri',
              ),
              right: _StatBox(
                icon: Icons.emoji_events_outlined,
                color: c.purple,
                value: '${streak.best}',
                label: 'En uzun seri',
              ),
            ),
            const SizedBox(height: 12),
            _StatRow(
              left: _StatBox(
                icon: Icons.bolt,
                color: c.gold,
                value: '${state.totalXp}',
                label: 'Toplam puan',
              ),
              right: _StatBox(
                icon: Icons.timer_outlined,
                color: c.blue,
                value: '${state.successfulDelays}',
                label: 'Ertelenen istek',
              ),
            ),
            const SizedBox(height: 16),
            ChunkyCard(
              color: c.leafLight,
              borderColor: c.leaf,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(streakIcon, color: c.leaf, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Seri nasıl işler? Bir gün en az bir görev yaparsan '
                      'serin bir gün uzar. Sigara içmek serini BOZMAZ; seri, '
                      'kendine iyi baktığın günleri sayar. Haftada bir gün '
                      'kaçırırsan da serin korunur (dinlenme günü).',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ChunkyButton(
              label: 'BİLGİLERİMİ DÜZENLE',
              icon: Icons.edit_outlined,
              variant: ChunkyVariant.secondary,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      OnboardingScreen(state: state, editMode: true),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Yan yana iki kutu; ikisi de aynı yükseklikte.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.left, required this.right});
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 12),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    return ChunkyCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 6),
              // Sayı çok büyürse (ör. 12.500 puan) yazı küçülsün, taşmasın.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: theme.textTheme.headlineSmall),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
