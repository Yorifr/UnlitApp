import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unlit/app.dart';
import 'package:unlit/app_state.dart';
import 'package:unlit/models/user_profile.dart';
import 'package:unlit/services/demo_device_service.dart';
import 'package:unlit/services/effects.dart';
import 'package:unlit/services/storage_service.dart';

import 'test_helpers.dart';

/// Testlerde çalınan sesleri kaydeden sahte oynatıcı.
late RecordingPlayer sounds;

/// Uygulamayı boş bir hafızayla, telefon boyutunda başlatıp [body]'yi
/// çalıştıran test. Sonunda demo kılıfın zamanlayıcısını durdurur (yoksa
/// Flutter test "bekleyen zamanlayıcı var" diye hata verir).
void testApp(
  String description,
  Future<void> Function(WidgetTester tester, AppState state) body,
) {
  testWidgets(description, (tester) async {
    // iPhone benzeri ekran: 390 × 844
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final demo = DemoDeviceService(storage: storage);
    final state = AppState(storage: storage, device: demo);
    sounds = RecordingPlayer();
    Effects.init(storage, sounds);
    await state.start();
    await tester.pumpWidget(UnlitApp(state: state));

    try {
      await body(tester, state);
    } finally {
      await demo.disconnect();
    }
  });
}

/// Onboarding'i "ATLA" ile geçip ana ekrana gel.
Future<void> skipOnboarding(WidgetTester tester) async {
  await tester.tap(find.text('ATLA'));
  await tester.pumpAndSettle();
}

/// Ekranın altında kalmış bir şeyi görünür yapıp ona dokun.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.byType(Scrollable).hitTestable().first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  testApp('ilk açılışta onboarding, "ATLA" ile ana ekran', (
    tester,
    state,
  ) async {
    expect(find.text('Merhaba! Ben Nefes.'), findsOneWidget);
    expect(
      find.text('Bilgilerin sadece bu telefonda kalır, kimseyle paylaşılmaz.'),
      findsOneWidget,
    );

    await skipOnboarding(tester);

    expect(state.onboardingDone, isTrue);
    expect(find.text('Günlük görevler'), findsOneWidget);
    expect(find.text('CANIM SİGARA İSTİYOR'), findsOneWidget);
    // Hoş geldin XP'si verildi, seri başladı.
    expect(state.totalXp, 10);
    expect(state.streak.current, 1);
  });

  testApp('sorular cevaplanınca profile kaydedilir', (tester, state) async {
    await tester.tap(find.text('BAŞLAYALIM'));
    await tester.pumpAndSettle();

    // Cevap yokken buton "ŞİMDİLİK GEÇ" der.
    expect(find.text('ŞİMDİLİK GEÇ'), findsOneWidget);

    // "Neden soruyoruz?" açıklaması açılır.
    await tester.tap(find.text('Neden soruyoruz?'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Ölçüm haftasının sonunda bu tahminini'),
      findsOneWidget,
    );

    // Günlük sigara: ilk "+" 15'ten başlar, ikinci "+" 16 yapar.
    await tester.tap(find.byTooltip('Artır'));
    await tester.pump();
    await tester.tap(find.byTooltip('Artır'));
    await tester.pump();
    expect(find.text('16'), findsOneWidget);
    expect(find.text('DEVAM'), findsOneWidget);

    await tester.tap(find.text('DEVAM'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(FirstCigaretteTime.within5Min.label));
    await tester.pump();
    await tester.tap(find.text('DEVAM'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '95,50');
    await tester.pump();
    await tester.tap(find.text('DEVAM'));
    await tester.pumpAndSettle();

    // Son soru: tetikleyiciler. Sadece 4 soru var, sonra "Hazırsın!".
    await tester.tap(find.text('Çay'));
    await tester.pump();
    await tester.tap(find.text('DEVAM'));
    await tester.pumpAndSettle();
    expect(find.text('Hazırsın!'), findsOneWidget);
    expect(find.text('+10 puan'), findsOneWidget);
    await tester.tap(find.text('BAŞLA'));
    await tester.pumpAndSettle();

    expect(state.profile.cigarettesPerDay, 16);
    expect(state.profile.firstCigarette, FirstCigaretteTime.within5Min);
    expect(state.profile.triggers, {SmokingTrigger.tea});
    // Fiyat profilde değil, tarihli fiyat geçmişinde; paket varsayılan 20'li.
    expect(state.prices.current!.price, 95.5);
    expect(state.prices.current!.perPack, 20);
    expect(find.text('Günlük görevler'), findsOneWidget);
  });

  testApp('"Kendini dinle" kutlama ekranı açar ve puan verir', (
    tester,
    state,
  ) async {
    await skipOnboarding(tester);
    final xpBefore = state.totalXp;
    // Ruh hali için tek giriş noktası var: görev satırı.
    expect(find.text('Bugün nasıl hissediyorsun?'), findsNothing);

    await scrollAndTap(tester, find.text('Kendini dinle'));
    await tester.pumpAndSettle();
    // Soldan sağa olumsuzdan olumluya: "Çok zor" en solda, "Harika" en sağda.
    final x = [
      for (final mood in ['Çok zor', 'Zor', 'İdare eder', 'İyi', 'Harika'])
        tester.getCenter(find.text(mood)).dx,
    ];
    for (var i = 1; i < x.length; i++) {
      expect(x[i], greaterThan(x[i - 1]));
    }

    await tester.tap(find.text('İyi'));
    await tester.pumpAndSettle();

    expect(find.text('Görev tamamlandı!'), findsOneWidget);
    expect(state.totalXp, xpBefore + 10);
    expect(sounds.played.last, Sfx.success.asset); // "ding-ding"

    await tester.tap(find.text('DEVAM'));
    await tester.pumpAndSettle();
    expect(find.text('Günlük görevler'), findsOneWidget);
  });

  testApp('erteleme: "İSTEK GEÇTİ" ile kutlama', (tester, state) async {
    await skipOnboarding(tester);

    await tester.tap(find.text('CANIM SİGARA İSTİYOR'));
    // Erteleme ekranında saniyelik sayaç var; pumpAndSettle yerine pump.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('kaldı'), findsOneWidget);
    expect(state.activeDelayStart, isNotNull);

    await scrollAndTapNoSettle(tester, find.text('İSTEK GEÇTİ'));
    await tester.pumpAndSettle();

    expect(find.text('Başardın!'), findsOneWidget);
    expect(sounds.played.last, Sfx.fanfare.asset); // büyük kutlama
    expect(state.successfulDelays, 1);
    expect(state.activeDelayStart, isNull);
  });

  testApp('nefes egzersizi "al" ve "ver" anlarında ses verir', (
    tester,
    state,
  ) async {
    await skipOnboarding(tester);
    await scrollAndTap(tester, find.text('Nefes molası'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('BAŞLA'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(sounds.played.last, Sfx.breathIn.asset);
    await tester.pump(const Duration(seconds: 4));
    expect(sounds.played.last, Sfx.breathOut.asset);

    // Yarıda bırakmak serbest: kapat, ceza yok.
    await tester.tap(find.byTooltip('Kapat'));
    await tester.pumpAndSettle();
    expect(find.text('Günlük görevler'), findsOneWidget);
  });

  testApp('demo verisi üretilince her yer dolar', (tester, state) async {
    await skipOnboarding(tester);

    await scrollAndTap(tester, find.text('DEMO VERİSİ ÜRET'));
    await tester.pumpAndSettle();

    // Sigara kaydı (kılıftan "+1") hiçbir ses ya da kutlama tetiklemez.
    final soundsBefore = sounds.played.length;
    await tester.drag(
      find.byType(Scrollable).hitTestable().first,
      const Offset(0, 3000), // en üste kaydır
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('+1 sigara'));
    await tester.pumpAndSettle();
    expect(sounds.played.length, soundsBefore);

    expect(state.events.length, greaterThan(100));
    expect(state.streak.current, greaterThan(5));
    // Ölçüm haftası geçmişte kaldı → erteleme görevi geldi.
    expect(state.measurementDay, isNull);

    // "Ölçüm haftan bitti!" özeti bir kez gösterilir.
    expect(state.measurementSummaryPending, isTrue);
    await tester.tap(find.text('SONUÇLARIMI GÖR'));
    await tester.pumpAndSettle();
    expect(find.text('Ölçüm haftan bitti!'), findsOneWidget);
    expect(find.text('Günde ortalama'), findsOneWidget);
    await scrollAndTap(tester, find.text('DEVAM'));
    await tester.pumpAndSettle();
    expect(state.measurementSummaryPending, isFalse);
    expect(find.text('SONUÇLARIMI GÖR'), findsNothing);

    await tester.tap(find.text('İstatistik'));
    await tester.pumpAndSettle();
    expect(find.text('sigara\nbugün'), findsOneWidget);
    expect(find.text('Geçen haftayla karşılaştırma'), findsOneWidget);
    // "Kaybedilen yaşam" yok; aynı kaynak "korunan" tarafta.
    expect(find.textContaining('kaybedilen'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Korunan yaşam süresi'),
      250,
      scrollable: find.byType(Scrollable).hitTestable().first,
    );
    expect(find.text('Kazandıkların'), findsOneWidget);
    expect(find.text('İçmediğin sigara'), findsOneWidget);
  });

  testApp('ölçüm haftasında "Kazandıkların" kapalı, ne zaman açılacağı yazar', (
    tester,
    state,
  ) async {
    await skipOnboarding(tester);
    expect(state.measurementDay, 1);
    // Puan üst çubukta yok (sadece seri); Profil'de ve kutlamalarda var.
    expect(find.byTooltip('Toplam XP'), findsNothing);
    await tester.tap(find.text('İstatistik'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('Ölçüm haftası bitince burada açılacak'),
      250,
      scrollable: find.byType(Scrollable).hitTestable().first,
    );
    expect(find.text('İçmediğin sigara'), findsNothing);
    // Haftalık karşılaştırma kartı 2 haftalık kayıt olmadan görünmez.
    expect(find.text('Geçen haftayla karşılaştırma'), findsNothing);
  });

  testApp('"Neden?" penceresinde kendi seçtiğin nedenler başta', (
    tester,
    state,
  ) async {
    await skipOnboarding(tester);
    await state.updateProfile(UserProfile(triggers: {SmokingTrigger.stress}));
    (state.device as DemoDeviceService).simulatePickup();
    await tester.pumpAndSettle();

    await scrollAndTap(tester, find.text('Neden?'));
    await tester.pumpAndSettle();
    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    expect((chips.first.label as Text).data, 'Stres');
    expect((chips.elementAt(1).label as Text).data, 'Kahve');
  });

  testApp('erteleme ekranında kendine not yazılır (emoji süzülür)', (
    tester,
    state,
  ) async {
    await skipOnboarding(tester);
    await tester.tap(find.text('CANIM SİGARA İSTİYOR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Not önerisi en altta (asıl butonları itmesin diye).
    await tester.drag(
      find.byType(Scrollable).hitTestable().first,
      const Offset(0, -2000),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Kendine bir not yaz'));
    await tester.pump(const Duration(milliseconds: 500));
    // Emoji yazı tipinde yok: web'de Google'dan font indirilmesin diye süzülür.
    await tester.enterText(
      find.byType(TextField),
      'Kızımla koşabilmek için \u{1F3C3}',
    );
    await tester.tap(find.text('KAYDET'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(state.profile.reasonNote, 'Kızımla koşabilmek için');
    // Not artık sayacın hemen altında, en üstte.
    await tester.drag(
      find.byType(Scrollable).hitTestable().first,
      const Offset(0, 3000),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Kendine notun'), findsOneWidget);
    expect(find.text('Kızımla koşabilmek için'), findsOneWidget);
    await state.cancelDelay();
  });

  testApp('fiyat yoksa para kartı fiyat penceresini açar', (
    tester,
    state,
  ) async {
    await skipOnboarding(tester);
    await tester.tap(find.text('İstatistik'));
    await tester.pumpAndSettle();

    await scrollAndTap(
      tester,
      find.text('Hesaplamak için dokun ve paket fiyatını ekle'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Paket fiyatı'), findsWidgets);
    // Daha önce fiyat yoksa "yanlış girmiştim" seçeneği gösterilmez.
    expect(find.text('Yanlış girmiştim'), findsNothing);

    await tester.enterText(find.byType(TextField), '100');
    await tester.pump();
    await tester.tap(find.text('KAYDET'));
    await tester.pumpAndSettle();
    expect(state.prices.current!.price, 100);
    expect(find.textContaining('Paket fiyatı 100 ₺'), findsOneWidget);
  });

  testApp('zam gelince fiyat kartından güncellenir, geçmiş görünür', (
    tester,
    state,
  ) async {
    await skipOnboarding(tester);
    await state.setPackPrice(price: 100);
    await tester.tap(find.text('İstatistik'));
    await tester.pumpAndSettle();

    await scrollAndTap(tester, find.text('DEĞİŞTİR'));
    await tester.pumpAndSettle();
    expect(find.text('Yanlış girmiştim'), findsOneWidget);
    expect(find.textContaining('beri:'), findsOneWidget); // fiyat geçmişi

    await tester.enterText(find.byType(TextField), '115');
    await tester.pump();
    await tester.tap(find.text('KAYDET'));
    await tester.pumpAndSettle();

    // Aynı gün değiştirildiği için bugünkü kayıt düzeltildi.
    expect(state.prices.entries.length, 1);
    expect(state.prices.current!.price, 115);
  });

  testApp('büyük yazı boyutunda da ekranlar taşmaz', (tester, state) async {
    // Telefonun ayarlarında yazı boyutu büyütülmüş gibi (%130).
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();

    await tester.tap(find.text('BAŞLAYALIM'));
    await tester.pumpAndSettle();
    await skipOnboarding(tester);
    await scrollAndTap(tester, find.text('DEMO VERİSİ ÜRET'));
    await tester.pumpAndSettle();
    // Dar bir Android telefon (360 px) ve her sekmeyi sonuna kadar kaydır.
    tester.view.physicalSize = const Size(1080, 2340);
    await tester.pumpAndSettle();

    // Önce "Ölçüm haftan bitti!" özeti (en üstteki buton).
    await tester.drag(
      find.byType(Scrollable).hitTestable().first,
      const Offset(0, 3000),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('SONUÇLARIMI GÖR'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 6; i++) {
      await tester.drag(
        find.byType(Scrollable).hitTestable().first,
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('DEVAM'));
    await tester.pumpAndSettle();

    for (final tab in ['Bugün', 'İstatistik', 'Profil']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      for (var i = 0; i < 6; i++) {
        await tester.drag(
          find.byType(Scrollable).hitTestable().first,
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
      }
    }
    // Taşma olsaydı Flutter test hata verirdi.
    expect(tester.takeException(), isNull);
  });

  testApp('büyük yazı: onboarding, kutlama ve erteleme taşmaz', (
    tester,
    state,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = const Size(1080, 2340); // 360 px genişlik
    await tester.pumpAndSettle();

    // Onboarding'in tüm sayfalarını cevaplamadan geç.
    await tester.tap(find.text('BAŞLAYALIM'));
    await tester.pumpAndSettle();
    while (find.text('ŞİMDİLİK GEÇ').evaluate().isNotEmpty) {
      await tester.tap(find.text('ŞİMDİLİK GEÇ'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Hazırsın!'), findsOneWidget);
    await tester.tap(find.text('BAŞLA'));
    await tester.pumpAndSettle();

    // Ruh hali penceresi + kutlama ekranı
    await scrollAndTap(tester, find.text('Kendini dinle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('İyi'));
    await tester.pumpAndSettle();
    expect(find.text('Görev tamamlandı!'), findsOneWidget);
    await tester.tap(find.text('DEVAM'));
    await tester.pumpAndSettle();

    // Erteleme ekranı (saniyelik sayaç var: pumpAndSettle yok)
    await tester.drag(
      find.byType(Scrollable).hitTestable().first,
      const Offset(0, 2000),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('CANIM SİGARA İSTİYOR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.drag(
      find.byType(Scrollable).hitTestable().first,
      const Offset(0, -800),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('YİNE DE İÇECEĞİM'), findsOneWidget);
    await tester.tap(find.text('YİNE DE İÇECEĞİM'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Sorun değil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testApp('"Tüm verilerimi sil" uygulamayı ilk haline döndürür', (
    tester,
    state,
  ) async {
    await skipOnboarding(tester);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Toplam puan'), findsOneWidget);

    await tester.tap(find.byTooltip('Ayarlar'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Tüm verilerimi sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hepsini sil'));
    await tester.pumpAndSettle();

    expect(state.onboardingDone, isFalse);
    expect(state.totalXp, 0);
    expect(find.text('Merhaba! Ben Nefes.'), findsOneWidget);
  });
}

/// [scrollAndTap] gibi ama pumpAndSettle kullanmaz (saniyelik sayaç olan
/// ekranlarda pumpAndSettle hiç bitmez).
Future<void> scrollAndTapNoSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
  await tester.pump();
}
