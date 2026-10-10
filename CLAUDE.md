# CLAUDE.md — Unlit

Bu dosya, bu repoda çalışan Claude oturumları (ve ekip üyeleri) için kısa
çalışma rehberidir. **Projenin tüm detayı, özellik listesi ve aşama planı:
[docs/SPEC.md](docs/SPEC.md).** Her oturuma orayı okuyarak başla.

## Proje bir bakışta
- **Unlit:** TÜBİTAK 2204-A lise projesi. Sigara paketine takılan akıllı
  kılıf (XIAO nRF52840, kapak + IR sensörü, isteğe bağlı OLED) her sigara
  alınışını sayıp Bluetooth LE ile telefona gönderir; bu Flutter uygulaması
  tüketimi takip eder ve kullanıcıyı azaltmadan bırakmaya yönlendirir.
- Kılıf henüz yok → `DemoDeviceService` gerçekçi sahte veri üretir.
- Şu anki durum: SPEC.md → "Aşama planı ve durum".

## Ekip ve iletişim
- Ekip **lise öğrencileri**, teknik bilgileri az. Kodu **açık, sade ve
  Türkçe yorumlu** yaz. Akıllıca ama anlaşılmaz kısa yollardan kaçın.
- Yaptığın her şeyi kullanıcıya **kısa Türkçe açıklamalarla** anlat.
- Arayüz dili **Türkçe**.
- Bir değişiklik bitince cevabın sonuna kısa bir **sürüm başlığı ve sürüm
  açıklaması** yaz; SPEC.md'deki "Sürüm geçmişi" tablosunu güncelle.

## Kesin kurallar
1. **Gizlilik:** Veriler sadece cihazda. Hesap, sunucu, Firebase, analiz,
   reklam, çökme raporlama SDK'sı **yok**. İnternete veri gönderen hiçbir
   paket ekleme. `google_fonts` gibi çalışırken internetten dosya indiren
   paketler de yasak.
2. **Uydurma sayı yok:** Her sayı ya kullanıcının kendi verisi ya da
   kaynaklı bilgi (SPEC.md Bölüm 7). Varsayımlar ekranda "varsayım",
   ortalamalar "ortalama tahmin" diye yazılır. Yeni kaynaklı bilgi eklersen
   SPEC.md'deki kaynak tablosuna da ekle.
3. **Suçlama yok:** Sigaradan hemen sonra suçluluk mesajı yok; artışlar
   kırmızıyla değil nötr renkle gösterilir.
4. **Her soru isteğe bağlı:** Eksik bilgide değer uydurma; "—" göster ve
   eklemeyi öner.
5. **Kılıf erişimi sadece `DeviceService` üzerinden.** Ekranlar Bluetooth'u
   ya da demo detaylarını bilmez (tek istisna: ayarlardaki ve ana ekrandaki
   demo butonları `is DemoDeviceService` kontrolüyle gösterilir).
6. **Web'de çalışmalı.** Her değişiklikten sonra web derlemesi başarılı
   olmalı. Web'e özgü olmayan bir paket eklersen web'de ne olacağını düşün.

## Komutlar
```bash
flutter pub get              # paketleri indir
dart format .                # kodu standart biçime sok
flutter analyze              # kod analizi (hata/uyarı olmamalı)
flutter test                 # tüm testler
flutter run -d chrome        # tarayıcıda çalıştır
flutter build web --release --no-web-resources-cdn --base-href /UnlitApp/
```
- Flutter sürümü **3.47.7 (stable)** — `.github/workflows/pages.yml` içinde
  sabitlendi. Sürümü yükseltirsen ikisini birlikte güncelle.
- Push öncesi: `flutter analyze` temiz + `flutter test` yeşil + web derlemesi
  başarılı olmalı. CI de aynılarını çalıştırır.

## Mimari (özet — detay SPEC.md Bölüm 4)
- `lib/app_state.dart`: tek `ChangeNotifier`; profil + olaylar; cihaz
  olaylarını dinler, kaydeder. Ekranlar `ListenableBuilder` ile dinler.
- `lib/services/`: `DeviceService` (arayüz), `DemoDeviceService`,
  `demo_day_planner.dart`, `StorageService` (shared_preferences).
- `lib/logic/stats.dart`: **saf** hesap fonksiyonları; `now`'ı parametre
  olarak alır → kolay test. Yeni hesapları buraya koy ve test yaz.
- `lib/utils/format.dart`: Türkçe tarih/para/süre/yüzde yazımı.
- `lib/screens/`, `lib/widgets/`: arayüz.
- Testler `test/` altında; demo ve hesaplar için sahte saat (`clock:`)
  kullanılır.

## Paket kuralları
"Az ama sağlam paket." Şu an: `shared_preferences`, `flutter_localizations`
(SDK). Yeni paket eklemeden önce: (1) gerçekten gerekli mi, birkaç satır
kodla çözülmüyor mu? (2) web dahil tüm platformları destekliyor mu?
(3) iyi bakılıyor mu (pub.dev puanı, son güncelleme)? (4) internete veri
gönderiyor mu? (göndermemeli). Eklersen SPEC.md'ye nedenini yaz.
Planlanan: `flutter_blue_plus` (Aşama 6), muhtemelen
`flutter_local_notifications` (Aşama 3).

## Dikkat edilecek tuzaklar
- **Türkçe büyük/küçük harf:** Dart'ın `toUpperCase()`/`toLowerCase()`
  fonksiyonları i/İ ve ı/I'yı yanlış çevirir. Türkçe metinde kullanma;
  hazır yazılmış metin/liste kullan (bkz. `format.dart`).
- **Web'de yedek font isteği:** Arayüz metninde Roboto'da olmayan karakter
  (→, ✓, emoji…) kullanırsan tarayıcı Google'dan font indirir (gizlilik
  vaadine aykırı). Bunun yerine `Icons.xxx` kullan. `₺ · – — … ’` sorunsuz.
- **Tarih aritmetiği:** Gün eklerken `Duration(days: n)` yerine
  `stats.dart`'taki `addDays` kullan (takvim günüyle hesaplar).
- **Testlerde zamanlayıcı:** Demo kılıf `Timer.periodic` kullanır; widget
  testlerinde test bitmeden `disconnect()` çağır (bkz.
  `test/app_flow_test.dart` → `testApp`).
- **Sürüm:** `pubspec.yaml` `version` ile `lib/app_info.dart` `appVersion`
  aynı olmalı.

## Git
- Ana dal `main`; main'e her push GitHub Pages'e yayınlanır.
- Özellik dallarında çalış, PR ile main'e birleştir (PR'da CI sadece kontrol
  eder, yayınlamaz).
- Her aşama bitince `docs/SPEC.md` → "Aşama planı ve durum" ve "Sürüm
  geçmişi" güncellenir.
