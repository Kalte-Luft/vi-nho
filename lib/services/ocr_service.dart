import 'dart:io';
import 'dart:ui' as ui;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../models/receipt_evidence.dart';
import 'receipt_parser.dart';

class OcrService {
  final picker = ImagePicker();
  Future<XFile?> pick(ImageSource source) =>
      picker.pickImage(source: source, maxWidth: 2400, imageQuality: 95);

  Future<ReceiptDraft> recognize(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(path),
      );
      ReceiptEvidence? evidence;
      ui.Codec? codec;
      ui.Image? image;
      try {
        codec = await ui.instantiateImageCodec(await File(path).readAsBytes());
        image = (await codec.getNextFrame()).image;
        evidence = ReceiptEvidence(
          imageWidth: image.width,
          imageHeight: image.height,
          lines: List.unmodifiable(
            result.blocks
                .expand((block) => block.lines)
                .map(
                  (line) => OcrLine(
                    text: line.text,
                    left: line.boundingBox.left,
                    top: line.boundingBox.top,
                    width: line.boundingBox.width,
                    height: line.boundingBox.height,
                  ),
                ),
          ),
        );
      } catch (_) {
        // Geometry is optional; retain usable OCR text if image decoding fails.
      } finally {
        image?.dispose();
        codec?.dispose();
      }
      return ReceiptParser().parse(result.text, evidence: evidence);
    } finally {
      await recognizer.close();
    }
  }
}
