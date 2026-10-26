import 'dart:io';
import 'package:flutter/material.dart';
import '../models/receipt_evidence.dart';

/// Uses the same contain transform for the image and ML Kit rectangles.
class ReceiptPhoto extends StatefulWidget {
  const ReceiptPhoto({super.key, required this.path, this.evidence});
  final String path;
  final ReceiptEvidence? evidence;
  @override
  State<ReceiptPhoto> createState() => _ReceiptPhotoState();
}

class _ReceiptPhotoState extends State<ReceiptPhoto> {
  bool showBounds = true;
  Widget image(bool bounds) => Stack(
    fit: StackFit.expand,
    children: [
      Image.file(
        File(widget.path),
        fit: BoxFit.contain,
        errorBuilder: (_, error, stack) =>
            const Center(child: Text('Ảnh không còn tồn tại')),
      ),
      if (bounds && widget.evidence != null)
        IgnorePointer(
          child: CustomPaint(
            painter: ReceiptBoundsPainter(
              widget.evidence!,
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
    ],
  );

  Future<void> enlarge() => showDialog<void>(
    context: context,
    builder: (context) {
      var bounds = showBounds;
      return StatefulBuilder(
        builder: (context, update) => Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .83,
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Ảnh & vùng chữ OCR',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (widget.evidence != null)
                      IconButton(
                        tooltip: 'Ẩn/hiện khung OCR',
                        onPressed: () => update(() => bounds = !bounds),
                        icon: Icon(
                          bounds ? Icons.layers : Icons.layers_outlined,
                        ),
                      ),
                    IconButton(
                      tooltip: 'Đóng ảnh',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Expanded(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 6,
                    child: SizedBox.expand(child: image(bounds)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Chụm hai ngón để phóng to và đối chiếu từng dòng.',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: InkWell(
            onTap: enlarge,
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(child: image(showBounds)),
                  const Positioned(
                    right: 12,
                    bottom: 12,
                    child: Chip(
                      avatar: Icon(Icons.zoom_in, size: 18),
                      label: Text('Phóng to ảnh'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      if (widget.evidence != null)
        Row(
          children: [
            Expanded(
              child: Text(
                '${widget.evidence!.lines.length} vùng chữ OCR · đối chiếu với ảnh',
                style: const TextStyle(fontSize: 11),
              ),
            ),
            IconButton(
              tooltip: 'Ẩn/hiện khung OCR',
              icon: Icon(showBounds ? Icons.layers : Icons.layers_outlined),
              onPressed: () => setState(() => showBounds = !showBounds),
            ),
          ],
        ),
    ],
  );
}

class ReceiptBoundsPainter extends CustomPainter {
  ReceiptBoundsPainter(this.evidence, this.color);
  final ReceiptEvidence evidence;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final source = Size(
      evidence.imageWidth.toDouble(),
      evidence.imageHeight.toDouble(),
    );
    final fitted = applyBoxFit(BoxFit.contain, source, size);
    final target = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    final sx = target.width / source.width, sy = target.height / source.height;
    final stroke = Paint()
      ..color = color.withValues(alpha: .85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final fill = Paint()..color = color.withValues(alpha: .07);
    canvas.save();
    canvas.clipRect(target);
    for (final line in evidence.lines) {
      final rect = Rect.fromLTWH(
        target.left + line.left * sx,
        target.top + line.top * sy,
        line.width * sx,
        line.height * sy,
      );
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ReceiptBoundsPainter oldDelegate) =>
      oldDelegate.evidence != evidence || oldDelegate.color != color;
}
