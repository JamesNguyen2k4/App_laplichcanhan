import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _vieneuUrlController = TextEditingController();
  bool _useVieNeuTts = false;
  bool _isTestingVieNeu = false;

  @override
  void initState() {
    super.initState();
    final currentKey = StorageService.getGeminiApiKey();
    if (currentKey != null) {
      _apiKeyController.text = currentKey;
    }

    final currentVieNeuUrl = StorageService.getVieNeuServerUrl();
    if (currentVieNeuUrl != null) {
      _vieneuUrlController.text = currentVieNeuUrl;
    }
    _useVieNeuTts = StorageService.getUseVieNeuTts();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _vieneuUrlController.dispose();
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

  void _saveVieNeuSettings() async {
    final url = _vieneuUrlController.text.trim();
    await StorageService.saveVieNeuServerUrl(url);
    await StorageService.setUseVieNeuTts(_useVieNeuTts);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu cấu hình VieNeu-TTS thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _testTts() async {
    await TtsService.speak(
      "Xin chào! Đây là tính năng đọc thông báo và lời nhắc tiếng Việt của Google TTS.",
    );
  }

  void _testVieNeuTts() async {
    final url = _vieneuUrlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập Server URL của VieNeu-TTS trước!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isTestingVieNeu = true);
    final success = await TtsService.playVieNeuTts(
      "Xin chào! Đây là giọng đọc nhân bản tiếng Việt siêu tự nhiên từ VieNeu-TTS.",
      url,
    );
    setState(() => _isTestingVieNeu = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Phát VieNeu-TTS thành công!' : 'Không thể kết nối đến VieNeu-TTS server'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Row(
                    children: const [
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

          // Mục 2: Cấu hình VieNeu-TTS (pnnbao97)
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.spatial_audio, color: Colors.deepOrange, size: 28),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'VieNeu-TTS AI (pnnbao97)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mô hình AI đọc văn bản tiếng Việt siêu tự nhiên và nhân bản giọng nói.',
                    style: TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ưu tiên sử dụng VieNeu-TTS', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Tự động phát giọng đọc VieNeu-TTS khi có kết nối server'),
                    value: _useVieNeuTts,
                    activeColor: Colors.deepOrange,
                    onChanged: (val) => setState(() => _useVieNeuTts = val),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _vieneuUrlController,
                    decoration: InputDecoration(
                      labelText: 'VieNeu-TTS Server URL',
                      hintText: 'Ví dụ: http://192.168.1.10:8000',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.dns),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveVieNeuSettings,
                          icon: const Icon(Icons.save),
                          label: const Text('Lưu cấu hình'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isTestingVieNeu ? null : _testVieNeuTts,
                          icon: _isTestingVieNeu
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.play_arrow),
                          label: const Text('Nghe thử'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.deepOrange,
                            side: const BorderSide(color: Colors.deepOrange),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Mục 3: Kiểm tra Google TTS mặc định
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.record_voice_over, color: Colors.indigo, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Google TTS (Dự phòng)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Giọng đọc offline mặc định có sẵn trên điện thoại Android.',
                    style: TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _testTts,
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Thử nghe Google TTS'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.indigo),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
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
