import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vi_nho/models/expense.dart';
import 'package:vi_nho/state/app_state.dart';
import 'widget_test.dart' show MemoryRepository;

class FailingRepository extends MemoryRepository {
  @override
  Future<void> save(Expense expense) async =>
      throw StateError('disk unavailable');
}

class DelayedRepository extends MemoryRepository {
  final pending = Completer<List<Expense>>();
  @override
  Future<List<Expense>> all() => pending.future;
}

void main() {
  test(
    'Notifier publishes immutable snapshots only after successful persistence',
    () async {
      final repository = MemoryRepository();
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      container.read(appProvider);
      await container.read(appProvider.notifier).load();
      final before = container.read(appProvider);
      await container
          .read(appProvider.notifier)
          .save(
            Expense(
              merchant: 'VKU',
              amount: 35000,
              date: DateTime(2026, 10, 26),
              category: Category.food,
            ),
          );
      final after = container.read(appProvider);
      expect(before.expenses, isEmpty);
      expect(after.expenses.single.amount, 35000);
      expect(() => after.expenses.clear(), throwsUnsupportedError);
      await container.read(appProvider.notifier).setTheme(ThemeMode.dark);
      expect(container.read(appProvider).theme, ThemeMode.dark);
      await container.read(appProvider.notifier).setBudget(1000000);
      expect(container.read(appProvider).budget, 1000000);
    },
  );
  test(
    'Failed SQLite save is propagated without a false expense in UI state',
    () async {
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(FailingRepository())],
      );
      addTearDown(container.dispose);
      container.read(appProvider);
      await container.read(appProvider.notifier).load();
      await expectLater(
        container
            .read(appProvider.notifier)
            .save(
              Expense(
                merchant: 'VKU',
                amount: 1000,
                date: DateTime(2026),
                category: Category.other,
              ),
            ),
        throwsStateError,
      );
      expect(container.read(appProvider).expenses, isEmpty);
    },
  );
  test('Disposed notifier ignores a late database load', () async {
    final repository = DelayedRepository();
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repository)],
    );
    container.read(appProvider);
    await Future<void>.delayed(Duration.zero);
    container.dispose();
    repository.pending.complete([]);
    await Future<void>.delayed(Duration.zero);
  });
}
