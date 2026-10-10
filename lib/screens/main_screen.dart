import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import 'profile_tab.dart';
import 'stats_tab.dart';
import 'today_tab.dart';

/// Onboarding'den sonraki ana iskelet: alttaki menü + 3 sekme.
///
/// - Bugün: maskot, görevler, erteleme, bugünkü sigaralar
/// - İstatistik: sayılar, grafik, para/süre/yaşam tahmini
/// - Profil: seri, XP, ayarlar
class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.state});

  final AppState state;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;

  /// Her dakika ekranı yeniler ("35 dk önce" yazıları, gece yarısında
  /// yeni görevler için). Yeni sigara gelince zaten AppState yeniler.
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Geniş ekranlarda (bilgisayar tarayıcısı) içerik çok yayılmasın.
            constraints: const BoxConstraints(maxWidth: 560),
            child: IndexedStack(
              index: _tab,
              children: [
                TodayTab(state: state),
                StatsTab(state: state),
                ProfileTab(state: state),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, size: 28),
            selectedIcon: Icon(Icons.home_rounded, size: 28),
            label: 'Bugün',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, size: 28),
            selectedIcon: Icon(Icons.bar_chart_rounded, size: 28),
            label: 'İstatistik',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, size: 28),
            selectedIcon: Icon(Icons.person_rounded, size: 28),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
