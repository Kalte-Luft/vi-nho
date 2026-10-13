# Kết quả kiểm tra

Ngày chuẩn bị: 13/10/2026 (Việt Nam).

## Môi trường

- Flutter stable 3.47.4, Dart 3.13.3, Ubuntu.
- Android minSdk 24; compileSdk/targetSdk theo Flutter.
- Gradle 8.14.3, Android Gradle Plugin 8.13.0, Kotlin 2.2.20.
- Build Android dùng Eclipse Temurin JDK 21.0.12.1 đầy đủ tại `.tools/jdk21`. Plugin OCR 0.15.1 đóng gói model Latin `com.google.mlkit:text-recognition:16.0.1`.
- Riverpod 2.6.1; các phiên bản phụ thuộc khác được khóa trong `pubspec.lock`.

## Đã kiểm tra

- `flutter analyze --no-pub`: không có lỗi/cảnh báo.
- `flutter test --no-pub --dart-define=SCREENSHOTS=true`: **8 test pass**.
- 5 test parser: merchant, total, ngày; bỏ cash/change/subtotal; dấu tiếng Việt; dòng tổng tách; VND grouping; date sai; không đoán trường thiếu.
- 2 test repository: SQLite CRUD/settings/demo không trùng; database file đóng/mở lại; ảnh được copy sang thư mục riêng, vẫn tồn tại sau khi xóa file cache nguồn, xóa giao dịch sẽ xóa ảnh.
- 1 test widget: tab, tìm kiếm, validation, thêm/sửa/xóa, dark mode, biểu đồ và màn hình rộng 390/320 logical pixels.
- Render và xem ảnh tổng quan, lịch sử, donut, tuần, dark mode và form trong `screenshots/`. Đây là Flutter test với repository demo, không phải chứng cứ chạy camera trên điện thoại.
- Report PDF 3 trang đã render và kiểm tra bố cục.
- Keystore release cục bộ được tạo riêng; keystore/key.properties/build được gitignore.

## Kiểm thử trên điện thoại Android thật

Thiết bị `25053RT47C`, serial `f4d808f`, Android 16 / API 36, arm64.

- APK release đã build, chữ ký APK v2 hợp lệ (RSA 2048, chứng thư riêng của dự án), cài thành công qua USB.
- ML Kit native trên ảnh mẫu đã đọc đúng **HIGHLANDS COFFEE**, **69.000 VND**, **13/10/2026**; không nhầm tạm tính 74.000 hoặc tiền khách đưa 100.000.
- Form review hiển thị ảnh, thông tin OCR và danh mục; xác nhận lưu thành công vào SQLite thật.
- Force-stop và cold start lại app: khoản chi 69.000 và theme sáng vẫn còn; mở lại chi tiết hiển thị ảnh hóa đơn đã lưu.
- Donut và biểu đồ cột tuần đã hiển thị đúng trên APK release thực tế; đã kiểm tra cả vị trí sau cuộn.
- Ảnh chụp thật từ điện thoại trong `docs/device-screenshots/`; `docs/screenshots/` vẫn là ảnh Flutter test với dữ liệu demo.
- Trên điện thoại có một khoản chi ảnh mẫu 69.000 để bạn khám phá app; đây là dữ liệu kiểm thử, không phải hóa đơn thật của người dùng.

**Còn cần bạn thử trước khi nộp:** chụp hóa đơn thật bằng camera, chọn ảnh thư viện, các bố cục hóa đơn thực tế và chế độ máy bay. OCR là heuristic, phải đối chiếu ảnh và sửa dữ liệu nếu cần. Không khẳng định đã kiểm tra camera hay offline trên phần cứng khi chưa thực hiện.

## Khắc phục môi trường sau lần mất mạng

- Thư mục NDK bị tải dở và thiếu `source.properties` đã được chuyển sang thư mục tạm; Android SDK tải/cài lại NDK 28.2.13676358 đầy đủ.
- Java 25 không tương thích Gradle 8.14.3. Java 21 hệ thống chỉ có JRE, thiếu `javac`; đã tải JDK 21 đầy đủ từ Eclipse Temurin, kiểm tra SHA-256 và đặt tại `.tools/jdk21` (gitignore).
- `tool/flutter_android.sh` chọn JDK đầy đủ cho lệnh Flutter; không đổi global Flutter config.
- Release R8: thêm đúng 8 rules cho các lớp model Trung/Nhật/Hàn/Devanagari mà plugin tham chiếu `compileOnly`. App chỉ khởi tạo `TextRecognitionScript.latin`; không bỏ qua các lỗi missing class khác.
- Lỗi phiên bản Java/Gradle trong log người dùng đã được xác định; “Got dependencies!” và thông báo có phiên bản thư viện mới không phải lỗi.

## Bản bàn giao cuối

- `output/app-release.apk`: khoảng 86 MB, đã cập nhật thành công trên điện thoại, giữ khoản chi OCR mẫu.
- SHA-256: `0d46a85bf6bf0c270d5c959b241b1b5071d28391963e69c117e6e692cd63c160`.
- File kiểm tra chữ ký: `output/APK_SIGNATURE.txt`; checksum: `output/SHA256SUMS`.
- Sau kiểm tra màn hình thật, Tổng quan dùng thẻ “Quét hóa đơn” có thể bấm toàn thẻ để tránh nút nổi che số tiền. Các tab Sổ/Thống kê vẫn có FAB.
- Mã sau điều chỉnh: analyze không có issues, cả 8 test pass; APK release build và cài lại thành công.
