// Alttan açılan seçim pencereleri: ruh hali ve sigara nedeni.

import 'package:flutter/material.dart';

import '../models/activity_log.dart';
import '../models/smoking_event.dart';
import '../models/user_profile.dart';
import '../services/effects.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'chunky.dart';

/// Beş ruh hali butonu yan yana: soldan sağa olumsuzdan olumluya ("Çok zor"
/// en solda, "Harika" en sağda; sıra [Mood] enum'unda). [selected] doluysa o
/// vurgulanır.
class MoodRow extends StatelessWidget {
  const MoodRow({super.key, required this.onSelected, this.selected});

  final ValueChanged<Mood> onSelected;
  final Mood? selected;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // IntrinsicHeight + stretch: tüm kutular aynı yükseklikte olsun.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final mood in Mood.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Semantics(
                  button: true,
                  selected: mood == selected,
                  label: mood.label,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Effects.select();
                      onSelected(mood);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: mood == selected ? c.blueLight : c.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: mood == selected ? c.blue : c.border,
                          width: 2,
                        ),
                      ),
                      child: ExcludeSemantics(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              mood.icon,
                              size: 32,
                              color: mood.isHard ? c.purple : c.gold,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mood.label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ruh hali penceresi. Seçilen ruh halini döndürür (vazgeçilirse null).
Future<Mood?> showMoodSheet(BuildContext context) {
  return showModalBottomSheet<Mood>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bugün nasıl hissediyorsun?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            MoodRow(onSelected: (m) => Navigator.of(context).pop(m)),
          ],
        ),
      ),
    ),
  );
}

/// Neden penceresinin sonucu. ([trigger] null ise neden kaldırıldı.)
class TriggerChoice {
  const TriggerChoice(this.trigger);
  final SmokingTrigger? trigger;
}

/// "Bu sigara neden?" penceresi. Vazgeçilirse null döner.
///
/// [preferred]: kullanıcının onboarding'de seçtiği tetikleyiciler. Bunlar
/// listenin EN BAŞINDA çıkar; çoğu zaman tek dokunuşla işaretlenir.
Future<TriggerChoice?> showTriggerSheet(
  BuildContext context,
  SmokingEvent event, {
  Set<SmokingTrigger> preferred = const {},
}) {
  final ordered = triggersInOrder(preferred);
  return showModalBottomSheet<TriggerChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final c = AppColors.of(context);
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bu sigara neden?', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Saat ${formatClock(event.time)}. Doğru ya da yanlış cevap '
                'yok; sadece fark etmek için.',
                style: theme.textTheme.bodyMedium?.copyWith(color: c.textMuted),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: [
                  for (final t in ordered)
                    ChoiceChip(
                      label: Text(t.label),
                      selected: event.trigger == t,
                      showCheckmark: false,
                      side: BorderSide(
                        color: event.trigger == t ? c.blue : c.border,
                        width: 2,
                      ),
                      selectedColor: c.blueLight,
                      labelStyle: theme.textTheme.labelLarge?.copyWith(
                        color: event.trigger == t ? c.blueText : c.text,
                      ),
                      onSelected: (_) {
                        Effects.select();
                        Navigator.of(context).pop(TriggerChoice(t));
                      },
                    ),
                ],
              ),
              if (event.trigger != null) ...[
                const SizedBox(height: 16),
                ChunkyButton(
                  label: 'NEDENİ KALDIR',
                  variant: ChunkyVariant.secondary,
                  onPressed: () =>
                      Navigator.of(context).pop(const TriggerChoice(null)),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// Önce kullanıcının seçtiği tetikleyiciler, sonra diğerleri (her grup kendi
/// içinde her zamanki sırada).
List<SmokingTrigger> triggersInOrder(Set<SmokingTrigger> preferred) => [
  for (final t in SmokingTrigger.values)
    if (preferred.contains(t)) t,
  for (final t in SmokingTrigger.values)
    if (!preferred.contains(t)) t,
];
