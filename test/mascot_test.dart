import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unlit/models/mascot_look.dart';
import 'package:unlit/widgets/mascot.dart';
import 'package:unlit/widgets/mascot_painter.dart';
import 'package:unlit/widgets/svg_path.dart';

void main() {
  group('SVG yolu okuyucu', () {
    test('mutlak çizgiler ve kapatma', () {
      final bounds = svgPath('M0 0 L10 0 L10 10 Z').getBounds();
      expect(bounds, const Rect.fromLTRB(0, 0, 10, 10));
    });

    test('küçük harf = önceki noktaya göre; M sonrası sayılar çizgi', () {
      final bounds = svgPath('m5 5 10 0 0 10 h-10 v-10 z').getBounds();
      expect(bounds, const Rect.fromLTRB(5, 5, 15, 15));
    });

    test('eğriler ve yay da okunur', () {
      expect(
        svgPath('M0 0 Q5 -8 10 0 C12 4 14 4 16 0').getBounds().right,
        closeTo(16, 0.01),
      );
      // Yarım daire yayı: (0,0)'dan (20,0)'a, yarıçap 10 → aşağı 10 birim.
      final arc = svgPath('M0 0 A10 10 0 0 0 20 0').getBounds();
      expect(arc.width, closeTo(20, 0.5));
      expect(arc.height, closeTo(10, 0.5));
    });

    test('bilinmeyen komut hata verir', () {
      expect(() => svgPath('M0 0 S1 1 2 2'), throwsFormatException);
    });
  });

  group('maskot çizimi', () {
    test('her ruh hali × aşama × eşya hatasız çizilir', () {
      final looks = [
        for (var stage = 1; stage <= 4; stage++) ...[
          MascotLook(stage: stage),
          for (final a in Accessory.values)
            MascotLook(stage: stage, accessories: {a}),
          MascotLook(
            stage: stage,
            accessories: {Accessory.bere, Accessory.gozluk, Accessory.atki},
          ),
        ],
      ];
      for (final mood in MascotMood.values) {
        for (final look in looks) {
          final recorder = PictureRecorder();
          MascotPainter(
            mood: mood,
            look: look,
          ).paint(Canvas(recorder), const Size(96, 96));
          recorder.endRecording().dispose();
        }
      }
    });

    test('görünüş değişince yeniden çizilir', () {
      const a = MascotPainter(mood: MascotMood.happy, look: MascotLook.plain);
      const b = MascotPainter(
        mood: MascotMood.happy,
        look: MascotLook(accessories: {Accessory.atki}),
      );
      expect(b.shouldRepaint(a), isTrue);
      expect(a.shouldRepaint(a), isFalse);
    });

    testWidgets('Mascot görünüşü uygulamanın kökünden alır', (tester) async {
      const look = MascotLook(stage: 3, accessories: {Accessory.kep});
      await tester.pumpWidget(
        const MaterialApp(
          home: MascotAppearance(look: look, child: Mascot()),
        ),
      );
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(Mascot),
          matching: find.byType(CustomPaint),
        ),
      );
      expect((paint.painter! as MascotPainter).look, look);
    });

    test('görünüş eşitliği eşyaların sırasına bakmaz', () {
      expect(
        const MascotLook(accessories: {Accessory.atki, Accessory.kep}),
        const MascotLook(accessories: {Accessory.kep, Accessory.atki}),
      );
      expect(const MascotLook(stage: 2), isNot(const MascotLook(stage: 3)));
    });
  });
}
