# Ví Nhỏ v1.1.0 - xác minh tuần 8

Ngày: 26/10/2026. Phạm vi: pipeline OCR → review → SQLite → Riverpod NotifierProvider → CustomPainter.

## Kiểm tra tự động

- `flutter analyze --no-pub`: đạt, không có lỗi/cảnh báo phân tích.
- `flutter test --no-pub --reporter expanded`: 14/15 test đạt lần đầu. Test review tìm nút ngoài viewport trước khi ListView dựng nó.
- Sửa thao tác cuộn trong test, không thay đổi mã ứng dụng. Lần chạy lại riêng đầu tiên vẫn chọn nhầm Scrollable của ô nhập; đổi sang Scrollable thuộc ListView và bỏ focus.
- `flutter test --no-pub test/receipt_review_test.dart --reporter expanded`: đạt 1/1. Tổng cộng 15 test đã đạt; các test đã đạt không chạy lại.
- Bao phủ: 5 parser, 3 SQLite (CRUD/preferences, lưu ảnh/persistence, migration v1 → v2), 2 OCR metadata, 3 notifier (snapshot bất biến, lỗi ghi, dispose khi đang tải), 2 widget (CRUD/navigation/theme/màn hình hẹp, bắt buộc xác nhận và lưu số đã sửa).

Không chạy test trong lúc viết tính năng; chỉ thực hiện đợt cuối và chạy lại test bị lỗi sau khi sửa.

## Thiết bị và phạm vi

Thiết bị USB: `25053RT47C`, Android 16 / API 36. Trước khi cài, package `vn.edu.vku.vi_nho` không có trên thiết bị. Vì vậy đây là cài mới; migration giữ dữ liệu cũ được xác minh bằng SQLite test, không khẳng định đã thử cập nhật trên dữ liệu cũ của điện thoại.

Camera hóa đơn giấy thật, chọn từ thư viện và airplane mode chưa kiểm tra trong đợt này. Video 2-3 phút do tác giả tự quay; không tạo video thay thế từ ảnh mẫu.

## APK release và walkthrough trên thiết bị

- `bash tool/flutter_android.sh build apk --release --no-pub`: thành công (185,6 giây), APK khoảng 86,6 MB. Công cụ cảnh báo hỗ trợ Gradle/AGP/Kotlin hiện tại sẽ bị bỏ trong tương lai, không chặn build này.
- `apksigner verify --verbose --print-certs`: hợp lệ với APK Signature Scheme v2, RSA 2048.
- `adb install -r`: Success. Android xác nhận versionName=1.1.0, versionCode=2, minSdk=24.
- Dùng chức năng thêm 7 khoản mẫu: tổng 478.000 VND. Dùng “Thử quét ảnh mẫu” qua ML Kit native: HIGHLANDS COFFEE, 69.000 VND, ngày 13/10/2026; 17 bounding boxes khớp các dòng trên ảnh.
- Quan sát nút “Xác nhận & lưu” disabled khi chưa tích xác nhận. Tích checkbox rồi lưu thành công; tự chuyển sang thống kê tháng 10/2026, tổng 547.000 VND và danh mục ăn uống 193.000 VND.
- Chụp thống kê ở cả theme tối/sáng; force-stop rồi cold start. Tổng 547.000 VND/8 khoản chi và theme sáng được khôi phục. Mở khoản OCR từ lịch sử: ảnh, 17 khung chữ, cửa hàng, 69.000 VND và ngày vẫn còn.
- 7 khoản seed là dữ liệu mẫu giao diện, tách biệt với khoản 69.000 VND được đọc bằng ML Kit. Giữ dữ liệu mẫu trên thiết bị để tiện khám phá.

Ảnh bằng chứng: [review](week8-screenshots/review.png), [nút lưu chưa xác nhận](week8-screenshots/confirmation.png), [light](week8-screenshots/light.png), [dark](week8-screenshots/dark.png), [mở lại khoản chi](week8-screenshots/persisted.png).

SHA-256 APK: `60deb60c5435cf2c15540548fddc2c5941927a676fe3e42ae3c34c4207b79347`.

## Phát hành

Mã nguồn pipeline: commit `45eaacb`. GitHub Release [v1.1.0](https://github.com/Kalte-Luft/vi-nho/releases/tag/v1.1.0) chứa APK và báo cáo PDF 4 trang. Digest SHA-256 GitHub trả về khớp file cục bộ; cả hai URL tải trực tiếp trả HTTP 200 khi truy cập không đăng nhập. Repository public.
