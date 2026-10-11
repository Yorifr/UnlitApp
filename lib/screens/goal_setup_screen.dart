import 'package:flutter/material.dart';

import '../app_state.dart';
import '../logic/goal.dart';
import '../logic/stats.dart';
import '../models/goal.dart';
import '../models/user_profile.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/chunky.dart';
import '../widgets/mascot.dart';
import '../widgets/onboarding_inputs.dart';
import '../widgets/reason_note.dart';
import 'celebration_screen.dart';

/// Hedef seçme akışının adımları. Onboarding gibi: her ekranda TEK soru.
enum _Step { percent, duration, note }

/// "Hedefini seç": ölçüm haftası bitince (ya da sonra Bugün'deki karttan)
/// açılır. Duolingo'daki günlük hedef seçimi gibi kısa bir akış:
/// 1. Ne kadar azaltmak istersin? (%25 / %50 / %75 / bırakmak)
/// 2. Ne kadar sürede? (sayı + hafta/ay; zorluğu hemen görünür)
/// 3. Kendine not (sadece daha önce yazılmadıysa; isteğe bağlı)
///
/// Not yeni bir şey değil: erteleme ekranında çıkan "Kendine not" ile aynı.
/// Hedef koyarken "neden?" diye düşünmek için en doğal an olduğu için
/// burada da sorulur; ikinci bir not türü yok.
class GoalSetupScreen extends StatefulWidget {
  const GoalSetupScreen({super.key, required this.state});

  final AppState state;

  /// Akışı açar. [replace] true ise mevcut ekranın (ör. ölçüm özeti)
  /// yerine açılır.
  static Future<void> open(
    BuildContext context,
    AppState state, {
    bool replace = false,
  }) {
    final route = MaterialPageRoute<void>(
      builder: (_) => GoalSetupScreen(state: state),
    );
    final navigator = Navigator.of(context);
    return replace ? navigator.pushReplacement(route) : navigator.push(route);
  }

  @override
  State<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends State<GoalSetupScreen> {
  AppState get state => widget.state;

  /// Hedef değiştiriliyorsa eski seçimler hazır gelir.
  late final Goal? _old = state.goal;
  late int? _percent = _old?.percent;
  late int _amount = _old?.amount ?? suggestedWeeks(50);
  late GoalUnit _unit = _old?.unit ?? GoalUnit.week;

  /// Kullanıcı süreyi kendisi değiştirdi mi? Değiştirmediyse, yüzde
  /// değişince önerilen süre de değişir.
  late bool _amountTouched = _old != null;

  /// Not adımı sadece henüz not yoksa gösterilir.
  late final List<_Step> _steps = [
    _Step.percent,
    _Step.duration,
    if (state.profile.reasonNote == null) _Step.note,
  ];
  int _index = 0;
  final _note = TextEditingController();
  bool _saving = false;

  _Step get _step => _steps[_index];
  bool get _isLast => _index == _steps.length - 1;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _choosePercent(int? percent) => setState(() {
    _percent = percent;
    if (percent != null && !_amountTouched) {
      _unit = GoalUnit.week;
      _amount = suggestedWeeks(percent);
    }
  });

  void _next() {
    // Yüzde seçilmeden "ŞİMDİLİK GEÇ": hedef koymadan kapat.
    if (_step == _Step.percent && _percent == null) {
      Navigator.of(context).pop();
      return;
    }
    if (_isLast) {
      _save();
    } else {
      FocusScope.of(context).unfocus();
      setState(() => _index++);
    }
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_index > 0) {
      setState(() => _index--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    _saving = true;
    if (_steps.contains(_Step.note) && _note.text.trim().isNotEmpty) {
      await state.setReasonNote(_note.text);
    }
    final reward = await state.setGoal(
      percent: _percent!,
      amount: _amount,
      unit: _unit,
    );
    final status = state.goalStatus;
    if (!mounted || status == null) return;
    await CelebrationScreen.show(
      context,
      reward,
      replace: true,
      title: _old == null ? 'Hedefin hazır!' : 'Hedefin güncellendi',
      message:
          'Bu hafta günde en fazla ${status.limit} sigara. Her küçük adımı '
          'birlikte kutlayacağız.',
    );
  }

  // ---------- Ekran ----------

  @override
  Widget build(BuildContext context) {
    final baseline = state.baseline;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: baseline == null
                // Ölçüm haftasında kayıt yoksa hedefin dayanacağı bir sayı
                // yok (bu ekran normalde o durumda açılmaz).
                ? const Center(child: Text('Önce ölçüm haftası bitmeli.'))
                : Column(
                    children: [
                      _topBar(),
                      Expanded(child: _page(baseline)),
                      _bottomBar(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 20, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: _back,
            icon: Icon(_index == 0 ? Icons.close : Icons.arrow_back),
            tooltip: _index == 0 ? 'Kapat' : 'Geri',
          ),
          Expanded(
            child: Semantics(
              label: 'Adım ${_index + 1} / ${_steps.length}',
              child: ChunkyProgressBar(value: (_index + 1) / _steps.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final skip = _step == _Step.percent && _percent == null;
    String label;
    if (skip) {
      label = 'ŞİMDİLİK GEÇ';
    } else if (_isLast) {
      label = 'HEDEFİMİ KAYDET';
    } else {
      label = 'DEVAM';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: ChunkyButton(
        label: label,
        variant: skip ? ChunkyVariant.secondary : ChunkyVariant.primary,
        onPressed: _next,
      ),
    );
  }

  Widget _page(double baseline) {
    return switch (_step) {
      _Step.percent => _percentPage(baseline),
      _Step.duration => _durationPage(baseline),
      _Step.note => _notePage(),
    };
  }

  // ---------- 1. Ne kadar? ----------

  Widget _percentPage(double baseline) {
    final c = AppColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        MascotSpeech(
          text:
              'Ölçüm haftanda günde ortalama ${formatDecimal(baseline)} '
              'sigara içtin. Ne kadar azaltmak istersin?',
          mood: MascotMood.think,
        ),
        const SizedBox(height: 6),
        const WhyToggle(
          text:
              'Seçtiğin hedefe göre her hafta için günlük bir sınır '
              'hesaplarım ve “Hedefim” sayfasında ne kadar ilerlediğini '
              'gösteririm. Hedefini istediğin zaman değiştirebilirsin; '
              'sınırın üstüne çıkmak puanını ya da serini asla bozmaz.',
        ),
        const SizedBox(height: 14),
        for (final percent in goalPercents)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SelectableBox(
              selected: percent == _percent,
              onTap: () => _choosePercent(percent == _percent ? null : percent),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      percent == 100 ? 'Bırakmak' : '%$percent azaltmak',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'günde ${goalTarget(baseline, percent)}',
                    style: TextStyle(
                      color: percent == _percent ? c.blueText : c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ---------- 2. Ne kadar sürede? ----------

  Widget _durationPage(double baseline) {
    final theme = Theme.of(context);
    final percent = _percent ?? 50;
    final start = startOfDay(state.now);
    final end = goalEndFrom(start, _amount, _unit);
    final steps = goalStepCount(start, end);
    final target = goalTarget(baseline, percent);
    final from = state.recentLevel;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        MascotSpeech(
          text: percent == 100
              ? 'Ne kadar sürede bırakmak istersin?'
              : '%$percent azaltmayı ne kadar sürede yapmak istersin?',
          mood: MascotMood.think,
        ),
        const SizedBox(height: 20),
        NumberStepper(
          value: _amount,
          min: 1,
          max: _unit.max,
          startValue: _amount,
          unit: _unit.label,
          onChanged: (v) => setState(() {
            _amount = v;
            _amountTouched = true;
          }),
        ),
        const SizedBox(height: 14),
        Center(
          child: ChipChoice<GoalUnit>(
            options: GoalUnit.values,
            selected: _unit,
            labelOf: (u) => u == GoalUnit.week ? 'Hafta' : 'Ay',
            // Seçili olana tekrar dokunmak birimi kaldırmasın.
            onChanged: (u) => setState(() {
              _unit = u ?? _unit;
              _amount = _amount.clamp(1, _unit.max);
              _amountTouched = true;
            }),
          ),
        ),
        const SizedBox(height: 20),
        _PaceCard(
          pace: goalPace(percent, start, end),
          text: _paceText(from, target, steps),
          end: end,
        ),
        const SizedBox(height: 10),
        Text(
          'Haftalık sınırlar şu anki seviyenden başlayıp her hafta biraz '
          'iner; son hafta hedefine ulaşır.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.of(context).textMuted,
          ),
        ),
      ],
    );
  }

  /// Seçilen hızın somut anlamı: "Her hafta günde yaklaşık 2 sigara".
  /// Sayı kullanıcının kendi verisinden hesaplanır.
  String _paceText(double from, int target, int steps) {
    if (from <= target) {
      return 'Zaten bu seviyedesin; hedefin orada kalmak.';
    }
    if (steps == 1) {
      return 'Bir haftada hedefe geçmek demek: günde en fazla $target.';
    }
    final perWeek = reductionPerWeek(from, target, steps);
    if (perWeek < 1) return 'Her hafta günde 1 sigaradan az azaltmak demek.';
    return 'Her hafta günde yaklaşık ${perWeek.round()} sigara azaltmak '
        'demek.';
  }

  // ---------- 3. Kendine not ----------

  Widget _notePage() {
    final c = AppColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        const MascotSpeech(
          text: 'Son olarak: bu hedef senin için neden önemli?',
          mood: MascotMood.think,
        ),
        const SizedBox(height: 10),
        Text(
          'İstersen kendi cümlenle yaz; canın sigara istediğinde erteleme '
          'ekranında karşına çıkar. Boş bırakabilirsin.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: c.textMuted),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _note,
          minLines: 2,
          maxLines: 4,
          maxLength: UserProfile.maxNoteLength,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          // Sadece yazı tipinde olan harfler (emoji web'de dış istek yapar).
          inputFormatters: [noteInputFormatter],
          decoration: const InputDecoration(
            hintText: 'Örn. Kızımla parkta koşabilmek istiyorum.',
          ),
        ),
      ],
    );
  }
}

/// Seçilen sürenin zorluğu: 4 çubuk + etiket + somut anlamı + bitiş günü.
class _PaceCard extends StatelessWidget {
  const _PaceCard({required this.pace, required this.text, required this.end});

  final GoalPace pace;
  final String text;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    return ChunkyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Zorluk',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: c.textMuted,
                  ),
                ),
              ),
              // Dolu çubuk sayısı = zorluk (1–4). Kırmızı yok: zorluk bir
              // uyarı değil, bilgi.
              for (var i = 1; i <= GoalPace.values.length; i++)
                Container(
                  width: 10,
                  height: 8.0 + i * 4,
                  margin: const EdgeInsets.only(left: 3),
                  decoration: BoxDecoration(
                    color: i <= pace.level ? c.blue : c.disabled,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              const SizedBox(width: 10),
              Text(
                pace.label,
                style: theme.textTheme.titleMedium?.copyWith(color: c.blueText),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Bitiş: ${formatDayMonth(end)}',
            style: theme.textTheme.bodySmall?.copyWith(color: c.textMuted),
          ),
          if (pace == GoalPace.veryAmbitious) ...[
            const SizedBox(height: 6),
            Text(
              'Hızlı bir hedef. Zorlanırsan süreyi sonra uzatabilirsin.',
              style: theme.textTheme.bodySmall?.copyWith(color: c.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
