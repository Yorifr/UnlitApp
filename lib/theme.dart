import 'package:flutter/material.dart';

/// Uygulamanın ana rengi: sakin, "temiz hava" hissi veren bir yeşil-mavi.
/// Bunu değiştirirsen tüm uygulamanın renkleri buna göre yeniden üretilir.
const Color brandSeedColor = Color(0xFF2F7D6D);

/// Açık veya koyu tema oluşturur (telefonun ayarına göre seçilir).
ThemeData buildTheme(Brightness brightness) {
  // Material 3: tek bir "tohum" renkten uyumlu bir renk paleti üretir.
  final scheme = ColorScheme.fromSeed(
    seedColor: brandSeedColor,
    brightness: brightness,
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    // Kartlar: gölgesiz, yuvarlak köşeli, hafif renkli.
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
