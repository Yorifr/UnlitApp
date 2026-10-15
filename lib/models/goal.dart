// Kullanıcının ölçüm haftasından sonra seçtiği hedef: azaltmak ya da
// bırakmak.
//
// Örnek: "Günde 15 sigarayı 8 haftada %50 azalt." ya da "29 Ekim'de
// bırak, o güne kadar azaltarak." Hedef bir söz değil, bir yol haritası:
// istenildiği zaman değiştirilebilir ve hedefin dışına çıkmak hiçbir ceza
// getirmez (puan düşmez, seri bozulmaz).
//
// Hesaplar (haftalık sınır, ilerleme...) burada değil,
// lib/logic/goal.dart'ta.

/// Hedef süresinin birimi.
enum GoalUnit {
  week('hafta'),
  month('ay');

  const GoalUnit(this.label);

  /// Ekranda yazılan adı ("4 hafta", "2 ay").
  final String label;

  /// Bu birimle seçilebilecek en büyük sayı. (Çok uzun bir azaltma
  /// planı anlamını yitirir; 12 hafta / 6 ay yeterli.)
  int get max => this == GoalUnit.week ? 12 : 6;
}

/// Seçilebilen azaltma oranları (yüzde). 100 = bırakmak.
const goalPercents = [25, 50, 75, 100];

/// Bırakma gününe nasıl gidilecek? (Sadece bırakma hedefinde.)
///
/// İkisi de geçerli bir yol: Cochrane derlemesi (Lindson ve ark. 2019)
/// aralarında belirgin bir üstünlük bulmadı; bir deneyde birden bırakanlar
/// biraz daha başarılıydı (Lindson-Hawley ve ark. 2016). Bu yüzden seçimi
/// kullanıcıya bırakıyoruz ve hiçbirini önceden seçili getirmiyoruz.
enum QuitMethod {
  /// O güne kadar her hafta günlük sınır biraz iner; bırakma gününde 0.
  gradual('O güne kadar azaltarak'),

  /// O güne kadar sınır yok; bırakma gününde birden bırakılır.
  abrupt('O gün birden');

  const QuitMethod(this.label);
  final String label;
}

class Goal {
  const Goal({
    required this.start,
    required this.baseline,
    required this.from,
    required this.percent,
    required this.amount,
    required this.unit,
    this.quitDay,
    this.quitMethod,
  });

  /// Hedefin başladığı gün (00:00). Haftalar bu günden sayılır.
  final DateTime start;

  /// Başlangıç noktası: ölçüm haftasında günde ortalama sigara. Yüzde ve
  /// ilerleme hep buna göre hesaplanır.
  final double baseline;

  /// Hedef konduğu an son 7 günde günde ortalama sigara. Haftalık sınırlar
  /// buradan başlayıp hedefe doğru iner. (İlk hedefte bu, ölçüm haftasının
  /// kendisidir; hedef sonradan değiştirilirse o anki seviyeden başlar.)
  final double from;

  /// Ne kadar azaltılacak (25, 50, 75 ya da 100 = bırakmak).
  final int percent;

  /// Süre: [amount] [unit] ("8 hafta", "2 ay"). Sadece azaltma hedefinde;
  /// bırakma hedefinde bunun yerine [quitDay] var.
  final int amount;
  final GoalUnit unit;

  /// Bırakma günü (00:00). Sadece bırakma hedefinde. (0.12.0'dan önceki
  /// bırakma hedeflerinde boştur; o zaman süre bitişi bırakma günü sayılır,
  /// bkz. logic/goal.dart → quitDayOf.)
  final DateTime? quitDay;

  /// Bırakma gününe nasıl gidilecek (sadece bırakma hedefinde; boşsa
  /// "azaltarak" sayılır: eski bırakma hedefleri böyle çalışıyordu).
  final QuitMethod? quitMethod;

  /// Bırakma hedefi mi?
  bool get isQuit => percent == 100;

  /// Aynı hedef, günleri kaydırılmış hâli (demo'daki "bir gün ekle" her
  /// kaydı bir gün geriye kaydırırken kullanılır).
  Goal copyWith({DateTime? start, DateTime? quitDay}) => Goal(
    start: start ?? this.start,
    baseline: baseline,
    from: from,
    percent: percent,
    amount: amount,
    unit: unit,
    quitDay: quitDay ?? this.quitDay,
    quitMethod: quitMethod,
  );

  Map<String, dynamic> toJson() => {
    'start': start.millisecondsSinceEpoch,
    'baseline': baseline,
    'from': from,
    'percent': percent,
    'amount': amount,
    'unit': unit.name,
    if (quitDay != null) 'quitDay': quitDay!.millisecondsSinceEpoch,
    if (quitMethod != null) 'quitMethod': quitMethod!.name,
  };

  /// JSON'dan okur; kayıt bozuksa null (uygulama çökmez, hedef yok sayılır).
  static Goal? fromJson(Map<String, dynamic> json) {
    final start = json['start'];
    final baseline = json['baseline'];
    final from = json['from'];
    final percent = json['percent'];
    final amount = json['amount'];
    final unit = GoalUnit.values.asNameMap()[json['unit']];
    final quitDay = json['quitDay'];
    if (start is! int ||
        baseline is! num ||
        from is! num ||
        percent is! int ||
        amount is! int ||
        unit == null) {
      return null;
    }
    return Goal(
      start: DateTime.fromMillisecondsSinceEpoch(start),
      baseline: baseline.toDouble(),
      from: from.toDouble(),
      percent: percent,
      amount: amount,
      unit: unit,
      quitDay: quitDay is int
          ? DateTime.fromMillisecondsSinceEpoch(quitDay)
          : null,
      quitMethod: QuitMethod.values.asNameMap()[json['quitMethod']],
    );
  }
}
