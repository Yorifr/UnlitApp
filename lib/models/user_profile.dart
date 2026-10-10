/// Kullanıcının onboarding'de verdiği cevaplar (+ kendine yazdığı not).
///
/// Tüm sorular isteğe bağlı olduğu için alanların çoğu boş (null) olabilir.
/// Uygulamanın her yeri "bu bilgi yoksa ne yaparım?" sorusunu düşünmeli.
///
/// KURAL: Burada sadece uygulamanın GERÇEKTEN kullandığı bilgiler durur.
/// "Sorulan her soru bir söz": cevap bir şeyi değiştirmiyorsa sorulmaz ve
/// saklanmaz. (0.6.0'da yaş, cinsiyet, kaç yıldır, hedef, bırakma isteği,
/// motivasyon ve aktiviteler bu yüzden kaldırıldı; hangisinin ne zaman
/// sorulacağı docs/SPEC.md'de yazıyor.)
///
/// Paket fiyatı BURADA DEĞİL: sık değiştiği ve tarihiyle saklanması gerektiği
/// için ayrı tutulur (bkz. models/pack_price.dart).
///
/// Not: Bu sınıfı bilerek "değiştirilebilir" (mutable) yazdık; onboarding
/// ekranı cevapları doğrudan bu nesneye yazar. Kaydetmeden önce [copy] ile
/// bir kopya üzerinde çalışırız ki yarım kalan değişiklikler asıl profili
/// bozmasın.
class UserProfile {
  UserProfile({
    this.cigarettesPerDay,
    this.firstCigarette,
    Set<SmokingTrigger>? triggers,
    this.reasonNote,
  }) : triggers = triggers ?? {};

  /// Günde ortalama kaç sigara içtiği (kullanıcının kendi tahmini).
  /// Ölçüm haftası özetinde kılıfın saydığıyla yan yana gösterilir; demo
  /// kılıf da sahte veriyi buna yakın üretir.
  int? cigarettesPerDay;

  /// Uyandıktan sonra ilk sigarayı ne zaman içtiği (Fagerström testi 1. soru).
  /// Ölçüm haftası özetinde gösterilir; demo kılıf da buna göre davranır.
  FirstCigaretteTime? firstCigarette;

  /// Sigara isteğini tetikleyen durumlar (kahve, stres, ...).
  /// "Bu sigara neden?" penceresinde bunlar en başta çıkar.
  Set<SmokingTrigger> triggers;

  /// Kullanıcının kendine yazdığı kısa not ("Neden azaltmak istiyorum?").
  /// Erteleme ekranında, zor anda kendi cümlesi olarak gösterilir.
  String? reasonNote;

  /// Notun en fazla kaç harf olabileceği (ekranda kısa ve okunur kalsın).
  static const maxNoteLength = 140;

  /// Profilin bağımsız bir kopyasını üretir.
  UserProfile copy() => UserProfile.fromJson(toJson());

  /// Kayıt için JSON'a çevirir. Enum'ları adlarıyla ("coffee" gibi) saklarız.
  Map<String, dynamic> toJson() => {
    'cigarettesPerDay': cigarettesPerDay,
    'firstCigarette': firstCigarette?.name,
    'triggers': triggers.map((t) => t.name).toList(),
    'reasonNote': reasonNote,
  };

  /// JSON'dan profili geri oluşturur. Bozuk ya da eski sürümden kalma bir
  /// değer gelirse o alanı boş bırakırız; uygulama çökmez. Eski sürümlerin
  /// artık kullanılmayan alanları (yaş, cinsiyet...) okunmaz; profil bir
  /// sonraki kayıtta onlarsız yazılır.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final note = json['reasonNote'];
    return UserProfile(
      cigarettesPerDay: _asInt(json['cigarettesPerDay']),
      firstCigarette: _enumByName(
        FirstCigaretteTime.values,
        json['firstCigarette'],
      ),
      triggers: _enumSet(SmokingTrigger.values, json['triggers']),
      reasonNote: note is String && note.trim().isNotEmpty ? note : null,
    );
  }
}

// ---------- JSON yardımcıları ----------

int? _asInt(Object? value) => value is num ? value.toInt() : null;

/// Adı verilen enum değerini bulur; bulamazsa null döner.
T? _enumByName<T extends Enum>(List<T> values, Object? name) {
  if (name is! String) return null;
  return values.asNameMap()[name];
}

/// Ad listesinden enum kümesi oluşturur; tanınmayan adları atlar.
Set<T> _enumSet<T extends Enum>(List<T> values, Object? names) {
  if (names is! List) return {};
  return names.map((n) => _enumByName(values, n)).whereType<T>().toSet();
}

// ---------- Seçenekler ----------
// Her seçeneğin ekranda görünecek Türkçe adı "label" alanında.

/// Fagerström Nikotin Bağımlılığı Testi 1. soru:
/// "Uyandıktan ne kadar sonra ilk sigaranızı içersiniz?"
enum FirstCigaretteTime {
  within5Min('İlk 5 dakika içinde'),
  within30Min('6–30 dakika içinde'),
  within60Min('31–60 dakika içinde'),
  after60Min('60 dakikadan sonra');

  const FirstCigaretteTime(this.label);
  final String label;
}

enum SmokingTrigger {
  coffee('Kahve'),
  tea('Çay'),
  meal('Yemek sonrası'),
  stress('Stres'),
  friends('Arkadaşlarla'),
  alcohol('Alkol'),
  boredom('Can sıkıntısı'),
  breakTime('Ders / iş arası'),
  driving('Araba kullanırken'),
  phone('Telefonda konuşurken');

  const SmokingTrigger(this.label);
  final String label;
}
