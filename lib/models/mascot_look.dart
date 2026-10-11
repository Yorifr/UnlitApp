// Maskotun görünüşü: başındaki filizin büyüme aşaması + taktığı eşyalar.
//
// Eşyalar puanla ya da anlamlı anlarla AÇILIR (puan harcanmaz, bkz.
// logic/wardrobe.dart). Burada sadece "hangi eşyalar var, nereye takılır"
// bilgisi duruyor.

import 'package:flutter/material.dart' show IconData, Icons;

/// Bir eşyanın takıldığı yer. Her yere aynı anda tek eşya takılır
/// (ör. bere ile kep birlikte takılmaz, ikisi de "baş").
enum AccessorySlot { head, face, neck }

/// Nefes'in dolabındaki eşyalar.
///
/// Kayıtta adıyla ("gozluk") saklanır; sırayı değiştirmek eski kayıtları
/// bozmaz. Ekrandaki sıra da bu sıradır (açılma sırasına göre).
enum Accessory {
  gozluk('Güneş gözlüğü', AccessorySlot.face, Icons.wb_sunny_outlined),
  atki('Atkı', AccessorySlot.neck, Icons.waves),
  kep('Kep', AccessorySlot.head, Icons.school_outlined),
  kulaklik('Kulaklık', AccessorySlot.head, Icons.headphones),
  tac('Yaprak taç', AccessorySlot.head, Icons.eco_outlined),
  bere('Bere', AccessorySlot.head, Icons.ac_unit);

  const Accessory(this.label, this.slot, this.icon);

  /// Ekranda görünen Türkçe adı.
  final String label;
  final AccessorySlot slot;
  final IconData icon;
}

/// Maskotun o anki görünüşü.
class MascotLook {
  const MascotLook({this.stage = 1, this.accessories = const {}});

  /// Hiçbir şey takılı değil, filiz en küçük hâlinde (onboarding gibi).
  static const plain = MascotLook();

  /// Başındaki filizin aşaması: 1 (minik filiz) – 4 (çiçek açmış).
  final int stage;

  /// Takılı eşyalar (her yerde en fazla bir tane).
  final Set<Accessory> accessories;

  bool wears(Accessory a) => accessories.contains(a);

  MascotLook copyWith({int? stage, Set<Accessory>? accessories}) => MascotLook(
    stage: stage ?? this.stage,
    accessories: accessories ?? this.accessories,
  );

  @override
  bool operator ==(Object other) =>
      other is MascotLook &&
      other.stage == stage &&
      other.accessories.length == accessories.length &&
      other.accessories.containsAll(accessories);

  @override
  int get hashCode => Object.hash(stage, Object.hashAllUnordered(accessories));
}
