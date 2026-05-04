import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../state/app_settings.dart';
import 'risk_calculator_screen.dart';

import '../l10n/strings.dart';
import '../models/trade.dart';
import '../state/trades_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddTradeFlow extends StatefulWidget {
  final Trade? initialTrade;
  final int? editIndex;

  const AddTradeFlow({
    super.key,
    this.initialTrade,
    this.editIndex,
  });

  bool get isEdit => initialTrade != null && editIndex != null;

  @override
  State<AddTradeFlow> createState() => _AddTradeFlowState();
}

class _AddTradeFlowState extends State<AddTradeFlow> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  static const _strategyPrefsKey = 'strategy_quick_picks_v1';

  static const _defaultStrategySuggestions = [
    'Price Action',
    'SMC',
    'Wyckoff',
    'Breakout',
    'Trend Following',
    'Mean Reversion',
  ];

  List<String> _strategySuggestions = [..._defaultStrategySuggestions];

  late DateTime _dateTime;
  late Market _market;
  late TradeDirection _dir;

  final _strategyCtrl = TextEditingController();
  final _symbolCtrl = TextEditingController();
  final _entryCtrl = TextEditingController();
  final _stopLossCtrl = TextEditingController();
  final _exitCtrl = TextEditingController();
  final _riskUsedCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _beforeImagePath;
  String? _afterImagePath;

  double? _plannedVolume;
  double? _plannedRiskMoney;
  double? _actualRiskMoney;
  String? _riskCalculatorProfile;
  String? _riskCalculatorAccountCurrency;

  TradeChecklist c = const TradeChecklist(
    contextOk: true,
    entryZoneOk: true,
    riskOk: true,
    executionOk: true,
    emotional: false,
  );

  @override
  void initState() {
    super.initState();

    final t = widget.initialTrade;

    if (t != null) {
      _dateTime = t.dateTime;
      _market = t.market;
      _dir = t.direction;

      _strategyCtrl.text = t.strategy;
      _symbolCtrl.text = t.symbol;
      _entryCtrl.text = t.entry.toString();
      _stopLossCtrl.text = t.stopLoss.toString();
      _exitCtrl.text = t.exit.toString();
      _riskUsedCtrl.text = t.riskUsed == 1.0 ? '' : _formatRiskUsed(t.riskUsed);
      _feeCtrl.text = t.fee == 0 ? '' : t.fee.toString();
      _noteCtrl.text = t.note ?? '';

      _beforeImagePath = t.beforeImagePath;
      _afterImagePath = t.afterImagePath;

      _plannedVolume = t.plannedVolume;
      _plannedRiskMoney = t.plannedRiskMoney;
      _actualRiskMoney = t.actualRiskMoney;
      _riskCalculatorProfile = t.riskCalculatorProfile;
      _riskCalculatorAccountCurrency = t.riskCalculatorAccountCurrency;

      c = t.checklist;
    } else {
      _dateTime = DateTime.now();
      _market = Market.forex;
      _dir = TradeDirection.long;
      _riskUsedCtrl.clear();
    }
    _strategyCtrl.addListener(_onStrategyTextChanged);
    _loadStrategySuggestions();
  }

  @override
  void dispose() {
    _strategyCtrl.removeListener(_onStrategyTextChanged);
    _strategyCtrl.dispose();
    _symbolCtrl.dispose();
    _entryCtrl.dispose();
    _stopLossCtrl.dispose();
    _exitCtrl.dispose();
    _riskUsedCtrl.dispose();
    _feeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }
  void _onStrategyTextChanged() {
    if (mounted) setState(() {});
  }

  bool _sameStrategy(String a, String b) {
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  bool _containsStrategy(List<String> list, String value) {
    return list.any((item) => _sameStrategy(item, value));
  }

  bool _isDefaultStrategy(String value) {
    return _defaultStrategySuggestions.any((item) => _sameStrategy(item, value));
  }

  Future<void> _persistCustomStrategies() async {
    final prefs = await SharedPreferences.getInstance();

    final custom = _strategySuggestions
        .where((item) => !_isDefaultStrategy(item))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    await prefs.setStringList(_strategyPrefsKey, custom);
  }

  Future<void> _loadStrategySuggestions() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_strategyPrefsKey) ?? const [];

    final merged = <String>[..._defaultStrategySuggestions];

    for (final raw in saved) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      if (!_containsStrategy(merged, value)) {
        merged.add(value);
      }
    }

    if (!mounted) return;
    setState(() => _strategySuggestions = merged);
  }

  Future<void> _addCurrentStrategyToQuickPick() async {
    final s = S.read(context);
    final value = _strategyCtrl.text.trim();

    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.isVi
                ? 'Nhập tên chiến lược trước khi lưu quick pick.'
                : 'Enter a strategy name before saving quick pick.',
          ),
        ),
      );
      return;
    }

    if (_containsStrategy(_strategySuggestions, value)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.isVi
                ? 'Chiến lược này đã có trong quick pick.'
                : 'This strategy is already in quick pick.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _strategySuggestions.add(value);
    });

    await _persistCustomStrategies();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          s.isVi
              ? 'Đã lưu "$value" vào quick pick.'
              : 'Saved "$value" to quick pick.',
        ),
      ),
    );
  }

  Future<void> _removeStrategyQuickPick(String value) async {
    if (_isDefaultStrategy(value)) return;

    setState(() {
      _strategySuggestions.removeWhere((item) => _sameStrategy(item, value));
    });

    await _persistCustomStrategies();
  }
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;

    setState(() {
      _dateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _dateTime.hour,
        _dateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _dateTime.hour,
        minute: _dateTime.minute,
      ),
    );
    if (picked == null) return;

    setState(() {
      _dateTime = DateTime(
        _dateTime.year,
        _dateTime.month,
        _dateTime.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _pickBeforeImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final folder = Directory('${appDir.path}/trade_images');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final newPath =
        '${folder.path}/before_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final copied = await File(picked.path).copy(newPath);

    setState(() {
      _beforeImagePath = copied.path;
    });
  }

  String _fmt2(int v) => v.toString().padLeft(2, '0');

  double? _parse(String text) => double.tryParse(text.trim());

  double _parseOptionalFee() {
    final text = _feeCtrl.text.trim();
    if (text.isEmpty) return 0.0;
    return double.tryParse(text) ?? 0.0;
  }
  String _formatRiskUsed(double value) {
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
  }
  String _formatCalculatorNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value
        .toStringAsFixed(8)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
  void _clearPositionSizingSnapshot() {
    _plannedVolume = null;
    _plannedRiskMoney = null;
    _actualRiskMoney = null;
    _riskCalculatorProfile = null;
    _riskCalculatorAccountCurrency = null;
  }
  Future<void> _openRiskCalculator() async {
    final result = await Navigator.of(context).push<RiskCalculatorFillResult>(
      MaterialPageRoute(
        builder: (_) => const RiskCalculatorScreen(
          returnResultOnUse: true,
        ),
      ),
    );

    if (result == null || !mounted) return;

    final settings = context.read<AppSettings>();
    final cashPerR = settings.cashPerR;
    final riskUsed = cashPerR > 0 ? result.actualRisk / cashPerR : 1.0;

    setState(() {
      _symbolCtrl.text = result.symbol;
      _entryCtrl.text = _formatCalculatorNumber(result.entry);
      _stopLossCtrl.text = _formatCalculatorNumber(result.stopLoss);

      if (result.target != null) {
        _exitCtrl.text = _formatCalculatorNumber(result.target!);
      }

      if (riskUsed > 0) {
        _riskUsedCtrl.text = _formatRiskUsed(riskUsed);
      }

      _plannedVolume = result.suggestedVolume;
      _plannedRiskMoney = result.riskMoney;
      _actualRiskMoney = result.actualRisk;
      _riskCalculatorProfile = result.profileName;
      _riskCalculatorAccountCurrency = result.accountCurrency;
    });

    final s = S.read(context);
    final volumeText = _formatCalculatorNumber(result.suggestedVolume);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          s.isVi
              ? 'Đã áp dụng từ máy tính 1R. Volume gợi ý: $volumeText'
              : 'Applied from 1R Calculator. Suggested volume: $volumeText',
        ),
      ),
    );
  }

  double _suggestedRiskForGrade(TradeGrade grade) {
    switch (grade) {
      case TradeGrade.a:
        return 1.00;
      case TradeGrade.aMinus:
        return 0.75;
      case TradeGrade.b:
        return 0.50;
    }
  }

  double? _parseRiskUsedText(String text) {
    return double.tryParse(text.trim());
  }

  double _parseRiskUsed() {
    final text = _riskUsedCtrl.text.trim();
    if (text.isEmpty) return 1.0;

    final value = _parseRiskUsedText(text);
    if (value == null || value <= 0) return 1.0;

    return value;
  }

  Widget _riskQuickPick(double value) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final raw = _riskUsedCtrl.text.trim();
    final selected = raw.isEmpty
        ? value == 1.0
        : raw == _formatRiskUsed(value);

    return ChoiceChip(
      label: Text('${_formatRiskUsed(value)}R'),
      selected: selected,
      showCheckmark: false,
      selectedColor: primary.withOpacity(
        theme.brightness == Brightness.dark ? 0.22 : 0.12,
      ),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      side: BorderSide(
        color: selected
            ? primary.withOpacity(0.35)
            : theme.colorScheme.outlineVariant,
      ),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: selected ? primary : theme.colorScheme.onSurface,
        fontWeight: FontWeight.w800,
      ),
      onSelected: (_) {
        setState(() {
          _riskUsedCtrl.text = _formatRiskUsed(value);
        });
      },
    );
  }

  void _showChecklistGuide() {
    final s = S.read(context);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final primary = theme.colorScheme.primary;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.isVi ? 'Cách dùng checklist' : 'How to use the checklist',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  s.isVi
                      ? 'Checklist này không dùng để đoán lệnh thắng hay thua. Nó dùng để đánh giá chất lượng quyết định và phân loại lệnh A / A- / B.'
                      : 'This checklist is not used to predict whether a trade will win or lose. It is used to evaluate decision quality and classify trades as A / A- / B.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _GuideItem(
                  title: s.isVi ? 'Bối cảnh đúng' : 'Market context valid',
                  body: s.isVi
                      ? 'Thị trường đang có điều kiện phù hợp với chiến lược của bạn. Ví dụ: trend-following cần xu hướng rõ; breakout cần vùng tích lũy hoặc mức giá quan trọng; Wyckoff/range cần range hoặc vùng đấu giá rõ.'
                      : 'The market condition supports your strategy. Example: trend-following needs a clear trend; breakout needs consolidation or a key level; Wyckoff/range needs a clear range or auction area.',
                ),
                _GuideItem(
                  title: s.isVi ? 'Vùng vào hợp lệ' : 'Entry zone valid',
                  body: s.isVi
                      ? 'Điểm vào nằm trong vùng hoặc điều kiện mà hệ thống cho phép, không phải vào ngẫu nhiên hoặc chase ngoài kế hoạch. Ví dụ: Wyckoff/range vào ở biên range, Spring/UTAD; trend-following vào ở pullback; breakout vào breakout hoặc retest; SMC/ICT vào POI, OB, FVG đúng điều kiện; mean reversion vào vùng extreme; scalping vào đúng signal zone/time window.'
                      : 'The entry is within the system’s planned area or condition, not random or chased. Example: Wyckoff/range at range edge, Spring/UTAD; trend-following at pullback; breakout at breakout or valid retest; SMC/ICT at POI, OB, FVG; mean reversion at an extreme; scalping at the right signal zone/time window.',
                ),
                _GuideItem(
                  title: s.isVi ? 'Execution đúng' : 'Execution valid',
                  body: s.isVi
                      ? 'Bạn vào/ra lệnh theo đúng quy trình đã định. Không vào quá sớm, không chase khi giá đã đi xa, không thoát lệnh tùy hứng nếu chưa có lý do.'
                      : 'Entry and exit follow the plan. No early entry, no chasing after price has moved too far, and no emotional exit without a valid reason.',
                ),
                _GuideItem(
                  title: s.isVi ? 'Risk đúng' : 'Risk valid',
                  body: s.isVi
                      ? 'Lệnh tuân thủ quy tắc rủi ro: đúng size, stop loss hợp lý, R:R đạt mức tối thiểu, không tăng size để gỡ, không vi phạm giới hạn rủi ro ngày/tuần.'
                      : 'The trade respects your risk rules: correct size, valid stop loss, minimum R:R, no revenge sizing, and no daily/weekly risk limit violation.',
                ),
                _GuideItem(
                  title: s.isVi ? 'Kỷ luật cảm xúc' : 'Emotional discipline',
                  body: s.isVi
                      ? 'Lệnh không bị thúc đẩy bởi FOMO, revenge trade, overtrade hoặc phá kỷ luật. Bạn vào lệnh vì setup, không phải vì cảm xúc.'
                      : 'The trade is not driven by FOMO, revenge trading, overtrading, or discipline breaks. You enter because of the setup, not emotion.',
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: primary.withOpacity(0.10),
                    border: Border.all(
                      color: primary.withOpacity(0.18),
                    ),
                  ),
                  child: Text(
                    s.isVi
                        ? 'A = đủ tiêu chí tốt\nA- = có 1 điểm chưa tối ưu\nB = sai bối cảnh, sai risk, mất kỷ luật cảm xúc hoặc sai từ 2 yếu tố trở lên'
                        : 'A = all key criteria are valid\nA- = one non-critical issue\nB = invalid context, invalid risk, emotional discipline break, or 2+ failed criteria',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
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

  double? _previewR() {
    final entry = _parse(_entryCtrl.text);
    final sl = _parse(_stopLossCtrl.text);
    final exit = _parse(_exitCtrl.text);

    if (entry == null || sl == null || exit == null) return null;

    final risk = _dir == TradeDirection.long ? (entry - sl) : (sl - entry);
    if (risk == 0) return null;

    final reward = _dir == TradeDirection.long ? (exit - entry) : (entry - exit);
    return reward / risk;
  }

  Future<void> _submit() async {
    final s = S.read(context);

    if (!_formKey.currentState!.validate()) return;

    final trade = Trade(
      dateTime: _dateTime,
      market: _market,
      strategy: _strategyCtrl.text.trim(),
      symbol: _symbolCtrl.text.trim(),
      direction: _dir,
      entry: double.parse(_entryCtrl.text.trim()),
      stopLoss: double.parse(_stopLossCtrl.text.trim()),
      exit: double.parse(_exitCtrl.text.trim()),
      riskUsed: _parseRiskUsed(),
      fee: _parseOptionalFee(),
      plannedVolume: _plannedVolume,
      plannedRiskMoney: _plannedRiskMoney,
      actualRiskMoney: _actualRiskMoney,
      riskCalculatorProfile: _riskCalculatorProfile,
      riskCalculatorAccountCurrency: _riskCalculatorAccountCurrency,
      checklist: c,
      beforeImagePath: _beforeImagePath,
      afterImagePath: _afterImagePath,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    final store = context.read<TradesStore>();

    if (widget.isEdit) {
      await store.updateTradeAt(widget.editIndex!, trade);
    } else {
      await store.addTrade(trade);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEdit
              ? s.updatedTradeAs(trade.grade.label)
              : s.savedTradeAs(trade.grade.label),
        ),
      ),
    );

    if (widget.isEdit) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dateTime = DateTime.now();
        _market = Market.forex;
        _dir = TradeDirection.long;
        _strategyCtrl.clear();
        _symbolCtrl.clear();
        _entryCtrl.clear();
        _stopLossCtrl.clear();
        _exitCtrl.clear();
        _riskUsedCtrl.clear();
        _feeCtrl.clear();
        _noteCtrl.clear();
        _beforeImagePath = null;
        _afterImagePath = null;

        _plannedVolume = null;
        _plannedRiskMoney = null;
        _actualRiskMoney = null;
        _riskCalculatorProfile = null;
        _riskCalculatorAccountCurrency = null;

        c = const TradeChecklist(
          contextOk: true,
          entryZoneOk: true,
          riskOk: true,
          executionOk: true,
          emotional: false,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final strategyChipBg = isDark
        ? colorScheme.surfaceContainerHighest.withOpacity(0.45)
        : colorScheme.surfaceContainerHighest;

    final strategyChipBorder = isDark
        ? colorScheme.outline.withOpacity(0.35)
        : colorScheme.outlineVariant;

    final strategyChipText = colorScheme.onSurface;

    final strategyChipSelectedBg = colorScheme.primary.withOpacity(
      isDark ? 0.22 : 0.12,
    );

    final strategyChipSelectedBorder = colorScheme.primary.withOpacity(
      isDark ? 0.45 : 0.30,
    );

    final strategyChipSelectedText = colorScheme.primary;

    final grade = classifyTrade(c);
    final previewR = _previewR();
    final suggestedRisk = _suggestedRiskForGrade(grade);
    final gradeColor = _gradeColor(grade);

    final cashPerR = context.watch<AppSettings>().cashPerR;
    final cashPerRText = s.isVi
        ? '${_formatCalculatorNumber(cashPerR)}\$'
        : '\$${_formatCalculatorNumber(cashPerR)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? s.editTrade : s.addTrade),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_rounded),
          label: Text(widget.isEdit ? s.updateTrade : s.saveTrade),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 150),
          children: [
            _GradePreviewCard(
              grade: grade,
              gradeColor: gradeColor,
              title: s.currentGrade,
              reason: grade.shortWhy,
              subtitle: s.basedOnChecklist,
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: s.basicInfo,
              icon: Icons.event_note_rounded,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _DateTimeButton(
                          icon: Icons.calendar_today_rounded,
                          label:
                          '${s.dateLabel}: ${_dateTime.year}-${_fmt2(_dateTime.month)}-${_fmt2(_dateTime.day)}',
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DateTimeButton(
                          icon: Icons.schedule_rounded,
                          label:
                          '${s.timeLabel}: ${_fmt2(_dateTime.hour)}:${_fmt2(_dateTime.minute)}',
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<Market>(
                    value: _market,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: s.market,
                    ),
                    items: Market.values
                        .map(
                          (m) => DropdownMenuItem<Market>(
                        value: m,
                        child: Text(m.label),
                      ),
                    )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _market = v);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  _DirectionToggle(
                    value: _dir,
                    longLabel: s.longLabel,
                    shortLabel: s.shortLabel,
                    onChanged: (value) {
                      setState(() => _dir = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: s.setupInfo,
              icon: Icons.auto_graph_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _strategyCtrl,
                    decoration: InputDecoration(
                      labelText: s.isVi
                          ? 'Chiến lược chính (tuỳ chọn)'
                          : 'Primary strategy (optional)',
                      hintText: s.isVi
                          ? 'Ví dụ: Price Action, SMC, Wyckoff...'
                          : 'Example: Price Action, SMC, Wyckoff...',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MutedText(text: s.quickPick),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _strategySuggestions.map((strategy) {
                      final selected = _strategyCtrl.text.trim().toLowerCase() ==
                          strategy.toLowerCase();
                      final isDefault = _isDefaultStrategy(strategy);

                      return InputChip(
                        label: Text(strategy),
                        selected: selected,
                        showCheckmark: false,
                        backgroundColor: strategyChipBg,
                        selectedColor: strategyChipSelectedBg,
                        side: BorderSide(
                          color: selected ? strategyChipSelectedBorder : strategyChipBorder,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                        labelStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: selected ? strategyChipSelectedText : strategyChipText,
                          fontWeight: FontWeight.w800,
                        ),
                        deleteIconColor: selected
                            ? strategyChipSelectedText
                            : colorScheme.onSurfaceVariant,
                        onPressed: () {
                          setState(() {
                            _strategyCtrl.text = strategy;
                          });
                        },
                        onDeleted: isDefault
                            ? null
                            : () {
                          _removeStrategyQuickPick(strategy);
                        },
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _addCurrentStrategyToQuickPick,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        s.isVi ? 'Lưu quick pick' : 'Save quick pick',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        backgroundColor: colorScheme.primary.withOpacity(
                          isDark ? 0.10 : 0.04,
                        ),
                        side: BorderSide(
                          color: colorScheme.primary.withOpacity(0.34),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _symbolCtrl,
                    decoration: InputDecoration(
                      labelText: s.pairSymbol,
                      hintText: s.pairHint,
                    ),
                    onChanged: (_) {
                      setState(() {
                        _clearPositionSizingSnapshot();
                      });
                    },
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return s.requiredField;
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: s.pricePlan,
              icon: Icons.query_stats_rounded,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openRiskCalculator,
                      icon: const Icon(Icons.calculate_rounded),
                      label: Text(
                        s.isVi ? 'Mở máy tính 1R' : 'Open 1R Calculator',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _entryCtrl,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: s.entry,
                    ),
                    onChanged: (_) {
                      setState(() {
                        _clearPositionSizingSnapshot();
                      });
                    },
                    validator: (v) {
                      if (_parse(v ?? '') == null) return s.numberField;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stopLossCtrl,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: s.stopLoss,
                    ),
                    onChanged: (_) {
                      setState(() {
                        _clearPositionSizingSnapshot();
                      });
                    },
                    validator: (v) {
                      if (_parse(v ?? '') == null) return s.numberField;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _exitCtrl,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: s.exit,
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (_parse(v ?? '') == null) return s.numberField;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _feeCtrl,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: s.isVi ? 'Phí giao dịch' : 'Fee',
                      hintText: s.isVi
                          ? 'Không bắt buộc: commission, funding, swap...'
                          : 'Optional: commission, funding, swap...',
                    ),
                    validator: (v) {
                      final text = (v ?? '').trim();
                      if (text.isEmpty) return null;
                      if (_parse(text) == null) return s.numberField;
                      if ((_parse(text) ?? 0) < 0) {
                        return s.isVi
                            ? 'Phí không được âm'
                            : 'Fee cannot be negative';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _riskUsedCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: s.isVi ? 'Risk theo 1R mặc định' : 'Risk vs default 1R',
                      hintText: s.isVi
                          ? 'Để trống = 1R'
                          : 'Leave blank = 1R',
                      helperText: s.isVi
                          ? '1R mặc định hiện tại: $cashPerRText. Gợi ý theo grade: ${_formatRiskUsed(suggestedRisk)}R'
                          : 'Current default 1R: $cashPerRText. Suggested by grade: ${_formatRiskUsed(suggestedRisk)}R',
                      helperStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final text = (v ?? '').trim();
                      if (text.isEmpty) return null;

                      final value = _parseRiskUsedText(text);
                      if (value == null) return s.numberField;

                      if (value <= 0) {
                        return s.isVi
                            ? 'Risk phải lớn hơn 0'
                            : 'Risk must be greater than 0';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _riskQuickPick(0.25),
                        _riskQuickPick(0.50),
                        _riskQuickPick(0.75),
                        _riskQuickPick(1.00),
                        ActionChip(
                          avatar: Icon(
                            Icons.auto_awesome_rounded,
                            size: 17,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          label: Text(
                            s.isVi
                                ? 'Gợi ý ${_formatRiskUsed(suggestedRisk)}R'
                                : 'Suggest ${_formatRiskUsed(suggestedRisk)}R',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          backgroundColor: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.16)
                              : Theme.of(context).colorScheme.primary.withOpacity(0.10),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.28),
                          ),
                          onPressed: () {
                            setState(() {
                              _riskUsedCtrl.text = _formatRiskUsed(suggestedRisk);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_plannedVolume != null || _actualRiskMoney != null) ...[
                    _PositionSizingPreviewCard(
                      volume: _plannedVolume,
                      plannedRiskMoney: _plannedRiskMoney,
                      actualRiskMoney: _actualRiskMoney,
                      profile: _riskCalculatorProfile,
                      currency: _riskCalculatorAccountCurrency,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _PreviewRCard(
                    label: s.autoR,
                    value: previewR,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: s.chartsAndNotes,
              icon: Icons.image_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ImagePickerCard(
                    title: s.beforeChart,
                    subtitle: s.tapToAddBeforeChart,
                    imagePath: _beforeImagePath,
                    onTap: _pickBeforeImage,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: s.note,
                      hintText: s.noteHint,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MutedText(text: s.afterChartLater),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: s.decisionChecklist,
              icon: Icons.fact_check_rounded,
              trailing: IconButton(
                tooltip: s.isVi ? 'Cách dùng checklist' : 'How to use checklist',
                onPressed: _showChecklistGuide,
                icon: const Icon(Icons.info_outline_rounded),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _MutedText(
                      text: s.isVi
                          ? 'Dùng để phân loại chất lượng lệnh A / A- / B'
                          : 'Used to classify trade quality: A / A- / B',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ChecklistTile(
                    title: s.isVi ? 'Bối cảnh đúng' : 'Market context valid',
                    subtitle: s.isVi
                        ? 'Thị trường phù hợp với chiến lược'
                        : 'Market condition supports the strategy',
                    value: c.contextOk,
                    onChanged: (v) {
                      setState(() => c = c.copyWith(contextOk: v));
                    },
                  ),
                  const SizedBox(height: 10),
                  _ChecklistTile(
                    title: s.isVi ? 'Vùng vào hợp lệ' : 'Entry zone valid',
                    subtitle: s.isVi
                        ? 'Điểm vào nằm trong vùng hệ thống cho phép'
                        : 'Entry is within the system’s planned area',
                    value: c.entryZoneOk,
                    onChanged: (v) {
                      setState(() => c = c.copyWith(entryZoneOk: v));
                    },
                  ),
                  const SizedBox(height: 10),
                  _ChecklistTile(
                    title: s.isVi ? 'Execution đúng' : 'Execution valid',
                    subtitle: s.isVi
                        ? 'Vào/ra lệnh đúng theo kế hoạch'
                        : 'Entry/exit follows the plan',
                    value: c.executionOk,
                    onChanged: (v) {
                      setState(() => c = c.copyWith(executionOk: v));
                    },
                  ),
                  const SizedBox(height: 10),
                  _ChecklistTile(
                    title: s.isVi ? 'Risk đúng' : 'Risk valid',
                    subtitle: s.isVi
                        ? 'Tuân thủ size, stop loss và rủi ro'
                        : 'Size, stop loss and risk rules are respected',
                    value: c.riskOk,
                    onChanged: (v) {
                      setState(() => c = c.copyWith(riskOk: v));
                    },
                  ),
                  const SizedBox(height: 10),
                  _ChecklistTile(
                    title: s.isVi ? 'Kỷ luật cảm xúc' : 'Emotional discipline',
                    subtitle: s.isVi
                        ? 'Không FOMO, revenge trade, overtrade'
                        : 'No FOMO, revenge trade or overtrade',
                    value: !c.emotional,
                    onChanged: (v) {
                      setState(() => c = c.copyWith(emotional: !v));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _gradeColor(TradeGrade grade) {
    switch (grade) {
      case TradeGrade.a:
        return Colors.green;
      case TradeGrade.aMinus:
        return Colors.orange;
      case TradeGrade.b:
        return Colors.red;
    }
  }
}

class _DirectionToggle extends StatelessWidget {
  final TradeDirection value;
  final String longLabel;
  final String shortLabel;
  final ValueChanged<TradeDirection> onChanged;

  const _DirectionToggle({
    required this.value,
    required this.longLabel,
    required this.shortLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(isDark ? 0.32 : 0.75),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.50),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DirectionOption(
              selected: value == TradeDirection.long,
              label: longLabel,
              icon: Icons.north_east_rounded,
              color: const Color(0xFF22C55E),
              onTap: () => onChanged(TradeDirection.long),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _DirectionOption(
              selected: value == TradeDirection.short,
              label: shortLabel,
              icon: Icons.south_east_rounded,
              color: const Color(0xFFEF4444),
              onTap: () => onChanged(TradeDirection.short),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionOption extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DirectionOption({
    required this.selected,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = selected
        ? color.withOpacity(isDark ? 0.22 : 0.13)
        : Colors.transparent;

    final borderColor = selected
        ? color.withOpacity(isDark ? 0.46 : 0.30)
        : Colors.transparent;

    final contentColor = selected ? color : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: borderColor,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? Icons.check_rounded : icon,
                size: 19,
                color: contentColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: contentColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradePreviewCard extends StatelessWidget {
  final TradeGrade grade;
  final Color gradeColor;
  final String title;
  final String reason;
  final String subtitle;

  const _GradePreviewCard({
    required this.grade,
    required this.gradeColor,
    required this.title,
    required this.reason,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _ProCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: gradeColor.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: gradeColor.withOpacity(0.25),
              ),
            ),
            child: Text(
              grade.label,
              style: TextStyle(
                color: gradeColor,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.25,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _ProCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBubble(icon: icon),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;

  const _IconBubble({required this.icon});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: primary.withOpacity(0.11),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primary.withOpacity(0.18),
        ),
      ),
      child: Icon(
        icon,
        color: primary,
        size: 20,
      ),
    );
  }
}

class _MutedText extends StatelessWidget {
  final String text;

  const _MutedText({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DateTimeButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurface,
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.7),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class _PositionSizingPreviewCard extends StatelessWidget {
  final double? volume;
  final double? plannedRiskMoney;
  final double? actualRiskMoney;
  final String? profile;
  final String? currency;

  const _PositionSizingPreviewCard({
    required this.volume,
    required this.plannedRiskMoney,
    required this.actualRiskMoney,
    required this.profile,
    required this.currency,
  });

  String _formatNumber(double? value) {
    if (value == null) return '—';

    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value
        .toStringAsFixed(4)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _formatMoney(double? value) {
    final c = currency ?? 'USD';
    final n = _formatNumber(value);

    if (c == 'USD') return '\$$n';

    return '$c $n';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.primary.withOpacity(
          theme.brightness == Brightness.dark ? 0.12 : 0.08,
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.calculate_rounded,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.isVi ? 'Position sizing từ 1R Calculator' : 'Position sizing from 1R Calculator',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.isVi
                      ? 'Volume: ${_formatNumber(volume)} · Risk thực tế: ${_formatMoney(actualRiskMoney)}'
                      : 'Volume: ${_formatNumber(volume)} · Actual risk: ${_formatMoney(actualRiskMoney)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  s.isVi
                      ? 'Risk dự kiến: ${_formatMoney(plannedRiskMoney)} · Profile: ${profile ?? '—'}'
                      : 'Planned risk: ${_formatMoney(plannedRiskMoney)} · Profile: ${profile ?? '—'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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

class _PreviewRCard extends StatelessWidget {
  final String label;
  final double? value;

  const _PreviewRCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = value == null ? '—' : value!.toStringAsFixed(2);
    final color = value == null
        ? theme.colorScheme.onSurfaceVariant
        : value! >= 0
        ? Colors.green
        : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface.withOpacity(
          theme.brightness == Brightness.dark ? 0.32 : 0.75,
        ),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.38),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.query_stats_rounded,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            display,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ChecklistTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = value ? Colors.green : theme.colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface.withOpacity(
          theme.brightness == Brightness.dark ? 0.32 : 0.75,
        ),
        border: Border.all(
          color: value
              ? Colors.green.withOpacity(0.20)
              : theme.colorScheme.outlineVariant.withOpacity(0.38),
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green,
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
        secondary: Icon(
          value ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: activeColor,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imagePath;
  final VoidCallback onTap;

  const _ImagePickerCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 132,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: theme.colorScheme.surface.withOpacity(
            theme.brightness == Brightness.dark ? 0.32 : 0.75,
          ),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.38),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(imagePath!),
              fit: BoxFit.cover,
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.62),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        )
            : Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_rounded,
                  size: 36,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  final String title;
  final String body;

  const _GuideItem({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}