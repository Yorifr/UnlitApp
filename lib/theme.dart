import 'package:flutter/material.dart';

/// Uygulamanın renk paleti: "Nane" teması.
///
/// Duolingo'dan ilham alan canlı, düz (gölgesiz, geçişsiz) renkler; ama
/// Duolingo'nun limon yeşili yerine kendi renklerimiz var:
/// - Nane (turkuaz): ana renk. Yeşil ile mavinin ortası; temiz havayı,
///   "Nefes"i ve söndürülmüş ateşi ("Unlit") anlatır.
/// - Mavi: ikinci renk (seçim, erteleme).
/// - Yaprak yeşili: sadece büyümeyi anlatan yerlerde (seri, maskotun filizi).
///
/// Her rengin bir de "koyu" eşi var: tok butonların alt kenarı
/// (3 boyutlu görünen gölge) bu koyu renkle çizilir.
///
/// Kullanım: `final colors = AppColors.of(context);` → `colors.mint`
class AppColors {
  const AppColors({
    required this.mint,
    required this.mintButton,
    required this.mintShadow,
    required this.mintLight,
    required this.mintText,
    required this.blue,
    required this.blueShadow,
    required this.blueLight,
    required this.blueText,
    required this.gold,
    required this.goldShadow,
    required this.goldLight,
    required this.leaf,
    required this.leafLight,
    required this.purple,
    required this.purpleLight,
    required this.red,
    required this.redShadow,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.disabled,
    required this.disabledText,
  });

  /// Parlak nane (turkuaz): ilerleme çubukları, ikonlar.
  final Color mint;

  /// Buton nanesi: üstündeki beyaz yazı okunsun diye biraz daha koyu.
  final Color mintButton;
  final Color mintShadow;
  final Color mintLight;

  /// Açık zemin üstünde nane rengi YAZI için (okunaklı koyu turkuaz).
  final Color mintText;

  /// Mavi: seçili seçenekler, erteleme, bilgi.
  final Color blue;
  final Color blueShadow;
  final Color blueLight;
  final Color blueText;

  /// Altın sarısı: XP (puan).
  final Color gold;
  final Color goldShadow;
  final Color goldLight;

  /// Yaprak yeşili: seri (yaprak ikonu). Büyümeyi anlatır.
  final Color leaf;
  final Color leafLight;

  /// Mor: rozetler, özel anlar.
  final Color purple;
  final Color purpleLight;

  /// Kırmızı: SADECE "tümünü sil" gibi tehlikeli işlemler için.
  /// Kullanıcının sigara davranışını göstermek için ASLA kullanma.
  final Color red;
  final Color redShadow;

  /// Sayfa zemini (çok hafif nane tonlu). Kartlar bunun üstünde beyaz
  /// ([surface]) durur, böylece öne çıkarlar.
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color disabled;
  final Color disabledText;

  static const light = AppColors(
    mint: Color(0xFF19C3AD),
    mintButton: Color(0xFF0E9A8A),
    mintShadow: Color(0xFF0A7366),
    mintLight: Color(0xFFD7F6F0),
    mintText: Color(0xFF0B7A6D),
    blue: Color(0xFF3D7BF7),
    blueShadow: Color(0xFF2457D6),
    blueLight: Color(0xFFE2ECFF),
    blueText: Color(0xFF2152CC),
    gold: Color(0xFFFFC21A),
    goldShadow: Color(0xFFE09B00),
    goldLight: Color(0xFFFFF4D1),
    leaf: Color(0xFF4FB52C),
    leafLight: Color(0xFFE3F5D8),
    purple: Color(0xFFB27CF7),
    purpleLight: Color(0xFFF1E6FF),
    red: Color(0xFFE5484D),
    redShadow: Color(0xFFB8353A),
    background: Color(0xFFF3F9F8),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEAF3F2),
    border: Color(0xFFD9E6E4),
    text: Color(0xFF263A3D),
    textMuted: Color(0xFF5E7275),
    disabled: Color(0xFFDCE6E5),
    disabledText: Color(0xFF9AABAD),
  );

  /// Koyu tema: lacivert zemin (gece gökyüzü).
  static const dark = AppColors(
    mint: Color(0xFF3DD9C1),
    mintButton: Color(0xFF0E9A8A),
    mintShadow: Color(0xFF0A6A5E),
    mintLight: Color(0xFF10332F),
    mintText: Color(0xFF5FE3CF),
    blue: Color(0xFF6E9BFF),
    blueShadow: Color(0xFF3D6FE0),
    blueLight: Color(0xFF182A4D),
    blueText: Color(0xFF9DBBFF),
    gold: Color(0xFFFFC83D),
    goldShadow: Color(0xFFC79200),
    goldLight: Color(0xFF3A3218),
    leaf: Color(0xFF7BD957),
    leafLight: Color(0xFF1E3518),
    purple: Color(0xFFC9A2FF),
    purpleLight: Color(0xFF2E2440),
    red: Color(0xFFFF6B70),
    redShadow: Color(0xFFB8353A),
    background: Color(0xFF0E1A2B),
    surface: Color(0xFF0E1A2B),
    surfaceAlt: Color(0xFF17263A),
    border: Color(0xFF2A3B55),
    text: Color(0xFFEEF4FA),
    textMuted: Color(0xFF9FB0C6),
    disabled: Color(0xFF2A3B55),
    disabledText: Color(0xFF61738C),
  );

  /// Telefonun açık/koyu moduna uygun paleti verir.
  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Uygulamanın yazı tipi: yuvarlak hatlı, samimi "Nunito".
/// Dosyaları assets/fonts/ içinde; internetten indirilmez (gizlilik).
const String appFontFamily = 'Nunito';

/// Seri ikonu: yaprak (her gün biraz büyüyen bir filiz).
/// Alev bilerek kullanılmıyor: hem Duolingo'nun simgesi, hem de sigarayı
/// bırakmaya çalışan birine "ateş" göstermek uygulamanın adına ("Unlit",
/// yanmayan) ters düşer.
const IconData streakIcon = Icons.eco;

/// Açık veya koyu tema oluşturur (telefonun ayarına göre seçilir).
ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;

  final scheme = ColorScheme.fromSeed(seedColor: c.mint, brightness: brightness)
      .copyWith(
        primary: c.mintButton,
        onPrimary: Colors.white,
        secondary: c.blue,
        surface: c.surface,
        onSurface: c.text,
        onSurfaceVariant: c.textMuted,
        outline: c.border,
        outlineVariant: c.border,
        error: c.red,
      );

  // Yazılar biraz kalın ve yuvarlak: Duolingo'daki samimi hava için.
  final base = ThemeData(brightness: brightness).textTheme;
  final textTheme = base
      .copyWith(
        displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.w900),
        displayMedium: base.displayMedium?.copyWith(
          fontWeight: FontWeight.w900,
        ),
        headlineLarge: base.headlineLarge?.copyWith(
          fontWeight: FontWeight.w900,
        ),
        headlineMedium: base.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
        ),
        headlineSmall: base.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        bodyLarge: base.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        bodyMedium: base.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        bodySmall: base.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        labelSmall: base.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      )
      .apply(
        fontFamily: appFontFamily,
        bodyColor: c.text,
        displayColor: c.text,
      );

  final rounded16 = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );

  return ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: appFontFamily,
    textTheme: textTheme,
    scaffoldBackgroundColor: c.background,
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.text,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: c.text),
    ),
    // Alt menü: seçili sekmenin arkasında yumuşak, nane renkli bir kapsül.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.background,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.mintLight,
      indicatorShape: const StadiumBorder(),
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelMedium?.copyWith(color: c.textMuted),
      ),
      height: 72,
    ),
    dividerTheme: DividerThemeData(color: c.border, thickness: 2),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: rounded16,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.blueText,
        textStyle: textTheme.labelLarge,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: rounded16),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStatePropertyAll(BorderSide(color: c.border, width: 2)),
        shape: WidgetStatePropertyAll(rounded16),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.blueLight : c.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.blueText : c.textMuted,
        ),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.border, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.border, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.blue, width: 2),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: c.textMuted,
      titleTextStyle: textTheme.titleSmall?.copyWith(color: c.text),
      subtitleTextStyle: textTheme.bodySmall?.copyWith(color: c.textMuted),
    ),
  );
}
