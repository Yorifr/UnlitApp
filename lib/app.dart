import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_info.dart';
import 'app_state.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme.dart';

/// Uygulamanın kök bileşeni: tema, dil ve ilk ekran burada ayarlanır.
class UnlitApp extends StatelessWidget {
  const UnlitApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark), // Telefon koyu moddaysa
      // Arayüz dili Türkçe: Flutter'ın kendi yazıları da ("Geri", "Kapat"
      // gibi buton açıklamaları) Türkçe olsun.
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _RootScreen(state: state),
    );
  }
}

/// Onboarding bitmediyse onboarding'i, bittiyse ana ekranı gösterir.
/// AppState değişince (ör. onboarding bitti, veriler silindi) kendini yeniler.
class _RootScreen extends StatelessWidget {
  const _RootScreen({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => state.onboardingDone
          ? HomeScreen(state: state)
          : OnboardingScreen(state: state),
    );
  }
}
