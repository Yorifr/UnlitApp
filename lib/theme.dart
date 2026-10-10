import 'package:flutter/material.dart';

/// Uygulamanın renk paleti.
///
/// Duolingo'dan ilham alan canlı, düz (gölgesiz, geçişsiz) renkler.
/// Her rengin bir de "koyu" eşi var: tok butonların alt kenarı
/// (3 boyutlu görünen gölge) bu koyu renkle çizilir.
///
/// Kullanım: `final colors = AppColors.of(context);` → `colors.green`
class AppColors {
  const AppColors({
    required this.green,
    required this.greenButton,
    required this.greenShadow,
    required this.greenLight,
    required this.greenText,
    required this.blue,
    required this.blueShadow,
    required this.blueLight,
    required this.blueText,
    required this.gold,
    required this.goldShadow,
    required this.goldLight,
    required this.orange,
    required this.orangeLight,
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

  /// Parlak yeşil: ilerleme çubukları, ikonlar, maskot.
  final Color green;

  /// Buton yeşili: üstündeki beyaz yazı okunsun diye biraz daha koyu.
  final Color greenButton;
  final Color greenShadow;
  final Color greenLight;

  /// Beyaz zemin üstünde yeşil YAZI için (okunaklı koyu yeşil).
  final Color greenText;

  /// Mavi: seçili seçenekler, erteleme, bilgi.
  final Color blue;
  final Color blueShadow;
  final Color blueLight;
  final Color blueText;

  /// Altın sarısı: XP (puan).
  final Color gold;
  final Color goldShadow;
  final Color goldLight;

  /// Turuncu: seri (alev).
  final Color orange;
  final Color orangeLight;

  /// Mor: rozetler, özel anlar.
  final Color purple;
  final Color purpleLight;

  /// Kırmızı: SADECE "tümünü sil" gibi tehlikeli işlemler için.
  /// Kullanıcının sigara davranışını göstermek için ASLA kullanma.
  final Color red;
  final Color redShadow;

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color disabled;
  final Color disabledText;

  static const light = AppColors(
    green: Color(0xFF58C41A),
    greenButton: Color(0xFF46A302),
    greenShadow: Color(0xFF357C01),
    greenLight: Color(0xFFE3F7D3),
    greenText: Color(0xFF2E7A05),
    blue: Color(0xFF1CB0F6),
    blueShadow: Color(0xFF1278B0),
    blueLight: Color(0xFFDDF4FF),
    blueText: Color(0xFF1477B0),
    gold: Color(0xFFFFC21A),
    goldShadow: Color(0xFFE09B00),
    goldLight: Color(0xFFFFF4D1),
    orange: Color(0xFFFF9600),
    orangeLight: Color(0xFFFFEBD1),
    purple: Color(0xFFB27CF7),
    purpleLight: Color(0xFFF1E6FF),
    red: Color(0xFFE5484D),
    redShadow: Color(0xFFB8353A),
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF7F7F7),
    border: Color(0xFFE5E5E5),
    text: Color(0xFF4B4B4B),
    textMuted: Color(0xFF6F6F6F),
    disabled: Color(0xFFE5E5E5),
    disabledText: Color(0xFFAFAFAF),
  );

  static const dark = AppColors(
    green: Color(0xFF79D63C),
    greenButton: Color(0xFF58A700),
    greenShadow: Color(0xFF3E7A00),
    greenLight: Color(0xFF1F3A1A),
    greenText: Color(0xFF8FE05A),
    blue: Color(0xFF49C0F8),
    blueShadow: Color(0xFF1A7DB5),
    blueLight: Color(0xFF16313F),
    blueText: Color(0xFF7DD3FB),
    gold: Color(0xFFFFC83D),
    goldShadow: Color(0xFFC79200),
    goldLight: Color(0xFF3A3218),
    orange: Color(0xFFFFA534),
    orangeLight: Color(0xFF3D2A14),
    purple: Color(0xFFC9A2FF),
    purpleLight: Color(0xFF2E2440),
    red: Color(0xFFFF6B70),
    redShadow: Color(0xFFB8353A),
    background: Color(0xFF131F24),
    surface: Color(0xFF131F24),
    surfaceAlt: Color(0xFF202F36),
    border: Color(0xFF37464F),
    text: Color(0xFFF1F7FB),
    textMuted: Color(0xFFA9BAC3),
    disabled: Color(0xFF37464F),
    disabledText: Color(0xFF6B7F88),
  );

  /// Telefonun açık/koyu moduna uygun paleti verir.
  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Uygulamanın yazı tipi: yuvarlak hatlı, samimi "Nunito".
/// Dosyaları assets/fonts/ içinde; internetten indirilmez (gizlilik).
const String appFontFamily = 'Nunito';

/// Açık veya koyu tema oluşturur (telefonun ayarına göre seçilir).
ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;

  final scheme =
      ColorScheme.fromSeed(seedColor: c.green, brightness: brightness).copyWith(
        primary: c.greenButton,
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
    // Alt menü: seçili sekmenin etrafında mavi çerçeve (Duolingo gibi).
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.background,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.blueLight,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.blue, width: 2),
      ),
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
