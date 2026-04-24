import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../state/app_settings.dart';
import '../reports/export_report_sheet.dart';
import 'request_review_card.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _cashPerRCtrl;

  @override
  void initState() {
    super.initState();
    _cashPerRCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _cashPerRCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final s = S.of(context);

    final currentText = settings.cashPerR.toStringAsFixed(
      settings.cashPerR % 1 == 0 ? 0 : 2,
    );
    if (_cashPerRCtrl.text != currentText) {
      _cashPerRCtrl.text = currentText;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          s.settings,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),

        Card(
          child: ListTile(
            title: Text(s.language),
            subtitle: Text(settings.lang.label),
            trailing: DropdownButton<AppLang>(
              value: settings.lang,
              items: [
                DropdownMenuItem(
                  value: AppLang.en,
                  child: Text(AppLang.en.label),
                ),
                DropdownMenuItem(
                  value: AppLang.vi,
                  child: Text(AppLang.vi.label),
                ),
              ],
              onChanged: (v) {
                if (v != null) {
                  settings.setLang(v);
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: ListTile(
            title: Text(s.theme),
            subtitle: Text(
              switch (settings.themeMode) {
                ThemeMode.system => s.system,
                ThemeMode.light => s.light,
                ThemeMode.dark => s.dark,
              },
            ),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(s.system),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(s.light),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(s.dark),
                ),
              ],
              onChanged: (v) {
                if (v != null) {
                  settings.setThemeMode(v);
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.defaultCashPerR,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cashPerRCtrl,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: s.cashPerR,
                    hintText: s.cashPerRHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
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
                    child: Text(s.saveTrade),
                  ),
                ),
              ],
            ),
          ),
        ),
        _ReportExportCard(
          onTap: () => showExportReportSheet(context),
        ),
        const SizedBox(height: 16),
        const RequestReviewCard(),
        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(s.disclaimer),
          ),
        ),
      ],
    );
  }
}
class _ReportExportCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ReportExportCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: primary.withOpacity(0.10),
                  child: Icon(
                    Icons.assessment_outlined,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reports & Export',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Export your trading performance as an image or PDF report.',
                        style: TextStyle(
                          color: Colors.black54,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.ios_share_outlined),
                label: const Text('Export Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}