// Web'de ses çalan parça: tarayıcının kendi "Web Audio" motoru.
//
// Neden audioplayers değil? iPhone Safari, sese ancak kullanıcı ekrana
// dokunduğu ANDA izin verir. Web Audio'da tek bir "ses bağlamını" ilk
// dokunuşta açınca sonraki tüm sesler sorunsuz çalar. Ayrıca iPhone'un
// sessiz moduna uyar ve sesler gecikmesiz çalar.
//
// Ses dosyaları uygulamanın kendi sitesinden yüklenir (dış istek yok).
//
// Not: Bu dosya sadece web'de kullanılır (bkz. sound_player.dart).

import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import 'effects.dart';

/// Platforma uygun ses oynatıcıyı oluşturur.
SoundPlayer createSoundPlayer() => WebAudioSoundPlayer();

class WebAudioSoundPlayer implements SoundPlayer {
  web.AudioContext? _context;
  bool _preloaded = false;

  /// Çözülmüş (çalmaya hazır) sesler: dosya yolu → ses verisi.
  final Map<String, web.AudioBuffer> _buffers = {};

  web.AudioContext _getContext() => _context ??= web.AudioContext();

  @override
  void unlock() {
    final context = _getContext();
    // Bu satır DOKUNUŞ sırasında çalışmalı: tarayıcı sesi burada açar.
    if (context.state != 'running') context.resume();
    // Sesleri şimdiden (bir kez) yükle ki ilk çalışta gecikme olmasın.
    if (!_preloaded) {
      _preloaded = true;
      for (final sound in Sfx.values) {
        _load(sound.asset).ignore();
      }
    }
  }

  /// Ses dosyasını oku ve çalmaya hazır hale getir (bir kez).
  Future<web.AudioBuffer> _load(String asset) async {
    final cached = _buffers[asset];
    if (cached != null) return cached;
    final data = await rootBundle.load('assets/$asset');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final buffer = await _getContext()
        .decodeAudioData(bytes.buffer.toJS)
        .toDart;
    return _buffers[asset] = buffer;
  }

  @override
  Future<void> play(String asset) async {
    final context = _getContext();
    final buffer = await _load(asset);
    if (context.state == 'suspended') {
      // Henüz dokunuş olmadıysa tarayıcı izin vermeyebilir; deneriz.
      await context.resume().toDart;
    }
    final source = context.createBufferSource()..buffer = buffer;
    source.connect(context.destination);
    source.start();
  }
}
