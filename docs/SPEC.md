# Unlit — Proje Şartnamesi (SPEC)

> Bu dosya projenin "tek doğru kaynağı"dır. Yeni bir oturuma/ekip üyesine
> bağlam vermek için buradan başlayın. **Her aşama bitince "Aşama planı ve
> durum" ile "Sürüm geçmişi" bölümlerini güncelleyin.**

Son güncelleme: 10 Ekim 2026 — Aşama 2 (Duolingo tarzı tasarım ve
oyunlaştırma) ve ses/titreşim efektleri tamamlandı.

---

## 1. Proje özeti

**Unlit**, bir TÜBİTAK 2204-A (Lise Öğrencileri Araştırma Projeleri)
projesidir. Ekip lise öğrencilerinden oluşur.

- **Donanım:** Sigara paketine takılan akıllı bir kılıf.
  - Kart: Seeed **XIAO nRF52840** (Bluetooth LE destekli)
  - **Kapak sensörü:** kapağın açıldığını algılar
  - **IR sensörü:** paketten gerçekten sigara alındığını doğrular
  - **OLED ekran (isteğe bağlı):** kılıf üzerinde küçük bilgi
  - Her sigara alınışını sayar ve **Bluetooth LE** ile telefona gönderir.
- **Mobil uygulama (bu repo):** Tüketimi takip eder, kişiselleştirilmiş geri
  bildirim verir ve kullanıcıyı **azaltmadan bırakmaya** giden bir süreçte
  yönlendirir.
- **Tasarım ve his:** Duolingo'dan ilham alır. Kullanıcı her gün küçük
  görevler tamamlar, XP kazanır, serisini büyütür ve kutlama ekranlarıyla
  "başardım" hissini yaşar. Asla suçlamaz, özgüven kırmaz (bkz. Bölüm 3).
- **Kılıf henüz yok.** Sahte veri üreten bir **demo modu**
  (`DemoDeviceService`) kullanılır.

## 2. Temel ilkeler (pazarlık konusu değil)

1. **Gizlilik:** Veriler **sadece cihazda** saklanır. Hesap yok, sunucu yok,
   analiz/reklam SDK'sı (Firebase vb.) yok. Web sürümü de dış sunuculara
   istek atmaz (Google CDN/Google Fonts dahil; font uygulamanın içinde).
2. **Uydurma sayısal iddia yok:** Ekranda/mesajda gösterilen her sayı ya
   kullanıcının kendi verisidir ya da kaynağı belli bir bilgidir (bkz.
   Bölüm 9). Varsayımlar "varsayım", ortalamalar "ortalama tahmin" diye
   açıkça yazılır.
3. **Suçlama yok:** Sigaradan hemen sonra suçluluk mesajı gösterilmez. Artış
   kırmızı/uyarı rengiyle değil nötr renkle gösterilir. Hedef aşıldığında
   destekleyici dil kullanılır.
4. **Her şey isteğe bağlı:** Onboarding atlanabilir; her soru boş
   bırakılabilir. Eksik bilgi varsa uygulama uydurmaz, "—" gösterir ve
   bilgiyi eklemeyi önerir.
5. **Türkçe arayüz**, açık ve yorumlu kod (ekip yeni başlıyor).
6. **Web'de de çalışmalı:** Ekip iPhone'dan web sürümünü (GitHub Pages)
   takip ediyor.

## 3. Oyunlaştırma ilkeleri (Duolingo'dan ilham, bağımlılığa uyarlanmış)

Amaç: Kullanıcı uygulamayı açtıkça küçük bir "görev tamamladım" hissi ve
hafif bir mutluluk yaşasın; motive olsun ama **özgüveni asla kırılmasın,
suçluluk duymasın**.

### Duolingo'dan aldıklarımız
- **Günlük görevler** (her gün 3 küçük, yapılabilir görev)
- **XP** (puan) ve **seri** (alev ikonu)
- **Kutlama ekranı:** konfeti, sevinen maskot, sayarak artan XP, seri
  kutucuğu, "DEVAM" butonu
- **Maskot** ("Nefes") konuşma balonlarıyla yol gösterir
- **Tok, basılan butonlar**, kalın kenarlı kartlar, parlak ilerleme
  çubukları, canlı düz renkler, yuvarlak yazı tipi (Nunito)
- **Tek soru = tek ekran** onboarding, üstte ilerleme çubuğu
- Alt menüde 3 sekme (Bugün / İstatistik / Profil)

### Bilerek ALMADIKLARIMIZ (ve nedenleri)
- **"Sigarasız gün serisi" yok (şimdilik).** Bir sigara bu seriyi sıfırlar
  ve kişi "zaten bozdum, boş ver" diyerek tamamen bırakabilir. Bağımlılık
  literatüründe buna **"perhiz ihlali etkisi" (abstinence violation effect)**
  denir (Marlatt & Gordon, 1985). Bizim serimiz **kendine iyi baktığın
  günleri** sayar.
- **Can/kalp cezası yok.** Hiçbir eylem XP götürmez.
- **Suçlayan bildirim yok** ("Nefes üzüldü…" gibi). Maskot asla üzgün,
  kızgın ya da hayal kırıklığına uğramış görünmez.
- **Lig/sıralama yok:** Sunucu yok (gizlilik) ve başkalarıyla kıyas
  özgüveni kırabilir.

### Kurallar (kodda `lib/logic/quests.dart`, `lib/logic/rewards.dart`)
1. **XP sadece artar.** Sigara içmek XP götürmez, seriyi bozmaz, mesaj
   göstermez.
2. **Seri = en az bir görev yapılan (XP kazanılan) ardışık günler.**
   - Bugün henüz bir şey yapılmadıysa seri bozulmaz; alev gri görünür.
   - **Dinlenme günü:** Haftada (7 günde) 1 kaçırılan gün otomatik
     affedilir; seri korunur ama artmaz.
   - Seri sıfırlanırsa dil olumlu: "Bugün bir görev yap, serin başlasın!"
     ve "en uzun seri" her zaman gösterilir.
3. **Günlük görevler** (gece yarısı yenilenir, yapılmayanın cezası yok):
   - **Ölçüm haftası (ilk 7 gün):** Günlük check-in, Nedenini keşfet (bir
     sigaranın nedenini işaretle), Nefes molası. **Azaltma görevi yok**,
     böylece başlangıç alışkanlığı doğru ölçülür.
   - **Sonrası:** Günlük check-in, İsteği ertele (10 dk), + günden güne
     değişen 3. görev (Nedenini keşfet / Nefes molası).
   - "Canım sigara istiyor" (erteleme) butonu **her zaman** açıktır:
     kullanıcının kendi istediği yardım asla engellenmez; sadece ölçüm
     haftasında görev olarak önerilmez.
4. **XP tablosu:**

   | Eylem | XP |
   |---|---|
   | Onboarding'i bitirmek / atlamak | +10 |
   | Her günlük görev | +10 |
   | Günün 3 görevi de bitince bonus | +20 |
   | Başarılı erteleme ("İSTEK GEÇTİ") | +15 |
   | Erteleme denemesi ("YİNE DE İÇECEĞİM") | +5 |
   | (Erteleme XP'si günde en fazla 5 kez) | |

5. **Erteleme:** 10 dakikalık geri sayım, somut öneriler (su iç, yürü,
   birine yaz…), nefes egzersizi kısayolu. İki çıkış da ödüllü:
   "İSTEK GEÇTİ" → konfetili kutlama; "YİNE DE İÇECEĞİM" → sakin ekran,
   "X dakika bekledin ve isteğini fark ettin. Bu da bir adım."
6. **Ruh hali check-in'i:** "Zor/Çok zor" seçilirse kutlama sakin olur ve
   maskot destekleyici konuşur.
7. **Maskot cümleleri** (`lib/logic/mascot_messages.dart`): sadece
   kullanıcının kendi verisi; azalma varsa kutlar, artış varsa nazikçe
   erteleme önerir; ölçüm haftasında karşılaştırma yapmaz.
8. **Renkler:** Kırmızı sadece "tümünü sil" gibi tehlikeli işlemlerde.
   Kullanıcının sigara davranışı asla kırmızıyla gösterilmez.
9. **Ses ve titreşim** (`lib/services/effects.dart`):
   - Ses **sadece güzel anlarda** çalar; "hata/ceza" sesi yoktur. Sigara
     içmek (kılıftan gelen olay) **hiçbir ses ya da titreşim tetiklemez**.

     | An | Ses | Titreşim |
     |---|---|---|
     | Görev tamamlandı | `success` ("ding-ding") | başarı titreşimi |
     | Büyük kutlama (günün görevleri, başarılı erteleme, "Hazırsın!") | `fanfare` | başarı titreşimi |
     | Sakin an (zor gün, "yine de içeceğim") | `calm` (yumuşak çan) | hafif |
     | Nefes egzersizi: al / ver | `breath_in` / `breath_out` | hafif |
     | Erteleme süresi doldu | `bell` | güçlü |
     | Butona basma / seçim yapma | — | hafif / en hafif |

   - Sesler `tool/make_sounds.py` ile **sıfırdan sentezlendi** (başka
     uygulamaların sesleri telif nedeniyle kullanılmaz).
   - Telefonda sesler **sessiz moda uyar** ve **çalan müziği durdurmaz**
     (iOS "ambient", Android "sonification", ses odağı almaz).
   - Ses ve titreşim **Ayarlar'dan ayrı ayrı kapatılabilir**. (Toplum
     içinde sesli bir sigara uygulaması gizliliği bozabilir; kapatmak kolay
     olmalı.)

## 4. Özellikler (tam vizyon)

### Özellik 1 — Onboarding ✅ (Aşama 1, Aşama 2'de yenilendi)
- En üstte: **"Bilgilerin sadece bu telefonda kalır, kimseyle paylaşılmaz."**
- Her ekranda tek soru; maskot soruyu sorar; **"Neden soruyoruz?"**
  açıklaması; cevap yoksa buton "ŞİMDİLİK GEÇ", varsa "DEVAM".
- Sigara soruları: günlük sigara sayısı, kaç yıldır, uyanınca ilk sigara ne
  zaman (Fagerström 1. soru), paket fiyatı (+ paketteki adet), tetikleyiciler
  (kahve, çay, yemek, stres, arkadaşlar, alkol, can sıkıntısı, ders/iş arası,
  araba, telefon), hedef (azaltma/bırakma), bırakma isteği 1–10.
- İsteğe bağlı profil ("BU BÖLÜMÜ ATLA"): yaş aralığı, cinsiyet ("Belirtmek
  istemiyorum" dahil), motivasyon (çocuk, eş, anne-baba, evcil hayvan,
  kendim), sevilen aktiviteler (koşu, futbol, yürüyüş, …).
- Sonunda konfetili "Hazırsın!" ekranı ve +10 XP.

### Özellik 2 — Ana ekran ✅ (Aşama 1; Aşama 2'de "İstatistik" sekmesine taşındı)
- Bugünkü sigara sayısı (+ bugünkü ilk sigara saati, son sigaradan geçen süre)
- Geçen haftayla karşılaştırma:
  - Bugün ↔ geçen haftanın aynı günü, **aynı saate kadar**
  - Son 7 gün ↔ önceki 7 gün (yüzde değişim; azalma varsa kart yeşil)
  - Yeterli kayıt yoksa karşılaştırma gösterilmez (yanıltmasın diye).
- Grafik: son 7 gün (günlük) / bugün (saatlik)
- Harcanan para, sigaraya giden süre, tahmini kaybedilen yaşam süresi
  (dönem: bugün / 7 gün / 30 gün)
  - Yaşam süresi: sigara başına erkek ~17 dk, kadın ~22 dk, belirtilmemişse
    ~20 dk (UCL 2024). **"Ortalama tahmin"** olduğu açıkça yazar.
  - Sigaraya giden süre: sigara başına ~6 dk **varsayımı**.

### Özellik 2b — Oyunlaştırma ✅ Aşama 2
Bölüm 3'teki her şey: "Bugün" sekmesi (maskot, "CANIM SİGARA İSTİYOR",
günlük görevler, ruh hali check-in'i, bugünkü sigaralar ve nedenleri),
erteleme ekranı, nefes egzersizi, kutlama ekranı, "Profil" sekmesi (seri,
en uzun seri, toplam XP, ertelenen istekler).

### Özellik 3 — Süreç aşamaları ⏳ Aşama 3
Ölçüm → Farkındalık → Azaltma → Bırakma günü → Sürdürme
- **Ölçüm (1 hafta):** sadece veri toplanır, **hiç mesaj yok**. (Aşama 2'de
  ölçüm haftası sayacı ve görev kısıtı eklendi.)
- **Farkındalık:** kullanıcıya kendi örüntüsü gösterilir (en yoğun saatler,
  işaretlenen nedenlerin dağılımı, sabah ilk sigara saati).
- **Azaltma:** kademeli günlük hedefler (ölçüm haftası ortalamasından).
- **Bırakma günü:** kullanıcı tarih seçer; **ALO 171** (Sigara Bırakma
  Danışma Hattı) ve **sigara bırakma polikliniği** (MHRS üzerinden randevu)
  yönlendirmesi.
- **Sürdürme:** sigarasız gün sayacı, **WHO iyileşme takvimi** (bkz.
  Bölüm 9). Perhiz ihlali etkisine karşı: sayaç **toplam sigarasız günü**
  de gösterir (asla sıfırlanmaz); kayma olursa suçlamadan, "kaldığın yerden
  devam" diliyle ele alınır.

### Özellik 4 — Mesaj motoru ⏳ Aşama 4
Profil bilgisine göre seçilen 3 tür mesaj:
1. **Motivasyon:** "Geçen haftaya göre %10 az içtin."
2. **Geleceğe dönük fırsat:** "Yarın sabah koşacaksan bu akşam son sigarayı
   21:00'de içmeye ne dersin?"
3. **Somut öneri:** "Kahveden sonra 10 dk yürü, sonra karar ver."

Kurallar: günde **en fazla 3** bildirim; sigaradan **hemen sonra suçluluk
mesajı yok**; hedef aşılınca **destekleyici** mesaj; **aynı tür üst üste
gelmez**; kullanıcı **tonu seçebilir**; **uydurma sayı yok** (sadece
kullanıcının verisi veya kaynaklı bilgi, ör. WHO: "12 saatte kandaki
karbonmonoksit normale döner"); ölçüm haftasında mesaj yok. Seri
hatırlatmaları da suçlamasız olmalı ("Bugünkü görevlerin seni bekliyor",
asla "serini kaybedeceksin!").

### Özellik 5 — Para kumbarası ⏳ Aşama 5
Kullanıcı bir hedef ödül belirler (ör. "kulaklık, 2.000 ₺"); ölçüm haftası
ortalamasına göre **içilmeyen** sigaraların parası kumbarada birikir ve
hedefe ilerleme gösterilir (kutlama ekranıyla).

### Özellik 6 — Karakter ⏳ Aşama 6 (maskot Aşama 2'de geldi)
Maskot **"Nefes"** Aşama 2'de görsel olarak eklendi. Bu aşamada: ödül
odaklı, **asla ölmez**; **enerji** göstergesi azaltmaya, **sağlık**
göstergesi **sadece sigarasız süreye** bağlı. Göstergeler düşük olsa bile
maskot üzgün/hasta çizilmez; "dinleniyor" gibi nötr bir hâl alır.

### Özellik 7 — Gerçek Bluetooth + veri dışa aktarma ⏳ Aşama 7
- `BleDeviceService` (flutter_blue_plus) — aynı `DeviceService` arayüzü.
- TÜBİTAK pilotu için **CSV dışa aktarma** (kullanıcı kendi isteğiyle
  paylaşır; uygulama otomatik göndermez). Ruh hali, nedenler ve ertelemeler
  de dışa aktarılabilir (pilot için değerli veri).

## 5. Mimari

```
lib/
├── main.dart                  Başlangıç: kayıt + cihaz + AppState
├── app.dart                   MaterialApp, tema, Türkçe dil, kök ekran
├── app_state.dart             Uygulamanın "beyni" (ChangeNotifier)
├── app_info.dart              Uygulama adı ve sürümü
├── theme.dart                 Renk paleti (AppColors) + tema + font
├── models/
│   ├── smoking_event.dart     Sigara alma olayı (zaman, kaynak, neden)
│   ├── user_profile.dart      Onboarding cevapları + seçenek listeleri
│   └── activity_log.dart      Ruh hali, erteleme, nefes, XP kayıtları
├── services/
│   ├── device_service.dart    Kılıf arayüzü (abstract class)
│   ├── demo_device_service.dart   Sanal kılıf
│   ├── demo_day_planner.dart  Gerçekçi bir günün sigara saatleri
│   ├── demo_activity.dart     Demo için geçmiş görev/XP/neden üretimi
│   ├── storage_service.dart   Yerel kayıt (shared_preferences)
│   ├── effects.dart           Ses + titreşim (Effects.celebrate() vb.)
│   ├── sound_player.dart      Platforma göre ses oynatıcı seçimi
│   ├── sound_player_native.dart  Telefonda: audioplayers
│   └── sound_player_web.dart  Web'de: tarayıcının Web Audio motoru
├── logic/                     Saf (test edilebilir) hesaplar
│   ├── stats.dart             Sayılar, para, süre, yaşam tahmini
│   ├── quests.dart            Günlük görevler, ölçüm haftası
│   ├── rewards.dart           XP ödülleri, seri (dinlenme günü dahil)
│   └── mascot_messages.dart   Maskotun ana ekran cümlesi
├── utils/format.dart          Türkçe tarih/para/süre yazımı
├── screens/
│   ├── onboarding_screen.dart Tek soru = tek ekran
│   ├── main_screen.dart       Alt menü + 3 sekme
│   ├── today_tab.dart         Bugün: maskot, görevler, erteleme, check-in
│   ├── stats_tab.dart         İstatistik: sayılar, grafik, maliyet
│   ├── profile_tab.dart       Profil: seri, XP, başarılar
│   ├── delay_screen.dart      10 dk erteleme
│   ├── breathing_screen.dart  1 dk nefes egzersizi
│   ├── celebration_screen.dart Konfetili kutlama
│   └── settings_screen.dart   Demo, gizlilik, kaynaklar
└── widgets/
    ├── chunky.dart            Tok buton, kart, ilerleme çubuğu, sayaç
    ├── mascot.dart            Maskot "Nefes" (kodla çizilir)
    ├── confetti.dart          Konfeti animasyonu
    ├── pickers.dart           Ruh hali ve "neden?" pencereleri
    ├── onboarding_inputs.dart Seçenek kutuları, sayı seçici, ölçek
    ├── bar_chart.dart, stat_tile.dart, privacy_banner.dart
assets/fonts/                  Nunito (SIL OFL), uygulamaya gömülü
assets/sounds/                 Ses efektleri (sentez, telif yok)
tool/make_sounds.py            Ses efektlerini üreten betik (Python + numpy)
```

- **Durum yönetimi:** Tek bir `AppState` (`ChangeNotifier`). Ekranlar
  `ListenableBuilder` ile dinler. Ek paket (provider, riverpod…) yok.
- **Ödül akışı:** Ekran bir eylem metodu çağırır (`logMood`, `tagEvent`,
  `finishDelay`, `logBreathing`, `completeOnboarding`). Metot kaydı yapar,
  yeni tamamlanan görevleri `pendingQuestRewards` ile hesaplar ve bir
  `Reward` döndürür; ekran `CelebrationScreen.show` ile kutlar.
- **Kılıf soyutlaması:** `DeviceService` → `events` (Stream), `status`
  (ValueListenable), `connect()`, `disconnect()`, `dispose()`.
  - Gerçek kılıf bağlı değilken de sayar ve hafızasında tutar; bağlanınca
    birikmiş olayları zaman damgasıyla gönderir. `DemoDeviceService` de
    böyle davranır (uygulama kapalıyken "geçen" sigaraları açılışta ekler,
    en fazla 30 gün geriye).
  - Aynı zaman damgalı olay iki kez gelirse `AppState` tekrar saymaz.
- **Demo kılıf:** Her gün için tohumdan (seed) üretilen sabit bir plan:
  günde 10–25 sigara (profildeki günlük sayıya yakın), uyanınca ilk sigara
  (Fagerström cevabına göre), kahve/çay ve yemek sonrası yoğunlaşma, hafta
  sonu geç uyanma ve akşam artışı, en az 20 dk ara. "Demo verisi üret"
  ayrıca geçmiş günler için ruh hali, nedenler, nefes, erteleme ve XP üretir
  (bugün boş kalır; 10. gün bilerek boş: dinlenme gününü gösterir).
- **Kayıt:** `shared_preferences` (Android/iOS yerel dosya, web'de
  localStorage). Anahtarlar: `profile`, `onboarding_done`, `events`,
  `activity`, `tracking_started_at`, `demo_last_sync`, `demo_seed`,
  `sound_on`, `haptics_on`.
- **Paketler:** `shared_preferences`, `flutter_localizations` (SDK),
  `audioplayers` (telefonda ses), `web` (Dart ekibinin resmi paketi; web'de
  ses). Grafik, konfeti ve maskot kendi yazdığımız bileşenler.
- **Ses mimarisi:** `Effects` (statik) → `SoundPlayer` arayüzü.
  - Telefonda `AudioplayersSoundPlayer`.
  - Web'de `WebAudioSoundPlayer`: iPhone Safari sese ancak bir DOKUNUŞ
    anında izin verir. Uygulamanın kökündeki `Listener` her dokunuşta
    `Effects.unlock()` çağırır; tek bir Web Audio bağlamı açılır, sonraki
    tüm sesler gecikmesiz çalar. Web Audio, iPhone'un sessiz moduna uyar.
  - Testlerde varsayılan `SilentSoundPlayer` (ses yok); testler
    `RecordingPlayer` ile hangi sesin çaldığını kontrol eder.
  - Ses dosyaları: `assets/sounds/*.wav` (22050 Hz, mono, toplam ~230 KB),
    uygulamanın kendi sitesinden yüklenir (dış istek yok).
- **Titreşim:** Flutter'ın `HapticFeedback`'i. Web'de Android Chrome'da
  çalışır; **iPhone tarayıcısı titreşimi desteklemez** (uygulamada çalışır).
- **Font:** Nunito (Medium 500, Bold 700, ExtraBold 800, Black 900), Latin +
  Türkçe harflere küçültülmüş (~48 KB/dosya), `assets/fonts/`.
- **Web:** `--no-web-resources-cdn` ile derlenir; arayüzde fontta olmayan
  karakter (→, emoji vb.) kullanılmaz, yoksa tarayıcı Google'dan yedek font
  indirir.

### BLE protokolü (TASLAK — Aşama 7'de donanım ekibiyle kesinleşecek)
- Özel bir GATT servisi; "olay" karakteristiği (notify): her sigara için
  `sıra no (uint16)` + `zaman`.
- Kılıfın gerçek saat (RTC) pili yoksa zaman "açılıştan beri geçen saniye"
  olarak gönderilir; telefon bağlanınca kılıfın o anki sayacını okuyup
  gerçek saate çevirir.
- Telefon aldığı son sıra numarasını onaylar (ack); kılıf onaylananları
  hafızasından silebilir. Bu, çift sayımı ve kaybı önler.

## 6. Veri modeli

- `SmokingEvent { time, source: demo | device, trigger? }`
- `UserProfile` (hepsi isteğe bağlı): `cigarettesPerDay`, `yearsSmoking`,
  `firstCigarette` (4 seçenek), `packPrice`, `cigarettesPerPack` (vars. 20),
  `triggers`, `goal`, `quitDesire` (1–10), `ageRange`, `gender`,
  `motivators`, `activities`.
- `ActivityLog { moods[], delays[], breaths[], xp[], activeDelayStart? }`
  - `MoodEntry { time, mood }` (Harika / İyi / İdare eder / Zor / Çok zor)
  - `DelayAttempt { start, end, outcome: success | gaveIn }`
  - `XpEntry { time, amount, reason }` — XP'nin "defteri"; toplam ve seri
    buradan hesaplanır.
- `tracking_started_at`: ölçüm haftasının başlangıcı (onboarding bitince).

## 7. Ekranlar (Aşama 2 itibarıyla)

- **Onboarding:** Karşılama ("Merhaba! Ben Nefes.") → 11 tek-soruluk ekran
  → konfetili "Hazırsın!". Sağ üstte "ATLA" (o ana kadarki cevaplar
  kaydedilir). Profil/Ayarlar'dan düzenleme modunda tekrar açılır.
- **Bugün:** ölçüm rozeti + seri + XP; demo uyarısı (+1 sigara); maskot
  cümlesi; "CANIM SİGARA İSTİYOR"; günlük görevler; ruh hali check-in'i;
  bugünkü sigaralar ve "Neden?" etiketleri.
- **İstatistik:** bugün kartı, haftalık karşılaştırma, grafik, maliyet
  kartları.
- **Profil:** maskot, seri, en uzun seri, toplam XP, ertelenen istekler,
  "Seri nasıl işler?", bilgilerimi düzenle, ayarlar.
- **Erteleme / Nefes / Kutlama:** tam ekran akışlar.
- **Ayarlar:** kılıf durumu, demo verisi üret/simüle et/sıfırla, bilgilerim,
  gizlilik + tüm verilerimi sil, kaynaklar, hakkında.

## 8. Görsel dil

- **Renkler** (`AppColors`): parlak yeşil (ilerleme, maskot), buton yeşili
  (beyaz yazı okunsun diye biraz koyu), mavi (seçim, erteleme), altın (XP),
  turuncu (seri), mor (rozet, neden etiketleri), kırmızı (sadece silme).
  Açık ve koyu tema.
- **Butonlar:** `ChunkyButton` — 4 px'lik koyu alt kenar; basınca iner.
  Yazılar BÜYÜK HARFLE ve elle yazılır (`toUpperCase()` Türkçe "i"yi bozar).
- **Kartlar:** `ChunkyCard` — 2 px gri çerçeve + 3 px alt kenar.
- **Erişilebilirlik:** Butonlarda beyaz yazı/yeşil zemin kontrastı ~3,2:1
  (kalın, büyük yazı). Büyük yazı boyutunda (%130) ve dar ekranda (360 px)
  tüm sekmelerde, onboarding'de, kutlama ve erteleme ekranlarında taşma
  olmadığı testle kontrol ediliyor. "Animasyonları azalt" açıksa konfeti gösterilmez.

## 9. Kaynaklar ve kaynaklı bilgiler

| Bilgi | Kaynak | Kullanıldığı yer |
|---|---|---|
| Sigara başına yaşam süresi: erkek ~17 dk, kadın ~22 dk, ort. ~20 dk | Jackson SE, Jarvis MJ, West R. "The price of a cigarette: 20 minutes of life?" *Addiction*, 2024 (UCL). doi:10.1111/add.16757 | İstatistik |
| Uyanınca ilk sigara süresi (bağımlılık göstergesi) | Heatherton TF ve ark. "The Fagerström Test for Nicotine Dependence", *Br J Addict*, 1991 | Onboarding, demo |
| Perhiz ihlali etkisi (seri tasarımının gerekçesi) | Marlatt GA, Gordon JR. *Relapse Prevention*, Guilford Press, 1985 | Tasarım kararı (ekranda sayı yok) |
| Sigara başına ~6 dk içme süresi | **Varsayım** (kaynaklı değil) | İstatistik |
| İyileşme takvimi (aşağıda) | WHO — "Tobacco: Health benefits of smoking cessation" (who.int) | Aşama 3 (Sürdürme), Aşama 4 (mesajlar) |
| ALO 171 Sigara Bırakma Danışma Hattı | T.C. Sağlık Bakanlığı | Aşama 3 (Bırakma günü) |
| Sigara bırakma poliklinikleri (MHRS randevu) | T.C. Sağlık Bakanlığı | Aşama 3 (Bırakma günü) |
| Nunito yazı tipi | The Nunito Project Authors, SIL Open Font License 1.1 (`assets/fonts/OFL.txt`) | Tüm arayüz |
| Ses efektleri | Ekip tarafından sentezlendi (`tool/make_sounds.py`), telif yok | Kutlamalar, nefes, erteleme |

**WHO iyileşme takvimi** (Aşama 3'te eklemeden önce metni WHO sayfasından
birebir doğrulayın):
- 20 dakika: kalp atış hızı ve kan basıncı düşer.
- 12 saat: kandaki karbonmonoksit seviyesi normale döner.
- 2–12 hafta: dolaşım iyileşir, akciğer fonksiyonu artar.
- 1–9 ay: öksürük ve nefes darlığı azalır.
- 1 yıl: koroner kalp hastalığı riski, içmeye devam edenlerin yaklaşık
  yarısına iner.
- 5 yıl: inme riski 5–15 yıl içinde hiç içmemiş birininkine iner.
- 10 yıl: akciğer kanseri riski, içmeye devam edenlerin yaklaşık yarısına
  iner; ağız, boğaz, yemek borusu, mesane, rahim ağzı ve pankreas kanseri
  riski azalır.
- 15 yıl: koroner kalp hastalığı riski hiç içmemiş birininki kadar olur.

## 10. Aşama planı ve durum

| Aşama | Kapsam | Durum |
|---|---|---|
| 1 | Temel: proje, dokümanlar, CI/Pages, `DeviceService` + demo kılıf, onboarding + yerel kayıt, ana ekran (Özellik 1–2) | ✅ Tamamlandı (10.10.2026) |
| 2 | Duolingo tarzı tasarım + oyunlaştırma: görevler, XP, seri, erteleme, nefes, kutlama, maskot, sekmeler (Özellik 2b) | ✅ Tamamlandı (10.10.2026) |
| 3 | Süreç aşamaları (Özellik 3) | ⏳ Sıradaki |
| 4 | Mesaj motoru + bildirimler (Özellik 4) | ⏳ Planlandı |
| 5 | Para kumbarası (Özellik 5) | ⏳ Planlandı |
| 6 | Karakter: enerji/sağlık göstergeleri (Özellik 6) | ⏳ Planlandı (sonra) |
| 7 | Gerçek Bluetooth + CSV dışa aktarma (Özellik 7) | ⏳ Planlandı (sonra) |

> **Öneri:** Pilot veri toplama TÜBİTAK takviminde kritik yol. Kılıf hazır
> olduğunda Aşama 7 (Bluetooth + CSV), Aşama 6'nın (karakter) önüne
> alınabilir.

### Aşama 1 — Temel ✅
- [x] Flutter projesi (Android, iOS, web), Türkçe arayüz
- [x] CLAUDE.md, docs/SPEC.md, README
- [x] GitHub Actions: analiz + test + web derlemesi; main'de Pages'e yayın
- [x] `DeviceService` arayüzü + `DemoDeviceService`
- [x] Onboarding + yerel kayıt
- [x] Ana ekran (bugün, karşılaştırmalar, grafik, para/süre/yaşam tahmini)
- [x] Ayarlar (demo, bilgilerimi düzenle, tüm verileri sil, kaynaklar)

### Aşama 2 — Duolingo tarzı tasarım ve oyunlaştırma ✅
- [x] Tasarım sistemi: `AppColors`, Nunito (gömülü), `ChunkyButton`,
      `ChunkyCard`, `ChunkyProgressBar`, açık/koyu tema
- [x] Maskot "Nefes" (4 ifade: neşeli, kutlama, sakin, düşünceli)
- [x] Konfeti + kutlama ekranı (sayarak artan XP, seri kutucuğu, titreşim)
- [x] Günlük görevler (ölçüm haftasına göre değişen), XP defteri
- [x] Affedici seri (dinlenme günü), en uzun seri
- [x] Erteleme (10 dk), nefes egzersizi (1 dk), ruh hali check-in'i,
      sigara nedenini işaretleme
- [x] Alt menü: Bugün / İstatistik / Profil
- [x] Onboarding: tek soru = tek ekran, maskot soruyor, sonunda konfeti
- [x] Ölçüm haftası rozeti ve takip başlangıç tarihi
- [x] Demo: geçmiş görev/XP/neden üretimi
- [x] Testler: görev/ödül/seri kuralları, AppState, arayüz akışları,
      büyük yazı boyutu; web'de dış istek yok (Playwright)
- [x] Ses efektleri (6 sentez ses) ve titreşim; Ayarlar'da aç/kapat;
      telefonda sessiz moda uyar, müziği durdurmaz; web'de iPhone uyumlu
      Web Audio

### Aşama 3 — Süreç aşamaları (sıradaki)
- [ ] Aşama modeli ve kaydı (hangi aşamada, ne zaman başladı)
- [ ] Ölçüm haftası bitişi: "Ölçüm haftan bitti!" kutlaması + özet
- [ ] Farkındalık ekranı: en yoğun saatler, işaretlenen nedenlerin
      dağılımı, ilk sigara saati ortalaması (sadece kullanıcının verisi)
- [ ] Azaltma: haftalık kademeli hedef (ölçüm ortalamasından), hedef kartı;
      hedefin altında kalınan gün için görev/rozet
- [ ] Bırakma günü: tarih seçimi, ALO 171 ve poliklinik (MHRS) bilgisi
- [ ] Sürdürme: sigarasız süre sayacı + toplam sigarasız gün (sıfırlanmaz),
      WHO takvimi (metin doğrulanmalı)
- [ ] Kayma için suçlamasız akış
- [ ] Aşamalar arası geçiş: otomatik öneri + kullanıcı onayı
- [ ] Testler

### Aşama 4 — Mesaj motoru
- [ ] Mesaj şablonları (3 tür × ton seçenekleri), profil/veri koşulları
- [ ] Kurallar: günde ≤3, sigaradan hemen sonra suçlama yok, aynı tür üst
      üste yok, hedef aşılınca destek, ölçüm haftasında mesaj yok
- [ ] Yerel bildirimler (mobilde; web'de uygulama içi kart); seri
      hatırlatması suçlamasız
- [ ] Ayarlar: ton seçimi, bildirim saatleri
- [ ] Kuralların birim testleri

### Aşama 5 — Para kumbarası
- [ ] Hedef ödül (ad + tutar), biriken = (ölçüm ort. − içilen) × sigara fiyatı
- [ ] İlerleme çubuğu, hedefe ulaşınca kutlama

### Aşama 6 — Karakter
- [ ] Enerji (azaltma) ve sağlık (sigarasız süre) göstergeleri; maskot
      asla ölmez, üzgün çizilmez

### Aşama 7 — Bluetooth + CSV
- [ ] Firmware ile protokol (yukarıdaki taslak) kesinleştirme
- [ ] `BleDeviceService` (flutter_blue_plus), izinler (Android/iOS),
      eşleştirme ekranı; demo/gerçek seçimi ayarlardan
- [ ] Gerçek kılıfa geçerken demo kayıtlarını silme seçeneği
- [ ] CSV dışa aktarma (paylaş menüsü), anonim katılımcı kodu
- [ ] Not: Web'de Bluetooth sınırlı (iOS Safari'de yok); pilot mobil
      uygulamayla yapılmalı

## 11. Açık sorular / kararlar

- **Yaş sınırı ve etik:** Yaş aralıkları 18+ ile başlıyor. Pilotta reşit
  olmayan katılımcı olacaksa etik kurul/veli izni gerekir — ekip ve danışman
  öğretmen karar vermeli.
- **Maskotun adı ve görünüşü:** Şimdilik "Nefes" (`lib/widgets/mascot.dart`
  → `mascotName`). Ekip isterse değiştirebilir. Duolingo'nun adı, logosu
  veya baykuşu kullanılmaz; sadece tarzından ilham alınır.
- **Seslerin iPhone'da denenmesi:** Web Audio'nun iPhone Safari'de ilk
  dokunuşla açılması tasarlandı ve Chrome'da doğrulandı, ama gerçek bir
  iPhone'da denenmeli. iPhone sessiz moddaysa web'de ses duyulmaz (bilerek).
- **Sesler zevke göre:** Sesler basit sentezlerdir. Ekip beğenmezse
  `tool/make_sounds.py`'deki notalar/süreler değiştirilip yeniden
  üretilebilir.
- **Oyunlaştırma ve ölçüm:** "Canım sigara istiyor" butonu ölçüm haftasında
  da açık; bu, başlangıç ölçümünü biraz etkileyebilir. Kullanıcının kendi
  istediği yardımı engellemek etik olmadığı için bilerek açık bırakıldı.
  Pilot raporunda belirtilmeli.
- **Sigara içme süresi varsayımı (6 dk):** Kaynaklı bir değer bulunursa
  güncellenmeli ya da kullanıcı ayarlayabilmeli.
- **iPhone web depolama:** Safari, uzun süre ziyaret edilmeyen sitelerin
  verilerini silebilir. "Ana Ekrana Ekle" ile açmak daha güvenli; kalıcı
  pilot verisi için mobil uygulama gerekir.
- **Kayıt kapasitesi:** shared_preferences ile yıllık ~9.000 olay sorunsuz;
  pilot ölçeğinde tekrar değerlendirilecek.

## 12. Sürüm geçmişi

| Sürüm | Başlık | Açıklama |
|---|---|---|
| 0.1.0 | Temel ve demo kılıf | Proje iskeleti, demo kılıf, onboarding, ana ekran, ayarlar, testler, GitHub Pages yayını |
| 0.2.0 | Nefes ile oyunlaştırma | Duolingo tarzı tasarım (Nunito, tok butonlar, canlı renkler), maskot "Nefes", günlük görevler, XP, affedici seri, erteleme, nefes egzersizi, ruh hali, sigara nedenleri, konfetili kutlamalar, Bugün/İstatistik/Profil sekmeleri |
| 0.3.0 | Ses ve titreşim | Sıfırdan sentezlenmiş 6 ses efekti (ding-ding, fanfar, sakin çan, nefes al/ver, zil), kutlama/nefes/erteleme titreşimleri, Ayarlar'da aç/kapat; telefonda sessiz moda uyar ve müziği durdurmaz; web'de iPhone uyumlu Web Audio |
