import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/vieneu_03b_service.dart';
import '../services/vietnamese_g2p_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _testTextController = TextEditingController(
    text: 'Thông báo nhắc nhở: 14h30 họp dự án ngày 17/11/2026.',
  );

  bool _useVieNeuTts = true;
  bool _is03bModelReady = false;
  bool _isTestingTts = false;

  List<TtsVoiceOption> _voices = [];
  TtsVoiceOption? _selectedVoice;
  double _speechRate = 0.5;
  double _pitch = 1.0;

  @override
  void initState() {
    super.initState();
    final currentKey = StorageService.getGeminiApiKey();
    if (currentKey != null) {
      _apiKeyController.text = currentKey;
    }
    _useVieNeuTts = StorageService.getUseVieNeuTts();
    _speechRate = StorageService.getTtsSpeechRate();
    _pitch = StorageService.getTtsPitch();
    _loadVoiceAndModelStatus();
  }

  Future<void> _loadVoiceAndModelStatus() async {
    final ready = await VieNeu03bService.ensureModelsReady();
    await TtsService.init();
    final voices = await TtsService.getAvailableVoices();

    final savedName = StorageService.getTtsVoiceName();
    final savedLocale = StorageService.getTtsVoiceLocale();
    TtsVoiceOption? matched;
    if (savedName != null) {
      matched = voices.where((v) => v.name == savedName && v.locale == savedLocale).firstOrNull;
    }
    matched ??= voices.where((v) => v.locale.toLowerCase().startsWith('vi')).firstOrNull;
    matched ??= voices.firstOrNull;

    if (mounted) {
      setState(() {
        _is03bModelReady = ready;
        _voices = voices;
        _selectedVoice = matched;
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _testTextController.dispose();
    super.dispose();
  }

  void _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    await StorageService.saveGeminiApiKey(key);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu Gemini API Key thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _toggleVieNeu(bool val) async {
    setState(() => _useVieNeuTts = val);
    await StorageService.setUseVieNeuTts(val);
  }

  void _onVoiceChanged(TtsVoiceOption? voice) async {
    if (voice == null) return;
    setState(() => _selectedVoice = voice);
    await StorageService.saveTtsVoice(voice.name, voice.locale);
    await TtsService.applySavedVoiceSettings();
  }

  void _testOfflineTts() async {
    setState(() => _isTestingTts = true);
    final rawText = _testTextController.text.trim();
    await TtsService.speakEventReminder(
      'test_sample',
      rawText.isEmpty ? 'Kiểm tra giọng đọc báo thức' : rawText,
      '',
    );
    if (mounted) {
      setState(() => _isTestingTts = false);
    }
  }

  void _stopTts() async {
    await TtsService.stop();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedPreview = VietnameseG2pService.normalizeText(_testTextController.text);
    final hasVietnameseVoice = _voices.any((v) => v.locale.toLowerCase().startsWith('vi'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt & Cấu hình'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Mục 1: Cấu hình Gemini API Key
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.indigo, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Gemini AI API Key',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cung cấp API Key từ Google AI Studio để sử dụng tính năng tạo lịch tự động bằng giọng nói và văn bản tự nhiên.',
                    style: TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      labelText: 'Nhập API Key của bạn',
                      hintText: 'AIzaSy...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _apiKeyController.clear(),
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveApiKey,
                      icon: const Icon(Icons.save),
                      label: const Text('Lưu API Key'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Mục 2: Cấu hình Giọng đọc Tiếng Việt & VieNeu-TTS 0.3B Offline
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.record_voice_over, color: Colors.deepOrange, size: 28),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cấu hình Giọng đọc & TTS 0.3B',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _is03bModelReady ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _is03bModelReady ? Colors.green.shade200 : Colors.orange.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _is03bModelReady ? Icons.check_circle : Icons.info_outline,
                          color: _is03bModelReady ? Colors.green : Colors.orange.shade800,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _is03bModelReady
                                ? 'Đã sẵn sàng: VieNeu-TTS 0.3B GGUF & NeuCodec ONNX (Offline).'
                                : 'Chưa thấy file trọng số 0.3B trong assets/models/. Đang dùng giọng đọc Tiếng Việt của thiết bị.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: _is03bModelReady ? Colors.green.shade900 : Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ưu tiên VieNeu-TTS 0.3B Offline', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Dùng model AI 0.3B nếu đã nhúng vào APK'),
                    value: _useVieNeuTts,
                    activeThumbColor: Colors.deepOrange,
                    onChanged: _toggleVieNeu,
                  ),
                  const Divider(),

                  // Chọn giọng đọc hệ thống (ưu tiên Tiếng Việt)
                  const Text(
                    'Chọn giọng đọc Tiếng Việt (trên máy / trình duyệt):',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (_voices.isNotEmpty)
                    DropdownButtonFormField<TtsVoiceOption>(
                      initialValue: _selectedVoice,
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.voice_chat),
                      ),
                      items: _voices.map((v) {
                        final isVi = v.locale.toLowerCase().startsWith('vi');
                        return DropdownMenuItem(
                          value: v,
                          child: Text(
                            '${isVi ? "🇻🇳 " : ""}${v.name} (${v.locale})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _onVoiceChanged,
                    )
                  else
                    const Text(
                      'Không tải được danh sách giọng đọc từ thiết bị.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),

                  if (_voices.isNotEmpty && !hasVietnameseVoice)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '⚠️ Thiết bị/Trình duyệt hiện tại chưa cài gói giọng nói Tiếng Việt (vi-VN), nên hệ thống có thể đọc bằng giọng mặc định.',
                        style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 12),
                  // Tốc độ đọc
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tốc độ đọc:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${_speechRate.toStringAsFixed(2)}x'),
                    ],
                  ),
                  Slider(
                    value: _speechRate,
                    min: 0.2,
                    max: 1.0,
                    divisions: 16,
                    activeColor: Colors.deepOrange,
                    onChanged: (val) async {
                      setState(() => _speechRate = val);
                      await StorageService.saveTtsSpeechRate(val);
                    },
                  ),

                  // Cao độ giọng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cao độ giọng (Pitch):', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(_pitch.toStringAsFixed(2)),
                    ],
                  ),
                  Slider(
                    value: _pitch,
                    min: 0.5,
                    max: 1.5,
                    divisions: 10,
                    activeColor: Colors.deepOrange,
                    onChanged: (val) async {
                      setState(() => _pitch = val);
                      await StorageService.saveTtsPitch(val);
                    },
                  ),

                  const Divider(),
                  // Ô nhập thử nội dung và xem trước văn bản đã chuẩn hóa
                  TextField(
                    controller: _testTextController,
                    maxLines: 2,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Nội dung thử đọc',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Đầu vào đã chuẩn hóa cho model:\n"$normalizedPreview"',
                      style: const TextStyle(fontSize: 12, color: Colors.black87, fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTestingTts ? null : _testOfflineTts,
                          icon: _isTestingTts
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.volume_up),
                          label: const Text('Nghe thử'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: _stopTts,
                        icon: const Icon(Icons.stop),
                        label: const Text('Dừng'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
