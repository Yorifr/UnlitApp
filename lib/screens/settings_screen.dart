import 'package:flutter/material.dart';

import '../app_info.dart';
import '../app_state.dart';
import '../logic/weekly_report.dart';
import '../services/demo_activity.dart';
import '../services/demo_device_service.dart';
import '../services/device_service.dart';
import '../services/effects.dart';
import '../utils/format.dart';
import '../widgets/price_sheet.dart';
import '../widgets/privacy_banner.dart';
import '../widgets/reason_note.dart';
import 'onboarding_screen.dart';

/// Ayarlar: kılıf/demo, bilgilerim, gizlilik, kaynaklar.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final device = state.device;
    final demo = device is DemoDeviceService ? device : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const _SectionTitle('Kılıf'),
              ValueListenableBuilder<DeviceStatus>(
                valueListenable: device.status,
                builder: (context, status, _) => ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(device.name),
                  subtitle: Text(status.label),
                  trailing: Icon(
                    Icons.circle,
                    size: 12,
                    color: status == DeviceStatus.connected
                        ? Colors.green
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              if (demo != null) ...[
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  subtitle: Text(
                    'Gerçek kılıf henüz hazır olmadığı için "demo kılıf" '
                    'kullanılıyor. Demo kılıf gerçekçi sahte sigara kayıtları '
                    'üretir; uygulama kapalıyken geçen sürenin kayıtlarını da '
                    'açılınca ekler.',
                  ),
                ),
                const _SectionTitle('Demo verisi'),
                ListTile(
                  leading: const Icon(Icons.auto_awesome),
                  title: const Text('Demo verisi üret'),
                  subtitle: const Text(
                    'Son iki haftanın sahte kayıtlarını, görevlerini ve '
                    'puanlarını oluşturur. Mevcut kayıtların yerini alır.',
                  ),
                  onTap: () => _generateDemo(context, demo),
                ),
                // Takibin kaçıncı günü olduğunu göstersin diye dinler.
                ListenableBuilder(
                  listenable: state,
                  builder: (context, _) => ListTile(
                    leading: const Icon(Icons.fast_forward_outlined),
                    title: const Text('Bir günlük veri ekle'),
                    subtitle: Text(
                      'Sanki bir gün geçmiş gibi: kayıtların bir gün geriye '
                      'kayar, son 24 saatin demo verisi eklenir. Ölçüm '
                      'haftasını ve haftalık raporları gün gün izlemek için.'
                      '${_dayLabel()}',
                    ),
                    onTap: () => _addDay(context, demo),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Şimdi bir sigara alındı'),
                  subtitle: const Text(
                    'Kılıfın kapağının açılmasını taklit eder.',
                  ),
                  onTap: () {
                    demo.simulatePickup();
                    _showSnack(context, 'Bir sigara kaydedildi (demo).');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restart_alt),
                  title: const Text('Demo verisini sıfırla'),
                  subtitle: const Text(
                    'Kayıtları, puanları, seriyi ve dolabı siler. Cevapların '
                    'kalır.',
                  ),
                  onTap: () => _resetEvents(context),
                ),
              ],
              const _SectionTitle('Ses ve titreşim'),
              const _EffectsSettings(),
              const _SectionTitle('Bilgilerim'),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Bilgilerimi düzenle'),
                subtitle: const Text(
                  'Günlük sigara, ilk sigara ve tetikleyiciler',
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        OnboardingScreen(state: state, editMode: true),
                  ),
                ),
              ),
              // Not değişince güncel hâlini göstersin diye state'i dinler.
              ListenableBuilder(
                listenable: state,
                builder: (context, _) => ListTile(
                  leading: const Icon(Icons.edit_note),
                  title: const Text('Kendime notum'),
                  subtitle: Text(
                    state.profile.reasonNote ??
                        'Henüz yazmadın. Erteleme ekranında karşına çıkar.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => showReasonNoteDialog(context, state),
                ),
              ),
              // Fiyat değişince güncel özeti göstersin diye state'i dinler.
              ListenableBuilder(
                listenable: state,
                builder: (context, _) {
                  final current = state.prices.current;
                  return ListTile(
                    leading: const Icon(Icons.sell_outlined),
                    title: const Text('Paket fiyatı'),
                    subtitle: Text(
                      current == null
                          ? 'Henüz girilmedi'
                          : '${formatMoney(current.price)} · '
                                '${perPackLabel(current.perPack)} · '
                                '${formatSince(current.since)}',
                    ),
                    onTap: () => showPriceSheet(context, state),
                  );
                },
              ),
              const _SectionTitle('Gizlilik'),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: PrivacyBanner(),
              ),
              const ListTile(
                subtitle: Text(
                  'Unlit hesap istemez, sunucuya veri göndermez, reklam veya '
                  'analiz aracı kullanmaz. Tüm kayıtlar yalnızca bu cihazda '
                  'saklanır. Uygulamayı silersen kayıtlar da silinir.',
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Tüm verilerimi sil',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                subtitle: const Text(
                  'Cevapların ve tüm sigara kayıtların kalıcı olarak silinir.',
                ),
                onTap: () => _deleteAll(context),
              ),
              const _SectionTitle('Kaynaklar'),
              const ListTile(
                title: Text('Korunan yaşam süresi'),
                subtitle: Text(
                  'Jackson SE, Jarvis MJ, West R. "The price of a cigarette: '
                  '20 minutes of life?" Addiction, 2024 (University College '
                  'London). Bir sigara ortalama olarak erkeklerde ~17 dk, '
                  'kadınlarda ~22 dk (genel ortalama ~20 dk) yaşam süresine '
                  'mal oluyor. Uygulama bu ortalamayı sadece sigarasız '
                  'günlerin için kullanır. Neden: Hackshaw A ve ark., BMJ, '
                  '2018 — sağlığa etkisi sigara sayısıyla orantılı değil, az '
                  'sayıda sigara bile riskin önemli bir kısmını taşıyor. '
                  'Ortalama bir tahmindir.',
                ),
              ),
              const ListTile(
                title: Text('İsteği 10 dakika ertelemek'),
                subtitle: Text(
                  'Mayo Clinic, "Quitting smoking: 10 ways to resist tobacco '
                  'cravings" (Türkçesi Koç Üniversitesi Hastanesi ve Amerikan '
                  'Hastanesi sitelerinde): isteği 10 dakika erteleyip dikkatini '
                  'dağıtmayı önerir. Yürüme önerisi: Taylor AH, Katomeri M, '
                  'Ussher M, Psychopharmacology, 2005. 10 dakika kesin bir '
                  'bilimsel sınır değildir; uygulama her ertelemenin süresini '
                  'kaydeder ve isteklerin sende genelde kaç dakikada '
                  'geçtiğini söyler.',
                ),
              ),
              const ListTile(
                title: Text('Nefes molası'),
                subtitle: Text(
                  'Shahab L, Sarkar BK, West R, Psychopharmacology, 2013: '
                  'nefes egzersizi sigara isteğini hemen azalttı (24 saat '
                  'sonra etkisi görülmedi). 4 saniye al, 4 saniye ver ritmi '
                  'ekibin seçimidir.',
                ),
              ),
              const ListTile(
                title: Text('Günde kaç sigara tahmini'),
                subtitle: Text(
                  'Shiffman S, Health Psychology, 2009: insanlar sigara '
                  'sayısını çoğu zaman yuvarlak bir tahminle hatırlar; anlık '
                  'kayıt bu yanılgıyı yapmaz. Bu yüzden tahminin ölçümle yan '
                  'yana gösterilir.',
                ),
              ),
              const ListTile(
                title: Text('Uyanınca ilk sigara sorusu'),
                subtitle: Text(
                  'Fagerström Nikotin Bağımlılığı Testi (Heatherton ve ark., '
                  '1991) sorularından biridir.',
                ),
              ),
              const _SectionTitle('Hakkında'),
              const ListTile(
                title: Text('$appName $appVersion'),
                subtitle: Text(
                  'TÜBİTAK 2204-A Lise Öğrencileri Araştırma Projesi',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateDemo(
    BuildContext context,
    DemoDeviceService demo,
  ) async {
    if (state.events.isNotEmpty) {
      final ok = await _confirm(
        context,
        title: 'Demo verisi üretilsin mi?',
        message:
            'Mevcut sigara kayıtları, puanlar ve görevler silinip yerine son '
            'iki haftanın yeni demo verisi oluşturulacak. Dolaptaki eşyalar '
            've filiz demo puanına göre yeniden hesaplanır.',
        action: 'Üret',
      );
      if (!ok) return;
    }
    await loadDemoHistory(state, demo);
    if (context.mounted) {
      _showSnack(context, '${state.events.length} demo kaydı oluşturuldu.');
    }
  }

  /// " Şu an takibin 9. günü (2. hafta)." (Takip başlamadıysa boş.)
  String _dayLabel() {
    final day = state.trackingDay;
    if (day == null) return '';
    return ' Şu an takibin $day. günü (${(day - 1) ~/ daysPerWeek + 1}. '
        'hafta).';
  }

  Future<void> _addDay(BuildContext context, DemoDeviceService demo) async {
    await addDemoDay(state, demo);
    if (!context.mounted) return;
    final news = state.measurementSummaryPending
        ? ' Ölçüm haftası özeti hazır!'
        : state.pendingWeeklyReport != null
        ? ' Haftalık rapor hazır!'
        : '';
    _showSnack(
      context,
      'Bir gün geçti: takibin ${state.trackingDay}. günü.$news',
    );
  }

  Future<void> _resetEvents(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: 'Kayıtlar silinsin mi?',
      message:
          'Tüm sigara kayıtları, puanlar, seri, görevler ve hedefin '
          'silinecek; Nefes\'in dolabı ve filiz de baştan başlar. '
          'Onboarding cevapların kalır.',
      action: 'Sil',
    );
    if (!ok) return;
    await state.resetEventsAndProgress();
    if (context.mounted) _showSnack(context, 'Kayıtlar silindi.');
  }

  Future<void> _deleteAll(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: 'Tüm veriler silinsin mi?',
      message:
          'Cevapların ve tüm sigara kayıtların bu cihazdan kalıcı olarak '
          'silinecek. Bu işlem geri alınamaz.',
      action: 'Hepsini sil',
    );
    if (!ok) return;
    await state.deleteAllData();
    Effects.resetSettings();
    // Uygulama ilk açılış haline döndü; karşılama ekranına geri dön.
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  /// "Emin misin?" penceresi. Onaylanırsa true döner.
  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Ses efektleri ve titreşim anahtarları.
class _EffectsSettings extends StatefulWidget {
  const _EffectsSettings();

  @override
  State<_EffectsSettings> createState() => _EffectsSettingsState();
}

class _EffectsSettingsState extends State<_EffectsSettings> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.volume_up_outlined),
          title: const Text('Ses efektleri'),
          subtitle: const Text(
            'Görev ve kutlama sesleri. Telefonda sessiz moda uyar, çalan '
            'müziği durdurmaz.',
          ),
          value: Effects.soundOn,
          onChanged: (value) async {
            await Effects.setSoundOn(value);
            setState(() {});
            // Açınca nasıl duyulduğunu hemen dinlet.
            if (value) Effects.play(Sfx.success);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.vibration),
          title: const Text('Titreşim'),
          subtitle: const Text(
            'Butonlara basınca ve kutlamalarda hafif titreşim. (iPhone '
            'tarayıcısında desteklenmez; uygulamada çalışır.)',
          ),
          value: Effects.hapticsOn,
          onChanged: (value) async {
            await Effects.setHapticsOn(value);
            setState(() {});
            if (value) Effects.tap();
          },
        ),
      ],
    );
  }
}
