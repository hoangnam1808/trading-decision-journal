import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'state/app_settings.dart';
import 'state/trades_store.dart';
import 'ui/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettings()..load()),
        ChangeNotifierProvider(create: (_) => TradesStore()..load()),
      ],
      child: const DecisionJournalApp(),
    ),
  );
}

class DecisionJournalApp extends StatelessWidget {
  const DecisionJournalApp({super.key});

  static const _seedColor = Color(0xFF2563EB);

  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );

    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,

      scaffoldBackgroundColor:
      isDark ? const Color(0xFF0B1220) : const Color(0xFFF6F8FB),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? const Color(0xFF0B1220) : const Color(0xFFF6F8FB),
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? const Color(0xFF111827) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF111827) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.4,
          ),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        highlightElevation: 1,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        side: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),

      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.06),
        thickness: 1,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    return MaterialApp(
      key: ValueKey('${settings.lang.code}_${settings.themeMode.name}'),
      title: 'Decision Journal',
      debugShowCheckedModeBanner: false,
      locale: settings.lang.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('vi'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      themeMode: settings.themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const AppShell(),
    );
  }
}