import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vi_nho/services/expense_repository.dart';
import 'package:vi_nho/models/expense.dart';

void main() {
  sqfliteFfiInit();
  test('SQLite CRUD, preferences and sample idempotence', () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: ExpenseRepository.createSchema,
      ),
    );
    final repository = ExpenseRepository(database: db);
    await repository.save(
      Expense(
        merchant: 'VKU',
        amount: 30000,
        date: DateTime(2026, 10, 13),
        category: Category.food,
      ),
    );
    var items = await repository.all();
    expect(items.single.amount, 30000);
    await repository.save(
      Expense(
        id: items.single.id,
        merchant: 'VKU edited',
        amount: 35000,
        date: items.single.date,
        category: Category.study,
      ),
    );
    items = await repository.all();
    expect(items.single.merchant, 'VKU edited');
    expect(items.single.category, Category.study);
    await repository.setSetting('budget', '1500000');
    expect(await repository.setting('budget'), '1500000');
    await repository.delete(items.single);
    expect(await repository.all(), isEmpty);
    await repository.addSamples();
    await repository.addSamples();
    expect((await repository.all()).length, 7);
    await db.close();
  });
  test(
    'Photo copied from temporary capture; disk database survives reopening',
    () async {
      final temp = await Directory.systemTemp.createTemp('vi-nho-test-');
      addTearDown(() => temp.delete(recursive: true));
      final documents = await Directory('${temp.path}/documents').create();
      final capture = File('${temp.path}/capture.jpg');
      await capture.writeAsBytes([1, 2, 3, 4]);
      final dbPath = '${documents.path}/vi_nho.db';
      var db = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: ExpenseRepository.createSchema,
        ),
      );
      var repository = ExpenseRepository(
        database: db,
        documentsDirectory: documents,
      );
      await repository.save(
        Expense(
          merchant: 'Receipt photo',
          amount: 69000,
          date: DateTime(2026, 10, 13),
          category: Category.food,
          photoPath: capture.path,
        ),
      );
      var item = (await repository.all()).single;
      expect(item.photoPath, startsWith('${documents.path}/receipts/'));
      expect(await File(item.photoPath!).readAsBytes(), [1, 2, 3, 4]);
      await capture.delete(); // Simulate camera cache being cleared.
      await repository.setSetting('theme', 'dark');
      await db.close();
      db = await databaseFactoryFfi.openDatabase(dbPath);
      repository = ExpenseRepository(
        database: db,
        documentsDirectory: documents,
      );
      item = (await repository.all()).single;
      expect(item.amount, 69000);
      expect(await File(item.photoPath!).exists(), isTrue);
      expect(await repository.setting('theme'), 'dark');
      await repository.delete(item);
      expect(await File(item.photoPath!).exists(), isFalse);
      await db.close();
    },
  );
  test(
    'SQLite v1 to v2 migration preserves existing records and settings',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'vi-nho-migration-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final path = '${directory.path}/old.db';
      var db = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute(
              "CREATE TABLE expenses (id INTEGER PRIMARY KEY AUTOINCREMENT, merchant TEXT NOT NULL, amount INTEGER NOT NULL, date TEXT NOT NULL, category TEXT NOT NULL, note TEXT NOT NULL, photo_path TEXT, raw_text TEXT NOT NULL)",
            );
            await db.execute(
              'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
            );
          },
        ),
      );
      await db.insert('expenses', {
        'merchant': 'Old receipt',
        'amount': 69000,
        'date': '2026-10-13T00:00:00.000',
        'category': 'food',
        'note': '',
        'photo_path': 'receipts/old.jpg',
        'raw_text': 'Tong cong 69.000',
      });
      await db.insert('settings', {'key': 'theme', 'value': 'dark'});
      await db.close();
      db = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
          onUpgrade: ExpenseRepository.upgradeSchema,
        ),
      );
      final repository = ExpenseRepository(database: db);
      final expense = (await repository.all()).single;
      expect(expense.amount, 69000);
      expect(expense.photoPath, 'receipts/old.jpg');
      expect(expense.evidence, isNull);
      expect(await repository.setting('theme'), 'dark');
      await db.close();
    },
  );
}
