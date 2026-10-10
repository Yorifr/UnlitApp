import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unlit/app.dart';
import 'package:unlit/app_state.dart';
import 'package:unlit/models/user_profile.dart';
import 'package:unlit/services/demo_device_service.dart';
import 'package:unlit/services/storage_service.dart';

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
    expect(find.textContaining('Başlangıç noktanı bilmek'), findsOneWidget);

    // Günlük sigara: ilk "+" 15'ten başlar, ikinci "+" 16 yapar.
    await tester.tap(find.byTooltip('Artır'));
    await tester.pump();
    await tester.tap(find.byTooltip('Artır'));
    await tester.pump();
    expect(find.text('16'), findsOneWidget);
    expect(find.text('DEVAM'), findsOneWidget);

    await tester.tap(find.text('DEVAM'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ŞİMDİLİK GEÇ')); // kaç yıldır: boş geç
    await tester.pumpAndSettle();

    await tester.tap(find.text(FirstCigaretteTime.within5Min.label));
    await tester.pump();
    await tester.tap(find.text('DEVAM'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '95,50');
    await tester.pump();

    // Geri kalanını atla: verilen cevaplar yine kaydedilmeli.
    await skipOnboarding(tester);

    expect(state.profile.cigarettesPerDay, 16);
    expect(state.profile.yearsSmoking, isNull);
    expect(state.profile.firstCigarette, FirstCigaretteTime.within5Min);
    expect(state.profile.packPrice, 95.5);
    expect(find.text('Günlük görevler'), findsOneWidget);
  });

  testApp('check-in kutlama ekranı açar ve XP verir', (tester, state) async {
    await skipOnboarding(tester);
    final xpBefore = state.totalXp;

    await scrollAndTap(tester, find.text('İyi'));
    await tester.pumpAndSettle();

    expect(find.text('Görev tamamlandı!'), findsOneWidget);
    expect(state.totalXp, xpBefore + 10);

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
    expect(state.successfulDelays, 1);
    expect(state.activeDelayStart, isNull);
  });

  testApp('demo verisi üretilince her yer dolar', (tester, state) async {
    await skipOnboarding(tester);

    await scrollAndTap(tester, find.text('DEMO VERİSİ ÜRET'));
    await tester.pumpAndSettle();

    expect(state.events.length, greaterThan(100));
    expect(state.streak.current, greaterThan(5));
    // Ölçüm haftası geçmişte kaldı → erteleme görevi geldi.
    expect(state.measurementDay, isNull);

    await tester.tap(find.text('İstatistik'));
    await tester.pumpAndSettle();
    expect(find.text('sigara\nbugün'), findsOneWidget);
    expect(find.textContaining('Karşılaştırma için en az'), findsNothing);
  });

  testApp('fiyat yoksa para kartı doğrudan fiyat sorusunu açar', (
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
    expect(find.text('Bir paket sigara kaç lira?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '100');
    await tester.tap(find.text('KAYDET'));
    await tester.pumpAndSettle();
    expect(state.profile.packPrice, 100);
    expect(find.text('Harcanan para'), findsOneWidget);
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

    // Kutlama ekranı
    await scrollAndTap(tester, find.text('İyi'));
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
    expect(find.text('Toplam XP'), findsOneWidget);

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
