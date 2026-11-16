import 'package:speech_to_text/speech_to_text.dart';

class SttService {
  static final SpeechToText _speech = SpeechToText();
  static bool _isAvailable = false;

  /// Khởi tạo và kiểm tra quyền Micro
  static Future<bool> init() async {
    if (_isAvailable) return true;
    _isAvailable = await _speech.initialize(
      onError: (val) => print('Lỗi nhận diện giọng nói: $val'),
      onStatus: (val) => print('Trạng thái Mic: $val'),
    );
    return _isAvailable;
  }

  /// Bắt đầu nghe và nhận diện tiếng Việt
  static Future<void> startListening({
    required Function(String text) onResult,
    Function()? onSoundLevelChange,
  }) async {
    final available = await init();
    if (available) {
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
        },
        localeId: 'vi_VN', // Cấu hình nhận diện giọng nói tiếng Việt
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
      );
    }
  }

  /// Dừng nghe
  static Future<void> stopListening() async {
    await _speech.stop();
  }

  static bool get isListening => _speech.isListening;
}
