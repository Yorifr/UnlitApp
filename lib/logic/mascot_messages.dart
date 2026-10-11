// Maskotun ana ekranda söylediği cümleyi seçer.
//
// Kurallar:
// - Asla suçlama, asla "hayal kırıklığı". Artış olduğunda bile nazik ve
//   çözüm öneren bir dil.
// - Sayı sadece kullanıcının KENDİ verisinden gelir (uydurma istatistik yok).
// - Ölçüm haftasında karşılaştırma/yorum yok; sadece bilgilendirme.

import '../widgets/mascot.dart' show MascotMood;
import 'stats.dart';

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
