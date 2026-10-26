import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../widgets/common.dart';
import '../services/receipt_parser.dart';
import '../widgets/expense_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    required this.data,
    required this.search,
    required this.filter,
    required this.monthSelector,
    required this.onRefresh,
    required this.onFilter,
    required this.onExpense,
    required this.empty,
  });
  final List<Expense> data;
  final TextEditingController search;
  final Category? filter;
  final Widget monthSelector;
  final VoidCallback onRefresh;
  final ValueChanged<Category?> onFilter;
  final ValueChanged<Expense> onExpense;
  final Widget Function(String, String, {bool sample}) empty;
  Widget expenseTile(Expense e) =>
      ExpenseCard(key: ValueKey(e.id), expense: e, onTap: () => onExpense(e));
  @override
  Widget build(BuildContext context) {
    final query = ReceiptParser.normalize(search.text.trim());
    final filtered = data
        .where(
          (e) =>
              (filter == null || e.category == filter) &&
              ReceiptParser.normalize(
                '${e.merchant} ${e.note}',
              ).contains(query),
        )
        .toList();
    return Column(
      key: const ValueKey('history'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SectionTitle('Sổ chi tiêu'),
              Align(alignment: Alignment.centerRight, child: monthSelector),
              const SizedBox(height: 8),
              TextField(
                controller: search,
                onChanged: (_) => onRefresh(),
                decoration: InputDecoration(
                  hintText: 'Tìm cửa hàng, ghi chú…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            search.clear();
                            onRefresh();
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: filter == null,
                        onSelected: (_) => onFilter(null),
                      ),
                    ),
                    ...Category.values.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c.label),
                          selected: filter == c,
                          onSelected: (_) => onFilter(c),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${filtered.length} khoản chi',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    money(filtered.fold(0, (a, e) => a + e.amount)),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    empty(
                      'Chưa có khoản chi phù hợp',
                      'Thử đổi tháng, danh mục hoặc từ khóa.',
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 105),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => expenseTile(filtered[i]),
                ),
        ),
      ],
    );
  }
}
