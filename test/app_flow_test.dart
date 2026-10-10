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

void main() {
  testApp('ilk açılışta onboarding, "Atla" ile ana ekran', (
    tester,
    state,
  ) async {
    expect(find.text('Unlit’e hoş geldin'), findsOneWidget);
    expect(
      find.text('Bilgilerin sadece bu telefonda kalır, kimseyle paylaşılmaz.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Atla'));
    await tester.pumpAndSettle();

    expect(state.onboardingDone, isTrue);
    expect(find.text('sigara\nbugün'), findsOneWidget);
    expect(find.text('Henüz kayıt yok'), findsOneWidget);
  });

  testApp('sorular cevaplanınca profile kaydedilir', (tester, state) async {
    await tester.tap(find.text('Başlayalım'));
    await tester.pumpAndSettle();
    expect(find.text('Adım 1 / 6'), findsOneWidget);

    // "Neden soruyoruz?" açıklaması açılıp kapanır.
    await tester.tap(find.text('Neden soruyoruz?').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Başlangıç noktanı bilmek'), findsOneWidget);

    // Günlük sigara: ilk "+" 15'ten başlar, ikinci "+" 16 yapar.
    await tester.tap(find.byTooltip('Artır').first);
    await tester.pump();
    await tester.tap(find.byTooltip('Artır').first);
    await tester.pump();
    expect(find.text('16 sigara'), findsOneWidget);

    // Üçüncü soru ekranın altında kalıyor: önce aşağı kaydır.
    final option = find.text(FirstCigaretteTime.within5Min.label);
    await tester.scrollUntilVisible(
      option,
      200,
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(option);
    await tester.pumpAndSettle();
    await tester.tap(option);
    await tester.pump();

    // Sonraki sayfa: paket fiyatı
    await tester.tap(find.text('İleri'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '95,50');
    await tester.pump();

    // Geri kalanını atla: verilen cevaplar yine kaydedilmeli.
    await tester.tap(find.text('Atla'));
    await tester.pumpAndSettle();

    expect(state.profile.cigarettesPerDay, 16);
    expect(state.profile.firstCigarette, FirstCigaretteTime.within5Min);
    expect(state.profile.packPrice, 95.5);
    expect(find.text('sigara\nbugün'), findsOneWidget);
  });

  testApp('demo verisi üretilince ana ekran dolar', (tester, state) async {
    await tester.tap(find.text('Atla'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Demo verisi üret'));
    await tester.pumpAndSettle();

    expect(state.events.length, greaterThan(100));
    expect(find.text('Henüz kayıt yok'), findsNothing);
    // 15 günlük veri var: haftalık karşılaştırma görünmeli.
    expect(find.textContaining('Karşılaştırma için en az'), findsNothing);
  });

  testApp('"+1 sigara" bugünkü sayıyı artırır', (tester, state) async {
    await tester.tap(find.text('Atla'));
    await tester.pumpAndSettle();

    final before = state.events.length;
    await tester.tap(find.text('+1 sigara'));
    await tester.pumpAndSettle();
    expect(state.events.length, before + 1);
  });

  testApp('fiyat yoksa para kartı doğrudan fiyat sorusunu açar', (
    tester,
    state,
  ) async {
    await tester.tap(find.text('Atla'));
    await tester.pumpAndSettle();

    final tile = find.text('Hesaplamak için dokun ve paket fiyatını ekle');
    await tester.scrollUntilVisible(tile, 200);
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.text('Bir paket sigara kaç lira?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '100');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(state.profile.packPrice, 100);
    expect(find.text('Harcanan para'), findsOneWidget); // ana ekrana döndü
  });

  testApp('"Tüm verilerimi sil" uygulamayı ilk haline döndürür', (
    tester,
    state,
  ) async {
    await tester.tap(find.text('Atla'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ayarlar'));
    await tester.pumpAndSettle();
    final deleteTile = find.text('Tüm verilerimi sil');
    await tester.scrollUntilVisible(deleteTile, 200);
    await tester.ensureVisible(deleteTile);
    await tester.pumpAndSettle();
    await tester.tap(deleteTile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hepsini sil'));
    await tester.pumpAndSettle();

    expect(state.onboardingDone, isFalse);
    expect(find.text('Unlit’e hoş geldin'), findsOneWidget);
  });
}
