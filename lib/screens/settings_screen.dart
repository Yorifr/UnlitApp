import 'package:flutter/material.dart';

import '../app_info.dart';
import '../app_state.dart';
import '../services/demo_activity.dart';
import '../services/demo_device_service.dart';
import '../services/device_service.dart';
import '../services/effects.dart';
import '../widgets/privacy_banner.dart';
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
                    'XP\'sini oluşturur. Mevcut kayıtların yerini alır.',
                  ),
                  onTap: () => _generateDemo(context, demo),
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
                    'Kayıtları, XP ve seriyi siler. Cevapların kalır.',
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
                  'Sigara alışkanlığı, paket fiyatı, hedef ve profil',
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        OnboardingScreen(state: state, editMode: true),
                  ),
                ),
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
                title: Text('Tahmini yaşam süresi etkisi'),
                subtitle: Text(
                  'Jackson SE, Jarvis MJ, West R. "The price of a cigarette: '
                  '20 minutes of life?" Addiction, 2024 (University College '
                  'London). Bir sigara ortalama olarak erkeklerde ~17 dk, '
                  'kadınlarda ~22 dk (genel ortalama ~20 dk) yaşam süresine '
                  'mal oluyor. Ortalama bir tahmindir.',
                ),
              ),
              const ListTile(
                title: Text('Uyanınca ilk sigara sorusu'),
                subtitle: Text(
                  'Fagerström Nikotin Bağımlılığı Testi (Heatherton ve ark., '
                  '1991) sorularından biridir.',
                ),
              ),
              const ListTile(
                title: Text('Sigaraya giden süre'),
                subtitle: Text(
                  'Bir sigaranın ~6 dakikada içildiği varsayılır. Bu kaynaklı '
                  'bir ölçüm değil, yaklaşık bir varsayımdır.',
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
            'Mevcut sigara kayıtları, XP ve görevler silinip yerine son '
            'iki haftanın yeni demo verisi oluşturulacak.',
        action: 'Üret',
      );
      if (!ok) return;
    }
    await loadDemoHistory(state, demo);
    if (context.mounted) {
      _showSnack(context, '${state.events.length} demo kaydı oluşturuldu.');
    }
  }

  Future<void> _resetEvents(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: 'Kayıtlar silinsin mi?',
      message:
          'Tüm sigara kayıtları, XP, seri ve görevler silinecek. Onboarding '
          'cevapların kalır.',
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
