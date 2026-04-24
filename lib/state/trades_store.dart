
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/trade.dart';
import '../reports/report_options.dart';
enum TimeFilter { all, today, week, month, year, custom }
class TradesStore extends ChangeNotifier {
  static const _storageKey = 'decision_journal_trades_v1';

  bool loaded = false;

  TimeFilter currentFilter = TimeFilter.all;
  DateTime? _customStart;
  DateTime? _customEnd;

  DateTime? get customStart => _customStart;
  DateTime? get customEnd => _customEnd;
  final List<Trade> _items = [];
  List<Trade> get items => List.unmodifiable(_items);
  List<Trade> get filteredItems => _applyTimeFilter(items);
  List<Trade> itemsForReportPeriod({
    required ReportPeriod period,
    DateTimeRange? customRange,
  }) {
    switch (period) {
      case ReportPeriod.currentFilter:
        return filteredItems;

      case ReportPeriod.thisMonth:
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, 1);
        final end = _endOfDay(now);
        return _filterByRange(items, start, end);

      case ReportPeriod.thisYear:
        final now = DateTime.now();
        final start = DateTime(now.year, 1, 1);
        final end = _endOfDay(now);
        return _filterByRange(items, start, end);

      case ReportPeriod.custom:
        if (customRange == null) return filteredItems;
        final start = _startOfDay(customRange.start);
        final end = _endOfDay(customRange.end);
        return _filterByRange(items, start, end);
    }
  }
  String timeFilterLabel({required bool isVi}) {
    switch (currentFilter) {
      case TimeFilter.all:
        return isVi ? 'Tất cả thời gian' : 'All time';
      case TimeFilter.today:
        return isVi ? 'Hôm nay' : 'Today';
      case TimeFilter.week:
        return isVi ? 'Tuần này' : 'This week';
      case TimeFilter.month:
        return isVi ? 'Tháng này' : 'This month';
      case TimeFilter.year:
        return isVi ? 'Năm nay' : 'This year';
      case TimeFilter.custom:
        if (_customStart == null || _customEnd == null) {
          return isVi ? 'Khoảng tùy chọn' : 'Custom range';
        }

        String fmt(DateTime d) {
          return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
        }

        return '${fmt(_customStart!)} → ${fmt(_customEnd!)}';
    }
  }
  void setTimeFilter(TimeFilter filter) {
    currentFilter = filter;
    notifyListeners();
  }

  void setCustomRange(DateTimeRange range) {
    _customStart = _startOfDay(range.start);
    _customEnd = _endOfDay(range.end);
    currentFilter = TimeFilter.custom;
    notifyListeners();
  }

  List<Trade> _applyTimeFilter(List<Trade> source) {
    if (currentFilter == TimeFilter.all) return source;

    final now = DateTime.now();
    late DateTime start;
    late DateTime end;

    switch (currentFilter) {
      case TimeFilter.today:
        start = _startOfDay(now);
        end = _endOfDay(now);
        break;

      case TimeFilter.week:
        start = _startOfWeek(now);
        end = _endOfDay(now);
        break;

      case TimeFilter.month:
        start = DateTime(now.year, now.month, 1);
        end = _endOfDay(now);
        break;

      case TimeFilter.year:
        start = DateTime(now.year, 1, 1);
        end = _endOfDay(now);
        break;

      case TimeFilter.custom:
        if (_customStart == null || _customEnd == null) return source;
        start = _customStart!;
        end = _customEnd!;
        break;

      case TimeFilter.all:
        return source;
    }

    return _filterByRange(source, start, end);
  }
  List<Trade> _filterByRange(
      List<Trade> source,
      DateTime start,
      DateTime end,
      ) {
    return source.where((t) {
      final dt = t.dateTime;
      return !dt.isBefore(start) && !dt.isAfter(end);
    }).toList();
  }
  DateTime _startOfDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  DateTime _endOfDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day, 23, 59, 59, 999);
  }

  DateTime _startOfWeek(DateTime dt) {
    final day = DateTime(dt.year, dt.month, dt.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    _items.clear();

    if (raw != null && raw.isNotEmpty) {
      try {
        _items.addAll(Trade.decodeList(raw));
      } catch (_) {}
    }

    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, Trade.encodeList(_items));
  }

  Future<void> addTrade(Trade t) async {
    _items.insert(0, t);
    await _save();
    notifyListeners();
  }

  Future<void> updateTradeAt(int index, Trade trade) async {
    if (index < 0 || index >= _items.length) return;
    _items[index] = trade;
    await _save();
    notifyListeners();
  }

  Future<void> updateAfterImageAt(int index, String? path) async {
    if (index < 0 || index >= _items.length) return;
    _items[index] = _items[index].setAfterImage(path);
    await _save();
    notifyListeners();
  }

  Future<void> deleteTradeAt(int index) async {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    await _save();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _items.clear();
    await _save();
    notifyListeners();
  }
}