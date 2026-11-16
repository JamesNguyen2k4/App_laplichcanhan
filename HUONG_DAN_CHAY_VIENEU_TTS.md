# HƯỚNG DẪN TÍCH HỢP & CHẠY VIENEU-TTS (pnnbao97)

Mô hình **VieNeu-TTS** giúp ứng dụng có giọng đọc thông báo báo thức tiếng Việt siêu tự nhiên, hỗ trợ cảm xúc và nhân bản giọng nói.

---

## 🚀 1. Cách chạy Server VieNeu-TTS trên Máy tính

### Bước 1: Cài đặt thư viện Python
Mở Terminal hoặc Command Prompt trên máy tính có Python và chạy lệnh:

* **Trên Windows:**
```bash
pip install vieneu --extra-index-url https://pnnbao97.github.io/llama-cpp-python-v0.3.16/cpu/
pip install fastapi uvicorn
```

* **Trên Linux / macOS:**
```bash
pip install vieneu fastapi uvicorn
```

### Bước 2: Khởi động Server
Trong thư mục dự án, chạy lệnh:
```bash
python vieneu_server.py
```
Server sẽ khởi động tại: `http://0.0.0.0:8000`

---

## 📱 2. Kết nối từ Điện thoại vào Server

1. **Tìm địa chỉ IP máy tính:**
   - Trên máy tính, mở Command Prompt và gõ `ipconfig`.
   - Tìm dòng `IPv4 Address` (ví dụ: `192.168.1.15`).

2. **Cấu hình trên App điện thoại:**
   - Đảm bảo điện thoại và máy tính kết nối chung một mạng Wi-Fi.
   - Mở App ➔ Vào **⚙️ Cài đặt** ➔ Mục **VieNeu-TTS AI (pnnbao97)**.
   - Bật công tắc **"Ưu tiên sử dụng VieNeu-TTS"**.
   - Nhập URL: `http://192.168.1.15:8000` (thay bằng IP máy tính của bạn).
   - Bấm **"Lưu cấu hình"** và bấm nút **"Nghe thử"** để kiểm tra!

---

## 🛡️ 3. Cơ chế hoạt động tự động (Fallback)
- **Khi có kết nối Server VieNeu-TTS:** Ứng dụng sẽ phát giọng đọc tiếng Việt siêu mượt của VieNeu-TTS khi báo thức.
- **Khi mất kết nối hoặc tắt máy tính:** Ứng dụng sẽ **tự động chuyển sang Google TTS có sẵn trên điện thoại** mà không gây lỗi, đảm bảo báo thức của bạn luôn reo đúng giờ 100%!
