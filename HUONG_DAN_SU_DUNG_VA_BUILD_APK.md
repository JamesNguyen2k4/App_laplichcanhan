# HƯỚNG DẪN DỰ ÁN: LỊCH CÁ NHÂN & BÁO THỨC THÔNG MINH TÍCH HỢP GEMINI AI

Ứng dụng Flutter di động hỗ trợ quản lý lịch trình cá nhân, báo thức toàn màn hình với cơ chế **Reo chuông ➔ Ngắt ➔ Đọc lời nhắc tiếng Việt bằng Google TTS**, kèm **Trợ lý AI Gemini** tự động phân tích giọng nói (Mic) hoặc văn bản thành lịch hẹn.

---

## 🌟 1. Các tính năng cốt lõi đã hoàn thiện

1. **Giao diện Lịch Tháng (TableCalendar):**
   - Xem tổng quan lịch theo tháng chuẩn Tiếng Việt.
   - Hiển thị chấm màu chỉ báo ngày có sự kiện.
   - Bấm vào ngày để xem danh sách lịch hẹn chi tiết trong ngày đó.
   - Nút "Hôm nay" để quay nhanh về ngày hiện tại.

2. **Trợ lý AI Gemini (Giọng nói & Văn bản tự nhiên):**
   - Bấm giữ/chạm nút **Mic** để nói tự nhiên (Ví dụ: *"Sáng mai 8h30 đi gặp khách hàng ở Cầu Giấy, nhắc trước 15 phút nhé"*).
   - Gemini AI tự động trích xuất: Tiêu đề, Thời gian chính xác, Số phút nhắc trước, Danh mục, Lời nhắc đọc bằng giọng nói.
   - Bật thẻ xem trước (Preview) để người dùng xác nhận trước khi lưu vào lịch.

3. **Cơ chế Báo thức & Giọng đọc Tiếng Việt:**
   - Đến giờ hẹn: Bật sáng màn hình báo thức (Full-screen alarm).
   - Phát chuông báo thức lớn trong 6 giây.
   - Tự động ngắt chuông và kích hoạt **Google Text-to-Speech (TTS) đọc to lời nhắc bằng tiếng Việt**.
   - Hỗ trợ nút **"Tắt báo thức"** và **"Báo lại sau 5 phút (Snooze)"**.

4. **Cài đặt & Tùy biến (Settings):**
   - Ô nhập **Gemini API Key** (lưu an toàn trong bộ nhớ máy).
   - Nút kiểm tra thử giọng đọc tiếng Việt.
   - Thư mục `assets/audio/` sẵn sàng để bạn thêm file nhạc chuông `.mp3` tùy ý.

---

## 📁 2. Cấu trúc thư mục mã nguồn

```
DuanLenLichCaNhan/
├── android/                             # Cấu hình Android (Quyền Exact Alarm, FullScreen, Mic, Boot)
│   └── app/src/main/AndroidManifest.xml
├── assets/
│   └── audio/                          # Nơi bạn đặt file chuông báo thức mp3
├── lib/
│   ├── models/
│   │   └── event_model.dart            # Cấu trúc dữ liệu sự kiện
│   ├── services/
│   │   ├── storage_service.dart        # Lưu trữ lịch offline
│   │   ├── alarm_service.dart          # Quản lý chu kỳ chuông & nhắc nhở
│   │   ├── tts_service.dart            # Đọc lời nhắc tiếng Việt (Google TTS)
│   │   ├── stt_service.dart            # Nhận diện giọng nói tiếng Việt qua Mic
│   │   └── gemini_service.dart         # Kết nối Gemini AI phân tích câu lệnh
│   ├── screens/
│   │   ├── home_calendar_screen.dart   # Màn hình chính (Lịch tháng + sự kiện ngày)
│   │   ├── add_event_screen.dart       # Form tạo/sửa lịch hẹn thủ công
│   │   ├── ai_assistant_dialog.dart    # Trợ lý AI (Mic thu âm + Text)
│   │   ├── alarm_ring_screen.dart      # Màn hình chuông reo toàn màn hình
│   │   └── settings_screen.dart        # Cài đặt Gemini API Key & Thử âm thanh
│   └── main.dart                       # Điểm khởi chạy ứng dụng
└── pubspec.yaml                        # Danh sách thư viện và tài nguyên
```

---

## 🔑 3. Hướng dẫn lấy Gemini API Key (Hoàn toàn miễn phí)

1. Truy cập vào: **https://aistudio.google.com/app/apikey**
2. Đăng nhập bằng tài khoản Google của bạn.
3. Nhấn **"Create API key"** (Tạo khóa API mới).
4. Sao chép chuỗi khóa (bắt đầu bằng `AIzaSy...`).
5. Mở ứng dụng, vào biểu tượng **⚙️ Cài đặt** ở góc trên bên phải, dán API Key vào và nhấn **Lưu**.

---

## 🚀 4. Hướng dẫn Build file `.apk` cài lên điện thoại

### Bước 1: Chuẩn bị môi trường (Nếu máy tính chưa cài Flutter)
- Tải bộ công cụ Flutter SDK mới nhất tại: https://docs.flutter.dev/get-started/install/windows
- Giải nén vào thư mục `C:\src\flutter` và thêm đường dẫn `C:\src\flutter\bin` vào `PATH` của Windows.

### Bước 2: Tải các thư viện dự án
Mở Terminal / PowerShell tại thư mục dự án và chạy:
```bash
flutter pub get
```

### Bước 3: Lệnh xuất file APK cài đặt
Chạy lệnh sau để build file APK Release tối ưu cho điện thoại Android:
```bash
flutter build apk --release
```

### Bước 4: Nhận file APK và cài đặt lên điện thoại
- Sau khi build xong, file APK sẽ nằm tại đường dẫn:
  `build/app/outputs/flutter-apk/app-release.apk`
- Bạn chỉ cần copy file `app-release.apk` này sang điện thoại qua **Zalo, Google Drive, hoặc cắm cáp USB**.
- Trên điện thoại, nhấn vào file APK và chọn **Cài đặt (Install)** là sử dụng được ngay!
