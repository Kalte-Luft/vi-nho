import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';

class ExpenseRepository {
  ExpenseRepository({Database? database, Directory? documentsDirectory})
    : _database = database,
      _documentsDirectory = documentsDirectory;
  final Directory? _documentsDirectory;
  Future<Directory> get documentsDirectory async =>
      _documentsDirectory ?? await getApplicationDocumentsDirectory();
  Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    final directory = await documentsDirectory;
    _database = await openDatabase(
      p.join(directory.path, 'vi_nho.db'),
      version: 2,
      onUpgrade: upgradeSchema,
      onCreate: createSchema,
    );
    return _database!;
  }

  static Future<void> createSchema(Database db, int version) async {
    await db.execute('''CREATE TABLE expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          merchant TEXT NOT NULL, amount INTEGER NOT NULL CHECK(amount > 0),
          date TEXT NOT NULL, category TEXT NOT NULL, note TEXT NOT NULL,
          photo_path TEXT, raw_text TEXT NOT NULL, ocr_evidence TEXT)''');
    await db.execute(
      'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );
  }

  static Future<void> upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE expenses ADD COLUMN ocr_evidence TEXT');
    }
  }

  Future<List<Expense>> all() async => (await (await database).query(
    'expenses',
    orderBy: 'date DESC, id DESC',
  )).map(Expense.fromMap).toList();
  Future<String?> setting(String key) async {
    final rows = await (await database).query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    await (await database).insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> save(Expense expense) async {
    String? copiedPath;
    try {
      var values = expense.toMap();
      if (expense.photoPath != null) {
        final directory = await documentsDirectory;
        final receipts = Directory(p.join(directory.path, 'receipts'));
        await receipts.create(recursive: true);
        if (p.dirname(expense.photoPath!) != receipts.path) {
          copiedPath = p.join(
            receipts.path,
            '${DateTime.now().microsecondsSinceEpoch}${p.extension(expense.photoPath!)}',
          );
          await File(expense.photoPath!).copy(copiedPath);
          values['photo_path'] = copiedPath;
        }
      }
      final db = await database;
      if (expense.id == null) {
        await db.insert('expenses', values);
      } else {
        await db.update(
          'expenses',
          values,
          where: 'id = ?',
          whereArgs: [expense.id],
        );
      }
    } catch (_) {
      if (copiedPath != null && await File(copiedPath).exists()) {
        await File(copiedPath).delete();
      }
      rethrow;
    }
  }

  Future<void> delete(Expense expense) async {
    await (await database).delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [expense.id],
    );
    // DB deletion is authoritative; cleanup failure must not falsely report save failure.
    try {
      if (expense.photoPath != null &&
          await File(expense.photoPath!).exists()) {
        await File(expense.photoPath!).delete();
      }
    } on FileSystemException {
      /* An orphan image can be cleaned up later. */
    }
  }

  Future<void> addSamples() async {
    final now = DateTime.now();
    final samples = [
      ('Highlands Coffee', 59000, Category.food, 0),
      ('Nhà sách Fahasa', 128000, Category.study, 0),
      ('Bún bò cô Lan', 35000, Category.food, 1),
      ('Grab Bike', 22000, Category.transport, 2),
      ('Co.opmart Đà Nẵng', 186000, Category.shopping, 3),
      ('Cơm trưa VKU', 30000, Category.food, 4),
      ('In tài liệu', 18000, Category.study, 5),
    ];
    final db = await database;
    await db.transaction((txn) async {
      // One-time seeding, even if all samples are later removed.
      if ((await txn.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['samples'],
      )).isNotEmpty) {
        return;
      }
      for (final (merchant, amount, category, days) in samples) {
        await txn.insert(
          'expenses',
          Expense(
            merchant: merchant,
            amount: amount,
            date: DateTime(
              now.year,
              now.month,
              now.day,
            ).subtract(Duration(days: days)),
            category: category,
            note: 'Dữ liệu mẫu để khám phá giao diện',
          ).toMap(),
        );
      }
      await txn.insert('settings', {'key': 'samples', 'value': 'yes'});
    });
  }
}
