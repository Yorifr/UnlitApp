// Günlük görevler.
//
// Her gün 3 küçük, YAPILABİLİR görev var. Görevler sigara içmeyi
// cezalandırmaz; kullanıcının kendine iyi bakmasını ödüllendirir
// (nasıl hissettiğini söylemek, bir isteği ertelemek, nefes molası...).
//
// Yapılmayan görevin cezası yok: gece yarısı sessizce yenileri gelir.

import 'package:flutter/material.dart' show IconData, Icons;

import '../models/activity_log.dart';
import '../models/smoking_event.dart';
import 'stats.dart';

/// Ölçüm haftası kaç gün? (Bu sürede kullanıcıya azaltma görevi verilmez,
/// böylece başlangıç alışkanlığı doğru ölçülür.)
const int measurementDays = 7;

/// Bir ertelemenin süresi (dakika).
const int delayMinutes = 10;

/// Görev türleri.
enum QuestType {
  checkIn(
    title: 'Kendini dinle',
    description: 'Bugün nasıl hissettiğini seç',
    icon: Icons.mood,
    reason: XpReason.questCheckIn,
  ),
  tagTrigger(
    title: 'Nedenini keşfet',
    description: 'Bugünkü bir sigaranın nedenini işaretle',
    icon: Icons.search,
    reason: XpReason.questTag,
  ),
  breathe(
    title: 'Nefes molası',
    description: '1 dakikalık nefes egzersizi yap',
    icon: Icons.air,
    reason: XpReason.questBreathe,
  ),
  delay(
    title: 'İsteği ertele',
    description: 'Bir sigara isteğini $delayMinutes dakika ertele',
    icon: Icons.timer_outlined,
    reason: XpReason.questDelay,
  );

  const QuestType({
    required this.title,
    required this.description,
    required this.icon,
    required this.reason,
  });

  final String title;
  final String description;
  final IconData icon;

  /// Tamamlanınca verilen XP'nin "nedeni" (aynı gün iki kez verilmesin diye).
  final XpReason reason;

  /// Tamamlamak için kaç kez yapılmalı? (Şimdilik hepsi 1: kolay kazanım.
  /// Bu yüzden ekranda ilerleme çubuğu yok; onay işareti yeterli.)
  int get target => 1;
}

/// Bir görevin bugünkü durumu.
class QuestStatus {
  const QuestStatus(this.type, this.progress);
  final QuestType type;
  final int progress;

  bool get done => progress >= type.target;
}

/// Verilen gün ölçüm haftasında mı?
/// Takip başlangıcı bilinmiyorsa (onboarding öncesi) ölçüm haftası sayılır.
bool isMeasurementDay(DateTime day, DateTime? trackingStart) {
  if (trackingStart == null) return true;
  return startOfDay(day)
      .isBefore(addDays(startOfDay(trackingStart), measurementDays));
}

/// Ölçüm haftasının kaçıncı günü? (1–7; ölçüm bittiyse null)
int? measurementDayNumber(DateTime day, DateTime? trackingStart) {
  if (trackingStart == null || !isMeasurementDay(day, trackingStart)) {
    return null;
  }
  return daysBetween(trackingStart, day) + 1;
}

/// O günün 3 görevi.
List<QuestType> questsForDay(DateTime day, {required DateTime? trackingStart}) {
  if (isMeasurementDay(day, trackingStart)) {
    // Ölçüm haftası: sadece farkındalık ve kendine iyi bakma. (Erteleme
    // görevi ölçüm haftası bitince "açılır"; bkz. ölçüm haftası özeti.)
    return const [QuestType.checkIn, QuestType.tagTrigger, QuestType.breathe];
  }
  // Ölçümden sonra: erteleme görevi eklenir; üçüncü görev günden güne değişir.
  return [
    QuestType.checkIn,
    QuestType.delay,
    day.day.isEven ? QuestType.tagTrigger : QuestType.breathe,
  ];
}

/// Görevin o günkü ilerlemesi.
int questProgress(
  QuestType type, {
  required DateTime day,
  required List<SmokingEvent> events,
  required ActivityLog activity,
}) {
  bool sameDay(DateTime t) => startOfDay(t) == startOfDay(day);

  return switch (type) {
    QuestType.checkIn => activity.moods.where((m) => sameDay(m.time)).length,
    QuestType.tagTrigger =>
      events.where((e) => sameDay(e.time) && e.trigger != null).length,
    QuestType.breathe => activity.breaths.where(sameDay).length,
    QuestType.delay =>
      activity.delays
          .where((d) => sameDay(d.end) && d.outcome == DelayOutcome.success)
          .length,
  };
}

/// O günün görevleri ve durumları.
List<QuestStatus> questStatuses({
  required DateTime day,
  required DateTime? trackingStart,
  required List<SmokingEvent> events,
  required ActivityLog activity,
}) {
  return [
    for (final type in questsForDay(day, trackingStart: trackingStart))
      QuestStatus(
        type,
        questProgress(type, day: day, events: events, activity: activity),
      ),
  ];
}
