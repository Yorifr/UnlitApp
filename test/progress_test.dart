import 'package:flutter_test/flutter_test.dart';
import 'package:unlit/logic/progress.dart';
import 'package:unlit/logic/stats.dart';
import 'package:unlit/models/smoking_event.dart';

/// [first] gününden başlayarak her gün [perDay] sigara (08:00'den saatte bir).
List<SmokingEvent> daysWith(DateTime first, List<int> perDay) => [
  for (var i = 0; i < perDay.length; i++)
    for (var h = 0; h < perDay[i]; h++)
      SmokingEvent(
        time: DateTime(first.year, first.month, first.day + i, 8 + h),
        source: EventSource.demo,
      ),
];

void main() {
  // Takip 1 Ekim'de başladı: ölçüm haftası 1–7 Ekim, 2. hafta 8–14 Ekim.
  final start = DateTime(2026, 10, 1, 9);
  final measurement = daysWith(DateTime(2026, 10, 1), List.filled(7, 10));

  test('ölçüm haftasında ve sonraki ilk 7 günde gösterilmez', () {
    final events = [
      ...measurement,
      ...daysWith(DateTime(2026, 10, 8), List.filled(6, 8)),
    ];
    // Ölçüm haftası sürüyor.
    expect(
      progressSinceStart(
        events: events,
        trackingStart: start,
        now: DateTime(2026, 10, 5),
      ),
      isNull,
    );
    // 14 Ekim: ölçümden sonra henüz 6 gün bitti ("şimdi" ölçüm haftasını
    // da içerirdi).
    expect(
      progressSinceStart(
        events: events,
        trackingStart: start,
        now: DateTime(2026, 10, 14, 12),
      ),
      isNull,
    );
  });

  test('başlangıç, şimdi ve yüzde değişim', () {
    final events = [
      ...measurement,
      ...daysWith(DateTime(2026, 10, 8), List.filled(7, 8)), // 2. hafta: 8
      ...daysWith(DateTime(2026, 10, 15), [3]), // bugün: sayılmaz
    ];
    final progress = progressSinceStart(
      events: events,
      trackingStart: start,
      now: DateTime(2026, 10, 15, 12),
    )!;
    expect(progress.baseline, 10);
    expect(progress.current, 8);
    expect(progress.changePercent, closeTo(-20, 0.001));
    // Hafta hafta: 1. hafta (ölçüm) 10, 2. hafta 8.
    expect([for (final w in progress.weeks) w.week], [1, 2]);
    expect([for (final w in progress.weeks) w.average], [10, 8]);
  });

  test('"şimdi" Hedefim ile aynı sayı (son 7 tamamlanmış gün)', () {
    final events = [
      ...measurement,
      ...daysWith(DateTime(2026, 10, 8), [12, 12, 12, 9, 9, 9, 9, 9, 9, 9]),
    ];
    final now = DateTime(2026, 10, 18, 20);
    final progress = progressSinceStart(
      events: events,
      trackingStart: start,
      now: now,
    )!;
    expect(progress.current, lastSevenDaysAverage(events, now));
    expect(progress.current, 9);
  });

  test('artış da gösterilir (eksi değil artı yüzde)', () {
    final events = [
      ...measurement,
      ...daysWith(DateTime(2026, 10, 8), List.filled(7, 12)),
    ];
    final progress = progressSinceStart(
      events: events,
      trackingStart: start,
      now: DateTime(2026, 10, 15),
    )!;
    expect(progress.changePercent, closeTo(20, 0.001));
  });

  test('ölçüm haftasında kayıt yoksa gösterilmez (başlangıç yok)', () {
    expect(
      progressSinceStart(
        events: daysWith(DateTime(2026, 10, 8), List.filled(7, 5)),
        trackingStart: start,
        now: DateTime(2026, 10, 20),
      ),
      isNull,
    );
  });

  test('grafikte 1. hafta + en yeni haftalar (en fazla 8 çubuk)', () {
    final events = [
      ...measurement,
      ...daysWith(DateTime(2026, 10, 8), List.filled(70, 9)), // 10 hafta
    ];
    // 12 hafta bitti (84 gün): 1. hafta + 6.–12. haftalar.
    final progress = progressSinceStart(
      events: events,
      trackingStart: start,
      now: DateTime(2026, 12, 24),
    )!;
    expect(progress.weeks.length, maxChartWeeks);
    expect(progress.weeks.first.week, 1);
    expect(progress.weeks[1].week, 6);
    expect(progress.weeks.last.week, 12);
  });
}
