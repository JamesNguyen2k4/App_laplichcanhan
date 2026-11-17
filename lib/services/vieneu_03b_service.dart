import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'vietnamese_g2p_service.dart';

/// Dịch vụ chạy mô hình VieNeu-TTS 0.3B GGUF + NeuCodec ONNX 100% Offline trên Android.
class VieNeu03bService {
  static const MethodChannel _channel =
      MethodChannel('com.example.duan_len_lich_ca_nhan/vieneu_tts');

  static const String ggufFileName = 'VieNeu-TTS-0.3B-Q4_K_M.gguf';
  static const String codecFileName = 'neucodec_decoder_int8.onnx';

  static String? _ggufLocalPath;
  static String? _codecLocalPath;

  /// Chuẩn bị và kiểm tra xem 2 file trọng số 0.3B (.gguf & .onnx) đã sẵn sàng chưa.
  /// Nếu file được đóng gói trong `assets/models/`, tự động giải nén ra bộ nhớ trong.
  static Future<bool> ensureModelsReady() async {
    if (kIsWeb) return false;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final modelDir = Directory('${dir.path}/vieneu_03b_models');
      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }

      final ggufFile = File('${modelDir.path}/$ggufFileName');
      final codecFile = File('${modelDir.path}/$codecFileName');

      if (!await ggufFile.exists()) {
        await _copyAssetIfExists('assets/models/$ggufFileName', ggufFile);
      }
      if (!await codecFile.exists()) {
        await _copyAssetIfExists('assets/models/$codecFileName', codecFile);
      }

      if (await ggufFile.exists() && await codecFile.exists()) {
        _ggufLocalPath = ggufFile.path;
        _codecLocalPath = codecFile.path;
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('Lỗi chuẩn bị model 0.3B: $e');
    }
    return false;
  }

  static Future<void> _copyAssetIfExists(String assetPath, File targetFile) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      await targetFile.writeAsBytes(
        byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        flush: true,
      );
    } catch (_) {
      // Asset chưa được đóng gói trong APK -> bỏ qua, sẽ fallback sang Google TTS
    }
  }

  /// Xây dựng Prompt chuẩn theo `VieNeu-TTS/src/vieneu/standard.py` (_infer_ggml)
  static String buildGgufPrompt(
    String text, {
    String refPhonemes = '',
    List<int> refCodes = const [],
    String emotionTag = '<|emotion_0|>',
  }) {
    final chunkPhonemes = VietnameseG2pService.phonemize(text);
    final codesStr = refCodes.map((id) => '<|speech_$id|>').join();
    final fullPhonemes = refPhonemes.isEmpty ? chunkPhonemes : '$refPhonemes $chunkPhonemes';

    return '<|TEXT_PROMPT_START|>$emotionTag$fullPhonemes'
        '<|TEXT_PROMPT_END|><|SPEECH_GENERATION_START|>$codesStr';
  }

  /// Trích xuất danh sách speech token IDs từ chuỗi đầu ra của GGUF backbone
  static List<int> extractSpeechIds(String rawOutput) {
    final regex = RegExp(r'<\|speech_(\d+)\|>');
    return regex
        .allMatches(rawOutput)
        .map((m) => int.parse(m.group(1)!))
        .toList();
  }

  /// Giải mã mảng speech codes thành file WAV 24kHz bằng NeuCodec ONNX Runtime trên Android
  static Future<String?> decodeSpeechCodesToWav(
    List<int> speechIds,
    String outputWavPath,
  ) async {
    if (kIsWeb || speechIds.isEmpty) return null;
    final ready = await ensureModelsReady();
    if (!ready || _codecLocalPath == null) return null;

    try {
      final String? resultPath = await _channel.invokeMethod<String>(
        'decodeNeuCodec',
        {
          'codes': speechIds,
          'modelPath': _codecLocalPath!,
          'outputPath': outputWavPath,
        },
      );
      return resultPath;
    } on PlatformException catch (e) {
      if (kDebugMode) print('Lỗi gọi NeuCodec native: ${e.message}');
      return null;
    }
  }

  /// Tổng hợp văn bản thành file WAV offline cho sự kiện (nếu model 0.3B đã sẵn sàng).
  /// Trả về đường dẫn file .wav hoặc null nếu chưa có file trọng số trong assets/models/.
  static Future<String?> synthesizeToWav(String text, String outputWavPath) async {
    final ready = await ensureModelsReady();
    if (!ready || _ggufLocalPath == null || _codecLocalPath == null) {
      return null;
    }

    // 1. Tạo prompt IPA chuẩn hóa cho GGUF 0.3B
    final prompt = buildGgufPrompt(text);

    // 2. Gọi GGUF backbone trên native để sinh `<|speech_X|>` tokens
    try {
      final String? rawTokens = await _channel.invokeMethod<String>(
        'generateSpeechTokens',
        {
          'modelPath': _ggufLocalPath!,
          'prompt': prompt,
          'maxTokens': 1024,
          'temperature': 1.0,
          'topK': 50,
        },
      );
      if (rawTokens == null || rawTokens.isEmpty) return null;

      final speechIds = extractSpeechIds(rawTokens);
      if (speechIds.isEmpty) return null;

      // 3. Giải mã speechIds qua NeuCodec ONNX -> file WAV 24kHz
      return await decodeSpeechCodesToWav(speechIds, outputWavPath);
    } on MissingPluginException {
      // Backbone GGUF native library (libllama.so) chưa được biên dịch vào NDK
      return null;
    } catch (e) {
      if (kDebugMode) print('Lỗi tổng hợp VieNeu 0.3B: $e');
      return null;
    }
  }
}
