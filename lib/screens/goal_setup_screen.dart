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
enum _Step { percent, duration, quitDay, quitMethod, note }

/// Bırakma günü için hızlı seçenekler.
enum _QuitWhen {
  today('Bugün'),
  oneWeek('1 hafta sonra'),
  twoWeeks('2 hafta sonra'),
  oneMonth('1 ay sonra');

  const _QuitWhen(this.label);
  final String label;

  /// Bu seçeneğin tarihi ([today]: bugünün 00:00'ı).
  DateTime dateFrom(DateTime today) => switch (this) {
    _QuitWhen.today => today,
    _QuitWhen.oneWeek => addDays(today, 7),
    _QuitWhen.twoWeeks => addDays(today, 14),
    _QuitWhen.oneMonth => DateTime(today.year, today.month + 1, today.day),
  };
}

/// "Hedefini seç": ölçüm haftası bitince (ya da sonra Bugün'deki karttan)
/// açılır. Duolingo'daki günlük hedef seçimi gibi kısa bir akış:
/// 1. Ne kadar azaltmak istersin? (%25 / %50 / %75 / bırakmak)
/// 2. Azaltmada: ne kadar sürede? (sayı + hafta/ay; zorluğu hemen görünür)
///    Bırakmada: bırakma günün ne zaman? + o güne nasıl? (azaltarak / birden;
///    bırakma günü bugünse bu soru yok)
/// 3. Kendine not (sadece daha önce yazılmadıysa; isteğe bağlı)
///
/// Not yeni bir şey değil: erteleme ekranında çıkan "Kendine not" ile aynı.
/// Hedef koyarken "neden?" diye düşünmek için en doğal an olduğu için
/// burada da sorulur; ikinci bir not türü yok.
class GoalSetupScreen extends StatefulWidget {
  const GoalSetupScreen({super.key, required this.state, this.quit = false});

  final AppState state;

  /// "Bırakmak" seçili açılsın mı? (Hedefim'deki "BIRAKMA GÜNÜ SEÇ".)
  final bool quit;

  /// Akışı açar. [replace] true ise mevcut ekranın (ör. ölçüm özeti)
  /// yerine açılır. [quit] true ise "Bırakmak" seçili gelir.
  static Future<void> open(
    BuildContext context,
    AppState state, {
    bool replace = false,
    bool quit = false,
  }) {
    final route = MaterialPageRoute<void>(
      builder: (_) => GoalSetupScreen(state: state, quit: quit),
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
  late int? _percent = widget.quit ? 100 : _old?.percent;
  late int _amount = _old?.amount ?? suggestedWeeks(50);
  late GoalUnit _unit = _old?.unit ?? GoalUnit.week;

  /// Kullanıcı süreyi kendisi değiştirdi mi? Değiştirmediyse, yüzde
  /// değişince önerilen süre de değişir.
  late bool _amountTouched = _old != null && !_old.isQuit;

  /// Bugün (00:00).
  late final DateTime _today = startOfDay(state.now);

  /// Bırakma günü: eski bırakma hedefinin günü (geçmediyse), yoksa
  /// önerilen gün (2 hafta sonra; bkz. logic/goal.dart).
  late DateTime _quitDay = _initialQuitDay();

  /// Bırakma yolu. Bilerek önceden seçili değil (ikisi de geçerli bir yol).
  late QuitMethod? _method = _old != null && _old.isQuit
      ? _old.quitMethod
      : null;

  /// Not adımı: sadece akış başlarken not yoksa. Akış içinde sabit kalır
  /// (kaydederken not yazılınca adım listesi kısalıp ekran bozulmasın).
  late final bool _askNote = state.profile.reasonNote == null;

  bool get _quit => _percent == 100;
  bool get _quitToday => _quitDay == _today;

  /// Adımlar seçime göre değişir. Not adımı sadece henüz not yoksa.
  List<_Step> get _steps => [
    _Step.percent,
    if (_quit) ...[
      _Step.quitDay,
      // Bugün bırakıyorsan "o güne nasıl?" sorusunun anlamı yok.
      if (!_quitToday) _Step.quitMethod,
    ] else
      _Step.duration,
    if (_askNote) _Step.note,
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

  DateTime _initialQuitDay() {
    final old = _old;
    if (old != null && old.isQuit) {
      final day = quitDayOf(old);
      if (!day.isBefore(_today)) return day;
    }
    return addDays(_today, suggestedQuitDays);
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
    final reward = _quit
        ? await state.setGoal(
            percent: 100,
            quitDay: _quitDay,
            quitMethod: _method,
          )
        : await state.setGoal(percent: _percent!, amount: _amount, unit: _unit);
    final status = state.goalStatus;
    if (!mounted || status == null) return;
    await CelebrationScreen.show(
      context,
      reward,
      replace: true,
      title: _old == null ? 'Hedefin hazır!' : 'Hedefin güncellendi',
      message: _savedMessage(status),
    );
  }

  /// Kutlamadaki cümle.
  String _savedMessage(GoalStatus status) {
    if (!status.goal.isQuit) {
      return 'Bu hafta günde en fazla ${status.limit} sigara. Her küçük '
          'adımı birlikte kutlayacağız.';
    }
    if (status.daysToQuit == 0) {
      return 'Bugün bırakma günün. Ben yanındayım; zorlandığında “CANIM '
          'SİGARA İSTİYOR” butonu hep orada.';
    }
    final day = formatLongDate(quitDayOf(status.goal));
    final limit = status.limit;
    return limit == null
        ? 'Bırakma günün: $day. O güne kadar birlikte hazırlanacağız.'
        : 'Bırakma günün: $day. O güne kadar her hafta biraz azaltacağız; '
              'bu hafta günde en fazla $limit sigara.';
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
    // Yol seçilmeden ilerlenmez (önceden seçili değil).
    final waiting = _step == _Step.quitMethod && _method == null;
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
        onPressed: waiting ? null : _next,
      ),
    );
  }

  Widget _page(double baseline) {
    return switch (_step) {
      _Step.percent => _percentPage(baseline),
      _Step.duration => _durationPage(baseline),
      _Step.quitDay => _quitDayPage(),
      _Step.quitMethod => _quitMethodPage(),
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
              'Seçtiğin hedefe göre günlük bir sınır hesaplarım ve “Hedefim” '
              'sayfasında ne kadar ilerlediğini gösteririm. Bırakmak '
              'istersen bir bırakma günü seçersin. Hedefini istediğin zaman '
              'değiştirebilirsin; sınırın üstüne çıkmak puanını ya da '
              'serini asla bozmaz.',
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
        // (Bırakmada bu sayfa yok; yerine bırakma günü soruluyor.)
        MascotSpeech(
          text: '%$percent azaltmayı ne kadar sürede yapmak istersin?',
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

  // ---------- 2b. Bırakma günü ----------

  Future<void> _pickQuitDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _quitDay,
      firstDate: _today,
      lastDate: DateTime(_today.year, _today.month + 6, _today.day),
      helpText: 'Bırakma günün',
    );
    if (picked != null && mounted) {
      setState(() => _quitDay = startOfDay(picked));
    }
  }

  Widget _quitDayPage() {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    final days = daysBetween(_today, _quitDay);
    _QuitWhen? selected;
    for (final option in _QuitWhen.values) {
      if (option.dateFrom(_today) == _quitDay) selected = option;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        const MascotSpeech(
          text: 'Bırakma günün ne zaman olsun?',
          mood: MascotMood.think,
        ),
        const SizedBox(height: 6),
        const WhyToggle(
          text:
              'Bırakma gününe kadar günleri sayarım, o gün yanında olurum ve '
              'sonrasında sigarasız günlerini sayarım. Rehberler bu günü '
              'yakın seçmeyi öneriyor: en fazla bir iki hafta sonrası. '
              'Hazırlanmaya zaman kalır ama kararlılığın da azalmaz (ABD Ulusal '
              'Kanser Enstitüsü Smokefree; Avustralya Quit). Günü istediğin zaman '
              'değiştirebilirsin.',
        ),
        const SizedBox(height: 14),
        Center(
          child: ChipChoice<_QuitWhen>(
            options: _QuitWhen.values,
            selected: selected,
            labelOf: (o) => o.label,
            // Seçili olana tekrar dokunmak günü kaldırmasın.
            onChanged: (o) => setState(() {
              if (o != null) _quitDay = o.dateFrom(_today);
            }),
          ),
        ),
        const SizedBox(height: 16),
        ChunkyCard(
          color: c.mintLight,
          borderColor: c.mint,
          child: Row(
            children: [
              Icon(Icons.flag, color: c.mintText, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatLongDate(_quitDay),
                      style: theme.textTheme.titleLarge,
                    ),
                    Text(
                      days == 0 ? 'Bugün' : '$days gün sonra',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: c.mintText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: _pickQuitDay,
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('BAŞKA BİR GÜN SEÇ'),
          ),
        ),
        // Uzak bir tarih: uyarı değil, nazik bir bilgi (nötr renk).
        if (days > quitDayNoteAfterDays)
          Text(
            'Uzak bir tarih kararlılığını azaltabilir; rehberler genelde bir '
            'iki hafta içini öneriyor. Yine de karar senin.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: c.textMuted),
          ),
      ],
    );
  }

  // ---------- 2c. Bırakma gününe nasıl? ----------

  Widget _quitMethodPage() {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    // "Azaltarak" seçilirse bu haftanın sınırı ne olur? (Kullanıcının kendi
    // verisinden; aynı hesap Hedefim'de de kullanılır.)
    final preview = Goal(
      start: _today,
      baseline: state.baseline ?? 0,
      from: state.recentLevel,
      percent: 100,
      amount: 0,
      unit: GoalUnit.week,
      quitDay: _quitDay,
      quitMethod: QuitMethod.gradual,
    );
    final firstLimit = limitOn(preview, _today);

    String detail(QuitMethod method) => switch (method) {
      QuitMethod.gradual =>
        'Her hafta günlük sınır biraz iner, bırakma gününde 0 olur. Bu '
            'hafta günde en fazla $firstLimit sigara.',
      QuitMethod.abrupt =>
        'O güne kadar bir sınır yok; bırakma gününde birden bırakırsın.',
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        const MascotSpeech(
          text: 'Bırakma gününe nasıl gitmek istersin?',
          mood: MascotMood.think,
        ),
        const SizedBox(height: 6),
        const WhyToggle(
          text:
              'Seçimine göre günlük sınırları hesaplarım. İki yol da işe '
              'yarayabilir: araştırmaların derlemesi aralarında belirgin bir '
              'fark bulmadı (Cochrane, 2019). Bir çalışmada birden bırakanlar '
              'biraz daha başarılıydı; farkın çoğu, azaltanların bırakma '
              'gününde bırakmayı daha az denemesinden geliyordu '
              '(Lindson-Hawley ve ark., 2016). Hangisini seçersen seç, önemli '
              'olan o gün gerçekten denemek.',
        ),
        const SizedBox(height: 14),
        for (final method in QuitMethod.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SelectableBox(
              selected: method == _method,
              onTap: () => setState(() => _method = method),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.label),
                  const SizedBox(height: 2),
                  Text(
                    detail(method),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: method == _method ? c.blueText : c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
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
