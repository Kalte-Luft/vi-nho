import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vi_nho/screens/review_screen.dart';
import 'package:vi_nho/services/receipt_parser.dart';
import 'package:vi_nho/state/app_state.dart';
import 'widget_test.dart' show MemoryRepository;

void main() {
  testWidgets(
    'OCR review must be explicitly confirmed and saves corrected values',
    (tester) async {
      final repository = MemoryRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [repositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('vi')],
            locale: const Locale('vi'),
            home: ReviewScreen(
              draft: ReceiptParser().parse(
                'HIGHLANDS\n26/10/2026\nTong cong 69.000',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), '75000');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Xác nhận & lưu'),
        250,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Xác nhận & lưu'),
      );
      expect(button.onPressed, isNull);
      expect(repository.values, isEmpty);
      await tester.ensureVisible(find.byKey(const ValueKey('verify-ocr')));
      await tester.tap(find.byKey(const ValueKey('verify-ocr')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Xác nhận & lưu'),
        250,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Xác nhận & lưu'));
      await tester.pumpAndSettle();
      expect(repository.values.single.amount, 75000);
    },
  );
}
