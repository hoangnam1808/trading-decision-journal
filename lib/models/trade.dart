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
  final bool riskOk;
  final bool executionOk;
  final bool emotional;

  const TradeChecklist({
    required this.contextOk,
    required this.riskOk,
    required this.executionOk,
    required this.emotional,
  });

  TradeChecklist copyWith({
    bool? contextOk,
    bool? riskOk,
    bool? executionOk,
    bool? emotional,
  }) {
    return TradeChecklist(
      contextOk: contextOk ?? this.contextOk,
      riskOk: riskOk ?? this.riskOk,
      executionOk: executionOk ?? this.executionOk,
      emotional: emotional ?? this.emotional,
    );
  }

  Map<String, dynamic> toJson() => {
    'contextOk': contextOk,
    'riskOk': riskOk,
    'executionOk': executionOk,
    'emotional': emotional,
  };

  factory TradeChecklist.fromJson(Map<String, dynamic> json) {
    return TradeChecklist(
      contextOk: json['contextOk'] ?? false,
      riskOk: json['riskOk'] ?? false,
      executionOk: json['executionOk'] ?? false,
      emotional: json['emotional'] ?? false,
    );
  }
}

TradeGrade classifyTrade(TradeChecklist c) {
  final failCount =
      (c.contextOk ? 0 : 1) + (c.riskOk ? 0 : 1) + (c.executionOk ? 0 : 1);
  final hasMajorIssue = !c.contextOk || failCount >= 2;

  if (hasMajorIssue || (c.emotional && !c.contextOk)) return TradeGrade.b;
  if (c.contextOk && c.riskOk && c.executionOk && !c.emotional) {
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
    'checklist': checklist.toJson(),
    'beforeImagePath': beforeImagePath,
    'afterImagePath': afterImagePath,
    'note': note,
  };

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      dateTime: DateTime.parse(json['dateTime']),
      market: Market.values.byName(json['market']),
      strategy: (json['strategy'] ?? 'General').toString(),
      symbol: json['symbol'],
      direction: TradeDirection.values.byName(json['direction']),
      entry: (json['entry'] as num).toDouble(),
      stopLoss: (json['stopLoss'] as num).toDouble(),
      exit: (json['exit'] as num).toDouble(),
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