import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../widgets/common.dart';
import '../widgets/charts.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({
    super.key,
    required this.data,
    required this.all,
    required this.monthSelector,
  });
  final List<Expense> data, all;
  final Widget monthSelector;
  @override
  Widget build(BuildContext context) {
    final totals = {
      for (final category in Category.values)
        category: data
            .where((e) => e.category == category)
            .fold(0, (a, e) => a + e.amount),
    };
    final total = totals.values.fold(0, (a, b) => a + b);
    final now = DateTime.now();
    final days = List.generate(
      7,
      (i) => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - i)),
    );
    final values = days
        .map(
          (day) => all
              .where(
                (e) =>
                    e.date.year == day.year &&
                    e.date.month == day.month &&
                    e.date.day == day.day,
              )
              .fold(0, (a, e) => a + e.amount),
        )
        .toList();
    return ListView(
      key: const ValueKey('reports'),
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 105),
      children: [
        const SectionTitle('Bức tranh chi tiêu'),
        Align(alignment: Alignment.centerRight, child: monthSelector),
        const SizedBox(height: 12),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TIỀN ĐI ĐÂU?',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              DonutChart(values: totals),
              const SizedBox(height: 16),
              if (total == 0)
                const Text(
                  'Thêm khoản chi để thấy phân bổ theo danh mục.',
                  style: TextStyle(fontSize: 13),
                ),
              for (final entry in totals.entries.where((e) => e.value > 0))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: entry.key.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          entry.key.label,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '${(entry.value / total * 100).round()}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        money(entry.value),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhịp chi tiêu',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              const Text(
                '7 ngày gần nhất · mọi danh mục',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              Text(
                money(values.fold(0, (a, b) => a + b)),
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              WeeklyChart(values: values, days: days),
            ],
          ),
        ),
      ],
    );
  }
}
