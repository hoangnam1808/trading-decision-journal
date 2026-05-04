import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'risk_calculator_screen.dart';
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
    final theme = Theme.of(context);

    final currentText = settings.cashPerR.toStringAsFixed(
      settings.cashPerR % 1 == 0 ? 0 : 2,
    );

    if (_cashPerRCtrl.text != currentText) {
      _cashPerRCtrl.text = currentText;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 132),
      children: [
        _ProfileHeader(
          title: s.settings,
          subtitle: s.isVi
              ? 'Tùy chỉnh ngôn ngữ, giao diện và cấu hình report.'
              : 'Customize language, appearance, and report settings.',
        ),
        const SizedBox(height: 16),

        _SettingsTile(
          icon: Icons.language_rounded,
          title: s.language,
          subtitle: settings.lang.label,
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<AppLang>(
              value: settings.lang,
              borderRadius: BorderRadius.circular(18),
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

        _SettingsTile(
          icon: Icons.dark_mode_rounded,
          title: s.theme,
          subtitle: switch (settings.themeMode) {
            ThemeMode.system => s.system,
            ThemeMode.light => s.light,
            ThemeMode.dark => s.dark,
          },
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              borderRadius: BorderRadius.circular(18),
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

        _ProCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardTitleRow(
                icon: Icons.attach_money_rounded,
                title: s.defaultCashPerR,
                subtitle: s.isVi
                    ? 'Dùng để quy đổi R sang tiền trong lịch và report.'
                    : 'Used to convert R into money in calendar and reports.',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _cashPerRCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: s.cashPerR,
                  hintText: s.cashPerRHint,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () async {
                    final value = double.tryParse(_cashPerRCtrl.text.trim());
                    if (value == null || value <= 0) return;

                    await context.read<AppSettings>().setCashPerR(value);

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.cashPerRSaved)),
                    );
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: Text(s.save),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        _RiskCalculatorCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RiskCalculatorScreen(
                  returnResultOnUse: false,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        _ReportExportCard(
          onTap: () => showExportReportSheet(context),
        ),

        const SizedBox(height: 12),

        const RequestReviewCard(),

        const SizedBox(height: 12),

        _ProCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.disclaimer,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ProfileHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _ProCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          _IconBubble(icon: icon),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
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
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _CardTitleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CardTitleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconBubble(icon: icon),
        const SizedBox(width: 13),
        Expanded(
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
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;

  const _IconBubble({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: primary.withOpacity(0.11),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary.withOpacity(0.18),
        ),
      ),
      child: Icon(
        icon,
        color: primary,
        size: 22,
      ),
    );
  }
}

class _RiskCalculatorCard extends StatelessWidget {
  final VoidCallback onTap;

  const _RiskCalculatorCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);

    return _ProCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitleRow(
            icon: Icons.calculate_rounded,
            title: s.isVi ? 'Máy tính 1R' : '1R Calculator',
            subtitle: s.isVi
                ? 'Tính khối lượng vào lệnh từ tài khoản, mức rủi ro, entry và stop loss.'
                : 'Calculate position size using account size, planned risk, entry, and stop loss.',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(s.isVi ? 'Mở máy tính 1R' : 'Open 1R Calculator'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.isVi
                ? 'Lên khối lượng theo rủi ro dự kiến. Phù hợp với nhiều phong cách giao dịch khác nhau.'
                : 'Plan position size from your intended risk. Designed to support different trading styles.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
    final s = S.of(context);
    final theme = Theme.of(context);

    return _ProCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitleRow(
            icon: Icons.assessment_rounded,
            title: s.isVi ? 'Report & Xuất dữ liệu' : 'Reports & Export',
            subtitle: s.isVi
                ? 'Xuất hiệu suất giao dịch thành ảnh hoặc báo cáo PDF.'
                : 'Export your trading performance as an image or PDF report.',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.ios_share_rounded),
              label: Text(s.isVi ? 'Xuất report' : 'Export Report'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.isVi
                ? 'Hỗ trợ export theo kỳ lọc, tháng, năm hoặc khoảng thời gian tùy chỉnh.'
                : 'Supports current filter, monthly, yearly, or custom date range exports.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}