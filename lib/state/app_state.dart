import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/expense_repository.dart';
import '../models/expense.dart';

final repositoryProvider = Provider((ref) => ExpenseRepository());
final appProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

/// Immutable UI snapshot. All mutations go through AppController.
class AppState {
  const AppState({
    this.expenses = const [],
    this.loading = true,
    this.error,
    this.theme = ThemeMode.system,
    this.budget = 2000000,
  });
  final List<Expense> expenses;
  final bool loading;
  final String? error;
  final ThemeMode theme;
  final int budget;

  AppState copyWith({
    List<Expense>? expenses,
    bool? loading,
    String? error,
    bool clearError = false,
    ThemeMode? theme,
    int? budget,
  }) => AppState(
    expenses: expenses == null ? this.expenses : List.unmodifiable(expenses),
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
    theme: theme ?? this.theme,
    budget: budget ?? this.budget,
  );
}

class AppController extends Notifier<AppState> {
  late ExpenseRepository _repository;
  bool _alive = false;
  int _loadTicket = 0;

  @override
  AppState build() {
    _repository = ref.watch(repositoryProvider);
    _alive = true;
    ref.onDispose(() {
      _alive = false;
      _loadTicket++;
    });
    scheduleMicrotask(load);
    return const AppState();
  }

  Future<void> load() async {
    if (!_alive) return;
    final ticket = ++_loadTicket;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final expenses = await _repository.all();
      final budget = int.tryParse(await _repository.setting('budget') ?? '');
      final themeName = await _repository.setting('theme');
      final themes = ThemeMode.values.where((mode) => mode.name == themeName);
      if (!_alive || ticket != _loadTicket) return;
      state = state.copyWith(
        expenses: expenses,
        loading: false,
        clearError: true,
        budget: budget != null && budget > 0 && budget <= 999999999
            ? budget
            : 2000000,
        theme: themes.isEmpty ? ThemeMode.system : themes.first,
      );
    } catch (_) {
      if (_alive && ticket == _loadTicket) {
        state = state.copyWith(
          loading: false,
          error: 'Không mở được dữ liệu. Hãy thử lại.',
        );
      }
    }
  }

  Future<void> _refreshExpenses() async {
    final expenses = await _repository.all();
    if (_alive) state = state.copyWith(expenses: expenses);
  }

  Future<void> save(Expense expense) async {
    await _repository.save(
      expense,
    ); // Do not emit success before SQLite commits.
    await _refreshExpenses();
  }

  Future<void> delete(Expense expense) async {
    await _repository.delete(expense);
    await _refreshExpenses();
  }

  Future<void> setBudget(int value) async {
    if (value < 1 || value > 999999999) {
      throw ArgumentError.value(value, 'budget');
    }
    await _repository.setSetting('budget', '$value');
    if (_alive) state = state.copyWith(budget: value);
  }

  Future<void> setTheme(ThemeMode value) async {
    await _repository.setSetting('theme', value.name);
    if (_alive) state = state.copyWith(theme: value);
  }

  Future<void> samples() async {
    await _repository.addSamples();
    await _refreshExpenses();
  }
}
