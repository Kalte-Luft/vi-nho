import 'package:flutter_test/flutter_test.dart';
import 'package:vi_nho/services/receipt_parser.dart';

void main() {
  final parser = ReceiptParser();
  test('Extracts merchant, valid date, final total; skips cash and change', () {
    final result = parser.parse(
      'HIGHLANDS COFFEE\nHOA DON\nNgay: 13/10/2026\nTam tinh 74.000\nGiam gia 5.000\nTONG CONG: 69.000 VND\nTien khach dua 100.000\nTien thua 31.000',
    );
    expect(result.merchant, 'HIGHLANDS COFFEE');
    expect(result.amount, 69000);
    expect(result.date, DateTime(2026, 10, 13));
    expect(result.warnings, isEmpty);
  });
  test('Handles Vietnamese accents and split OCR label/amount', () {
    final result = parser.parse(
      'Co.opmart\nNgày 2-9-26\nTổng cộng\n245,000.00\nTiền khách đưa 300.000',
    );
    expect(result.amount, 245000);
    expect(result.date, DateTime(2026, 9, 2));
  });
  test('Final amount due wins over generic total', () {
    expect(
      parser
          .parse('STORE\nTOTAL 100,000\nAmount due 90,000\nTOTAL ITEMS 2')
          .amount,
      90000,
    );
  });
  test(
    'Does not guess phone or cash as total; invalid date not rolled over',
    () {
      final result = parser.parse('Tel 0901234567\n31/02/2026\nCash 200000');
      expect(result.amount, isNull);
      expect(result.date, isNull);
      expect(result.merchant, isEmpty);
      expect(result.warnings.length, 3);
    },
  );
  test('Parses VND delimiters and refuses non-zero fractional amount', () {
    expect(ReceiptParser.parseAmount('45.000 ₫'), 45000);
    expect(ReceiptParser.parseAmount('45 000 VND'), 45000);
    expect(ReceiptParser.parseAmount('45,000.00'), 45000);
    expect(ReceiptParser.parseAmount('45,000.50'), isNull);
    expect(ReceiptParser.parseAmount('-45000'), isNull);
    expect(ReceiptParser.parseAmount('abc45000'), isNull);
  });
}
