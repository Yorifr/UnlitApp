import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unlit/services/effects.dart';
import 'package:unlit/services/storage_service.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RecordingPlayer player;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    player = RecordingPlayer();
    Effects.init(await StorageService.create(), player);
  });

  test('kutlama türüne göre doğru ses çalar', () {
    Effects.celebrate();
    Effects.celebrate(big: true);
    Effects.celebrate(calm: true);
    expect(player.played, [
      Sfx.success.asset,
      Sfx.fanfare.asset,
      Sfx.calm.asset,
    ]);
  });

  test('nefes ve süre doldu sesleri', () {
    Effects.breath(inhale: true);
    Effects.breath(inhale: false);
    Effects.timerDone();
    expect(player.played, [
      Sfx.breathIn.asset,
      Sfx.breathOut.asset,
      Sfx.bell.asset,
    ]);
  });

  test('ses kapalıyken hiçbir şey çalmaz', () async {
    await Effects.setSoundOn(false);
    Effects.celebrate(big: true);
    Effects.unlock();
    expect(player.played, isEmpty);
    expect(player.unlocks, 0);
  });

  test('ayarlar kaydedilir ve tekrar açılınca okunur', () async {
    await Effects.setSoundOn(false);
    await Effects.setHapticsOn(false);
    Effects.init(await StorageService.create(), player);
    expect(Effects.soundOn, isFalse);
    expect(Effects.hapticsOn, isFalse);

    Effects.resetSettings();
    expect(Effects.soundOn, isTrue);
    expect(Effects.hapticsOn, isTrue);
  });

  test('her ses dosyası projede var', () async {
    for (final sound in Sfx.values) {
      final data = await rootBundle.load('assets/${sound.asset}');
      expect(data.lengthInBytes, greaterThan(1000), reason: sound.asset);
    }
  });
}
