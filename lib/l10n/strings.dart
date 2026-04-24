import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_settings.dart';

class S {
  final AppLang lang;
  const S(this.lang);

  static S of(BuildContext context) {
    final lang = context.watch<AppSettings>().lang;
    return S(lang);
  }
  static S read(BuildContext context) {
    final lang = context.read<AppSettings>().lang;
    return S(lang);
  }
  bool get isVi => lang == AppLang.vi;
  String get analyst => 'Analyst';
  String get equityView => isVi ? 'Equity' : 'Equity';
  String get calendarView => isVi ? 'Lịch' : 'Calendar';
  String get defaultCashPerR =>
      isVi ? 'Tiền mặc định cho 1R' : 'Default cash per 1R';
  String get cashPerRSaved =>
      isVi ? 'Đã lưu giá trị tiền cho 1R' : 'Cash per 1R saved';
  String get calendarHistory =>
      isVi ? 'Lịch sử giao dịch' : 'Trade History Calendar';
  String get monthSummary => isVi ? 'Tổng tháng' : 'Month Summary';
  String get selectedDayLabel => isVi ? 'Ngày đã chọn' : 'Selected Day';
  String get noTradesOnThisDay =>
      isVi ? 'Không có lệnh trong ngày này' : 'No trades on this day';
  String get requestReview => isVi ? 'Yêu cầu review' : 'Request Review';

  String get reviewByMeTitle => isVi
      ? 'Review thủ công bởi Trading Analyst'
      : 'Manual review by Trading Analyst';

  String get reviewByMeSubtitle => isVi
      ? 'Không phải phân tích tự động'
      : 'Not an automated analysis';

  String get addTradeFab => isVi ? 'Thêm lệnh' : 'Add Trade';

  String get reviewCtaHeadline => isVi
      ? 'Có 30–50 lệnh và muốn biết mình đang sai ở đâu?'
      : 'Have 30–50 trades and want to know what is actually going wrong?';

  String get reviewCtaBody => isVi
      ? 'Chuỗi lệnh của bạn sẽ được Trading Analyst review thủ công để tìm ra vấn đề về chất lượng quyết định, lọc setup, quản lý rủi ro và hiệu suất chiến lược.'
      : 'Your trade sample will be manually reviewed by a Trading Analyst to find issues in decision quality, setup filtering, risk management, and strategy performance.';

  String get manualNotAuto => isVi
      ? 'Đây là review thủ công bởi Trading Analyst, không phải báo cáo tự động từ app.'
      : 'This is a manual review by a Trading Analyst, not an automated app-generated report.';

  String get whatYouGet => isVi ? 'Bạn sẽ được review gì?' : 'What you will get';
  String get reviewPoint1 => isVi
      ? 'Chất lượng quyết định A / A- / B trong toàn bộ mẫu lệnh'
      : 'A / A- / B decision quality across your full sample';
  String get reviewPoint2 => isVi
      ? 'Setup nào có edge thật và setup nào đang kéo tụt hiệu suất'
      : 'Which setups have real edge and which ones are dragging performance down';
  String get reviewPoint3 => isVi
      ? 'Lỗi về risk, overtrade, execution và hành vi'
      : 'Risk, overtrading, execution, and behavioral mistakes';
  String get reviewPoint4 => isVi
      ? 'Chiến lược nào đang hoạt động tốt hơn trong dữ liệu của bạn'
      : 'Which strategy is actually performing better in your own data';
  String get reviewPoint5 => isVi
      ? 'Gợi ý để giảm drawdown và cải thiện consistency'
      : 'Suggestions to reduce drawdown and improve consistency';

  String get idealFor => isVi ? 'Phù hợp nếu bạn:' : 'Best for you if you:';
  String get reviewFit1 => isVi
      ? 'đã có khoảng 30–50 lệnh'
      : 'already have around 30–50 trades';
  String get reviewFit2 => isVi
      ? 'có lúc có lợi nhuận nhưng chưa ổn định'
      : 'can be profitable sometimes but not consistently';
  String get reviewFit3 => isVi
      ? 'muốn biết mình nên bỏ setup nào và giữ setup nào'
      : 'want to know what to cut and what to keep';

  String get close => isVi ? 'Đóng' : 'Close';
  String get contactMeLater => isVi
      ? 'Phần liên hệ trực tiếp có thể thêm ở bước sau.'
      : 'Direct contact action can be added in the next step.';

  String get basicInfo => isVi ? 'Thông tin cơ bản' : 'Basic Info';
  String get setupInfo => isVi ? 'Setup & chiến lược' : 'Setup & Strategy';
  String get pricePlan => isVi ? 'Giá & kế hoạch lệnh' : 'Price & Trade Plan';
  String get chartsAndNotes => isVi ? 'Chart & ghi chú' : 'Charts & Notes';
  String get currentGrade => isVi ? 'Phân loại hiện tại' : 'Current Grade';
  String get basedOnChecklist =>
      isVi ? 'Dựa trên checklist hiện tại' : 'Based on current checklist';
  String get tapToAddBeforeChart => isVi
      ? 'Chạm để thêm chart trước lệnh'
      : 'Tap to add before-entry chart';

  String get dashboardTagline => isVi
      ? 'Biến nhật ký giao dịch thành quyết định tốt hơn.'
      : 'Turn your trade journal into better decisions.';

  String get unitMode => isVi ? 'Đơn vị' : 'Unit';
  String get rUnit => 'R';
  String get moneyUnit => isVi ? 'Tiền' : 'Money';
  String get cashPerR => isVi ? 'Giá trị tiền của 1R' : 'Cash value per 1R';
  String get cashPerRHint => isVi ? 'vd. 100' : 'e.g. 100';

  String get tradesCount => isVi ? 'Số lệnh' : 'Trades';
  String get netValue => isVi ? 'Lãi/lỗ ròng' : 'Net';
  String get strategy => isVi ? 'Chiến lược' : 'Strategy';
  String get primaryStrategy => isVi ? 'Chiến lược chính' : 'Primary strategy';
  String get strategyHint => isVi
      ? 'vd. Wyckoff, Price Action, SMC...'
      : 'e.g. Wyckoff, Price Action, SMC...';
  String get quickPick => isVi ? 'Chọn nhanh' : 'Quick pick';
  String get allStrategies =>
      isVi ? 'Tất cả chiến lược' : 'All strategies';

  String get compareStrategyAndQualityFilters => isVi
      ? 'So sánh theo chất lượng quyết định và chiến lược'
      : 'Compare quality and strategy filters';

  String get generalStrategy => isVi ? 'Chung' : 'General';
  String get addTrade => isVi ? 'Thêm lệnh' : 'Add Trade';
  String get editTrade => isVi ? 'Sửa lệnh' : 'Edit Trade';

  String get market => isVi ? 'Thị trường' : 'Market';
  String get pairSymbol => isVi ? 'Cặp / Mã' : 'Pair / Symbol';
  String get entry => 'Entry';
  String get stopLoss => isVi ? 'Cắt lỗ' : 'Stop Loss';
  String get exit => isVi ? 'Thoát lệnh' : 'Exit';
  String get autoR => 'Auto R';
  String get note => isVi ? 'Ghi chú' : 'Note';

  String get beforeChart => isVi ? 'Chart trước lệnh' : 'Before chart';
  String get afterChartLater => isVi
      ? 'Chart sau lệnh có thể thêm sau trong Chi tiết lệnh.'
      : 'After chart can be added later in Trade Detail.';

  String get decisionChecklist =>
      isVi ? 'Checklist quyết định' : 'Decision Checklist';

  String get contextOk => isVi ? 'Context OK' : 'Context OK';
  String get contextSub => isVi
      ? 'Đúng vị trí thị trường theo kế hoạch'
      : 'Right market location for your plan';

  String get executionOk => isVi ? 'Execution OK' : 'Execution OK';
  String get executionSub => isVi
      ? 'Vào/ra lệnh đúng theo quy trình'
      : 'Followed your entry/exit process';

  String get riskOk => isVi ? 'Risk OK' : 'Risk OK';
  String get riskSub => isVi
      ? 'Tuân thủ size và quy tắc rủi ro'
      : 'Sizing & risk rules respected';

  String get emotionalOvertrade =>
      isVi ? 'Cảm xúc / Overtrade' : 'Emotional / Overtrade';
  String get emotionalSub => isVi
      ? 'FOMO, trả thù thị trường, mất kỷ luật'
      : 'FOMO, revenge, tilt';

  String get longLabel => 'Long';
  String get shortLabel => 'Short';

  String get saveTrade => isVi ? 'Lưu lệnh' : 'Save trade';
  String get updateTrade => isVi ? 'Cập nhật lệnh' : 'Update trade';
  String get save => isVi ? 'Lưu' : 'Save';
  String savedTradeAs(String grade) => isVi
      ? 'Đã lưu lệnh loại $grade'
      : 'Saved trade as $grade';

  String updatedTradeAs(String grade) => isVi
      ? 'Đã cập nhật lệnh loại $grade'
      : 'Trade updated ($grade)';

  String get dateLabel => isVi ? 'Ngày' : 'Date';
  String get timeLabel => isVi ? 'Giờ' : 'Time';

  String get requiredField => isVi ? 'Bắt buộc' : 'Required';
  String get numberField => isVi ? 'Phải là số' : 'Number';

  String get noteHint => isVi
      ? 'Ghi chú ngắn / bài học / lỗi sai...'
      : 'Short review / lesson / mistake...';

  String get pairHint => isVi
      ? 'vd. EURUSD, XAUUSD, BTCUSDT'
      : 'e.g. EURUSD, XAUUSD, BTCUSDT';
  String get tradeDetail => isVi ? 'Chi tiết lệnh' : 'Trade Detail';
  String get tradeNotFound => isVi ? 'Không tìm thấy lệnh' : 'Trade not found';

  String get dateTime => isVi ? 'Ngày/Giờ' : 'Date/Time';
  String get grade => isVi ? 'Phân loại' : 'Grade';

  String get beforeChartTitle => isVi ? 'Chart trước lệnh' : 'Before Chart';
  String get afterChartTitle => isVi ? 'Chart sau lệnh' : 'After Chart';

  String get addLabel => isVi ? 'Thêm' : 'Add';
  String get replaceLabel => isVi ? 'Thay' : 'Replace';
  String get deleteTrade => isVi ? 'Xóa lệnh' : 'Delete trade';
  String get deleteConfirmTitle => isVi ? 'Xóa lệnh?' : 'Delete trade?';
  String get deleteConfirmBody => isVi
      ? 'Hành động này không thể hoàn tác.'
      : 'This action cannot be undone.';
  String get cancel => isVi ? 'Hủy' : 'Cancel';
  String get delete => isVi ? 'Xóa' : 'Delete';
  String get tradeDeleted => isVi ? 'Đã xóa lệnh' : 'Trade deleted';
  String get afterChartUpdated => isVi
      ? 'Đã cập nhật chart sau lệnh'
      : 'After chart updated';

  String imageNotAddedYet(String title) => isVi
      ? '$title chưa được thêm'
      : '$title not added yet';
  String get dashboard => isVi ? 'Tổng quan' : 'Dashboard';
  String get trades => isVi ? 'Lệnh' : 'Trades';
  String get add => isVi ? 'Thêm' : 'Add';
  String get equity => isVi ? 'Equity' : 'Equity';
  String get profile => isVi ? 'Hồ sơ' : 'Profile';

  String get settings => isVi ? 'Cài đặt' : 'Settings';
  String get language => isVi ? 'Ngôn ngữ' : 'Language';
  String get theme => isVi ? 'Giao diện' : 'Theme';
  String get system => isVi ? 'Theo máy' : 'System';
  String get light => isVi ? 'Sáng' : 'Light';
  String get dark => isVi ? 'Tối' : 'Dark';

  String get noTradesYet =>
      isVi ? 'Chưa có lệnh nào.' : 'No trades yet.';
  String get addFirstTradeToSeeStats => isVi
      ? 'Hãy thêm lệnh đầu tiên để xem thống kê.'
      : 'Add your first trade to see stats.';

  String get totalTrades => isVi ? 'Tổng lệnh' : 'Total Trades';
  String get netR => 'Net R';
  String get avgR => 'Avg R';
  String get winrate => isVi ? 'Tỷ lệ thắng' : 'Winrate';
  String get gradeBreakdown => isVi ? 'Phân bố phân loại' : 'Grade Breakdown';
  String bTradeRatio(double value) =>
      isVi ? 'Tỷ lệ lệnh B: ${value.toStringAsFixed(1)}%' : 'B Trade Ratio: ${value.toStringAsFixed(1)}%';

  String get equitySimulation =>
      isVi ? 'Mô phỏng Equity' : 'Equity Simulation';
  String get compareDecisionFilteringScenarios => isVi
      ? 'So sánh các kịch bản lọc quyết định'
      : 'Compare decision filtering scenarios';

  String get allTrades => isVi ? 'Tất cả lệnh' : 'All Trades';
  String get noBTrades => isVi ? 'Không có lệnh B' : 'No B Trades';
  String get onlyATrades => isVi ? 'Chỉ lệnh A' : 'Only A Trades';

  String get baselinePerformance =>
      isVi ? 'Hiệu suất cơ sở' : 'Baseline performance';
  String get removeLowQualityDecisions =>
      isVi ? 'Loại bỏ quyết định chất lượng thấp' : 'Remove low-quality decisions';
  String get highestQualitySetupsOnly =>
      isVi ? 'Chỉ giữ setup chất lượng cao nhất' : 'Highest-quality setups only';

  String get noTradesToSimulate => isVi
      ? 'Chưa có lệnh nào.\nHãy thêm lệnh để mô phỏng equity.'
      : 'No trades yet.\nAdd trades to simulate equity.';

  String get noTradesInThisFilter =>
      isVi ? 'Không có lệnh trong bộ lọc này' : 'No trades in this filter';

  String showingTrades(int shown, int total) => isVi
      ? 'Đang hiển thị $shown / $total lệnh'
      : 'Showing $shown of $total trades';

  String get compareScenarios =>
      isVi ? 'So sánh các kịch bản lọc' : 'Compare decision filtering scenarios';

  String get maxDd => 'Max DD';

  String get appTitle => 'Decision Journal';

  String get disclaimer => isVi
      ? 'Không phải tư vấn tài chính.\nKhông đảm bảo lợi nhuận.'
      : 'Not financial advice.\nNo profit guarantee.';
}