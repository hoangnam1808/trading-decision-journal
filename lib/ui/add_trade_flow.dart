import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/trade.dart';
import '../state/trades_store.dart';

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

  static const _strategySuggestions = [
    'Wyckoff',
    'Price Action',
    'SMC',
    'Breakout',
    'Trend Following',
    'Mean Reversion',
  ];

  late DateTime _dateTime;
  late Market _market;
  late TradeDirection _dir;

  final _strategyCtrl = TextEditingController();
  final _symbolCtrl = TextEditingController();
  final _entryCtrl = TextEditingController();
  final _stopLossCtrl = TextEditingController();
  final _exitCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _beforeImagePath;
  String? _afterImagePath;

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
      _feeCtrl.text = t.fee == 0 ? '' : t.fee.toString();
      _noteCtrl.text = t.note ?? '';

      _beforeImagePath = t.beforeImagePath;
      _afterImagePath = t.afterImagePath;
      c = t.checklist;
    } else {
      _dateTime = DateTime.now();
      _market = Market.forex;
      _dir = TradeDirection.long;
      _strategyCtrl.text = 'Wyckoff';
    }
  }

  @override
  void dispose() {
    _strategyCtrl.dispose();
    _symbolCtrl.dispose();
    _entryCtrl.dispose();
    _stopLossCtrl.dispose();
    _exitCtrl.dispose();
    _feeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
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
  void _showChecklistGuide() {
    final s = S.read(context);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final primary = Theme.of(sheetContext).colorScheme.primary;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.isVi ? 'Cách dùng checklist' : 'How to use the checklist',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  s.isVi
                      ? 'Checklist này không dùng để đoán lệnh thắng hay thua. Nó dùng để đánh giá chất lượng quyết định và phân loại lệnh A / A- / B.'
                      : 'This checklist is not used to predict whether a trade will win or lose. It is used to evaluate decision quality and classify trades as A / A- / B.',
                  style: const TextStyle(height: 1.45),
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
                    borderRadius: BorderRadius.circular(16),
                    color: primary.withOpacity(0.08),
                  ),
                  child: Text(
                    s.isVi
                        ? 'A = đủ tiêu chí tốt\nA- = có 1 điểm chưa tối ưu\nB = sai bối cảnh, sai risk, mất kỷ luật cảm xúc hoặc sai từ 2 yếu tố trở lên'
                        : 'A = all key criteria are valid\nA- = one non-critical issue\nB = invalid context, invalid risk, emotional discipline break, or 2+ failed criteria',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
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

    final reward =
    _dir == TradeDirection.long ? (exit - entry) : (entry - exit);
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
      fee: _parseOptionalFee(),
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
        _strategyCtrl.text = 'Wyckoff';
        _symbolCtrl.clear();
        _entryCtrl.clear();
        _stopLossCtrl.clear();
        _exitCtrl.clear();
        _feeCtrl.clear();
        _noteCtrl.clear();
        _beforeImagePath = null;
        _afterImagePath = null;
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
    final grade = classifyTrade(c);
    final previewR = _previewR();
    final gradeColor = _gradeColor(grade);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? s.editTrade : s.addTrade),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_outlined),
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Theme.of(context).cardColor,
                border: Border.all(color: Colors.black12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: gradeColor.withOpacity(0.15),
                    child: Text(
                      grade.label,
                      style: TextStyle(
                        color: gradeColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.currentGrade,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          grade.shortWhy,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.basedOnChecklist,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _SectionCard(
              title: s.basicInfo,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(
                            '${s.dateLabel}: ${_dateTime.year}-${_fmt2(_dateTime.month)}-${_fmt2(_dateTime.day)}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.schedule_outlined),
                          label: Text(
                            '${s.timeLabel}: ${_fmt2(_dateTime.hour)}:${_fmt2(_dateTime.minute)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<Market>(
                    value: _market,
                    decoration: InputDecoration(
                      labelText: s.market,
                      border: const OutlineInputBorder(),
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SegmentedButton<TradeDirection>(
                      segments: [
                        ButtonSegment<TradeDirection>(
                          value: TradeDirection.long,
                          label: Text(s.longLabel),
                        ),
                        ButtonSegment<TradeDirection>(
                          value: TradeDirection.short,
                          label: Text(s.shortLabel),
                        ),
                      ],
                      selected: {_dir},
                      onSelectionChanged: (selection) {
                        setState(() => _dir = selection.first);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _SectionCard(
              title: s.setupInfo,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _strategyCtrl,
                    decoration: InputDecoration(
                      labelText: s.primaryStrategy,
                      hintText: s.strategyHint,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return s.requiredField;
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.quickPick,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _strategySuggestions.map((strategy) {
                      final selected =
                          _strategyCtrl.text.trim().toLowerCase() ==
                              strategy.toLowerCase();

                      return ChoiceChip(
                        label: Text(strategy),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _strategyCtrl.text = strategy;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _symbolCtrl,
                    decoration: InputDecoration(
                      labelText: s.pairSymbol,
                      hintText: s.pairHint,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return s.requiredField;
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _SectionCard(
              title: s.pricePlan,
              child: Column(
                children: [
                  TextFormField(
                    controller: _entryCtrl,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: s.entry,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
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
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
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
                      border: const OutlineInputBorder(),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: s.isVi ? 'Phí giao dịch' : 'Fee',
                      hintText: s.isVi
                          ? 'Không bắt buộc: commission, funding, swap...'
                          : 'Optional: commission, funding, swap...',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final text = (v ?? '').trim();
                      if (text.isEmpty) return null;
                      if (_parse(text) == null) return s.numberField;
                      if ((_parse(text) ?? 0) < 0) {
                        return s.isVi ? 'Phí không được âm' : 'Fee cannot be negative';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.black.withOpacity(0.03),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.query_stats_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.autoR,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          previewR == null ? '—' : previewR.toStringAsFixed(2),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: previewR == null
                                ? Colors.grey.shade700
                                : (previewR >= 0 ? Colors.green : Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _SectionCard(
              title: s.chartsAndNotes,
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
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.afterChartLater,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _SectionCard(
              title: s.decisionChecklist,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          s.isVi
                              ? 'Dùng để phân loại chất lượng lệnh A / A- / B'
                              : 'Used to classify trade quality: A / A- / B',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: s.isVi ? 'Cách dùng checklist' : 'How to use checklist',
                        onPressed: () {
                          _showChecklistGuide();
                        },
                        icon: const Icon(Icons.info_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

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

            const SizedBox(height: 12),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Theme.of(context).cardColor,
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          child,
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
    final activeColor = value ? Colors.green : Colors.grey.shade500;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withOpacity(0.03),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        secondary: Icon(
          value ? Icons.check_circle : Icons.radio_button_unchecked,
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

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.black.withOpacity(0.03),
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
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white),
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
                const Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 36,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}