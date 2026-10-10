// Sayıları, tarihleri ve süreleri Türkçe yazmak için küçük yardımcılar.
//
// Not: `intl` paketini kullanmak yerine bu birkaç fonksiyonu kendimiz
// yazdık; hem daha az paket, hem de ne yaptıkları açıkça görülüyor.
//
// DİKKAT: Dart'ın toUpperCase()/toLowerCase() fonksiyonları Türkçe "i/İ" ve
// "ı/I" harflerini doğru çevirmez ("i".toUpperCase() → "I" olur, "İ" değil).
// Bu yüzden büyük/küçük harf dönüşümü yerine hazır listeler kullanıyoruz.

const _months = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', //
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

const _weekdays = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];

const _weekdaysLower = [
  'pazartesi',
  'salı',
  'çarşamba',
  'perşembe',
  'cuma',
  'cumartesi',
  'pazar',
];

const _weekdaysShort = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

/// "10 Ekim Cumartesi"
String formatLongDate(DateTime d) =>
    '${d.day} ${_months[d.month - 1]} ${_weekdays[d.weekday - 1]}';

/// "cumartesi" (cümle içinde kullanmak için küçük harfle)
String weekdayLower(DateTime d) => _weekdaysLower[d.weekday - 1];

/// "Cmt"
String weekdayShort(DateTime d) => _weekdaysShort[d.weekday - 1];

/// "07:05"
String formatClock(DateTime d) =>
    '${_twoDigits(d.hour)}:${_twoDigits(d.minute)}';

String _twoDigits(int n) => n.toString().padLeft(2, '0');

/// Binlik ayraçlı tam sayı: 12500 → "12.500"
String formatThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    // Sondan her 3 basamakta bir nokta koy.
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Para: 1234.6 → "1.235 ₺" (kuruşları yuvarlıyoruz, ekranda sade dursun)
String formatMoney(double amount) => '${formatThousands(amount.round())} ₺';

/// Süre (dakikadan): 45 → "45 dk", 200 → "3 sa 20 dk", 3000 → "2 gün 2 sa"
String formatDuration(int minutes) {
  if (minutes < 60) return '$minutes dk';
  final days = minutes ~/ (24 * 60);
  final hours = (minutes % (24 * 60)) ~/ 60;
  final mins = minutes % 60;
  if (days > 0) return hours > 0 ? '$days gün $hours sa' : '$days gün';
  return mins > 0 ? '$hours sa $mins dk' : '$hours sa';
}

/// Ne kadar önce: "az önce", "12 dk önce", "3 sa önce", "2 gün önce"
String formatTimeAgo(DateTime time, DateTime now) {
  final minutes = now.difference(time).inMinutes;
  if (minutes < 1) return 'az önce';
  if (minutes < 60) return '$minutes dk önce';
  if (minutes < 24 * 60) return '${minutes ~/ 60} sa önce';
  return '${minutes ~/ (24 * 60)} gün önce';
}

/// Yüzde: Türkçede yüzde işareti sayıdan ÖNCE gelir → "%12"
String formatPercent(double percent) => '%${percent.abs().round()}';
