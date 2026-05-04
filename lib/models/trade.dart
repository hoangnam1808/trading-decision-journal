import 'dart:convert';

import 'package:flutter/foundation.dart';

enum TradeGrade { a, aMinus, b }

extension TradeGradeX on TradeGrade {
  String get label => switch (this) {
    TradeGrade.a => 'A',
    TradeGrade.aMinus => 'A-',
    TradeGrade.b => 'B',
  };

  String get shortWhy => switch (this) {
    TradeGrade.a => 'High quality: context+risk+execution OK',
    TradeGrade.aMinus => 'Mixed quality: variance higher',
    TradeGrade.b => 'Low quality: edge killer',
  };
}

@immutable
class TradeChecklist {
  final bool contextOk;
  final bool entryZoneOk;
  final bool riskOk;
  final bool executionOk;
  final bool emotional;

  const TradeChecklist({
    required this.contextOk,
    required this.entryZoneOk,
    required this.riskOk,
    required this.executionOk,
    required this.emotional,
  });

  TradeChecklist copyWith({
    bool? contextOk,
    bool? entryZoneOk,
    bool? riskOk,
    bool? executionOk,
    bool? emotional,
  }) {
    return TradeChecklist(
      contextOk: contextOk ?? this.contextOk,
      entryZoneOk: entryZoneOk ?? this.entryZoneOk,
      riskOk: riskOk ?? this.riskOk,
      executionOk: executionOk ?? this.executionOk,
      emotional: emotional ?? this.emotional,
    );
  }

  Map<String, dynamic> toJson() => {
    'contextOk': contextOk,
    'entryZoneOk': entryZoneOk,
    'riskOk': riskOk,
    'executionOk': executionOk,
    'emotional': emotional,
  };

  factory TradeChecklist.fromJson(Map<String, dynamic> json) {
    final oldContextOk = json['contextOk'] ?? false;

    return TradeChecklist(
      contextOk: oldContextOk,
      entryZoneOk: json['entryZoneOk'] ?? oldContextOk,
      riskOk: json['riskOk'] ?? false,
      executionOk: json['executionOk'] ?? false,
      emotional: json['emotional'] ?? false,
    );
  }
}

TradeGrade classifyTrade(TradeChecklist c) {
  final failCount =
      (c.contextOk ? 0 : 1) +
          (c.entryZoneOk ? 0 : 1) +
          (c.executionOk ? 0 : 1) +
          (c.riskOk ? 0 : 1) +
          (c.emotional ? 1 : 0);

  final hasMajorIssue = !c.contextOk || !c.riskOk || c.emotional;

  if (hasMajorIssue || failCount >= 2) return TradeGrade.b;

  if (c.contextOk &&
      c.entryZoneOk &&
      c.executionOk &&
      c.riskOk &&
      !c.emotional) {
    return TradeGrade.a;
  }

  return TradeGrade.aMinus;
}

enum Market { forex, crypto, stocks, futures }

extension MarketX on Market {
  String get label => switch (this) {
    Market.forex => 'Forex',
    Market.crypto => 'Crypto',
    Market.stocks => 'Stocks',
    Market.futures => 'Futures',
  };
}

enum TradeDirection { long, short }

extension TradeDirectionX on TradeDirection {
  String get label => this == TradeDirection.long ? 'Long' : 'Short';
}

@immutable
class Trade {
  final DateTime dateTime;
  final Market market;
  final String strategy;
  final String symbol;
  final TradeDirection direction;
  final double entry;
  final double stopLoss;
  final double exit;

  /// Risk size used for this specific trade.
  ///
  /// Example:
  /// - 1.00 = full base 1R
  /// - 0.75 = 0.75R risk
  /// - 0.50 = 0.5R risk
  /// - 0.25 = 0.25R risk
  final double riskUsed;

  final double fee;

  /// Optional position sizing data from 1R Calculator.
  final double? plannedVolume;
  final double? plannedRiskMoney;
  final double? actualRiskMoney;
  final String? riskCalculatorProfile;
  final String? riskCalculatorAccountCurrency;

  final TradeChecklist checklist;
  final String? beforeImagePath;
  final String? afterImagePath;
  final String? note;

  const Trade({
    required this.dateTime,
    required this.market,
    required this.strategy,
    required this.symbol,
    required this.direction,
    required this.entry,
    required this.stopLoss,
    required this.exit,
    this.riskUsed = 1.0,
    this.fee = 0.0,
    this.plannedVolume,
    this.plannedRiskMoney,
    this.actualRiskMoney,
    this.riskCalculatorProfile,
    this.riskCalculatorAccountCurrency,
    required this.checklist,
    this.beforeImagePath,
    this.afterImagePath,
    this.note,
  });

  TradeGrade get grade => classifyTrade(checklist);

  double get resultR {
    final risk = direction == TradeDirection.long
        ? (entry - stopLoss)
        : (stopLoss - entry);

    if (risk == 0) return 0;

    final reward =
    direction == TradeDirection.long ? (exit - entry) : (entry - exit);

    return reward / risk;
  }

  double moneyResult(double cashPerR) {
    return resultR * riskUsed * cashPerR - fee;
  }

  Trade setAfterImage(String? path) {
    return Trade(
      dateTime: dateTime,
      market: market,
      strategy: strategy,
      symbol: symbol,
      direction: direction,
      entry: entry,
      stopLoss: stopLoss,
      exit: exit,
      riskUsed: riskUsed,
      fee: fee,
      plannedVolume: plannedVolume,
      plannedRiskMoney: plannedRiskMoney,
      actualRiskMoney: actualRiskMoney,
      riskCalculatorProfile: riskCalculatorProfile,
      riskCalculatorAccountCurrency: riskCalculatorAccountCurrency,
      checklist: checklist,
      beforeImagePath: beforeImagePath,
      afterImagePath: path,
      note: note,
    );
  }

  Trade setBeforeImage(String? path) {
    return Trade(
      dateTime: dateTime,
      market: market,
      strategy: strategy,
      symbol: symbol,
      direction: direction,
      entry: entry,
      stopLoss: stopLoss,
      exit: exit,
      riskUsed: riskUsed,
      fee: fee,
      plannedVolume: plannedVolume,
      plannedRiskMoney: plannedRiskMoney,
      actualRiskMoney: actualRiskMoney,
      riskCalculatorProfile: riskCalculatorProfile,
      riskCalculatorAccountCurrency: riskCalculatorAccountCurrency,
      checklist: checklist,
      beforeImagePath: path,
      afterImagePath: afterImagePath,
      note: note,
    );
  }

  Map<String, dynamic> toJson() => {
    'dateTime': dateTime.toIso8601String(),
    'market': market.name,
    'strategy': strategy,
    'symbol': symbol,
    'direction': direction.name,
    'entry': entry,
    'stopLoss': stopLoss,
    'exit': exit,
    'riskUsed': riskUsed,
    'fee': fee,
    'plannedVolume': plannedVolume,
    'plannedRiskMoney': plannedRiskMoney,
    'actualRiskMoney': actualRiskMoney,
    'riskCalculatorProfile': riskCalculatorProfile,
    'riskCalculatorAccountCurrency': riskCalculatorAccountCurrency,
    'checklist': checklist.toJson(),
    'beforeImagePath': beforeImagePath,
    'afterImagePath': afterImagePath,
    'note': note,
  };

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      dateTime: DateTime.parse(json['dateTime']),
      market: Market.values.byName(json['market']),
      strategy: (json['strategy'] ?? '').toString(),
      symbol: json['symbol'],
      direction: TradeDirection.values.byName(json['direction']),
      entry: (json['entry'] as num).toDouble(),
      stopLoss: (json['stopLoss'] as num).toDouble(),
      exit: (json['exit'] as num).toDouble(),
      riskUsed: (json['riskUsed'] as num?)?.toDouble() ?? 1.0,
      fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
      plannedVolume: (json['plannedVolume'] as num?)?.toDouble(),
      plannedRiskMoney: (json['plannedRiskMoney'] as num?)?.toDouble(),
      actualRiskMoney: (json['actualRiskMoney'] as num?)?.toDouble(),
      riskCalculatorProfile: json['riskCalculatorProfile']?.toString(),
      riskCalculatorAccountCurrency:
      json['riskCalculatorAccountCurrency']?.toString(),
      checklist: TradeChecklist.fromJson(
        Map<String, dynamic>.from(json['checklist']),
      ),
      beforeImagePath: json['beforeImagePath'],
      afterImagePath: json['afterImagePath'],
      note: json['note'],
    );
  }

  static String encodeList(List<Trade> trades) {
    return jsonEncode(trades.map((t) => t.toJson()).toList());
  }

  static List<Trade> decodeList(String raw) {
    final List<dynamic> data = jsonDecode(raw);
    return data
        .map((e) => Trade.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}