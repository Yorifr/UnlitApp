import 'package:flutter_test/flutter_test.dart';
import 'package:unlit/logic/wardrobe.dart';
import 'package:unlit/models/mascot_look.dart';

void main() {
  group('filizin büyümesi', () {
    test('aşamalar puan eşiklerinde değişir', () {
      expect(sproutStage(0), 1);
      expect(sproutStage(299), 1);
      expect(sproutStage(300), 2);
      expect(sproutStage(999), 2);
      expect(sproutStage(1000), 3);
      expect(sproutStage(2499), 3);
      expect(sproutStage(2500), 4);
      expect(sproutStage(100000), 4);
    });

    test('aşama ASLA geri gitmez (puan arttıkça hep aynı ya da büyük)', () {
      var previous = sproutStage(0);
      for (var xp = 1; xp <= 5000; xp++) {
        final stage = sproutStage(xp);
        expect(stage, greaterThanOrEqualTo(previous), reason: '$xp puan');
        previous = stage;
      }
    });

    test('sonraki aşamaya kalan puan', () {
      expect(pointsToNextStage(0), 300);
      expect(pointsToNextStage(250), 50);
      expect(pointsToNextStage(300), 700);
      expect(pointsToNextStage(2500), isNull); // çiçek açtı
    });
  });

  group('eşyaların açılması', () {
    Set<Accessory> unlocked({
      int xp = 0,
      int best = 0,
      bool measurement = false,
    }) => unlockedAccessories(
      totalXp: xp,
      bestStreak: best,
      measurementDone: measurement,
    );

    test('başlangıçta hiçbir şey açık değil', () {
      expect(unlocked(), isEmpty);
    });

    test('puanla açılanlar', () {
      expect(unlocked(xp: 99), isEmpty);
      expect(unlocked(xp: 100), {Accessory.gozluk});
      expect(unlocked(xp: 250), {Accessory.gozluk, Accessory.atki});
      expect(unlocked(xp: 500), contains(Accessory.kulaklik));
      expect(unlocked(xp: 1000), contains(Accessory.bere));
      // Puan ne kadar olursa olsun kep ve taç puanla açılmaz.
      expect(unlocked(xp: 99999), isNot(contains(Accessory.kep)));
      expect(unlocked(xp: 99999), isNot(contains(Accessory.tac)));
    });

    test('kep ölçüm haftası bitince, taç 7 günlük seride açılır', () {
      expect(unlocked(measurement: true), {Accessory.kep});
      expect(unlocked(best: 6), isEmpty);
      expect(unlocked(best: 7), {Accessory.tac});
    });

    test('açılan eşya kaybolmaz: girdiler arttıkça liste hiç küçülmez', () {
      var previous = <Accessory>{};
      for (var day = 0; day < 60; day++) {
        final now = unlocked(xp: day * 40, best: day, measurement: day >= 7);
        expect(now.containsAll(previous), isTrue, reason: '$day. gün');
        previous = now;
      }
      expect(previous, Accessory.values.toSet());
    });

    test('sonraki puan eşyası ve kalan puan', () {
      expect(nextPointUnlock(0), (
        accessory: Accessory.gozluk,
        pointsLeft: 100,
      ));
      expect(nextPointUnlock(130), (
        accessory: Accessory.atki,
        pointsLeft: 120,
      ));
      expect(nextPointUnlock(1000), isNull);
    });
  });

  group('takma ve çıkarma', () {
    test('aynı yerde tek eşya: kep takılınca bere çıkar', () {
      final worn = toggleAccessory({
        Accessory.bere,
        Accessory.atki,
      }, Accessory.kep);
      expect(worn, {Accessory.kep, Accessory.atki});
    });

    test('takılı eşyaya tekrar dokununca çıkar', () {
      expect(toggleAccessory({Accessory.gozluk}, Accessory.gozluk), isEmpty);
    });

    test('kilitli eşya takılı görünmez, her yerde en fazla bir eşya', () {
      final worn = wearable(
        {Accessory.bere, Accessory.kep, Accessory.gozluk},
        {Accessory.kep, Accessory.bere},
      );
      expect(worn.length, 1);
      expect(worn.single.slot, AccessorySlot.head);
    });

    test('yeni eşya sadece yeri boşsa otomatik takılır', () {
      expect(autoEquip({}, [Accessory.gozluk]), {Accessory.gozluk});
      // Başta kulaklık var: yeni açılan bere kullanıcının seçimini bozmaz.
      expect(autoEquip({Accessory.kulaklik}, [Accessory.bere]), {
        Accessory.kulaklik,
      });
    });
  });
}
