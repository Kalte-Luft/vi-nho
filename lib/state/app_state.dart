import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/expense_repository.dart';
import '../models/expense.dart';

final repositoryProvider = Provider((ref) => ExpenseRepository());
final appProvider = ChangeNotifierProvider(
  (ref) => AppState(ref.watch(repositoryProvider)),
);

/// Riverpod 2 manages ownership; ChangeNotifier keeps this classroom-sized app simple.
class AppState extends ChangeNotifier {
  AppState(this.repository) {
    load();
  }
  final ExpenseRepository repository;
  List<Expense> expenses = [];
  bool loading = true;
  String? error;
  ThemeMode theme = ThemeMode.system;
  int budget = 2000000;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      expenses = await repository.all();
      budget =
          int.tryParse(await repository.setting('budget') ?? '') ?? 2000000;
      theme = ThemeMode.values.byName(
        await repository.setting('theme') ?? 'system',
      );
    } catch (_) {
      error = 'Không mở được dữ liệu. Hãy thử lại.';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> save(Expense expense) async {
    await repository.save(expense);
    expenses = await repository.all();
    notifyListeners();
  }

  Future<void> delete(Expense expense) async {
    await repository.delete(expense);
    expenses = await repository.all();
    notifyListeners();
  }

  Future<void> setBudget(int value) async {
    await repository.setSetting('budget', '$value');
    budget = value;
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode value) async {
    await repository.setSetting('theme', value.name);
    theme = value;
    notifyListeners();
  }

  Future<void> samples() async {
    await repository.addSamples();
    expenses = await repository.all();
    notifyListeners();
  }
}
