import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../services/receipt_parser.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/receipt_photo.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, this.draft, this.photoPath, this.expense});
  final ReceiptDraft? draft;
  final String? photoPath;
  final Expense? expense;
  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController merchant, amount, note;
  late DateTime date;
  late Category category;
  bool saving = false;
  bool verified = false;
  String get rawText => widget.expense?.rawText ?? widget.draft?.rawText ?? '';
  String? get photo => widget.expense?.photoPath ?? widget.photoPath;
  @override
  void initState() {
    super.initState();
    merchant = TextEditingController(
      text: widget.expense?.merchant ?? widget.draft?.merchant ?? '',
    );
    final value = widget.expense?.amount ?? widget.draft?.amount;
    amount = TextEditingController(text: value == null ? '' : '$value');
    note = TextEditingController(text: widget.expense?.note ?? '');
    date = widget.expense?.date ?? widget.draft?.date ?? DateTime.now();
    category = widget.expense?.category ?? Category.food;
  }

  @override
  void dispose() {
    merchant.dispose();
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (widget.draft != null && !verified) return;
    if (!form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await ref
          .read(appProvider.notifier)
          .save(
            Expense(
              id: widget.expense?.id,
              merchant: merchant.text.trim(),
              amount: ReceiptParser.parseAmount(amount.text)!,
              date: DateTime(date.year, date.month, date.day),
              category: category,
              note: note.text.trim(),
              photoPath: photo,
              rawText: rawText,
              evidence: widget.expense?.evidence ?? widget.draft?.evidence,
            ),
          );
      if (mounted) Navigator.pop(context, date);
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa lưu được. Kiểm tra bộ nhớ và thử lại.'),
          ),
        );
      }
    }
  }

  Future<void> delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa khoản chi này?'),
        content: const Text('Ảnh hóa đơn đi kèm cũng sẽ bị xóa khỏi ứng dụng.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => saving = true);
    try {
      await ref.read(appProvider.notifier).delete(widget.expense!);
      if (mounted) Navigator.pop(context, date);
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không xóa được. Hãy thử lại.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.expense == null ? 'Kiểm tra hóa đơn' : 'Chi tiết khoản chi',
        ),
        actions: [
          if (widget.expense != null)
            IconButton(
              onPressed: saving ? null : delete,
              tooltip: 'Xóa khoản chi',
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Form(
              key: form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
                children: [
                  if (photo != null) ...[
                    ReceiptPhoto(
                      path: photo!,
                      evidence:
                          widget.expense?.evidence ?? widget.draft?.evidence,
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (widget.draft != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.fact_check_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.draft!.warnings.isEmpty
                                  ? 'OCR đã đọc xong. Hãy đối chiếu cửa hàng, ngày và tổng tiền trước khi lưu.'
                                  : widget.draft!.warnings.join('\n'),
                              style: const TextStyle(height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  const SectionTitle('Thông tin khoản chi'),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: merchant,
                    enabled: !saving,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Cửa hàng',
                      prefixIcon: Icon(Icons.storefront_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Nhập tên cửa hàng'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amount,
                    enabled: !saving,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tổng thanh toán (VND)',
                      suffixText: '₫',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: (value) {
                      final number = ReceiptParser.parseAmount(value ?? '');
                      return number == null || number <= 0 || number > 999999999
                          ? 'Nhập số tiền từ 1 đến 999.999.999 ₫'
                          : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            final selected = await showDatePicker(
                              context: context,
                              initialDate: date,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100, 12, 31),
                            );
                            if (selected != null && mounted) {
                              setState(() => date = selected);
                            }
                          },
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text('Ngày chi: ${shortDate(date)}'),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'DANH MỤC',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: Category.values
                        .map(
                          (item) => ChoiceChip(
                            label: Text(item.label),
                            avatar: Icon(item.icon, size: 18),
                            selected: category == item,
                            onSelected: saving
                                ? null
                                : (_) => setState(() => category = item),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: note,
                    enabled: !saving,
                    maxLength: 250,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú (tùy chọn)',
                      prefixIcon: Icon(Icons.edit_note),
                    ),
                  ),
                  if (rawText.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ExpansionTile(
                      title: const Text('Văn bản OCR gốc'),
                      tilePadding: EdgeInsets.zero,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SelectableText(
                            rawText,
                            style: const TextStyle(fontSize: 13, height: 1.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ],
                  const SizedBox(height: 22),
                  if (widget.draft != null)
                    CheckboxListTile(
                      key: const ValueKey('verify-ocr'),
                      contentPadding: EdgeInsets.zero,
                      value: verified,
                      onChanged: saving
                          ? null
                          : (value) =>
                                setState(() => verified = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'Tôi đã đối chiếu cửa hàng, ngày và tổng tiền',
                        style: TextStyle(fontSize: 13),
                      ),
                      subtitle: const Text(
                        'Sửa dữ liệu OCR sai trước khi xác nhận.',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: saving || (widget.draft != null && !verified)
                        ? null
                        : save,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(saving ? 'Đang lưu…' : 'Xác nhận & lưu'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Dữ liệu và ảnh được lưu trên thiết bị của bạn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
