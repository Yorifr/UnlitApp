# Unlit — Proje Şartnamesi (SPEC)

> Bu dosya projenin "tek doğru kaynağı"dır. Yeni bir oturuma/ekip üyesine
> bağlam vermek için buradan başlayın. **Her aşama bitince "Aşama planı ve
> durum" ile "Sürüm geçmişi" bölümlerini güncelleyin.**

Son güncelleme: 10 Ekim 2026 — Aşama 1 tamamlandı.

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
- **Kılıf henüz yok.** İlk aşamalarda sahte veri üreten bir **demo modu**
  (`DemoDeviceService`) kullanılır.

## 2. Temel ilkeler (pazarlık konusu değil)

1. **Gizlilik:** Veriler **sadece cihazda** saklanır. Hesap yok, sunucu yok,
   analiz/reklam SDK'sı (Firebase vb.) yok. Web sürümü de dış sunuculara
   istek atmaz (Google CDN/Google Fonts dahil).
2. **Uydurma sayısal iddia yok:** Ekranda/mesajda gösterilen her sayı ya
   kullanıcının kendi verisidir ya da kaynağı belli bir bilgidir (bkz.
   Bölüm 7). Varsayımlar "varsayım", ortalamalar "ortalama tahmin" diye
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

## 3. Özellikler (tam vizyon)

### Özellik 1 — Onboarding (isteğe bağlı, atlanabilir, kısa) ✅ Aşama 1
- En üstte: **"Bilgilerin sadece bu telefonda kalır, kimseyle paylaşılmaz."**
- Her sorunun yanında **"Neden soruyoruz?"** açıklaması.
- Sigara soruları: günlük sigara sayısı, kaç yıldır, uyanınca ilk sigara ne
  zaman (Fagerström 1. soru), paket fiyatı (+ paketteki adet), tetikleyiciler
  (kahve, çay, yemek, stres, arkadaşlar, alkol, can sıkıntısı, ders/iş arası,
  araba, telefon), hedef (azaltma/bırakma), bırakma isteği 1–10.
- İsteğe bağlı profil: yaş aralığı, cinsiyet ("Belirtmek istemiyorum"
  dahil), motivasyon (çocuk, eş, anne-baba, evcil hayvan, kendim), sevilen
  aktiviteler (koşu, futbol, yürüyüş, …).

### Özellik 2 — Ana ekran ✅ Aşama 1
- Bugünkü sigara sayısı (+ bugünkü ilk sigara saati, son sigaradan geçen süre)
- Geçen haftayla karşılaştırma:
  - Bugün ↔ geçen haftanın aynı günü, **aynı saate kadar**
  - Son 7 gün ↔ önceki 7 gün (yüzde değişim)
  - Yeterli kayıt yoksa karşılaştırma gösterilmez (yanıltmasın diye).
- Grafik: son 7 gün (günlük) / bugün (saatlik)
- Harcanan para, sigaraya giden süre, tahmini kaybedilen yaşam süresi
  (dönem: bugün / 7 gün / 30 gün)
  - Yaşam süresi: sigara başına erkek ~17 dk, kadın ~22 dk, belirtilmemişse
    ~20 dk (UCL 2024). **"Ortalama tahmin"** olduğu açıkça yazar.
  - Sigaraya giden süre: sigara başına ~6 dk **varsayımı** (kaynaklı değil;
    ekranda "varsayım" yazar).

### Özellik 3 — Süreç aşamaları ⏳ Aşama 2
Ölçüm → Farkındalık → Azaltma → Bırakma günü → Sürdürme
- **Ölçüm (1 hafta):** sadece veri toplanır, **hiç mesaj yok**.
- **Farkındalık:** kullanıcıya kendi örüntüsü gösterilir (en yoğun saatler,
  tetikleyicilerle eşleşen anlar, sabah ilk sigara saati).
- **Azaltma:** kademeli günlük hedefler (kullanıcının kendi ölçüm haftası
  ortalamasından başlayarak).
- **Bırakma günü:** kullanıcı tarih seçer; **ALO 171** (Sigara Bırakma
  Danışma Hattı) ve **sigara bırakma polikliniği** (MHRS üzerinden randevu)
  yönlendirmesi.
- **Sürdürme:** sigarasız gün sayacı, **WHO iyileşme takvimi** (bkz.
  Bölüm 7). Kayma (bir sigara) olursa suçlamadan, destekleyici şekilde ele
  alınır.

### Özellik 4 — Mesaj motoru ⏳ Aşama 3
Profil bilgisine göre seçilen 3 tür mesaj:
1. **Motivasyon:** "Geçen haftaya göre %10 az içtin."
2. **Geleceğe dönük fırsat:** "Yarın sabah koşacaksan bu akşam son sigarayı
   21:00'de içmeye ne dersin?"
3. **Somut öneri:** "Kahveden sonra 10 dk yürü, sonra karar ver."

Kurallar:
- Günde **en fazla 3** bildirim.
- Sigaradan **hemen sonra suçluluk mesajı yok**.
- Hedef aşılınca **destekleyici** mesaj.
- **Aynı tür üst üste gelmez.**
- Kullanıcı **tonu seçebilir** (ör. samimi / sade / esprili).
- **Uydurma sayı yok:** sadece kullanıcının kendi verisi veya kaynaklı bilgi
  (ör. WHO: "12 saatte kandaki karbonmonoksit normale döner").
- Ölçüm haftasında mesaj yok.

### Özellik 5 — Para kumbarası ⏳ Aşama 4
Kullanıcı bir hedef ödül belirler (ör. "kulaklık, 2.000 ₺"); ölçüm haftası
ortalamasına göre **içilmeyen** sigaraların parası kumbarada birikir ve
hedefe ilerleme gösterilir.

### Özellik 6 — Karakter ⏳ Aşama 5 (sonra)
Ödül odaklı, **asla ölmez**.
- **Enerji** göstergesi: azaltmaya bağlı.
- **Sağlık** göstergesi: **sadece sigarasız süreye** bağlı.

### Özellik 7 — Gerçek Bluetooth + veri dışa aktarma ⏳ Aşama 6 (sonra)
- `BleDeviceService` (flutter_blue_plus) — aynı `DeviceService` arayüzü.
- TÜBİTAK pilotu için **CSV dışa aktarma** (kullanıcı kendi isteğiyle
  paylaşır; uygulama otomatik göndermez).

## 4. Mimari

```
lib/
├── main.dart                  Başlangıç: kayıt + cihaz + AppState
├── app.dart                   MaterialApp, tema, Türkçe dil, kök ekran
├── app_state.dart             Uygulamanın "beyni" (ChangeNotifier)
├── app_info.dart              Uygulama adı ve sürümü
├── theme.dart                 Renkler/tema (Material 3)
├── models/
│   ├── smoking_event.dart     Sigara alma olayı (zaman + kaynak)
│   └── user_profile.dart      Onboarding cevapları + seçenek listeleri
├── services/
│   ├── device_service.dart    Kılıf arayüzü (abstract class)
│   ├── demo_device_service.dart   Sanal kılıf
│   ├── demo_day_planner.dart  Gerçekçi bir günün sigara saatleri
│   └── storage_service.dart   Yerel kayıt (shared_preferences)
├── logic/
│   └── stats.dart             Tüm hesaplamalar (saf fonksiyonlar)
├── utils/
│   └── format.dart            Türkçe tarih/para/süre yazımı
├── screens/                   Onboarding, ana ekran, ayarlar
└── widgets/                   Tekrar kullanılan parçalar (grafik, kart...)
```

- **Durum yönetimi:** Tek bir `AppState` (`ChangeNotifier`). Ekranlar
  `ListenableBuilder` ile dinler. Ek paket (provider, riverpod…) yok.
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
  sonu geç uyanma ve akşam artışı, en az 20 dk ara.
- **Kayıt:** `shared_preferences` (Android/iOS yerel dosya, web'de
  localStorage). Olaylar JSON listesi: `[{"t": epochMs, "s": "demo"}]`.
  Birkaç bin kayıt için yeterli; pilotta yavaşlarsa SQLite'a (sqflite/drift)
  geçilebilir.
- **Paketler:** `shared_preferences`, `flutter_localizations` (SDK).
  Grafik kendi yazdığımız basit bileşen (`SimpleBarChart`).
- **Web:** `--no-web-resources-cdn` ile derlenir; arayüzde Roboto fontunda
  olmayan karakter (→, emoji vb.) kullanılmaz, yoksa tarayıcı Google'dan
  yedek font indirir.

### BLE protokolü (TASLAK — Aşama 6'da donanım ekibiyle kesinleşecek)
- Özel bir GATT servisi; "olay" karakteristiği (notify): her sigara için
  `sıra no (uint16)` + `zaman`.
- Kılıfın gerçek saat (RTC) pili yoksa zaman "açılıştan beri geçen saniye"
  olarak gönderilir; telefon bağlanınca kılıfın o anki sayacını okuyup
  gerçek saate çevirir.
- Telefon aldığı son sıra numarasını onaylar (ack); kılıf onaylananları
  hafızasından silebilir. Bu, çift sayımı ve kaybı önler.

## 5. Veri modeli

- `SmokingEvent { time: DateTime, source: demo | device }`
- `UserProfile` (hepsi isteğe bağlı): `cigarettesPerDay`, `yearsSmoking`,
  `firstCigarette` (4 seçenek), `packPrice`, `cigarettesPerPack` (vars. 20),
  `triggers`, `goal`, `quitDesire` (1–10), `ageRange`, `gender`,
  `motivators`, `activities`.
- Diğer anahtarlar: `onboarding_done`, `demo_last_sync`, `demo_seed`.

## 6. Ekranlar (Aşama 1 itibarıyla)

- **Onboarding:** Karşılama → Alışkanlık → Harcama → Tetikleyiciler → Hedef
  → (isteğe bağlı) Profil → Motivasyon/aktiviteler → Hazırsın. Sağ üstte
  "Atla" (o ana kadarki cevaplar kaydedilir). Ayarlardan düzenleme modunda
  tekrar açılır.
- **Ana ekran:** demo uyarısı (+1 sigara), bugün kartı, haftalık
  karşılaştırma, grafik, maliyet kartları, açıklama notu.
- **Ayarlar:** kılıf durumu, demo verisi üret/simüle et/sıfırla,
  bilgilerimi düzenle, gizlilik + tüm verilerimi sil, kaynaklar, hakkında.

## 7. Kaynaklar ve kaynaklı bilgiler

| Bilgi | Kaynak | Kullanıldığı yer |
|---|---|---|
| Sigara başına yaşam süresi: erkek ~17 dk, kadın ~22 dk, ort. ~20 dk | Jackson SE, Jarvis MJ, West R. "The price of a cigarette: 20 minutes of life?" *Addiction*, 2024 (UCL). doi:10.1111/add.16757 | Ana ekran |
| Uyanınca ilk sigara süresi (bağımlılık göstergesi) | Heatherton TF ve ark. "The Fagerström Test for Nicotine Dependence", *Br J Addict*, 1991 | Onboarding, demo |
| Sigara başına ~6 dk içme süresi | **Varsayım** (kaynaklı değil) | Ana ekran |
| İyileşme takvimi (aşağıda) | WHO — "Tobacco: Health benefits of smoking cessation" (who.int) | Aşama 2 (Sürdürme), Aşama 3 (mesajlar) |
| ALO 171 Sigara Bırakma Danışma Hattı | T.C. Sağlık Bakanlığı | Aşama 2 (Bırakma günü) |
| Sigara bırakma poliklinikleri (MHRS randevu) | T.C. Sağlık Bakanlığı | Aşama 2 (Bırakma günü) |

**WHO iyileşme takvimi** (Aşama 2'de eklemeden önce metni WHO sayfasından
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

## 8. Aşama planı ve durum

| Aşama | Kapsam | Durum |
|---|---|---|
| 1 | Temel: proje, dokümanlar, CI/Pages, `DeviceService` + demo kılıf, onboarding + yerel kayıt, ana ekran (Özellik 1–2) | ✅ Tamamlandı (10.10.2026) |
| 2 | Süreç aşamaları (Özellik 3) | ⏳ Sıradaki |
| 3 | Mesaj motoru + bildirimler (Özellik 4) | ⏳ Planlandı |
| 4 | Para kumbarası (Özellik 5) | ⏳ Planlandı |
| 5 | Karakter (Özellik 6) | ⏳ Planlandı (sonra) |
| 6 | Gerçek Bluetooth + CSV dışa aktarma (Özellik 7) | ⏳ Planlandı (sonra) |

> **Öneri:** Pilot veri toplama TÜBİTAK takviminde kritik yol. Kılıf hazır
> olduğunda Aşama 6 (Bluetooth + CSV), Aşama 5'in (karakter) önüne
> alınabilir.

### Aşama 1 — Temel ✅
- [x] Flutter projesi (Android, iOS, web), Türkçe arayüz
- [x] CLAUDE.md, docs/SPEC.md, README
- [x] GitHub Actions: analiz + test + web derlemesi; main'de Pages'e yayın
- [x] `DeviceService` arayüzü + `DemoDeviceService` (geçmiş üret, kapalıyken
      geçen süreyi doldur, canlı olay, +1 simülasyon, sıfırla)
- [x] Onboarding (atlanabilir, "Neden soruyoruz?", gizlilik notu) + yerel kayıt
- [x] Ana ekran (bugün, karşılaştırmalar, grafik, para/süre/yaşam tahmini)
- [x] Ayarlar (demo, bilgilerimi düzenle, tüm verileri sil, kaynaklar)
- [x] Birim + arayüz testleri; web sürümü dış sunucuya istek atmıyor
      (Playwright ile kontrol edildi)

### Aşama 2 — Süreç aşamaları (sıradaki)
- [ ] Aşama modeli ve kaydı (hangi aşamada, ne zaman başladı); kullanıcının
      takip başlangıç tarihi (`trackingStartedAt`) saklanmalı
- [ ] Ölçüm haftası: 7 gün, ilerleme göstergesi ("Ölçüm: 3. gün / 7"), mesaj yok
- [ ] Farkındalık ekranı: en yoğun saatler, ilk sigara saati ortalaması,
      tetikleyicilerle eşleşen anlar (sadece kullanıcının verisi)
- [ ] Azaltma: haftalık kademeli hedef (ölçüm ortalamasından), hedef kartı
- [ ] Bırakma günü: tarih seçimi, ALO 171 ve poliklinik (MHRS) bilgisi
- [ ] Sürdürme: sigarasız gün/saat sayacı, WHO takvimi (metin doğrulanmalı)
- [ ] Kayma (bırakmadan sonra sigara) için suçlamasız akış
- [ ] Aşamalar arası geçiş: otomatik öneri + kullanıcı onayı (kullanıcı
      isterse aşamayı kendisi değiştirebilir)
- [ ] Testler

### Aşama 3 — Mesaj motoru
- [ ] Mesaj şablonları (3 tür × ton seçenekleri), profil/veri koşulları
- [ ] Kurallar: günde ≤3, sigaradan hemen sonra suçlama yok, aynı tür üst
      üste yok, hedef aşılınca destek, ölçüm haftasında mesaj yok
- [ ] Yerel bildirimler (mobilde; web'de uygulama içi kart)
- [ ] Ayarlar: ton seçimi, bildirim saatleri
- [ ] Kuralların birim testleri

### Aşama 4 — Para kumbarası
- [ ] Hedef ödül (ad + tutar), biriken = (ölçüm ort. − içilen) × sigara fiyatı
- [ ] İlerleme çubuğu, hedefe ulaşınca kutlama

### Aşama 5 — Karakter
- [ ] Asla ölmeyen karakter; enerji (azaltma) ve sağlık (sigarasız süre)

### Aşama 6 — Bluetooth + CSV
- [ ] Firmware ile protokol (yukarıdaki taslak) kesinleştirme
- [ ] `BleDeviceService` (flutter_blue_plus), izinler (Android/iOS),
      eşleştirme ekranı; demo/gerçek seçimi ayarlardan
- [ ] Gerçek kılıfa geçerken demo kayıtlarını silme seçeneği
- [ ] CSV dışa aktarma (paylaş menüsü), anonim katılımcı kodu
- [ ] Not: Web'de Bluetooth sınırlı (iOS Safari'de yok); pilot mobil
      uygulamayla yapılmalı

## 9. Açık sorular / kararlar

- **Yaş sınırı ve etik:** Yaş aralıkları 18+ ile başlıyor. Pilotta reşit
  olmayan katılımcı olacaksa etik kurul/veli izni gerekir — ekip ve danışman
  öğretmen karar vermeli.
- **Sigara içme süresi varsayımı (6 dk):** Kaynaklı bir değer bulunursa
  güncellenmeli ya da kullanıcı ayarlayabilmeli.
- **iPhone web depolama:** Safari, uzun süre ziyaret edilmeyen sitelerin
  verilerini silebilir. "Ana Ekrana Ekle" ile açmak daha güvenli; kalıcı
  pilot verisi için mobil uygulama gerekir.
- **Kayıt kapasitesi:** shared_preferences ile yıllık ~9.000 olay sorunsuz;
  pilot ölçeğinde tekrar değerlendirilecek.

## 10. Sürüm geçmişi

| Sürüm | Başlık | Açıklama |
|---|---|---|
| 0.1.0 | Temel ve demo kılıf | Proje iskeleti, demo kılıf, onboarding, ana ekran, ayarlar, testler, GitHub Pages yayını |
