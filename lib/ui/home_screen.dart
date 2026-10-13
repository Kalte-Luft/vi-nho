import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/expense.dart';
import '../services/ocr_service.dart';
import '../services/receipt_parser.dart';
import '../state/app_state.dart';
import 'charts.dart';
import 'review_screen.dart';
import 'style.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int tab = 0;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  final search = TextEditingController();
  Category? filter;
  bool busy = false;
  String progress = 'Đang đọc hóa đơn…';
  final ocr = OcrService();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => recoverPhoto());
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> recoverPhoto() async {
    try {
      final lost = await ocr.picker.retrieveLostData();
      if (!mounted) return;
      if (lost.files?.isNotEmpty == true) {
        await process(lost.files!.first.path);
      } else if (lost.exception != null) {
        message('Không khôi phục được ảnh vừa chụp. Hãy chọn lại.');
      }
    } catch (_) {
      /* No recoverable camera result on this launch. */
    }
  }

  Future<void> process(String path) async {
    setState(() {
      busy = true;
      progress = 'Đang đọc hóa đơn…';
    });
    ReceiptDraft? draft;
    try {
      draft = await ocr.recognize(path);
    } catch (_) {
      draft = const ReceiptDraft(
        merchant: '',
        amount: null,
        date: null,
        rawText: '',
        warnings: [
          'Không đọc được ảnh. Bạn vẫn có thể đối chiếu ảnh và nhập thủ công.',
        ],
      );
    }
    if (!mounted) return;
    setState(() => busy = false);
    await review(draft: draft, photo: path);
  }

  Future<void> pick(ImageSource source) async {
    setState(() {
      busy = true;
      progress =
          'Đang mở ${source == ImageSource.camera ? 'camera' : 'thư viện'}…';
    });
    try {
      final file = await ocr.pick(source);
      if (!mounted) return;
      if (file == null) {
        setState(() => busy = false);
        return;
      }
      await process(file.path);
    } on PlatformException {
      if (mounted) setState(() => busy = false);
      message(
        'Không mở được camera/thư viện. Kiểm tra quyền của ứng dụng trong Cài đặt Android.',
      );
    } catch (_) {
      if (mounted) setState(() => busy = false);
      message('Không chọn được ảnh. Hãy thử lại.');
    }
  }

  Future<void> sampleReceipt() async {
    setState(() {
      busy = true;
      progress = 'Đang chuẩn bị ảnh mẫu…';
    });
    try {
      final bytes = await rootBundle.load('assets/receipts/sample_receipt.png');
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/sample_receipt.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      if (mounted) await process(file.path);
    } catch (_) {
      if (mounted) setState(() => busy = false);
      message('Không mở được ảnh mẫu. Hãy chọn ảnh từ thư viện.');
    }
  }

  Future<void> review({
    ReceiptDraft? draft,
    String? photo,
    Expense? expense,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ReviewScreen(draft: draft, photoPath: photo, expense: expense),
      ),
    );
    if (saved == true) {
      HapticFeedback.lightImpact();
      message('Đã cập nhật sổ chi tiêu');
    }
  }

  Future<void> sources() async {
    final source = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Thêm khoản chi'),
              const SizedBox(height: 6),
              const Text('Chụp rõ tổng tiền, ngày và tên cửa hàng.'),
              const SizedBox(height: 18),
              for (final (index, icon, title, subtitle) in [
                (
                  0,
                  Icons.camera_alt_outlined,
                  'Chụp hóa đơn',
                  'Nhận diện chữ ngay trên thiết bị',
                ),
                (
                  1,
                  Icons.photo_library_outlined,
                  'Chọn từ thư viện',
                  'Dùng ảnh hóa đơn đã chụp',
                ),
                (
                  2,
                  Icons.edit_outlined,
                  'Nhập thủ công',
                  'Khi không có hóa đơn',
                ),
                (
                  3,
                  Icons.auto_awesome_outlined,
                  'Thử quét ảnh mẫu',
                  'Ảnh mẫu đi qua ML Kit thật',
                ),
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                    child: Icon(icon),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(subtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, index),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    switch (source) {
      case 0:
        await pick(ImageSource.camera);
      case 1:
        await pick(ImageSource.gallery);
      case 2:
        await review();
      case 3:
        await sampleReceipt();
    }
  }

  List<Expense> inMonth(List<Expense> data) => data
      .where((e) => e.date.year == month.year && e.date.month == month.month)
      .toList();
  Widget monthSelector() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'Tháng trước',
        onPressed: () =>
            setState(() => month = DateTime(month.year, month.month - 1)),
        icon: const Icon(Icons.chevron_left, size: 20),
      ),
      Text(
        'Tháng ${month.month.toString().padLeft(2, '0')} · ${month.year}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      IconButton(
        tooltip: 'Tháng sau',
        onPressed: () =>
            setState(() => month = DateTime(month.year, month.month + 1)),
        icon: const Icon(Icons.chevron_right, size: 20),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final data = inMonth(app.expenses);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 78,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: green,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: lime,
                size: 23,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ví nhỏ',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  'CHI TIÊU GỌN GÀNG',
                  style: TextStyle(fontSize: 9, letterSpacing: 2),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Đổi giao diện sáng/tối',
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () async {
              try {
                await app.setTheme(
                  Theme.of(context).brightness == Brightness.dark
                      ? ThemeMode.light
                      : ThemeMode.dark,
                );
              } catch (_) {
                message('Không lưu được giao diện.');
              }
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            if (app.loading)
              const Center(child: CircularProgressIndicator())
            else if (app.error != null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(app.error!),
                    TextButton(
                      onPressed: app.load,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              )
            else
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: switch (tab) {
                      0 => overview(app, data),
                      1 => history(data),
                      _ => reports(data),
                    },
                  ),
                ),
              ),
            if (busy)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Center(
                    child: Surface(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          Text(progress),
                          const SizedBox(height: 8),
                          const Text(
                            'Không cần tải ảnh lên máy chủ',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: tab == 0 || busy || app.loading || app.error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: sources,
              backgroundColor: green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Quét hóa đơn'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: busy
            ? null
            : (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Sổ chi tiêu',
          ),
          NavigationDestination(
            icon: Icon(Icons.donut_large_outlined),
            selectedIcon: Icon(Icons.donut_large),
            label: 'Thống kê',
          ),
        ],
      ),
    );
  }

  Widget overview(AppState app, List<Expense> data) {
    final total = data.fold(0, (sum, e) => sum + e.amount);
    final remaining = app.budget - total;
    return ListView(
      key: const ValueKey('overview'),
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 105),
      children: [
        const Text(
          'Một chút mỗi ngày,',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -.9,
          ),
        ),
        const Text(
          'chủ động hơn mỗi tháng.',
          style: TextStyle(fontSize: 18, height: 1.6),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF234F40), Color(0xFF36745C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'CHI TIÊU THÁNG',
                      style: TextStyle(
                        color: Color(0xFFD8E9DA),
                        fontSize: 11,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${month.month.toString().padLeft(2, '0')} / ${month.year}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: total.toDouble()),
                  duration: const Duration(milliseconds: 650),
                  builder: (context, value, child) => Text(
                    money(value.round()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(Icons.receipt_long, size: 16, color: lime),
                  const SizedBox(width: 7),
                  Text(
                    '${data.length} khoản chi',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: editBudget,
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sửa ngân sách',
                            style: TextStyle(color: lime, fontSize: 12),
                          ),
                          SizedBox(width: 3),
                          Icon(Icons.north_east, size: 13, color: lime),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: (total / app.budget).clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 700),
                  builder: (context, value, child) => LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    color: remaining >= 0 ? lime : const Color(0xFFFFBD9C),
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                remaining >= 0
                    ? 'Còn ${money(remaining)} trong ngân sách ${money(app.budget)}'
                    : 'Vượt ${money(-remaining)} so với ngân sách ${money(app.budget)}',
                style: const TextStyle(
                  color: Color(0xFFD8E9DA),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Surface(
          onTap: sources,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.document_scanner_outlined),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quét hóa đơn',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Chụp · Kiểm tra · Lưu',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: sources,
                tooltip: 'Quét ngay',
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionTitle(
          'Gần đây',
          trailing: TextButton(
            onPressed: () => setState(() => tab = 1),
            child: const Text('Xem tất cả'),
          ),
        ),
        const SizedBox(height: 8),
        if (data.isEmpty)
          empty(
            app.expenses.isEmpty
                ? 'Bắt đầu từ hóa đơn đầu tiên'
                : 'Tháng này chưa có khoản chi',
            'Quét hóa đơn hoặc nhập một khoản chi để theo dõi.',
            sample: app.expenses.isEmpty,
          )
        else
          ...data.take(4).map(expenseTile),
        if (data.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.offline_bolt_outlined, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'OCR và sổ chi tiêu hoạt động offline.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget expenseTile(Expense expense) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Card(
      key: ValueKey(expense.id),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => review(expense: expense),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: expense.category.color.withValues(alpha: .17),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  expense.category.icon,
                  color: expense.category.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.merchant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${expense.category.label} · ${shortDate(expense.date)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 108),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    money(expense.amount),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget history(List<Expense> data) {
    final query = ReceiptParser.normalize(search.text.trim());
    final filtered = data
        .where(
          (e) =>
              (filter == null || e.category == filter) &&
              ReceiptParser.normalize(
                '${e.merchant} ${e.note}',
              ).contains(query),
        )
        .toList();
    return Column(
      key: const ValueKey('history'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SectionTitle('Sổ chi tiêu'),
              Align(alignment: Alignment.centerRight, child: monthSelector()),
              const SizedBox(height: 8),
              TextField(
                controller: search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tìm cửa hàng, ghi chú…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () => setState(() => search.clear()),
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: filter == null,
                        onSelected: (_) => setState(() => filter = null),
                      ),
                    ),
                    ...Category.values.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c.label),
                          selected: filter == c,
                          onSelected: (_) => setState(() => filter = c),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${filtered.length} khoản chi',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    money(filtered.fold(0, (a, e) => a + e.amount)),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    empty(
                      'Chưa có khoản chi phù hợp',
                      'Thử đổi tháng, danh mục hoặc từ khóa.',
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 105),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => expenseTile(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget reports(List<Expense> data) {
    final totals = {
      for (final category in Category.values)
        category: data
            .where((e) => e.category == category)
            .fold(0, (a, e) => a + e.amount),
    };
    final total = totals.values.fold(0, (a, b) => a + b);
    final now = DateTime.now();
    final days = List.generate(
      7,
      (i) => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - i)),
    );
    final all = ref.read(appProvider).expenses;
    final values = days
        .map(
          (day) => all
              .where(
                (e) =>
                    e.date.year == day.year &&
                    e.date.month == day.month &&
                    e.date.day == day.day,
              )
              .fold(0, (a, e) => a + e.amount),
        )
        .toList();
    return ListView(
      key: const ValueKey('reports'),
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 105),
      children: [
        const SectionTitle('Bức tranh chi tiêu'),
        Align(alignment: Alignment.centerRight, child: monthSelector()),
        const SizedBox(height: 12),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TIỀN ĐI ĐÂU?',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              DonutChart(values: totals),
              const SizedBox(height: 16),
              if (total == 0)
                const Text(
                  'Thêm khoản chi để thấy phân bổ theo danh mục.',
                  style: TextStyle(fontSize: 13),
                ),
              for (final entry in totals.entries.where((e) => e.value > 0))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: entry.key.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          entry.key.label,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '${(entry.value / total * 100).round()}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        money(entry.value),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhịp chi tiêu',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              const Text(
                '7 ngày gần nhất · mọi danh mục',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              Text(
                money(values.fold(0, (a, b) => a + b)),
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              WeeklyChart(values: values, days: days),
            ],
          ),
        ),
      ],
    );
  }

  Widget empty(String title, String subtitle, {bool sample = false}) => Surface(
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.receipt_long_outlined, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
        if (sample) ...[
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: () async {
              try {
                await ref.read(appProvider).samples();
                message('Đã thêm 7 khoản chi mẫu (không phải kết quả OCR)');
              } catch (_) {
                message('Không thêm được dữ liệu mẫu.');
              }
            },
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Khám phá với dữ liệu mẫu'),
          ),
        ],
      ],
    ),
  );
  Future<void> editBudget() async {
    final controller = TextEditingController(
      text: '${ref.read(appProvider).budget}',
    );
    final key = GlobalKey<FormState>();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ngân sách mỗi tháng'),
        content: Form(
          key: key,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Số tiền (VND)'),
            validator: (value) {
              final n = ReceiptParser.parseAmount(value ?? '');
              return n == null || n < 1 || n > 999999999
                  ? 'Nhập ngân sách hợp lệ'
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(
                  context,
                  ReceiptParser.parseAmount(controller.text),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    // Dispose after the dialog route has finished its exit animation.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (result != null && mounted) {
      try {
        await ref.read(appProvider).setBudget(result);
      } catch (_) {
        message('Không lưu được ngân sách.');
      }
    }
  }
}
