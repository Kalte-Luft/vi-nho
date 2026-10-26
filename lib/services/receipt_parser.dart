import '../models/receipt_evidence.dart';

class ReceiptDraft {
  const ReceiptDraft({
    required this.merchant,
    required this.amount,
    required this.date,
    required this.rawText,
    required this.warnings,
    this.evidence,
  });
  final String merchant;
  final int? amount;
  final DateTime? date;
  final String rawText;
  final List<String> warnings;
  final ReceiptEvidence? evidence;
}

/// Simple heuristics, deliberately not an AI service or an opaque parser.
class ReceiptParser {
  static String normalize(String value) {
    const accents = [
      'àáạảãâầấậẩẫăằắặẳẵ',
      'èéẹẻẽêềếệểễ',
      'ìíịỉĩ',
      'òóọỏõôồốộổỗơờớợởỡ',
      'ùúụủũưừứựửữ',
      'ỳýỵỷỹ',
      'đ',
    ];
    const plain = ['a', 'e', 'i', 'o', 'u', 'y', 'd'];
    var result = value.toLowerCase();
    for (var i = 0; i < accents.length; i++) {
      for (final char in accents[i].split('')) {
        result = result.replaceAll(char, plain[i]);
      }
    }
    return result;
  }

  /// VND receipts use 45.000, 45,000, 45000 or 45,000.00.
  static int? parseAmount(String value) {
    var text = value
        .trim()
        .replaceAll(RegExp(r'vnd|[₫đ]', caseSensitive: false), '')
        .trim();
    if (text.isEmpty || !RegExp(r'^[0-9., ]+$').hasMatch(text)) return null;
    if (RegExp(r'[.,]\d{2}$').hasMatch(text)) {
      final decimals = text.substring(text.length - 2);
      if (decimals != '00') return null;
      text = text.substring(0, text.length - 3);
    }
    if (!RegExp(r'^\d+$|^\d{1,3}([., ]\d{3})+$').hasMatch(text)) return null;
    return int.tryParse(text.replaceAll(RegExp(r'[., ]'), ''));
  }

  ReceiptDraft parse(String raw, {ReceiptEvidence? evidence}) {
    final lines = raw
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final warnings = <String>[];
    var merchant = '';
    for (final line in lines.take(6)) {
      final text = normalize(line);
      if (RegExp(r'[a-z]').hasMatch(text) &&
          !RegExp(
            r'hoa don|receipt|invoice|dia chi|address|tel|phone|mst|ma so|ngay|date|cash|change|total|tong|thanh toan|tien khach|tien thua|tam tinh|subtotal|discount|giam gia',
          ).hasMatch(text) &&
          !RegExp(r'^\d').hasMatch(text)) {
        merchant = line;
        break;
      }
    }
    if (merchant.isEmpty) warnings.add('Chưa tìm thấy cửa hàng. Hãy nhập lại.');
    DateTime? date;
    final dates = RegExp(
      r'\b(\d{1,2})[/.-](\d{1,2})[/.-](\d{4}|\d{2})\b',
    ).allMatches(raw);
    for (final match in dates) {
      final day = int.parse(match[1]!);
      final month = int.parse(match[2]!);
      var year = int.parse(match[3]!);
      if (year < 100) year += 2000;
      final candidate = DateTime(year, month, day);
      if (candidate.day == day &&
          candidate.month == month &&
          year >= 2000 &&
          year <= 2100) {
        date = candidate;
        break;
      }
    }
    if (date == null) {
      warnings.add('Chưa đọc được ngày; tạm dùng ngày hôm nay.');
    }
    int? total;
    var bestScore = -1;
    final number = RegExp(r'\d[\d.,]*(?:[ ]\d{3})*');
    for (var i = 0; i < lines.length; i++) {
      final text = normalize(lines[i]);
      if (RegExp(
        r'tam tinh|subtotal|tien khach|cash|change|tien thua|giam gia|discount',
      ).hasMatch(text)) {
        continue;
      }
      final score =
          RegExp(
            r'tong cong|grand total|thanh toan|amount due|phai tra',
          ).hasMatch(text)
          ? 3
          : RegExp(r'\btong\b|\btotal\b').hasMatch(text)
          ? 2
          : 0;
      if (score == 0) continue;
      // ML Kit sometimes separates a label and its amount into adjacent lines.
      var matches = number.allMatches(lines[i]).toList();
      if (matches.isEmpty &&
          i + 1 < lines.length &&
          RegExp(r'^[\d\s.,₫đdVNDvnd]+$').hasMatch(lines[i + 1])) {
        matches = number.allMatches(lines[i + 1]).toList();
      }
      if (matches.isNotEmpty && score >= bestScore) {
        final amount = parseAmount(matches.last[0]!);
        if (amount != null && amount > 0 && amount <= 999999999) {
          total = amount;
          bestScore = score;
        }
      }
    }
    // Never guess the largest number: it could be a phone number or cash tendered.
    if (total == null) {
      warnings.add('Chưa xác định tổng thanh toán. Hãy đối chiếu hóa đơn.');
    }
    return ReceiptDraft(
      merchant: merchant,
      amount: total,
      date: date,
      rawText: raw,
      warnings: warnings,
      evidence: evidence,
    );
  }
}
