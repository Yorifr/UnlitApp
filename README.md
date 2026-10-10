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
- **Günlük 3 görev** (check-in, sigaranın nedenini işaretleme, nefes molası,
  bir isteği 10 dakika erteleme…) → **XP** ve **seri**.
- **"CANIM SİGARA İSTİYOR"** butonu: 10 dakikalık erteleme, öneriler ve
  nefes egzersizi.
- Her başarıda **konfetili kutlama ekranı**.
- **Seri sigara içince bozulmaz**: kendine iyi baktığın günleri sayar,
  haftada bir kaçırılan gün affedilir.
- **İstatistik:** bugünkü sayı, geçen haftayla karşılaştırma, grafik,
  harcanan para, sigaraya giden süre, tahmini yaşam süresi etkisi.

---

## GitHub Pages'i açma (bir kez yapılır)

Web sürümü, `main` dalına yapılan her push'ta GitHub Actions ile otomatik
derlenip GitHub Pages'e yayınlanır (`.github/workflows/pages.yml`).
İlk sefer için:

1. GitHub'da repoyu aç → **Settings** (Ayarlar) → soldaki menüden **Pages**.
2. **Build and deployment** → **Source** kısmında **GitHub Actions**'ı seç.
   (Başka bir şey kaydetmen gerekmez.)
3. Kodun `main` dalına gelmesini sağla: çalıştığımız dal için bir
   **Pull Request** aç ve **Merge** et. (Ya da `main`'e doğrudan push et.)
4. **Actions** sekmesinde "Web'i yayınla (GitHub Pages)" çalışmasını izle.
   Yeşil tik olunca site şu adreste açılır:
   **https://yorifr.github.io/UnlitApp/** (ilk yayın 1–2 dakika sürebilir).
5. Elle yeniden yayınlamak için: **Actions** → "Web'i yayınla (GitHub
   Pages)" → **Run workflow** (dal: `main`).

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
3. Veriler **o tarayıcıda** saklanır. Safari geçmişini/verilerini temizlersen
   kayıtlar silinir. Safari, uzun süre açılmayan sitelerin verilerini
   silebildiği için ana ekrandan açmak daha güvenli.
4. Demo modunda uygulama kapalıyken geçen sürenin "sigaraları" da açılınca
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
├── app_state.dart         Profil, sigaralar, XP (uygulamanın beyni)
├── theme.dart             Renkler ve yazı tipi (Duolingo tarzı)
├── models/                Veri modelleri (sigara, profil, etkinlikler)
├── services/              Kılıf bağlantısı (demo), yerel kayıt
├── logic/                 Hesaplar: sayılar, görevler, XP, seri
├── utils/format.dart      Türkçe tarih/para/süre yazımı
├── screens/               Onboarding, Bugün, İstatistik, Profil, ...
└── widgets/               Tok butonlar, maskot, konfeti, grafik
assets/fonts/              Nunito yazı tipi (uygulamanın içinde)
test/                      Otomatik testler
docs/SPEC.md               Şartname + aşama planı
```

## Kaynaklar

- Sigara başına yaşam süresi tahmini: Jackson SE, Jarvis MJ, West R.
  *"The price of a cigarette: 20 minutes of life?"* Addiction, 2024 (UCL).
- Uyanınca ilk sigara sorusu: Fagerström Nikotin Bağımlılığı Testi
  (Heatherton ve ark., 1991).
- Yazı tipi: Nunito, SIL Open Font License 1.1 (`assets/fonts/OFL.txt`).
- Diğerleri: [docs/SPEC.md](docs/SPEC.md) → "Kaynaklar".
