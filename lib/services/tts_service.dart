import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    await _flutterTts.setLanguage('vi-VN'); // Tiếng Việt
    await _flutterTts.setSpeechRate(0.5);   // Tốc độ vừa phải, rõ ràng
    await _flutterTts.setVolume(1.0);       // Âm lượng tối đa
    await _flutterTts.setPitch(1.0);        // Cao độ chuẩn

    _flutterTts.setErrorHandler((msg) {
      // ignore: avoid_print
      print("TTS Lỗi: $msg");
    });

    _isInitialized = true;
  }

  /// Đọc to đoạn văn bản tiếng Việt
  static Future<void> speak(String text, {Function()? onComplete}) async {
    await init();
    if (text.trim().isEmpty) return;

    if (onComplete != null) {
      _flutterTts.setCompletionHandler(onComplete);
    }

    await _flutterTts.speak(text);
  }

  /// Dừng đọc
  static Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// Đọc lời nhắc thông báo cho một sự kiện
  static Future<void> speakEventReminder(String title, String description, {Function()? onComplete}) async {
    String message = "Thông báo nhắc nhở. Đến giờ: $title.";
    if (description.isNotEmpty && description.trim() != title.trim()) {
      message += " Nội dung: $description.";
    }
    await speak(message, onComplete: onComplete);
  }
}
