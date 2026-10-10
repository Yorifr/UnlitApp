import 'package:flutter/material.dart';

import '../app_state.dart';
import '../logic/rewards.dart';
import '../models/user_profile.dart';
import '../services/effects.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/chunky.dart';
import '../widgets/confetti.dart';
import '../widgets/mascot.dart';
import '../widgets/onboarding_inputs.dart';
import '../widgets/privacy_banner.dart';

/// Onboarding'in adımları. Duolingo gibi: her ekranda TEK soru.
enum OnboardingStep {
  welcome,
  cigarettesPerDay,
  yearsSmoking,
  firstCigarette,
  packPrice,
  triggers,
  goal,
  quitDesire,
  ageRange,
  gender,
  motivators,
  activities,
  done;

  /// Soru sayfası mı? (Karşılama ve bitiş değil.)
  bool get isQuestion => this != welcome && this != done;

  /// İsteğe bağlı profil bölümünde mi? ("Bu bölümü atla" çıkar.)
  bool get isOptionalProfile =>
      index >= ageRange.index && index <= activities.index;
}

/// İlk açılıştaki kısa soru akışı. Her şey isteğe bağlı ve atlanabilir.
///
/// [editMode] true ise (Profil/Ayarlar > Bilgilerimi düzenle) karşılama ve
/// bitiş sayfaları gösterilmez; "KAYDET" ile geri dönülür. Paket fiyatı
/// düzenleme modunda YOKTUR: fiyatın kendi yeri var (İstatistik → Paket
/// fiyatı), çünkü tarihiyle saklanması gerekiyor.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.state,
    this.editMode = false,
  });

  final AppState state;
  final bool editMode;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// Cevapları önce bu kopyaya yazıyoruz; kaydedince asıl profil olur.
  late final UserProfile _draft = widget.state.profile.copy();

  late final List<OnboardingStep> _steps = [
    for (final step in OnboardingStep.values)
      if (!widget.editMode)
        step
      // Düzenleme modunda: sadece sorular, fiyat hariç.
      else if (step.isQuestion && step != OnboardingStep.packPrice)
        step,
  ];

  /// Şu an gösterilen sayfanın sırası (0'dan başlar).
  int _index = 0;
  final _pageController = PageController();

  /// Paket fiyatı (sadece ilk onboarding'de sorulur, profilin parçası değil).
  double? _price;
  int _perPack = 20;
  bool _showPerPack = false;
  final _priceController = TextEditingController();

  OnboardingStep get _step => _steps[_index];
  bool get _isLast => _index == _steps.length - 1;
  List<OnboardingStep> get _questions =>
      _steps.where((s) => s.isQuestion).toList();

  @override
  void dispose() {
    _pageController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // ---------- Gezinme ----------

  void _goTo(int index) {
    FocusScope.of(context).unfocus(); // Açık klavyeyi kapat.
    setState(() => _index = index);
    // "Hazırsın!" sayfasına gelince konfetiyle birlikte fanfar çalsın.
    if (_steps[index] == OnboardingStep.done) Effects.celebrate(big: true);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() => _isLast ? _finish() : _goTo(_index + 1);

  void _back() {
    if (_index > 0) _goTo(_index - 1);
  }

  /// İsteğe bağlı profil bölümünü atla.
  void _skipSection() {
    if (widget.editMode) {
      _finish();
    } else {
      _goTo(_steps.indexOf(OnboardingStep.done));
    }
  }

  /// Cevapları kaydet ve bitir. ("ATLA" da buraya gelir: o ana kadar
  /// verilen cevaplar yine kaydedilir.)
  Future<void> _finish() async {
    if (widget.editMode) {
      await widget.state.updateProfile(_draft);
      if (mounted) Navigator.of(context).pop();
    } else {
      final price = _price;
      if (price != null) {
        await widget.state.setPackPrice(price: price, perPack: _perPack);
      }
      // Ana ekrana geçişi uygulamanın kökü kendisi yapar (bkz. app.dart).
      await widget.state.completeOnboarding(_draft);
    }
  }

  /// Bu soru cevaplandı mı? (Buton "DEVAM" mı "ŞİMDİLİK GEÇ" mi olsun?)
  bool _answered(OnboardingStep step) => switch (step) {
    OnboardingStep.cigarettesPerDay => _draft.cigarettesPerDay != null,
    OnboardingStep.yearsSmoking => _draft.yearsSmoking != null,
    OnboardingStep.firstCigarette => _draft.firstCigarette != null,
    OnboardingStep.packPrice => _price != null,
    OnboardingStep.triggers => _draft.triggers.isNotEmpty,
    OnboardingStep.goal => _draft.goal != null,
    OnboardingStep.quitDesire => _draft.quitDesire != null,
    OnboardingStep.ageRange => _draft.ageRange != null,
    OnboardingStep.gender => _draft.gender != null,
    OnboardingStep.motivators => _draft.motivators.isNotEmpty,
    OnboardingStep.activities => _draft.activities.isNotEmpty,
    OnboardingStep.welcome || OnboardingStep.done => true,
  };

  // ---------- Ekran ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Geniş ekranlarda (bilgisayar tarayıcısı) içerik çok yayılmasın.
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                _buildTopBar(context),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: PrivacyBanner(compact: true),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    // Sadece butonlarla ilerlenir; kazara kaydırma olmasın.
                    physics: const NeverScrollableScrollPhysics(),
                    children: [for (final step in _steps) _buildStep(step)],
                  ),
                ),
                _buildBottomBar(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final c = AppColors.of(context);
    final questionIndex = _questions.indexOf(_step);

    final Widget? leading = _index > 0 && _step != OnboardingStep.done
        ? IconButton(
            onPressed: _back,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Geri',
          )
        : widget.editMode
        ? IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Kaydetmeden kapat',
          )
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      child: Row(
        children: [
          SizedBox(width: 48, child: leading),
          Expanded(
            child: questionIndex >= 0
                ? Semantics(
                    label: 'Soru ${questionIndex + 1} / ${_questions.length}',
                    child: ChunkyProgressBar(
                      value: (questionIndex + 1) / _questions.length,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          SizedBox(
            width: 84,
            child: _step == OnboardingStep.done
                ? null
                : TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(foregroundColor: c.textMuted),
                    child: Text(widget.editMode ? 'KAYDET' : 'ATLA'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final answered = _answered(_step);
    final label = switch (_step) {
      OnboardingStep.welcome => 'BAŞLAYALIM',
      OnboardingStep.done => 'BAŞLA',
      _ when _isLast => 'KAYDET',
      _ when answered => 'DEVAM',
      _ => 'ŞİMDİLİK GEÇ',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_step.isOptionalProfile)
            TextButton(
              onPressed: _skipSection,
              child: const Text('BU BÖLÜMÜ ATLA'),
            ),
          ChunkyButton(
            label: label,
            // Cevaplanmamış soruda buton beyaz: "geçmek de serbest".
            variant: answered || _isLast
                ? ChunkyVariant.primary
                : ChunkyVariant.secondary,
            onPressed: _next,
          ),
        ],
      ),
    );
  }

  Widget _buildStep(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.welcome => _welcomePage(),
      OnboardingStep.done => _donePage(),
      OnboardingStep.cigarettesPerDay => _question(
        question: 'Günde ortalama kaç sigara içiyorsun?',
        note: 'Emin değilsen tahmini bir sayı yeterli.',
        why:
            'Başlangıç noktanı bilmek, ilerlemeni doğru karşılaştırmamızı '
            'sağlar. Kılıf birkaç gün ölçüm yapana kadar bu sayıyı referans '
            'alırız.',
        answer: NumberStepper(
          value: _draft.cigarettesPerDay,
          min: 1,
          max: 80,
          startValue: 15,
          unit: 'sigara',
          onChanged: (v) => setState(() => _draft.cigarettesPerDay = v),
        ),
      ),
      OnboardingStep.yearsSmoking => _question(
        question: 'Kaç yıldır sigara içiyorsun?',
        why:
            'Alışkanlığın ne kadar süredir devam ettiği, sana uygun bir tempo '
            'önermemize yardım eder.',
        answer: NumberStepper(
          value: _draft.yearsSmoking,
          min: 0,
          max: 70,
          startValue: 5,
          unit: 'yıl',
          zeroLabel: '1 yıldan az',
          onChanged: (v) => setState(() => _draft.yearsSmoking = v),
        ),
      ),
      OnboardingStep.firstCigarette => _question(
        question: 'Sabah uyandıktan ne kadar sonra ilk sigaranı içiyorsun?',
        why:
            'Bu, nikotin bağımlılığını ölçmek için yaygın kullanılan '
            'Fagerström testinin sorularından biridir. Uyanınca sigaraya ne '
            'kadar çabuk ihtiyaç duyulduğu, bağımlılığın en güçlü '
            'göstergelerinden biri kabul edilir. Azaltma planını buna göre '
            'ayarlayacağız.',
        answer: OptionList<FirstCigaretteTime>(
          options: FirstCigaretteTime.values,
          selected: _draft.firstCigarette,
          labelOf: (o) => o.label,
          onChanged: (v) => setState(() => _draft.firstCigarette = v),
        ),
      ),
      OnboardingStep.packPrice => _pricePage(),
      OnboardingStep.triggers => _question(
        question: 'Hangi durumlarda canın daha çok sigara istiyor?',
        note: 'Birden fazla seçebilirsin.',
        why:
            'Sigara isteği çoğu zaman belirli anlara bağlıdır. Bu anları '
            'bilirsek sana tam o anlara uygun öneriler hazırlayabiliriz '
            '(ör. kahveden sonra kısa bir yürüyüş).',
        answer: ChipMultiChoice<SmokingTrigger>(
          options: SmokingTrigger.values,
          selected: _draft.triggers,
          labelOf: (t) => t.label,
          onChanged: (v) => setState(() => _draft.triggers = v),
        ),
      ),
      OnboardingStep.goal => _question(
        question: 'Hedefin ne?',
        why:
            'Sana göstereceğimiz adımlar buna göre değişir. Fikrini '
            'istediğin zaman değiştirebilirsin.',
        answer: OptionList<QuitGoal>(
          options: QuitGoal.values,
          selected: _draft.goal,
          labelOf: (g) => g.label,
          onChanged: (v) => setState(() => _draft.goal = v),
        ),
      ),
      OnboardingStep.quitDesire => _question(
        question: 'Sigarayı bırakmayı ne kadar istiyorsun?',
        why:
            'Ne kadar hazır hissettiğin, sana ne hızda bir plan '
            'önereceğimizi belirler. Doğru ya da yanlış cevap yok.',
        answer: ScalePicker(
          value: _draft.quitDesire,
          lowLabel: '1 · Hiç',
          highLabel: '10 · Çok',
          onChanged: (v) => setState(() => _draft.quitDesire = v),
        ),
      ),
      OnboardingStep.ageRange => _question(
        question: 'Biraz da seni tanıyayım. Yaş aralığın ne?',
        note: 'Bu bölüm tamamen isteğe bağlı.',
        why:
            'Önerileri ve mesajları yaşına uygun bir dille hazırlamak için. '
            'Tam yaşını sormuyoruz.',
        answer: ChipChoice<AgeRange>(
          options: AgeRange.values,
          selected: _draft.ageRange,
          labelOf: (a) => a.label,
          onChanged: (v) => setState(() => _draft.ageRange = v),
        ),
      ),
      OnboardingStep.gender => _question(
        question: 'Cinsiyetin?',
        why:
            'Sadece "tahmini yaşam süresi etkisi" hesabında kullanılır: '
            'araştırmalar erkeklerde ve kadınlarda farklı ortalamalar '
            'buluyor. Belirtmezsen genel ortalamayı kullanırız.',
        answer: OptionList<Gender>(
          options: Gender.values,
          selected: _draft.gender,
          labelOf: (g) => g.label,
          onChanged: (v) => setState(() => _draft.gender = v),
        ),
      ),
      OnboardingStep.motivators => _question(
        question: 'Seni en çok kim ya da ne motive ediyor?',
        note: 'Birden fazla seçebilirsin.',
        why:
            'Zor anlarda sana neden başladığını hatırlatan mesajlar daha '
            'etkili olur.',
        answer: ChipMultiChoice<Motivator>(
          options: Motivator.values,
          selected: _draft.motivators,
          labelOf: (m) => m.label,
          onChanged: (v) => setState(() => _draft.motivators = v),
        ),
      ),
      OnboardingStep.activities => _question(
        question: 'Hangi aktiviteleri seviyorsun?',
        note: 'Birden fazla seçebilirsin.',
        why:
            'Sevdiğin aktiviteleri sigarasız anlarla birleştiren öneriler '
            'sunmak için (ör. "Yarın sabah koşacaksan bu akşam son sigarayı '
            'erken içmeye ne dersin?").',
        answer: ChipMultiChoice<Activity>(
          options: Activity.values,
          selected: _draft.activities,
          labelOf: (a) => a.label,
          onChanged: (v) => setState(() => _draft.activities = v),
        ),
      ),
    };
  }

  // ---------- Sayfa şablonları ----------

  /// Maskotun soruyu sorduğu, kaydırılabilir soru sayfası.
  Widget _question({
    required String question,
    required String why,
    required Widget answer,
    String? note,
  }) {
    final c = AppColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        MascotSpeech(text: question, mood: MascotMood.think),
        if (note != null) ...[
          const SizedBox(height: 10),
          Text(
            note,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: c.textMuted),
          ),
        ],
        const SizedBox(height: 6),
        WhyToggle(text: why),
        const SizedBox(height: 18),
        answer,
      ],
    );
  }

  Widget _pricePage() {
    final priceText = _priceController.text.trim();
    final priceInvalid = priceText.isNotEmpty && parsePrice(priceText) == null;
    final theme = Theme.of(context);

    return _question(
      question: 'Bir paket sigara kaç lira?',
      why:
          'Sigaraya ne kadar para harcadığını ve azalttıkça ne kadar '
          'biriktirdiğini hesaplamak için. Zam gelirse sonra İstatistik → '
          'Paket fiyatı bölümünden kolayca güncelleyebilirsin; eski günlerin '
          'hesabı değişmez.',
      answer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.headlineSmall,
            decoration: InputDecoration(
              hintText: 'Örneğin 110',
              suffixText: '₺',
              errorText: priceInvalid
                  ? 'Geçerli bir fiyat gir (ör. 95,50)'
                  : null,
            ),
            onChanged: (text) => setState(() => _price = parsePrice(text)),
          ),
          const SizedBox(height: 12),
          // Çoğu paket 20'li; farklıysa değiştirilebilir.
          if (_showPerPack) ...[
            Text('Pakette kaç sigara var?', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            ChipChoice<int>(
              options: const [10, 20, 25],
              selected: _perPack,
              labelOf: perPackLabel,
              // Seçim kaldırılırsa varsayılan 20'ye dön.
              onChanged: (v) => setState(() => _perPack = v ?? 20),
            ),
          ] else
            TextButton(
              onPressed: () => setState(() => _showPerPack = true),
              child: Text('Paketin ${perPackLabel(20)} değil mi?'),
            ),
        ],
      ),
    );
  }

  Widget _welcomePage() {
    final theme = Theme.of(context);
    final c = AppColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const SizedBox(height: 12),
          const Mascot(size: 170),
          const SizedBox(height: 20),
          Text(
            'Merhaba! Ben $mascotName.',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 14),
          Text(
            'Sigarayı adım adım azaltman için yanındayım. Seni asla '
            'yargılamam; her küçük adımı birlikte kutlarız.\n\n'
            'Önce birkaç kısa soru soracağım. Hepsi isteğe bağlı: istediğini '
            'geçebilir ya da sağ üstten tamamen atlayabilirsin.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: c.textMuted,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Yaklaşık 2 dakika sürer.',
            style: theme.textTheme.bodySmall?.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _donePage() {
    final theme = Theme.of(context);
    final c = AppColors.of(context);
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Mascot(mood: MascotMood.cheer, size: 170),
              const SizedBox(height: 16),
              Text(
                'Hazırsın!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: c.mintText,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: c.goldLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.gold, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, color: c.goldShadow),
                    const SizedBox(width: 4),
                    Text(
                      '+$xpWelcome XP',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: c.goldShadow,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'İlk hafta ölçüm haftası: sen sadece kılıfını yanında taşı, '
                'ben de alışkanlıklarını tanıyayım. Bu hafta sana azaltma '
                'görevi vermeyeceğim.\n\n'
                'Her gün 3 küçük görevin olacak. Yaptıkça XP kazanır, '
                'serini büyütürsün. Sigara içmek serini asla bozmaz.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: c.textMuted,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (_step == OnboardingStep.done)
          const Positioned.fill(child: ConfettiBurst()),
      ],
    );
  }
}
