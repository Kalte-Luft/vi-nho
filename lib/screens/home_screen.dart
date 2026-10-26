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
import 'overview_screen.dart';
import 'history_screen.dart';
import 'reports_screen.dart';
import 'review_screen.dart';
import '../core/app_theme.dart';
import '../widgets/common.dart';

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
    final savedDate = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(
        builder: (_) =>
            ReviewScreen(draft: draft, photoPath: photo, expense: expense),
      ),
    );
    if (savedDate != null && mounted) {
      setState(() {
        month = DateTime(savedDate.year, savedDate.month);
        tab = 2;
      });
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
                await ref
                    .read(appProvider.notifier)
                    .setTheme(
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
                      onPressed: ref.read(appProvider.notifier).load,
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
                      0 => OverviewScreen(
                        app: app,
                        data: data,
                        month: month,
                        onScan: sources,
                        onBudget: editBudget,
                        onHistory: () => setState(() => tab = 1),
                        onExpense: (e) => review(expense: e),
                        empty: empty,
                      ),
                      1 => HistoryScreen(
                        data: data,
                        search: search,
                        filter: filter,
                        monthSelector: monthSelector(),
                        onRefresh: () => setState(() {}),
                        onFilter: (c) => setState(() => filter = c),
                        onExpense: (e) => review(expense: e),
                        empty: empty,
                      ),
                      _ => ReportsScreen(
                        data: data,
                        all: app.expenses,
                        monthSelector: monthSelector(),
                      ),
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
                await ref.read(appProvider.notifier).samples();
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
        await ref.read(appProvider.notifier).setBudget(result);
      } catch (_) {
        message('Không lưu được ngân sách.');
      }
    }
  }
}
