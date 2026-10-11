// Maskotun ana ekranda ve haftalık raporda söylediği cümleleri seçer.
//
// Kurallar:
// - Asla suçlama, asla "hayal kırıklığı". Artış olduğunda bile nazik ve
//   çözüm öneren bir dil.
// - Sayı sadece kullanıcının KENDİ verisinden gelir (uydurma istatistik yok).
// - Ölçüm haftasında karşılaştırma/yorum yok; sadece bilgilendirme.

import '../models/user_profile.dart';
import '../utils/format.dart';
import '../widgets/mascot.dart' show MascotMood;
import 'quests.dart';
import 'stats.dart';
import 'weekly_report.dart';

/// Maskotun söyleyeceği söz ve yüz ifadesi.
class MascotLine {
  const MascotLine(this.text, this.mood);
  final String text;
  final MascotMood mood;
}

MascotLine mascotGreeting({
  required DateTime now,
  required int questsDone,
  required int questsTotal,
  required int? measurementDay,
  required WeekComparison week,
  required bool canCompareWeeks,
  required bool hardDay,
  required bool delayActive,
  bool measurementSummaryPending = false,
  int? weeklyReportWeek,
}) {
  if (delayActive) {
    return const MascotLine(
      'Ertelemen sürüyor. Yanındayım, birlikte bekliyoruz!',
      MascotMood.calm,
    );
  }
  if (measurementSummaryPending) {
    return const MascotLine(
      'Ölçüm haftan bitti! Seni bir hafta tanıdım. Sonuçlarına birlikte '
      'bakalım mı?',
      MascotMood.cheer,
    );
  }
  if (weeklyReportWeek != null) {
    return MascotLine(
      '$weeklyReportWeek. haftan bitti! Haftalık raporun hazır; birlikte '
      'bakalım mı?',
      MascotMood.cheer,
    );
  }
  if (questsTotal > 0 && questsDone == questsTotal) {
    return const MascotLine(
      'Bugünün tüm görevlerini bitirdin. Harikasın!',
      MascotMood.cheer,
    );
  }
  if (hardDay) {
    return const MascotLine(
      'Zor bir gün gibi. Küçük adımlar da sayılır; ben buradayım.',
      MascotMood.calm,
    );
  }
  if (measurementDay != null) {
    return MascotLine(
      'Ölçüm haftasının $measurementDay. günü! Bu hafta hiçbir şeyi '
      'değiştirmeye çalışma; kılıfını taşı, ben de seni tanıyayım.',
      MascotMood.happy,
    );
  }
  final percent = week.changePercent;
  if (canCompareWeeks && percent != null && percent <= -1) {
    return MascotLine(
      'Son 7 günde önceki haftadan %${percent.abs().round()} daha az içtin. '
      'Süper gidiyorsun!',
      MascotMood.cheer,
    );
  }
  if (canCompareWeeks && percent != null && percent >= 1) {
    return const MascotLine(
      'Bu hafta biraz yoğun geçti, olur böyle. Yavaş ama emin adımlarla: '
      'bugün bir isteği ertelemeyi denemeye ne dersin?',
      MascotMood.happy,
    );
  }
  final hour = now.hour;
  final text = hour >= 5 && hour < 12
      ? 'Günaydın! Bugünkü görevlerin hazır.'
      : hour >= 12 && hour < 18
      ? 'Merhaba! Görevlerine bir göz atalım mı?'
      : 'İyi akşamlar! Günü güzel bitirelim.';
  return MascotLine(text, MascotMood.happy);
}

// ---------- Haftalık rapor ----------

/// Haftalık raporun başında maskotun söylediği cümle.
///
/// Sıra önemli: önce olumlu olan söylenir (önceki haftadan az, başlangıç
/// noktasının altında). Artış varsa suçlama yok; kendine iyi baktığı günler
/// hatırlatılır. Sayılar sadece kullanıcının kendi verisi.
MascotLine weeklyReportLine(WeeklyReport report) {
  final change = report.changeFromPrevious;
  final previous = report.previousIsMeasurement
      ? 'Ölçüm haftana'
      : 'Önceki haftaya';
  if (report.total == 0) {
    return const MascotLine(
      'Bu hafta kılıf hiç sigara saymadı. Kılıfın hep yanındaydıysa harika '
      'bir hafta geçirdin!',
      MascotMood.cheer,
    );
  }
  if (change < 0) {
    return MascotLine(
      '$previous göre ${-change} sigara daha az içtin. Bu senin emeğin!',
      MascotMood.cheer,
    );
  }
  if (report.notSmoked > 0) {
    return MascotLine(
      'Başlangıç noktanın altındasın: bu hafta ${report.notSmoked} sigara '
      'daha az içtin. Yavaş ama emin adımlarla!',
      MascotMood.cheer,
    );
  }
  if (change == 0) {
    return MascotLine(
      '$previous göre aynı: ${report.total} sigara. Kendini tanımaya devam; '
      'küçük adımlar da sayılır.',
      MascotMood.happy,
    );
  }
  return MascotLine(
    report.activeDays > 0
        ? 'Bu hafta biraz yoğun geçti, olur böyle. Yine de '
              '${report.activeDays} gün kendine iyi baktın; bu da sayılır.'
        : 'Bu hafta biraz yoğun geçti, olur böyle. Yeni hafta, yeni bir '
              'başlangıç; ben yanındayım.',
    MascotMood.calm,
  );
}

/// "Gelecek hafta için bir fikir": haftanın en sık nedenine (yoksa en yoğun
/// saatine) göre TEK, somut bir öneri. Öneri hep uygulamanın kendi
/// araçlarına (erteleme, nefes molası) çıkar; sayı içermez.
String weeklyTip(WeeklyReport report) {
  final trigger = report.summary.topTrigger;
  if (trigger == SmokingTrigger.stress) {
    return 'En sık nedenin “Stres”. Gelecek hafta stresli bir anda önce '
        '1 dakikalık nefes molası vermeyi dene; sonra karar senin.';
  }
  if (trigger != null) {
    return 'En sık nedenin “${trigger.label}”. Gelecek hafta '
        '${_situations[trigger]} gelen bir isteği $delayMinutes dakika '
        'ertelemeyi denemeye ne dersin?';
  }
  final peak = report.summary.peakHour;
  if (peak != null) {
    return 'En yoğun saatin ${formatHourRange(peak)}. Gelecek hafta o saatte '
        'gelen bir isteği $delayMinutes dakika ertelemeyi denemeye ne '
        'dersin?';
  }
  return 'Bir istek gelirse “CANIM SİGARA İSTİYOR” butonu her zaman Bugün '
      'sekmesinde seni bekliyor.';
}

/// Bir nedenin cümle içindeki hâli: "... gelen bir isteği ertele".
const _situations = {
  SmokingTrigger.coffee: 'kahveden sonra',
  SmokingTrigger.tea: 'çay içerken',
  SmokingTrigger.meal: 'yemekten sonra',
  SmokingTrigger.stress: 'stresli bir anda',
  SmokingTrigger.friends: 'arkadaşlarınlayken',
  SmokingTrigger.alcohol: 'içki içerken',
  SmokingTrigger.boredom: 'canın sıkıldığında',
  SmokingTrigger.breakTime: 'ders ya da iş arasında',
  SmokingTrigger.driving: 'araba kullanırken',
  SmokingTrigger.phone: 'telefonda konuşurken',
};
