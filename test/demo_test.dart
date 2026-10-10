import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unlit/models/smoking_event.dart';
import 'package:unlit/models/user_profile.dart';
import 'package:unlit/services/demo_day_planner.dart';
import 'package:unlit/services/demo_device_service.dart';
import 'package:unlit/services/storage_service.dart';

void main() {
  group('planDemoDay', () {
    test('60 gün boyunca her gün kurallara uyar', () {
      for (var i = 0; i < 60; i++) {
        final day = DateTime(2026, 9, 1 + i);
        final plan = planDemoDay(day, Random(i));

        // Günde 10–25 sigara
        expect(plan.length, inInclusiveRange(10, 25), reason: '$day');

        // Hepsi o gün içinde ve sıralı
        for (final t in plan) {
          expect(
            t.year == day.year && t.month == day.month && t.day == day.day,
            isTrue,
          );
        }
        for (var j = 1; j < plan.length; j++) {
          final gap = plan[j].difference(plan[j - 1]).inMinutes;
          expect(gap, greaterThanOrEqualTo(demoMinGapMinutes - 1));
        }

        // Uykuda sigara yok: ilk sigara sabah 06:00–12:00 arasında
        // (gece yarısından sonrası zaten "aynı gün" kontrolüyle elendi).
        expect(plan.first.hour, greaterThanOrEqualTo(6));
        expect(plan.first.hour, lessThan(12));
      }
    });

    test('aynı tohum aynı günü üretir (tekrarlanabilir)', () {
      final day = DateTime(2026, 10, 10);
      expect(planDemoDay(day, Random(42)), planDemoDay(day, Random(42)));
    });

    test('"ilk 5 dakika" cevabında ilk sigara erkenden içilir', () {
      // Hafta içi uyanma en geç 07:30, +5 dk → ilk sigara 07:36'dan önce.
      final plan = planDemoDay(
        DateTime(2026, 10, 7),
        Random(1),
        firstCigarette: FirstCigaretteTime.within5Min,
      );
      expect(plan.first.isBefore(DateTime(2026, 10, 7, 7, 36)), isTrue);
    });

    test('profildeki günlük sayıya yakın üretir', () {
      final counts = [
        for (var i = 0; i < 30; i++)
          planDemoDay(
            DateTime(2026, 9, 1 + i),
            Random(i),
            usualPerDay: 12,
          ).length,
      ];
      final average = counts.reduce((a, b) => a + b) / counts.length;
      expect(average, closeTo(12.6, 2)); // 12 ± 3, hafta sonu +2
    });
  });

  group('DemoDeviceService', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.create();
    });

    test('generateHistory son 15 günün gerçekçi verisini üretir', () async {
      final now = DateTime(2026, 10, 10, 15);
      final demo = DemoDeviceService(storage: storage, clock: () => now);
      final events = await demo.generateHistory();

      expect(events, isNotEmpty);
      expect(events.every((e) => e.source == EventSource.demo), isTrue);
      expect(events.every((e) => !e.time.isAfter(now)), isTrue);
      expect(events.first.time.isAfter(DateTime(2026, 9, 26)), isTrue);
      // 14 tam gün × 10–25 + bugünün bir kısmı
      expect(events.length, inInclusiveRange(14 * 10, 15 * 25));
      demo.dispose();
    });

    test('bağlanınca uygulama kapalıyken "içilenleri" gönderir', () async {
      var now = DateTime(2026, 10, 10, 6); // sabah 6, henüz sigara yok
      final demo = DemoDeviceService(storage: storage, clock: () => now);
      final received = <SmokingEvent>[];
      demo.events.listen(received.add);

      await demo.connect(); // ilk bağlantı: geçmiş yok
      await demo.disconnect();
      expect(received, isEmpty);

      // Uygulama gün boyu kapalı kaldı, akşam açıldı:
      now = DateTime(2026, 10, 10, 23, 59);
      await demo.connect();
      await demo.disconnect();
      await Future<void>.delayed(Duration.zero); // olayların ulaşmasını bekle

      expect(received.length, inInclusiveRange(10, 25));
      demo.dispose();
    });

    test('simulatePickup şu anki saatle bir olay gönderir', () async {
      final now = DateTime(2026, 10, 10, 12);
      final demo = DemoDeviceService(storage: storage, clock: () => now);
      final next = demo.events.first;
      demo.simulatePickup();
      expect((await next).time, now);
      demo.dispose();
    });
  });
}
