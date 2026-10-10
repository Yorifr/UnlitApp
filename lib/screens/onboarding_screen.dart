import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/user_profile.dart';
import '../widgets/onboarding_inputs.dart';
import '../widgets/privacy_banner.dart';

/// Onboarding'in adımları (sayfaları).
enum OnboardingStep {
  welcome,
  habits,
  cost,
  triggers,
  goal,
  about,
  motivation,
  done,
}

/// İlk açılıştaki kısa soru akışı. Her şey isteğe bağlı ve atlanabilir.
///
/// [editMode] true ise (Ayarlar > Bilgilerimi düzenle) karşılama ve bitiş
/// sayfaları gösterilmez; son sayfada "Kaydet" ile ayarlara dönülür.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.state,
    this.editMode = false,
    this.initialStep,
  });

  final AppState state;
  final bool editMode;

  /// Doluysa akış bu sayfadan başlar (ör. ana ekrandan "paket fiyatını
  /// ekle"ye dokununca doğrudan Harcama sayfası açılır).
  final OnboardingStep? initialStep;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// Cevapları önce bu kopyaya yazıyoruz; kaydedince asıl profil olur.
  late final UserProfile _draft = widget.state.profile.copy();

  late final List<OnboardingStep> _steps = [
    if (!widget.editMode) OnboardingStep.welcome,
    OnboardingStep.habits,
    OnboardingStep.cost,
    OnboardingStep.triggers,
    OnboardingStep.goal,
    OnboardingStep.about,
    OnboardingStep.motivation,
    if (!widget.editMode) OnboardingStep.done,
  ];

  /// Şu an gösterilen sayfanın sırası (0'dan başlar).
  late int _index = widget.initialStep == null
      ? 0
      : _steps.indexOf(widget.initialStep!).clamp(0, _steps.length - 1);
  late final _pageController = PageController(initialPage: _index);
  late final _priceController = TextEditingController(
    text: _draft.packPrice == null ? '' : _priceToText(_draft.packPrice!),
  );

  OnboardingStep get _step => _steps[_index];
  bool get _isLast => _index == _steps.length - 1;

  /// Soru sayfaları (karşılama ve bitiş hariç) — ilerleme çubuğu için.
  List<OnboardingStep> get _questionSteps => _steps
      .where((s) => s != OnboardingStep.welcome && s != OnboardingStep.done)
      .toList();

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

  /// Cevapları kaydet ve bitir. (Atla da buraya gelir: o ana kadar
  /// verilen cevaplar yine kaydedilir.)
  Future<void> _finish() async {
    if (widget.editMode) {
      await widget.state.updateProfile(_draft);
      if (mounted) Navigator.of(context).pop();
    } else {
      // Ana ekrana geçişi uygulamanın kökü kendisi yapar (bkz. app.dart).
      await widget.state.completeOnboarding(_draft);
    }
  }

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
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: PrivacyBanner(),
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
    final questionIndex = _questionSteps.indexOf(_step);
    final showProgress = questionIndex >= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      child: Row(
        children: [
          // Geri butonu (ilk sayfada yok)
          SizedBox(
            width: 48,
            child: _index > 0 && _step != OnboardingStep.done
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
                : null,
          ),
          Expanded(
            child: showProgress
                ? Column(
                    children: [
                      Text(
                        'Adım ${questionIndex + 1} / ${_questionSteps.length}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (questionIndex + 1) / _questionSteps.length,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          SizedBox(
            width: 72,
            child: _step == OnboardingStep.done
                ? null
                : TextButton(
                    onPressed: _finish,
                    child: Text(widget.editMode ? 'Kaydet' : 'Atla'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final label = switch (_step) {
      OnboardingStep.welcome => 'Başlayalım',
      OnboardingStep.done => 'Ana ekrana git',
      _ when _isLast => 'Kaydet',
      _ => 'İleri',
    };
    final isOptionalSection =
        _step == OnboardingStep.about || _step == OnboardingStep.motivation;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOptionalSection)
            TextButton(
              onPressed: _skipSection,
              child: const Text('Bu bölümü atla'),
            ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _next, child: Text(label)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.welcome => _welcomePage(),
      OnboardingStep.habits => _habitsPage(),
      OnboardingStep.cost => _costPage(),
      OnboardingStep.triggers => _triggersPage(),
      OnboardingStep.goal => _goalPage(),
      OnboardingStep.about => _aboutPage(),
      OnboardingStep.motivation => _motivationPage(),
      OnboardingStep.done => _donePage(),
    };
  }

  // ---------- Sayfalar ----------

  Widget _welcomePage() {
    final theme = Theme.of(context);
    return _CenteredMessage(
      icon: Icons.smoke_free,
      title: 'Unlit’e hoş geldin',
      body:
          'Akıllı kılıfın her sigarayı sayar; Unlit de sana kendi '
          'verinle yol gösterir.\n\n'
          'Birkaç kısa soru soracağız. Hepsi isteğe bağlı: istediğini boş '
          'bırakabilir ya da sağ üstten tamamen atlayabilirsin.',
      footer: Text(
        'Yaklaşık 2 dakika sürer.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _habitsPage() {
    return _QuestionPage(
      title: 'Sigara alışkanlığın',
      subtitle: 'Emin değilsen tahmini bir cevap yeterli.',
      children: [
        QuestionBlock(
          question: 'Günde ortalama kaç sigara içiyorsun?',
          why:
              'Başlangıç noktanı bilmek, ilerlemeni doğru '
              'karşılaştırmamızı sağlar. Kılıf birkaç gün ölçüm yapana kadar '
              'bu sayıyı referans alırız.',
          child: NumberStepper(
            value: _draft.cigarettesPerDay,
            min: 1,
            max: 80,
            startValue: 15,
            unit: 'sigara',
            onChanged: (v) => setState(() => _draft.cigarettesPerDay = v),
          ),
        ),
        QuestionBlock(
          question: 'Kaç yıldır sigara içiyorsun?',
          why:
              'Alışkanlığın ne kadar süredir devam ettiği, sana uygun bir '
              'tempo önermemize yardım eder.',
          child: NumberStepper(
            value: _draft.yearsSmoking,
            min: 0,
            max: 70,
            startValue: 5,
            unit: 'yıl',
            zeroLabel: '1 yıldan az',
            onChanged: (v) => setState(() => _draft.yearsSmoking = v),
          ),
        ),
        QuestionBlock(
          question: 'Sabah uyandıktan ne kadar sonra ilk sigaranı içiyorsun?',
          why:
              'Bu, nikotin bağımlılığını ölçmek için yaygın kullanılan '
              'Fagerström testinin sorularından biridir. Uyanınca sigaraya ne '
              'kadar çabuk ihtiyaç duyulduğu, bağımlılığın en güçlü '
              'göstergelerinden biri kabul edilir. Azaltma planını buna göre '
              'ayarlayacağız.',
          child: OptionList<FirstCigaretteTime>(
            options: FirstCigaretteTime.values,
            selected: _draft.firstCigarette,
            labelOf: (o) => o.label,
            onChanged: (v) => setState(() => _draft.firstCigarette = v),
          ),
        ),
      ],
    );
  }

  Widget _costPage() {
    final priceText = _priceController.text.trim();
    final priceInvalid = priceText.isNotEmpty && _parsePrice(priceText) == null;

    return _QuestionPage(
      title: 'Harcama',
      children: [
        QuestionBlock(
          question: 'Bir paket sigara kaç lira?',
          why:
              'Sigaraya ne kadar para harcadığını ve azalttıkça ne kadar '
              'biriktirdiğini hesaplamak için.',
          child: TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Örneğin 100',
              suffixText: '₺',
              border: const OutlineInputBorder(),
              errorText: priceInvalid
                  ? 'Geçerli bir fiyat gir (ör. 95,50)'
                  : null,
            ),
            onChanged: (text) =>
                setState(() => _draft.packPrice = _parsePrice(text)),
          ),
        ),
        QuestionBlock(
          question: 'Pakette kaç sigara var?',
          why:
              'Bir sigaranın kaç liraya geldiğini bulmak için. Türkiye’de '
              'paketler genelde 20’liktir.',
          child: ChipChoice<int>(
            options: const [10, 20, 25],
            selected: _draft.cigarettesPerPack,
            labelOf: (n) => n == 10 ? '10’lu' : '$n’li',
            // Seçim kaldırılırsa varsayılan 20'ye dön.
            onChanged: (v) =>
                setState(() => _draft.cigarettesPerPack = v ?? 20),
          ),
        ),
      ],
    );
  }

  Widget _triggersPage() {
    return _QuestionPage(
      title: 'Tetikleyiciler',
      children: [
        QuestionBlock(
          question: 'Hangi durumlarda canın daha çok sigara istiyor?',
          why:
              'Sigara isteği çoğu zaman belirli anlara bağlıdır. Bu anları '
              'bilirsek sana tam o anlara uygun öneriler hazırlayabiliriz '
              '(ör. kahveden sonra kısa bir yürüyüş).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Birden fazla seçebilirsin.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              ChipMultiChoice<SmokingTrigger>(
                options: SmokingTrigger.values,
                selected: _draft.triggers,
                labelOf: (t) => t.label,
                onChanged: (v) => setState(() => _draft.triggers = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _goalPage() {
    return _QuestionPage(
      title: 'Hedefin',
      children: [
        QuestionBlock(
          question: 'Ne yapmak istiyorsun?',
          why:
              'Sana göstereceğimiz adımlar buna göre değişir. Fikrini '
              'istediğin zaman Ayarlar’dan değiştirebilirsin.',
          child: OptionList<QuitGoal>(
            options: QuitGoal.values,
            selected: _draft.goal,
            labelOf: (g) => g.label,
            onChanged: (v) => setState(() => _draft.goal = v),
          ),
        ),
        QuestionBlock(
          question: 'Sigarayı bırakmayı ne kadar istiyorsun?',
          why:
              'Ne kadar hazır hissettiğin, sana ne hızda bir plan '
              'önereceğimizi belirler. Doğru ya da yanlış cevap yok.',
          child: ScalePicker(
            value: _draft.quitDesire,
            lowLabel: '1 · Hiç',
            highLabel: '10 · Çok',
            onChanged: (v) => setState(() => _draft.quitDesire = v),
          ),
        ),
      ],
    );
  }

  Widget _aboutPage() {
    return _QuestionPage(
      title: 'Biraz da seni tanıyalım',
      subtitle: 'Bu bölüm tamamen isteğe bağlı.',
      children: [
        QuestionBlock(
          question: 'Yaş aralığın',
          why:
              'Önerileri ve mesajları yaşına uygun bir dille hazırlamak için. '
              'Tam yaşını sormuyoruz.',
          child: ChipChoice<AgeRange>(
            options: AgeRange.values,
            selected: _draft.ageRange,
            labelOf: (a) => a.label,
            onChanged: (v) => setState(() => _draft.ageRange = v),
          ),
        ),
        QuestionBlock(
          question: 'Cinsiyetin',
          why:
              'Sadece "tahmini yaşam süresi etkisi" hesabında kullanılır: '
              'araştırmalar erkeklerde ve kadınlarda farklı ortalamalar '
              'buluyor. Belirtmezsen genel ortalamayı kullanırız.',
          child: ChipChoice<Gender>(
            options: Gender.values,
            selected: _draft.gender,
            labelOf: (g) => g.label,
            onChanged: (v) => setState(() => _draft.gender = v),
          ),
        ),
      ],
    );
  }

  Widget _motivationPage() {
    return _QuestionPage(
      title: 'Seni ne mutlu ediyor?',
      subtitle: 'Bu bölüm de isteğe bağlı.',
      children: [
        QuestionBlock(
          question: 'Seni en çok kim ya da ne motive ediyor?',
          why:
              'Zor anlarda sana neden başladığını hatırlatan mesajlar daha '
              'etkili olur.',
          child: ChipMultiChoice<Motivator>(
            options: Motivator.values,
            selected: _draft.motivators,
            labelOf: (m) => m.label,
            onChanged: (v) => setState(() => _draft.motivators = v),
          ),
        ),
        QuestionBlock(
          question: 'Hangi aktiviteleri seviyorsun?',
          why:
              'Sevdiğin aktiviteleri sigarasız anlarla birleştiren öneriler '
              'sunmak için (ör. "Yarın sabah koşacaksan bu akşam son sigarayı '
              'erken içmeye ne dersin?").',
          child: ChipMultiChoice<Activity>(
            options: Activity.values,
            selected: _draft.activities,
            labelOf: (a) => a.label,
            onChanged: (v) => setState(() => _draft.activities = v),
          ),
        ),
      ],
    );
  }

  Widget _donePage() {
    return const _CenteredMessage(
      icon: Icons.check_circle_outline,
      title: 'Hazırsın!',
      body:
          'İlk hafta sadece ölçüm yapacağız: sana öneri ya da mesaj '
          'göndermeden alışkanlıklarını tanıyacağız.\n\n'
          'Cevaplarını istediğin zaman Ayarlar’daki "Bilgilerimi düzenle" '
          'bölümünden değiştirebilirsin.',
    );
  }
}

// ---------- Fiyat metni yardımcıları ----------

/// "95,50" veya "95.50" → 95.5. Geçersizse null.
double? _parsePrice(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  if (value == null || value <= 0 || value > 100000) return null;
  return value;
}

/// 95.5 → "95,5", 100.0 → "100"
String _priceToText(double price) {
  final isWhole = price == price.roundToDouble();
  return (isWhole ? price.toStringAsFixed(0) : price.toString()).replaceAll(
    '.',
    ',',
  );
}

// ---------- Sayfa iskeletleri ----------

/// Başlık + soru listesi olan, kaydırılabilir sayfa.
class _QuestionPage extends StatelessWidget {
  const _QuestionPage({
    required this.title,
    this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }
}

/// Ortada büyük ikon + başlık + metin (karşılama ve bitiş sayfaları).
class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.body,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          if (footer != null) ...[const SizedBox(height: 20), footer!],
        ],
      ),
    );
  }
}
