import 'package:flutter/material.dart';

import '../app_state.dart';
import '../logic/wardrobe.dart';
import '../models/mascot_look.dart';
import '../services/effects.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/mascot.dart';

/// "Nefes'in dolabı": başındaki filizin büyümesi ve puanla açılan eşyalar.
///
/// Puan HARCANMAZ: eşyalar belli puanlarda ya da anlamlı anlarda açılır,
/// açılan eşya bir daha kaybolmaz (kurallar: logic/wardrobe.dart). Bu
/// ekran sadece Profil'den açılır.
class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nefes\'in dolabı')),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final c = AppColors.of(context);
          final theme = Theme.of(context);
          final look = state.mascotLook;
          final unlocked = state.unlockedAccessories;
          final tiles = [
            for (final a in Accessory.values)
              _AccessoryTile(
                accessory: a,
                stage: look.stage,
                worn: look.wears(a),
                unlocked: unlocked.contains(a),
                lockedText: _lockedText(a),
                onTap: () {
                  Effects.select();
                  state.toggleOutfit(a);
                },
              ),
          ];

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // Görünüş açıkça verilir ki takıp çıkarınca maskot zıplasın.
                  Center(child: Mascot(size: 150, look: look)),
                  const SizedBox(height: 4),
                  Text(
                    'Toplam puanın: ${state.totalXp}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: c.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _GrowthCard(totalXp: state.totalXp),
                  const SizedBox(height: 24),
                  Text('Eşyalar', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Açılan eşyaya dokunarak tak ya da çıkar. Aynı anda bir '
                    'şapka (bere, kep, taç ya da kulaklık), bir gözlük ve bir '
                    'atkı takılabilir.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: c.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // İkişerli sıralar; kutular içeriğe göre uzar (büyük yazı
                  // boyutunda da taşmasın diye sabit oranlı ızgara yok).
                  for (var i = 0; i < tiles.length; i += 2) ...[
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: tiles[i]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: i + 1 < tiles.length
                                ? tiles[i + 1]
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 4),
                  // Bilgi notu: mavi (yaprak yeşili sadece seri ve filiz için).
                  ChunkyCard(
                    color: c.blueLight,
                    borderColor: c.blue,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_open_rounded,
                          color: c.blueText,
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Puan harcanmaz: eşya açmak puanını azaltmaz. '
                            'Açılan eşya kaybolmaz; sigara içmek hiçbir şeyi '
                            'kilitlemez. Filiz de sadece puanla büyür, asla '
                            'küçülmez. (Ayarlar\'dan kayıtlarını sıfırlarsan '
                            'puanlarla birlikte dolap da baştan başlar.)',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Kilitli eşyanın altında yazacak: "250 puan · 120 kaldı" gibi.
  String _lockedText(Accessory a) {
    final rule = unlockRules[a]!;
    final points = rule.points;
    if (points != null) {
      return '${rule.label} · ${points - state.totalXp} kaldı';
    }
    if (rule.streakDays != null) {
      return '${rule.label} · en uzun serin ${state.streak.best} gün';
    }
    return rule.label;
  }
}

/// Filizin büyümesi: aşama + sonraki aşamaya ilerleme çubuğu.
class _GrowthCard extends StatelessWidget {
  const _GrowthCard({required this.totalXp});

  final int totalXp;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    final stage = sproutStage(totalXp);
    final left = pointsToNextStage(totalXp);
    // Bu aşamanın başından sonraki aşamaya kadar ne kadar ilerlendi?
    final double progress;
    if (left == null) {
      progress = 1;
    } else {
      final from = sproutStagePoints[stage - 1];
      final to = sproutStagePoints[stage];
      progress = (totalXp - from) / (to - from);
    }

    return ChunkyCard(
      child: Row(
        children: [
          Icon(streakIcon, color: c.leaf, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filiz: $stage. aşama ($maxSproutStage aşamadan)',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ChunkyProgressBar(value: progress, height: 12, color: c.leaf),
                const SizedBox(height: 6),
                Text(
                  left == null
                      ? 'Filiz çiçek açtı! En son aşamadasın.'
                      : '${stage + 1}. aşamaya $left puan kaldı',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dolaptaki tek bir eşya: önizleme + adı + durumu (takılı / tak / kilitli).
class _AccessoryTile extends StatelessWidget {
  const _AccessoryTile({
    required this.accessory,
    required this.stage,
    required this.worn,
    required this.unlocked,
    required this.lockedText,
    required this.onTap,
  });

  final Accessory accessory;
  final int stage;
  final bool worn;
  final bool unlocked;
  final String lockedText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);

    // Önizleme: Nefes bu eşyayı tek başına takmış hâliyle.
    final preview = Mascot(
      size: 84,
      look: MascotLook(stage: stage, accessories: {accessory}),
    );

    // Ekran okuyucunun söyleyeceği durum.
    final spoken = worn
        ? 'takılı'
        : unlocked
        ? 'açık'
        : 'kilitli, $lockedText';

    final (IconData icon, String status, Color color) = worn
        ? (Icons.check_circle, 'Takılı', c.mintText)
        : unlocked
        ? (Icons.add_circle_outline, 'Tak', c.blueText)
        : (Icons.lock_outline, lockedText, c.textMuted);

    // excludeSemantics içerideki dokunmayı da gizlediği için dokunma eylemi
    // burada ayrıca veriliyor (ekran okuyucuyla da takılabilsin).
    // container: yan yana iki kart ekran okuyucuda tek öğeye birleşmesin.
    return Semantics(
      container: true,
      button: unlocked,
      selected: worn,
      onTap: unlocked ? onTap : null,
      label: '${accessory.label}: $spoken',
      excludeSemantics: true,
      child: ChunkyCard(
        onTap: unlocked ? onTap : null,
        color: worn ? c.mintLight : null,
        borderColor: worn ? c.mint : null,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        child: Column(
          children: [
            // Kilitli eşyalar soluk görünür ama görünür: neyin geleceğini
            // bilmek motive eder.
            Opacity(opacity: unlocked ? 1 : 0.4, child: preview),
            const SizedBox(height: 6),
            Text(
              accessory.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    status,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
