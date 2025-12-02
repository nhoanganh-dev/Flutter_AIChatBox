# README - Đồ án giữa kỳ: Tích hợp ChatGPT vào Flutter

## Mô tả dự án:
Đồ án giữa kỳ này là một ứng dụng Flutter tích hợp với API của ChatGPT để cung cấp tính năng trò chuyện thông minh. Ứng dụng cho phép người dùng gửi câu hỏi hoặc yêu cầu và nhận phản hồi từ ChatGPT thông qua giao diện người dùng thân thiện. Dự án được phát triển bằng Flutter, hỗ trợ chạy trên các nền tảng Android, iOS và trình duyệt Chrome (web).

## Thông tin chung
- **Ngôn ngữ lập trình**: Dart
- **Framework**: Flutter (phiên bản 3.x.x trở lên)
- **API sử dụng**: ChatGPT API
- **Nền tảng hỗ trợ**: Android, iOS, Web (Chrome)
- **Trạng thái dự án**: Đã chạy `flutter clean` để làm sạch các file build trước khi nộp.

## Yêu cầu môi trường:
Để chạy dự án, cần chuẩn bị các thành phần sau:
- **Flutter SDK**: Phiên bản 3.2.0 trở lên. Tải tại: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
- **Dart**: Phiên bản tương thích với Flutter (thường được cài tự động khi cài Flutter).
- **IDE**: Android Studio, VS Code, hoặc IntelliJ IDEA (khuyến nghị Android Studio cho cấu hình đầy đủ).

## Công cụ bổ sung:
- **Android**: Android SDK, emulator (hoặc thiết bị thật).
- **iOS**: Xcode (chỉ cần thiết khi chạy trên macOS với iOS simulator/thiết bị thật).
- **Web**: Trình duyệt Chrome để chạy ứng dụng dưới dạng web.
- **Mạng**: Kết nối internet ổn định để gọi API ChatGPT.

## Hướng dẫn cài đặt và chạy dự án

### Bước 1:
Clone dự án và vào thư mục "Flutter_AIChatBox".

### Bước 2:
Tại thư mục "Flutter_AIChatBox", mở Terminal (hoặc Command Line) và lần lượt chạy các lệnh sau:

- `flutter doctor`  
  -> Lệnh này để kiểm tra cấu hình hệ thống Flutter xem đã đủ chưa.

- `flutter pub get`  
  -> Lệnh này sẽ cài đặt tất cả các gói được liệt kê trong file `pubspec.yaml`.

### Bước 3:
Khởi chạy chương trình bằng CLI tùy theo nền tảng:

- **Chạy trên Android**:  
  `flutter run -d android`

- **Chạy trên Web**:  
  `flutter run -d chrome`  
  (hoặc `-d edge`, `-d firefox` nếu bạn muốn chạy bằng trình duyệt khác)

- **Chạy trên iOS (yêu cầu máy MacOS)**:  
  `flutter run -d ios`

- **Xem danh sách thiết bị**:  
  `flutter devices`

- **Chạy trên thiết bị mong muốn**:  
  `flutter run -d [device_id]`

### Link video demo sản phẩm:

[Video demo](https://drive.google.com/file/d/1gCAxW7wNXav7uW5NWd2p39GwLoxVtVeM/view?usp=sharing)

### Link video hướng dẫn chạy bằng thiết bị máy ảo Android tại link sau:

[Video hướng dẫn](https://drive.google.com/file/d/1ChYiotUDB94IkwDegouH3TkRfA9aR68j/view?usp=sharing)
