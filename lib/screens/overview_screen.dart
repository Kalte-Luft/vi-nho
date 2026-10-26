import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../widgets/common.dart';
import '../core/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/expense_card.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({
    super.key,
    required this.app,
    required this.data,
    required this.month,
    required this.onScan,
    required this.onBudget,
    required this.onHistory,
    required this.onExpense,
    required this.empty,
  });
  final AppState app;
  final List<Expense> data;
  final DateTime month;
  final VoidCallback onScan, onBudget, onHistory;
  final ValueChanged<Expense> onExpense;
  final Widget Function(String, String, {bool sample}) empty;
  Widget expenseTile(Expense e) =>
      ExpenseCard(key: ValueKey(e.id), expense: e, onTap: () => onExpense(e));
  @override
  Widget build(BuildContext context) {
    final total = data.fold(0, (sum, e) => sum + e.amount);
    final remaining = app.budget - total;
    return ListView(
      key: const ValueKey('overview'),
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 105),
      children: [
        const Text(
          'Một chút mỗi ngày,',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -.9,
          ),
        ),
        const Text(
          'chủ động hơn mỗi tháng.',
          style: TextStyle(fontSize: 18, height: 1.6),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF234F40), Color(0xFF36745C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'CHI TIÊU THÁNG',
                      style: TextStyle(
                        color: Color(0xFFD8E9DA),
                        fontSize: 11,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${month.month.toString().padLeft(2, '0')} / ${month.year}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: total.toDouble()),
                  duration: const Duration(milliseconds: 650),
                  builder: (context, value, child) => Text(
                    money(value.round()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(Icons.receipt_long, size: 16, color: lime),
                  const SizedBox(width: 7),
                  Text(
                    '${data.length} khoản chi',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onBudget,
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sửa ngân sách',
                            style: TextStyle(color: lime, fontSize: 12),
                          ),
                          SizedBox(width: 3),
                          Icon(Icons.north_east, size: 13, color: lime),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: (total / app.budget).clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 700),
                  builder: (context, value, child) => LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    color: remaining >= 0 ? lime : const Color(0xFFFFBD9C),
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                remaining >= 0
                    ? 'Còn ${money(remaining)} trong ngân sách ${money(app.budget)}'
                    : 'Vượt ${money(-remaining)} so với ngân sách ${money(app.budget)}',
                style: const TextStyle(
                  color: Color(0xFFD8E9DA),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Surface(
          onTap: onScan,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.document_scanner_outlined),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quét hóa đơn',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Chụp · Kiểm tra · Lưu',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onScan,
                tooltip: 'Quét ngay',
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionTitle(
          'Gần đây',
          trailing: TextButton(
            onPressed: onHistory,
            child: const Text('Xem tất cả'),
          ),
        ),
        const SizedBox(height: 8),
        if (data.isEmpty)
          empty(
            app.expenses.isEmpty
                ? 'Bắt đầu từ hóa đơn đầu tiên'
                : 'Tháng này chưa có khoản chi',
            'Quét hóa đơn hoặc nhập một khoản chi để theo dõi.',
            sample: app.expenses.isEmpty,
          )
        else
          ...data.take(4).map(expenseTile),
        if (data.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.offline_bolt_outlined, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'OCR và sổ chi tiêu hoạt động offline.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
