import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unlit/models/smoking_event.dart';
import 'package:unlit/models/user_profile.dart';
import 'package:unlit/logic/rewards.dart';
import 'package:unlit/logic/stats.dart';
import 'package:unlit/services/demo_activity.dart';
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

    test('ölçüm haftasından sonra demo kullanıcısı yavaşça azaltır', () {
      final start = DateTime(2026, 10, 1, 9); // ölçüm 1–7 Ekim
      expect(demoReduction(DateTime(2026, 10, 7), start), 0);
      expect(demoReduction(DateTime(2026, 10, 8), start), closeTo(0.05, 1e-9));
      expect(demoReduction(DateTime(2026, 10, 10), start), closeTo(0.09, 1e-9));
      expect(demoReduction(DateTime(2027, 1, 1), start), 0.30); // üst sınır
      expect(demoReduction(DateTime(2026, 10, 20), null), 0);

      // %30 azaltma gerçekten daha az sigara demek.
      final day = DateTime(2026, 10, 7);
      final normal = planDemoDay(day, Random(3)).length;
      final reduced = planDemoDay(day, Random(3), reduction: 0.3).length;
      expect(reduced, (normal * 0.7).round());
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
      // 14 tam gün × 10–25 + bugünün bir kısmı (ölçüm haftasından sonra
      // demo kullanıcısı biraz azaltsa da günde 10'un altına inmez).
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

  test('demo etkinliği seri, XP ve nedenler üretir (bugün hariç)', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final now = DateTime(2026, 10, 10, 15);
    final demo = DemoDeviceService(storage: storage, clock: () => now);
    final events = await demo.generateHistory();
    final start = startOfDay(events.first.time);

    final result = buildDemoActivity(
      events: events,
      trackingStart: start,
      now: now,
      random: Random(7),
    );
    final today = startOfDay(now);

    expect(result.events.length, events.length);
    expect(result.events.where((e) => e.trigger != null), isNotEmpty);
    expect(result.activity.totalXp, greaterThan(100));
    // Bugün boş: görevleri kullanıcı kendisi yapsın.
    expect(
      result.activity.xp.where((x) => startOfDay(x.time) == today),
      isEmpty,
    );
    // 15 günlük veri: 14 geçmiş gün, biri (10. gün) boş ama dinlenme günü
    // sayesinde seri sürüyor → 13 aktif gün.
    final streak = computeStreak(result.activity.xp, now);
    expect(streak.current, 13);
    expect(streak.activeToday, isFalse);
    demo.dispose();
  });
}
