import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../state/app_settings.dart';

enum RiskInputMode {
  percent,
  fixedMoney,
}

class SymbolSpec {
  final String symbol;
  final String assetClass;
  final String profitCurrency;
  final double tickSize;
  final double tickValuePerLot;
  final double volumeStep;
  final double minVolume;

  const SymbolSpec({
    required this.symbol,
    required this.assetClass,
    required this.profitCurrency,
    required this.tickSize,
    required this.tickValuePerLot,
    required this.volumeStep,
    required this.minVolume,
  });

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'assetClass': assetClass,
      'profitCurrency': profitCurrency,
      'tickSize': tickSize,
      'tickValuePerLot': tickValuePerLot,
      'volumeStep': volumeStep,
      'minVolume': minVolume,
    };
  }

  static SymbolSpec? fromJson(Map<String, dynamic> json) {
    try {
      return SymbolSpec(
        symbol: json['symbol'] as String,
        assetClass: json['assetClass'] as String? ?? 'Custom',
        profitCurrency: json['profitCurrency'] as String? ?? 'USD',
        tickSize: (json['tickSize'] as num).toDouble(),
        tickValuePerLot: (json['tickValuePerLot'] as num).toDouble(),
        volumeStep: (json['volumeStep'] as num).toDouble(),
        minVolume: (json['minVolume'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}

class BrokerProfile {
  final String id;
  final String name;
  final String accountCurrency;
  final List<SymbolSpec> symbols;
  final bool isDefault;

  const BrokerProfile({
    required this.id,
    required this.name,
    required this.accountCurrency,
    required this.symbols,
    this.isDefault = false,
  });

  BrokerProfile copyWith({
    String? id,
    String? name,
    String? accountCurrency,
    List<SymbolSpec>? symbols,
    bool? isDefault,
  }) {
    return BrokerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      accountCurrency: accountCurrency ?? this.accountCurrency,
      symbols: symbols ?? this.symbols,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'accountCurrency': accountCurrency,
      'symbols': symbols.map((e) => e.toJson()).toList(),
      'isDefault': false,
    };
  }

  static BrokerProfile? fromJson(Map<String, dynamic> json) {
    try {
      final rawSymbols = json['symbols'] as List<dynamic>;
      final parsedSymbols = rawSymbols
          .map((e) => SymbolSpec.fromJson(e as Map<String, dynamic>))
          .whereType<SymbolSpec>()
          .toList();

      if (parsedSymbols.isEmpty) return null;

      return BrokerProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        accountCurrency: json['accountCurrency'] as String? ?? 'USD',
        symbols: parsedSymbols,
        isDefault: false,
      );
    } catch (_) {
      return null;
    }
  }
}

class ExchangeRateSnapshot {
  final DateTime fetchedAt;
  final String rateDate;
  final Map<String, double> usdBaseRates;

  const ExchangeRateSnapshot({
    required this.fetchedAt,
    required this.rateDate,
    required this.usdBaseRates,
  });

  bool get isStale {
    return DateTime.now().difference(fetchedAt) > const Duration(hours: 24);
  }

  double? conversionRate({
    required String from,
    required String to,
  }) {
    final fromCode = from.toUpperCase().trim();
    final toCode = to.toUpperCase().trim();

    if (fromCode == toCode) return 1.0;

    final fromToUsd = _toUsdRate(fromCode);
    final usdToTarget = _usdToCurrencyRate(toCode);

    if (fromToUsd == null || usdToTarget == null) return null;

    return fromToUsd * usdToTarget;
  }

  double? _toUsdRate(String currency) {
    if (currency == 'USD') return 1.0;

    final usdToCurrency = usdBaseRates[currency];
    if (usdToCurrency == null || usdToCurrency <= 0) return null;

    return 1.0 / usdToCurrency;
  }

  double? _usdToCurrencyRate(String currency) {
    if (currency == 'USD') return 1.0;

    final rate = usdBaseRates[currency];
    if (rate == null || rate <= 0) return null;

    return rate;
  }

  Map<String, dynamic> toJson() {
    return {
      'fetchedAt': fetchedAt.toIso8601String(),
      'rateDate': rateDate,
      'usdBaseRates': usdBaseRates,
    };
  }

  static ExchangeRateSnapshot? fromJson(Map<String, dynamic> json) {
    try {
      final rawRates = json['usdBaseRates'] as Map<String, dynamic>;

      return ExchangeRateSnapshot(
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
        rateDate: json['rateDate'] as String? ?? '',
        usdBaseRates: rawRates.map(
              (key, value) => MapEntry(
            key.toUpperCase(),
            (value as num).toDouble(),
          ),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}

class ExchangeRateService {
  static const _cacheKey = 'exchange_rate_snapshot_v1';

  static const _supportedCurrencies = [
    'EUR',
    'GBP',
    'JPY',
    'CHF',
    'CAD',
    'AUD',
    'NZD',
  ];
  ExchangeRateSnapshot builtInFallback() {
    return ExchangeRateSnapshot(
      fetchedAt: DateTime(2000, 1, 1),
      rateDate: 'built_in_estimate',
      usdBaseRates: const {
        'EUR': 0.92,
        'GBP': 0.79,
        'JPY': 155.0,
        'CHF': 0.90,
        'CAD': 1.37,
        'AUD': 1.52,
        'NZD': 1.66,
      },
    );
  }

  Future<ExchangeRateSnapshot?> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      return ExchangeRateSnapshot.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSnapshot(ExchangeRateSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(snapshot.toJson()));
  }

  Future<ExchangeRateSnapshot> fetchLatestUsdBaseRates() async {
    final uri = Uri.https(
      'api.frankfurter.dev',
      '/v2/rates',
      {
        'base': 'USD',
        'quotes': _supportedCurrencies.join(','),
      },
    );

    final response = await http.get(uri).timeout(
      const Duration(seconds: 10),
    );

    if (response.statusCode != 200) {
      throw Exception('Rate update failed');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final rawRates = body['rates'] as Map<String, dynamic>;

    final rates = rawRates.map(
          (key, value) => MapEntry(
        key.toUpperCase(),
        (value as num).toDouble(),
      ),
    );

    return ExchangeRateSnapshot(
      fetchedAt: DateTime.now(),
      rateDate: body['date']?.toString() ?? '',
      usdBaseRates: rates,
    );
  }

  Future<ExchangeRateSnapshot> refreshAndSave() async {
    final snapshot = await fetchLatestUsdBaseRates();
    await saveSnapshot(snapshot);
    return snapshot;
  }
}

class RiskCalculationResult {
  final double riskMoney;
  final double slDistance;
  final double conversionRate;
  final double tickValueInAccountCurrency;
  final double riskPerLot;
  final double suggestedVolume;
  final double actualRisk;
  final double? rr;
  final double? potentialProfit;
  final String? error;

  const RiskCalculationResult({
    required this.riskMoney,
    required this.slDistance,
    required this.conversionRate,
    required this.tickValueInAccountCurrency,
    required this.riskPerLot,
    required this.suggestedVolume,
    required this.actualRisk,
    this.rr,
    this.potentialProfit,
    this.error,
  });

  bool get hasError => error != null;
}

class RiskCalculatorFillResult {
  final String profileName;
  final String accountCurrency;
  final String symbol;
  final double entry;
  final double stopLoss;
  final double? target;
  final double riskMoney;
  final double actualRisk;
  final double suggestedVolume;

  const RiskCalculatorFillResult({
    required this.profileName,
    required this.accountCurrency,
    required this.symbol,
    required this.entry,
    required this.stopLoss,
    required this.target,
    required this.riskMoney,
    required this.actualRisk,
    required this.suggestedVolume,
  });
}

class RiskCalculatorScreen extends StatefulWidget {
  final bool returnResultOnUse;

  const RiskCalculatorScreen({
    super.key,
    this.returnResultOnUse = true,
  });

  @override
  State<RiskCalculatorScreen> createState() => _RiskCalculatorScreenState();
}

class _RiskCalculatorScreenState extends State<RiskCalculatorScreen> {
  static const _customProfilesKey = 'risk_calculator_custom_profiles_v1';

  static const List<SymbolSpec> _defaultSymbols = [
    SymbolSpec(symbol: 'EURUSD', assetClass: 'Forex', profitCurrency: 'USD', tickSize: 0.0001, tickValuePerLot: 10, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'GBPUSD', assetClass: 'Forex', profitCurrency: 'USD', tickSize: 0.0001, tickValuePerLot: 10, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'AUDUSD', assetClass: 'Forex', profitCurrency: 'USD', tickSize: 0.0001, tickValuePerLot: 10, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'NZDUSD', assetClass: 'Forex', profitCurrency: 'USD', tickSize: 0.0001, tickValuePerLot: 10, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'USDJPY', assetClass: 'Forex', profitCurrency: 'JPY', tickSize: 0.01, tickValuePerLot: 1000, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'USDCHF', assetClass: 'Forex', profitCurrency: 'CHF', tickSize: 0.0001, tickValuePerLot: 10, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'USDCAD', assetClass: 'Forex', profitCurrency: 'CAD', tickSize: 0.0001, tickValuePerLot: 10, volumeStep: 0.01, minVolume: 0.01),

    SymbolSpec(symbol: 'AUDCAD', assetClass: 'Forex', profitCurrency: 'CAD', tickSize: 0.0001, tickValuePerLot: 10, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'AUDCHF', assetClass: 'Forex', profitCurrency: 'CHF', tickSize: 0.0001, tickValuePerLot: 10, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'AUDJPY', assetClass: 'Forex', profitCurrency: 'JPY', tickSize: 0.01, tickValuePerLot: 1000, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'AUDNZD', assetClass: 'Forex', profitCurrency: 'NZD', tickSize: 0.0001, tickValuePerLot: 10, volumeStep: 0.01, minVolume: 0.01),

    SymbolSpec(symbol: 'CADCHF', assetClass: 'Forex', profitCurrency: 'CHF', tickSize: 0.0001, tickValuePerLot: 10, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'CADJPY', assetClass: 'Forex', profitCurrency: 'JPY', tickSize: 0.01, tickValuePerLot: 1000, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'CHFJPY', assetClass: 'Forex', profitCurrency: 'JPY', tickSize: 0.01, tickValuePerLot: 1000, volumeStep: 0.01, minVolume: 0.01),

    SymbolSpec(symbol: 'EURAUD', assetClass: 'Forex', profitCurrency: 'AUD', tickSize: 0.0001, tickValuePerLot: 10, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'EURCAD', assetClass: 'Forex', profitCurrency: 'CAD', tickSize: 0.0001, tickValuePerLot: 10, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'EURCHF', assetClass: 'Forex', profitCurrency: 'CHF', tickSize: 0.0001, tickValuePerLot: 10, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'EURGBP', assetClass: 'Forex', profitCurrency: 'GBP', tickSize: 0.0001, tickValuePerLot: 10, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'EURJPY', assetClass: 'Forex', profitCurrency: 'JPY', tickSize: 0.01, tickValuePerLot: 1000, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'EURNZD', assetClass: 'Forex', profitCurrency: 'NZD', tickSize: 0.0001, tickValuePerLot: 10, volumeStep: 0.01, minVolume: 0.01),

    SymbolSpec(symbol: 'GBPAUD', assetClass: 'Forex', profitCurrency: 'AUD', tickSize: 0.0001, tickValuePerLot: 10, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'GBPCAD', assetClass: 'Forex', profitCurrency: 'CAD', tickSize: 0.0001, tickValuePerLot: 10, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'GBPCHF', assetClass: 'Forex', profitCurrency: 'CHF', tickSize: 0.0001, tickValuePerLot: 10, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'GBPJPY', assetClass: 'Forex', profitCurrency: 'JPY', tickSize: 0.01, tickValuePerLot: 1000, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'GBPNZD', assetClass: 'Forex', profitCurrency: 'NZD', tickSize: 0.0001, tickValuePerLot: 10, volumeStep: 0.01, minVolume: 0.01),

    SymbolSpec(symbol: 'NZDCAD', assetClass: 'Forex', profitCurrency: 'CAD', tickSize: 0.0001, tickValuePerLot: 10, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'NZDCHF', assetClass: 'Forex', profitCurrency: 'CHF', tickSize: 0.0001, tickValuePerLot: 10, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'NZDJPY', assetClass: 'Forex', profitCurrency: 'JPY', tickSize: 0.01, tickValuePerLot: 1000, volumeStep: 0.01, minVolume: 0.01),

    SymbolSpec(symbol: 'XAUUSD', assetClass: 'Metals', profitCurrency: 'USD', tickSize: 0.01, tickValuePerLot: 1, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'XAGUSD', assetClass: 'Metals', profitCurrency: 'USD', tickSize: 0.001, tickValuePerLot: 5, volumeStep: 0.01, minVolume: 0.01),

    SymbolSpec(symbol: 'US30.cash', assetClass: 'Index CFD', profitCurrency: 'USD', tickSize: 0.01, tickValuePerLot: 0.01, volumeStep: 0.1, minVolume: 0.1),
    SymbolSpec(symbol: 'US100.cash', assetClass: 'Index CFD', profitCurrency: 'USD', tickSize: 0.01, tickValuePerLot: 0.01, volumeStep: 0.1, minVolume: 0.1),
    SymbolSpec(symbol: 'US500.cash', assetClass: 'Index CFD', profitCurrency: 'USD', tickSize: 0.01, tickValuePerLot: 0.01, volumeStep: 0.1, minVolume: 0.1),
    SymbolSpec(symbol: 'UK100.cash', assetClass: 'Index CFD', profitCurrency: 'GBP', tickSize: 0.01, tickValuePerLot: 0.01, volumeStep: 0.1, minVolume: 0.1),
    SymbolSpec(symbol: 'GER40.cash', assetClass: 'Index CFD', profitCurrency: 'EUR', tickSize: 0.01, tickValuePerLot: 0.01, volumeStep: 0.1, minVolume: 0.1),
    SymbolSpec(symbol: 'JP225.cash', assetClass: 'Index CFD', profitCurrency: 'JPY', tickSize: 1, tickValuePerLot: 1, volumeStep: 0.1, minVolume: 0.1),

    SymbolSpec(symbol: 'USOIL.cash', assetClass: 'Energy CFD', profitCurrency: 'USD', tickSize: 0.001, tickValuePerLot: 0.1, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'NATGAS.cash', assetClass: 'Energy CFD', profitCurrency: 'USD', tickSize: 0.001, tickValuePerLot: 1, volumeStep: 0.01, minVolume: 0.01),

    SymbolSpec(symbol: 'BTCUSD', assetClass: 'Crypto CFD', profitCurrency: 'USD', tickSize: 0.01, tickValuePerLot: 0.01, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'ETHUSD', assetClass: 'Crypto CFD', profitCurrency: 'USD', tickSize: 0.01, tickValuePerLot: 1, volumeStep: 0.01, minVolume: 0.01),
    SymbolSpec(symbol: 'XRPUSD', assetClass: 'Crypto CFD', profitCurrency: 'USD', tickSize: 0.0001, tickValuePerLot: 1, volumeStep: 1, minVolume: 1),
  ];

  final _rateService = ExchangeRateService();

  final _accountController = TextEditingController();
  final _riskPercentController = TextEditingController(text: '1');
  final _fixedRiskController = TextEditingController();

  final _entryController = TextEditingController();
  final _stopController = TextEditingController();
  final _targetController = TextEditingController();

  final _tickSizeController = TextEditingController(text: '0.01');
  final _tickValueController = TextEditingController(text: '1');
  final _volumeStepController = TextEditingController(text: '0.01');
  final _minVolumeController = TextEditingController(text: '0.01');

  final List<String> _currencies = const [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CHF',
    'CAD',
    'AUD',
    'NZD',
  ];

  RiskInputMode _riskMode = RiskInputMode.percent;

  late List<BrokerProfile> _profiles;
  late BrokerProfile _selectedProfile;
  late SymbolSpec _selectedSpec;

  ExchangeRateSnapshot? _rates;
  bool _isRefreshingRates = false;
  String? _rateError;

  String _profitCurrency = 'USD';

  List<BrokerProfile> get _defaultProfiles {
    return const [
      BrokerProfile(
        id: 'app_default_usd',
        name: 'App Default',
        accountCurrency: 'USD',
        symbols: _defaultSymbols,
        isDefault: true,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();

    _syncDefaultRiskFromProfile();

    _profiles = _defaultProfiles;
    _selectedProfile = _profiles.first;
    _selectedSpec = _selectedProfile.symbols.first;
    _applySpec(_selectedSpec);

    for (final controller in [
      _accountController,
      _riskPercentController,
      _fixedRiskController,
      _entryController,
      _stopController,
      _targetController,
      _tickSizeController,
      _tickValueController,
      _volumeStepController,
      _minVolumeController,
    ]) {
      controller.addListener(() => setState(() {}));
    }

    _loadCustomProfiles();
    _initRates();
  }

  @override
  void dispose() {
    _accountController.dispose();
    _riskPercentController.dispose();
    _fixedRiskController.dispose();
    _entryController.dispose();
    _stopController.dispose();
    _targetController.dispose();
    _tickSizeController.dispose();
    _tickValueController.dispose();
    _volumeStepController.dispose();
    _minVolumeController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customProfilesKey);

    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final custom = decoded
          .map((e) => BrokerProfile.fromJson(e as Map<String, dynamic>))
          .whereType<BrokerProfile>()
          .toList();

      if (!mounted) return;

      final selectedId = _selectedProfile.id;

      setState(() {
        _profiles = [
          ..._defaultProfiles,
          ...custom,
        ];

        _selectedProfile = _findProfileById(selectedId) ?? _profiles.first;
        _selectedSpec = _selectedProfile.symbols.first;
        _applySpec(_selectedSpec);
      });
    } catch (_) {
      return;
    }
  }

  BrokerProfile? _findProfileById(String id) {
    for (final profile in _profiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  Future<void> _saveCustomProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final customProfiles = _profiles.where((p) => !p.isDefault).toList();
    await prefs.setString(
      _customProfilesKey,
      jsonEncode(customProfiles.map((e) => e.toJson()).toList()),
    );
  }
  void _syncDefaultRiskFromProfile() {
    final cashPerR = context.read<AppSettings>().cashPerR;
    final defaultBalance = cashPerR * 100;

    _accountController.text = _formatNumber(defaultBalance);
    _fixedRiskController.text = _formatNumber(cashPerR);
    _riskPercentController.text = '1';
  }
  Future<void> _initRates() async {
    final cached = await _rateService.loadCached();

    if (!mounted) return;

    final initialRates = cached ?? _rateService.builtInFallback();

    setState(() {
      _rates = initialRates;
    });

    if (cached == null || cached.isStale) {
      await _refreshRates(showSnack: false);
    }
  }

  Future<void> _refreshRates({bool showSnack = true}) async {
    if (_isRefreshingRates) return;

    setState(() {
      _isRefreshingRates = true;
      _rateError = null;
    });

    try {
      final fresh = await _rateService.refreshAndSave();

      if (!mounted) return;

      setState(() {
        _rates = fresh;
        _rateError = null;
      });

      if (showSnack) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exchange rates updated.')),
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _rateError = showSnack
            ? 'Could not update rates. Using saved rates if available.'
            : null;
      });

      if (showSnack) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update rates. Using saved rates if available.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshingRates = false);
      }
    }
  }

  void _applySpec(SymbolSpec spec) {
    _profitCurrency = spec.profitCurrency;
    _tickSizeController.text = _formatNumber(spec.tickSize);
    _tickValueController.text = _formatNumber(spec.tickValuePerLot);
    _volumeStepController.text = _formatNumber(spec.volumeStep);
    _minVolumeController.text = _formatNumber(spec.minVolume);
  }

  double _num(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;
  }

  RiskCalculationResult _calculate() {
    final account = _num(_accountController);
    final riskPercent = _num(_riskPercentController);
    final fixedRisk = _num(_fixedRiskController);

    final entry = _num(_entryController);
    final stop = _num(_stopController);
    final target = _num(_targetController);

    final tickSize = _num(_tickSizeController);
    final tickValue = _num(_tickValueController);
    final volumeStep = _num(_volumeStepController);
    final minVolume = _num(_minVolumeController);

    final accountCurrency = _selectedProfile.accountCurrency;

    final riskMoney = _riskMode == RiskInputMode.percent
        ? account * riskPercent / 100
        : fixedRisk;

    if (riskMoney <= 0) {
      return _empty(error: 'Risk money must be greater than 0.');
    }

    if (entry <= 0 || stop <= 0) {
      return _empty(error: 'Enter both entry and stop loss.');
    }

    final slDistance = (entry - stop).abs();

    if (slDistance <= 0) {
      return _empty(error: 'Stop loss cannot be equal to entry.');
    }

    if (tickSize <= 0 || tickValue <= 0) {
      return _empty(error: 'Symbol specs need tick size and tick value.');
    }

    if (volumeStep <= 0 || minVolume < 0) {
      return _empty(error: 'Volume step must be greater than 0.');
    }

    final conversionRate = _rates?.conversionRate(
      from: _profitCurrency,
      to: accountCurrency,
    );

    if (_profitCurrency != accountCurrency && conversionRate == null) {
      return _empty(
        error:
        'Rates are required for this symbol. Connect internet once or try again.',
      );
    }

    final safeConversionRate = conversionRate ?? 1.0;
    final tickValueInAccountCurrency = tickValue * safeConversionRate;

    final ticks = slDistance / tickSize;
    final riskPerLot = ticks * tickValueInAccountCurrency;

    if (riskPerLot <= 0) {
      return _empty(error: 'Risk per lot cannot be calculated.');
    }

    final rawVolume = riskMoney / riskPerLot;
    final roundedVolume = _floorToStep(rawVolume, volumeStep);
    final double suggestedVolume = roundedVolume >= minVolume ? roundedVolume : 0.0;
    final double actualRisk = suggestedVolume * riskPerLot;

    double? rr;
    double? potentialProfit;

    if (target > 0) {
      final targetDistance = (target - entry).abs();
      if (targetDistance > 0) {
        rr = targetDistance / slDistance;
        potentialProfit = actualRisk * rr;
      }
    }

    return RiskCalculationResult(
      riskMoney: riskMoney,
      slDistance: slDistance,
      conversionRate: safeConversionRate,
      tickValueInAccountCurrency: tickValueInAccountCurrency,
      riskPerLot: riskPerLot,
      suggestedVolume: suggestedVolume,
      actualRisk: actualRisk,
      rr: rr,
      potentialProfit: potentialProfit,
    );
  }

  RiskCalculationResult _empty({String? error}) {
    return RiskCalculationResult(
      riskMoney: 0,
      slDistance: 0,
      conversionRate: 1,
      tickValueInAccountCurrency: 0,
      riskPerLot: 0,
      suggestedVolume: 0,
      actualRisk: 0,
      error: error,
    );
  }

  double _floorToStep(double value, double step) {
    if (value <= 0 || step <= 0) return 0;
    final units = (value / step).floor();
    return double.parse((units * step).toStringAsFixed(8));
  }
  String _tr(BuildContext context, String en, String vi) {
    return S.of(context).isVi ? vi : en;
  }
  String _formatMoney(double value, [String? currency]) {
    final c = currency ?? _selectedProfile.accountCurrency;

    if (c == 'USD') {
      return '\$${value.toStringAsFixed(2)}';
    }

    return '$c ${value.toStringAsFixed(2)}';
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value
        .toStringAsFixed(8)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _formatVolume(double value) {
    if (value <= 0) return '0';
    return value
        .toStringAsFixed(4)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year.toString();
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');

    return '$d/$m/$y $h:$min';
  }

  String _rateStatusText() {
    final rates = _rates;

    if (_isRefreshingRates && rates == null) {
      return 'Updating rates...';
    }

    if (rates == null) {
      return 'Using built-in rate estimates';
    }

    if (rates.rateDate == 'built_in_estimate') {
      return _isRefreshingRates
          ? 'Updating rates...'
          : 'Using built-in rate estimates';
    }

    if (rates.isStale) {
      return 'Using saved rates from ${_formatDateTime(rates.fetchedAt)}';
    }

    return 'Updated ${_formatDateTime(rates.fetchedAt)}';
  }

  void _showBrokerProfileGuide() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr(
                    context,
                    'How broker profiles work',
                    'Cách dùng broker / nền tảng',
                  ),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _tr(
                    context,
                    'A broker/platform profile stores symbol specifications used to calculate position size. App Default is enough for quick estimates.',
                    'Broker / nền tảng lưu thông số symbol dùng để tính khối lượng vào lệnh. App Default là đủ để tính nhanh.',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _tr(
                    context,
                    'For more accurate sizing, create your own profile using the values from MT5 → Symbol Specification or your broker contract details.',
                    'Để tính chính xác hơn, hãy tạo profile riêng bằng thông số trong MT5 → Symbol Specification hoặc contract details của broker.',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.18),
                    ),
                  ),
                  child: Text(
                    _tr(
                      context,
                      'Tip: If you are not sure, keep App Default and verify volume with your broker before trading.',
                      'Gợi ý: Nếu chưa chắc, cứ dùng App Default và kiểm tra lại volume với broker trước khi vào lệnh.',
                    ),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCustomProfileSheet({
    BrokerProfile? addSymbolToProfile,
  }) async {
    final isAddingSymbol =
        addSymbolToProfile != null && !addSymbolToProfile.isDefault;

    final profileNameCtrl = TextEditingController(
      text: addSymbolToProfile?.name ?? '',
    );
    final symbolCtrl = TextEditingController();
    final assetClassCtrl = TextEditingController(text: 'Custom');
    final tickSizeCtrl = TextEditingController(text: '0.0001');
    final tickValueCtrl = TextEditingController(text: '10');
    final volumeStepCtrl = TextEditingController(text: '0.01');
    final minVolumeCtrl = TextEditingController(text: '0.01');

    String accountCurrency = addSymbolToProfile?.accountCurrency ?? 'USD';
    String profitCurrency = 'USD';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text(
                    isAddingSymbol
                        ? _tr(context, 'Add symbol specs', 'Thêm thông số symbol')
                        : _tr(context, 'Add broker / platform profile', 'Thêm broker / nền tảng'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _tr(
                      context,
                      'You can find these values in MT5 → Symbol Specification or your broker contract details.',
                      'Bạn có thể xem các thông số này trong MT5 → Specification hoặc phần contract details của broker.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!isAddingSymbol) ...[
                    TextField(
                      controller: profileNameCtrl,
                      decoration: InputDecoration(
                        labelText: _tr(context, 'Profile name', 'Tên profile'),
                        hintText: _tr(context, 'My MT5 / My Broker / FTMO', 'MT5 của tôi / Broker của tôi / FTMO'),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: accountCurrency,
                      decoration: InputDecoration(
                        labelText: _tr(context, 'Account currency', 'Tiền tệ tài khoản'),
                        border: OutlineInputBorder(),
                      ),
                      items: _currencies
                          .map(
                            (currency) => DropdownMenuItem(
                          value: currency,
                          child: Text(currency),
                        ),
                      )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => accountCurrency = value);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    controller: symbolCtrl,
                    decoration: InputDecoration(
                      labelText: _tr(context, 'Symbol name', 'Tên symbol'),
                      hintText: 'EURNZD / UK100.cash / BTCUSD',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: assetClassCtrl,
                    decoration: InputDecoration(
                      labelText: _tr(context, 'Asset class', 'Nhóm tài sản'),
                      hintText: 'Forex / Index CFD / Crypto',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: profitCurrency,
                    decoration: InputDecoration(
                      labelText: 'Profit currency',
                      border: OutlineInputBorder(),
                    ),
                    items: _currencies
                        .map(
                          (currency) => DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() => profitCurrency = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tickSizeCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Tick size',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: tickValueCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Tick value / lot',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: volumeStepCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Volume step',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: minVolumeCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Min volume',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () async {
                      final symbol = symbolCtrl.text.trim().toUpperCase();
                      final profileName = profileNameCtrl.text.trim();

                      final tickSize = double.tryParse(
                        tickSizeCtrl.text.trim().replaceAll(',', '.'),
                      ) ??
                          0;
                      final tickValue = double.tryParse(
                        tickValueCtrl.text.trim().replaceAll(',', '.'),
                      ) ??
                          0;
                      final volumeStep = double.tryParse(
                        volumeStepCtrl.text.trim().replaceAll(',', '.'),
                      ) ??
                          0;
                      final minVolume = double.tryParse(
                        minVolumeCtrl.text.trim().replaceAll(',', '.'),
                      ) ??
                          0;

                      if (symbol.isEmpty ||
                          tickSize <= 0 ||
                          tickValue <= 0 ||
                          volumeStep <= 0 ||
                          minVolume < 0 ||
                          (!isAddingSymbol && profileName.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all required specs.'),
                          ),
                        );
                        return;
                      }

                      final newSpec = SymbolSpec(
                        symbol: symbol,
                        assetClass: assetClassCtrl.text.trim().isEmpty
                            ? 'Custom'
                            : assetClassCtrl.text.trim(),
                        profitCurrency: profitCurrency,
                        tickSize: tickSize,
                        tickValuePerLot: tickValue,
                        volumeStep: volumeStep,
                        minVolume: minVolume,
                      );

                      if (isAddingSymbol) {
                        final current = addSymbolToProfile;
                        if (current == null) return;

                        final updatedProfile = current.copyWith(
                          symbols: [
                            ...current.symbols,
                            newSpec,
                          ],
                        );

                        setState(() {
                          _profiles = _profiles
                              .map(
                                (p) => p.id == updatedProfile.id
                                ? updatedProfile
                                : p,
                          )
                              .toList();
                          _selectedProfile = updatedProfile;
                          _selectedSpec = newSpec;
                          _applySpec(newSpec);
                        });
                      } else {
                        final newProfile = BrokerProfile(
                          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                          name: profileName,
                          accountCurrency: accountCurrency,
                          symbols: [newSpec],
                          isDefault: false,
                        );

                        setState(() {
                          _profiles = [
                            ..._profiles,
                            newProfile,
                          ];
                          _selectedProfile = newProfile;
                          _selectedSpec = newSpec;
                          _applySpec(newSpec);
                        });
                      }

                      await _saveCustomProfiles();

                      if (!mounted) return;
                      Navigator.of(sheetContext).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Custom specs saved.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: Text(
                      isAddingSymbol
                          ? _tr(context, 'Save symbol', 'Lưu symbol')
                          : _tr(context, 'Save custom profile', 'Lưu profile'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _calculate();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_tr(context, '1R Calculator', 'Máy tính 1R')),
      ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
          Text(
            _tr(
              context,
              'Calculate position size using account size, planned risk, entry, and stop loss.',
              'Tính khối lượng vào lệnh từ tài khoản, mức rủi ro, entry và stop loss.',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          _sectionCard(
            title: _tr(context, 'Risk', 'Rủi ro'),
            children: [
              SegmentedButton<RiskInputMode>(
                segments: [
                  ButtonSegment(
                    value: RiskInputMode.percent,
                    label: Text(_tr(context, '% Balance', '% tài khoản')),
                  ),
                  ButtonSegment(
                    value: RiskInputMode.fixedMoney,
                    label: Text(_tr(context, 'Fixed', 'Cố định')),
                  ),
                ],
                selected: {_riskMode},
                onSelectionChanged: (value) {
                  setState(() => _riskMode = value.first);
                },
              ),
              const SizedBox(height: 12),
              if (_riskMode == RiskInputMode.percent) ...[
                _numberField(
                  controller: _accountController,
                  label: _tr(context, 'Account balance', 'Số dư tài khoản'),
                  prefixText: _selectedProfile.accountCurrency == 'USD'
                      ? '\$ '
                      : '${_selectedProfile.accountCurrency} ',
                ),
                const SizedBox(height: 12),
                _numberField(
                  controller: _riskPercentController,
                  label: _tr(context, 'Risk', 'Rủi ro'),
                  suffixText: ' %',
                ),
              ] else
                _numberField(
                  controller: _fixedRiskController,
                  label: _tr(context, 'Fixed risk money', 'Số tiền risk cố định'),
                  prefixText: _selectedProfile.accountCurrency == 'USD'
                      ? '\$ '
                      : '${_selectedProfile.accountCurrency} ',
                ),
            ],
          ),

          const SizedBox(height: 12),

          _sectionCard(
            title: _tr(context, 'Trade', 'Lệnh giao dịch'),
            children: [
              DropdownButtonFormField<BrokerProfile>(
                value: _selectedProfile,
                decoration: InputDecoration(
                  labelText: _tr(context, 'Broker / platform profile', 'Broker / nền tảng'),
                  border: OutlineInputBorder(),
                ),
                items: _profiles
                    .map(
                      (profile) => DropdownMenuItem(
                    value: profile,
                    child: Text(profile.name),
                  ),
                )
                    .toList(),
                onChanged: (profile) {
                  if (profile == null) return;
                  setState(() {
                    _selectedProfile = profile;
                    _selectedSpec = profile.symbols.first;
                    _applySpec(_selectedSpec);
                  });
                },
              ),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _showBrokerProfileGuide,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedProfile.isDefault
                              ? _tr(
                            context,
                            'Using app default specs. Tap to learn when to create your own broker profile.',
                            'Đang dùng thông số mặc định. Bấm để xem khi nào cần tạo broker/nền tảng riêng.',
                          )
                              : _tr(
                            context,
                            'Using saved custom specs for ${_selectedProfile.name}.',
                            'Đang dùng thông số đã lưu cho ${_selectedProfile.name}.',
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SymbolSpec>(
                value: _selectedSpec,
                decoration: InputDecoration(
                  labelText: _tr(context, 'Symbol', 'Mã giao dịch'),
                  border: OutlineInputBorder(),
                ),
                items: _selectedProfile.symbols
                    .map(
                      (spec) => DropdownMenuItem(
                    value: spec,
                    child: Text(spec.symbol),
                  ),
                )
                    .toList(),
                onChanged: (spec) {
                  if (spec == null) return;
                  setState(() {
                    _selectedSpec = spec;
                    _applySpec(spec);
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      controller: _entryController,
                      label: _tr(context, 'Entry', 'Entry'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _numberField(
                      controller: _stopController,
                      label: _tr(context, 'Stop loss', 'Stop loss'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _numberField(
                controller: _targetController,
                label: _tr(context, 'Target optional', 'Target / Exit tùy chọn'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showCustomProfileSheet(),
                icon: const Icon(Icons.add_rounded),
                label: Text(_tr(context, 'Add broker / platform specs', 'Thêm thông số broker/nền tảng')),
              ),
              if (!_selectedProfile.isDefault) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _showCustomProfileSheet(
                    addSymbolToProfile: _selectedProfile,
                  ),
                  icon: const Icon(Icons.playlist_add_rounded),
                  label: Text(_tr(context, 'Add symbol to this profile', 'Thêm symbol vào profile này')),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          if (result.hasError)
            _warningCard(result.error!)
          else
            _resultCard(result),

          const SizedBox(height: 12),

          _advancedCard(),


        ],
          ),
      ),
      bottomNavigationBar: widget.returnResultOnUse
          ? SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: result.hasError || result.suggestedVolume <= 0
              ? null
              : () {
            final target = _num(_targetController);

            Navigator.of(context).pop(
              RiskCalculatorFillResult(
                profileName: _selectedProfile.name,
                accountCurrency: _selectedProfile.accountCurrency,
                symbol: _selectedSpec.symbol,
                entry: _num(_entryController),
                stopLoss: _num(_stopController),
                target: target > 0 ? target : null,
                riskMoney: result.riskMoney,
                actualRisk: result.actualRisk,
                suggestedVolume: result.suggestedVolume,
              ),
            );
          },
          icon: const Icon(Icons.arrow_forward),
          label: Text(_tr(context, 'Use in New Trade', 'Dùng cho lệnh mới')),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      )
          : null,
    );
  }

  Widget _sectionCard({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _advancedCard() {
    final theme = Theme.of(context);
    final conversionRate = _rates?.conversionRate(
      from: _profitCurrency,
      to: _selectedProfile.accountCurrency,
    );

    String conversionText;

    if (_profitCurrency == _selectedProfile.accountCurrency) {
      conversionText = 'No currency conversion needed.';
    } else if (conversionRate == null) {
      conversionText = 'Conversion handled automatically when rates are available.';
    } else {
      conversionText =
      '1 $_profitCurrency ≈ ${_formatMoney(conversionRate, _selectedProfile.accountCurrency)}';
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        title: Text(_tr(context, 'Advanced broker specs', 'Cài đặt broker nâng cao')),
        subtitle: Text(
          _tr(
            context,
            'Rates and symbol specs are handled automatically. Edit only if needed.',
            'App tự xử lý tỷ giá và thông số symbol. Chỉ mở phần này khi bạn muốn tự chỉnh.',
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        children: [
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _profitCurrency,
            decoration: InputDecoration(
              labelText: _tr(context, 'Profit currency', 'Tiền tệ lợi nhuận'),
              border: OutlineInputBorder(),
            ),
            items: _currencies
                .map(
                  (currency) => DropdownMenuItem(
                value: currency,
                child: Text(currency),
              ),
            )
                .toList(),
            onChanged: (currency) {
              if (currency == null) return;
              setState(() => _profitCurrency = currency);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _numberField(
                  controller: _tickSizeController,
                  label: _tr(context, 'Tick size', 'Tick size'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numberField(
                  controller: _tickValueController,
                  label: _tr(context, 'Tick value / lot', 'Giá trị tick / lot'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _numberField(
                  controller: _volumeStepController,
                  label: _tr(context, 'Volume step', 'Bước volume'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numberField(
                  controller: _minVolumeController,
                  label: _tr(context, 'Min volume', 'Volume tối thiểu'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.currency_exchange_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_tr(context, 'Exchange rates', 'Tỷ giá')),
                      const SizedBox(height: 3),
                      Text(
                        _rateStatusText(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        conversionText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_rateError != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _rateError!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_isRefreshingRates)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else
                  IconButton(
                    tooltip: 'Refresh rates',
                    onPressed: () => _refreshRates(),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    String? prefixText,
    String? suffixText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        suffixText: suffixText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _warningCard(String message) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.errorContainer.withOpacity(0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultCard(RiskCalculationResult result) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withOpacity(0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_tr(context, 'Result', 'Kết quả'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            _bigResultRow(
              label: _tr(context, 'Suggested volume', 'Volume gợi ý'),
              value: _formatVolume(result.suggestedVolume),
            ),
            const Divider(height: 28),
            _resultRow(_tr(context, '1R money', 'Tiền risk / 1R'), _formatMoney(result.riskMoney)),
            _resultRow(_tr(context, 'SL distance', 'Khoảng cách SL'), _formatNumber(result.slDistance)),
            _resultRow(_tr(context, 'Actual risk', 'Risk thực tế'), _formatMoney(result.actualRisk)),
            if (result.rr != null)
              _resultRow(_tr(context, 'Planned R:R', 'R:R dự kiến'), '1:${result.rr!.toStringAsFixed(2)}'),
            if (result.potentialProfit != null)
              _resultRow(_tr(context, 'Potential profit', 'Lợi nhuận dự kiến'), _formatMoney(result.potentialProfit!)),
            if (result.suggestedVolume <= 0) ...[
              const SizedBox(height: 12),
              Text(
                _tr(
                  context,
                  'The calculated volume is below minimum volume. Try reducing risk distance, increasing risk money, or checking broker specs.',
                  'Volume tính được thấp hơn volume tối thiểu. Hãy kiểm tra khoảng SL, mức risk hoặc thông số broker.',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bigResultRow({
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _resultRow(String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}