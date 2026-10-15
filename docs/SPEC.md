# Unlit — Proje Şartnamesi (SPEC)

> Bu dosya projenin "tek doğru kaynağı"dır. Yeni bir oturuma/ekip üyesine
> bağlam vermek için buradan başlayın. **Her aşama bitince "Aşama planı ve
> durum" ile "Sürüm geçmişi" bölümlerini güncelleyin.**

Son güncelleme: 15 Ekim 2026 — Aşama 2 (Duolingo tarzı tasarım ve
oyunlaştırma), ses/titreşim efektleri, tarihli paket fiyatı, kendi renk
teması ("Nane"), sadeleştirme (0.6.0: 4 soruluk onboarding, ölçüm haftası
özeti, "Kazandıkların"), Nefes 2.0 + "Nefes'in dolabı" (0.7.0) ve haftalık
rapor + "bir günlük veri ekle" demo seçeneği (0.8.0), erteleme
ekranında kişisel cümle (0.8.1), azaltma hedefi + "Hedefim" sayfası
(0.9.0), Bugün'de "Son sigarandan beri" sayacı (0.10.0), "Başladığından
beri" kartı + elle düzeltme + kaynaklı sayılar (0.11.0) ve bırakma günü +
7 tam günlük ölçüm haftası (hazırlık günü) (0.12.0) tamamlandı.

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
   | İlk azaltma hedefini seçmek (bir kez; değiştirmek puan vermez) | +10 |
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
12. **Azaltma hedefi ceza vermez** (0.9.0, `lib/logic/goal.dart`; ayrıntı
   Özellik 2e): günlük sınırın üstüne çıkmak puan götürmez, seriyi bozmaz,
   mesaj ya da ses tetiklemez, kırmızı gösterilmez (haftalık şeritte nötr
   gri). "Hedefinde kaldığın gün" sayısı sadece artar. Nefes sınırı aşılan
   günlerden hiç bahsetmez; süre dolduysa suçlamadan yeni bir süre önerir.
   Hedef her an değiştirilebilir.
   **Bırakma günü de ceza vermez** (0.12.0; Özellik 2i): bırakma gününden
   sonra sigara içilen gün şeritte nötr gri; "sigarasız gün" sayısı sadece
   artar (sigara içilen gün sayıyı düşürmez, sadece eklenmez). Sigarasız
   güne puan/rozet yok (aynı gerekçe: perhiz ihlali etkisi). Kayma olursa
   Nefes "Kaldığın yerden devam" der; asla "baştan başla" demez.
13. **"Son sigarandan beri" sayacı bir seri değildir** (0.10.0; ayrıntı
   Özellik 2f): yeni sigara gelince **sessizce** sıfırdan başlar: mesaj,
   ses, titreşim, renk değişimi yok. Puan vermez, rekor ("en uzun ara")
   tutmaz, kutlama tetiklemez; filiz ve dolap ona bağlı değildir.
14. **Elle düzeltme bir ölçüm düzeltmesidir** (0.11.0; Özellik 2h): elle
   sigara eklemek ya da "Bu sigarayı ben içmedim" ile silmek puan
   götürmez/getirmez, ses, titreşim, kutlama tetiklemez (sadece kısa bir
   "Kaydedildi" / "Kayıt silindi" yazısı). Silinen kaydın daha önce
   kazandırdığı puan geri alınmaz (puan asla düşmez).

## 4. Özellikler (tam vizyon)

### Özellik 1 — Onboarding ✅ (Aşama 1; Aşama 2'de yenilendi; 0.6.0'da 4 soruya indi; 0.11.0'da 5)
- En üstte: **"Bilgilerin sadece bu telefonda kalır, kimseyle paylaşılmaz."**
- Her ekranda tek soru; maskot soruyu sorar; **"Neden soruyoruz?"**
  açıklaması; cevap yoksa buton "ŞİMDİLİK GEÇ", varsa "DEVAM".
- İlke: **"Sorulan her soru bir söz."** Bir soru ancak cevabı uygulamada
  gerçekten bir şeyi değiştiriyorsa sorulur ve saklanır; "Neden
  soruyoruz?" metni tam olarak bunu söyler. Soru, cevabın kullanılacağı
  ana konur ("tam zamanında").
- **Sorulan 5 soru ve nerede kullanıldıkları:**

  | Soru | Nerede kullanılıyor |
  |---|---|
  | Günde kaç sigara (tahmin) | Ölçüm haftası özetinde kılıfın saydığıyla yan yana; demo verisi buna yakın |
  | Uyanınca ilk sigara (Fagerström 1. soru) | Ölçüm haftası özetinde, ölçülen ilk sigara saatinin yanında; demo verisi; Aşama 3'te sabah hedefi |
  | Kılıfın göremeyeceği sigaralar olur mu? (0.11.0) | "Evet" ise Bugün'de **ELLE SİGARA EKLE** butonu (Özellik 2h) |
  | Paket fiyatı (+ paketteki adet) | Harcanan para, cebinde kalan para |
  | Tetikleyiciler | "Bu sigara neden?" penceresinde seçilenler en başta (tek dokunuş) |

- **Kılıf zaten ölçüyorsa "günde kaç" neden soruluyor?** (0.11.0'da
  tartışıldı, kaldı.) Bu soru ölçmek için değil: (1) **Tahmin ancak
  ölçümden ÖNCE sorulabilir**; sonra sorulursa kullanıcı sayıyı görmüş
  olur. (2) İnsanlar sigara sayısını yuvarlak sayılarla (10, 20)
  hatırlar; anlık kayıt bu yanılgıyı yapmaz (Shiffman 2009). Tahmin ile
  ölçülen arasındaki fark hem kullanıcı için bir farkındalık anı hem de
  pilot için hazır bir araştırma sorusudur ("Katılımcıların tahmini,
  kılıfın ölçümünden ne kadar farklı?"). (3) "Uyanınca ilk sigara" ile
  birlikte **Sigara İçme Ağırlığı İndeksi'nin** (HSI, Heatherton 1989)
  iki sorusudur; pilot raporunda katılımcıların bağımlılık düzeyi bu iki
  cevaptan hesaplanabilir (uygulama içinde hesaplanıp gösterilmez).
  "Neden soruyoruz?" metni artık demo verisinden bahsetmez (gerçek
  kullanıcı için gerekçe değil).
- **"Uyanınca ilk sigara" kılıfla ölçülemez:** kılıf saati bilir ama
  kişinin ne zaman uyandığını bilemez. "Neden soruyoruz?" metni bunu
  söyler.
- **Kılıfın göremeyeceği sigaralar** (0.11.0): Kılıf sadece takılı olduğu
  paketten alınan sigaraları sayar; başkasının paketinden, ikinci bir
  paketten ya da sarma içilenler eksik kalır. Cevap "Evet" ise Bugün'de
  elle ekleme butonu çıkar (cevap gerçekten bir şeyi değiştiriyor).
  Nargile ve e-sigara bilerek kapsam dışı: bir nargile ya da e-sigara
  oturumu "1 sigara" sayılamaz.

- **Kaldırılan sorular ve ne zaman sorulacakları** (0.6.0'a kadar
  soruluyordu ama hiçbir yerde kullanılmıyordu; eski cevaplar açılışta
  kayıttan silinir):

  | Soru | Karar |
  |---|---|
  | Hedef (azaltmak/bırakmak) | **0.9.0'da geldi:** ölçüm haftası özetinin sonunda (yüzde + süre; bkz. Özellik 2e) |
  | Bırakma isteği 1–10 | Sorulmuyor: cevabı uygulamada hiçbir şeyi değiştirmiyor |
  | Sevilen aktiviteler | Aşama 4'te, mesaj motoru ("Yarın koşacaksan…") gelince |
  | Motivasyon (çocuk, eş…) | Hazır seçenek yerine **kendine not** (aşağıda) |
  | Kaç yıldır, yaş aralığı, cinsiyet | Uygulamada dürüst bir kullanımı yok (tek kullanımı "paket-yıl" gibi bir risk sayısı göstermek olurdu; korkutma kuralına aykırı). Pilot anketinde sorulur: bkz. Bölüm 11 → "Pilot anketi" |
  | Daha önce bırakmayı denedin mi? | Pilot anketinde. Uygulamada belki Aşama 3'te (hedef/bırakma günü seçerken, olumlu dille: "Daha önce 3 ay bırakmıştın"); başarısızlık hatırlatmamalı |
  | Uyku/uyanma saati | Aşama 4'te, bildirimlerin "rahatsız etme" saatleri için |

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
- Bugünkü sigara sayısı (+ bugünkü ilk sigara saati). Son sigaradan geçen
  süre 0.10.0'dan beri burada değil, Bugün sekmesindeki sayaçta (Özellik
  2f; aynı bilgi iki yerde olmasın).
- Geçen haftayla karşılaştırma:
  - Bugün ↔ geçen haftanın aynı günü, **aynı saate kadar** (bugün kartında)
  - Yeterli kayıt yoksa karşılaştırma gösterilmez (yanıltmasın diye).
  - "Son 7 gün ↔ önceki 7 gün" kartı **0.11.0'da kaldırıldı**: yerine en
    üstte "Başladığından beri" kartı var (Özellik 2g); haftadan haftaya
    fark haftalık raporda.
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
  - **Korunan yaşam süresi** (0.11.0'da değişti) = **sadece sigarasız
    günler** için: her sigarasız (tamamlanmış) gün × başlangıç noktası ×
    ~20 dk (UCL 2024, genel ortalama). Azaltılan günler sayılmaz, çünkü
    sağlığa etkisi sigara sayısıyla orantılı değil (Hackshaw 2018; gerekçe
    Bölüm 11). Henüz sigarasız gün yoksa kart yerine "Korunan yaşam süresi
    nasıl hesaplanır?" bağlantısı durur ("0 dk" kartı göstermeyiz).
    **"Ortalama tahmin"** olduğu ve kaynağı açıkça yazar; (i) penceresi
    hesabı ve nedenini anlatır. Haftalık rapordaki kazanç kartında da aynı
    kural.
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
- **Ölçüm haftası 7 TAM gündür** (0.12.0, `trackingStartFor`): onboarding
  gün ortasında biterse o gün **hazırlık günü** olur, ölçüm ertesi gün
  00:00'da başlar. Gece 04:00'ten önce bittiyse (gün henüz başlamadı;
  `dayStartsAtHour`) ölçüm aynı gün başlar. Neden? Yarım ilk gün başlangıç
  noktasını olduğundan düşük, günün ilk sigarasını da olduğundan geç
  gösterirdi (öğleden sonra başlayan birinin "ilk sigarası" 15:00
  görünürdü). Hazırlık gününde: rozet "Ölçüm yarın başlıyor", Nefes
  "Bugün kılıfını tanı", görevler ölçüm haftasınınki gibi (azaltma görevi
  yok), sigaralar kaydedilir ve Bugün/İstatistik'te görünür ama başlangıç
  noktasına, haftalık raporlara ve "Başladığından beri"ye girmez. Takip
  sıfırlanınca da aynı kural. Demo verisi gece yarısından başladığı için
  hazırlık günü yoktur.
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
  | Sigara sayısı/saati | İstatistik ("Başladığından beri", bugün, grafik), ölçüm özeti, haftalık rapor, Bugün'deki maskot cümlesi ve "Son sigarandan beri" sayacı (0.10.0) |
  | Onboarding tahminleri | Ölçüm özetinde ölçülenle yan yana |
  | "Kılıfın göremeyeceği sigaralar" (0.11.0) | Bugün'de "ELLE SİGARA EKLE" butonu |
  | İşaretlenen nedenler | Ölçüm özeti (1. hafta), haftalık rapor (en sık neden + öneri) |
  | Ruh hali | O günün maskot cümlesi/kutlaması (zor gün → sakin), haftalık rapor (dağılım) |
  | Erteleme, nefes | Profil (toplam ertelenen istek), haftalık rapor, erteleme ekranında Nefes'in cümlesi (kaç isteği atlattın, genelde kaç dakikada geçti) |
  | Kendine not | Erteleme ekranı (hedef seçerken de yazılabilir; aynı not) |
  | Azaltma hedefi (0.9.0) | Bugün'deki "Hedefim" kartı, Hedefim sayfası (haftalık sınır, ilerleme, hedefinde kaldığın günler) |
  | Bırakma günü ve yolu (0.12.0) | Hedefim kartı ve sayfası (geri sayım, sınırlar, sigarasız gün), Bugün'de Nefes'in bir gün önceki ve bırakma günündeki cümlesi |

### Özellik 2e — Azaltma hedefi ve "Hedefim" sayfası ✅ (0.9.0)
- **Ne zaman sorulur?** Ölçüm haftası özetinin sonunda (ilk seferde):
  **HEDEFİMİ SEÇ** ya da **ŞİMDİLİK GEÇ**. Geçen kullanıcı için Bugün'de
  küçük bir "Bir hedef seç" kartı durur. Soru, cevabın kullanılacağı ana
  (başlangıç noktası belli olduğunda) konur.
- **Akış** (Duolingo'daki hedef seçimi gibi, her ekranda tek soru):
  1. *Ne kadar?* %25 / %50 / %75 azaltmak ya da bırakmak; her seçeneğin
     yanında günlük karşılığı ("günde 9"). "Neden soruyoruz?" açıklaması
     var.
  2. *Ne kadar sürede?* Sayı (– / +) ve yanında **Hafta / Ay** seçimi
     (hafta 1–12, ay 1–6). Altında **zorluk**: 4 çubuk + etiket (Rahat /
     Dengeli / İddialı / Çok iddialı), somut anlamı ("Her hafta günde
     yaklaşık 2 sigara azaltmak demek") ve bitiş günü. Önerilen süre her
     yüzdede "Dengeli" (%25 → 2, %50 → 4, %75 → 6, %100 → 8 hafta).
  3. *Kendine not* — sadece daha önce yazılmadıysa ve isteğe bağlı. Yeni
     bir not türü değil: erteleme ekranındaki "Kendine not"un aynısı.
     Hedef koyarken "neden?" diye düşünmek için en doğal an olduğu için
     burada da soruluyor.
  Sonunda "Hedefin hazır!" kutlaması (ilk hedefte bir kez +10 puan).
  **Bırakmak** seçilirse 2. adım süre değil **bırakma günü** ve **yol**
  (0.12.0; bkz. Özellik 2i).
- **Hesap** (`lib/logic/goal.dart`, saf ve testli):
  - Hedef = başlangıç noktası (ölçüm haftasında günde ortalama) × kalan
    yüzde, yuvarlanır. Yüzde hep başlangıç noktasına göredir.
  - Azaltma **hafta hafta**: her haftanın bir günlük sınırı var. Sınırlar,
    hedef konduğundaki seviyeden (son 7 tamamlanmış günün ortalaması) eşit
    adımlarla iner, son hafta hedefe eşittir (yukarı yuvarlanır, rahat
    başlar). "Ay" takvim ayıdır; tam haftaya bölünmeyen birkaç gün son
    haftaya eklenir.
  - **Şimdi** = son 7 tamamlanmış günün ortalaması (bugün sayılmaz;
    sayı sigaradan hemen sonra değişmez). **İlerleme** = başlangıçtan
    hedefe yolun yürünen kısmı (0–100 %, eksiye inmez).
  - **Zorluk** = haftada başlangıcın yüzde kaçı kadar azaltılacağı: ≤ %10
    Rahat, ≤ %20 Dengeli, ≤ %35 İddialı, üstü Çok iddialı. Bu eşikler
    **ekibin varsayımıdır**, kaynaklı değildir; ekranda sayı olarak
    gösterilmez, sadece etiketi seçer. Kırmızı yok: zorluk uyarı değil,
    bilgi. "Çok iddialı"da "Zorlanırsan süreyi sonra uzatabilirsin" yazar.
- **Hedefim sayfası** (tek giriş noktası: Bugün'deki "Hedefim" kartı;
  kartta bu haftanın sınırı ve ilerleme çubuğu). Tek ekrana sığacak kadar
  sade:
  1. Nefes'in cümlesi (`goalLine`): önce olumlu olan (hedefe ulaştın →
     yolun yarısı → ilerliyorsun); süre dolduysa suçlamadan yeni süre önerisi.
  2. Yol kartı: "%50 azaltmak · 4 hafta · Bitiş", ilerleme çubuğu,
     Başlangıç / Şimdi / Hedef.
  3. Bu hafta: "Günde en fazla 12 sigara" ve 7 günlük şerit (hedefinde
     kalınan gün nane renkli + onay; diğerleri nötr gri; bugün mavi
     çerçevede bugünkü sayı; gelecek günler boş) + "Hedefinde kaldığın gün".
  4. Bırakma hedefinde: ALO 171 ve MHRS'den sigara bırakma polikliniği
     bilgisi (T.C. Sağlık Bakanlığı).
  5. HEDEFİ DEĞİŞTİR (süre dolduysa YENİ HEDEF SEÇ).
  6. Azaltma hedefi **tamamlanınca ya da süresi dolunca** (0.12.0): "Bir
     sonraki adım: bırakma günü" kartı ve **BIRAKMA GÜNÜ SEÇ** (akış
     "Bırakmak" seçili açılır). Açılır pencere ya da bildirim değil; seçmek
     isteğe bağlı. Gerekçe: azaltma son durak olmasın (Bölüm 11 →
     "azaltarak mı, birden mi").
- Takip baştan başlarsa (demo verisi üret, kayıtları sıfırla) hedef silinir
  (başlangıç noktası değişti). Demo'daki "bir gün ekle" hedefi de bir gün
  geriye kaydırır.
- Kod: `lib/models/goal.dart`, `lib/logic/goal.dart`,
  `lib/screens/goal_setup_screen.dart`, `lib/screens/goal_screen.dart`.

### Özellik 2i — Bırakma günü ✅ (0.12.0)
- **Nerede?** Hedef seçme akışında "Bırakmak" seçilince (ölçüm özetinden,
  Bugün'deki "Bir hedef seç" kartından, HEDEFİ DEĞİŞTİR'den ya da azaltma
  hedefi bitince Hedefim'deki BIRAKMA GÜNÜ SEÇ'ten). Ayrı bir ekran ya da
  ikinci bir hedef türü değil: bırakma, hedefin bir türü (tek giriş
  noktası).
- **Akış:**
  1. *Bırakma günün ne zaman olsun?* Hızlı seçenekler: Bugün / 1 hafta
     sonra / 2 hafta sonra / 1 ay sonra + **BAŞKA BİR GÜN SEÇ** (takvim,
     bugünden en fazla 6 ay sonrası). **Varsayılan 2 hafta sonra:**
     rehberler bırakma gününü yakın seçmeyi öneriyor (NCI Smokefree: "en
     fazla bir iki hafta sonra"; Quit (quit.org.au): "önümüzdeki iki hafta
     içinde"). 14 günden uzak bir tarihte nötr bir not: "Uzak bir tarih
     kararlılığını azaltabilir… Yine de karar senin."
  2. *Bırakma gününe nasıl gitmek istersin?* **O güne kadar azaltarak**
     (her hafta günlük sınır iner, bırakma gününde 0; seçeneğin altında bu
     haftanın sınırı yazar) ya da **O gün birden** (o güne kadar sınır
     yok). **Hiçbiri önceden seçili değil**, seçmeden ilerlenmez: iki yol
     da geçerli (Cochrane 2019); bir deneyde birden bırakanlar biraz daha
     başarılıydı (Lindson-Hawley 2016). "Neden soruyoruz?" bunu dürüstçe
     söyler. Bırakma günü bugünse bu soru sorulmaz.
  3. Kendine not (daha önce yazılmadıysa).
- **Hesap** (`lib/logic/goal.dart`):
  - Bırakma hedefinde hedef = 0. "Azaltarak": hedef konduğundaki
    seviyeden (son 7 gün) bırakma gününe kadar haftalık eşit adımlarla
    iner; 0'a bırakma GÜNÜNDE ulaşılır (örn. günde 15, 2 hafta: 10 → 5 →
    bırakma günü 0). "Birden": bırakma gününe kadar sınır yok (`null`).
  - Bırakma hedefi "dolmaz": bırakma gününden sonra sınır 0 ve
    **sigarasız gün** sayılır (bırakma gününden sonraki BİTEN günlerden
    hiç sigara olmayanlar; sadece artar).
  - 0.12.0'dan önceki bırakma hedeflerinde bırakma günü yoktu: onlarda
    süre bitişi bırakma günü, yol "azaltarak" sayılır.
- **Gösterim:**
  - Bugün'deki "Hedefim" kartı: "Bırakma gününe 9 gün (· bu hafta günde
    en fazla 10)" → "Yarın bırakma günün" → "Bugün bırakma günün" →
    "Sigarasız gün: 5".
  - Hedefim: yol kartında "O gün birden · Bırakma günü: 29 Ekim Perşembe";
    "birden" yolunda bırakma gününe kadar şerit yerine geri sayım ("9 gün
    kaldı"); bırakma gününden sonra "Sigarasız gün: N" + şerit (sigarasız
    gün nane + onay, diğerleri nötr gri). ALO 171 / MHRS kartı.
  - Nefes (`goalLine`, `mascotGreeting`): geri sayım; bir gün önce "Yarın
    bırakma günün! İstersen bugün evdeki sigaraları, çakmakları ve
    küllükleri kaldır" (NCI Smokefree "Prepare to quit" önerisi); bırakma
    günü "Bugün bırakma günün! … ALO 171 hep burada"; sonra önce olumlu
    olan (son 7 gün sigarasız → "N gün sigarasız geçti") yoksa "Bırakma
    yolu herkes için düz değil. Kaldığın yerden devam".
- **Yok (bilerek):** sigarasız güne puan/rozet, bırakma gününde
  geri sayım bildirimi (Aşama 4), WHO iyileşme takvimi (metin önce
  doğrulanmalı; Aşama 3 Sürdürme).
- Demo'daki "Bir günlük veri ekle" bırakma gününü de bir gün geriye
  kaydırır (yarın bırakacaksan ertesi "gün" bırakma günü olur).
- Kod: `lib/models/goal.dart` (`quitDay`, `QuitMethod`), `lib/logic/goal.dart`
  (`quitDayOf`, `limitOn`, `GoalStatus.daysToQuit` / `smokeFreeDays`),
  `lib/screens/goal_setup_screen.dart`, `lib/screens/goal_screen.dart`.

### Özellik 2f — "Son sigarandan beri" sayacı ✅ (0.10.0)
- **Nerede?** Bugün sekmesinde, maskotun cümlesinin altında ve **CANIM
  SİGARA İSTİYOR** butonunun hemen üstünde: istek geldiğinde ne kadar
  zamandır içmediğini görürsün. İlk sigara kaydından sonra görünür
  (öncesinde sayacak bir şey yok).
- **Biçim:** 3 kutu (büyük sayı + altında birim):
  - 24 saatten az: **saat / dakika / saniye** (her saniye ilerler):
    `02 saat · 14 dakika · 05 saniye`
  - 24 saat ve fazlası: **gün / saat / dakika** (saniye gösterilmez, ekran
    sakin kalsın): `3 gün · 04 saat · 12 dakika`
- Süre sayılarak değil, her saniye "şimdi − son sigaranın zamanı" diye
  yeniden hesaplanır: uygulama arka planda kalsa ya da telefon kilitlense
  bile doğru. Eksi süre (saat geri alınırsa) 0 gösterilir.
- **Kurallar** (Bölüm 3, madde 13): Yeni sigara gelince sessizce sıfırlanır;
  mesaj, ses, titreşim, renk değişimi yok. Puan, rekor, kutlama yok. Renk
  nane (nötr, olumlu); kırmızı ya da yaprak (seri) rengi değil.
- Uyku da süreye dahildir (sabahları sayaç birkaç saatten başlar); bu
  doğru bir bilgidir, ayrıca bir şey yapılmadı.
- Ekran okuyucu kutuları tek tek değil, tek cümle okur: "Son sigarandan
  beri 2 saat 14 dakika 5 saniye".
- İstatistik'teki "Son: 3 sa önce" yazısı kaldırıldı (tek giriş noktası).
- Kod: `lib/widgets/since_last_counter.dart` (sayaç), `sinceCounterParts`
  (`lib/utils/format.dart`, süreyi 3 kutuya böler; testli).
- Açık soru: ölçüm haftasında da görünüyor (bkz. Bölüm 11).

### Özellik 2g — "Başladığından beri" ✅ (0.11.0)
- **Neden?** Kullanıcı tek bakışta "ne durumdayım?" sorusunun cevabını
  göremiyordu: parçalar vardı ama dağınıktı (Hedefim sadece hedef
  seçenlerde; haftalık kart başlangıca değil geçen haftaya göreydi).
- **Nerede?** İstatistik sekmesinin **en üstünde** (tek giriş noktası).
  Ölçüm haftasından sonra **7 gün tamamlanınca** açılır (takibin 15.
  günü); öncesinde "şimdi" ölçüm haftasının kendisi olurdu. Ölçüm
  haftası özetindeki "Neler açıldı?" listesinde haber verilir.
- **İçerik:**
  1. Büyük yazı: "%27 daha az" / "%8 daha fazla" / "Başlangıç noktana
     yakın" (yüzde %0'a yuvarlanıyorsa).
  2. "Başlangıçta günde 15 → Şimdi günde 11". Başlangıç = ölçüm
     haftasında günde ortalama; Şimdi = son 7 tamamlanmış gün (Hedefim'deki
     "Şimdi" ile aynı sayı, `lastSevenDaysAverage`).
  3. Hafta hafta küçük grafik: takibin her biten haftasında günde
     ortalama (1. hafta = ölçüm haftası). En fazla 8 çubuk: 1. hafta + en
     yeni 7 hafta.
- **Renk:** azalma varsa kart nane; artış nötr (kırmızı yok, mesaj yok).
- **Araştırma için:** Bu yüzde, pilotun ana sonuç sayısıdır (başlangıca
  göre günlük sigara sayısındaki değişim); kullanıcı ile araştırma aynı
  sayıya bakar.
- Kod: `lib/logic/progress.dart` (saf hesap, `test/progress_test.dart`),
  `lib/screens/stats_tab.dart` → `_SinceStartCard`.

### Özellik 2h — Elle düzeltme ✅ (0.11.0)
- **Neden?** Kılıf her sigarayı göremez (başkasının paketi, ikinci paket,
  sarma) ve bazen yanlış sayar (sigarayı bir arkadaşına vermek). Pilotta
  ilk sorulacak şey "kılıf ne kadar doğru ölçüyor?" olacak.
- **Elle ekleme:** Onboarding'de "Kılıfın göremeyeceği sigaralar içtiğin
  olur mu?" sorusuna "Evet" diyenlerin Bugün sekmesinde, "Bugünkü
  sigaraların" kartının altında **ELLE SİGARA EKLE** butonu var.
  Dokununca saat sorulur (varsayılan şimdi; gelecek saat seçilemez).
  Kayıt `source: manual` ile saklanır; listede "· elle" yazar. Cevabı
  "Bilgilerimi düzenle"den değiştirilebilir.
- **"Bu sigarayı ben içmedim":** Bugünkü bir sigaranın "Neden?"
  penceresinin altında küçük, nötr (kırmızı değil) bir bağlantı. Onaydan
  sonra kayıt silinir.
- **Kurallar:** Bölüm 3, madde 14 (puan, ses, kutlama yok).
- **Pilot için:** Elle eklenenler `manual` kaynağıyla ayrıldığı için
  "sigaraların yüzde kaçını kılıf gördü?" raporlanabilir.
- **Aşama 7 notu:** Silinen bir kılıf kaydı, kılıf onu tekrar gönderirse
  yeniden eklenebilir. Taslak protokolde telefon her kaydı onaylar (ack)
  ve kılıf onaylananları siler, bu yüzden normalde tekrar gelmez; gerçek
  kılıfta denenmeli.
- Kod: `AppState.addManualEvent` / `removeEvent`,
  `lib/screens/today_tab.dart`, `lib/widgets/pickers.dart`
  (`TriggerChoice.notMine`).

### Özellik 3 — Süreç aşamaları ⏳ Aşama 3
Ölçüm → Farkındalık → Azaltma → Bırakma günü → Sürdürme
- **Ölçüm (1 hafta):** sadece veri toplanır, **hiç mesaj yok**. (Aşama 2'de
  ölçüm haftası sayacı ve görev kısıtı; 0.6.0'da hafta sonu özeti eklendi.)
- **Farkındalık:** kullanıcıya kendi örüntüsü gösterilir (en yoğun saatler,
  işaretlenen nedenlerin dağılımı, sabah ilk sigara saati).
- **Azaltma:** kademeli günlük hedefler (ölçüm haftası ortalamasından).
  ✅ 0.9.0'da geldi (Özellik 2e).
- **Bırakma günü:** kullanıcı tarih seçer; **ALO 171** (Sigara Bırakma
  Danışma Hattı) ve **sigara bırakma polikliniği** (MHRS üzerinden randevu)
  yönlendirmesi. ✅ 0.12.0'da geldi (Özellik 2i).
- **Sürdürme:** sigarasız gün sayacı (son sigaradan beri geçen süre
  0.10.0'da Bugün'de; bkz. Özellik 2f), **WHO iyileşme takvimi** (bkz.
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
│   ├── goal.dart              Azaltma hedefi (yüzde, süre, başlangıç)
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
│   ├── progress.dart          "Başladığından beri" (başlangıç, şimdi, haftalar)
│   ├── weekly_report.dart     Haftalık rapor (haftalar, rapor hesabı)
│   ├── quests.dart            Günlük görevler, ölçüm haftası
│   ├── rewards.dart           XP ödülleri, seri (dinlenme günü dahil)
│   ├── wardrobe.dart          Nefes'in dolabı: eşya açılma, filiz aşaması
│   ├── goal.dart              Hedef: haftalık sınır, ilerleme, zorluk
│   └── mascot_messages.dart   Maskotun cümleleri (ana ekran, haftalık rapor)
├── utils/format.dart          Türkçe tarih/para/süre yazımı
├── screens/
│   ├── onboarding_screen.dart Tek soru = tek ekran
│   ├── main_screen.dart       Alt menü + 3 sekme
│   ├── today_tab.dart         Bugün: maskot, sayaç, görevler, erteleme
│   ├── stats_tab.dart         İstatistik: "Başladığından beri", sayılar, grafik, maliyet
│   ├── profile_tab.dart       Profil: seri, puan, dolap kartı, başarılar
│   ├── delay_screen.dart      10 dk erteleme
│   ├── breathing_screen.dart  1 dk nefes egzersizi
│   ├── celebration_screen.dart Konfetili kutlama
│   ├── measurement_summary_screen.dart "Ölçüm haftan bitti!" özeti
│   ├── weekly_report_screen.dart Haftalık rapor
│   ├── wardrobe_screen.dart   Nefes'in dolabı (Profil'den açılır)
│   ├── goal_setup_screen.dart Hedef seçme (yüzde, süre + zorluk, not)
│   ├── goal_screen.dart       Hedefim: tek bakışta ilerleme
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
    ├── since_last_counter.dart "Son sigarandan beri" sayacı (her saniye)
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
  hafızasından silebilir. Bu, çift sayımı ve kaybı önler. (Kullanıcının
  "Bu sigarayı ben içmedim" ile sildiği kayıt da böylece tekrar gelmez.)
- İsteğe bağlı olay türü (araştırma için): kapak açıldı ama IR sensörü
  sigara alındığını görmedi. Direnilmiş bir istek mi, paket kontrolü mü
  belirsiz; bu yüzden uygulamada puan/görev/mesaj OLMAZ, sadece pilot
  verisi olarak saklanabilir.

### Kılıfın OLED ekranı (ÖNERİ — donanım ekibi için, 0.11.0)
Kapak açılma anı, sigara kararının verildiği an; doğru anda küçük bir
bilgi vermek için en değerli yer ("tam zamanında müdahale", JITAI:
Nahum-Shani ve ark. 2018). Ama kılıf masada durur ve başkaları da görür.
- **Ne zaman yanar?** Normalde kapalı. Kapak açılınca ~5 saniye yanar,
  sonra söner. (Pil: açıkken kılıfın en çok enerji harcayan parçası olur.
  Gizlilik: sürekli açık bir ekran dikkat çeker.)
- **Ne yazar? Tek bilgi:** `Son sigaradan beri` + `2 sa 14 dk` (24 saati
  geçince `1 gun 4 sa` gibi). Uygulamadaki sayacın aynısı, nötr ve
  kişinin kendi verisi. Kılıf bunu telefonsuz bilir: son olaydan beri
  geçen süreyi kendi sayacıyla tutar, gerçek saate (RTC) gerek yok.
  İlk kayıttan önce sadece logo.
- **Köşede küçük teknik simgeler:** pil, Bluetooth bağlı mı, telefona
  gönderilmeyi bekleyen kayıt sayısı. Pilotta sorun ararken çok işe yarar
  (sağlık bilgisi değil, teknik bilgi).
- **YAZMAYACAKLARI:** bugünkü sigara sayısı ya da hedef (yanındakiler
  görür; tek renkli ekranda "11/10" nötr gösterilemez → suçlama kuralına
  takılır), sağlık uyarıları, harcanan para, üzgün yüz.
- **Sigara alındıktan sonra:** hiçbir şey (Bölüm 3: sigara içmek hiçbir
  şey tetiklemez). Ekran söner.
- **Türkçe harfler:** Hazır OLED fontlarının çoğunda ş, ğ, ı, İ yok.
  Önerilen metinlerde bu harfler yok; "gün" yerine "gun" yazılabilir ya
  da Türkçe harfli bir font eklenir. Kılıfta denenmeli.

## 6. Veri modeli

- `SmokingEvent { time, source: demo | device | manual, trigger? }`
  (`manual` = elle eklenen, 0.11.0)
- `UserProfile` (hepsi isteğe bağlı): `cigarettesPerDay`, `firstCigarette`
  (4 seçenek), `smokesOutsideCase` (0.11.0; kılıfın göremeyeceği
  sigaralar olur mu), `triggers`, `reasonNote` (kendine not, ≤140 harf).
- `ActivityLog { moods[], delays[], breaths[], xp[], activeDelayStart? }`
  - `MoodEntry { time, mood }` (Çok zor / Zor / İdare eder / İyi / Harika;
    ekranda bu sırayla soldan sağa)
  - `DelayAttempt { start, end, outcome: success | gaveIn }`
  - `XpEntry { time, amount, reason }` — XP'nin "defteri"; toplam ve seri
    buradan hesaplanır.
- `PriceHistory { entries: PackPrice { since, price, perPack (vars. 20) } }`
  — `at(zaman)` o andaki geçerli fiyatı verir.
- `tracking_started_at`: ölçüm haftasının ilk günü. 0.12.0'dan beri
  onboarding gün ortasında biterse ERTESİ günün 00:00'ı (bugün hazırlık
  günü; `trackingStartFor`). Eski kullanıcılarda onboarding anı (onların
  1. günü yarımdı; değiştirilmedi).
- `measurement_summary_seen`: "Ölçüm haftan bitti!" özeti görüldü mü.
- `goal` (0.9.0): `Goal { start, baseline, from, percent, amount, unit:
  week | month, quitDay?, quitMethod?: gradual | abrupt }` (`quitDay` ve
  `quitMethod` 0.12.0'dan beri, sadece bırakma hedefinde). Haftalık sınırlar ve ilerleme saklanmaz, her seferinde
  kayıtlardan hesaplanır. Takip baştan başlarsa silinir.
- `weekly_report_seen`: en son görülen haftalık raporun hafta numarası
  (0 = hiç). Raporların kendisi saklanmaz, her seferinde kayıtlardan
  hesaplanır.
- `mascot_outfit`: takılı eşyaların adları (`Accessory`: gozluk, atki, kep,
  kulaklik, tac, bere). Açılan eşyalar ve filiz aşaması **saklanmaz**, her
  seferinde toplam puan / en uzun seri / ölçüm haftasından hesaplanır
  (`MascotLook { stage, accessories }`).

## 7. Ekranlar (Aşama 2 itibarıyla)

- **Onboarding:** Karşılama ("Merhaba! Ben Nefes.") → 5 tek-soruluk ekran
  → konfetili "Hazırsın!". Sağ üstte "ATLA" (o ana kadarki cevaplar
  kaydedilir). Profil/Ayarlar'dan düzenleme modunda tekrar açılır;
  düzenleme modunda paket fiyatı sorusu YOKTUR (fiyatın kendi yeri var).
- **Bugün:** ölçüm rozeti + seri; demo uyarısı (+1 sigara); maskot
  cümlesi (+ hafta bitince "SONUÇLARIMI GÖR", sonraki haftalarda "RAPORUMU
  GÖR"); "Son sigarandan beri" sayacı (ilk kayıttan sonra; 0.10.0);
  "CANIM SİGARA İSTİYOR"; "Hedefim" kartı (ölçüm özeti görülünce;
  hedef yoksa "Bir hedef seç");
  günlük görevler; bugünkü sigaralar ve "Neden?" etiketleri ("Neden?"
  penceresinde "Bu sigarayı ben içmedim"; "Evet" diyenlerde altta
  "ELLE SİGARA EKLE", 0.11.0).
- **Hedef seçme / Hedefim** (0.9.0): bkz. Özellik 2e; bırakma günü
  (0.12.0): Özellik 2i.
- **İstatistik:** "Başladığından beri" (takibin 15. gününden itibaren, en
  üstte; 0.11.0), bugün kartı, son 7 gün grafiği, "Haftalık raporların" (ölçüm haftasından
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
| Sigara başına yaşam süresi: erkek ~17 dk, kadın ~22 dk, ort. ~20 dk | Jackson SE, Jarvis MJ, West R. "The price of a cigarette: 20 minutes of life?" *Addiction*, 2024 (UCL). doi:10.1111/add.16757 | İstatistik → "Kazandıkların": sadece sigarasız günler × başlangıç noktası × 20 dk (genel ortalama; cinsiyet sorulmuyor) |
| Az sayıda sigara bile riskin önemli kısmını taşır: günde ~1 sigara, koroner kalp hastalığı ve inme riskinin günde 20 içenlerdekinin yaklaşık yarısı kadar | Hackshaw A ve ark. "Low cigarette consumption and risk of coronary heart disease and stroke: meta-analysis of 141 cohort studies in 55 study reports." *BMJ*, 2018;360:j5855 | Tasarım kararı: korunan yaşam süresi azaltılan günlere değil sadece sigarasız günlere (ekranda (i) penceresinde, sayı yok) |
| Azaltmanın sağlık kazancı sınırlı/belirsiz | Pisinger C, Godtfredsen NS. "Is there a health benefit of reduced tobacco consumption? A systematic review." *Nicotine Tob Res*, 2007;9(6):631–646 | Aynı tasarım kararı (ekranda sayı yok) |
| Uyanınca ilk sigara süresi (bağımlılık göstergesi) | Heatherton TF ve ark. "The Fagerström Test for Nicotine Dependence", *Br J Addict*, 1991 | Onboarding, demo |
| Günde kaç sigara + uyanınca ilk sigara = Sigara İçme Ağırlığı İndeksi (HSI) | Heatherton TF, Kozlowski LT, Frecker RC, Rickert W, Robinson J. "Measuring the heaviness of smoking..." *Br J Addict*, 1989;84(7):791–800 | Pilot raporu (bağımlılık düzeyi); uygulamada hesaplanmaz |
| Fagerström testinin Türkçe güvenilirliği | Uysal MA ve ark. "Fagerström test for nicotine dependence: reliability in a Turkish sample and factor analysis." *Tüberküloz ve Toraks*, 2004;52(2):115–121 (ayrıca 2015;63(4):250–256) | Pilot anketi |
| İnsanlar sigara sayısını yuvarlak sayılarla hatırlar; anlık kayıt (EMA) bu yanılgıyı yapmaz | Shiffman S. "How many cigarettes did you smoke? Assessing cigarette consumption by global report, Time-Line Follow-Back, and ecological momentary assessment." *Health Psychology*, 2009 | Onboarding "günde kaç" sorusunun gerekçesi; ölçüm özetinde tahmin ↔ ölçüm |
| İsteği ~10 dk erteleyip dikkat dağıtmak; istek dakikalar içinde geçer | Mayo Clinic, "Quitting smoking: 10 ways to resist tobacco cravings" (Türkçesi: Koç Üniversitesi Hastanesi ve Amerikan Hastanesi Mayo Clinic sağlık kütüphanesi) | Erteleme süresi (10 dk) |
| Kısa yürüyüş sigara isteğini azaltır | Taylor AH, Katomeri M, Ussher M. "Acute effects of self-paced walking on urges to smoke during temporary smoking abstinence." *Psychopharmacology*, 2005;181(1):1–7. Ayrıca Taylor AH, Katomeri M, *Nicotine Tob Res*, 2007 (15 dk yürüyüş sonraki sigarayı ~57 dk geciktirdi) | Erteleme ekranındaki "yürü" önerisi |
| Nefes egzersizi isteği hemen azaltır (24 saat sonra etkisi görülmedi) | Shahab L, Sarkar BK, West R. "The acute effects of yogic breathing exercises on craving and withdrawal symptoms in abstaining smokers." *Psychopharmacology*, 2013;225:875–882 | Nefes molası (ritim 4 sn al / 4 sn ver ekip seçimi) |
| "İstek dalga gibi gelir, geçer": isteği azaltmadı ama 7 günde daha az sigara içildi | Bowen S, Marlatt GA. "Surfing the urge: brief mindfulness-based intervention for college student smokers." *Psychol Addict Behav*, 2009;23(4):666–671 | Erteleme ekranındaki "Bu istek geçici" dili |
| Azaltarak bırakma ↔ birden bırakma | Lindson-Hawley N ve ark. "Gradual versus abrupt smoking cessation: a randomized, controlled noninferiority trial." *Ann Intern Med*, 2016;164(9):585–592. Lindson N ve ark. "Smoking reduction interventions for smoking cessation." *Cochrane Database Syst Rev*, 2019 (CD013183) | Bırakma günü: "O güne kadar azaltarak" / "O gün birden" eşit sunulur, hiçbiri önceden seçili değil; "Neden soruyoruz?" metni (0.12.0) |
| Bırakma gününü yakın seç ("en fazla bir iki hafta sonra"); bırakmadan önce sigaraları, çakmakları, küllükleri kaldır | National Cancer Institute, Smokefree.gov — "Prepare to quit" (smokefree.nci.nih.gov). Quit (quit.org.au, Cancer Council Victoria) — "Setting a quit date and preparing to quit" (quit.org.au): "önümüzdeki iki hafta içinde". (Daha geniş: American Cancer Society "bir ay içinde".) | Bırakma günü varsayılanı 14 gün; 14 günden uzak tarihte nötr not; bırakma gününden bir gün önce Nefes'in hazırlık cümlesi (0.12.0) |
| Kendini izlemek tek başına davranışı değiştirebilir (reaktivite) | McFall RM. "Effects of self-monitoring on normal smoking behavior." *J Consult Clin Psychol*, 1970;35(2):135–142 | Pilot raporunda sınırlılık (ölçüm haftası "saf" değil) |
| Doğru anda müdahale (JITAI) | Nahum-Shani I ve ark. "Just-in-Time Adaptive Interventions (JITAIs) in mobile health." *Ann Behav Med*, 2018;52(6):446–462 | OLED ekran önerisi (Bölüm 5) |
| Kullanılabilirlik ölçeği (SUS) | Brooke J. "SUS: a 'quick and dirty' usability scale." 1996 | Pilot anketi (sonda) |
| Perhiz ihlali etkisi (seri tasarımının gerekçesi) | Marlatt GA, Gordon JR. *Relapse Prevention*, Guilford Press, 1985 | Tasarım kararı (ekranda sayı yok) |
| Korku/tehdit mesajları ancak kişi "değiştirebilirim" diye hissederse işe yarar; yoksa kaçınma/savunma | Witte K. "Putting the fear back into fear appeals: The extended parallel process model." *Communication Monographs*, 1992; Peters GJY, Ruiter RAC, Kok G. "Threatening communication: a critical re-analysis and a revised meta-analytic test of fear appeal theory." *Health Psychology Review*, 2013 | Tasarım kararı: "kaybedilen yaşam" kartı kaldırıldı (ekranda sayı yok) |
| İnsanlar kötü hissettiren ilerleme bilgisine bakmaktan kaçınabilir ("devekuşu sorunu") | Webb TL, Chang BPI, Benn Y. "'The Ostrich Problem': Motivated avoidance or rejection of information about goal progress." *Social and Personality Psychology Compass*, 2013 | Tasarım kararı: kayıp yerine kazanım çerçevesi (ekranda sayı yok) |
| İyileşme takvimi (aşağıda) | WHO — "Tobacco: Health benefits of smoking cessation" (who.int) | Aşama 3 (Sürdürme), Aşama 4 (mesajlar) |
| ALO 171 Sigara Bırakma Danışma Hattı | T.C. Sağlık Bakanlığı | Hedefim sayfası, bırakma hedefinde (0.9.0); Aşama 3 (Bırakma günü) |
| Sigara bırakma poliklinikleri (MHRS randevu) | T.C. Sağlık Bakanlığı | Hedefim sayfası, bırakma hedefinde (0.9.0); Aşama 3 (Bırakma günü) |
| Nunito yazı tipi | The Nunito Project Authors, SIL Open Font License 1.1 (`assets/fonts/OFL.txt`) | Tüm arayüz |
| Ses efektleri | Ekip tarafından sentezlendi (`tool/make_sounds.py`), telif yok | Kutlamalar, nefes, erteleme |

> Not: Kaynaklar arama sonuçları ve özetlerden doğrulandı; tam metinlere
> erişilemedi. Pilot raporunda kesin rakam kullanmadan önce özetleri
> (özellikle Cochrane 2019 ve Pisinger 2007) bir kez okuyun.

### Sayıların dayanağı (0.11.0)
TÜBİTAK için her sayıya makale aramıyoruz; önce TÜRÜNE bakıyoruz. Üçüncü
türe zorla kaynak bulmak, kaynaksız bırakmaktan daha kötü görünür.

| Sayı | Tür | Dayanak |
|---|---|---|
| ~20 dk / sigara (sadece sigarasız günler) | Sağlık iddiası → kaynak şart | UCL 2024; neden sadece sigarasız gün: Hackshaw 2018 |
| WHO iyileşme takvimi (Aşama 3) | Sağlık iddiası → kaynak şart | WHO |
| 10 dk erteleme | Müdahale ayarı → kaynak varsa kaynak | Mayo Clinic; yürüyüş Taylor 2005; "istek geçici" Bowen & Marlatt 2009. Kesin bilimsel sınır değil; pilotta kendi verimizle test edilir (her ertelemenin süresi kaydediliyor; Nefes "istekler genelde X dakikada geçti" diyor) |
| Nefes molası: 6 tur × (4 sn al + 4 sn ver) ≈ 48 sn | Müdahale ayarı | Kısa nefes egzersizinin anlık etkisi: Shahab 2013. Ritim ekibin seçimi |
| 7 günlük ölçüm haftası | Müdahale ayarı → gerekçe | Bir tam hafta içi + hafta sonu döngüsü (hafta sonu farkı büyük). Kaynak değil, ekip kararı |
| Fagerström seçenekleri (5 / 6–30 / 31–60 / 60+ dk) | Kaynaklı ölçek | Heatherton 1991 |
| Gün 04:00'te başlar (ilk sigara için; ölçümün aynı gün başlaması için) | Ekip kararı | Gece yarısından sonra yatmadan önce içilen sigara "günün ilk sigarası" sayılmasın; 04:00'ten önce bitirilen onboarding'de gün henüz başlamamış sayılır |
| Hazırlık günü (ölçüm ertesi gün başlar) | Müdahale ayarı → gerekçe | Başlangıç noktası 7 tam günden ve bir hafta içi + hafta sonu döngüsünden oluşsun (Bölüm 11) |
| Bırakma günü varsayılanı 14 gün; 14 günden uzaksa not | Müdahale ayarı → kaynak | NCI Smokefree, Quit (quit.org.au) (Bölüm 9) |
| Bırakma günü takvimi en fazla 6 ay sonrası | Arayüz kararı | Azaltma hedefinin en uzun süresiyle (6 ay) aynı |
| Zorluk eşikleri (%10 / %20 / %35), önerilen süreler | Ekip kararı (varsayım) | Ekranda sayı olarak gösterilmez, sadece etiket |
| "Başladığından beri" için 7 gün bekleme | Arayüz kararı | "Şimdi" ölçüm haftasının kendisi olmasın |
| Puanlar, dolap eşikleri, dinlenme günü, erteleme puanı günde ≤5 | Oyun kararı | Kaynak gerekmez |
| Fiyat 90 günde bir "hâlâ aynı mı?" | Arayüz kararı | Kaynak gerekmez |

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
| 2+++++ | Azaltma hedefi + "Hedefim" sayfası (Özellik 2e; Aşama 3'ün bir kısmı) | ✅ Tamamlandı (11.10.2026, 0.9.0) |
| 2+6 | "Başladığından beri" kartı, elle düzeltme, kaynaklı sayılar, korunan sürenin sadece sigarasız günlere bağlanması (Özellik 2g, 2h) | ✅ Tamamlandı (15.10.2026, 0.11.0) |
| 3 (kısmi) | Bırakma günü (azaltarak / birden, geri sayım, sigarasız gün), azaltma hedefi bitince öneri, ölçüm haftası 7 tam gün (hazırlık günü) (Özellik 2c, 2i) | ✅ Tamamlandı (15.10.2026, 0.12.0) |
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
- [x] Ölçüm haftası bitince **hedef** (azaltmak/bırakmak) sorusu: yüzde +
      süre, zorluk görünür (0.9.0). Bırakma isteği (1–10) bilerek
      sorulmuyor (hiçbir şeyi değiştirmiyor).
- [ ] Farkındalık ekranı: en yoğun saatler, işaretlenen nedenlerin
      dağılımı, ilk sigara saati ortalaması (sadece kullanıcının verisi;
      özet hesapları `measurement.dart`'ta hazır). Not: haftalık rapor
      (0.8.0) bunun haftalık hâlini zaten gösteriyor; ayrı ekran gerekir mi
      yeniden değerlendirilmeli.
- [x] Azaltma: haftalık kademeli hedef (ölçüm ortalamasından), hedef kartı,
      Hedefim sayfası (0.9.0)
- [ ] Hedefin altında kalınan gün için görev/rozet (açık soru, Bölüm 11)
- [x] Bırakma günü: tarih seçimi, azaltarak / birden, geri sayım,
      bırakma gününden sonra sigarasız gün sayısı, ALO 171 ve poliklinik
      (MHRS) bilgisi; azaltma hedefi bitince öneri (0.12.0)
- [x] Ölçüm haftası 7 tam gün: gün ortasında başlandıysa hazırlık günü
      (0.12.0)
- [ ] Sürdürme: sigarasız süre sayacı + toplam sigarasız gün (sıfırlanmaz),
      WHO takvimi (metin doğrulanmalı). Son sigaradan beri geçen süre
      sayacı 0.10.0'da Bugün'e geldi (Özellik 2f); toplam sigarasız gün ve
      WHO takvimi kaldı.
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
- [ ] CSV dışa aktarma (paylaş menüsü), anonim katılımcı kodu; olay
      kaynağı (`device` / `manual`) da dışa aktarılsın
- [ ] Pilot anketi (Bölüm 11 → "Pilot anketi"): başta ve sonda
- [ ] OLED ekranı (Bölüm 5 → "Kılıfın OLED ekranı") donanım ekibiyle
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
  gösteriliyor (0.11.0'dan beri sadece sigarasız günler için; aşağıda). Kaynaksız "sigaraya giden süre (~6 dk)" varsayımı da
  kaldırıldı (önceki açık soru böylece kapandı).
- **Karar — kazanç NET hesaplanır:** Gün gün "ortalamanın altındaysa ekle"
  toplamı, hiç azaltmayan birinin dalgalanmasını bile kazanç gösterirdi.
  Net hesap daha dürüst; toplam eksiye inmez, bugün sayılmaz (sayı gün
  içinde, sigaradan hemen sonra düşmez). Bir ağır gün sonrası sayı
  azalabilir; bu bilgi verir, suçlamaz (renk nötr, mesaj yok).
- **Karar — azaltma hedefi (0.9.0):**
  - *Yüzde + süre (sayı ve hafta/ay):* Kullanıcı hem "ne kadar" hem "ne
    kadar sürede"yi kendisi seçer; zorluk hemen görünür. Hedef bir söz
    değil, yol haritası: her an değiştirilir, sınırın üstü ceza değildir.
  - *Neden hafta hafta?* Bir anda %50 azaltmak yerine küçük adımlar. Sınırlar
    hedef konduğundaki seviyeden başlar; böylece hedef sonradan
    değiştirilirse kullanıcı geriye itilmez.
  - *Zorluk eşikleri ekibin varsayımı* (Özellik 2e). Birden bırakmak da
    geçerli bir yol olduğu için "Çok iddialı" etiketi caydırıcı değil;
    sadece "zorlanırsan süreyi uzatabilirsin" der.
  - *Kendine not:* İkinci bir not türü eklenmedi; hedef seçerken, daha önce
    yazılmadıysa, aynı not sorulur (tek kavram, tek kayıt).
  - *İlk hedefe +10 puan, değiştirmeye puan yok:* Değiştirip durarak puan
    toplanmasın.
  - **Açık soru — hedefte kalınan güne puan/rozet?** Aşama 3 planında vardı
    ama bilerek eklenmedi: sigarayla bağlantılı bir ödül, sınırı aşan günü
    dolaylı olarak "ödülsüz gün" yapar (perhiz ihlali etkisi riski). Şimdilik
    sadece sayaç var ("Hedefinde kaldığın gün", sadece artar). Ekip karar
    vermeli.
  - **Açık soru — "hedefi kaldır":** Hedef değiştirilebiliyor ama tamamen
    kaldırılamıyor. Gerekirse Hedefim sayfasına küçük bir bağlantı
    eklenebilir.
  - **Açık soru — haftalık raporda hedef:** Rapor henüz hedeften bahsetmiyor
    ("bu hafta 5 gün hedefinde kaldın" gibi). Eklenirse tek cümle olarak,
    Nefes'in rapor cümlesinin içinde olmalı (kalabalık olmasın).
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
- **Karar — "Son sigarandan beri" sayacı (0.10.0):** Bölüm 3'te
  "sigarasız gün serisi" bilerek yok (perhiz ihlali etkisi, Marlatt &
  Gordon 1985). Bu sayaç da her sigarada sıfırlanır, yani aynı risk biraz
  var. Riski küçültmek için seri gibi davranmaz: puan, rekor, kutlama,
  "serin bozuldu" yok; sıfırlanırken mesaj/ses/renk değişimi yok; filiz ve
  dolap ona bağlı değil. Sayaç sadece bilgi verir. Pilotta kullanıcılara
  "sayaç sıfırlanınca nasıl hissettin?" diye sorulması önerilir.
  - **Açık soru — ölçüm haftasında gösterilsin mi?** Şu an ilk kayıttan
    itibaren görünüyor. Ölçüm haftasında Nefes "hiçbir şeyi değiştirmeye
    çalışma" diyor; göz önünde ilerleyen bir sayaç bazı kullanıcıları
    beklemeye itip başlangıç noktasını biraz düşürebilir (erteleme butonu
    gibi; bkz. "Oyunlaştırma ve ölçüm"). Seçenek: sayacı ölçüm haftası
    bitince açmak (kademeli açılım, `today_tab.dart`'ta tek koşul). Ekip
    karar vermeli.
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
- **Karar — ölçüm haftası 7 tam gün, ilk gün hazırlık günü (0.12.0):**
  Onboarding gün ortasında biterse 1. gün eksik ölçülüyordu; başlangıç
  noktası (günde ortalama) düşük, günün ilk sigarası geç çıkıyordu ve bu
  sayı artık "Başladığından beri" kartının ve pilotun ana sonuç sayısının
  temeli. İki seçenek vardı:
  - *İlk günü ortalamaya katmamak:* bekleme yok ama başlangıç 6 günden
    hesaplanır ve haftanın bir günü eksik kalır (ör. cumartesi öğleden
    sonra başlayan birinde cumartesi hiç ölçülmez; hafta sonu farkı büyük).
  - *Ölçümü ertesi gün 00:00'da başlatmak* ✅ **seçildi:** her başlangıç
    noktası 7 tam günden ve bir tam hafta içi + hafta sonu döngüsünden
    oluşur; haftalık raporların haftaları da tam 7 gün. Bedeli: özet bir
    gün geç gelir (hazırlık günü). Gece 04:00'ten önce başlayan için aynı
    gün başlar (gün henüz başlamadı; "günün ilk sigarası" kuralıyla aynı
    sınır). Hazırlık günü kılıfı tanımak için de doğal bir gün.
- **Karar — kullanılmayan sorular kaldırıldı (0.6.0):** Bkz. Özellik 1.
  **Pilot için demografi** (yaş aralığı, cinsiyet, kaç yıldır içtiği)
  gerekiyorsa uygulamada "kişiselleştirme" gibi sorulmamalı: ya pilot onam
  formunda ya da Aşama 7'de CSV ile birlikte, açıkça "araştırma için,
  uygulamayı değiştirmez" diye etiketlenmiş ayrı bir bölümde sorulmalı.
  Ekip ve danışman öğretmen karar vermeli. Önerilen içerik: aşağıda
  "Pilot anketi".
- **Öneri — Pilot anketi (0.11.0):** Uygulamanın "kişiselleştirme"
  soruları değil; araştırma için. Kâğıt/onam formunda ya da Aşama 7'de
  uygulamada ayrı, "araştırma için, uygulamayı değiştirmez" diye
  etiketlenmiş bir bölümde (cevaplar sadece cihazda, CSV ile kullanıcının
  kendi isteğiyle paylaşılır).
  - **Başta:** yaş (18+ kontrolü), cinsiyet, kaç yıldır içtiği, daha önce
    bırakma denemesi (kaç kez, en uzun ne kadar), Fagerström testinin
    tamamı (6 soru; Türkçe güvenilirlik: Uysal ve ark. 2004). HSI,
    uygulamadaki iki sorudan zaten hesaplanabilir (Heatherton 1989).
  - **Sonda:** Fagerström testi tekrar (önce/sonra farkı somut bir sonuç
    verir), SUS kullanılabilirlik ölçeği (Brooke 1996), açık uçlu
    sorular ("Sayaç sıfırlanınca nasıl hissettin?", "Kılıf hiç yanlış
    saydı mı?").
  - **Ana sonuç sayısı:** başlangıca göre günlük sigara sayısındaki
    değişim (%) — uygulamadaki "Başladığından beri" ile aynı hesap.
  - **Raporda yazılacak sınırlılıklar:** kendini izlemek tek başına
    davranışı değiştirebilir (McFall 1970), bu yüzden ölçüm haftası "saf"
    bir başlangıç değildir; erteleme butonu ölçüm haftasında da açık;
    kılıfın göremediği sigaralar (elle eklenenler `manual` kaynağıyla
    ayrı sayılabilir); ilk gün yarım ölçülebilir.
- **Karar — korunan yaşam süresi sadece sigarasız günlerde (0.11.0):**
  UCL'nin "sigara başına ~20 dk" tahmini, hayat boyu içilen sigaralara
  bölünmüş bir ortalama ve kendi çerçevesi BIRAKMAK. Bunu "azalttığın her
  sigara 20 dk" diye kullanmak sigara ile kayıp arasında doğrusal bir
  ilişki varsayar; oysa günde ~1 sigara bile koroner kalp hastalığı ve
  inme riskinin, günde 20 içenlerdekinin yaklaşık yarısını taşır
  (Hackshaw 2018) ve azaltmanın sağlık kazancı belirsizdir (Pisinger ve
  Godtfredsen 2007). Tıp bilgisi olan bir değerlendirici bunu sorardı.
  Artık sadece sigarasız günler sayılır (her gün × başlangıç noktası ×
  20 dk); azaltılan günlerde içilmeyen sigara ve para yine birikir. (i)
  penceresi nedenini korkutmadan anlatır. Demo kullanıcısının hiç
  sigarasız günü olmadığı için demoda bu kart görünmez (bağlantı
  görünür).
- **Tartışma — azaltarak mı, birden mi bırakmak? (0.11.0):** Projenin
  temel fikri ("azaltmadan bırakmaya") bu tartışmanın ortasında; raporda
  bilerek ele alınmalı.
  - İngiltere'de 697 kişilik deneyde 6. ayda birden bırakanların %22'si,
    2 haftada %75 azaltıp bırakanların %15,5'i sigarasızdı
    (Lindson-Hawley 2016). Farkın çoğu, azaltma grubunun bırakma gününde
    bırakmayı daha az denemesinden geliyordu.
  - Cochrane derlemesi (Lindson ve ark. 2019) ise ikisi arasında belirgin
    bir üstünlük bulmadı (orta düzey kanıt); kişiye seçenek sunulmasını
    destekliyor.
  - **Uygulama için çıkarım:** "Bırakmak" hedef ekranında azaltmayla eşit
    görünür (öyle). Azaltma son durak değil, bir bırakma tarihine giden
    yol olarak sunulmalı → Aşama 3'teki "Bırakma günü" öncelikli.
  - **Karar (0.12.0):** Azaltma hedefi tamamlanınca ya da süresi dolunca
    Hedefim'de nazik bir "Bir sonraki adım: bırakma günü" kartı çıkar
    (açılır pencere/bildirim değil; Özellik 2e madde 6). Bırakma günü
    seçerken iki yol eşit sunulur, hiçbiri önceden seçili değil
    (Özellik 2i).
- **Karar — "günde kaç" sorusu kalır (0.11.0):** Kılıf ölçüyor diye
  kaldırılması tartışıldı; kaldı. Gerekçe Özellik 1'de (tahmin ölçümden
  önce sorulabilir; tahmin ↔ ölçüm farkı bir bulgu; HSI).
- **Karar — "Son 7 gün ↔ önceki 7 gün" kartı yerine "Başladığından beri"
  (0.11.0):** Haftadan haftaya fark haftalık raporda zaten var; İstatistik'in
  en üstü "başladığımdan beri ne durumdayım?" sorusuna ayrıldı (tek giriş
  noktası).
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
| 0.9.0 | Hedefim | Ölçüm haftası özetinin sonunda Duolingo tarzı hedef seçimi: ne kadar (%25 / %50 / %75 / bırakmak, yanında günlük karşılığı), ne kadar sürede (sayı + hafta/ay) ve hemen görünen zorluk (Rahat / Dengeli / İddialı / Çok iddialı + "her hafta günde yaklaşık 2 sigara"); isteğe bağlı kendine not (erteleme ekranındakiyle aynı not); ilk hedefe +10 puan. Hafta hafta inen günlük sınırlar. Tek bakışta "Hedefim" sayfası: Nefes'in cümlesi, başlangıç / şimdi / hedef ve ilerleme çubuğu, bu haftanın sınırı ve 7 günlük şerit (nane = hedefinde, gri = nötr), hedefinde kaldığın gün sayısı, bırakma hedefinde ALO 171 bilgisi. Bugün'de "Hedefim" kartı. Sınırın üstü asla ceza değil. Kutlamada uzun seri yazısı artık taşmıyor |
| 0.10.0 | Son sigarandan beri | Bugün sekmesinde, erteleme butonunun üstünde canlı sayaç: 24 saatten az ise saat / dakika / saniye (her saniye ilerler), sonra gün / saat / dakika. İlk kayıttan sonra görünür; yeni sigarada sessizce sıfırlanır (mesaj, ses, renk değişimi, puan yok; seri değil). Ekran okuyucu tek cümle okur. İstatistik'teki "Son: … önce" yazısı kaldırıldı (aynı bilgi iki yerde olmasın) |
| 0.11.0 | Başladığından beri | İstatistik'in en üstünde tek bakışta durum: başlangıca göre "%27 daha az", "Başlangıçta günde 15 → Şimdi günde 11" ve hafta hafta küçük grafik (takibin 15. gününden itibaren; artış nötr). Kılıf yanılırsa düzelt: onboarding'e "Kılıfın göremeyeceği sigaralar içtiğin olur mu?" sorusu, "Evet" diyenlere Bugün'de "ELLE SİGARA EKLE"; "Neden?" penceresinde "Bu sigarayı ben içmedim" (puan/ses/kutlama yok). Korunan yaşam süresi artık sadece sigarasız günlerden (Hackshaw 2018). "Neden soruyoruz?" metinleri gerçek gerekçeyi söylüyor. Ayarlar → Kaynaklar'a 10 dk erteleme, nefes molası ve tahmin sorusunun kaynakları; SPEC'e sayıların dayanağı tablosu, OLED ekran önerisi, pilot anketi ve "azaltarak mı birden mi" tartışması. "Son 7 gün ↔ önceki 7 gün" kartı kaldırıldı |
| 0.12.0 | Bırakma günü | Hedef seçerken "Bırakmak" seçilince süre yerine bırakma günü: Bugün / 1 hafta / 2 hafta / 1 ay sonra ya da takvimden (varsayılan 2 hafta; rehberler 1–2 hafta öneriyor) ve yol: "O güne kadar azaltarak" ya da "O gün birden" (ikisi de geçerli, hiçbiri önceden seçili değil; kaynaklar "Neden soruyoruz?"da). Hedefim'de geri sayım, bırakma gününden sonra "Sigarasız gün" sayısı (sadece artar; kayma olursa "Kaldığın yerden devam"). Nefes bir gün önce hazırlık önerir, bırakma günü yanında olur. Azaltma hedefi bitince Hedefim'de "Bir sonraki adım: bırakma günü" önerisi. Ölçüm haftası artık 7 tam gün: gün ortasında başlandıysa bugün hazırlık günü, ölçüm yarın başlar ("Ölçüm yarın başlıyor"). Hedef akışında not yazınca oluşan çökme düzeltildi |
