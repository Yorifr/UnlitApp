import 'package:flutter_test/flutter_test.dart';
import 'package:unlit/logic/mascot_messages.dart';
import 'package:unlit/models/activity_log.dart';

void main() {
  group('erteleme ekranındaki cümle (kendi verisi)', () {
    final start = DateTime(2026, 10, 1, 14);

    /// [start]'tan [seconds] saniye sonra biten bir erteleme.
    DelayAttempt delay(
      int seconds, {
      DelayOutcome outcome = DelayOutcome.success,
    }) => DelayAttempt(
      start: start,
      end: start.add(Duration(seconds: seconds)),
      outcome: outcome,
    );

    test('hiç erteleme yoksa genel cümle', () {
      expect(delayStartLine([]), startsWith('Bu istek geçici.'));
    });

    test('"yine de içtim" sayılmaz ve asla söylenmez', () {
      final gaveIn = [
        for (var i = 0; i < 4; i++) delay(300, outcome: DelayOutcome.gaveIn),
      ];
      expect(delayStartLine(gaveIn), startsWith('Bu istek geçici.'));

      final line = delayStartLine([...gaveIn, delay(600)]);
      expect(line, startsWith('Daha önce bir isteği atlattın.'));
      expect(line, isNot(contains('5')));
    });

    test('1–2 başarıda sadece sayı; "genelde" denmez', () {
      final line = delayStartLine([delay(200), delay(240)]);
      expect(line, startsWith('Daha önce 2 isteği atlattın.'));
      expect(line, isNot(contains('genelde')));
    });

    test('3 başarıdan sonra isteklerin genelde kaç dakikada geçtiği', () {
      // 4:10, 6:30 ve ekrandan çıkıp 45 dk sonra basılan (10 dk sayılır).
      final line = delayStartLine([delay(250), delay(390), delay(2700)]);
      expect(
        line,
        'Daha önce 3 isteği atlattın; istekler genelde 7 dakika içinde '
        'geçti. Birlikte bekleyelim, sonra karar senin.',
      );
    });

    test('istekler genelde 10 dakikada geçtiyse süre söylenmez', () {
      final line = delayStartLine([delay(600), delay(600), delay(300)]);
      expect(line, startsWith('Daha önce 3 isteği atlattın.'));
      expect(line, isNot(contains('genelde')));
    });

    test('ortanca süre: yukarı yuvarlanır, en az 1, en fazla 10', () {
      expect(typicalDelayMinutes([]), isNull);
      expect(typicalDelayMinutes([delay(5)]), 1);
      expect(typicalDelayMinutes([delay(301)]), 6);
      expect(typicalDelayMinutes([delay(9999)]), 10);
      // Çift sayıda kayıt: ortadaki ikisinden büyüğü (yarısı bu sürede geçti).
      expect(
        typicalDelayMinutes([delay(60), delay(120), delay(300), delay(600)]),
        5,
      );
    });
  });
}
