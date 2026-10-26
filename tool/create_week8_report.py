"""Build the Week 8 report from recorded verification and device screenshots."""
import json
from html import escape
from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor, white
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, Table, TableStyle
from reportlab.lib.styles import ParagraphStyle

ROOT = Path(__file__).resolve().parents[1]
RESULT = json.loads((ROOT/'docs/week8-verification.json').read_text())
OUT = ROOT/'docs/vi-nho-week8-report.pdf'
for name, file in [('VN','DejaVuSans.ttf'), ('Bold','DejaVuSans-Bold.ttf'), ('Mono','DejaVuSansMono.ttf')]:
    pdfmetrics.registerFont(TTFont(name, '/usr/share/fonts/truetype/dejavu/'+file))
pdfmetrics.registerFontFamily('VN', normal='VN', bold='Bold', italic='VN', boldItalic='Bold')
W,H = 595.28,841.89
INK=HexColor('#213D34'); GREEN=HexColor('#23634E'); MUTED=HexColor('#61776D'); LINE=HexColor('#D8E4DA')
c=canvas.Canvas(str(OUT),pagesize=(W,H))
c.setTitle('Ví Nhỏ - Week 8: Connecting the System Pipeline')
c.setAuthor('Nguyen Ba Nghia - 23IT.B137')
body=ParagraphStyle('body',fontName='VN',fontSize=9.5,leading=15,textColor=INK)
small=ParagraphStyle('small',parent=body,fontSize=8.2,leading=12.5)
mono=ParagraphStyle('mono',parent=small,fontName='Mono',fontSize=7.2,leading=11,wordWrap='CJK')
def para(t,y,x=44,width=507,style=body):
    p=Paragraph(t,style);_,h=p.wrap(width,700);p.drawOn(c,x,y-h);return y-h-10

def title(t,y):
    c.setFillColor(GREEN);c.setFont('Bold',13);c.drawString(44,y-14,t);return y-29

def page(n,sub):
    c.setFillColor(HexColor('#F1F5EC'));c.rect(0,H-105,W,105,fill=1,stroke=0)
    c.setFillColor(GREEN);c.setFont('Bold',28);c.drawString(44,H-48,'ví nhỏ')
    c.setFillColor(INK);c.setFont('VN',10);c.drawString(44,H-76,sub)
    c.setStrokeColor(LINE);c.line(44,43,W-44,43)
    c.setFillColor(MUTED);c.setFont('VN',8);c.drawString(44,28,'Nguyen Ba Nghia · 23IT.B137 · VKU · 26/10/2026')
    c.drawRightString(W-44,28,f'{n} / 4')

page(1,'WEEK 8 · Connecting the System Pipeline · v1.1.0')
y=para('<b>Môn học:</b> Phát triển ứng dụng đa nền tảng<br/><b>Sinh viên:</b> Nguyen Ba Nghia · <b>MSSV:</b> 23IT.B137<br/><b>Dự án:</b> Mini-Project 3 - Receipt OCR &amp; Expense Tracker',H-124)
y=title('01. Mục tiêu và kiến trúc',y)
y=para('Ví Nhỏ chuyển ảnh hóa đơn thành khoản chi có kiểm chứng. Bản tuần 8 nối camera, nhận diện chữ, Regex, màn hình đối chiếu, lưu trữ và biểu đồ thành một luồng. Giữ phạm vi mini project: Flutter Android, xử lý trên thiết bị, không máy chủ hay đăng nhập.',y)
# Directed vector diagram: three rows, alternating direction.
labels=[('Camera / thư viện','image_picker'),('ML Kit Latin OCR','TextRecognizer'),('ReceiptParser','Dart Regex'),('SQLite v2','sqflite CRUD'),('Review & xác nhận','sửa trước khi lưu'),('NotifierProvider','immutable AppState'),('Biểu đồ động','CustomPainter')]
positions=[(44,y-57),(222,y-57),(400,y-57),(222,y-147),(400,y-147),(44,y-147),(44,y-237)]
for (label,detail),(x,yy) in zip(labels,positions):
    c.setFillColor(HexColor('#E7EFE1'));c.setStrokeColor(LINE);c.roundRect(x,yy,151,53,9,fill=1,stroke=1)
    c.setFillColor(GREEN);c.setFont('Bold',9);c.drawCentredString(x+75.5,yy+32,label)
    c.setFillColor(INK);c.setFont('VN',8);c.drawCentredString(x+75.5,yy+15,detail)
def arrow(x1,y1,x2,y2):
    c.setStrokeColor(GREEN);c.setLineWidth(1.3);c.line(x1,y1,x2,y2)
    if x1==x2: c.line(x2,y2,x2-3,y2+5);c.line(x2,y2,x2+3,y2+5)
    elif x2>x1: c.line(x2,y2,x2-5,y2-3);c.line(x2,y2,x2-5,y2+3)
    else: c.line(x2,y2,x2+5,y2-3);c.line(x2,y2,x2+5,y2+3)
arrow(195,y-30,218,y-30);arrow(373,y-30,396,y-30)
arrow(475,y-57,475,y-90);arrow(400,y-120,377,y-120);arrow(222,y-120,199,y-120);arrow(119,y-147,119,y-180)
y-=254
y=para('Review là điểm chặn ghi dữ liệu: bản nháp chưa vào SQLite. Sau khi người dùng xác nhận, controller chờ lưu thành công, đọc danh sách mới và phát state. Giao diện tự mở thống kê đúng tháng; donut chạy animation khi dữ liệu thay đổi.',y)
y=title('02. Phân lớp vừa đủ cho mini project',y)
y=para('<b>core/</b> theme · <b>models/</b> khoản chi và khung OCR · <b>services/</b> OCR, parser, repository · <b>state/</b> AppController và AppState · <b>widgets/</b> chart, ảnh, card · <b>screens/</b> tổng quan, lịch sử, review, thống kê.',y)
para('Mã nguồn: <link href="https://github.com/Kalte-Luft/vi-nho" color="#23634E">github.com/Kalte-Luft/vi-nho</link><br/>APK: <link href="https://github.com/Kalte-Luft/vi-nho/releases/download/v1.1.0/app-release.apk" color="#23634E">GitHub Releases / v1.1.0 / app-release.apk</link>',y,style=small)
c.showPage()

page(2,'TRÍCH XUẤT & KIỂM CHỨNG · Regex và lưu trữ')
y=title('03. Bảng Regex và quy tắc trích xuất',H-124)
y=para('Chuẩn hóa chữ thường và bỏ dấu tiếng Việt để so khớp nhãn; giữ nguyên văn bản OCR gốc. Parser là heuristic minh bạch, không bảo đảm chính xác với mọi mẫu hóa đơn.',y)
rows=[['Trường / vai trò','Regex / quy tắc trong mã','Xử lý'],
['Ngày',r'\b(\d{1,2})[/.-](\d{1,2})[/.-](\d{4}|\d{2})\b','Kiểm tra lại ngày/tháng; năm 2000-2100. Năm 2 chữ số cộng 2000.'],
['Tổng ưu tiên',r'tong cong|grand total|thanh toan|amount due|phai tra','Điểm 3. Nhãn tong/total theo ranh giới từ: điểm 2. Lấy dòng cuối khi đồng điểm.'],
['Loại trừ',r'tam tinh|subtotal|tien khach|cash|change|tien thua|giam gia|discount','Không nhầm tạm tính, giảm giá, tiền khách đưa hoặc tiền thừa thành tổng.'],
['Chuỗi số',r'\d[\d.,]*(?:[ ]\d{3})*','Lấy số cuối dòng tổng; nhận dòng kế tiếp nếu chỉ gồm số, dấu phân cách và ký hiệu tiền.'],
['Định dạng VND',r'^\d+$|^\d{1,3}([., ]\d{3})+$','Bỏ ký hiệu VND/đ/₫; phần lẻ chỉ nhận 00. Tổng hợp lệ: 1-999.999.999.'],
['Cửa hàng',r'[a-z]; reject ^\d','Dòng phù hợp đầu tiên trong 6 dòng đầu; loại nhãn hóa đơn, địa chỉ, điện thoại và thanh toán.']]
cells=[]
for i,row in enumerate(rows):
    cells.append([Paragraph(escape(t), small if i==0 or j!=1 else mono) for j,t in enumerate(row)])
t=Table(cells,colWidths=[83,214,210]);t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),HexColor('#E7EFE1')),('GRID',(0,0),(-1,-1),.5,LINE),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),8),('RIGHTPADDING',(0,0),(-1,-1),8),('TOPPADDING',(0,0),(-1,-1),8),('BOTTOMPADDING',(0,0),(-1,-1),8)]))
_,h=t.wrap(507,700);t.drawOn(c,44,y-h);y-=h+20
y=title('04. Review và bằng chứng OCR',y)
y=para('ML Kit trả văn bản và bounding box từng dòng. ReceiptEvidence giữ kích thước ảnh cùng tọa độ; CustomPainter áp dụng cùng phép co ảnh BoxFit.contain. Người dùng bật/tắt khung, phóng to, xem chữ gốc và sửa form. Nút lưu bản nháp OCR chỉ bật sau khi tích ô đã đối chiếu.',y)
y=title('05. SQLite và tương thích dữ liệu cũ',y)
para('Bảng expenses giữ số tiền nguyên VND, ngày ISO, danh mục, ghi chú, đường dẫn ảnh và raw_text. Migration v1 → v2 thêm cột nullable <b>ocr_evidence</b> chứa JSON; không xóa bảng. Hóa đơn cũ thiếu metadata vẫn đọc được. Ảnh được sao chép vào documents; budget và theme lưu trong settings. Lỗi ghi được trả về form, không báo lưu thành công giả.',y)
c.showPage()

page(3,'GIAO DIỆN THỰC TẾ · Android release trên điện thoại')
y=title('06. Light / dark và đối chiếu hóa đơn',H-124)
y=para('Ảnh chụp bản v1.1.0 trên 25053RT47C, Android 16. Luồng OCR dùng ảnh hóa đơn mẫu đóng gói trong app, đi qua ML Kit native. Biểu đồ gồm 7 khoản mẫu và khoản OCR. Chưa kiểm tra camera hóa đơn giấy thật.',y)
for name,x,label in [('light',44,'Thống kê · sáng'),('dark',217,'Thống kê · tối'),('review',390,'Review · khung OCR')]:
    c.setFillColor(GREEN);c.setFont('Bold',9);c.drawCentredString(x+80,y-12,label)
    c.drawImage(str(ROOT/f'docs/week8-screenshots/{name}.png'),x,y-382,width=161,height=355,preserveAspectRatio=True,anchor='n',mask='auto')
y-=400
y=para('Biểu đồ donut chia theo danh mục, dùng drawArc và TweenAnimationBuilder; biểu đồ cột 7 ngày dùng drawRRect. Màu danh mục nhất quán với lịch sử; dữ liệu phụ thuộc snapshot Riverpod. Theme được ghi SQLite và khôi phục khi mở lại.',y)
y=title('Tương tác trọng tâm',y)
para('1. Chụp/chọn ảnh → nhận diện và điền bản nháp.<br/>2. Đọc khung OCR trên ảnh; sửa cửa hàng, ngày, số tiền và danh mục.<br/>3. Tích xác nhận → ghi SQLite → mở thống kê đúng tháng.<br/>4. Từ sổ chi tiêu, mở lại để sửa/xóa hoặc đối chiếu ảnh đã lưu.<br/><br/>Mở rộng nhỏ giữ lại: ngân sách tháng và tìm kiếm/lọc; không thêm backend hoặc công nghệ vượt phạm vi.',y)
c.showPage()

page(4,'XÁC MINH & GIỚI HẠN · Bàn giao v1.1.0')
y=title('07. Kết quả kiểm thử cuối',H-124)
y=para('Triển khai hoàn tất trước khi chạy đợt xác minh cuối. Chỉ chạy lại kiểm tra bị lỗi khi cần sửa. Bằng chứng chi tiết và phạm vi: docs/WEEK8_VERIFICATION.md.',y)
for label,value in RESULT['checks']:
    y=para(f'<b>{escape(label)}:</b> {escape(value)}',y)
y=title('08. Giới hạn và đánh giá',y)
y=para('OCR Latin có thể sai dấu, chữ nhỏ, ảnh nghiêng/mờ hoặc hóa đơn nhiều cột. Regex ưu tiên nhãn quen thuộc; nhiều dòng tổng cùng mức ưu tiên chọn dòng cuối. Tên cửa hàng chỉ xét 6 dòng đầu. App dùng VND nguyên, chưa hỗ trợ ngoại tệ, viết tay hoặc đồng bộ nhiều thiết bị.',y)
y=para('Khung OCR giúp đối chiếu vị trí chữ, không biểu thị độ tin cậy hay đảm bảo giá trị đúng. Ảnh có EXIF/hướng xoay đặc biệt có thể cần chụp lại. Kiểm tra thiết bị lần này dùng ảnh mẫu; camera hóa đơn thật, chọn thư viện và chế độ máy bay chưa được xác minh. Gỡ app/xóa dữ liệu sẽ mất sổ chi tiêu cục bộ.',y)
y=title('09. Deliverables',y)
y=para('<b>APK:</b> bản release ký cùng khóa cập nhật, tải từ GitHub Releases v1.1.0.<br/><b>Repository:</b> public, đủ core/models/services/state/widgets/screens và README.<br/><b>Báo cáo:</b> 4 trang, sơ đồ kiến trúc, bảng Regex, ảnh sáng/tối và giới hạn.<br/><b>Video 2-3 phút:</b> sinh viên tự quay camera hóa đơn thật; chưa đính kèm.',y)
y=title('Tài liệu kỹ thuật',y)
para('Mã nguồn bản v1.1.0: lib/services/receipt_parser.dart, expense_repository.dart; lib/state/app_state.dart; lib/widgets/receipt_photo.dart và charts.dart.<br/>Yêu cầu: ảnh đề Week 8 “Connecting the System Pipeline” và “Deliverables &amp; Grading Checklist”; kế thừa phạm vi slide Week 7 Flutter Part 1.<br/>Thư viện: flutter_riverpod 2.6.1, google_mlkit_text_recognition, image_picker, sqflite (phiên bản khóa trong pubspec.lock).',y,style=small)
c.save()
print(OUT)
