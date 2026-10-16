import 'package:flutter_test/flutter_test.dart';
import 'package:unlit/logic/measurement.dart';
import 'package:unlit/logic/quests.dart';
import 'package:unlit/models/pack_price.dart';
import 'package:unlit/models/smoking_event.dart';
import 'package:unlit/models/user_profile.dart';
import 'package:unlit/widgets/pickers.dart';

/// [day] gününe, verilen saatlerde sigara olayları (sıralı).
List<SmokingEvent> onDay(
  DateTime day,
  List<int> hours, {
  SmokingTrigger? trigger,
}) => [
  for (final h in hours)
    SmokingEvent(
      time: DateTime(day.year, day.month, day.day, h, 15),
      source: EventSource.demo,
      trigger: trigger,
    ),
];

/// Her gün [perDay] sigara (08:15'ten başlayarak saatte bir).
List<SmokingEvent> daysWith(DateTime first, List<int> perDay) => [
  for (var i = 0; i < perDay.length; i++)
    ...onDay(DateTime(first.year, first.month, first.day + i), [
      for (var h = 0; h < perDay[i]; h++) 8 + h,
    ]),
];

void main() {
  // Takip 1 Ekim 14:00'te başladı → ölçüm haftası 1–7 Ekim, 8 Ekim 00:00'da biter.
  final start = DateTime(2026, 10, 1, 14);

  group('ölçüm haftası', () {
    test('bitişi 8. günün gece yarısı', () {
      expect(measurementEnd(start), DateTime(2026, 10, 8));
      expect(measurementOver(DateTime(2026, 10, 7, 23, 59), start), isFalse);
      expect(measurementOver(DateTime(2026, 10, 8), start), isTrue);
      expect(measurementOver(DateTime(2026, 10, 8), null), isFalse);
    });

    test('özet: ortalama, en yoğun saat, en sık neden, ilk sigara', () {
      final events = [
        // 1 Ekim: 08:15 kahve, 10:15 kahve, 10:15'ten sonra bir tane daha
        ...onDay(DateTime(2026, 10, 1), [
          8,
          10,
        ], trigger: SmokingTrigger.coffee),
        ...onDay(DateTime(2026, 10, 1), [12], trigger: SmokingTrigger.stress),
        // 2 Ekim: gece 01:15'teki sigara "ilk sigara" sayılmaz (04:00 kuralı)
        ...onDay(DateTime(2026, 10, 2), [1, 9, 10]),
        // Ölçüm haftasından SONRA: özete girmez
        ...onDay(DateTime(2026, 10, 9), [5, 6, 7, 8]),
      ];
      final summary = summarizeMeasurementWeek(events, start);

      expect(summary.total, 6);
      expect(summary.dailyAverage, closeTo(6 / 7, 0.001));
      expect(summary.peakHour, 10); // 10:00–11:00 iki kez
      expect(summary.topTrigger, SmokingTrigger.coffee);
      expect(summary.topTriggerCount, 2);
      // İlk sigaralar: 08:15 ve 09:15 → ortalama 08:45
      expect(summary.averageFirstMinute, 8 * 60 + 45);
    });

    test('kayıt yoksa özet boş ama çökmez', () {
      final summary = summarizeMeasurementWeek([], start);
      expect(summary.total, 0);
      expect(summary.peakHour, isNull);
      expect(summary.topTrigger, isNull);
      expect(summary.averageFirstMinute, isNull);
    });
  });

  group('ölçüm haftası 7 tam gün', () {
    test('gün ortasında başlanırsa ölçüm yarın 00:00\'da başlar', () {
      expect(
        trackingStartFor(DateTime(2026, 10, 10, 15, 30)),
        DateTime(2026, 10, 11),
      );
      expect(
        trackingStartFor(DateTime(2026, 10, 10, 4)),
        DateTime(2026, 10, 11),
      );
    });

    test('gece 04:00\'ten önce başlanırsa aynı gün başlar', () {
      expect(
        trackingStartFor(DateTime(2026, 10, 10, 1, 15)),
        DateTime(2026, 10, 10),
      );
    });

    test('hazırlık günündeki sigaralar başlangıç noktasına sayılmaz', () {
      final trackingStart = trackingStartFor(DateTime(2026, 10, 10, 15));
      final events = [
        ...onDay(DateTime(2026, 10, 10), [16, 17, 18]), // hazırlık günü
        ...daysWith(DateTime(2026, 10, 11), List.filled(7, 10)),
      ];
      final summary = summarizeMeasurementWeek(events, trackingStart);
      expect(summary.days, 7);
      expect(summary.total, 70);
      expect(summary.dailyAverage, 10);
      // Hazırlık günündeki 16:15 "günün ilk sigarası" ortalamasını kaydırmaz.
      expect(summary.averageFirstMinute, 8 * 60 + 15);
      expect(
        measurementDayNumber(DateTime(2026, 10, 10, 20), trackingStart),
        0,
      );
      expect(measurementDayNumber(DateTime(2026, 10, 11, 9), trackingStart), 1);
    });
  });

  group('Kazandıkların', () {
    final prices = PriceHistory([
      PackPrice(since: DateTime(2026, 10, 1), price: 100), // 5 ₺/sigara
    ]);
    // Ölçüm haftası: her gün 10 → ortalama 10.
    final week = daysWith(DateTime(2026, 10, 1), List.filled(7, 10));

    test('ölçüm haftasında hesaplanmaz', () {
      expect(
        computeGains(
          events: week,
          trackingStart: start,
          now: DateTime(2026, 10, 5),
          prices: prices,
        ),
        isNull,
      );
    });

    test('ortalamanın altındaki günler birikir; bugün sayılmaz', () {
      final events = [
        ...week,
        ...daysWith(DateTime(2026, 10, 8), [8, 7]), // 2 + 3 içilmedi
        ...onDay(DateTime(2026, 10, 10), [8]), // bugün: sayılmaz
      ];
      final gains = computeGains(
        events: events,
        trackingStart: start,
        now: DateTime(2026, 10, 10, 9),
        prices: prices,
      )!;
      expect(gains.baseline, 10);
      expect(gains.days, 2);
      expect(gains.notSmoked, 5);
      expect(gains.money, 25); // 5 × 5 ₺
      // Azaltılan günler korunan süreye sayılmaz (sadece sigarasız günler).
      expect(gains.smokeFreeDays, 0);
      expect(gains.lifeMinutes, 0);
    });

    test('korunan yaşam süresi sadece sigarasız günlerden', () {
      final events = [
        ...week,
        ...daysWith(DateTime(2026, 10, 8), [0, 7]), // sigarasız gün + azaltma
      ];
      final gains = computeGains(
        events: events,
        trackingStart: start,
        now: DateTime(2026, 10, 10, 9),
        prices: prices,
      )!;
      expect(gains.notSmoked, 13); // 10 + 3: azaltılan gün de burada
      expect(gains.smokeFreeDays, 1);
      // Sigarasız gün: başlangıç noktası (10) × 20 dk. Azaltılan gündeki
      // 3 sigara korunan süreye eklenmez.
      expect(gains.lifeMinutes, 200);
    });

    test('NET hesap: fazla içilen gün, az içilen günü dengeler', () {
      final events = [
        ...week,
        ...daysWith(DateTime(2026, 10, 8), [7, 13]), // −3, +3 → 0
      ];
      final gains = computeGains(
        events: events,
        trackingStart: start,
        now: DateTime(2026, 10, 10),
        prices: prices,
      )!;
      expect(gains.notSmoked, 0);
      expect(gains.money, 0);
    });

    test('toplam eksiye inmez', () {
      final events = [
        ...week,
        ...daysWith(DateTime(2026, 10, 8), [15, 15]),
      ];
      final gains = computeGains(
        events: events,
        trackingStart: start,
        now: DateTime(2026, 10, 10),
        prices: prices,
      )!;
      expect(gains.notSmoked, 0);
      expect(gains.money, 0);
    });

    test('para her gün o günün fiyatıyla (zam eski günleri değiştirmez)', () {
      final withRaise = PriceHistory([
        PackPrice(since: DateTime(2026, 10, 1), price: 100), // 5 ₺
        PackPrice(since: DateTime(2026, 10, 9), price: 200), // 10 ₺
      ]);
      final events = [
        ...week,
        ...daysWith(DateTime(2026, 10, 8), [8, 8]), // 2 + 2 içilmedi
      ];
      final gains = computeGains(
        events: events,
        trackingStart: start,
        now: DateTime(2026, 10, 10),
        prices: withRaise,
      )!;
      expect(gains.money, 2 * 5 + 2 * 10);
    });

    test('fiyat yoksa para null; ölçümde kayıt yoksa hiç hesap yok', () {
      final noPrice = computeGains(
        events: [
          ...week,
          ...daysWith(DateTime(2026, 10, 8), [5]),
        ],
        trackingStart: start,
        now: DateTime(2026, 10, 9),
        prices: PriceHistory(),
      )!;
      expect(noPrice.notSmoked, 5);
      expect(noPrice.money, isNull);

      expect(
        computeGains(
          events: daysWith(DateTime(2026, 10, 8), [5]),
          trackingStart: start,
          now: DateTime(2026, 10, 9),
          prices: prices,
        ),
        isNull,
      );
    });
  });

  test('"Neden?" listesi: kullanıcının seçtikleri başta', () {
    final order = triggersInOrder({SmokingTrigger.phone, SmokingTrigger.tea});
    expect(order.take(2), [SmokingTrigger.tea, SmokingTrigger.phone]);
    expect(order.length, SmokingTrigger.values.length);
    expect(triggersInOrder({}), SmokingTrigger.values);
  });
}
