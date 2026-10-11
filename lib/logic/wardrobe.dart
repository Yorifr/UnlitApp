// "Nefes'in dolabı": filizin büyümesi ve eşyaların açılması.
//
// TEMEL KURALLAR (bkz. docs/SPEC.md → Bölüm 3, "Nefes'in dolabı"):
// - Puan HARCANMAZ. Eşyalar belli puanlarda ya da anlamlı anlarda AÇILIR;
//   toplam puan hiç düşmez.
// - Açılan eşya bir daha kaybolmaz. Sigara içmek hiçbir şeyi kilitlemez.
//   (Toplam puan, en uzun seri ve "ölçüm haftası bitti" bilgisi zamanla
//   sadece artar; bu yüzden buradaki hesaplar da asla geri gitmez.)
// - Filiz SADECE toplam puanla büyür; sigara sayısına, sigarasız süreye
//   bağlı DEĞİLDİR. Hiçbir zaman küçülmez ya da solmaz.
// - Sürpriz kutu, "sadece bugün" ya da tetikleyici eşya (fincan, kadeh...)
//   YOK.
//
// Bu dosyadaki fonksiyonlar "saf": ekranla ya da kayıtla uğraşmazlar
// (bkz. test/wardrobe_test.dart).

import '../models/mascot_look.dart';

// ---------- Filizin büyümesi ----------

/// Filizin her aşamaya geçtiği toplam puan. [0] = 1. aşama (başlangıç).
/// (Aktif bir günde yaklaşık 50 puan kazanılıyor: 3 görev × 10 + 20 bonus.)
const List<int> sproutStagePoints = [0, 300, 1000, 2500];

/// En son aşama (çiçek açmış).
int get maxSproutStage => sproutStagePoints.length;

/// Toplam puana göre filizin aşaması (1–4). Puan hiç düşmediği için aşama
/// da hiç geri gitmez.
int sproutStage(int totalXp) {
  var stage = 1;
  for (var i = 0; i < sproutStagePoints.length; i++) {
    if (totalXp >= sproutStagePoints[i]) stage = i + 1;
  }
  return stage;
}

/// Bir sonraki aşamaya kaç puan kaldı? Son aşamadaysa null.
int? pointsToNextStage(int totalXp) {
  final stage = sproutStage(totalXp);
  if (stage >= maxSproutStage) return null;
  return sproutStagePoints[stage] - totalXp;
}

// ---------- Eşyaların açılması ----------

/// Bir eşyanın nasıl açıldığı. Üç yoldan biri:
/// [points] toplam puan, [afterMeasurement] ölçüm haftası bitince,
/// [streakDays] en uzun seri bu kadar gün olunca.
class UnlockRule {
  const UnlockRule.points(int this.points)
    : afterMeasurement = false,
      streakDays = null;
  const UnlockRule.measurement()
    : points = null,
      afterMeasurement = true,
      streakDays = null;
  const UnlockRule.streak(int this.streakDays)
    : points = null,
      afterMeasurement = false;

  final int? points;
  final bool afterMeasurement;
  final int? streakDays;

  /// Ekranda: "250 puan", "Ölçüm haftası bitince", "7 günlük seri".
  String get label {
    if (points != null) return '$points puan';
    if (afterMeasurement) return 'Ölçüm haftası bitince';
    return '$streakDays günlük seri';
  }
}

/// Her eşyanın açılma kuralı. (Eşikler öneridir; ekip değiştirebilir.
/// Değiştirirseniz docs/SPEC.md'deki tabloyu da güncelleyin.)
const Map<Accessory, UnlockRule> unlockRules = {
  Accessory.gozluk: UnlockRule.points(100),
  Accessory.atki: UnlockRule.points(250),
  Accessory.kep: UnlockRule.measurement(),
  Accessory.kulaklik: UnlockRule.points(500),
  Accessory.tac: UnlockRule.streak(7),
  Accessory.bere: UnlockRule.points(1000),
};

/// Açılmış eşyalar.
///
/// [bestStreak]: şimdiye kadarki EN UZUN seri (şu anki seri değil; böylece
/// seri bitse bile taç kaybolmaz). [measurementDone]: ölçüm haftası bitti mi.
Set<Accessory> unlockedAccessories({
  required int totalXp,
  required int bestStreak,
  required bool measurementDone,
}) {
  return {
    for (final MapEntry(key: accessory, value: rule) in unlockRules.entries)
      if ((rule.points != null && totalXp >= rule.points!) ||
          (rule.afterMeasurement && measurementDone) ||
          (rule.streakDays != null && bestStreak >= rule.streakDays!))
        accessory,
  };
}

/// Puanla açılan bir sonraki eşya ve kalan puan (hepsi açıldıysa null).
({Accessory accessory, int pointsLeft})? nextPointUnlock(int totalXp) {
  ({Accessory accessory, int pointsLeft})? best;
  for (final MapEntry(key: accessory, value: rule) in unlockRules.entries) {
    final points = rule.points;
    if (points == null || totalXp >= points) continue;
    if (best == null || points - totalXp < best.pointsLeft) {
      best = (accessory: accessory, pointsLeft: points - totalXp);
    }
  }
  return best;
}

// ---------- Takma / çıkarma ----------

/// Takılı eşyalardan sadece açılmış olanları ve her yerde en fazla birini
/// bırakır. (Ör. veriler sıfırlandıysa kilitli eşya takılı kalmasın.)
Set<Accessory> wearable(Set<Accessory> equipped, Set<Accessory> unlocked) {
  final result = <Accessory>{};
  final usedSlots = <AccessorySlot>{};
  for (final a in Accessory.values) {
    if (!equipped.contains(a) || !unlocked.contains(a)) continue;
    if (usedSlots.add(a.slot)) result.add(a);
  }
  return result;
}

/// [accessory] takılıysa çıkarır; değilse takar (aynı yerdeki eşyayı
/// çıkararak, ör. kep takılınca bere çıkar).
Set<Accessory> toggleAccessory(Set<Accessory> equipped, Accessory accessory) {
  if (equipped.contains(accessory)) return {...equipped}..remove(accessory);
  return {
    for (final a in equipped)
      if (a.slot != accessory.slot) a,
    accessory,
  };
}

/// Mezuniyet kepini takar: başta başka bir eşya varsa onun yerine (ölçüm
/// haftası özetinde "kep geldi" denirken Nefes kep takıyor olsun).
Set<Accessory> wearCap(Set<Accessory> equipped) =>
    equipped.contains(Accessory.kep)
    ? {...equipped}
    : toggleAccessory(equipped, Accessory.kep);

/// Yeni açılan eşyaları, YERİ BOŞSA otomatik takar (kullanıcı yeni eşyasını
/// hemen görsün). Yeri doluysa dokunmaz: kullanıcının seçimine saygı.
Set<Accessory> autoEquip(Set<Accessory> equipped, Iterable<Accessory> fresh) {
  final result = {...equipped};
  for (final a in fresh) {
    final slotTaken = result.any((e) => e.slot == a.slot);
    if (!slotTaken) result.add(a);
  }
  return result;
}
