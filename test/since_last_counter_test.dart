import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unlit/theme.dart';
import 'package:unlit/widgets/since_last_counter.dart';

void main() {
  testWidgets('sayaç her saniye ilerler, 24 saatten sonra gün gösterir', (
    tester,
  ) async {
    // Sahte saat: testte zamanı biz ilerletiyoruz.
    final last = DateTime(2026, 10, 15, 9, 46, 55);
    var now = last.add(const Duration(hours: 2, minutes: 13, seconds: 5));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: SinceLastCounter(last: last, clock: () => now),
        ),
      ),
    );
    expect(find.text('02'), findsOneWidget);
    expect(find.text('13'), findsOneWidget);
    expect(find.text('05'), findsOneWidget);
    expect(find.text('saniye'), findsOneWidget);

    // Bir saniye sonra sayaç kendiliğinden yenilenir.
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('06'), findsOneWidget);
    expect(find.text('05'), findsNothing);

    // 3 gün 4 saat 12 dakika sonra: gün / saat / dakika.
    now = last.add(const Duration(days: 3, hours: 4, minutes: 12, seconds: 30));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('3'), findsOneWidget);
    expect(find.text('gün'), findsOneWidget);
    expect(find.text('04'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('saniye'), findsNothing);

    // Ekran okuyucu tek cümle okur.
    expect(
      find.bySemanticsLabel('Son sigarandan beri 3 gün 4 saat 12 dakika'),
      findsOneWidget,
    );
  });
}
