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

  test('yüzde işareti sayıdan önce gelir', () {
    expect(formatPercent(-10.4), '%10');
    expect(formatPercent(12.6), '%13');
  });
}
