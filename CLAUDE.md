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
- Tasarım ve his **Duolingo'dan ilham** alır: günlük görevler, XP (ekranda
  "puan"), seri,
  konfetili kutlamalar, maskot "Nefes", tok butonlar. Ama bağımlılığa
  uyarlandı: asla ceza/suçlama yok (SPEC.md → "Oyunlaştırma ilkeleri").
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
   kaynaklı bilgi (SPEC.md Bölüm 9). Varsayımlar ekranda "varsayım",
   ortalamalar "ortalama tahmin" diye yazılır. Yeni kaynaklı bilgi eklersen
   SPEC.md'deki kaynak tablosuna da ekle. Yeni bir sayı (süre, eşik...)
   eklerken SPEC.md → "Sayıların dayanağı" tablosuna türünü yaz (sağlık
   iddiası → kaynak şart; müdahale ayarı → kaynak ya da gerekçe; oyun/
   arayüz kararı → "ekip kararı"). Kaynak uydurma.
3. **Suçlama ve korkutma yok:** Sigaradan hemen sonra suçluluk mesajı yok;
   artışlar kırmızıyla değil nötr renkle gösterilir. Sürekli büyüyen bir
   kayıp sayısı ("kaybedilen yaşam" gibi) gösterme; aynı kaynaklı bilgiyi
   kazanım tarafında göster ("içmediğin sigaralarla korunan süre").
4. **Her soru isteğe bağlı ve bir söz:** Eksik bilgide değer uydurma; "—"
   göster ve eklemeyi öner. Bir soruyu ancak cevabı uygulamada GERÇEKTEN
   bir şeyi değiştiriyorsa sor (ve sadece o zaman sakla); "Neden
   soruyoruz?" metni de tam olarak bunu söylesin. Soruyu, cevabın
   kullanılacağı ana koy (ör. hedef sorusu ölçüm haftası bitince).
   Hangi sorunun ne zaman sorulacağı: SPEC.md → Özellik 1.
5. **Oyunlaştırma ceza vermez:** XP asla düşmez; sigara içmek XP
   götürmez, seriyi bozmaz, kutlama/mesaj tetiklemez. Seri "sigarasız
   gün" değil "en az bir görev yapılan gün" sayar (dinlenme günüyle).
   Maskot asla üzgün/kızgın çizilmez. "Can/kalp", lig, suçlayan bildirim
   yok. Puan HARCANMAZ: "Nefes'in dolabı"ndaki eşyalar eşikle açılır ve
   kaybolmaz; başındaki filiz sadece toplam puanla büyür, asla küçülmez.
   Azaltma hedefinin günlük sınırını aşmak da ceza değildir (nötr gri,
   mesaj yok; "hedefinde kaldığın gün" sadece artar). Elle sigara
   ekleme / "Bu sigarayı ben içmedim" ile silme bir ölçüm düzeltmesidir:
   puan, ses, kutlama yok; silinen kaydın puanı geri alınmaz.
   Yeni bir oyun mekaniği eklerken önce SPEC.md Bölüm 3'e bak.
6. **Kılıf erişimi sadece `DeviceService` üzerinden.** Ekranlar Bluetooth'u
   ya da demo detaylarını bilmez (tek istisna: ayarlardaki ve "Bugün" sekmesindeki
   demo butonları `is DemoDeviceService` kontrolüyle gösterilir).
7. **Web'de çalışmalı.** Her değişiklikten sonra web derlemesi başarılı
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

## Mimari (özet — detay SPEC.md Bölüm 5)
- `lib/app_state.dart`: tek `ChangeNotifier`; profil, olaylar, etkinlikler
  (ruh hali, erteleme, nefes, XP). Olumlu eylem metotları (`logMood`,
  `tagEvent`, `finishDelay`, `logBreathing`...) bir `Reward` döndürür;
  ekran `CelebrationScreen.show(context, reward)` ile kutlar.
- `lib/services/`: `DeviceService` (arayüz), `DemoDeviceService`,
  `demo_day_planner.dart`, `demo_activity.dart`, `StorageService`,
  `effects.dart` (ses + titreşim) ve ses oynatıcılar (`sound_player*.dart`).
- `lib/logic/`: **saf** hesap fonksiyonları (`stats.dart`,
  `measurement.dart` (ölçüm haftası özeti + "Kazandıkların"; korunan
  yaşam süresi sadece sigarasız günlerden), `progress.dart`
  ("Başladığından beri": başlangıç, şimdi, hafta hafta),
  `weekly_report.dart` (haftalık rapor; haftalar takipten sayılır),
  `goal.dart` (azaltma hedefi: haftalık sınır, ilerleme, zorluk), `quests.dart`,
  `rewards.dart`, `wardrobe.dart` (dolap: eşya açılma, filiz aşaması),
  `mascot_messages.dart`); `now`'ı parametre olarak alır →
  kolay test. Yeni hesapları buraya koy ve test yaz. XP miktarları
  `rewards.dart`'ın başında. (Kodda adı XP, ekranda "puan".)
- `lib/utils/format.dart`: Türkçe tarih/para/süre/yüzde yazımı.
- `lib/screens/`: onboarding, `main_screen` (alt menü) + `today_tab`,
  `stats_tab`, `profile_tab`; erteleme, nefes, kutlama, ölçüm haftası
  özeti, haftalık rapor, Nefes'in dolabı, hedef seçme (`goal_setup_screen`)
  ve Hedefim (`goal_screen`), ayarlar.
- `lib/widgets/`: `chunky.dart` (tok buton/kart/çubuk), `mascot.dart`
  (+ `mascot_painter.dart`, `svg_path.dart`), `confetti.dart`,
  `pickers.dart`, `reason_note.dart` (kendine not), `change_chip.dart`
  (fark rozeti: azalma nane, artış nötr), `since_last_counter.dart`
  ("Son sigarandan beri" sayacı; seri değil, sessizce sıfırlanır), ...

## Tasarım dili (Duolingo tarzı)
- **Sade ve anlaşılır:** Her işin TEK giriş noktası olsun (aynı şeyi iki
  yerde gösterme). Bir ekranda tek seçici. Yeni özellik ilk günden değil,
  anlamlı olduğu anda açılsın ("kademeli açılım": ör. erteleme görevi ve
  "Kazandıkların" ölçüm haftası bitince). Ekranda "XP", "check-in" gibi
  İngilizce/oyun jargonu yerine "puan", "Kendini dinle" gibi Türkçe kullan.
- **Ölçekler soldan sağa olumsuzdan olumluya:** ruh hali "Çok zor" en
  solda, "Harika" en sağda (sıra `Mood` enum'unda).
- Renkler için her zaman `AppColors.of(context)` kullan (açık/koyu tema
  otomatik). Tema **"Nane"**: `mint` ana renk (ilerleme, ana buton),
  `blue` ikinci renk, `leaf` sadece seri/filiz (büyüme). Kırmızı (`red`)
  sadece silme gibi tehlikeli işlemlerde.
- **Duolingo'yu andırsın, kopyası olmasın:** Duolingo'nun renklerini
  (limon yeşili, onların mavisi/turuncusu), alev seri ikonunu ya da yeşil
  maskotu geri getirme. Seri ikonu `streakIcon` (yaprak).
- Ana eylemler `ChunkyButton` (yazısı BÜYÜK HARF, elle yazılmış: "DEVAM",
  "İLERİ"); kartlar `ChunkyCard`; ilerleme `ChunkyProgressBar`.
- Maskotla konuşma: `MascotSpeech(text:, mood:)`. Cümle seçimi
  `logic/mascot_messages.dart`'ta, kurallara uygun (suçlama yok, kendi veri).
- **Kişisel geri bildirim az ve sade:** Yeni kart/bölüm eklemek yerine
  Nefes'in zaten söylediği cümleyi kişiselleştir (ör. erteleme ekranında
  `delayStartLine`). Düşünülüp ertelenen fikirler: SPEC.md Bölüm 11.
- **Maskot çizimi:** Nefes 2.0, `docs/maskot/1-nefes-2.svg` tasarımının
  birebir kod hâli (`widgets/mascot_painter.dart`; şekiller SVG'deki `d="..."`
  yazılarıyla, `svgPath(...)` üzerinden). Çizimi değiştirirsen SVG'yi de
  aynı koordinatlarla güncelle. Maskot, filiz aşamasını ve takılı eşyaları
  uygulama kökündeki `MascotAppearance`'tan alır; ekranlara ayrıca bilgi
  geçirme. Önizleme için `Mascot(look: ...)`.
- Bir şey başarıldığında `CelebrationScreen.show(...)`; zor anlarda
  `calm: true` (konfetisiz, destekleyici).
- Yazı tipi Nunito (`assets/fonts/`, gömülü). Ağırlıklar: 500/700/800/900.
- **Paket fiyatı** profilde DEĞİL, tarihli `PriceHistory`'de
  (`models/pack_price.dart`). Para hesabı her zaman `moneyBetween(...)` ile
  (her sigara kendi tarihindeki fiyatla); tek bir "güncel fiyat × sayı"
  hesabı yapma. Fiyat sadece `showPriceSheet` / `setPackPrice` ile
  değişir. Fiyat internetten çekilmez (SPEC.md Bölüm 11'deki karar).
- **Ses ve titreşim** sadece `Effects` üzerinden (`Effects.tap()`,
  `Effects.select()`, `Effects.celebrate()`, `Effects.breath()`,
  `Effects.timerDone()`). `HapticFeedback`'i doğrudan çağırma; yoksa
  Ayarlar'daki "Titreşim kapalı" seçeneği çalışmaz. Ses sadece güzel
  anlarda; sigara içmek asla ses/titreşim tetiklemez. Yeni ses gerekiyorsa
  `tool/make_sounds.py`'ye ekle, `Sfx` listesine yaz.
- Testler `test/` altında; demo ve hesaplar için sahte saat (`clock:`)
  kullanılır.

## Paket kuralları
"Az ama sağlam paket." Şu an: `shared_preferences`, `flutter_localizations`
(SDK), `audioplayers` (telefonda ses), `web` (web'de ses; Dart ekibinin
resmi paketi). Yeni paket eklemeden önce: (1) gerçekten gerekli mi, birkaç satır
kodla çözülmüyor mu? (2) web dahil tüm platformları destekliyor mu?
(3) iyi bakılıyor mu (pub.dev puanı, son güncelleme)? (4) internete veri
gönderiyor mu? (göndermemeli). Eklersen SPEC.md'ye nedenini yaz.
Planlanan: `flutter_blue_plus` (Aşama 7), muhtemelen
`flutter_local_notifications` (Aşama 4). Grafik, konfeti ve maskot bilerek
paketsiz yazıldı.

## Dikkat edilecek tuzaklar
- **Türkçe büyük/küçük harf:** Dart'ın `toUpperCase()`/`toLowerCase()`
  fonksiyonları i/İ ve ı/I'yı yanlış çevirir. Türkçe metinde kullanma;
  hazır yazılmış metin/liste kullan (bkz. `format.dart`).
- **Web'de yedek font isteği:** Arayüz metninde Nunito'da olmayan karakter
  (→, ✓, emoji…) kullanırsan tarayıcı Google'dan font indirir (gizlilik
  vaadine aykırı). Bunun yerine `Icons.xxx` kullan. `₺ · – — … ’ %`
  sorunsuz. Yeni karakter eklersen web'de dış istek olmadığını kontrol et.
- **Tarih aritmetiği:** Gün eklerken `Duration(days: n)` yerine
  `stats.dart`'taki `addDays` kullan (takvim günüyle hesaplar).
- **Testlerde zamanlayıcı:** Demo kılıf `Timer.periodic` kullanır; widget
  testlerinde test bitmeden `disconnect()` çağır (bkz.
  `test/app_flow_test.dart` → `testApp`). Erteleme ekranında saniyelik
  sayaç var: o ekran açıkken `pumpAndSettle()` bitmez, `pump()` kullan.
  Bugün'deki "Son sigarandan beri" sayacı da saniyelik ama animasyonsuz;
  `pumpAndSettle()` çalışır. İlerlemesini test etmek için sahte saat +
  `pump(const Duration(seconds: 1))` (bkz. `test/since_last_counter_test.dart`).
- **Kullanıcının yazdığı metin (TextField):** Kullanıcı emoji vb. yazarsa
  aynı yedek font sorunu olur. Serbest yazı alanlarında
  `noteInputFormatter` (`widgets/reason_note.dart`) gibi, sadece Nunito'da
  olan harflere izin veren bir süzgeç kullan.
- **Testlerde yazı tipi:** Testler her harfi kare çizen bir font kullanır,
  yazılar gerçekte olduğundan geniş görünür. Bir `Row` taşıyorsa uzun
  yazıyı `Expanded`/`Flexible` içine al (bu, küçük telefonlarda da işe
  yarar).
- **Testlerde ses:** `Effects.player` varsayılan olarak sessizdir; testler
  gerçek ses çalmaz. Hangi sesin çaldığını kontrol etmek için
  `test/test_helpers.dart` → `RecordingPlayer`.
- **Web'de ses izni:** Tarayıcılar (özellikle iPhone) sese ancak dokunuş
  anında izin verir. Bu yüzden ilk sesten önce mutlaka bir dokunuş olur
  (uygulama kökündeki `Listener` → `Effects.unlock()`). Dokunuşsuz,
  kendiliğinden çalan bir ses ekleme.
- **Sürüm:** `pubspec.yaml` `version` ile `lib/app_info.dart` `appVersion`
  aynı olmalı.

## Git
- Ana dal `main`; main'e her push GitHub Pages'e yayınlanır.
- Özellik dallarında çalış, PR ile main'e birleştir (PR'da CI sadece kontrol
  eder, yayınlamaz).
- Her aşama bitince `docs/SPEC.md` → "Aşama planı ve durum" ve "Sürüm
  geçmişi" güncellenir.
