# Kịch bản demo video (2-3 phút)

Dùng chức năng quay màn hình của Android. Quay dọc, tắt thông báo, để cỡ chữ mặc định. Chuẩn bị một hóa đơn rõ hoặc dùng ảnh mẫu để kiểm tra luồng trước khi quay. Không quay thông tin cá nhân trên hóa đơn nếu không muốn công khai.

1. **0:00-0:20 - Tổng quan**: giới thiệu Ví Nhỏ, số tiền tháng, ngân sách. Giải thích app offline cho sinh viên/CLB.
2. **0:20-1:05 - OCR**: Quét hóa đơn → Camera, chụp hóa đơn thật. Mở ảnh gốc, đối chiếu tên/ngày/tổng. Nếu OCR sai, sửa trực tiếp để cho thấy review. Chọn danh mục, thêm ghi chú và lưu. Có thể bật chế độ máy bay để chứng minh OCR offline.
3. **1:05-1:30 - SQLite CRUD**: Sổ chi tiêu → tìm cửa hàng → sửa khoản chi. Đóng hẳn app và mở lại để chứng minh dữ liệu/ảnh còn lưu. Xóa một khoản khác, hiện hộp thoại xác nhận.
4. **1:30-2:00 - Canvas**: Thống kê → donut animation và cột 7 ngày. Giải thích donut theo tháng, cột theo 7 ngày gần nhất; đọc số tiền một danh mục.
5. **2:00-2:20 - UI và mở rộng**: đổi dark mode; sửa ngân sách để hiện số còn lại/vượt mức. Lọc theo danh mục và đổi tháng.
6. **2:20-2:40 - Kết thúc**: nhắc ML Kit + Dart Regex + Riverpod 2 + sqflite + CustomPainter. Không cần máy chủ hay đăng nhập.

## Ảnh chụp nên nộp

- Tổng quan có ngân sách và vài khoản chi.
- Review OCR kèm ảnh hóa đơn và các trường nhận được.
- Sổ chi tiêu với tìm kiếm/lọc.
- Thống kê donut và cột, có số liệu đa danh mục.
- Dark mode.

Để biểu đồ đẹp, thêm 5-7 khoản chi ở nhiều danh mục và ngày khác nhau. Có thể dùng “Khám phá với dữ liệu mẫu” để xem UI trước, nhưng phải phân biệt dữ liệu mẫu khi thuyết trình. Ảnh trong `docs/screenshots` là preview được render bằng Flutter test. Ảnh thật đã chụp từ điện thoại nằm trong `docs/device-screenshots`, gồm review OCR, dữ liệu sau restart và giao diện cuối. Khi nộp, bổ sung hóa đơn thực tế của bạn.

## Checklist trên điện thoại thật

- [ ] Camera và chọn ảnh thư viện hoạt động; hủy chọn không báo lỗi.
- [ ] Thử ảnh mẫu: cửa hàng Highlands, tổng 69.000, ngày 13/10/2026.
- [ ] Quét ít nhất 2 hóa đơn thật và ghi lại trường nào đúng/sai.
- [ ] Sửa dữ liệu OCR rồi lưu, tiền/ngày/danh mục hiển thị đúng.
- [ ] Force stop/mở lại: dữ liệu và ảnh gốc còn nguyên.
- [ ] Sửa/xóa, tìm kiếm, tháng, danh mục hoạt động.
- [ ] Ngân sách và dark mode được lưu sau restart.
- [ ] Không có overflow khi mở bàn phím hoặc đổi hướng màn hình.
- [ ] Chế độ máy bay: OCR và CRUD vẫn hoạt động.
- [ ] APK release cài thành công; điền model điện thoại + Android vào báo cáo.

## Bài nộp theo trang 42

Source GitHub sạch, APK release có ký, video demo thực tế, báo cáo kỹ thuật 2-4 trang có họ tên/MSSV/lớp. Đây là các bước cần thông tin và thiết bị của sinh viên; dự án cung cấp source, script và mẫu báo cáo để hoàn thiện.
