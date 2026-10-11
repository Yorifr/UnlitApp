// Kullanıcının ölçüm haftasından sonra seçtiği azaltma hedefi.
//
// Örnek: "Günde 15 sigarayı 8 haftada %50 azalt." Hedef bir söz değil, bir
// yol haritası: istenildiği zaman değiştirilebilir ve hedefin dışına çıkmak
// hiçbir ceza getirmez (puan düşmez, seri bozulmaz).
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

class Goal {
  const Goal({
    required this.start,
    required this.baseline,
    required this.from,
    required this.percent,
    required this.amount,
    required this.unit,
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

  /// Süre: [amount] [unit] ("8 hafta", "2 ay").
  final int amount;
  final GoalUnit unit;

  /// Bırakma hedefi mi?
  bool get isQuit => percent == 100;

  /// Aynı hedef, başlangıç günü değişmiş hâli (demo'daki "bir gün ekle"
  /// her kaydı bir gün geriye kaydırırken kullanılır).
  Goal copyWith({DateTime? start}) => Goal(
    start: start ?? this.start,
    baseline: baseline,
    from: from,
    percent: percent,
    amount: amount,
    unit: unit,
  );

  Map<String, dynamic> toJson() => {
    'start': start.millisecondsSinceEpoch,
    'baseline': baseline,
    'from': from,
    'percent': percent,
    'amount': amount,
    'unit': unit.name,
  };

  /// JSON'dan okur; kayıt bozuksa null (uygulama çökmez, hedef yok sayılır).
  static Goal? fromJson(Map<String, dynamic> json) {
    final start = json['start'];
    final baseline = json['baseline'];
    final from = json['from'];
    final percent = json['percent'];
    final amount = json['amount'];
    final unit = GoalUnit.values.asNameMap()[json['unit']];
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
    );
  }
}
