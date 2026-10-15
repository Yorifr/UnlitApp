import 'package:flutter_test/flutter_test.dart';
import 'package:unlit/utils/format.dart';

void main() {
  test('binlik ayraç', () {
    expect(formatThousands(0), '0');
    expect(formatThousands(999), '999');
    expect(formatThousands(1000), '1.000');
    expect(formatThousands(1234567), '1.234.567');
  });

  test('para kuruşsuz ve ₺ ile yazılır', () {
    expect(formatMoney(57), '57 ₺');
    expect(formatMoney(1234.6), '1.235 ₺');
  });

  test('süre: dk, sa, gün', () {
    expect(formatDuration(0), '0 dk');
    expect(formatDuration(45), '45 dk');
    expect(formatDuration(60), '1 sa');
    expect(formatDuration(200), '3 sa 20 dk');
    expect(formatDuration(24 * 60), '1 gün');
    expect(formatDuration(3000), '2 gün 2 sa');
  });

  test('Türkçe tarih ve gün adları', () {
    final saturday = DateTime(2026, 10, 10, 7, 5);
    expect(formatLongDate(saturday), '10 Ekim Cumartesi');
    expect(weekdayLower(saturday), 'cumartesi');
    expect(weekdayShort(saturday), 'Cmt');
    expect(formatClock(saturday), '07:05');
  });

  test('ne kadar önce', () {
    final now = DateTime(2026, 10, 10, 12);
    expect(formatTimeAgo(now, now), 'az önce');
    expect(
      formatTimeAgo(now.subtract(const Duration(minutes: 35)), now),
      '35 dk önce',
    );
    expect(
      formatTimeAgo(now.subtract(const Duration(hours: 3)), now),
      '3 sa önce',
    );
  });

  test('sayaç: 24 saatten az saat/dakika/saniye, sonra gün/saat/dakika', () {
    String show(Duration d) =>
        sinceCounterParts(d).map((p) => '${p.text} ${p.unit}').join(' ');

    expect(show(Duration.zero), '00 saat 00 dakika 00 saniye');
    expect(
      show(const Duration(hours: 2, minutes: 14, seconds: 5)),
      '02 saat 14 dakika 05 saniye',
    );
    expect(
      show(const Duration(hours: 23, minutes: 59, seconds: 59)),
      '23 saat 59 dakika 59 saniye',
    );
    // Tam 24 saat → gün başlar, saniye artık gösterilmez.
    expect(show(const Duration(hours: 24)), '1 gün 00 saat 00 dakika');
    expect(
      show(const Duration(days: 3, hours: 4, minutes: 12, seconds: 59)),
      '3 gün 04 saat 12 dakika',
    );
    expect(show(const Duration(days: 120)), '120 gün 00 saat 00 dakika');
    // Telefonun saati geri alınırsa eksi süre 0 sayılır.
    expect(show(const Duration(minutes: -5)), '00 saat 00 dakika 00 saniye');
  });

  test('fiyat yazımı ve okunması', () {
    expect(parsePrice('95,50'), 95.5);
    expect(parsePrice(' 110 '), 110);
    expect(parsePrice('0'), isNull);
    expect(parsePrice('abc'), isNull);
    expect(priceToInput(95.5), '95,5');
    expect(priceToInput(110), '110');
  });

  test('Türkçe ekler: paket boyutu ve "…’den beri"', () {
    expect(perPackLabel(10), '10’lu');
    expect(perPackLabel(20), '20’li');
    expect(perPackLabel(25), '25’li');
    expect(perPackLabel(40), '40’lı');
    expect(formatSince(DateTime(2026, 10, 5)), '5 Ekim’den beri');
    expect(formatSince(DateTime(2026, 8, 10)), '10 Ağustos’tan beri');
    expect(formatSince(DateTime(2026, 11, 1)), '1 Kasım’dan beri');
  });

  test('ondalık sayı virgülle, tek basamak', () {
    expect(formatDecimal(17.33), '17,3');
    expect(formatDecimal(15), '15');
    expect(formatDecimal(14.96), '15');
  });

  test('saat ve saat aralığı', () {
    expect(formatMinuteOfDay(465), '07:45');
    expect(formatHourRange(10), '10:00–11:00');
    expect(formatHourRange(23), '23:00–00:00');
  });

  test('yüzde işareti sayıdan önce gelir', () {
    expect(formatPercent(-10.4), '%10');
    expect(formatPercent(12.6), '%13');
  });
}
