import 'package:flutter_test/flutter_test.dart';
import 'package:unlit/logic/goal.dart';
import 'package:unlit/logic/mascot_messages.dart';
import 'package:unlit/models/goal.dart';
import 'package:unlit/models/smoking_event.dart';
import 'package:unlit/widgets/mascot.dart' show MascotMood;

void main() {
  final start = DateTime(2026, 10, 1); // hedefin başladığı gün

  Goal goal({
    double baseline = 10,
    double? from,
    int percent = 50,
    int amount = 2,
    GoalUnit unit = GoalUnit.week,
  }) => Goal(
    start: start,
    baseline: baseline,
    from: from ?? baseline,
    percent: percent,
    amount: amount,
    unit: unit,
  );

  /// [day] gününde (start'a göre, eksi olabilir) [count] sigara.
  List<SmokingEvent> smoke(int day, int count) => [
    for (var i = 0; i < count; i++)
      SmokingEvent(
        time: DateTime(2026, 10, 1 + day, 8 + i),
        source: EventSource.demo,
      ),
  ];

  group('hedef sayısı ve süre', () {
    test('hedef = başlangıç × kalan yüzde, yuvarlanır', () {
      expect(goalTarget(15, 50), 8); // 7,5 → 8
      expect(goalTarget(14.6, 25), 11); // 10,95 → 11
      expect(goalTarget(14.6, 75), 4); // 3,65 → 4
      expect(goalTarget(14.6, 100), 0); // bırakmak
    });

    test('bitiş günü: hafta 7 gün, ay takvim ayı', () {
      expect(goalEndFrom(start, 4, GoalUnit.week), DateTime(2026, 10, 29));
      expect(goalEndFrom(start, 2, GoalUnit.month), DateTime(2026, 12, 1));
      // Yıl değişse de doğru: 10 Kasım + 2 ay = 10 Ocak.
      expect(
        goalEndFrom(DateTime(2026, 11, 10, 15), 2, GoalUnit.month),
        DateTime(2027, 1, 10),
      );
    });

    test('haftalık adım sayısı: artan günler son haftaya eklenir', () {
      final oneMonth = goalEndFrom(start, 1, GoalUnit.month); // 31 gün
      expect(goalStepCount(start, oneMonth), 4);
      expect(goalStepCount(start, goalEndFrom(start, 3, GoalUnit.week)), 3);
      expect(goalStepCount(start, start), 1); // en az 1
    });
  });

  group('haftalık sınır', () {
    test('her hafta biraz iner, son hafta hedefe eşit', () {
      final g = goal(baseline: 15, amount: 4); // hedef 8
      expect([for (var w = 1; w <= 4; w++) weeklyLimit(g, w)], [14, 12, 10, 8]);
    });

    test('hedef değiştirilince sınırlar o anki seviyeden başlar', () {
      final g = goal(baseline: 15, from: 11, amount: 3); // hedef 8
      expect(weeklyLimit(g, 1), 10);
      expect(weeklyLimit(g, 3), 8);
    });

    test('zaten hedefin altındaysa sınır hep hedef', () {
      final g = goal(baseline: 15, from: 6, amount: 4);
      expect(weeklyLimit(g, 1), 8);
    });

    test('hafta numarası: süre dolunca son hafta kalır', () {
      final g = goal(amount: 2);
      expect(goalWeekOf(g, start), 1);
      expect(goalWeekOf(g, DateTime(2026, 10, 8)), 2);
      expect(goalWeekOf(g, DateTime(2026, 11, 20)), 2);
      expect(limitOn(g, DateTime(2026, 11, 20)), targetOf(g));
    });
  });

  group('zorluk', () {
    DateTime weeks(int n) => goalEndFrom(start, n, GoalUnit.week);

    test('haftada ne kadar azaltılacağına göre', () {
      expect(goalPace(25, start, weeks(4)), GoalPace.relaxed); // %6
      expect(goalPace(50, start, weeks(4)), GoalPace.balanced); // %12,5
      expect(goalPace(100, start, weeks(4)), GoalPace.ambitious); // %25
      expect(goalPace(100, start, weeks(1)), GoalPace.veryAmbitious);
    });

    test('önerilen süre her yüzde için "Dengeli"', () {
      for (final p in goalPercents) {
        expect(
          goalPace(p, start, weeks(suggestedWeeks(p))),
          GoalPace.balanced,
          reason: '%$p',
        );
      }
    });
  });

  group('hedefin durumu', () {
    // Başlangıç günde 10, hedef %50 → 5, 2 hafta: sınırlar 8 ve 5.
    final g = goal();
    final events = [
      for (var d = -7; d < 0; d++) ...smoke(d, 10), // önceki hafta
      ...smoke(0, 7), // 1. gün: sınırda (8) değil, altında
      ...smoke(1, 9), // 2. gün: sınırın üstünde
      ...smoke(2, 8), // 3. gün: tam sınırda
      ...smoke(3, 2), // bugün
    ];
    final now = DateTime(2026, 10, 4, 15);

    test('sınır, ilerleme ve şerit', () {
      final s = goalStatus(goal: g, events: events, now: now);
      expect(s.target, 5);
      expect(s.steps, 2);
      expect(s.week, 1);
      expect(s.limit, 8);
      expect(s.ended, isFalse);
      expect(s.daysSinceStart, 3);
      // Son 7 tamamlanmış gün: 4 × 10 + 7 + 9 + 8 = 64 → günde ~9,1.
      expect(s.currentLevel, closeTo(64 / 7, 1e-9));
      expect(s.progress, closeTo((10 - 64 / 7) / 5, 1e-9));
      expect(s.reached, isFalse);
      expect(s.daysOnTarget, 2);
      expect(
        [for (final d in s.days) d.state],
        [
          GoalDayState.onTarget,
          GoalDayState.over,
          GoalDayState.onTarget,
          GoalDayState.today,
          GoalDayState.future,
          GoalDayState.future,
          GoalDayState.future,
        ],
      );
      expect(s.days[3].count, 2);
    });

    test('bugün içilenler sayıları değiştirmez (gün bitmedi)', () {
      final busy = [...events, ...smoke(3, 5)];
      final s = goalStatus(goal: g, events: busy, now: now);
      final before = goalStatus(goal: g, events: events, now: now);
      expect(s.daysOnTarget, before.daysOnTarget);
      expect(s.progress, before.progress);
    });

    test('ilerleme 0 ile 1 arasında kalır', () {
      final more = goalStatus(
        goal: g,
        events: [for (var d = -7; d < 3; d++) ...smoke(d, 14)],
        now: now,
      );
      expect(more.progress, 0); // eksiye inmez
      final none = goalStatus(goal: g, events: const [], now: now);
      expect(none.progress, 1);
      expect(none.reached, isTrue);
    });

    test('süre dolunca şerit 7\'şer günlük dilimlerle devam eder', () {
      final later = DateTime(2026, 10, 20, 12); // 20. gün, süre doldu
      final s = goalStatus(goal: g, events: events, now: later);
      expect(s.ended, isTrue);
      expect(s.week, 2);
      expect(s.limit, 5);
      expect(s.days.first.day, DateTime(2026, 10, 15));
    });
  });

  group('Nefes\'in hedef cümlesi', () {
    GoalStatus status(List<SmokingEvent> events, DateTime now, {Goal? g}) =>
        goalStatus(goal: g ?? goal(), events: events, now: now);

    test('ilk gün: hedefin hazır', () {
      final line = goalLine(status(const [], DateTime(2026, 10, 1, 20)));
      expect(line.text, startsWith('Hedefin hazır!'));
    });

    test('hedefe ulaşınca kutlar (bırakmada "hiç saymadı")', () {
      final reached = goalLine(status(smoke(2, 3), DateTime(2026, 10, 5, 12)));
      expect(reached.text, startsWith('Hedefine ulaştın'));
      expect(reached.mood, MascotMood.cheer);
      final quit = goalLine(
        status(const [], DateTime(2026, 10, 5, 12), g: goal(percent: 100)),
      );
      expect(quit.text, contains('hiç sigara saymadı'));
    });

    test('ilerleme yoksa ya da süre dolduysa suçlamadan destekler', () {
      final heavy = [for (var d = -7; d < 30; d++) ...smoke(d, 12)];
      final early = goalLine(status(heavy, DateTime(2026, 10, 5, 12)));
      expect(early.text, startsWith('Her hafta küçük bir adım'));
      final ended = goalLine(status(heavy, DateTime(2026, 10, 25, 12)));
      expect(ended.text, contains('Olur böyle'));
      expect(ended.mood, MascotMood.calm);
    });
  });

  test('hedef kaydı: JSON ve bozuk kayıt', () {
    final g = goal(percent: 75, amount: 3, unit: GoalUnit.month);
    final back = Goal.fromJson(g.toJson())!;
    expect(back.start, g.start);
    expect(back.percent, 75);
    expect(back.amount, 3);
    expect(back.unit, GoalUnit.month);
    expect(back.baseline, 10);
    expect(Goal.fromJson({'start': 'dün'}), isNull);
  });
}
