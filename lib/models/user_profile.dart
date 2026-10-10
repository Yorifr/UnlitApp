/// Kullanıcının onboarding'de verdiği cevaplar.
///
/// Tüm sorular isteğe bağlı olduğu için alanların çoğu boş (null) olabilir.
/// Uygulamanın her yeri "bu bilgi yoksa ne yaparım?" sorusunu düşünmeli.
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
    this.yearsSmoking,
    this.firstCigarette,
    Set<SmokingTrigger>? triggers,
    this.goal,
    this.quitDesire,
    this.ageRange,
    this.gender,
    Set<Motivator>? motivators,
    Set<Activity>? activities,
  }) : triggers = triggers ?? {},
       motivators = motivators ?? {},
       activities = activities ?? {};

  // ---------- Sigara alışkanlığı ----------

  /// Günde ortalama kaç sigara içtiği (kullanıcının kendi tahmini).
  int? cigarettesPerDay;

  /// Kaç yıldır sigara içtiği. 0 = "1 yıldan az".
  int? yearsSmoking;

  /// Uyandıktan sonra ilk sigarayı ne zaman içtiği (Fagerström testi 1. soru).
  FirstCigaretteTime? firstCigarette;

  /// Sigara isteğini tetikleyen durumlar (kahve, stres, ...).
  Set<SmokingTrigger> triggers;

  /// Hedef: azaltmak mı, bırakmak mı?
  QuitGoal? goal;

  /// Bırakma isteği, 1 (hiç) – 10 (çok).
  int? quitDesire;

  // ---------- İsteğe bağlı profil ----------

  AgeRange? ageRange;
  Gender? gender;

  /// Kullanıcıyı motive eden kişiler/şeyler.
  Set<Motivator> motivators;

  /// Sevdiği aktiviteler (mesaj motorunda "yarın koşacaksan..." gibi
  /// önerilerde kullanılacak).
  Set<Activity> activities;

  /// Profilin bağımsız bir kopyasını üretir.
  UserProfile copy() => UserProfile.fromJson(toJson());

  /// Kayıt için JSON'a çevirir. Enum'ları adlarıyla ("coffee" gibi) saklarız.
  Map<String, dynamic> toJson() => {
    'cigarettesPerDay': cigarettesPerDay,
    'yearsSmoking': yearsSmoking,
    'firstCigarette': firstCigarette?.name,
    'triggers': triggers.map((t) => t.name).toList(),
    'goal': goal?.name,
    'quitDesire': quitDesire,
    'ageRange': ageRange?.name,
    'gender': gender?.name,
    'motivators': motivators.map((m) => m.name).toList(),
    'activities': activities.map((a) => a.name).toList(),
  };

  /// JSON'dan profili geri oluşturur. Bozuk ya da eski sürümden kalma bir
  /// değer gelirse o alanı boş bırakırız; uygulama çökmez.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      cigarettesPerDay: _asInt(json['cigarettesPerDay']),
      yearsSmoking: _asInt(json['yearsSmoking']),
      firstCigarette: _enumByName(
        FirstCigaretteTime.values,
        json['firstCigarette'],
      ),
      triggers: _enumSet(SmokingTrigger.values, json['triggers']),
      goal: _enumByName(QuitGoal.values, json['goal']),
      quitDesire: _asInt(json['quitDesire']),
      ageRange: _enumByName(AgeRange.values, json['ageRange']),
      gender: _enumByName(Gender.values, json['gender']),
      motivators: _enumSet(Motivator.values, json['motivators']),
      activities: _enumSet(Activity.values, json['activities']),
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

enum QuitGoal {
  reduce('Azaltmak istiyorum'),
  quit('Tamamen bırakmak istiyorum');

  const QuitGoal(this.label);
  final String label;
}

enum AgeRange {
  from18to24('18–24'),
  from25to34('25–34'),
  from35to44('35–44'),
  from45to54('45–54'),
  from55to64('55–64'),
  over65('65+');

  const AgeRange(this.label);
  final String label;
}

enum Gender {
  male('Erkek'),
  female('Kadın'),
  unspecified('Belirtmek istemiyorum');

  const Gender(this.label);
  final String label;
}

enum Motivator {
  child('Çocuğum'),
  partner('Eşim / sevgilim'),
  parents('Annem, babam'),
  pet('Evcil hayvanım'),
  myself('Kendim');

  const Motivator(this.label);
  final String label;
}

enum Activity {
  running('Koşu'),
  football('Futbol'),
  walking('Yürüyüş'),
  cycling('Bisiklet'),
  swimming('Yüzme'),
  basketball('Basketbol'),
  gym('Spor salonu'),
  dancing('Dans'),
  hiking('Doğa yürüyüşü');

  const Activity(this.label);
  final String label;
}
