THƯ MỤC CHỨA TRỌNG SỐ MODEL VIENEU-TTS 0.3B OFFLINE
===================================================

Để chạy VieNeu-TTS 0.3B hoàn toàn Offline trong file APK:
Đặt 2 file sau vào thư mục này trước khi chạy `flutter build apk --release`:

1. VieNeu-TTS-0.3B-Q4_K_M.gguf (Backbone GGUF 0.3B đã lượng tử hóa)
2. neucodec_decoder_int8.onnx  (Audio Codec Decoder 24kHz)

Lưu ý: Khi chưa có 2 file trọng số này, ứng dụng vẫn biên dịch và chạy bình thường
với cơ chế dự phòng tự động sang giọng đọc tiếng Việt hệ thống (Google TTS).
