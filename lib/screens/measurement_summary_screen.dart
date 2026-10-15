import 'package:flutter/material.dart';

import '../app_state.dart';
import '../logic/quests.dart';
import '../logic/wardrobe.dart';
import '../models/mascot_look.dart';
import '../services/effects.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/chunky.dart';
import '../widgets/confetti.dart';
import '../widgets/mascot.dart';
import '../widgets/stat_tile.dart';
import 'goal_setup_screen.dart';

/// "Ölçüm haftan bitti!" ekranı.
///
/// İlk 7 günün kısa özeti: günde ortalama, ilk sigara saati, en yoğun saat,
/// en sık neden. Sadece kullanıcının KENDİ verisi; yorum ya da yargı yok
/// ("doğru ya da yanlış yok, bu senin başlangıç noktan").
///
/// Aynı zamanda "kademeli açılım" anı: ölçüm haftasından sonra açılan
/// özellikleri (erteleme görevi, "Kazandıkların", haftalık raporlar) burada
/// haber veririz. Bu özet, aynı zamanda 1. haftanın raporudur (İstatistik →
/// "Haftalık raporların" listesinde 1. hafta).
/// Böylece ilk gün her şey birden ekrana dökülmez.
///
/// İlk seferde en altta "HEDEFİMİ SEÇ" çıkar: hedef sorusu, cevabının
/// kullanılacağı ana (başlangıç noktası belli olduğunda) konur. Seçmemek
/// de serbest ("ŞİMDİLİK GEÇ"); sonra Bugün'deki karttan seçilebilir.
class MeasurementSummaryScreen extends StatefulWidget {
  const MeasurementSummaryScreen({super.key, required this.state});

  final AppState state;

  @override
  State<MeasurementSummaryScreen> createState() =>
      _MeasurementSummaryScreenState();
}

class _MeasurementSummaryScreenState extends State<MeasurementSummaryScreen> {
  AppState get state => widget.state;

  /// İlk kez mi görülüyor? Kutlama (konfeti + fanfar) sadece ilk seferde;
  /// İstatistik'ten tekrar açılınca sakin bir özet.
  late final bool _firstTime = state.measurementSummaryPending;

  @override
  void initState() {
    super.initState();
    // Bu ekran bir dokunuşla açılır; ses izni sorunu yok.
    if (_firstTime) Effects.celebrate(big: true);
  }

  /// Kep takılmış görünüş (DEVAM'da olacak olanın önizlemesi).
  MascotLook _withCap(MascotLook look) =>
      look.copyWith(accessories: wearCap(look.accessories));

  Future<void> _done() async {
    await state.markMeasurementSummarySeen();
    if (mounted) Navigator.of(context).pop();
  }

  /// Özet görüldü; hedef seçme akışı bu ekranın yerine açılır.
  Future<void> _chooseGoal() async {
    await state.markMeasurementSummarySeen();
    if (mounted) await GoalSetupScreen.open(context, state, replace: true);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    final summary = state.measurementSummary;
    final profile = state.profile;
    final estimate = profile.cigarettesPerDay;
    final firstAnswer = profile.firstCigarette;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Kapat',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    Center(
                      // İlk seferde Nefes mezuniyet kepini takmış görünür
                      // (DEVAM'a basınca gerçekten takılır).
                      child: Mascot(
                        mood: MascotMood.cheer,
                        size: 120,
                        look: _firstTime ? _withCap(state.mascotLook) : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ölçüm haftan bitti!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: c.mintText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$measurementDays gün boyunca seni tanıdım. İşte kılıfın '
                      'gördükleri. Doğru ya da yanlış yok; bu senin başlangıç '
                      'noktan.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: c.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (summary != null) ...[
                      StatTile(
                        icon: Icons.today_outlined,
                        color: c.blue,
                        title: 'Günde ortalama',
                        value: '${formatDecimal(summary.dailyAverage)} sigara',
                        footnote: estimate == null
                            ? null
                            : 'Başta günde ~$estimate demiştin.',
                      ),
                      if (summary.averageFirstMinute != null) ...[
                        const SizedBox(height: 12),
                        StatTile(
                          icon: Icons.wb_twilight,
                          color: c.gold,
                          title: 'Günün ilk sigarası (ortalama)',
                          value: formatMinuteOfDay(summary.averageFirstMinute!),
                          footnote: firstAnswer == null
                              ? null
                              : 'Uyanınca ilk sigara için '
                                    '“${firstAnswer.label}” demiştin.',
                        ),
                      ],
                      if (summary.peakHour != null) ...[
                        const SizedBox(height: 12),
                        StatTile(
                          icon: Icons.schedule,
                          color: c.purple,
                          title: 'En yoğun saatin',
                          value: formatHourRange(summary.peakHour!),
                        ),
                      ],
                      const SizedBox(height: 12),
                      StatTile(
                        icon: Icons.label_outline,
                        color: c.mint,
                        title: 'En sık neden',
                        value: summary.topTrigger?.label ?? '—',
                        footnote: summary.topTrigger == null
                            ? 'Bu hafta hiç neden işaretlemedin. İstersen '
                                  'sigaraların yanındaki "Neden?" ile '
                                  'işaretleyebilirsin.'
                            : '${summary.topTriggerCount} kez işaretledin.',
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text('Neler açıldı?', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 10),
                    ChunkyCard(
                      color: c.mintLight,
                      borderColor: c.mint,
                      child: Column(
                        children: [
                          _Unlocked(
                            icon: Icons.timer_outlined,
                            text:
                                'Günlük görevlere “İsteği ertele” eklendi: '
                                'bir isteği $delayMinutes dakika bekletmeyi '
                                'deneyebilirsin.',
                          ),
                          const SizedBox(height: 12),
                          const _Unlocked(
                            icon: Icons.savings_outlined,
                            text:
                                'İstatistik’te “Kazandıkların” açıldı: bu '
                                'ortalamanın altında kaldıkça içmediğin '
                                'sigaralar ve cebinde kalan para birikir.',
                          ),
                          const SizedBox(height: 12),
                          const _Unlocked(
                            icon: Icons.event_note_outlined,
                            text:
                                'Her hafta bitince kısa bir haftalık rapor '
                                'gelecek: örüntün, kendine iyi baktığın '
                                'anlar ve gelecek hafta için bir fikir. Bir '
                                'hafta sonra İstatistik’in en üstünde '
                                '“Başladığından beri” kartı da açılacak.',
                          ),
                          const SizedBox(height: 12),
                          const _Unlocked(
                            icon: Icons.school_outlined,
                            text:
                                'Nefes’in dolabına mezuniyet kepi geldi: '
                                'ölçüm haftasını bitirmenin hatırası.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // İlk seferde: başlangıç noktan belli, şimdi istersen
                    // bir hedef seç. (Özet sonradan açılınca sadece DEVAM.)
                    if (_firstTime && state.goal == null) ...[
                      Text(
                        'Şimdi istersen bir hedef seç: ne kadar azaltacağına '
                        've ne kadar sürede yapacağına sen karar ver.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      ChunkyButton(
                        label: 'HEDEFİMİ SEÇ',
                        icon: Icons.flag_outlined,
                        onPressed: _chooseGoal,
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: _done,
                          child: const Text('ŞİMDİLİK GEÇ'),
                        ),
                      ),
                    ] else
                      ChunkyButton(label: 'DEVAM', onPressed: _done),
                  ],
                ),
              ),
            ),
          ),
          // Konfeti dokunuşları engellemesin.
          if (_firstTime)
            const Positioned.fill(child: IgnorePointer(child: ConfettiBurst())),
        ],
      ),
    );
  }
}

/// "Neler açıldı?" kartındaki tek satır.
class _Unlocked extends StatelessWidget {
  const _Unlocked({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: c.mintText, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
