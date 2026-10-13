import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
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
      return ReceiptParser().parse(result.text);
    } finally {
      await recognizer.close();
    }
  }
}
