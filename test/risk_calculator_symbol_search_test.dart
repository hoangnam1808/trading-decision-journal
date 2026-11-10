import 'dart:convert';

import 'package:decision_journal/state/app_settings.dart';
import 'package:decision_journal/ui/add_trade_flow.dart';
import 'package:decision_journal/ui/risk_calculator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const symbols = [
    SymbolSpec(
      symbol: 'EURUSD',
      assetClass: 'Forex',
      profitCurrency: 'USD',
      tickSize: 0.0001,
      tickValuePerLot: 10,
      volumeStep: 0.01,
      minVolume: 0.01,
    ),
    SymbolSpec(
      symbol: 'XAUUSD',
      assetClass: 'Metals',
      profitCurrency: 'USD',
      tickSize: 0.01,
      tickValuePerLot: 1,
      volumeStep: 0.01,
      minVolume: 0.01,
    ),
    SymbolSpec(
      symbol: 'BTCUSD',
      assetClass: 'Crypto CFD',
      profitCurrency: 'USD',
      tickSize: 0.01,
      tickValuePerLot: 0.01,
      volumeStep: 0.01,
      minVolume: 0.01,
    ),
  ];

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'exchange_rate_snapshot_v1': jsonEncode(
        ExchangeRateSnapshot(
          fetchedAt: DateTime.now(),
          rateDate: 'test',
          usdBaseRates: const {'EUR': 0.92},
        ).toJson(),
      ),
    });
  });

  test('search handles case, outer spaces, and partial matches', () {
    expect(filterSymbolSpecs(symbols, ''), symbols);
    expect(filterSymbolSpecs(symbols, '  '), symbols);
    expect(filterSymbolSpecs(symbols, '  eUr '), [symbols[0]]);
    expect(filterSymbolSpecs(symbols, 'xAu'), [symbols[1]]);
    expect(filterSymbolSpecs(symbols, 'btc'), [symbols[2]]);
    expect(filterSymbolSpecs(symbols, ' UsD '), symbols);
    expect(filterSymbolSpecs(symbols, 'missing'), isEmpty);
  });

  testWidgets('search filters the picker and cancellation keeps selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppSettings(),
        child: const MaterialApp(
          home: RiskCalculatorScreen(returnResultOnUse: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('symbolSelector'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('symbolSelector')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('symbolSearchField')), ' xAu ');
    await tester.pumpAndSettle();
    expect(find.text('XAUUSD'), findsOneWidget);
    expect(find.text('BTCUSD'), findsNothing);

    await tester.enterText(find.byKey(const Key('symbolSearchField')), 'none');
    await tester.pumpAndSettle();
    expect(find.text('No matching symbols found.'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('No matching symbols found.'), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('symbolSearchField')))
          .controller!
          .text,
      isEmpty,
    );
    Navigator.of(
      tester.element(find.byKey(const Key('symbolSearchField'))),
    ).pop();
    await tester.pumpAndSettle();
    expect(find.text('EURUSD'), findsOneWidget);

    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('symbolSelector'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('symbolSelector')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('symbolSearchField')), 'btc');
    await tester.pumpAndSettle();
    await tester.tap(find.text('BTCUSD'));
    await tester.pumpAndSettle();
    expect(find.text('BTCUSD'), findsOneWidget);

    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('symbolSelector'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('symbolSelector')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('symbolSearchField')), 'xau');
    await tester.pumpAndSettle();
    Navigator.of(
      tester.element(find.byKey(const Key('symbolSearchField'))),
    ).pop();
    await tester.pumpAndSettle();
    expect(find.text('BTCUSD'), findsOneWidget);
  });

  testWidgets('reselecting the current symbol keeps edited broker specs', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppSettings(),
        child: const MaterialApp(
          home: RiskCalculatorScreen(returnResultOnUse: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Advanced broker specs'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Advanced broker specs'));
    await tester.pumpAndSettle();
    final tickValue = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Tick value / lot',
    );
    await Scrollable.ensureVisible(tester.element(tickValue), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.enterText(tickValue, '17');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('symbolSelector')),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('symbolSelector'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('symbolSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'EURUSD'));
    await tester.pumpAndSettle();

    expect(find.text('EURUSD'), findsOneWidget);
    expect(tester.widget<TextField>(tickValue).controller!.text, '17');
  });

  testWidgets('broker switching scopes symbol search in Vietnamese', (
    tester,
  ) async {
    final customProfile = BrokerProfile(
      id: 'test_broker',
      name: 'Demo Broker',
      accountCurrency: 'USD',
      symbols: [
        symbols[0],
        symbols[1],
        const SymbolSpec(
          symbol: 'TESTUSD',
          assetClass: 'Custom',
          profitCurrency: 'USD',
          tickSize: 0.01,
          tickValuePerLot: 1,
          volumeStep: 0.01,
          minVolume: 0.01,
        ),
      ],
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'risk_calculator_custom_profiles_v1',
      jsonEncode([customProfile.toJson()]),
    );

    final settings = AppSettings()..lang = AppLang.vi;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: const MaterialApp(
          home: RiskCalculatorScreen(returnResultOnUse: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('App Default'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Demo Broker').last);
    await tester.pumpAndSettle();

    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('symbolSelector'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('symbolSelector')));
    await tester.pumpAndSettle();
    expect(find.text('Tìm mã giao dịch'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('symbolSearchField')), 'xau');
    await tester.pumpAndSettle();
    expect(find.text('XAUUSD'), findsOneWidget);
    await tester.tap(find.text('XAUUSD'));
    await tester.pumpAndSettle();
    expect(find.text('XAUUSD'), findsOneWidget);

    await Scrollable.ensureVisible(
      tester.element(find.text('Demo Broker')),
      alignment: 0.3,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Demo Broker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('App Default').last);
    await tester.pumpAndSettle();
    expect(find.text('EURUSD'), findsOneWidget);

    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('symbolSelector'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('symbolSelector')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('symbolSearchField')), 'test');
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy mã giao dịch phù hợp.'), findsOneWidget);
    Navigator.of(
      tester.element(find.byKey(const Key('symbolSearchField'))),
    ).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('App Default'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Demo Broker').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('symbolSelector')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('symbolSearchField')), 'test');
    await tester.pumpAndSettle();
    await tester.tap(find.text('TESTUSD'));
    await tester.pumpAndSettle();
    expect(find.text('TESTUSD'), findsOneWidget);
  });

  testWidgets('calculator returns selected symbol and sizing', (tester) async {
    RiskCalculatorFillResult? applied;
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppSettings(),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  applied = await Navigator.of(context)
                      .push<RiskCalculatorFillResult>(
                        MaterialPageRoute(
                          builder: (_) => const RiskCalculatorScreen(),
                        ),
                      );
                },
                child: const Text('Open calculator'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open calculator'));
    await tester.pumpAndSettle();

    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('symbolSelector'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('symbolSelector')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('symbolSearchField')), 'xau');
    await tester.pumpAndSettle();
    await tester.tap(find.text('XAUUSD'));
    await tester.pumpAndSettle();

    final entry = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == 'Entry',
    );
    final stop = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == 'Stop loss',
    );
    await tester.enterText(entry, '2000');
    await tester.enterText(stop, '1990');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use in New Trade'));
    await tester.pumpAndSettle();

    expect(applied?.symbol, 'XAUUSD');
    expect(applied?.riskMoney, 100);
    expect(applied?.suggestedVolume, closeTo(0.1, 0.000001));
    expect(applied?.actualRisk, closeTo(100, 0.000001));
  });

  testWidgets('Add Trade receives the selected symbol and sizing', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppSettings(),
        child: const MaterialApp(home: AddTradeFlow()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Open 1R Calculator'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Open 1R Calculator'));
    await tester.pumpAndSettle();

    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('symbolSelector'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('symbolSelector')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('symbolSearchField')), 'xau');
    await tester.pumpAndSettle();
    await tester.tap(find.text('XAUUSD'));
    await tester.pumpAndSettle();

    final entry = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == 'Entry',
    );
    final stop = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == 'Stop loss',
    );
    await tester.enterText(entry, '2000');
    await tester.enterText(stop, '1990');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use in New Trade'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Pair / Symbol'),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    final symbolField = find.widgetWithText(TextFormField, 'Pair / Symbol');
    expect(
      tester.widget<TextFormField>(symbolField).controller!.text,
      'XAUUSD',
    );
    await tester.scrollUntilVisible(
      find.text('Position sizing from 1R Calculator'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Position sizing from 1R Calculator'), findsOneWidget);
    expect(
      find.textContaining('Volume: 0.1 · Actual risk: \$100'),
      findsOneWidget,
    );
  });
}
