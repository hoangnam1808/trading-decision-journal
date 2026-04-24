import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../l10n/strings.dart';
import '../models/trade.dart';
import '../reports/export_report_sheet.dart';
import '../state/app_settings.dart';
import '../state/trades_store.dart';
import 'request_review_card.dart';
import 'time_filter_sheet.dart';

enum AnalystView { equity, calendar }
enum EquityScenario { all, noB, onlyA }

class EquityScreen extends StatefulWidget {
  const EquityScreen({super.key});

  @override
  State<EquityScreen> createState() => _EquityScreenState();
}

class _EquityScreenState extends State<EquityScreen> {
  static const _allStrategiesKey = '__all__';

  AnalystView _view = AnalystView.equity;
  EquityScenario _scenario = EquityScenario.all;
  String _strategyFilter = _allStrategiesKey;

  bool _moneyMode = false;
  final _cashPerRCtrl = TextEditingController();
  final _cashPerRFocusNode = FocusNode();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  @override
  void dispose() {
    _cashPerRCtrl.dispose();
    _cashPerRFocusNode.dispose();
    super.dispose();
  }

  String _scenarioTitle(S s, EquityScenario scenario) {
    switch (scenario) {
      case EquityScenario.all:
        return s.allTrades;
      case EquityScenario.noB:
        return s.noBTrades;
      case EquityScenario.onlyA:
        return s.onlyATrades;
    }
  }

  String _viewLabel(S s, AnalystView view) {
    switch (view) {
      case AnalystView.equity:
        return s.equityView;
      case AnalystView.calendar:
        return s.calendarView;
    }
  }

  List<Trade> _applyScenario(List<Trade> items, EquityScenario scenario) {
    switch (scenario) {
      case EquityScenario.all:
        return items;
      case EquityScenario.noB:
        return items.where((t) => t.grade != TradeGrade.b).toList();
      case EquityScenario.onlyA:
        return items.where((t) => t.grade == TradeGrade.a).toList();
    }
  }

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  Map<DateTime, List<Trade>> _groupByDay(List<Trade> trades) {
    final map = <DateTime, List<Trade>>{};
    for (final t in trades) {
      final key = _dayKey(t.dateTime);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  List<double> _buildCurve(List<Trade> trades) {
    final curve = <double>[0];
    double equity = 0;
    for (final t in trades) {
      equity += t.resultR;
      curve.add(equity);
    }
    return curve;
  }

  double _maxDrawdown(List<double> curve) {
    if (curve.isEmpty) return 0;
    double peak = curve.first;
    double maxDd = 0;

    for (final v in curve) {
      if (v > peak) peak = v;
      final dd = peak - v;
      if (dd > maxDd) maxDd = dd;
    }
    return maxDd;
  }

  double _minY(List<double> curve) {
    if (curve.isEmpty) return -1;
    final minVal = curve.reduce((a, b) => a < b ? a : b);
    return minVal == 0 ? -1 : minVal - (minVal.abs() * 0.15) - 0.3;
  }

  double _maxY(List<double> curve) {
    if (curve.isEmpty) return 1;
    final maxVal = curve.reduce((a, b) => a > b ? a : b);
    return maxVal == 0 ? 1 : maxVal + (maxVal.abs() * 0.15) + 0.3;
  }

  double _niceInterval(double minY, double maxY) {
    final range = (maxY - minY).abs();
    if (range <= 2) return 0.5;
    if (range <= 5) return 1;
    if (range <= 10) return 2;
    if (range <= 20) return 5;
    return 10;
  }

  double _bottomInterval(int length) {
    if (length <= 6) return 1;
    if (length <= 15) return 2;
    if (length <= 30) return 5;
    if (length <= 60) return 10;
    return 20;
  }

  String _formatValue(double value, S s, double cashPerR) {
    if (!_moneyMode) {
      return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)} ${s.rUnit}';
    }
    final money = value * cashPerR;
    return '${money >= 0 ? '+' : ''}\$${money.toStringAsFixed(2)}';
  }

  Color _valueColor(BuildContext context, double value) {
    if (value > 0) return Colors.green;
    if (value < 0) return Colors.red;
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = context.watch<AppSettings>();
    final allItems = context.watch<TradesStore>().filteredItems;

    final persistedCashText = settings.cashPerR.toStringAsFixed(
      settings.cashPerR % 1 == 0 ? 0 : 2,
    );
    if (!_cashPerRFocusNode.hasFocus &&
        _cashPerRCtrl.text != persistedCashText) {
      _cashPerRCtrl.text = persistedCashText;
    }

    final cashPerR =
        double.tryParse(_cashPerRCtrl.text.trim()) ?? settings.cashPerR;

    final strategies = allItems
        .map((t) => t.strategy.trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final effectiveStrategyFilter = strategies.contains(_strategyFilter)
        ? _strategyFilter
        : _allStrategiesKey;

    final qualityFiltered = _applyScenario(allItems, _scenario);
    final trades = effectiveStrategyFilter == _allStrategiesKey
        ? qualityFiltered
        : qualityFiltered
        .where((t) => t.strategy == effectiveStrategyFilter)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.analyst),
        actions: [
          IconButton(
            tooltip: s.isVi ? 'Xuất report' : 'Export report',
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: () {
              showExportReportSheet(context);
            },
          ),
          IconButton(
            tooltip: s.isVi ? 'Lọc thời gian' : 'Time filter',
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () {
              showTimeFilterBottomSheet(context);
            },
          ),
        ],
      ),
      body: allItems.isEmpty
          ? Center(child: Text(s.noTradesToSimulate))
          : _buildBody(
        context: context,
        s: s,
        settings: settings,
        trades: trades,
        allItems: allItems,
        strategies: strategies,
        effectiveStrategyFilter: effectiveStrategyFilter,
        cashPerR: cashPerR,
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required S s,
    required AppSettings settings,
    required List<Trade> trades,
    required List<Trade> allItems,
    required List<String> strategies,
    required String effectiveStrategyFilter,
    required double cashPerR,
  }) {
    final grouped = _groupByDay(trades);
    final selectedKey = _dayKey(_selectedDay ?? DateTime.now());
    final selectedTrades = grouped[selectedKey] ?? [];

    final netR = trades.fold<double>(0, (sum, t) => sum + t.resultR);
    final avgR = trades.isEmpty ? 0.0 : netR / trades.length;
    final wins = trades.where((t) => t.resultR > 0).length;
    final winrate = trades.isEmpty ? 0.0 : (wins / trades.length) * 100;
    final curve = _buildCurve(trades);
    final maxDd = _maxDrawdown(curve);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          s.compareStrategyAndQualityFilters,
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<AnalystView>(
                  segments: AnalystView.values
                      .map(
                        (v) => ButtonSegment<AnalystView>(
                      value: v,
                      label: Text(_viewLabel(s, v)),
                    ),
                  )
                      .toList(),
                  selected: {_view},
                  onSelectionChanged: (selection) {
                    setState(() => _view = selection.first);
                  },
                ),
                const SizedBox(height: 12),
                SegmentedButton<EquityScenario>(
                  segments: EquityScenario.values
                      .map(
                        (sc) => ButtonSegment<EquityScenario>(
                      value: sc,
                      label: Text(_scenarioTitle(s, sc)),
                    ),
                  )
                      .toList(),
                  selected: {_scenario},
                  onSelectionChanged: (selection) {
                    setState(() => _scenario = selection.first);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: effectiveStrategyFilter,
                  decoration: InputDecoration(
                    labelText: s.strategy,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: _allStrategiesKey,
                      child: Text(s.allStrategies),
                    ),
                    ...strategies.map(
                          (strategy) => DropdownMenuItem(
                        value: strategy,
                        child: Text(strategy),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _strategyFilter = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment<bool>(value: false, label: Text(s.rUnit)),
                    ButtonSegment<bool>(value: true, label: Text(s.moneyUnit)),
                  ],
                  selected: {_moneyMode},
                  onSelectionChanged: (selection) {
                    setState(() => _moneyMode = selection.first);
                  },
                ),
                if (_moneyMode) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cashPerRCtrl,
                          focusNode: _cashPerRFocusNode,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: s.cashPerR,
                            hintText: s.cashPerRHint,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          final value =
                          double.tryParse(_cashPerRCtrl.text.trim());
                          if (value == null || value <= 0) return;

                          await context.read<AppSettings>().setCashPerR(value);

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.cashPerRSaved)),
                          );
                        },
                        child: Text(s.save),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              label: s.totalTrades,
              value: '${trades.length}',
              icon: Icons.format_list_numbered,
            ),
            _MetricCard(
              label: s.netR,
              value: netR.toStringAsFixed(2),
              icon: Icons.show_chart,
              valueColor: _valueColor(context, netR),
            ),
            _MetricCard(
              label: s.avgR,
              value: avgR.toStringAsFixed(2),
              icon: Icons.analytics_outlined,
              valueColor: _valueColor(context, avgR),
            ),
            _MetricCard(
              label: s.winrate,
              value: '${winrate.toStringAsFixed(1)}%',
              icon: Icons.emoji_events_outlined,
            ),
            _MetricCard(
              label: s.maxDd,
              value: maxDd.toStringAsFixed(2),
              icon: Icons.trending_down,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_view == AnalystView.equity)
          _EquitySection(
            trades: trades,
            title: _scenarioTitle(s, _scenario),
            subtitle: effectiveStrategyFilter == _allStrategiesKey
                ? s.allStrategies
                : '${s.strategy}: $effectiveStrategyFilter',
            minY: _minY(curve),
            maxY: _maxY(curve),
            niceInterval: _niceInterval,
            bottomInterval: _bottomInterval,
          )
        else
          _CalendarSection(
            s: s,
            localeCode: s.isVi ? 'vi_VN' : 'en_US',
            grouped: grouped,
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
            },
            selectedTrades: selectedTrades,
            selectedKey: selectedKey,
            moneyMode: _moneyMode,
            cashPerR: cashPerR,
            formatValue: (value) => _formatValue(value, s, cashPerR),
          ),
        const SizedBox(height: 16),
        _ExportReportCard(
          onTap: () => showExportReportSheet(context),
        ),
        const SizedBox(height: 16),
        const RequestReviewCard(),
      ],
    );
  }
}

class _EquitySection extends StatelessWidget {
  final List<Trade> trades;
  final String title;
  final String subtitle;
  final double minY;
  final double maxY;
  final double Function(double minY, double maxY) niceInterval;
  final double Function(int length) bottomInterval;

  const _EquitySection({
    required this.trades,
    required this.title,
    required this.subtitle,
    required this.minY,
    required this.maxY,
    required this.niceInterval,
    required this.bottomInterval,
  });

  List<double> _buildCurve(List<Trade> trades) {
    final curve = <double>[0];
    double equity = 0;
    for (final t in trades) {
      equity += t.resultR;
      curve.add(equity);
    }
    return curve;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final curve = _buildCurve(trades);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: trades.isEmpty
                  ? Center(child: Text(s.noTradesInThisFilter))
                  : LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (curve.length - 1).toDouble(),
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: niceInterval(minY, maxY),
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.black12),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: niceInterval(minY, maxY),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 11),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: bottomInterval(curve.length),
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= curve.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '$idx',
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          return LineTooltipItem(
                            'Trade ${spot.x.toInt()}\n${spot.y.toStringAsFixed(2)} R',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        curve.length,
                            (i) => FlSpot(i.toDouble(), curve[i]),
                      ),
                      isCurved: false,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarSection extends StatelessWidget {
  final S s;
  final String localeCode;
  final Map<DateTime, List<Trade>> grouped;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final void Function(DateTime focusedDay) onPageChanged;
  final List<Trade> selectedTrades;
  final DateTime selectedKey;
  final bool moneyMode;
  final double cashPerR;
  final String Function(double value) formatValue;

  const _CalendarSection({
    required this.s,
    required this.localeCode,
    required this.grouped,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.selectedTrades,
    required this.selectedKey,
    required this.moneyMode,
    required this.cashPerR,
    required this.formatValue,
  });

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  double _dayNetR(List<Trade> trades) {
    return trades.fold<double>(0, (sum, t) => sum + t.resultR);
  }

  Color _valueColor(double value) {
    if (value > 0) return Colors.green;
    if (value < 0) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final monthTrades = grouped.entries
        .where(
          (e) => e.key.year == focusedDay.year && e.key.month == focusedDay.month,
    )
        .expand((e) => e.value)
        .toList();
    final monthNet = _dayNetR(monthTrades);
    final dayNet = _dayNetR(selectedTrades);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TableCalendar<Trade>(
              locale: localeCode,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: focusedDay,
              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              onDaySelected: onDaySelected,
              onPageChanged: onPageChanged,
              eventLoader: (day) => grouped[_dayKey(day)] ?? const [],
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return const SizedBox.shrink();

                  final net = _dayNetR(events.cast<Trade>());
                  final positive = net >= 0;

                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: positive
                            ? Colors.green.withOpacity(0.15)
                            : Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        formatValue(net),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: positive ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              label: s.monthSummary,
              value: formatValue(monthNet),
              icon: Icons.calendar_month_outlined,
              valueColor: _valueColor(monthNet),
            ),
            _MetricCard(
              label: s.selectedDayLabel,
              value: formatValue(dayNet),
              icon: Icons.today_outlined,
              valueColor: _valueColor(dayNet),
            ),
            _MetricCard(
              label: s.tradesCount,
              value: '${selectedTrades.length}',
              icon: Icons.list_alt_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '${s.selectedDayLabel}: ${selectedKey.year}-${selectedKey.month.toString().padLeft(2, '0')}-${selectedKey.day.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          '${s.netValue}: ${formatValue(dayNet)} • ${s.tradesCount}: ${selectedTrades.length}',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        if (selectedTrades.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(s.noTradesOnThisDay),
            ),
          )
        else
          ...selectedTrades.map(
                (t) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(child: Text(t.grade.label)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${t.symbol} • ${t.direction.label}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text('${s.strategy}: ${t.strategy}'),
                          const SizedBox(height: 4),
                          Text(
                            '${s.netR}: ${moneyMode ? formatValue(t.resultR) : t.resultR.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _valueColor(t.resultR),
                            ),
                          ),
                          if (t.note != null && t.note!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              t.note!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 165,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _ExportReportCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ExportReportCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: primary.withOpacity(0.10),
              child: Icon(
                Icons.ios_share_outlined,
                color: primary,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Performance Report',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Create a clean image or PDF report from your trading journal.',
                    style: TextStyle(
                      color: Colors.black54,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Export'),
            ),
          ],
        ),
      ),
    );
  }
}