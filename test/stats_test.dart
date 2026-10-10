import 'package:flutter_test/flutter_test.dart';
import 'package:unlit/logic/stats.dart';
import 'package:unlit/models/smoking_event.dart';
import 'package:unlit/models/user_profile.dart';

/// Kısa yoldan test olayı oluşturur.
SmokingEvent at(DateTime time) =>
    SmokingEvent(time: time, source: EventSource.demo);

void main() {
  // Testlerdeki "şu an": 10 Ekim 2026 Cumartesi 15:00
  final now = DateTime(2026, 10, 10, 15);

  test('bugünkü sayı sadece gece yarısından bu yana olanları sayar', () {
    final events = [
      at(DateTime(2026, 10, 9, 23, 50)), // dün
      at(DateTime(2026, 10, 10, 7, 30)),
      at(DateTime(2026, 10, 10, 14, 59)),
      at(now), // tam şu an da sayılmalı
    ];
    expect(countToday(events, now), 3);
  });

  test('geçen haftanın aynı günü, aynı saate kadar', () {
    final events = [
      at(DateTime(2026, 10, 3, 8)), // geçen cumartesi sabah → sayılır
      at(DateTime(2026, 10, 3, 14)), // geçen cumartesi 14:00 → sayılır
      at(DateTime(2026, 10, 3, 16)), // 15:00'ten sonra → sayılmaz
    ];
    expect(countSameDayLastWeek(events, now), 2);
  });

  test('haftalık karşılaştırma ve yüzde', () {
    final events = [
      // Önceki 7 gün: 10 sigara
      for (var i = 0; i < 10; i++) at(DateTime(2026, 9, 28, 8 + i)),
      // Son 7 gün: 9 sigara
      for (var i = 0; i < 9; i++) at(DateTime(2026, 10, 6, 8 + i)),
    ];
    final c = compareWeeks(events, now);
    expect(c.lastWeek, 10);
    expect(c.thisWeek, 9);
    expect(c.changePercent, closeTo(-10, 0.001)); // %10 azalma
  });

  test('önceki hafta boşsa yüzde hesaplanmaz', () {
    final c = compareWeeks([at(DateTime(2026, 10, 9, 9))], now);
    expect(c.changePercent, isNull);
  });

  test('kayıtlar yeterince eskiden başlamış mı?', () {
    final events = [at(DateTime(2026, 10, 1, 8))];
    expect(hasDataSince(events, DateTime(2026, 10, 3)), isTrue);
    expect(hasDataSince(events, DateTime(2026, 9, 30)), isFalse);
    expect(hasDataSince([], now), isFalse);
  });

  test('günlük ve saatlik sayılar', () {
    final events = [
      at(DateTime(2026, 10, 4, 9)), // 7 günlük pencerenin dışında
      at(DateTime(2026, 10, 9, 9)),
      at(DateTime(2026, 10, 10, 8, 10)),
      at(DateTime(2026, 10, 10, 8, 50)),
      at(DateTime(2026, 10, 10, 13)),
    ];
    final days = dailyCounts(events, now, days: 7);
    expect(days.length, 7);
    expect(days.first.day, DateTime(2026, 10, 4));
    expect(days.first.count, 1);
    expect(days.last.day, DateTime(2026, 10, 10));
    expect(days.last.count, 3);

    final hours = hourlyCounts(events, now);
    expect(hours[8], 2);
    expect(hours[13], 1);
    expect(hours.reduce((a, b) => a + b), 3);

    expect(firstEventOfDay(events, now), DateTime(2026, 10, 10, 8, 10));
  });

  test('para: paket fiyatı / paketteki adet', () {
    final profile = UserProfile(packPrice: 100, cigarettesPerPack: 20);
    expect(moneyFor(12, profile), 60); // 12 × 5 ₺
    expect(moneyFor(12, UserProfile()), isNull); // fiyat bilinmiyor
  });

  test('yaşam süresi: erkek 17, kadın 22, belirtilmemiş 20 dk', () {
    expect(lifeMinutesFor(10, Gender.male), 170);
    expect(lifeMinutesFor(10, Gender.female), 220);
    expect(lifeMinutesFor(10, Gender.unspecified), 200);
    expect(lifeMinutesFor(10, null), 200);
  });

  test('sigaraya giden süre varsayımı', () {
    expect(smokingMinutesFor(10), 10 * minutesPerCigarette);
  });
}
