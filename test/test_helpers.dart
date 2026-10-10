// Testlerde ortak kullanılan yardımcılar.

import 'package:unlit/services/effects.dart';

/// Çalınan sesleri kaydeden sahte oynatıcı (gerçekten ses çıkarmaz).
/// Testlerde "doğru anda doğru ses çaldı mı?" diye bakmak için.
class RecordingPlayer implements SoundPlayer {
  final played = <String>[];
  int unlocks = 0;

  @override
  void unlock() => unlocks++;

  @override
  Future<void> play(String asset) async => played.add(asset);
}
