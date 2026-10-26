import 'package:flutter_test/flutter_test.dart';
import 'package:vi_nho/models/receipt_evidence.dart';

void main() {
  test('OCR evidence round-trips pixel coordinates and original text', () {
    const value = ReceiptEvidence(
      imageWidth: 900,
      imageHeight: 1400,
      lines: [
        OcrLine(
          text: 'TONG CONG: 69.000',
          left: 80,
          top: 850,
          width: 700,
          height: 42,
        ),
      ],
    );
    final decoded = ReceiptEvidence.decode(value.encode())!;
    expect(decoded.imageWidth, 900);
    expect(decoded.lines.single.text, 'TONG CONG: 69.000');
    expect(decoded.lines.single.top, 850);
  });
  test(
    'Optional metadata on old or corrupt records never breaks receipt reading',
    () {
      expect(ReceiptEvidence.decode(null), isNull);
      expect(ReceiptEvidence.decode('not json'), isNull);
      expect(
        ReceiptEvidence.decode('{"imageWidth":0,"imageHeight":10,"lines":[]}'),
        isNull,
      );
    },
  );
}
