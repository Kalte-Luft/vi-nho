"""Generate the 3-page Vietnamese draft with ReportLab (not a runtime app dependency)."""
from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor, white
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph
from reportlab.lib.styles import ParagraphStyle

ROOT = Path(__file__).resolve().parents[1]
FONT_ROOT = Path('/usr/share/fonts/truetype/dejavu')
pdfmetrics.registerFont(TTFont('VN', str(FONT_ROOT/'DejaVuSans.ttf')))
pdfmetrics.registerFont(TTFont('VN-Bold', str(FONT_ROOT/'DejaVuSans-Bold.ttf')))
pdfmetrics.registerFontFamily('VN', normal='VN', bold='VN-Bold', italic='VN', boldItalic='VN-Bold')
W, H = 595.28, 841.89
c = canvas.Canvas(str(ROOT/'docs/bao_cao_ky_thuat.pdf'), pagesize=(W,H))
c.setTitle('Ví Nhỏ - Báo cáo kỹ thuật Mini Project 3')
c.setAuthor('VKU Student Project - draft')
GREEN, INK, MUTED = HexColor('#286B57'), HexColor('#263B36'), HexColor('#63736C')
style = ParagraphStyle('body', fontName='VN', fontSize=9.3, leading=15, textColor=INK)

def para(text, y, width=499, x=48, size=None):
    s = style if size is None else ParagraphStyle('small',parent=style,fontSize=size,leading=size*1.55)
    p=Paragraph(text,s); _,h=p.wrap(width,720);p.drawOn(c,x,y-h);return y-h-10

def title(text, y):
    c.setFont('VN-Bold',13); c.setFillColor(GREEN);c.drawString(48,y,text);return y-20

def page(number, subtitle):
    c.setFillColor(HexColor('#F6F7F2'));c.rect(0,H-100,W,100,fill=1,stroke=0)
    c.setFillColor(GREEN);c.setFont('VN-Bold',24);c.drawString(48,H-49,'ví nhỏ')
    c.setFillColor(INK);c.setFont('VN',10);c.drawString(48,H-73,subtitle)
    c.setStrokeColor(HexColor('#DCE6DD'));c.line(48,43,W-48,43)
    c.setFillColor(MUTED);c.setFont('VN',8);c.drawString(48,28,'VKU · Mini Project 3 · Bản dự thảo cần bổ sung thông tin sinh viên')
    c.drawRightString(W-48,28,f'{number} / 3')

page(1,'Receipt OCR & Expense Tracker | Báo cáo kỹ thuật')
y=H-124
y=para('<b>Họ tên:</b> ......................................  <b>MSSV:</b> .............................<br/><b>Lớp:</b> ..........................................  <b>Giảng viên:</b> Nguyễn Thanh Tuấn',y)
y=title('01. Bài toán và phạm vi',y)
y=para('Sinh viên và quản lý câu lạc bộ nhập chi tiêu từ hóa đơn giấy, dễ sai và mất thời gian. Ví Nhỏ chuyển ảnh hóa đơn thành bản nháp khoản chi, cho người dùng kiểm tra trước khi lưu. Ứng dụng Flutter Android dùng dữ liệu cục bộ, không yêu cầu tài khoản hoặc máy chủ.',y)
y=para('Phạm vi bám Week 7, trang 41-43: chụp ảnh, nhận diện chữ trên thiết bị, parser Regex tổng tiền/ngày/cửa hàng, SQLite CRUD và lưu ảnh; Material 3, dark mode; donut danh mục và cột tuần có animation bằng CustomPainter. Mở rộng nhỏ: ngân sách tháng và tìm kiếm/lọc.',y)
y=title('02. Luồng xử lý',y)
steps=['Camera / thư viện','ML Kit Latin OCR','Dart Regex parser','Review & sửa','SQLite + ảnh']
for i,label in enumerate(steps):
    xx=48+i*101
    c.setFillColor(GREEN if i%2==0 else HexColor('#E7F0E1'));c.roundRect(xx,y-45,95,40,9,fill=1,stroke=0)
    c.setFillColor(white if i%2==0 else INK);c.setFont('VN',7);c.drawCentredString(xx+47.5,y-28,label)
y-=64
y=para('ML Kit model Latin được đóng gói qua dependency Android <b>com.google.mlkit:text-recognition</b>. Ảnh không tải lên máy chủ. Parser chỉ là heuristic dễ giải thích; OCR không phải bảo đảm dữ liệu chính xác. Chỉ nút “Xác nhận &amp; lưu” mới ghi khoản chi vào SQLite.',y)
y=title('03. Đối chiếu tiêu chí chấm',y)
for label,desc in [
 ('OCR & heuristics · 3,5 điểm','image_picker, TextRecognizer, tìm merchant header, ngày hợp lệ và dòng tổng thanh toán; fallback nhập tay.'),
 ('Custom canvas · 2,5 điểm','drawArc vẽ donut; drawRRect vẽ cột 7 ngày; TextPainter ghi nhãn; TweenAnimationBuilder tạo chuyển động.'),
 ('State & DB · 2,0 điểm','Riverpod 2.6.1 + ChangeNotifier; sqflite CRUD, settings; copy ảnh khỏi cache camera vào documents.'),
 ('UI/UX · 1,0 điểm','Material 3, sáng/tối, SafeArea, form xác nhận, phóng to ảnh, empty/loading/error state.'),
 ('Bài nộp · 1,0 điểm','Source, hướng dẫn .md, script ký APK và báo cáo; sinh viên bổ sung video/demo thực tế và GitHub.')]:
 y=para(f'<b>{label}</b><br/>{desc}',y,size=8.7)
c.showPage()

page(2,'Thiết kế giao diện và thuật toán trích xuất')
y=H-127
y=title('04. Giao diện và tương tác',y)
y=para('Tông xanh trầm, nền trung tính và điểm nhấn xanh chanh. Ba tab: Tổng quan, Sổ chi tiêu, Thống kê. Nút quét luôn dễ tiếp cận. Các biểu đồ có màu danh mục, nhãn số và chuyển động nhẹ. Theme sáng/tối được lưu vào SQLite.',y)
# Rendered Flutter screenshots with demo data, not physical device evidence.
for name,x in [('01-overview',88),('03b-weekly',321)]:
    path=ROOT/f'docs/screenshots/{name}.png'
    c.drawImage(str(path),x,y-322,width=149,height=322,preserveAspectRatio=True,mask='auto')
y-=340
y=para('Hình: render từ Flutter widget test với dữ liệu demo, không phải ảnh chụp từ điện thoại. Ảnh thật và video cần được thay vào sau khi kiểm thử thiết bị.',y,size=8)
y=title('05. Parser Regex và xác nhận',y)
y=para('<b>Tổng tiền:</b> ưu tiên “Tổng cộng”, “Thanh toán”, “Grand total”, “Amount due”; sau đó “Total/Tổng”. Bỏ qua tạm tính, giảm giá, tiền khách đưa và tiền thừa. Hỗ trợ số VND 69.000 / 69,000 / 69000 / 69,000.00; tổng ở dòng kế tiếp nếu OCR tách nhãn.',y)
y=para('<b>Ngày:</b> regex dd/MM/yyyy hoặc dd-MM-yy; kiểm tra lại ngày/tháng để không biến 31/02 thành ngày khác. <b>Cửa hàng:</b> dòng chữ đầu phù hợp trong sáu dòng đầu, bỏ nhãn hóa đơn, địa chỉ, điện thoại. Trường thiếu sinh cảnh báo; không đoán số lớn nhất.',y)
y=para('Màn hình review cho xem ảnh gốc và văn bản OCR; nhập sửa cửa hàng, số tiền, ngày, danh mục, ghi chú. Form từ chối tên rỗng và số tiền ngoài 1-999.999.999 VND. Hóa đơn bố cục lạ hoặc ảnh mờ có thể cần sửa thủ công.',y)
c.showPage()

page(3,'Cấu trúc mã, kiểm thử và hướng phát triển')
y=H-125
y=title('06. State, SQLite và vòng đời',y)
y=para('<b>main.dart</b> thiết lập MaterialApp và ProviderScope. <b>AppState</b> giữ list expenses, budget, theme và trạng thái tải/lỗi. Riverpod 2 sở hữu ChangeNotifier; thao tác async hoàn thành mới cập nhật UI. Navigator mở form review, không cần routing phức tạp.',y)
y=para('<b>ExpenseRepository</b> chứa SQLite version 1. Bảng expenses: id, merchant, amount (INTEGER VND), date (ISO), category, note, photo_path, raw_text. Bảng settings lưu budget/theme và cờ demo. Query dùng tham số; lịch sử sort ngày rồi id giảm dần. Ảnh được sao chép vào thư mục receipts riêng, xóa ảnh sau khi xóa bản ghi.',y)
y=para('<b>Lifecycle:</b> đóng TextRecognizer trong finally; dispose TextEditingController; kiểm tra mounted sau async; image_picker.retrieveLostData khôi phục ảnh nếu Android hủy activity. ListView.builder cho lịch sử; ValueKey(id) nhận diện card; SafeArea và constraints thích nghi màn hình.',y)
y=title('07. Kiểm thử và giới hạn kết quả',y)
y=para('Test tự động gồm parser (tổng tiền, dấu tiếng Việt, ngày sai, tiền khách/tiền thừa), SQLite in-memory thật (CRUD/settings/dữ liệu mẫu không trùng) và widget test (điều hướng, tìm kiếm, validation, thêm/sửa/xóa, theme, chart, màn hình hẹp). Kết quả và môi trường thực tế xem <b>docs/VERIFICATION.md</b>.',y)
y=para('<b>Kiểm thử thiết bị thật:</b> APK release đã cài trên 25053RT47C, Android 16 / API 36. ML Kit native đọc ảnh mẫu đúng HIGHLANDS COFFEE, 69.000 VND, 13/10/2026. Sau force-stop/cold start, dữ liệu, theme và ảnh vẫn còn. Chưa thử camera hóa đơn thật, thư viện và chế độ máy bay; cần bổ sung trước khi nộp.',y)
y=para('<b>Thiết bị:</b> 25053RT47C / Android 16. <b>Ảnh mẫu:</b> 69.000 VND - đúng.<br/><b>Hóa đơn thật 1:</b> .................................................................<br/><b>Hóa đơn thật 2:</b> .................................................................<br/><b>Camera/thư viện/chế độ máy bay:</b> ...............................................',y)
y=title('08. Bàn giao và hướng phát triển',y)
y=para('README.md hướng dẫn USB, cài APK, tạo khóa release và xử lý lỗi môi trường. DEMO.md có kịch bản quay video 2-3 phút. Ngân sách tháng và tìm kiếm/lọc là mở rộng trong phạm vi mini project. Hướng phát triển sau môn học: cải thiện parser cho nhiều mẫu hóa đơn, xuất CSV hoặc thống kê khoảng ngày; chưa triển khai để giữ bài gọn.',y)
y=title('Tài liệu tham khảo',y)
y=para('Nguyễn Thanh Tuấn, Week 7 - Flutter &amp; Dart Part 1, VKU, trang 41-43.<br/>pub.dev/packages/google_mlkit_text_recognition<br/>pub.dev/packages/image_picker · pub.dev/packages/flutter_riverpod/versions/2.6.1<br/>developers.google.com/ml-kit/vision/text-recognition/v2/android<br/>Mã nguồn: lib/services/receipt_parser.dart, lib/ui/charts.dart, lib/data/expense_repository.dart.',y,size=8)
c.save()
print(ROOT/'docs/bao_cao_ky_thuat.pdf')
