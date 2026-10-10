// Ses ve titreşim (haptic) efektleri — hepsi tek yerden yönetilir.
//
// Duolingo hissinin bir parçası: bir görev bitince "ding", büyük başarıda
// kısa bir "fanfar", telefonda da küçük bir titreşim.
//
// KURALLAR:
// - Ses sadece GÜZEL anlarda çalar (görev, kutlama, nefes ipucu, süre
//   doldu). "Hata" ya da "ceza" sesi YOK; sigara içince hiçbir ses çalmaz.
// - Ses ve titreşim Ayarlar'dan ayrı ayrı kapatılabilir.
// - Telefonda sesler çalan müziği durdurmaz ve sessiz moda uyar.
// - Bir ses çalınamazsa uygulama asla çökmez (sessizce devam eder).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'storage_service.dart';

/// Uygulamadaki ses efektleri. Dosyalar: assets/sounds/
/// (tool/make_sounds.py ile sıfırdan üretildi, telif sorunu yok).
enum Sfx {
  /// Görev tamamlandı: kısa, parlak "ding-ding".
  success('sounds/success.wav'),

  /// Büyük kutlama (günün görevleri bitti, erteleme başarılı...).
  fanfare('sounds/fanfare.wav'),

  /// Sakin an (zor gün, "yine de içeceğim"): yumuşak, sıcak bir çan.
  calm('sounds/calm.wav'),

  /// Nefes egzersizi: "nefes al" ve "nefes ver" ipuçları.
  breathIn('sounds/breath_in.wav'),
  breathOut('sounds/breath_out.wav'),

  /// Erteleme süresi doldu.
  bell('sounds/bell.wav');

  const Sfx(this.asset);

  /// assets/ klasörüne göre dosya yolu.
  final String asset;
}

/// Sesi gerçekten çalan parça için "sözleşme".
/// - Telefonda: audioplayers paketi (sound_player_native.dart)
/// - Web'de: tarayıcının Web Audio motoru (sound_player_web.dart)
/// - Testlerde: hiçbir şey çalmayan [SilentSoundPlayer]
abstract class SoundPlayer {
  /// Sesi açmaya hazırla. Web'de bir DOKUNUŞ sırasında çağrılmalı;
  /// tarayıcılar (özellikle iPhone) sese ancak böyle izin verir.
  /// Birden çok kez çağrılabilir; ses zaten açıksa hiçbir şey yapmaz.
  void unlock();

  /// [asset] dosyasını çal.
  Future<void> play(String asset);
}

/// Hiç ses çıkarmayan oynatıcı (testler ve varsayılan).
class SilentSoundPlayer implements SoundPlayer {
  @override
  void unlock() {}

  @override
  Future<void> play(String asset) async {}
}

/// Ses + titreşim efektleri. Her yerden `Effects.xxx()` diye çağrılır.
class Effects {
  Effects._(); // Nesnesi oluşturulmaz; tüm metotlar statik.

  /// Ses efektleri açık mı? (Ayarlar'dan değişir.)
  static bool soundOn = true;

  /// Titreşim açık mı? (Ayarlar'dan değişir.)
  static bool hapticsOn = true;

  /// Sesi çalan parça. main.dart gerçek oynatıcıyı verir; testlerde sessiz.
  static SoundPlayer player = SilentSoundPlayer();

  static StorageService? _storage;

  static const _kSound = 'sound_on';
  static const _kHaptics = 'haptics_on';

  /// Uygulama açılırken: kayıtlı ayarları oku, oynatıcıyı bağla.
  static void init(StorageService storage, SoundPlayer soundPlayer) {
    _storage = storage;
    player = soundPlayer;
    soundOn = storage.readBool(_kSound) ?? true;
    hapticsOn = storage.readBool(_kHaptics) ?? true;
  }

  static Future<void> setSoundOn(bool value) async {
    soundOn = value;
    await _storage?.writeBool(_kSound, value);
  }

  static Future<void> setHapticsOn(bool value) async {
    hapticsOn = value;
    await _storage?.writeBool(_kHaptics, value);
  }

  /// "Tüm verilerimi sil" sonrası: varsayılan ayarlara dön.
  static void resetSettings() {
    soundOn = true;
    hapticsOn = true;
  }

  /// Her dokunuşta çağrılır (uygulamanın kökündeki Listener). Web'de ses
  /// henüz açılmadıysa açar; açıldıysa hiçbir şey yapmaz.
  static void unlock() {
    if (soundOn) _safely(() => player.unlock());
  }

  // ---------- Titreşimler ----------

  /// Butona basma: hafif "tık".
  static void tap() {
    if (hapticsOn) _haptic(HapticFeedback.lightImpact);
  }

  /// Bir seçeneği seçme: en hafif "tık".
  static void select() {
    if (hapticsOn) _haptic(HapticFeedback.selectionClick);
  }

  // ---------- Ses + titreşim ----------

  /// Kutlama anı. [big]: büyük kutlama; [calm]: sakin, destekleyici an.
  static void celebrate({bool big = false, bool calm = false}) {
    play(
      calm
          ? Sfx.calm
          : big
          ? Sfx.fanfare
          : Sfx.success,
    );
    if (!hapticsOn) return;
    // "Başarı" titreşimi (iPhone'da sistemin kendi başarı titreşimi).
    _haptic(
      calm ? HapticFeedback.lightImpact : HapticFeedback.successNotification,
    );
  }

  /// Nefes egzersizinde "al" / "ver" anı.
  static void breath({required bool inhale}) {
    play(inhale ? Sfx.breathIn : Sfx.breathOut);
    if (hapticsOn) _haptic(HapticFeedback.lightImpact);
  }

  /// Erteleme süresi doldu.
  static void timerDone() {
    play(Sfx.bell);
    if (hapticsOn) _haptic(HapticFeedback.heavyImpact);
  }

  /// Bir ses çal (ses kapalıysa hiçbir şey yapmaz).
  static void play(Sfx sound) {
    if (!soundOn) return;
    unawaited(
      player.play(sound.asset).catchError((Object error) {
        debugPrint('Ses çalınamadı (${sound.asset}): $error');
      }),
    );
  }

  static void _haptic(Future<void> Function() feedback) {
    unawaited(feedback().catchError((Object _) {}));
  }

  static void _safely(void Function() action) {
    try {
      action();
    } catch (error) {
      debugPrint('Ses hazırlanamadı: $error');
    }
  }
}
