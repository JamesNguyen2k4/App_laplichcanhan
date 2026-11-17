import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/stt_service.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../services/alarm_service.dart';
import '../services/tts_service.dart';

class AiAssistantDialog extends StatefulWidget {
  final Function() onEventAdded;

  const AiAssistantDialog({Key? key, required this.onEventAdded}) : super(key: key);

  @override
  State<AiAssistantDialog> createState() => _AiAssistantDialogState();
}

class _AiAssistantDialogState extends State<AiAssistantDialog> {
  final TextEditingController _inputController = TextEditingController();
  bool _isListening = false;
  bool _isLoading = false;
  EventModel? _parsedEvent;
  String? _errorMessage;

  @override
  void dispose() {
    _inputController.dispose();
    SttService.stopListening();
    super.dispose();
  }

  void _toggleListening() async {
    if (_isListening) {
      await SttService.stopListening();
      setState(() {
        _isListening = false;
      });
    } else {
      setState(() {
        _isListening = true;
        _errorMessage = null;
      });

      await SttService.startListening(
        onResult: (text) {
          setState(() {
            _inputController.text = text;
          });
        },
      );
    }
  }

  void _analyzeWithGemini() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nói hoặc nhập nội dung lịch hẹn!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _parsedEvent = null;
    });

    try {
      final event = await GeminiService.parseEventFromText(text);
      setState(() {
        _parsedEvent = event;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _saveEvent() async {
    if (_parsedEvent == null) return;

    // Lưu vào database
    await StorageService.addEvent(_parsedEvent!);

    // Kích hoạt báo thức nếu bật
    if (_parsedEvent!.isAlarmEnabled) {
      await AlarmService.scheduleAlarm(_parsedEvent!);
      // Tải và lưu sẵn giọng đọc VieNeu-TTS vào máy ngay khi tạo lịch
      TtsService.cacheEventAudio(
        _parsedEvent!.id,
        _parsedEvent!.title,
        _parsedEvent!.description,
      );
    }

    widget.onEventAdded();
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm lịch: ${_parsedEvent!.title}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tiêu đề
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.indigo, size: 28),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Trợ lý Gemini AI Lên Lịch',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Nhấn Mic để nói hoặc nhập văn bản tự nhiên (Ví dụ: "Sáng mai 8h đi họp với phòng kỹ thuật, nhắc trước 15p")',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Ô nhập liệu kèm nút Mic
            TextField(
              controller: _inputController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nói hoặc nhập lịch trình của bạn...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : Colors.indigo,
                    size: 30,
                  ),
                  onPressed: _toggleListening,
                ),
              ),
            ),

            if (_isListening)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '🎙 Đang lắng nghe tiếng Việt... Hãy nói nội dung lịch của bạn',
                  style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 12),

            // Nút phân tích
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _analyzeWithGemini,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.psychology),
              label: Text(_isLoading ? 'AI đang phân tích...' : 'Phân tích & Tách lịch'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            // Thẻ kết quả xem lại sau khi Gemini phân tích xong
            if (_parsedEvent != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _parsedEvent!.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Text(
                      '⏰ Thời gian: ${DateFormat('HH:mm - dd/MM/yyyy').format(_parsedEvent!.dateTime)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🔔 Nhắc trước: ${_parsedEvent!.reminderMinutes} phút',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🏷 Danh mục: ${_parsedEvent!.category}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (_parsedEvent!.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '📝 Lời nhắc TTS: "${_parsedEvent!.description}"',
                        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _saveEvent,
                icon: const Icon(Icons.check),
                label: const Text('Xác nhận & Lưu vào Lịch'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
