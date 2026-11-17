import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';
import 'vieneu_03b_service.dart';
import 'vietnamese_g2p_service.dart';

class TtsVoiceOption {
  final String name;
  final String locale;

  const TtsVoiceOption({required this.name, required this.locale});
}

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    await _flutterTts.setLanguage('vi-VN');
    await _flutterTts.setVolume(1.0);
    await applySavedVoiceSettings();

    _flutterTts.setErrorHandler((msg) {
      if (kDebugMode) print("TTS Lỗi: $msg");
    });

    _isInitialized = true;
  }

  /// Lấy danh sách giọng đọc có sẵn trên thiết bị / trình duyệt (ưu tiên Tiếng Việt lên đầu)
  static Future<List<TtsVoiceOption>> getAvailableVoices() async {
    try {
      final raw = await _flutterTts.getVoices;
      if (raw is! List) return [];

      final voices = <TtsVoiceOption>[];
      for (final item in raw) {
        if (item is Map) {
          final name = item['name']?.toString() ?? '';
          final locale = item['locale']?.toString() ?? '';
          if (name.isNotEmpty) {
            voices.add(TtsVoiceOption(name: name, locale: locale));
          }
        }
      }

      // Đưa các giọng tiếng Việt (vi-VN / vi_VN / vi) lên đầu danh sách
      voices.sort((a, b) {
        final aVi = _isVietnameseVoice(a) ? 0 : 1;
        final bVi = _isVietnameseVoice(b) ? 0 : 1;
        if (aVi != bVi) return aVi.compareTo(bVi);
        return a.name.compareTo(b.name);
      });
      return voices;
    } catch (e) {
      if (kDebugMode) print("Lỗi lấy danh sách giọng đọc: $e");
      return [];
    }
  }

  static bool _isVietnameseVoice(TtsVoiceOption v) {
    final loc = v.locale.toLowerCase();
    final name = v.name.toLowerCase();
    return loc.startsWith('vi') || name.contains('vietnam') || name.contains('tiếng việt');
  }

  /// Áp dụng giọng đọc, tốc độ và cao độ đã lưu (tự động chọn giọng vi-VN nếu chưa chọn)
  static Future<void> applySavedVoiceSettings() async {
    await _flutterTts.setLanguage('vi-VN');
    await _flutterTts.setSpeechRate(StorageService.getTtsSpeechRate());
    await _flutterTts.setPitch(StorageService.getTtsPitch());

    var savedName = StorageService.getTtsVoiceName();
    var savedLocale = StorageService.getTtsVoiceLocale();

    if (savedName == null || savedLocale == null) {
      final voices = await getAvailableVoices();
      final viVoice = voices.where(_isVietnameseVoice).firstOrNull;
      if (viVoice != null) {
        savedName = viVoice.name;
        savedLocale = viVoice.locale;
        await StorageService.saveTtsVoice(savedName, savedLocale);
      }
    }

    if (savedName != null && savedLocale != null) {
      await _flutterTts.setVoice({'name': savedName, 'locale': savedLocale});
    }
  }

  /// Chuẩn hóa câu lời nhắc trước khi đưa vào model / TTS đọc
  static String buildReminderMessage(String title, String description) {
    final cleanTitle = title.trim();
    final cleanDesc = description.trim();

    final raw = (cleanDesc.isNotEmpty && cleanDesc != cleanTitle)
        ? 'Thông báo nhắc nhở. Đến giờ: $cleanTitle. Nội dung: $cleanDesc.'
        : 'Thông báo nhắc nhở. Đến giờ: $cleanTitle.';

    return VietnameseG2pService.normalizeText(raw);
  }

  /// Lấy đường dẫn file âm thanh đã tổng hợp sẵn của sự kiện trên máy
  static Future<String?> getCachedAudioPath(String eventId) async {
    try {
      if (kIsWeb) return null;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/tts_event_$eventId.wav');
      if (await file.exists()) {
        return file.path;
      }
    } catch (e) {
      if (kDebugMode) print("Lỗi kiểm tra cache audio: $e");
    }
    return null;
  }

  /// Sinh sẵn file âm thanh bằng mô hình VieNeu-TTS 0.3B Offline ngay khi tạo lịch
  static Future<void> cacheEventAudio(
    String eventId,
    String title,
    String description,
  ) async {
    if (kIsWeb || !StorageService.getUseVieNeuTts()) return;
    try {
      final message = buildReminderMessage(title, description);
      final dir = await getApplicationDocumentsDirectory();
      final outPath = '${dir.path}/tts_event_$eventId.wav';
      await VieNeu03bService.synthesizeToWav(message, outPath);
    } catch (e) {
      if (kDebugMode) print("Không thể tổng hợp trước âm thanh 0.3B (sẽ dùng Google TTS): $e");
    }
  }

  /// Đọc to đoạn văn bản tiếng Việt (đã chuẩn hóa) bằng TTS hệ thống
  static Future<void> speak(String text, {Function()? onComplete}) async {
    await init();
    final normalized = VietnameseG2pService.normalizeText(text);
    if (normalized.isEmpty) return;

    await applySavedVoiceSettings();
    await _flutterTts.stop();

    if (onComplete != null) {
      _flutterTts.setCompletionHandler(onComplete);
    }

    await _flutterTts.speak(normalized);
  }

  /// Dừng đọc
  static Future<void> stop() async {
    await _flutterTts.stop();
    await _audioPlayer.stop();
  }

  /// Đọc lời nhắc thông báo cho một sự kiện (100% Offline):
  /// 1. Ưu tiên file WAV sinh bởi VieNeu-TTS 0.3B trên thiết bị
  /// 2. Thử sinh trực tiếp bằng VieNeu-TTS 0.3B nếu chưa cache
  /// 3. Dự phòng bằng TTS Tiếng Việt của thiết bị
  static Future<void> speakEventReminder(
    String eventId,
    String title,
    String description, {
    Function()? onComplete,
  }) async {
    final message = buildReminderMessage(title, description);

    if (!kIsWeb && StorageService.getUseVieNeuTts()) {
      var wavPath = await getCachedAudioPath(eventId);

      if (wavPath == null) {
        final dir = await getApplicationDocumentsDirectory();
        wavPath = await VieNeu03bService.synthesizeToWav(
          message,
          '${dir.path}/tts_event_$eventId.wav',
        );
      }

      if (wavPath != null) {
        try {
          if (onComplete != null) {
            _audioPlayer.onPlayerComplete.listen((_) => onComplete());
          }
          await _audioPlayer.play(DeviceFileSource(wavPath));
          return;
        } catch (e) {
          if (kDebugMode) print("Lỗi phát file WAV 0.3B: $e");
        }
      }
    }

    await speak(message, onComplete: onComplete);
  }
}
