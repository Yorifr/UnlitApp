// Telefonda (Android/iOS) ses çalan parça: audioplayers paketi.
//
// Not: Bu dosya web'de kullanılmaz (bkz. sound_player.dart).

import 'package:audioplayers/audioplayers.dart';

import 'effects.dart';

/// Platforma uygun ses oynatıcıyı oluşturur.
SoundPlayer createSoundPlayer() => AudioplayersSoundPlayer();

class AudioplayersSoundPlayer implements SoundPlayer {
  AudioPlayer? _player;
  bool _contextSet = false;

  /// Oynatıcıyı ilk ihtiyaçta oluştur.
  Future<AudioPlayer> _getPlayer() async {
    if (!_contextSet) {
      _contextSet = true;
      // Kısa efekt sesleri için ayar:
      // - iPhone: "ambient" → sessiz moda uyar, çalan müziği durdurmaz.
      // - Android: "bildirim sesi" türü, müziğin sesini çalmaz (odak yok).
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );
    }
    return _player ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  }

  @override
  void unlock() {} // Telefonda gerek yok.

  @override
  Future<void> play(String asset) async {
    final player = await _getPlayer();
    await player.stop(); // Önceki ses hâlâ çalıyorsa kes.
    await player.play(AssetSource(asset));
  }
}
