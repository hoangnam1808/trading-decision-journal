import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/trade.dart';
import '../reports/export_report_sheet.dart';
import '../state/trades_store.dart';

class RequestReviewCard extends StatelessWidget {
  const RequestReviewCard({super.key});

  static const String _contactEmail = 'decisionjournal.review@gmail.com';

  void _showReviewSheet(BuildContext parentContext, List<Trade> trades) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final s = S.of(sheetContext);
        final stats = _ReviewStats.fromTrades(trades);
        final isEarly = stats.totalTrades < 30;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SheetHeader(
                  title: s.isVi ? 'Yêu cầu review journal' : 'Request Journal Review',
                  subtitle: s.isVi
                      ? 'Review thủ công bởi Trading Performance Analyst. Có thể dùng dữ liệu trong app hoặc journal bên ngoài.'
                      : 'Manual review by a Trading Performance Analyst. You can use app data or an external journal.',
                ),
                const SizedBox(height: 14),

                _StatusCard(
                  isEarly: isEarly,
                  tradesCount: stats.totalTrades,
                  isVi: s.isVi,
                ),

                const SizedBox(height: 12),

                _StatsCard(
                  stats: stats,
                  isVi: s.isVi,
                ),

                const SizedBox(height: 12),

                _InfoCard(
                  icon: Icons.upload_file_rounded,
                  title: s.isVi ? 'Bạn có thể gửi journal từ nguồn khác' : 'External journals are accepted',
                  body: s.isVi
                      ? 'Bạn có thể gửi Excel, Google Sheet, CSV, ảnh chart trước/sau lệnh, lịch sử MT4/MT5, Binance, TradingView, Notion hoặc Google Doc.'
                      : 'You can send Excel, Google Sheet, CSV, before/after chart screenshots, MT4/MT5 history, Binance, TradingView, Notion, or Google Doc.',
                ),

                const SizedBox(height: 12),

                _PricingCard(isVi: s.isVi),

                const SizedBox(height: 12),

                _InfoCard(
                  icon: Icons.lock_outline_rounded,
                  title: s.isVi ? 'Quyền riêng tư' : 'Privacy',
                  body: s.isVi
                      ? 'Dữ liệu journal nằm trên thiết bị của bạn. App chỉ gửi đi nếu bạn tự export và gửi cho analyst.'
                      : 'Your journal data stays on your device. The app only shares data if you export and send it yourself.',
                ),

                const SizedBox(height: 14),

                _ActionButton(
                  icon: Icons.content_copy_rounded,
                  label: s.isVi ? 'Copy nội dung yêu cầu review' : 'Copy request message',
                  onPressed: () {
                    _copyRequestMessage(
                      parentContext: parentContext,
                      stats: stats,
                      isVi: s.isVi,
                    );
                  },
                ),
                const SizedBox(height: 10),

                _ActionButton(
                  icon: Icons.ios_share_rounded,
                  label: s.isVi ? 'Xuất report từ app' : 'Export app report',
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await Future<void>.delayed(const Duration(milliseconds: 180));

                    if (!parentContext.mounted) return;
                    showExportReportSheet(parentContext);
                  },
                ),
                const SizedBox(height: 10),

                _ActionButton(
                  icon: Icons.alternate_email_rounded,
                  label: s.isVi ? 'Copy thông tin liên hệ' : 'Copy contact info',
                  onPressed: () {
                    _copyContactInfo(
                      parentContext: parentContext,
                      isVi: s.isVi,
                    );
                  },
                  filled: false,
                ),

                const SizedBox(height: 14),

                Text(
                  s.isVi
                      ? 'Đây là dịch vụ review journal thủ công, không phải tín hiệu giao dịch hay lời khuyên tài chính. Không đảm bảo lợi nhuận.'
                      : 'This is a manual journal review service, not trading signals or financial advice. No profit is guaranteed.',
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _copyRequestMessage({
    required BuildContext parentContext,
    required _ReviewStats stats,
    required bool isVi,
  }) async {
    final message = isVi
        ? '''
Tôi muốn yêu cầu review journal giao dịch.

Số lệnh hiện có trong Decision Journal: ${stats.totalTrades}
Net R: ${_signedR(stats.netR)}
Winrate: ${stats.winrate.toStringAsFixed(1)}%
Phân loại: A ${stats.aCount}, A- ${stats.aMinusCount}, B ${stats.bCount}
Tỷ lệ lệnh B: ${stats.bRatio.toStringAsFixed(1)}%

Tôi có thể gửi thêm journal từ nguồn khác nếu cần:
Excel / Google Sheet / CSV / ảnh chart / MT4-MT5 / Binance / TradingView / Notion / Google Doc.

Mục tiêu review:
- Kiểm tra chất lượng quyết định
- Phân loại setup A / A- / B
- Tìm lỗi risk management
- Tìm lỗi cảm xúc / overtrade
- Đề xuất cách lọc setup tốt hơn

Tôi hiểu rằng nếu số mẫu còn ít, kết luận về expectancy sẽ chỉ mang tính tham khảo.

Vui lòng báo phạm vi review, giá cuối cùng và phương thức thanh toán phù hợp.
'''
        : '''
I would like to request a trading journal review.

Trades currently logged in Decision Journal: ${stats.totalTrades}
Net R: ${_signedR(stats.netR)}
Winrate: ${stats.winrate.toStringAsFixed(1)}%
Breakdown: A ${stats.aCount}, A- ${stats.aMinusCount}, B ${stats.bCount}
B-trade ratio: ${stats.bRatio.toStringAsFixed(1)}%

I can also provide an external journal source if needed:
Excel / Google Sheet / CSV / chart screenshots / MT4-MT5 / Binance / TradingView / Notion / Google Doc.

Review goals:
- Check decision quality
- Classify setups as A / A- / B
- Find risk-management issues
- Find emotional or overtrading patterns
- Improve setup filtering

I understand that if the sample size is small, expectancy conclusions will be limited.

Please confirm the review scope, final price, and available payment method.
''';

    await Clipboard.setData(ClipboardData(text: message.trim()));

    if (!parentContext.mounted) return;
    ScaffoldMessenger.of(parentContext).showSnackBar(
      SnackBar(
        content: Text(
          isVi ? 'Đã copy nội dung yêu cầu review.' : 'Review request message copied.',
        ),
      ),
    );
  }

  Future<void> _copyContactInfo({
    required BuildContext parentContext,
    required bool isVi,
  }) async {
    final text = isVi
        ? '''
Email review: $_contactEmail

Phương thức thanh toán sẽ được xác nhận sau khi thống nhất phạm vi review.
Có thể hỗ trợ chuyển khoản ngân hàng, thanh toán quốc tế hoặc crypto theo thỏa thuận.
'''
        : '''
Review email: $_contactEmail

Payment method will be confirmed after the review scope is agreed.
Available options may include bank transfer, international transfer, or crypto by agreement.
''';

    await Clipboard.setData(ClipboardData(text: text.trim()));

    if (!parentContext.mounted) return;
    ScaffoldMessenger.of(parentContext).showSnackBar(
      SnackBar(
        content: Text(
          isVi ? 'Đã copy thông tin liên hệ.' : 'Contact info copied.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final store = context.watch<TradesStore>();

    return _ProCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBubble(icon: Icons.fact_check_rounded),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.requestReview,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      s.isVi
                          ? 'Có journal giao dịch cần được xem lại?'
                          : 'Have a trading journal that needs a second look?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            s.isVi
                ? 'Nhận review thủ công bởi Trading Performance Analyst. Tập trung vào chất lượng quyết định, phân loại setup A/A-/B, risk management và lỗi cảm xúc — không phải tín hiệu giao dịch hay cam kết lợi nhuận.'
                : 'Get a manual review by a Trading Performance Analyst. Focused on decision quality, A/A-/B setup classification, risk management, and emotional patterns — not trading signals or profit guarantees.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _showReviewSheet(
              context,
              List<Trade>.from(store.items),
            ),
            icon: const Icon(Icons.fact_check_outlined),
            label: Text(s.requestReview),
          ),
        ],
      ),
    );
  }
}

class _ReviewStats {
  final int totalTrades;
  final double netR;
  final double winrate;
  final int aCount;
  final int aMinusCount;
  final int bCount;
  final double bRatio;

  const _ReviewStats({
    required this.totalTrades,
    required this.netR,
    required this.winrate,
    required this.aCount,
    required this.aMinusCount,
    required this.bCount,
    required this.bRatio,
  });

  factory _ReviewStats.fromTrades(List<Trade> trades) {
    final total = trades.length;
    final netR = trades.fold<double>(0, (sum, t) => sum + t.resultR);
    final wins = trades.where((t) => t.resultR > 0).length;

    final a = trades.where((t) => t.grade == TradeGrade.a).length;
    final aMinus = trades.where((t) => t.grade == TradeGrade.aMinus).length;
    final b = trades.where((t) => t.grade == TradeGrade.b).length;

    return _ReviewStats(
      totalTrades: total,
      netR: netR,
      winrate: total == 0 ? 0 : wins / total * 100,
      aCount: a,
      aMinusCount: aMinus,
      bCount: b,
      bRatio: total == 0 ? 0 : b / total * 100,
    );
  }
}

String _signedR(double value) {
  final sign = value > 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(2)}R';
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SheetHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconBubble(icon: Icons.manage_search_rounded),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 5),
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

class _StatusCard extends StatelessWidget {
  final bool isEarly;
  final int tradesCount;
  final bool isVi;

  const _StatusCard({
    required this.isEarly,
    required this.tradesCount,
    required this.isVi,
  });

  @override
  Widget build(BuildContext context) {
    final color = isEarly ? Colors.orange : Colors.green;

    return _SoftBox(
      borderColor: color.withOpacity(0.22),
      backgroundColor: color.withOpacity(0.10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isEarly ? Icons.hourglass_top_rounded : Icons.verified_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isVi
                  ? 'Review journal thủ công bởi Trading Performance Analyst. Tập trung vào chất lượng quyết định, setup A/A-/B, risk management và lỗi cảm xúc — không phải tín hiệu giao dịch.'
                  : 'Manual journal review by a Trading Performance Analyst. Focused on decision quality, A/A-/B setup classification, risk management, and emotional mistakes — not trading signals.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final _ReviewStats stats;
  final bool isVi;

  const _StatsCard({
    required this.stats,
    required this.isVi,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftBox(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _StatChip(label: isVi ? 'Lệnh' : 'Trades', value: '${stats.totalTrades}'),
          _StatChip(label: 'Net R', value: _signedR(stats.netR)),
          _StatChip(label: 'Winrate', value: '${stats.winrate.toStringAsFixed(1)}%'),
          _StatChip(label: 'A/A-/B', value: '${stats.aCount}/${stats.aMinusCount}/${stats.bCount}'),
          _StatChip(label: isVi ? 'B trade' : 'B ratio', value: '${stats.bRatio.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final bool isVi;

  const _PricingCard({
    required this.isVi,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoTitle(
            icon: Icons.payments_rounded,
            title: isVi ? 'Giá review dự kiến' : 'Estimated pricing',
          ),
          const SizedBox(height: 12),
          _PriceRow(
            title: 'Early Review',
            price: 'from \$19',
            subtitle: isVi
                ? 'Dưới 30 lệnh hoặc journal còn ít mẫu.'
                : 'Fewer than 30 trades or early-stage journal.',
          ),
          const SizedBox(height: 10),
          _PriceRow(
            title: 'Journal Review',
            price: 'from \$49',
            subtitle: isVi
                ? 'Khuyến nghị 30–50 lệnh để review ổn định hơn.'
                : '30–50 trades recommended for a more reliable review.',
          ),
          const SizedBox(height: 10),
          _PriceRow(
            title: 'Deep Review',
            price: 'from \$99',
            subtitle: isVi
                ? 'Journal nhiều dữ liệu, ảnh chart hoặc cần report sâu.'
                : 'More data, chart screenshots, or deeper written report.',
          ),
          const SizedBox(height: 12),
          Text(
            isVi
                ? 'Giá cuối cùng tùy vào số lượng lệnh, ảnh chart và độ sâu review. Phương thức thanh toán sẽ được xác nhận sau khi thống nhất phạm vi review. Có thể hỗ trợ chuyển khoản ngân hàng, thanh toán quốc tế hoặc crypto theo thỏa thuận.'
                : 'Final pricing depends on sample size, chart screenshots, and review depth. Payment method will be confirmed after the review scope is agreed. Available options may include bank transfer, international transfer, or crypto by agreement.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoTitle(icon: icon, title: title),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _InfoTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Icon(icon, color: primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;

  const _PriceRow({
    required this.title,
    required this.price,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              const SizedBox(height: 2),
              Text(
                subtitle,
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
        Text(
          price,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool filled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}



class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 112,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(
          theme.brightness == Brightness.dark ? 0.32 : 0.75,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftBox extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;

  const _SoftBox({
    required this.child,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor ??
            theme.colorScheme.surface.withOpacity(
              theme.brightness == Brightness.dark ? 0.32 : 0.75,
            ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ??
              theme.colorScheme.outlineVariant.withOpacity(0.38),
        ),
      ),
      child: child,
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

class _IconBubble extends StatelessWidget {
  final IconData icon;

  const _IconBubble({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary.withOpacity(0.18),
        ),
      ),
      child: Icon(
        icon,
        color: primary,
        size: 23,
      ),
    );
  }
}