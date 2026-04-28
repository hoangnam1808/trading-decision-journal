import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../l10n/strings.dart';
import '../models/trade.dart';
import '../state/app_settings.dart';
import '../state/trades_store.dart';
import 'request_review_card.dart';
import 'time_filter_sheet.dart';
import '../reports/analyst_export_sheet.dart';

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

  String _analystExportContextLabel({
    required S s,
    required TradesStore store,
    required EquityScenario scenario,
    required String effectiveStrategyFilter,
  }) {
    final period = store.timeFilterLabel(isVi: s.isVi);
    final scenarioLabel = _scenarioTitle(s, scenario);
    final strategyLabel = effectiveStrategyFilter == _allStrategiesKey
        ? s.allStrategies
        : effectiveStrategyFilter;

    return '$period · $scenarioLabel · $strategyLabel';
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
    final store = context.watch<TradesStore>();
    final allItems = store.filteredItems;

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
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () {
              showAnalystExportSheet(
                context,
                trades: trades,
                contextLabel: _analystExportContextLabel(
                  s: s,
                  store: store,
                  scenario: _scenario,
                  effectiveStrategyFilter: effectiveStrategyFilter,
                ),
              );
            },
          ),
          IconButton(
            tooltip: s.isVi ? 'Lọc thời gian' : 'Time filter',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {
              showTimeFilterBottomSheet(context);
            },
          ),
        ],
      ),
      body: allItems.isEmpty
          ? _EmptyAnalystState(text: s.noTradesToSimulate)
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 132),
      children: [
        _CompactFilterCard(
          description: s.compareStrategyAndQualityFilters,
          viewOptions: AnalystView.values
              .map(
                (v) => _SegmentOption<AnalystView>(
              value: v,
              label: _viewLabel(s, v),
            ),
          )
              .toList(),
          selectedView: _view,
          onViewChanged: (value) => setState(() => _view = value),
          scenarioOptions: EquityScenario.values
              .map(
                (sc) => _SegmentOption<EquityScenario>(
              value: sc,
              label: _scenarioTitle(s, sc),
            ),
          )
              .toList(),
          selectedScenario: _scenario,
          onScenarioChanged: (value) => setState(() => _scenario = value),
          strategyLabel: s.strategy,
          allStrategiesLabel: s.allStrategies,
          strategies: strategies,
          effectiveStrategyFilter: effectiveStrategyFilter,
          allStrategiesKey: _allStrategiesKey,
          onStrategyChanged: (value) {
            if (value != null) {
              setState(() => _strategyFilter = value);
            }
          },
          rLabel: s.rUnit,
          moneyLabel: s.moneyUnit,
          moneyMode: _moneyMode,
          onMoneyModeChanged: (value) => setState(() => _moneyMode = value),
          showCashInput: _moneyMode,
          cashPerRCtrl: _cashPerRCtrl,
          cashPerRFocusNode: _cashPerRFocusNode,
          cashPerRLabel: s.cashPerR,
          cashPerRHint: s.cashPerRHint,
          saveLabel: s.save,
          onSaveCashPerR: () async {
            final value = double.tryParse(_cashPerRCtrl.text.trim());
            if (value == null || value <= 0) return;

            await context.read<AppSettings>().setCashPerR(value);

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.cashPerRSaved)),
            );
          },
        ),
        const SizedBox(height: 14),
        _CompactStatsCard(
          items: [
            _StatItem(
              label: s.totalTrades,
              value: '${trades.length}',
              icon: Icons.format_list_numbered_rounded,
            ),
            _StatItem(
              label: s.netR,
              value: _signedNumber(netR),
              icon: Icons.show_chart_rounded,
              valueColor: _valueColor(context, netR),
            ),
            _StatItem(
              label: s.avgR,
              value: _signedNumber(avgR),
              icon: Icons.analytics_rounded,
              valueColor: _valueColor(context, avgR),
            ),
            _StatItem(
              label: s.winrate,
              value: '${winrate.toStringAsFixed(1)}%',
              icon: Icons.emoji_events_rounded,
            ),
            _StatItem(
              label: s.maxDd,
              value: maxDd.toStringAsFixed(2),
              icon: Icons.trending_down_rounded,
              valueColor: maxDd > 0 ? Colors.orange : null,
            ),
          ],
        ),
        const SizedBox(height: 14),
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
        const SizedBox(height: 14),
        _ExportReportCard(
          onTap: () => showAnalystExportSheet(
            context,
            trades: trades,
            contextLabel: _analystExportContextLabel(
              s: s,
              store: context.read<TradesStore>(),
              scenario: _scenario,
              effectiveStrategyFilter: effectiveStrategyFilter,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const RequestReviewCard(),
      ],
    );
  }
}

String _signedNumber(double value) {
  final sign = value > 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(2)}';
}

class _ProCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _ProCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.055),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SegmentOption<T> {
  final T value;
  final String label;

  const _SegmentOption({
    required this.value,
    required this.label,
  });
}

class _CompactSegmented<T> extends StatelessWidget {
  final List<_SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const _CompactSegmented({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final active = option.value == selected;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onChanged(option.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: active
                    ? primary.withOpacity(isDark ? 0.24 : 0.13)
                    : theme.colorScheme.surface.withOpacity(0.48),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active
                      ? primary.withOpacity(0.55)
                      : theme.colorScheme.outlineVariant.withOpacity(0.45),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (active) ...[
                    Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: primary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    option.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: active ? primary : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CompactFilterCard extends StatelessWidget {
  final String description;

  final List<_SegmentOption<AnalystView>> viewOptions;
  final AnalystView selectedView;
  final ValueChanged<AnalystView> onViewChanged;

  final List<_SegmentOption<EquityScenario>> scenarioOptions;
  final EquityScenario selectedScenario;
  final ValueChanged<EquityScenario> onScenarioChanged;

  final String strategyLabel;
  final String allStrategiesLabel;
  final List<String> strategies;
  final String effectiveStrategyFilter;
  final String allStrategiesKey;
  final ValueChanged<String?> onStrategyChanged;

  final String rLabel;
  final String moneyLabel;
  final bool moneyMode;
  final ValueChanged<bool> onMoneyModeChanged;

  final bool showCashInput;
  final TextEditingController cashPerRCtrl;
  final FocusNode cashPerRFocusNode;
  final String cashPerRLabel;
  final String cashPerRHint;
  final String saveLabel;
  final VoidCallback onSaveCashPerR;

  const _CompactFilterCard({
    required this.description,
    required this.viewOptions,
    required this.selectedView,
    required this.onViewChanged,
    required this.scenarioOptions,
    required this.selectedScenario,
    required this.onScenarioChanged,
    required this.strategyLabel,
    required this.allStrategiesLabel,
    required this.strategies,
    required this.effectiveStrategyFilter,
    required this.allStrategiesKey,
    required this.onStrategyChanged,
    required this.rLabel,
    required this.moneyLabel,
    required this.moneyMode,
    required this.onMoneyModeChanged,
    required this.showCashInput,
    required this.cashPerRCtrl,
    required this.cashPerRFocusNode,
    required this.cashPerRLabel,
    required this.cashPerRHint,
    required this.saveLabel,
    required this.onSaveCashPerR,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _ProCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _CompactSegmented<AnalystView>(
            options: viewOptions,
            selected: selectedView,
            onChanged: onViewChanged,
          ),
          const SizedBox(height: 10),
          _CompactSegmented<EquityScenario>(
            options: scenarioOptions,
            selected: selectedScenario,
            onChanged: onScenarioChanged,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: effectiveStrategyFilter,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: strategyLabel,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: allStrategiesKey,
                      child: Text(allStrategiesLabel),
                    ),
                    ...strategies.map(
                          (strategy) => DropdownMenuItem(
                        value: strategy,
                        child: Text(strategy),
                      ),
                    ),
                  ],
                  onChanged: onStrategyChanged,
                ),
              ),
              const SizedBox(width: 10),
              _CompactSegmented<bool>(
                options: [
                  _SegmentOption<bool>(value: false, label: rLabel),
                  _SegmentOption<bool>(value: true, label: moneyLabel),
                ],
                selected: moneyMode,
                onChanged: onMoneyModeChanged,
              ),
            ],
          ),
          if (showCashInput) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: cashPerRCtrl,
                    focusNode: cashPerRFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: cashPerRLabel,
                      hintText: cashPerRHint,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onSaveCashPerR,
                  child: Text(saveLabel),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });
}

class _CompactStatsCard extends StatelessWidget {
  final List<_StatItem> items;

  const _CompactStatsCard({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return _ProCard(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 10.0;
          final itemWidth = (constraints.maxWidth - gap) / 2;

          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: items
                .map(
                  (item) => SizedBox(
                width: itemWidth,
                child: _TinyMetric(item: item),
              ),
            )
                .toList(),
          );
        },
      ),
    );
  }
}

class _TinyMetric extends StatelessWidget {
  final _StatItem item;

  const _TinyMetric({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(
          theme.brightness == Brightness.dark ? 0.32 : 0.75,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.38),
        ),
      ),
      child: Row(
        children: [
          Icon(
            item.icon,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: item.valueColor ?? theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    final theme = Theme.of(context);
    final curve = _buildCurve(trades);

    return _ProCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 230,
            child: trades.isEmpty
                ? Center(
              child: Text(
                s.noTradesInThisFilter,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
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
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.colorScheme.outlineVariant
                          .withOpacity(0.28),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color:
                    theme.colorScheme.outlineVariant.withOpacity(0.35),
                  ),
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
                      reservedSize: 38,
                      interval: niceInterval(minY, maxY),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: bottomInterval(curve.length),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= curve.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            '$idx',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
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
                            fontWeight: FontWeight.w700,
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
                      color:
                      theme.colorScheme.primary.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

  double _tradeMoney(Trade trade) {
    return trade.resultR * cashPerR - trade.fee;
  }

  double _dayNetMoney(List<Trade> trades) {
    return trades.fold<double>(0, (sum, t) => sum + _tradeMoney(t));
  }

  String _moneyText(double value) {
    return '${value >= 0 ? '+' : ''}\$${value.toStringAsFixed(2)}';
  }

  String _calendarValueText(double value) {
    if (moneyMode) return _moneyText(value);
    return formatValue(value);
  }

  Color _valueColor(BuildContext context, double value) {
    if (value > 0) return Colors.green;
    if (value < 0) return Colors.red;
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final monthTrades = grouped.entries
        .where(
          (e) =>
      e.key.year == focusedDay.year && e.key.month == focusedDay.month,
    )
        .expand((e) => e.value)
        .toList();

    final monthNet =
    moneyMode ? _dayNetMoney(monthTrades) : _dayNetR(monthTrades);

    final dayNet =
    moneyMode ? _dayNetMoney(selectedTrades) : _dayNetR(selectedTrades);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProCard(
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
            rowHeight: 46,
            daysOfWeekHeight: 24,
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ) ??
                  const TextStyle(),
              leftChevronIcon: Icon(
                Icons.chevron_left_rounded,
                color: theme.colorScheme.onSurface,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ) ??
                  const TextStyle(),
              weekendStyle: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ) ??
                  const TextStyle(),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
              weekendTextStyle: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
              todayTextStyle: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
              selectedTextStyle: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return const SizedBox.shrink();

                final dayTrades = events.cast<Trade>().toList();
                final net =
                moneyMode ? _dayNetMoney(dayTrades) : _dayNetR(dayTrades);
                final positive = net >= 0;
                final color = positive ? Colors.green : Colors.red;

                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _calendarValueText(net),
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        _CompactStatsCard(
          items: [
            _StatItem(
              label: s.monthSummary,
              value: _calendarValueText(monthNet),
              icon: Icons.calendar_month_rounded,
              valueColor: _valueColor(context, monthNet),
            ),
            _StatItem(
              label: s.selectedDayLabel,
              value: _calendarValueText(dayNet),
              icon: Icons.today_rounded,
              valueColor: _valueColor(context, dayNet),
            ),
            _StatItem(
              label: s.tradesCount,
              value: '${selectedTrades.length}',
              icon: Icons.list_alt_rounded,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SelectedDayCard(
          s: s,
          selectedKey: selectedKey,
          selectedTrades: selectedTrades,
          dayNetText: _calendarValueText(dayNet),
          moneyMode: moneyMode,
          formatValue: formatValue,
          valueColor: (value) => _valueColor(context, value),
        ),
      ],
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  final S s;
  final DateTime selectedKey;
  final List<Trade> selectedTrades;
  final String dayNetText;
  final bool moneyMode;
  final String Function(double value) formatValue;
  final Color Function(double value) valueColor;

  const _SelectedDayCard({
    required this.s,
    required this.selectedKey,
    required this.selectedTrades,
    required this.dayNetText,
    required this.moneyMode,
    required this.formatValue,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateText =
        '${selectedKey.year}-${selectedKey.month.toString().padLeft(2, '0')}-${selectedKey.day.toString().padLeft(2, '0')}';

    return _ProCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${s.selectedDayLabel}: $dateText',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${s.netValue}: $dayNetText • ${s.tradesCount}: ${selectedTrades.length}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (selectedTrades.isEmpty)
            Text(
              s.noTradesOnThisDay,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...selectedTrades.map(
                  (t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.green.withOpacity(0.14),
                      child: Text(
                        t.grade.label,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${t.symbol} • ${t.direction.label}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${s.strategy}: ${t.strategy}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${s.netR}: ${moneyMode ? formatValue(t.resultR) : t.resultR.toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: valueColor(t.resultR),
                            ),
                          ),
                          if (t.note != null && t.note!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              t.note!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
    final s = S.of(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return _ProCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: primary.withOpacity(0.12),
            child: Icon(
              Icons.ios_share_rounded,
              color: primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.isVi
                      ? 'Xuất report hiệu suất'
                      : 'Export Performance Report',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.isVi
                      ? 'Tạo ảnh hoặc PDF report từ journal giao dịch của bạn.'
                      : 'Create a clean image or PDF report from your trading journal.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.file_download_outlined),
            label: Text(s.isVi ? 'Xuất' : 'Export'),
          ),
        ],
      ),
    );
  }
}

class _EmptyAnalystState extends StatelessWidget {
  final String text;

  const _EmptyAnalystState({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _ProCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.analytics_rounded,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                text,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}