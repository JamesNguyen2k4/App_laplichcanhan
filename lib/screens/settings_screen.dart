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
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    final currentKey = StorageService.getGeminiApiKey();
    if (currentKey != null) {
      _apiKeyController.text = currentKey;
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    await StorageService.saveGeminiApiKey(key);
    setState(() {
      _isSaved = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu Gemini API Key thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _testTts() async {
    await TtsService.speak(
      "Xin chào! Đây là tính năng đọc thông báo và lời nhắc tiếng Việt của ứng dụng.",
    );
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

          // Mục 2: Kiểm tra Âm thanh & Text-To-Speech (TTS)
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
                        'Giọng đọc Tiếng Việt (TTS)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kiểm tra thử giọng đọc tiếng Việt của Google TTS trên điện thoại của bạn.',
                    style: TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _testTts,
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Thử nghe giọng đọc tiếng Việt'),
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

          const SizedBox(height: 16),

          // Mục 3: Hướng dẫn
          Card(
            elevation: 1,
            color: Colors.indigo.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '💡 Mẹo: Bạn có thể lấy API Key miễn phí tại https://aistudio.google.com/app/apikey. Key của bạn được lưu hoàn toàn trên điện thoại và không bị chia sẻ ra ngoài.',
                style: TextStyle(fontSize: 13, color: Colors.indigo, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
