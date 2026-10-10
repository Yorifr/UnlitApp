// Platforma göre doğru ses oynatıcıyı seçer:
// - Web'de derlenirken: sound_player_web.dart (Web Audio)
// - Telefonda: sound_player_native.dart (audioplayers)
//
// Bu "koşullu dışa aktarma" (conditional export) sayesinde web koduna
// telefon paketi, telefon koduna da web paketi karışmaz.

export 'sound_player_native.dart'
    if (dart.library.js_interop) 'sound_player_web.dart';
