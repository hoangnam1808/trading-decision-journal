import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import 'add_trade_flow.dart';
import 'analyst_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'trades_list_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int idx = 0;

  bool get _showAddFab {
    return idx == 0 || idx == 1;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pages = const [
      DashboardScreen(),
      TradesListScreen(),
      AddTradeFlow(),
      EquityScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeOut,
          child: IndexedStack(
            key: ValueKey(idx),
            index: idx,
            children: pages,
          ),
        ),
      ),
      floatingActionButton: _showAddFab
          ? FloatingActionButton.extended(
        heroTag: 'app_shell_add_trade_fab',
        onPressed: () => setState(() => idx = 2),
        icon: const Icon(Icons.add_rounded),
        label: Text(s.addTradeFab),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: theme.navigationBarTheme.backgroundColor ??
                (isDark ? const Color(0xFF0F172A) : Colors.white),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.22 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            height: 74,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            selectedIndex: idx,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (i) => setState(() => idx = i),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: const Icon(Icons.dashboard_rounded),
                label: s.dashboard,
              ),
              NavigationDestination(
                icon: const Icon(Icons.receipt_long_outlined),
                selectedIcon: const Icon(Icons.receipt_long_rounded),
                label: s.trades,
              ),
              NavigationDestination(
                icon: const Icon(Icons.add_circle_outline_rounded),
                selectedIcon: const Icon(Icons.add_circle_rounded),
                label: s.add,
              ),
              NavigationDestination(
                icon: const Icon(Icons.insights_outlined),
                selectedIcon: const Icon(Icons.insights_rounded),
                label: s.analyst,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: const Icon(Icons.person_rounded),
                label: s.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}