import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'receipt_evidence.dart';

enum Category {
  food('Ăn uống', Icons.restaurant_rounded, Color(0xFFEE9B62)),
  transport('Di chuyển', Icons.directions_bus_rounded, Color(0xFF7B9CF2)),
  shopping('Mua sắm', Icons.shopping_bag_rounded, Color(0xFFB391D9)),
  study('Học tập', Icons.school_rounded, Color(0xFF56B5A4)),
  other('Khác', Icons.more_horiz_rounded, Color(0xFFACADBA));

  const Category(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

String money(num value) => '${NumberFormat('#,###', 'vi_VN').format(value)} ₫';
String shortDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

class Expense {
  const Expense({
    this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    this.note = '',
    this.photoPath,
    this.rawText = '',
    this.evidence,
  });
  final int? id;
  final String merchant;
  final int amount; // VND is stored as integer, avoiding floating point errors.
  final DateTime date;
  final Category category;
  final String note;
  final String? photoPath;
  final String rawText;
  final ReceiptEvidence? evidence;

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'merchant': merchant,
    'amount': amount,
    'date': date.toIso8601String(),
    'category': category.name,
    'note': note,
    'photo_path': photoPath,
    'raw_text': rawText,
    'ocr_evidence': evidence?.encode(),
  };
  factory Expense.fromMap(Map<String, Object?> map) => Expense(
    id: map['id'] as int,
    merchant: map['merchant'] as String,
    amount: map['amount'] as int,
    date: DateTime.parse(map['date'] as String),
    category: Category.values.byName(map['category'] as String),
    note: map['note'] as String,
    photoPath: map['photo_path'] as String?,
    rawText: map['raw_text'] as String,
    evidence: ReceiptEvidence.decode(map['ocr_evidence'] as String?),
  );
}
