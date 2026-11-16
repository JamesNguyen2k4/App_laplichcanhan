import 'dart:convert';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'storage_service.dart';

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  static final AudioPlayer _vieneuAudioPlayer = AudioPlayer();
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

  /// Đọc to đoạn văn bản tiếng Việt (Fallback Google TTS)
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
    await _vieneuAudioPlayer.stop();
  }

  /// Đọc lời nhắc thông báo cho một sự kiện (Ưu tiên VieNeu-TTS, nếu không thì Google TTS)
  static Future<void> speakEventReminder(String title, String description, {Function()? onComplete}) async {
    String message = "Thông báo nhắc nhở. Đến giờ: $title.";
    if (description.isNotEmpty && description.trim() != title.trim()) {
      message += " Nội dung: $description.";
    }

    final useVieNeu = StorageService.getUseVieNeuTts();
    final serverUrl = StorageService.getVieNeuServerUrl();

    if (useVieNeu && serverUrl != null && serverUrl.isNotEmpty) {
      try {
        final success = await playVieNeuTts(message, serverUrl, onComplete: onComplete);
        if (success) return;
      } catch (e) {
        // ignore: avoid_print
        print("VieNeu-TTS lỗi kết nối, chuyển sang Google TTS: $e");
      }
    }

    // Dự phòng mặc định: Google TTS
    await speak(message, onComplete: onComplete);
  }

  /// Gửi văn bản lên VieNeu-TTS Server và phát trực tiếp
  static Future<bool> playVieNeuTts(String text, String serverUrl, {Function()? onComplete}) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;
      final uri = Uri.parse('$cleanUrl/synthesize');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': text}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (onComplete != null) {
          _vieneuAudioPlayer.onPlayerComplete.listen((_) => onComplete());
        }
        await _vieneuAudioPlayer.play(BytesSource(response.bodyBytes));
        return true;
      }
    } catch (e) {
      // ignore: avoid_print
      print("Lỗi phát VieNeu-TTS: $e");
    }
    return false;
  }
}
