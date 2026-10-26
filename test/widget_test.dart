import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vi_nho/main.dart';
import 'package:vi_nho/services/expense_repository.dart';
import 'package:vi_nho/models/expense.dart';
import 'package:vi_nho/state/app_state.dart';

class MemoryRepository extends ExpenseRepository {
  final values = <Expense>[];
  final settings = <String, String>{};
  @override
  Future<List<Expense>> all() async => List.of(values);
  @override
  Future<String?> setting(String key) async => settings[key];
  @override
  Future<void> setSetting(String key, String value) async {
    settings[key] = value;
  }

  @override
  Future<void> save(Expense expense) async {
    values.removeWhere((e) => expense.id != null && e.id == expense.id);
    values.insert(
      0,
      Expense(
        id: expense.id ?? values.length + 1,
        merchant: expense.merchant,
        amount: expense.amount,
        date: expense.date,
        category: expense.category,
      ),
    );
  }

  @override
  Future<void> delete(Expense expense) async {
    values.removeWhere((e) => e.id == expense.id);
  }

  @override
  Future<void> addSamples() async {
    final now = DateTime.now();
    final items = [
      ('Highlands Coffee', 59000, Category.food),
      ('Nhà sách Fahasa', 128000, Category.study),
      ('Grab Bike', 22000, Category.transport),
      ('Co.opmart Đà Nẵng', 186000, Category.shopping),
      ('Cơm trưa VKU', 30000, Category.food),
      ('In tài liệu', 18000, Category.study),
    ];
    for (var i = 0; i < items.length; i++) {
      final (merchant, amount, category) = items[i];
      values.add(
        Expense(
          id: i + 1,
          merchant: merchant,
          amount: amount,
          date: DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: i)),
          category: category,
        ),
      );
    }
  }
}

Future<void> screenshot(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('SCREENSHOTS')) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('capture')),
    );
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('docs/screenshots').create(recursive: true);
    await File(
      'docs/screenshots/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  testWidgets(
    'Demo navigation, charts, filters, dark mode and manual CRUD without overflow',
    (tester) async {
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = true);
      final font = FontLoader('Roboto')
        ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf'));
      await tester.runAsync(() => font.load());
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await tester.runAsync(() => icons.load());
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = MemoryRepository();
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: const ValueKey('capture'),
            child: const ViNhoApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bắt đầu từ hóa đơn đầu tiên'), findsOneWidget);
      await container.read(appProvider.notifier).samples();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await screenshot(tester, '01-overview');
      await tester.tap(find.text('Sổ chi tiêu'));
      await tester.pumpAndSettle();
      await screenshot(tester, '02-history');
      await tester.enterText(find.byType(TextField), 'fahasa');
      await tester.pumpAndSettle();
      expect(find.text('Nhà sách Fahasa'), findsOneWidget);
      expect(find.text('Highlands Coffee'), findsNothing);
      await tester.tap(find.text('Thống kê'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await screenshot(tester, '03-reports');
      await tester.drag(find.text('TIỀN ĐI ĐÂU?'), const Offset(0, -300));
      await tester.pumpAndSettle();
      await screenshot(tester, '03b-weekly');
      await tester.tap(find.byTooltip('Đổi giao diện sáng/tối'));
      await tester.pumpAndSettle();
      await screenshot(tester, '04-dark');
      await tester.tap(find.byTooltip('Đổi giao diện sáng/tối'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quét hóa đơn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhập thủ công'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận & lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập tên cửa hàng'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'Cà phê VKU');
      await tester.enterText(find.byType(TextFormField).at(1), '45000');
      await tester.pumpAndSettle();
      tester.state<FormState>(find.byType(Form)).validate();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await screenshot(tester, '05-review');
      await tester.ensureVisible(find.text('Xác nhận & lưu'));
      await tester.tap(find.text('Xác nhận & lưu'));
      await tester.pumpAndSettle();
      expect(repository.values.first.amount, 45000);
      await tester.tap(find.text('Sổ chi tiêu'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Cà phê');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cà phê VKU'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), '50000');
      await tester.ensureVisible(find.text('Xác nhận & lưu'));
      await tester.tap(find.text('Xác nhận & lưu'));
      await tester.pumpAndSettle();
      expect(repository.values.first.amount, 50000);
      await tester.tap(find.text('Sổ chi tiêu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cà phê VKU'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Xóa khoản chi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();
      expect(repository.values.length, 6);
      expect(tester.takeException(), isNull);
      // Compact screens and larger text must stay usable.
      tester.view.physicalSize = const Size(960, 1920);
      await tester.tap(find.text('Thống kê'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      debugDisableShadows = true;
    },
  );
}
