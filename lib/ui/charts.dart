import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/expense.dart';

class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.values});
  final Map<Category, int> values;
  @override
  Widget build(BuildContext context) {
    final total = values.values.fold(0, (a, b) => a + b);
    return Semantics(
      label: 'Biểu đồ cơ cấu chi tiêu. Tổng ${money(total)}',
      child: TweenAnimationBuilder<double>(
        key: ValueKey(values.values.join(',')),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 950),
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) => SizedBox(
          height: 190,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: DonutPainter(
                    values,
                    progress,
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    total == 0 ? 'Chưa có dữ liệu' : 'TỔNG CHI',
                    style: const TextStyle(fontSize: 11, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 128,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        money(total),
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DonutPainter extends CustomPainter {
  DonutPainter(this.values, this.progress, this.trackColor);
  final Map<Category, int> values;
  final double progress;
  final Color trackColor;
  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) / 2 - 16;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = trackColor);
    final total = values.values.fold(0, (a, b) => a + b);
    if (total == 0) return;
    var start = -math.pi / 2;
    for (final entry in values.entries) {
      if (entry.value == 0) continue;
      final sweep = entry.value / total * math.pi * 2;
      final gap = math.min(.045, sweep / 3);
      canvas.drawArc(
        rect,
        start + gap / 2,
        (sweep - gap) * progress,
        false,
        paint..color = entry.key.color,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.values != values ||
      oldDelegate.trackColor != trackColor;
}

class WeeklyChart extends StatelessWidget {
  const WeeklyChart({super.key, required this.values, required this.days});
  final List<int> values;
  final List<DateTime> days;
  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Chi tiêu bảy ngày: ${List.generate(7, (i) => '${shortDate(days[i])}: ${money(values[i])}').join(', ')}',
    child: TweenAnimationBuilder<double>(
      key: ValueKey(values.join(',')),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => SizedBox(
        height: 180,
        width: double.infinity,
        child: CustomPaint(
          painter: WeeklyPainter(
            values,
            days,
            value,
            Theme.of(context).colorScheme.onSurfaceVariant,
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
    ),
  );
}

class WeeklyPainter extends CustomPainter {
  WeeklyPainter(
    this.values,
    this.days,
    this.progress,
    this.labelColor,
    this.gridColor,
  );
  final List<int> values;
  final List<DateTime> days;
  final double progress;
  final Color labelColor, gridColor;
  void label(
    Canvas canvas,
    String text,
    Offset at,
    double width, {
    bool bold = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Roboto',
          color: labelColor,
          fontSize: 10,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: width);
    painter.paint(canvas, Offset(at.dx + (width - painter.width) / 2, at.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = values.fold(0, math.max);
    final top = math.max(maxValue, 1);
    final cell = size.width / 7;
    final height = size.height - 48;
    final paint = Paint()..color = gridColor;
    for (var i = 0; i < 4; i++) {
      final y = 20 + (height - 20) * i / 3;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint..strokeWidth = 1,
      );
    }
    for (var i = 0; i < 7; i++) {
      final x = cell * i;
      final barHeight = values[i] / top * (height - 30) * progress;
      final bar = Rect.fromLTWH(
        x + cell * .22,
        height - math.max(barHeight, 3),
        cell * .56,
        math.max(barHeight, 3),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bar, const Radius.circular(7)),
        paint..color = i == 6 ? greenChart : const Color(0xFFA8CAB3),
      );
      if (values[i] > 0) {
        label(
          canvas,
          values[i] >= 1000 ? '${(values[i] / 1000).round()}k' : '${values[i]}',
          Offset(x, bar.top - 18),
          cell,
          bold: true,
        );
      }
      label(
        canvas,
        switch (days[i].weekday) {
          7 => 'CN',
          final n => 'T${n + 1}',
        },
        Offset(x, height + 10),
        cell,
        bold: i == 6,
      );
      label(
        canvas,
        '${days[i].day}/${days[i].month}',
        Offset(x, height + 25),
        cell,
      );
    }
  }

  static const greenChart = Color(0xFF438A6C);
  @override
  bool shouldRepaint(covariant WeeklyPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.values != values ||
      oldDelegate.labelColor != labelColor ||
      oldDelegate.gridColor != gridColor;
}
