import 'dart:convert';

/// Pixel coordinates from ML Kit, in the decoded receipt image's coordinate space.
class OcrLine {
  const OcrLine({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
  final String text;
  final double left, top, width, height;
  Map<String, Object> toMap() => {
    'text': text,
    'left': left,
    'top': top,
    'width': width,
    'height': height,
  };
  factory OcrLine.fromMap(Map<String, dynamic> map) => OcrLine(
    text: map['text'] as String,
    left: (map['left'] as num).toDouble(),
    top: (map['top'] as num).toDouble(),
    width: (map['width'] as num).toDouble(),
    height: (map['height'] as num).toDouble(),
  );
}

class ReceiptEvidence {
  const ReceiptEvidence({
    required this.imageWidth,
    required this.imageHeight,
    required this.lines,
  });
  final int imageWidth, imageHeight;
  final List<OcrLine> lines;
  String encode() => jsonEncode({
    'imageWidth': imageWidth,
    'imageHeight': imageHeight,
    'lines': lines.map((line) => line.toMap()).toList(),
  });

  /// Old records and malformed optional metadata remain readable without overlays.
  static ReceiptEvidence? decode(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final map = jsonDecode(value) as Map<String, dynamic>;
      final width = map['imageWidth'] as int;
      final height = map['imageHeight'] as int;
      if (width <= 0 || height <= 0) return null;
      final lines = (map['lines'] as List)
          .map(
            (line) => OcrLine.fromMap(Map<String, dynamic>.from(line as Map)),
          )
          .where(
            (line) =>
                line.left.isFinite &&
                line.top.isFinite &&
                line.width.isFinite &&
                line.height.isFinite &&
                line.width > 0 &&
                line.height > 0,
          )
          .toList();
      return ReceiptEvidence(
        imageWidth: width,
        imageHeight: height,
        lines: List.unmodifiable(lines),
      );
    } catch (_) {
      return null;
    }
  }
}
