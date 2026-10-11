# Unlit — Proje Şartnamesi (SPEC)

> Bu dosya projenin "tek doğru kaynağı"dır. Yeni bir oturuma/ekip üyesine
> bağlam vermek için buradan başlayın. **Her aşama bitince "Aşama planı ve
> durum" ile "Sürüm geçmişi" bölümlerini güncelleyin.**

Son güncelleme: 11 Ekim 2026 — Aşama 2 (Duolingo tarzı tasarım ve
oyunlaştırma), ses/titreşim efektleri, tarihli paket fiyatı, kendi renk
teması ("Nane"), sadeleştirme (0.6.0: 4 soruluk onboarding, ölçüm haftası
özeti, "Kazandıkların"), Nefes 2.0 + "Nefes'in dolabı" (0.7.0) ve haftalık
rapor + "bir günlük veri ekle" demo seçeneği (0.8.0) ve erteleme
ekranında kişisel cümle (0.8.1) tamamlandı.

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
- **XP** ve **seri** (bizde alev değil yaprak ikonu; bkz. Bölüm 8). Ekranda
  XP'ye **"puan"** diyoruz: "XP" İngilizce oyun jargonu, herkes bilmiyor.
  (Kodda kısa olsun diye adı XP.)
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
   - Bugün henüz bir şey yapılmadıysa seri bozulmaz; seri yaprağı gri görünür.
   - **Dinlenme günü:** Haftada (7 günde) 1 kaçırılan gün otomatik
     affedilir; seri korunur ama artmaz.
   - Seri sıfırlanırsa dil olumlu: "Bugün bir görev yap, serin başlasın!"
     ve "en uzun seri" her zaman gösterilir.
3. **Günlük görevler** (gece yarısı yenilenir, yapılmayanın cezası yok):
   - **Ölçüm haftası (ilk 7 gün):** Kendini dinle (ruh hali), Nedenini
     keşfet (bir sigaranın nedenini işaretle), Nefes molası. **Azaltma
     görevi yok**, böylece başlangıç alışkanlığı doğru ölçülür.
   - **Sonrası:** Kendini dinle, İsteği ertele (10 dk), + günden güne
     değişen 3. görev (Nedenini keşfet / Nefes molası).
   - Her görevin hedefi 1 olduğu için görev satırında ilerleme çubuğu yok;
     onay işareti yeterli.
   - "Canım sigara istiyor" (erteleme) butonu **her zaman** açıktır:
     kullanıcının kendi istediği yardım asla engellenmez; sadece ölçüm
     haftasında görev olarak önerilmez.
4. **XP (puan) tablosu:**

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
   - **Kişisel cümle** (0.8.1, `delayStartLine`): Ekranın başında Nefes,
     kullanıcının daha önce atlattığı istekleri kendi verisiyle hatırlatır:
     "Daha önce 6 isteği atlattın; istekler genelde 7 dakika içinde geçti."
     Sadece başarılı ertelemeler sayılır ("yine de içtim" sayısı asla
     söylenmez). Süre en az 3 başarılı ertelemeden sonra ve 10 dakikadan
     kısaysa söylenir (ortanca süre, yukarı yuvarlanır; 10 dakikadan uzun
     bekleme 10 sayılır). Hiç başarılı erteleme yoksa genel cümle: "Bu
     istek geçici." Yeni bir kart eklenmedi; var olan cümle kişiselleşti.
6. **Kendini dinle (ruh hali):** Sadece görev satırından açılır (eskiden
   ayrıca bir kart vardı; aynı iş için iki giriş kafa karıştırıyordu).
   Seçenekler soldan sağa **olumsuzdan olumluya**: Çok zor, Zor, İdare
   eder, İyi, Harika (ölçeklerde alışılmış düzen). "Zor/Çok zor" seçilirse
   kutlama sakin olur ve maskot destekleyici konuşur.
7. **Maskot cümleleri** (`lib/logic/mascot_messages.dart`): sadece
   kullanıcının kendi verisi; azalma varsa kutlar, artış varsa nazikçe
   erteleme önerir; ölçüm haftasında karşılaştırma yapmaz ("hiçbir şeyi
   değiştirmeye çalışma, kılıfını taşı"); hafta bitince özeti, sonraki
   haftalarda haftalık raporu önerir. Haftalık raporun cümlesi ve "gelecek
   hafta için bir fikir" de burada seçilir (bkz. Özellik 2d).
8. **Renkler:** Kırmızı sadece "tümünü sil" gibi tehlikeli işlemlerde.
   Kullanıcının sigara davranışı asla kırmızıyla gösterilmez.
9. **Sadelik ve kademeli açılım** (0.6.0):
   - Her işin tek giriş noktası; ekranda tek seçici; üst çubukta sadece
     seri (puanın harcanacağı bir yer olmadığı için sürekli göz önünde
     durması gereksiz; kutlamalarda ve Profil'de görünür).
   - İlk gün her şey açık değil: **ölçüm haftası bitince** "Ölçüm haftan
     bitti!" ekranı açılır ve "İsteği ertele" görevi ile İstatistik'teki
     "Kazandıkların" ve "Haftalık raporların" bölümleri o an "açılır".
     "CANIM SİGARA İSTİYOR" butonu ise her zaman açık (kural, bkz. madde 3).
10. **Nefes'in dolabı ve büyüyen filiz** (0.7.0, `lib/logic/wardrobe.dart`):
   puanın harcanacağı değil, **anlam kazandığı** yer.
   - **Puan harcanmaz.** Eşyalar belli puanlarda ya da anlamlı anlarda
     **açılır**; toplam puan hiç düşmez. Açılan eşya **bir daha kaybolmaz**
     (toplam puan, en uzun seri ve "ölçüm haftası bitti" bilgisi zamanla
     sadece artar). Sigara içmek hiçbir şeyi kilitlemez ya da geri almaz.

     | Eşya | Ne zaman açılır |
     |---|---|
     | Güneş gözlüğü | 100 puan |
     | Atkı | 250 puan |
     | Kep (mezuniyet) | Ölçüm haftası bitince (özet ekranında, baştaki eşyanın yerine takılır; haftada hiç kayıt yoksa ilk olumlu eylemin kutlamasında haber verilir) |
     | Kulaklık | 500 puan |
     | Yaprak taç | En uzun seri 7 gün olunca |
     | Bere | 1000 puan |

   - "Ayarlar → kayıtları sıfırla" puanları sildiği için dolap ve filiz de
     baştan başlar (onay penceresinde yazıyor). 0.6.0'dan güncelleyen
     kullanıcıda, o ana kadar açılmış eşyalar ilk açılışta bir kez takılır.
   - Aynı anda **bir baş eşyası** (bere, kep, taç ya da kulaklık), **bir
     gözlük**, **bir atkı**. Yeni açılan eşya, yeri boşsa otomatik takılır
     (kutlamada görünsün); yeri doluysa kullanıcının seçimine dokunulmaz.
   - **Filiz** sadece **toplam puanla** büyür: 1. aşama (başlangıç), 300
     puanda 2., 1000 puanda 3., 2500 puanda 4. aşama (mor çiçek). Sigara
     sayısına, sigarasız süreye ya da Aşama 6'daki göstergelere **bağlı
     değildir**; asla küçülmez, asla solmaz (test ile korunuyor).
   - Yeni eşya ve filizin büyümesi kutlama ekranında haber verilir (büyük
     kutlama sesi).
   - **Yok:** sürpriz kutu (kumar mekaniği), "sadece bugün" (kaçırma
     korkusu), tetikleyici eşya (fincan, bardak, kadeh, pipo, ateş, duman).
   - Dolabın tek giriş noktası: Profil → "Nefes'in dolabı" kartı (sonraki
     eşyaya ilerleme çubuğu).
11. **Ses ve titreşim** (`lib/services/effects.dart`):
   - Ses **sadece güzel anlarda** çalar; "hata/ceza" sesi yoktur. Sigara
     içmek (kılıftan gelen olay) **hiçbir ses ya da titreşim tetiklemez**.

     | An | Ses | Titreşim |
     |---|---|---|
     | Görev tamamlandı | `success` ("ding-ding") | başarı titreşimi |
     | Büyük kutlama (günün görevleri, başarılı erteleme, "Hazırsın!", yeni eşya, filiz büyüdü) | `fanfare` | başarı titreşimi |
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

### Özellik 1 — Onboarding ✅ (Aşama 1; Aşama 2'de yenilendi; 0.6.0'da 4 soruya indi)
- En üstte: **"Bilgilerin sadece bu telefonda kalır, kimseyle paylaşılmaz."**
- Her ekranda tek soru; maskot soruyu sorar; **"Neden soruyoruz?"**
  açıklaması; cevap yoksa buton "ŞİMDİLİK GEÇ", varsa "DEVAM".
- İlke: **"Sorulan her soru bir söz."** Bir soru ancak cevabı uygulamada
  gerçekten bir şeyi değiştiriyorsa sorulur ve saklanır; "Neden
  soruyoruz?" metni tam olarak bunu söyler. Soru, cevabın kullanılacağı
  ana konur ("tam zamanında").
- **Sorulan 4 soru ve nerede kullanıldıkları:**

  | Soru | Nerede kullanılıyor |
  |---|---|
  | Günde kaç sigara (tahmin) | Ölçüm haftası özetinde kılıfın saydığıyla yan yana; demo verisi buna yakın |
  | Uyanınca ilk sigara (Fagerström 1. soru) | Ölçüm haftası özetinde, ölçülen ilk sigara saatinin yanında; demo verisi; Aşama 3'te sabah hedefi |
  | Paket fiyatı (+ paketteki adet) | Harcanan para, cebinde kalan para |
  | Tetikleyiciler | "Bu sigara neden?" penceresinde seçilenler en başta (tek dokunuş) |

- **Kaldırılan sorular ve ne zaman sorulacakları** (0.6.0'a kadar
  soruluyordu ama hiçbir yerde kullanılmıyordu; eski cevaplar açılışta
  kayıttan silinir):

  | Soru | Karar |
  |---|---|
  | Hedef (azaltmak/bırakmak), bırakma isteği 1–10 | Aşama 3'te, ölçüm haftası bitip plan kurulurken sorulacak |
  | Sevilen aktiviteler | Aşama 4'te, mesaj motoru ("Yarın koşacaksan…") gelince |
  | Motivasyon (çocuk, eş…) | Hazır seçenek yerine **kendine not** (aşağıda) |
  | Kaç yıldır, yaş aralığı, cinsiyet | Uygulamada dürüst bir kullanımı yok; pilot için gerekirse bkz. Bölüm 11 |

- **Kendine not:** Kullanıcı isterse "Bunu neden yapıyorsun?" sorusuna kendi
  cümlesiyle kısa bir not yazar (en fazla 140 harf). Erteleme ekranında,
  sayacın hemen altında gösterilir; yoksa ekranın en altında nazikçe
  önerilir. Ayarlar → "Kendime notum"dan da düzenlenir. Hazır seçenek
  ("Çocuğum için") yerine serbest yazı seçildi: hazır cümleler kolayca
  suçluluğa dönüşebilir; kişinin kendi cümlesi daha kişisel ve daha az
  riskli. Yazı kutusu sadece yazı tipinde olan harflere izin verir (emoji
  web'de dış font isteğine yol açardı).
- Sonunda konfetili "Hazırsın!" ekranı ve +10 puan.

### Özellik 2 — Ana ekran ✅ (Aşama 1; Aşama 2'de "İstatistik" sekmesine taşındı)
- Bugünkü sigara sayısı (+ bugünkü ilk sigara saati, son sigaradan geçen süre)
- Geçen haftayla karşılaştırma:
  - Bugün ↔ geçen haftanın aynı günü, **aynı saate kadar**
  - Son 7 gün ↔ önceki 7 gün (yüzde değişim; azalma varsa kart nane renkli)
  - Yeterli kayıt yoksa karşılaştırma gösterilmez (yanıltmasın diye).
  - Haftalık karşılaştırma kartı sadece 2 haftalık kayıt varken görünür
    (öncesinde boş bir "henüz yok" kartı kalabalık yapıyordu).
- Grafik: sadece son 7 gün (günlük). Saatlik görünüm ve ikinci seçici
  kaldırıldı (sayfada tek seçici kalsın; en yoğun saat ölçüm haftası
  özetinde).
- **Harcanan para** (dönem: bugün / 7 gün / 30 gün; sayfadaki tek seçici).
- **"Kazandıkların"** (0.6.0; ölçüm haftası bitince açılır, öncesinde ne
  zaman açılacağını söyleyen kapalı bir kart görünür):
  - Başlangıç noktası = ölçüm haftasında günde ortalama sigara.
  - **İçmediğin sigara** = ölçüm haftasından sonraki TAMAMLANMIŞ günlerde
    (bugün sayılmaz) Σ(ortalama − o günkü sayı), **net** ve en az 0.
  - **Cebinde kalan para** = her gün (ortalama − o günkü sayı) × **o günün**
    sigara fiyatı (`PriceHistory.at`), net ve en az 0.
  - **Korunan yaşam süresi** = içilmeyen sigara × ~20 dk (UCL 2024, genel
    ortalama). **"Ortalama tahmin"** olduğu ve kaynağı açıkça yazar; (i)
    penceresi hesabı anlatır.
  - Neden net? Her günü ayrı "ortalamanın altındaysa ekle" diye toplamak,
    hiç azaltmayan birinin günlük dalgalanmasını bile kazanç gibi
    gösterirdi. Neden bugün yok? Gün bitmeden "bugün 15 sigara içmedin"
    demek yanlış olur; böylece sayı sigaradan hemen sonra da değişmez.
  - Ölçüm haftası özeti, "Haftalık raporların" listesinde "1. hafta"
    olarak tekrar açılır (0.8.0'a kadar burada ayrı bir buton vardı; tek
    giriş noktası kalsın diye listeye taşındı).
- **Kaldırılanlar (0.6.0):** "Tahmini kaybedilen yaşam süresi" ve
  "Sigaraya giden süre (~6 dk varsayımı)" kartları. Gerekçe: Bölüm 11.
- **Paket fiyatı (tarihli):** Fiyat profilin parçası değil; kendi yeri
  İstatistik → "Paket fiyatı" kartı (ve Ayarlar'da kısayol).
  - Her fiyat "ne zamandan beri geçerli" bilgisiyle saklanır. **Her sigara
    kendi tarihindeki fiyatla** hesaplanır: zam gelip fiyat güncellenince
    eski günlerin harcaması değişmez.
  - Yeni fiyat **bugünden** geçerli olur; aynı gün tekrar değiştirilirse
    bugünkü kayıt düzeltilir. "Yanlış girmiştim" seçeneği tüm geçmişi yeni
    fiyatla hesaplar.
  - İlk fiyattan önceki kayıtlar ilk fiyatla hesaplanır (en iyi tahmin).
  - Pakette varsayılan 20 sigara; farklıysa "Paketin 20’li değil mi?" ile
    değiştirilir.
  - Fiyat 90 gün değişmediyse kartta nazikçe "Paket fiyatın hâlâ X ₺ mı?"
    sorulur ("AYNI" deyince bir süre sorulmaz). Açılır pencere ya da
    bildirim değildir.
  - Fiyat **internetten çekilmez** (bkz. Bölüm 11).

### Özellik 2b — Oyunlaştırma ✅ Aşama 2
Bölüm 3'teki her şey: "Bugün" sekmesi (maskot, "CANIM SİGARA İSTİYOR",
günlük görevler, bugünkü sigaralar ve nedenleri),
erteleme ekranı, nefes egzersizi, kutlama ekranı, "Profil" sekmesi (seri,
en uzun seri, toplam puan, ertelenen istekler).

### Özellik 2c — Ölçüm haftası özeti ✅ (0.6.0)
- Ölçüm haftası (ilk 7 gün) bitince "Bugün" sekmesinde maskot "Ölçüm haftan
  bitti!" der ve **SONUÇLARIMI GÖR** butonu çıkar (açılır pencere değil).
- Özet ekranı (konfeti + fanfar): günde ortalama (kullanıcının onboarding
  tahmini yanında, yorum yok), günün ilk sigarasının ortalama saati
  (onboarding'deki Fagerström cevabı yanında; gece 04:00'ten önceki
  sigaralar önceki gecenin sayılır), en yoğun saat, en sık işaretlenen
  neden. "Doğru ya da yanlış yok; bu senin başlangıç noktan."
- "Neler açıldı?": erteleme görevi ve "Kazandıkların" (kademeli açılım).
- Bir kez gösterilir (`measurement_summary_seen`); takip sıfırlanınca (demo
  verisi üretme, kayıtları sıfırlama) yeni ölçüm haftası için yeniden çıkar.
  Ölçüm haftasında hiç kayıt yoksa gösterilmez.
- Kod: `lib/logic/measurement.dart` (saf hesaplar),
  `lib/screens/measurement_summary_screen.dart`.
- Bu özet aynı zamanda **1. haftanın raporudur**; İstatistik → "Haftalık
  raporların" listesinde "1. hafta · Ölçüm haftası" olarak durur.

### Özellik 2d — Haftalık rapor ✅ (0.8.0)
- **Neden?** 0.7.0'a kadar her gün topladığımız veri (ruh hali, işaretlenen
  nedenler, ertelemeler, nefes molaları) ölçüm haftasından sonra kullanıcıya
  hiçbir yerde geri dönmüyordu; "kişiselleştirilmiş geri bildirim" sadece
  Bugün'deki tek maskot cümlesi ve bir kez gösterilen ölçüm özetiydi.
  Haftalık rapor bu döngüyü kapatır: "verdiğin her bilgi sana geri döner".
- **Haftalar takipten sayılır, takvimden değil:** 1. hafta = ölçüm haftası
  (takibin 1.–7. günü), 2. hafta = 8.–14. gün... Kullanıcı çarşamba
  başladıysa ilk takvim haftası yarım kalırdı; böylece her hafta tam 7
  günle karşılaştırılır. Sadece **biten** haftalar raporlanır.
- **Duyuru:** Hafta bitince Bugün'de maskot "2. haftan bitti! Haftalık
  raporun hazır" der ve **RAPORUMU GÖR** butonu çıkar (açılır pencere ya da
  bildirim değil). Sadece EN SON biten hafta duyurulur (uygulama üç hafta
  açılmadıysa üç rapor üst üste gelmez). Ölçüm haftası özeti bekliyorsa
  önce o çıkar. Haftada hiçbir şey olmadıysa (ne kayıt ne görev ne ruh
  hali) duyurulmaz. Görülen hafta `weekly_report_seen`'de saklanır.
- **Kalıcı yeri:** İstatistik → "Haftalık raporların" (en yenisi üstte, 4'ten
  fazlası "TÜMÜNÜ GÖSTER" ile; sıradaki raporun tarihi yazar).
- **İçerik** (sadece kullanıcının kendi verisi):
  1. Nefes'in cümlesi: önce olumlu olan söylenir (önceki haftadan az →
     başlangıç noktasının altında → aynı → artış). Artışta suçlama yok,
     "olur böyle" + kendine iyi baktığı gün sayısı; maskot sakin.
  2. Sigara: bu hafta ve önceki hafta (2. hafta için "Ölçüm haftası"), fark
     rozeti (azalma nane, artış nötr gri), günde ortalama ve başlangıç
     noktası, 7 günün grafiği.
  3. Örüntün: en yoğun saat, günün ilk sigarası (önceki haftanınki yanında,
     yorumsuz), en sık neden.
  4. Kendine iyi baktığın anlar: görev yaptığın gün (x / 7), ertelenen
     istek, nefes molası, kazanılan puan, ruh hali dağılımı (soldan sağa
     olumsuzdan olumluya).
  5. Bu hafta kazandıkların: **sadece içilmeyen sigara varsa** (net hesap,
     `gainsBetween`, "Kazandıkların" ile aynı kural; "0" diye bir kart
     göstermeyiz).
  6. Gelecek hafta için bir fikir: en sık nedene göre tek, somut öneri
     ("kahveden sonra gelen bir isteği 10 dakika ertelemeyi dene"; stres →
     nefes molası; neden yoksa en yoğun saat). Öneriler hep uygulamanın
     kendi araçlarına çıkar, sayı içermez.
- Konfeti yok (rapor bir ödül değil, bir ayna); ilk açılışta hafif "ding".
- Kod: `lib/logic/weekly_report.dart` (saf hesaplar),
  `lib/logic/mascot_messages.dart` (`weeklyReportLine`, `weeklyTip`),
  `lib/screens/weekly_report_screen.dart`.
- **Toplanan veri nerede geri dönüyor? (0.8.1 itibarıyla)**

  | Veri | Nerede kullanıcıya döner |
  |---|---|
  | Sigara sayısı/saati | İstatistik (bugün, haftalık karşılaştırma, grafik), ölçüm özeti, haftalık rapor, Bugün'deki maskot cümlesi |
  | Onboarding tahminleri | Ölçüm özetinde ölçülenle yan yana |
  | İşaretlenen nedenler | Ölçüm özeti (1. hafta), haftalık rapor (en sık neden + öneri) |
  | Ruh hali | O günün maskot cümlesi/kutlaması (zor gün → sakin), haftalık rapor (dağılım) |
  | Erteleme, nefes | Profil (toplam ertelenen istek), haftalık rapor, erteleme ekranında Nefes'in cümlesi (kaç isteği atlattın, genelde kaç dakikada geçti) |
  | Kendine not | Erteleme ekranı |

### Özellik 3 — Süreç aşamaları ⏳ Aşama 3
Ölçüm → Farkındalık → Azaltma → Bırakma günü → Sürdürme
- **Ölçüm (1 hafta):** sadece veri toplanır, **hiç mesaj yok**. (Aşama 2'de
  ölçüm haftası sayacı ve görev kısıtı; 0.6.0'da hafta sonu özeti eklendi.)
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

(0.8.0: haftalık rapordaki "Gelecek hafta için bir fikir" bu "somut öneri"
türünün ilk, bildirimsiz hâlidir.)

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
hedefe ilerleme gösterilir (kutlama ekranıyla). Hesap 0.6.0'da hazır:
`computeGains` (`lib/logic/measurement.dart`) parayı her gün **o günün
fiyatıyla** ve net hesaplıyor; kumbara bunun üstüne kurulmalı.

### Özellik 6 — Karakter ⏳ Aşama 6 (Nefes 2.0 ve dolap 0.7.0'da geldi)
- ✅ **Nefes 2.0** (0.7.0): `docs/maskot/1-nefes-2.svg` tasarımının kodla
  çizilmiş birebir hâli (`lib/widgets/mascot_painter.dart`). 4 ruh hali
  (neşeli, kutlama, sakin, düşünceli: sağ üstte üç mavi nokta), başında 4
  aşamada büyüyen filiz, 6 eşya. Nefes egzersizinde gövdesi nefesle hafifçe
  şişip iner ("seninle nefes alıyorum").
- ✅ **Nefes'in dolabı** (0.7.0): kurallar Bölüm 3, madde 10.
- ⏳ Kalan: **enerji** göstergesi azaltmaya, **sağlık** göstergesi **sadece
  sigarasız süreye** bağlı; maskot **asla ölmez**. Göstergeler düşük olsa
  bile maskot üzgün/hasta çizilmez, filiz küçülmez; "dinleniyor" gibi nötr
  bir hâl alır (ör. sakin mod).

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
│   ├── pack_price.dart        Tarihli paket fiyatı (PackPrice, PriceHistory)
│   ├── mascot_look.dart       Maskotun görünüşü (filiz aşaması, eşyalar)
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
│   ├── stats.dart             Sayılar, para, yaşam tahmini sabiti
│   ├── measurement.dart       Ölçüm haftası özeti + "Kazandıkların"
│   ├── weekly_report.dart     Haftalık rapor (haftalar, rapor hesabı)
│   ├── quests.dart            Günlük görevler, ölçüm haftası
│   ├── rewards.dart           XP ödülleri, seri (dinlenme günü dahil)
│   ├── wardrobe.dart          Nefes'in dolabı: eşya açılma, filiz aşaması
│   └── mascot_messages.dart   Maskotun cümleleri (ana ekran, haftalık rapor)
├── utils/format.dart          Türkçe tarih/para/süre yazımı
├── screens/
│   ├── onboarding_screen.dart Tek soru = tek ekran
│   ├── main_screen.dart       Alt menü + 3 sekme
│   ├── today_tab.dart         Bugün: maskot, görevler, erteleme
│   ├── stats_tab.dart         İstatistik: sayılar, grafik, maliyet
│   ├── profile_tab.dart       Profil: seri, puan, dolap kartı, başarılar
│   ├── delay_screen.dart      10 dk erteleme
│   ├── breathing_screen.dart  1 dk nefes egzersizi
│   ├── celebration_screen.dart Konfetili kutlama
│   ├── measurement_summary_screen.dart "Ölçüm haftan bitti!" özeti
│   ├── weekly_report_screen.dart Haftalık rapor
│   ├── wardrobe_screen.dart   Nefes'in dolabı (Profil'den açılır)
│   └── settings_screen.dart   Demo, gizlilik, kaynaklar
└── widgets/
    ├── chunky.dart            Tok buton, kart, ilerleme çubuğu, sayaç
    ├── mascot.dart            Maskot "Nefes" + MascotAppearance + konuşma balonu
    ├── mascot_painter.dart    Nefes 2.0 çizimi (SVG'nin birebir kod hâli)
    ├── svg_path.dart          SVG "d" yazısını Path'e çeviren küçük okuyucu
    ├── confetti.dart          Konfeti animasyonu
    ├── pickers.dart           Ruh hali ve "neden?" pencereleri
    ├── price_sheet.dart       "Paket fiyatı" penceresi (fiyatın tek yeri)
    ├── reason_note.dart       "Kendine bir not" penceresi + kartı
    ├── onboarding_inputs.dart Seçenek kutuları, sayı seçici, ölçek
    ├── change_chip.dart       Fark rozeti ("2 az" nane / "3 fazla" nötr)
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
  sonu geç uyanma ve akşam artışı, en az 20 dk ara. Ölçüm haftasından
  sonra demo kullanıcısı yavaşça azaltır (ilk gün %5, her gün +%2, en fazla
  %30; `demoReduction`) ki "Kazandıkların" sunumda dolu görünsün; bu sahte
  bir demodur, gerçek kullanıcı hakkında iddia değildir. "Demo verisi üret"
  ayrıca geçmiş günler için ruh hali, nedenler, nefes, erteleme ve XP üretir
  (bugün boş kalır; 10. gün bilerek boş: dinlenme gününü gösterir).
- **"Bir günlük veri ekle"** (0.8.0, `addDemoDay`): gerçek saat ileri
  alınamadığı için her kayıt (sigaralar, ruh hali, ertelemeler, puanlar,
  fiyatlar, takip başlangıcı) bir gün GERİYE kaydırılır; boşalan son 24 saate
  yeni demo sigaraları eklenir (yeni tohumla, yoksa her gün aynı saatler
  tekrar ederdi). Dün hiç görev yapılmadıysa demo kullanıcısı yapar. Geçmiş
  sadece kayar, değişmez; görülen özet/raporlar görülmüş kalır. Böylece
  ölçüm haftası ve haftalık raporlar gün gün izlenebilir. Ayarlar'da "Şu an
  takibin N. günü (M. hafta)" yazar.
- **Kayıt:** `shared_preferences` (Android/iOS yerel dosya, web'de
  localStorage). Anahtarlar: `profile`, `onboarding_done`, `events`,
  `activity`, `tracking_started_at`, `demo_last_sync`, `demo_seed`,
  `sound_on`, `haptics_on`, `prices`, `price_confirmed_at`,
  `measurement_summary_seen`, `mascot_outfit`, `weekly_report_seen`.
  - Taşıma: 0.3.0 ve öncesinde fiyat profilin içindeydi (`packPrice`,
    `cigarettesPerPack`). Açılışta bir kez, takip başlangıcından geçerli tek
    bir fiyata taşınır ve profilden silinir.
  - 0.6.0: Profil açılışta yeniden kaydedilir; artık sorulmayan eski
    cevaplar (yaş, cinsiyet, kaç yıldır, hedef, bırakma isteği, motivasyon,
    aktiviteler) böylece kayıttan silinir.
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
- `UserProfile` (hepsi isteğe bağlı): `cigarettesPerDay`, `firstCigarette`
  (4 seçenek), `triggers`, `reasonNote` (kendine not, ≤140 harf).
- `ActivityLog { moods[], delays[], breaths[], xp[], activeDelayStart? }`
  - `MoodEntry { time, mood }` (Çok zor / Zor / İdare eder / İyi / Harika;
    ekranda bu sırayla soldan sağa)
  - `DelayAttempt { start, end, outcome: success | gaveIn }`
  - `XpEntry { time, amount, reason }` — XP'nin "defteri"; toplam ve seri
    buradan hesaplanır.
- `PriceHistory { entries: PackPrice { since, price, perPack (vars. 20) } }`
  — `at(zaman)` o andaki geçerli fiyatı verir.
- `tracking_started_at`: ölçüm haftasının başlangıcı (onboarding bitince).
- `measurement_summary_seen`: "Ölçüm haftan bitti!" özeti görüldü mü.
- `weekly_report_seen`: en son görülen haftalık raporun hafta numarası
  (0 = hiç). Raporların kendisi saklanmaz, her seferinde kayıtlardan
  hesaplanır.
- `mascot_outfit`: takılı eşyaların adları (`Accessory`: gozluk, atki, kep,
  kulaklik, tac, bere). Açılan eşyalar ve filiz aşaması **saklanmaz**, her
  seferinde toplam puan / en uzun seri / ölçüm haftasından hesaplanır
  (`MascotLook { stage, accessories }`).

## 7. Ekranlar (Aşama 2 itibarıyla)

- **Onboarding:** Karşılama ("Merhaba! Ben Nefes.") → 4 tek-soruluk ekran
  → konfetili "Hazırsın!". Sağ üstte "ATLA" (o ana kadarki cevaplar
  kaydedilir). Profil/Ayarlar'dan düzenleme modunda tekrar açılır;
  düzenleme modunda paket fiyatı sorusu YOKTUR (fiyatın kendi yeri var).
- **Bugün:** ölçüm rozeti + seri; demo uyarısı (+1 sigara); maskot
  cümlesi (+ hafta bitince "SONUÇLARIMI GÖR", sonraki haftalarda "RAPORUMU
  GÖR"); "CANIM SİGARA İSTİYOR";
  günlük görevler; bugünkü sigaralar ve "Neden?" etiketleri.
- **İstatistik:** bugün kartı, haftalık karşılaştırma (2 haftalık kayıt
  varsa), son 7 gün grafiği, "Haftalık raporların" (ölçüm haftasından
  sonra), "Kazandıkların" (ölçüm haftasından sonra),
  "Para": paket fiyatı kartı (DEĞİŞTİR → fiyat penceresi, fiyat geçmişi),
  dönem seçici, harcanan para.
- **Profil:** maskot, seri, "Nefes'in dolabı" kartı (sonraki eşyaya
  ilerleme), en uzun seri, toplam puan, ertelenen istekler,
  "Seri nasıl işler?", bilgilerimi düzenle, ayarlar.
- **Nefes'in dolabı:** büyük maskot önizlemesi, filizin aşaması ve sonraki
  aşamaya ilerleme, 6 eşya (açık olana dokun → tak/çıkar; kilitli olan soluk
  görünür ve ne zaman açılacağını yazar), "puan harcanmaz" notu.
- **Erteleme / Nefes / Kutlama / Ölçüm haftası özeti / Haftalık rapor:**
  tam ekran akışlar.
  Kutlamada yeni eşya ve filizin büyümesi haber verilir.
  Erteleme ekranında kendine not (varsa sayacın altında, yoksa en altta
  öneri).
- **Ayarlar:** kılıf durumu, demo verisi üret / bir günlük veri ekle /
  simüle et / sıfırla, bilgilerim
  (düzenle, kendime notum, paket fiyatı), gizlilik + tüm verilerimi sil,
  kaynaklar, hakkında.

## 8. Görsel dil

- **Renk teması "Nane"** (`AppColors`, `lib/theme.dart`): Duolingo'yu
  *andırsın* ama aynısı olmasın diye kendi paletimiz var.
  - `mint` (nane/turkuaz): ana renk — ilerleme, ana butonlar
    (`mintButton`, beyaz yazı okunsun diye biraz koyu), maskotun gövdesi.
  - `blue`: ikinci renk — seçim, erteleme, bilgi.
  - `leaf` (yaprak yeşili): sadece büyümeyi anlatan yerlerde — seri,
    maskotun başındaki filiz.
  - `gold` (XP), `purple` (rozet, neden etiketleri), `red` (sadece silme).
  - Açık temada zemin çok hafif nane tonlu, kartlar beyaz; koyu temada
    lacivert zemin.
  - **Neden nane?** Yeşil ile mavinin ortası; temiz havayı, maskot
    "Nefes"i ve söndürülmüş ateşi ("Unlit" = yanmayan) anlatır. Turuncu/
    mercan gibi sıcak renkler ateş ve kor çağrıştırdığı için ana renk
    yapılmadı.
- **Duolingo'dan bilerek farklı tuttuklarımız:** limon yeşili yerine nane,
  yeşil maskot yerine nane renkli maskot (yeşil filizli), alev yerine
  yaprak seri ikonu (`streakIcon`), alt menüde mavi çerçeveli kare yerine
  yumuşak nane kapsül, bembeyaz yerine hafif tonlu zemin, kendi koyu
  temamız. Tok butonlar, Nunito, konfeti ve konuşan maskot "Duolingo
  havası" için korundu.
- **Butonlar:** `ChunkyButton` — 4 px'lik koyu alt kenar; basınca iner.
  Yazılar BÜYÜK HARFLE ve elle yazılır (`toUpperCase()` Türkçe "i"yi bozar).
- **Kartlar:** `ChunkyCard` — 2 px gri çerçeve + 3 px alt kenar.
- **Erişilebilirlik:** Butonlarda beyaz yazı/nane zemin kontrastı ~3,5:1
  (kalın, büyük yazı); gri yardımcı yazılar zeminde ~4,7:1. Büyük yazı boyutunda (%130) ve dar ekranda (360 px)
  tüm sekmelerde, onboarding'de, kutlama ve erteleme ekranlarında taşma
  olmadığı testle kontrol ediliyor. "Animasyonları azalt" açıksa konfeti gösterilmez.

## 9. Kaynaklar ve kaynaklı bilgiler

| Bilgi | Kaynak | Kullanıldığı yer |
|---|---|---|
| Sigara başına yaşam süresi: erkek ~17 dk, kadın ~22 dk, ort. ~20 dk | Jackson SE, Jarvis MJ, West R. "The price of a cigarette: 20 minutes of life?" *Addiction*, 2024 (UCL). doi:10.1111/add.16757 | İstatistik → "Kazandıkların": içilmeyen sigara × 20 dk (genel ortalama; cinsiyet sorulmuyor) |
| Uyanınca ilk sigara süresi (bağımlılık göstergesi) | Heatherton TF ve ark. "The Fagerström Test for Nicotine Dependence", *Br J Addict*, 1991 | Onboarding, demo |
| Perhiz ihlali etkisi (seri tasarımının gerekçesi) | Marlatt GA, Gordon JR. *Relapse Prevention*, Guilford Press, 1985 | Tasarım kararı (ekranda sayı yok) |
| Korku/tehdit mesajları ancak kişi "değiştirebilirim" diye hissederse işe yarar; yoksa kaçınma/savunma | Witte K. "Putting the fear back into fear appeals: The extended parallel process model." *Communication Monographs*, 1992; Peters GJY, Ruiter RAC, Kok G. "Threatening communication: a critical re-analysis and a revised meta-analytic test of fear appeal theory." *Health Psychology Review*, 2013 | Tasarım kararı: "kaybedilen yaşam" kartı kaldırıldı (ekranda sayı yok) |
| İnsanlar kötü hissettiren ilerleme bilgisine bakmaktan kaçınabilir ("devekuşu sorunu") | Webb TL, Chang BPI, Benn Y. "'The Ostrich Problem': Motivated avoidance or rejection of information about goal progress." *Social and Personality Psychology Compass*, 2013 | Tasarım kararı: kayıp yerine kazanım çerçevesi (ekranda sayı yok) |
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
| 2+ | Sadeleştirme: 4 soruluk onboarding, ölçüm haftası özeti, "Kazandıkların", kendine not, tekrarların temizlenmesi (Özellik 1, 2, 2c) | ✅ Tamamlandı (10.10.2026, 0.6.0) |
| 2++ | Nefes 2.0 (yeni maskot, büyüyen filiz) + Nefes'in dolabı (Özellik 6'nın bir kısmı) | ✅ Tamamlandı (11.10.2026, 0.7.0) |
| 2+++ | Haftalık rapor + "bir günlük veri ekle" demo seçeneği (Özellik 2d) | ✅ Tamamlandı (11.10.2026, 0.8.0) |
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
- [x] Erteleme (10 dk), nefes egzersizi (1 dk), ruh hali seçimi,
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
- [x] Tarihli paket fiyatı: fiyat kartı + pencere, fiyat geçmişi, "yanlış
      girmiştim", 90 günde bir "hâlâ aynı mı?", onboarding'de sadece fiyat
      (paket varsayılan 20), eski sürümden otomatik taşıma

### Sadeleştirme (0.6.0) ✅
- [x] Onboarding 11 → 4 soru; "Neden soruyoruz?" metinleri gerçekte
      yapılanla eşleşti; kullanılmayan eski cevaplar kayıttan silinir
- [x] Tetikleyiciler "Neden?" penceresinde en başta
- [x] Kendine not (erteleme ekranı + Ayarlar), emoji süzgeci
- [x] "Bugün": ikinci ruh hali kartı, görev ilerleme çubukları ve üst
      çubuktaki XP kaldırıldı; "check-in" → "Kendini dinle", XP → puan
- [x] Ruh hali sırası soldan sağa olumsuzdan olumluya (Harika en sağda)
- [x] İstatistik: tek seçici; saatlik grafik, "kaybedilen yaşam" ve
      "sigaraya giden süre" kaldırıldı; haftalık kart 2 haftalık kayıtla
- [x] Ölçüm haftası özeti + "Kazandıkların" (net, o günün fiyatıyla,
      bugün hariç); kademeli açılım
- [x] Demo kullanıcısı ölçüm haftasından sonra yavaşça azaltır
- [x] Testler (ölçüm/kazanç hesapları, demo azaltma, yeni akışlar);
      web'de dış istek yok (Playwright ile kontrol edildi)

### Haftalık rapor (0.8.0) ✅
- [x] Takipten sayılan haftalar; sadece biten haftalar raporlanır
- [x] Rapor: maskot cümlesi, sigara (önceki hafta + grafik), örüntü, kendine
      iyi baktığın anlar (ruh hali dağılımı dahil), haftanın kazancı (varsa),
      gelecek hafta için bir fikir
- [x] Bugün'de "RAPORUMU GÖR" (sadece en son hafta, bir kez); İstatistik'te
      "Haftalık raporların" listesi (1. hafta = ölçüm özeti)
- [x] Demo: "Bir günlük veri ekle" (her şey bir gün geriye kayar)
- [x] Ortak hesaplar: `summarizePeriod`, `gainsBetween`, `daysBetween`
- [x] Testler (rapor hesabı, maskot cümlesi, öneri, AppState duyuru
      kuralları, demo gün ilerletme, arayüz akışı, büyük yazı boyutu);
      web'de dış istek yok (Playwright ile kontrol edildi)

### Aşama 3 — Süreç aşamaları (sıradaki)
- [ ] Aşama modeli ve kaydı (hangi aşamada, ne zaman başladı)
- [x] Ölçüm haftası bitişi: "Ölçüm haftan bitti!" kutlaması + özet (0.6.0)
- [ ] Ölçüm haftası bitince **hedef** (azaltmak/bırakmak) ve **bırakma
      isteği** (1–10) sorusu: plan kurulurken, cevaplar planı değiştirir
- [ ] Farkındalık ekranı: en yoğun saatler, işaretlenen nedenlerin
      dağılımı, ilk sigara saati ortalaması (sadece kullanıcının verisi;
      özet hesapları `measurement.dart`'ta hazır). Not: haftalık rapor
      (0.8.0) bunun haftalık hâlini zaten gösteriyor; ayrı ekran gerekir mi
      yeniden değerlendirilmeli.
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
- [ ] "Sevdiğin aktiviteler" sorusu (mesajlarda kullanılacağı için burada)
- [ ] Kurallar: günde ≤3, sigaradan hemen sonra suçlama yok, aynı tür üst
      üste yok, hedef aşılınca destek, ölçüm haftasında mesaj yok
- [ ] Yerel bildirimler (mobilde; web'de uygulama içi kart); seri
      hatırlatması suçlamasız
- [ ] Ayarlar: ton seçimi, bildirim saatleri
- [ ] Kuralların birim testleri

### Aşama 5 — Para kumbarası
- [ ] Hedef ödül (ad + tutar), biriken = `computeGains(...).money` (net,
      her gün o günün fiyatıyla; 0.6.0'da hazır)
- [ ] İlerleme çubuğu, hedefe ulaşınca kutlama

### Aşama 6 — Karakter
- [ ] Enerji (azaltma) ve sağlık (sigarasız süre) göstergeleri; maskot
      asla ölmez, üzgün çizilmez
- [x] Maskot seçimi (Nefes 2.0) ve Flutter'a birebir taşıma (SVG ile
      piksel karşılaştırması yapıldı); filizin aşaması sadece toplam puana
      bağlı, asla geri gitmez (test ile) — 0.7.0
- [x] Nefes'in dolabı: eşikle açılan 6 eşya, harcama yok, kutlamada haber,
      Profil'de kart — 0.7.0
- [x] Nefes egzersizinde maskotun gövdesi nefesle şişip iner — 0.7.0

### Aşama 7 — Bluetooth + CSV
- [ ] Firmware ile protokol (yukarıdaki taslak) kesinleştirme
- [ ] `BleDeviceService` (flutter_blue_plus), izinler (Android/iOS),
      eşleştirme ekranı; demo/gerçek seçimi ayarlardan
- [ ] Gerçek kılıfa geçerken demo kayıtlarını silme seçeneği
- [ ] CSV dışa aktarma (paylaş menüsü), anonim katılımcı kodu
- [ ] Not: Web'de Bluetooth sınırlı (iOS Safari'de yok); pilot mobil
      uygulamayla yapılmalı

## 11. Açık sorular / kararlar

- **Karar — fiyat internetten çekilmez:** Resmî, herkese açık bir sigara
  fiyatı API'si bulunamadı (fiyatlar firma grubu bazında, farklı tarihlerde
  haberlerle duyuruluyor). Bir liste tutmak ekibin sürekli güncellemesini
  gerektirir, proje bitince eskir; doğru fiyat için marka sormak gerekir;
  ve uygulamanın "hiç internete çıkmaz" vaadi bozulur. Kullanıcının kendi
  ödediği fiyatı yazması daha doğru ve 3 saniye sürüyor. Bunun yerine
  tarihli fiyat geçmişi + 90 günde bir nazik "hâlâ aynı mı?" sorusu var.

- **Karar — "kaybedilen yaşam süresi" kartı kaldırıldı (0.6.0):** Her
  sigarada büyüyen, hiç iyiye gitmeyen tek sayıydı (günde 15 içen biri
  "30 gün"de ~5–6 gün görüyordu). Oyunlaştırmanın "ceza yok" ilkesiyle
  çelişiyordu; korku mesajları kişi "değiştirebilirim" hissetmezse kaçınma
  yaratabilir (Witte 1992; Peters ve ark. 2013) ve insanlar kötü
  hissettiren bilgiye bakmayı bırakabilir (Webb ve ark. 2013). Stres de
  uygulamanın kendi tetikleyici listesinde. Aynı kaynak (UCL 2024) artık
  "içmediğin sigaralarla korunan süre" olarak, ölçüm haftasından sonra
  gösteriliyor. Kaynaksız "sigaraya giden süre (~6 dk)" varsayımı da
  kaldırıldı (önceki açık soru böylece kapandı).
- **Karar — kazanç NET hesaplanır:** Gün gün "ortalamanın altındaysa ekle"
  toplamı, hiç azaltmayan birinin dalgalanmasını bile kazanç gösterirdi.
  Net hesap daha dürüst; toplam eksiye inmez, bugün sayılmaz (sayı gün
  içinde, sigaradan hemen sonra düşmez). Bir ağır gün sonrası sayı
  azalabilir; bu bilgi verir, suçlamaz (renk nötr, mesaj yok).
- **Karar — kişisel geri bildirim az ve var olan yerlerde (0.8.1):**
  Kişisel geri bildirim yeni kartlarla değil, Nefes'in zaten söylediği
  cümlelerin içinde verilir; aşırıya kaçarsa arayüz kalabalıklaşır ve
  kullanım zorlaşır. İlk adım erteleme ekranıdır (isteğin en zor anı;
  bkz. Bölüm 3, madde 5). Değerlendirilip **şimdilik yapılmayanlar:**
  - *Geçen haftanın fikrini takip etmek* ("kahve sonrası ertelemeyi
    önermiştim…"): ertelemelerde neden kaydı yok, bu yüzden çoğu fikir
    ölçülemiyor; ölçülebilenler raporda zaten olan sayıları tekrar ederdi.
  - *Ruh hali ile sigara ilişkisi:* ruh hali günde bir kez ve isteğe bağlı
    giriliyor; az veride sahte örüntü çıkar ve "kötü günde fazla içtin"
    suçlama gibi okunabilir.
  - *Kişisel rekorlar* ("ilk sigaran hiç bu kadar geç olmamıştı"): olabilir,
    ama sadece Bugün'deki maskot cümlesi olarak ve ertesi gün (sigaradan
    hemen sonra kutlama/mesaj yok kuralı).
  - *Riskli saat kartı* ("genelde 15:00'te zorlanıyorsun"): Aşama 4 ile;
    sigarayı hatırlatıp isteği tetikleyebileceği için önce denenmeli.
- **Karar — haftalık rapor var; günlük ve aylık rapor yok (0.8.0):**
  - *Günlük rapor:* Bugün sekmesi ve İstatistik'teki "bugün" kartı zaten
    günün sayılarını gösteriyor; her akşam gelen bir "gün karnesi", ağır bir
    günden sonra her akşam kötü bir not gibi hissettirir (suçlama yok
    ilkesi, perhiz ihlali etkisi). Tek bir gün de çok gürültülü: hafta içi /
    hafta sonu farkı tek başına büyük dalgalanma yaratır.
  - *Aylık rapor:* Şimdilik yok. İlk ay ölçüm haftası + 3 haftadan ibaret ve
    haftalık rapor bunu zaten kapsıyor. Pilot uzarsa (≥ 4–5 haftalık rapor)
    ayrı bir rapor yerine haftalık raporlara "son 4 hafta" eğilim grafiği
    eklenmesi önerilir (aynı veri, tek giriş noktası).
- **Açık soru — ölçüm haftasının ilk günü yarım:** Onboarding gün ortasında
  biterse 1. gün eksik ölçülür; başlangıç noktası (günde ortalama) biraz
  düşük çıkar ve 2. hafta raporu "biraz yoğun" diyebilir. Seçenekler:
  ölçümü ertesi gün 00:00'dan başlatmak ya da ilk günü ortalamaya katmamak.
  Ekip karar vermeli (`summarizeMeasurementWeek` tek yerden değişir).
- **Karar — kullanılmayan sorular kaldırıldı (0.6.0):** Bkz. Özellik 1.
  **Pilot için demografi** (yaş aralığı, cinsiyet, kaç yıldır içtiği)
  gerekiyorsa uygulamada "kişiselleştirme" gibi sorulmamalı: ya pilot onam
  formunda ya da Aşama 7'de CSV ile birlikte, açıkça "araştırma için,
  uygulamayı değiştirmez" diye etiketlenmiş ayrı bir bölümde sorulmalı.
  Ekip ve danışman öğretmen karar vermeli.
- **Açık soru — cinsiyete göre yaşam süresi:** Cinsiyet artık sorulmadığı
  için herkese genel ortalama (20 dk) kullanılıyor (UCL: erkek ~17, kadın
  ~22). Bu bir ortalama tahmin olduğu için yeterli görüldü.
- **Yaş sınırı ve etik:** Uygulama 0.6.0'dan beri yaş sormuyor (önceki yaş
  aralıkları 18+ ile başlıyordu). Uygulama yetişkin sigara içiciler için;
  pilotta reşit olmayan katılımcı olacaksa etik kurul/veli izni gerekir —
  ekip ve danışman öğretmen karar vermeli (yaş kontrolü pilot onam
  formunda yapılabilir).
- **Maskotun adı ve görünüşü:** Şimdilik "Nefes" (`lib/widgets/mascot.dart`
  → `mascotName`). Ekip isterse değiştirebilir. Duolingo'nun adı, logosu
  veya baykuşu kullanılmaz; sadece tarzından ilham alınır.
  **Karar (0.7.0): Nefes 2.0** uygulandı. Diğer öneriler
  ([docs/maskot/](maskot/README.md): Filiz, Balina, Ferah (fil), Kaplumbağa)
  arşivde; Balina ("Mavi Balina" çağrışımı) ve Ferah (hortum → nargile)
  bilerek eklenmedi. Yine de 5–8 yetişkin sigara içiciyle kısa bir "Ciddiye
  alır mısın? Neyi hatırlatıyor?" testi önerilir.
- **Karar — puanla açılan dolap (0.7.0):** Puanlar harcanmaz, eşyalar eşikle
  açılır (kurallar Bölüm 3, madde 10). Para gibi harcamak "XP asla düşmez"
  ilkesini bozardı, "biriktir mi harca mı" kararıyla karmaşıklık eklerdi ve
  uygulamadaki gerçek parayla (harcanan / cebinde kalan) karışırdı. Eşikler
  öneridir; değiştirilirse `lib/logic/wardrobe.dart` ve Bölüm 3 birlikte
  güncellenmeli.
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
| 0.4.0 | Tarihli paket fiyatı | Fiyatın kendi yeri (İstatistik'te kart + pencere, Ayarlar'da kısayol), her sigara kendi tarihindeki fiyatla hesaplanır, fiyat geçmişi, "yanlış girmiştim" düzeltmesi, 90 günde bir "hâlâ aynı mı?", onboarding'de sadece fiyat (paket varsayılan 20), eski sürümden otomatik taşıma; fiyat internetten çekilmez |
| 0.5.0 | Nane teması | Duolingo'nun birebir renkleri yerine kendi paletimiz: nane (turkuaz) ana renk, mavi ikinci renk, yaprak yeşili seri; nane renkli, yeşil filizli maskot; seri ikonu alev yerine yaprak; alt menüde yumuşak kapsül; hafif nane tonlu zemin, lacivert koyu tema; buton kontrastı ~3,2'den ~3,5'e çıktı |
| 0.6.0 | Sade ve kişisel | Onboarding 11 → 4 soru (her cevap bir şeyi değiştirir; kullanılmayan eski cevaplar silinir), tetikleyiciler "Neden?" penceresinde başta, erteleme ekranında "kendine not", ölçüm haftası bitince özet ekranı ve kademeli açılım, "kaybedilen yaşam" yerine "Kazandıkların" (içmediğin sigara, cebinde kalan para, korunan yaşam süresi; net hesap), tekrarlar temizlendi (ikinci ruh hali kartı, görev çubukları, iki seçici, üst çubukta XP), ruh hali soldan sağa olumsuzdan olumluya, "XP" → "puan", "check-in" → "Kendini dinle" |
| 0.7.0 | Nefes 2.0 ve dolap | Yeni maskot Nefes 2.0 (SVG tasarımın kodla birebir çizimi): daha ifadeli yüz, düşünürken üç nokta, başında puanla 4 aşamada büyüyen filiz (asla küçülmez); "Nefes'in dolabı": puan harcanmadan eşikle açılan 6 eşya (gözlük, atkı, kep, kulaklık, taç, bere), kutlamada "yeni eşya / filiz büyüdü" haberi, Profil'de sonraki eşyaya ilerleme; ölçüm haftası bitince mezuniyet kepi; nefes egzersizinde maskot da nefes alır; "yavaş ama emin adımlarla" |
| 0.8.0 | Haftalık rapor | Her hafta bitince kısa bir rapor: Nefes'in kişisel cümlesi (önce olumlu olan), bu hafta ve önceki hafta + 7 günün grafiği, örüntün (en yoğun saat, ilk sigara, en sık neden), kendine iyi baktığın anlar (görev günleri, ertelemeler, nefes, puan, ruh hali dağılımı), varsa haftanın kazancı ve en sık nedene göre "gelecek hafta için bir fikir"; Bugün'de bir kez "RAPORUMU GÖR", İstatistik'te "Haftalık raporların" listesi (1. hafta = ölçüm özeti); demo'ya "Bir günlük veri ekle" (sanki bir gün geçmiş gibi, ölçüm haftasını ve raporları gün gün izlemek için); onboarding'de yazı tipinde olmayan "→" karakteri kaldırıldı |
| 0.8.1 | Kendi başarın | Erteleme ekranında Nefes, daha önce atlattığın istekleri senin verinle hatırlatır ("Daha önce 6 isteği atlattın; istekler genelde 7 dakika içinde geçti."); sadece başarılı ertelemeler sayılır, yeni kart eklenmedi; demo ertelemeleri artık 4–10 dakikada geçebiliyor |
