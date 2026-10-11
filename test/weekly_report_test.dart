import 'package:flutter_test/flutter_test.dart';
import 'package:unlit/logic/mascot_messages.dart';
import 'package:unlit/logic/weekly_report.dart';
import 'package:unlit/models/activity_log.dart';
import 'package:unlit/models/pack_price.dart';
import 'package:unlit/models/smoking_event.dart';
import 'package:unlit/models/user_profile.dart';
import 'package:unlit/utils/format.dart';
import 'package:unlit/widgets/mascot.dart';

/// [first] gününden başlayarak her gün [perDay] sigara (08:15'ten itibaren
/// saatte bir; [trigger] verilirse hepsi o nedenle işaretli).
List<SmokingEvent> daysWith(
  DateTime first,
  List<int> perDay, {
  SmokingTrigger? trigger,
}) => [
  for (var i = 0; i < perDay.length; i++)
    for (var h = 0; h < perDay[i]; h++)
      SmokingEvent(
        time: DateTime(first.year, first.month, first.day + i, 8 + h, 15),
        source: EventSource.demo,
        trigger: trigger,
      ),
];

void main() {
  // Takip 1 Ekim 14:00'te başladı:
  // 1. hafta (ölçüm) 1–7 Ekim, 2. hafta 8–14 Ekim, 3. hafta 15–21 Ekim.
  final start = DateTime(2026, 10, 1, 14);
  final prices = PriceHistory([
    PackPrice(since: DateTime(2026, 10, 1), price: 100), // 5 ₺/sigara
  ]);
  // Ölçüm haftası her gün 10 → başlangıç noktası günde 10.
  final measurement = daysWith(DateTime(2026, 10, 1), List.filled(7, 10));

  WeeklyReport? report(
    int week, {
    required List<SmokingEvent> events,
    ActivityLog? activity,
    DateTime? now,
    PriceHistory? withPrices,
  }) => buildWeeklyReport(
    week: week,
    events: events,
    activity: activity ?? ActivityLog(),
    trackingStart: start,
    now: now ?? DateTime(2026, 10, 15, 9),
    prices: withPrices ?? prices,
  );

  group('haftalar', () {
    test('takibin günleri ve biten haftalar', () {
      expect(trackingDayNumber(DateTime(2026, 10, 1, 8), start), 1);
      expect(trackingDayNumber(DateTime(2026, 10, 8), start), 8);
      expect(weekStart(start, 1), DateTime(2026, 10, 1));
      expect(weekStart(start, 3), DateTime(2026, 10, 15));

      expect(completedWeeks(DateTime(2026, 10, 7, 23, 59), start), 0);
      expect(completedWeeks(DateTime(2026, 10, 8), start), 1); // ölçüm bitti
      expect(completedWeeks(DateTime(2026, 10, 14, 23), start), 1);
      expect(completedWeeks(DateTime(2026, 10, 15), start), 2);
      expect(completedWeeks(DateTime(2026, 10, 15), null), 0);
    });

    test('sadece biten haftalar raporlanır; 1. hafta ölçüm özetidir', () {
      final events = [
        ...measurement,
        ...daysWith(DateTime(2026, 10, 8), List.filled(7, 8)),
      ];
      final day14 = DateTime(2026, 10, 14, 22);
      expect(report(2, events: events, now: day14), isNull); // bitmedi
      expect(report(1, events: events), isNull); // ölçüm haftası
      expect(report(3, events: events), isNull); // gelecek
      expect(report(2, events: events), isNotNull);
    });
  });

  group('rapor', () {
    test('sigara: toplam, önceki hafta, grafik, net kazanç', () {
      final events = [
        ...measurement,
        // 2. hafta: 8, 8, 8, 8, 8, 12, 12 → 64 (ölçüm haftası 70)
        ...daysWith(DateTime(2026, 10, 8), [8, 8, 8, 8, 8, 12, 12]),
        // 3. haftanın ilk günü: rapora girmez
        ...daysWith(DateTime(2026, 10, 15), [3]),
      ];
      final r = report(2, events: events)!;

      expect(r.start, DateTime(2026, 10, 8));
      expect(r.lastDay, DateTime(2026, 10, 14));
      expect(r.total, 64);
      expect(r.previous.total, 70);
      expect(r.previousIsMeasurement, isTrue);
      expect(r.changeFromPrevious, -6);
      expect(r.days.map((d) => d.count), [8, 8, 8, 8, 8, 12, 12]);
      expect(r.summary.dailyAverage, closeTo(64 / 7, 1e-9));
      // NET: 5 gün −2 = 10 içilmedi, 2 gün +2 = 4 fazla → 6
      expect(r.gains!.baseline, 10);
      expect(r.notSmoked, 6);
      expect(r.gains!.money, 30); // 6 × 5 ₺
    });

    test('artış olan haftada kazanç 0, eksiye inmez', () {
      final events = [
        ...measurement,
        ...daysWith(DateTime(2026, 10, 8), List.filled(7, 12)),
      ];
      final r = report(2, events: events)!;
      expect(r.changeFromPrevious, 14);
      expect(r.notSmoked, 0);
      expect(r.gains!.money, 0);
    });

    test('ölçüm haftasında kayıt yoksa başlangıç noktası yok', () {
      final r = report(
        2,
        events: daysWith(DateTime(2026, 10, 8), List.filled(7, 5)),
      )!;
      expect(r.gains, isNull);
      expect(r.notSmoked, 0);
      expect(r.previous.total, 0);
    });

    test('örüntü: en yoğun saat, en sık neden, ilk sigara', () {
      final events = [
        ...measurement,
        ...daysWith(
          DateTime(2026, 10, 8),
          List.filled(7, 3),
          trigger: SmokingTrigger.coffee,
        ),
      ];
      final r = report(2, events: events)!;
      expect(r.summary.peakHour, 8); // eşitlikte en erken saat
      expect(r.summary.topTrigger, SmokingTrigger.coffee);
      expect(r.summary.topTriggerCount, 21);
      expect(r.summary.averageFirstMinute, 8 * 60 + 15);
      expect(r.previous.averageFirstMinute, 8 * 60 + 15);
    });

    test('kendine iyi baktığın anlar: sadece o haftanın kayıtları', () {
      final activity = ActivityLog(
        moods: [
          MoodEntry(time: DateTime(2026, 10, 8, 9), mood: Mood.good),
          MoodEntry(time: DateTime(2026, 10, 9, 9), mood: Mood.good),
          MoodEntry(time: DateTime(2026, 10, 10, 9), mood: Mood.hard),
          MoodEntry(time: DateTime(2026, 10, 3, 9), mood: Mood.great), // 1. h.
        ],
        delays: [
          DelayAttempt(
            start: DateTime(2026, 10, 9, 11),
            end: DateTime(2026, 10, 9, 11, 10),
            outcome: DelayOutcome.success,
          ),
          DelayAttempt(
            start: DateTime(2026, 10, 9, 15),
            end: DateTime(2026, 10, 9, 15, 4),
            outcome: DelayOutcome.gaveIn,
          ),
        ],
        breaths: [DateTime(2026, 10, 8, 14), DateTime(2026, 10, 15, 8)],
        xp: [
          XpEntry(
            time: DateTime(2026, 10, 8, 9),
            amount: 10,
            reason: XpReason.questCheckIn,
          ),
          XpEntry(
            time: DateTime(2026, 10, 9, 9),
            amount: 10,
            reason: XpReason.questCheckIn,
          ),
          XpEntry(
            time: DateTime(2026, 10, 9, 11, 10),
            amount: 15,
            reason: XpReason.delaySuccess,
          ),
          XpEntry(
            time: DateTime(2026, 10, 1, 14),
            amount: 10,
            reason: XpReason.welcome,
          ), // 1. hafta: sayılmaz
        ],
      );
      final r = report(2, events: measurement, activity: activity)!;
      expect(r.activeDays, 2);
      expect(r.xp, 35);
      expect(r.successfulDelays, 1);
      expect(r.breaths, 1);
      // Ruh hali sırası soldan sağa olumsuzdan olumluya.
      expect(r.moods, {Mood.hard: 1, Mood.good: 2});
      expect(r.moods.keys.toList(), [Mood.hard, Mood.good]);
      expect(r.isEmpty, isFalse);
    });

    test('hiçbir şey olmayan hafta "boş" sayılır', () {
      expect(report(2, events: measurement)!.isEmpty, isTrue);
    });
  });

  group('maskotun cümlesi (suçlama yok)', () {
    WeeklyReport withSecondWeek(List<int> perDay, {ActivityLog? activity}) =>
        report(
          2,
          events: [...measurement, ...daysWith(DateTime(2026, 10, 8), perDay)],
          activity: activity,
        )!;

    test('azalma kutlanır, sayı kullanıcının kendi verisi', () {
      final line = weeklyReportLine(withSecondWeek(List.filled(7, 9)));
      expect(line.mood, MascotMood.cheer);
      expect(line.text, contains('Ölçüm haftana göre 7 sigara daha az'));
    });

    test('önceki haftadan fazla ama başlangıcın altında: yine olumlu', () {
      final r = report(
        3,
        events: [
          ...measurement,
          ...daysWith(DateTime(2026, 10, 8), List.filled(7, 6)), // 42
          ...daysWith(DateTime(2026, 10, 15), List.filled(7, 8)), // 56
        ],
        now: DateTime(2026, 10, 22, 9),
      )!;
      expect(r.changeFromPrevious, 14);
      final line = weeklyReportLine(r);
      expect(line.mood, MascotMood.cheer);
      expect(line.text, contains('14 sigara daha az'));
      expect(line.text, contains('Başlangıç noktanın altındasın'));
    });

    test('artışta sakin ve destekleyici; kendine iyi baktığı günler', () {
      final activity = ActivityLog(
        xp: [
          XpEntry(
            time: DateTime(2026, 10, 9, 9),
            amount: 10,
            reason: XpReason.questCheckIn,
          ),
        ],
      );
      final line = weeklyReportLine(
        withSecondWeek(List.filled(7, 12), activity: activity),
      );
      expect(line.mood, MascotMood.calm);
      expect(line.text, contains('olur böyle'));
      expect(line.text, contains('1 gün kendine iyi baktın'));
      for (final word in ['kötü', 'maalesef', 'başaramadın', 'fazla']) {
        expect(line.text.contains(word), isFalse, reason: word);
      }
    });

    test('aynı hafta ve hiç kayıt olmayan hafta', () {
      final same = weeklyReportLine(withSecondWeek(List.filled(7, 10)));
      expect(same.text, contains('aynı: 70 sigara'));
      final none = weeklyReportLine(withSecondWeek(List.filled(7, 0)));
      expect(none.text, contains('hiç sigara saymadı'));
    });
  });

  group('gelecek hafta için bir fikir', () {
    WeeklyReport tagged(SmokingTrigger? trigger) => report(
      2,
      events: [
        ...measurement,
        ...daysWith(DateTime(2026, 10, 8), [2], trigger: trigger),
      ],
    )!;

    test('en sık nedene göre erteleme önerir', () {
      expect(
        weeklyTip(tagged(SmokingTrigger.coffee)),
        contains('kahveden sonra gelen bir isteği 10 dakika ertelemeyi'),
      );
      // Her nedenin bir cümlesi var.
      for (final t in SmokingTrigger.values) {
        expect(weeklyTip(tagged(t)), isNot(contains('null')), reason: '$t');
      }
    });

    test('stres → nefes molası; neden yoksa en yoğun saat', () {
      expect(
        weeklyTip(tagged(SmokingTrigger.stress)),
        contains('nefes molası'),
      );
      expect(weeklyTip(tagged(null)), contains('08:00–09:00'));
    });
  });

  test('gün aralığı yazımı', () {
    expect(
      formatDayRange(DateTime(2026, 10, 8), DateTime(2026, 10, 14)),
      '8–14 Ekim',
    );
    expect(
      formatDayRange(DateTime(2026, 9, 29), DateTime(2026, 10, 5)),
      '29 Eylül – 5 Ekim',
    );
  });
}
