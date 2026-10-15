# Unlit

Sigara paketine takılan **akıllı kılıf** için Flutter mobil uygulaması.
Kılıf her sigara alınışını sayıp Bluetooth LE ile telefona gönderir;
uygulama tüketimi takip eder, kişiselleştirilmiş geri bildirim verir ve
kullanıcıyı azaltmadan bırakmaya giden süreçte yönlendirir.

TÜBİTAK 2204-A Lise Öğrencileri Araştırma Projesi.

- 📄 Proje şartnamesi ve aşama planı: [docs/SPEC.md](docs/SPEC.md)
- 🤖 Claude için çalışma rehberi: [CLAUDE.md](CLAUDE.md)
- 🌐 Web sürümü (Pages açıldıktan sonra): **https://yorifr.github.io/UnlitApp/**

> 🔒 **Gizlilik:** Tüm veriler yalnızca cihazda saklanır. Hesap, sunucu,
> analiz veya reklam aracı yoktur.

> 🧪 Kılıf henüz hazır olmadığı için uygulama **demo modunda** çalışır:
> "demo kılıf" gerçekçi sahte sigara kayıtları üretir.

## Uygulamada neler var?

Tasarım ve kullanım hissi **Duolingo'dan ilham** alır, ama hiçbir zaman
suçlamaz:

- **Nefes** adında bir maskot seni karşılar, soruları sorar, yol gösterir.
  Başındaki filiz puan topladıkça 4 aşamada büyür (asla küçülmez).
- **Nefes'in dolabı:** puanlar harcanmaz; belli puanlarda ve anlamlı
  anlarda gözlük, atkı, kep, kulaklık, taç, bere açılır ve Nefes'e
  takılabilir. Açılan eşya kaybolmaz.
- **Sadece 5 kısa soru** (günde kaç sigara, uyanınca ilk sigara, kılıfın
  göremeyeceği sigaralar, paket fiyatı, tetikleyiciler). Her cevap
  uygulamada bir şeyi değiştirir.
- **Günlük 3 görev** (kendini dinle, sigaranın nedenini işaretleme, nefes
  molası, bir isteği 10 dakika erteleme…) → **puan** ve **seri**.
- **Ölçüm haftası:** 7 tam gün sadece ölçülür (gün ortasında başlandıysa
  o gün hazırlık günü, ölçüm ertesi gün başlar); bitince "Ölçüm haftan
  bitti!" özeti (günde ortalama, ilk sigara saati, en yoğun saat, en sık
  neden) ve yeni özellikler açılır.
- **Hedef:** azaltmak (%25 / %50 / %75, süre seçerek) ya da **bırakma
  günü** seçmek (o güne kadar azaltarak ya da o gün birden); bıraktıktan
  sonra sigarasız günler sayılır.
- **"CANIM SİGARA İSTİYOR"** butonu: 10 dakikalık erteleme, öneriler,
  nefes egzersizi ve kullanıcının **kendine yazdığı not**.
- Her başarıda **konfetili kutlama ekranı**.
- **Seri sigara içince bozulmaz**: kendine iyi baktığın günleri sayar,
  haftada bir kaçırılan gün affedilir.
- **İstatistik:** en üstte tek bakışta **"Başladığından beri"** (başlangıca
  göre yüzde kaç değişti + hafta hafta grafik), bugünkü sayı, son 7 günün
  grafiği, harcanan para ve ölçüm haftasından sonra **"Kazandıkların"**:
  içmediğin sigaralar, cebinde kalan para, sigarasız günlerde korunan
  yaşam süresi (ortalama tahmin). Sürekli büyüyen bir "kaybedilen yaşam"
  sayısı bilerek yok.
- **Kılıf yanılırsa düzelt:** kılıfın görmediği sigarayı elle ekle, yanlış
  sayılanı "Bu sigarayı ben içmedim" ile sil.
- **Paket fiyatı:** Zam gelince İstatistik → "Paket fiyatı" kartından
  güncelle; eski günlerin harcaması eski fiyatla kalır.
- **Ses ve titreşim:** görev "ding-ding"i, büyük başarıda fanfar, nefes
  egzersizinde ipucu sesleri, erteleme bitince zil. Ayarlar'dan
  kapatılabilir. Telefonda sessiz moda uyar ve müziği durdurmaz.

---


**Sorun çıkarsa:**
- Site 404 veriyorsa: 2. adımda kaynağın **GitHub Actions** seçili olduğundan
  emin ol ve workflow'u yeniden çalıştır.
- "Branch is not allowed to deploy to github-pages" hatası: Settings →
  **Environments** → `github-pages` → "Deployment branches" kısmında `main`
  izinli olmalı.
- Workflow kırmızıysa: hatalı adımı aç; çoğu zaman `flutter analyze` ya da
  `flutter test` bir sorun bulmuştur. Pull request'lerde de aynı kontroller
  çalışır (ama yayın yapılmaz).

## iPhone'dan takip etme

1. Safari'de **https://yorifr.github.io/UnlitApp/** adresini aç.
2. **Paylaş** → **Ana Ekrana Ekle**. Uygulama gibi tam ekran açılır.
3. **Ses için** iPhone sessiz modda olmamalı (yan tuş "zil" konumunda);
   sessiz moddayken sesler bilerek çalmaz. Ses, ekrana ilk dokunuştan
   sonra açılır. iPhone tarayıcısı titreşimi desteklemez (uygulamada
   çalışır).
4. Veriler **o tarayıcıda** saklanır. Safari geçmişini/verilerini temizlersen
   kayıtlar silinir. Safari, uzun süre açılmayan sitelerin verilerini
   silebildiği için ana ekrandan açmak daha güvenli.
5. Demo modunda uygulama kapalıyken geçen sürenin "sigaraları" da açılınca
   eklenir; yani günlerce takip ettikçe veri gerçek bir kullanıcınınki gibi
   birikir. Ayarlar → **Demo verisi üret** ile son iki haftayı anında
   doldurabilirsin.

## Bilgisayarda çalıştırma

1. [Flutter'ı kur](https://docs.flutter.dev/get-started/install) (stable,
   3.47.7 önerilir). Kontrol: `flutter doctor`
2. Proje klasöründe:
   ```bash
   flutter pub get          # paketleri indir
   flutter run -d chrome    # tarayıcıda çalıştır
   flutter test             # testleri çalıştır
   flutter analyze          # kod analizi
   ```
3. Android telefonda denemek için telefonu USB ile bağla (geliştirici modu
   açık) ve `flutter run` yaz.

## Proje yapısı

```
lib/
├── main.dart              Uygulama buradan başlar
├── app.dart               Tema, Türkçe dil, ilk ekran seçimi
├── app_state.dart         Profil, sigaralar, puan (uygulamanın beyni)
├── theme.dart             Renkler ve yazı tipi (Duolingo tarzı)
├── models/                Veri modelleri (sigara, profil, etkinlikler)
├── services/              Kılıf bağlantısı (demo), yerel kayıt
├── logic/                 Hesaplar: sayılar, ölçüm haftası, görevler, puan, seri
├── utils/format.dart      Türkçe tarih/para/süre yazımı
├── screens/               Onboarding, Bugün, İstatistik, Profil, ...
└── widgets/               Tok butonlar, maskot, konfeti, grafik
assets/fonts/              Nunito yazı tipi (uygulamanın içinde)
assets/sounds/             Ses efektleri (tool/make_sounds.py ile üretildi)
test/                      Otomatik testler
docs/SPEC.md               Şartname + aşama planı
```

## Kaynaklar

- İçilmeyen sigara başına korunan yaşam süresi tahmini: Jackson SE, Jarvis MJ, West R.
  *"The price of a cigarette: 20 minutes of life?"* Addiction, 2024 (UCL).
  Sadece sigarasız günler için kullanılır; neden: Hackshaw A ve ark., BMJ, 2018.
- İsteği 10 dakika ertelemek: Mayo Clinic, *"Quitting smoking: 10 ways to
  resist tobacco cravings"*.
- Uyanınca ilk sigara sorusu: Fagerström Nikotin Bağımlılığı Testi
  (Heatherton ve ark., 1991).
- Yazı tipi: Nunito, SIL Open Font License 1.1 (`assets/fonts/OFL.txt`).
- Diğerleri: [docs/SPEC.md](docs/SPEC.md) → "Kaynaklar".
