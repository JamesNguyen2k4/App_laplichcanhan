import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';
import 'storage_service.dart';

class GeminiService {
  /// Phân tích đoạn text (từ giọng nói hoặc gõ phím) thành cấu trúc EventModel
  static Future<EventModel?> parseEventFromText(String naturalInputText) async {
    final apiKey = StorageService.getGeminiApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Vui lòng vào phần Cài đặt và nhập Gemini API Key trước khi sử dụng tính năng này.');
    }

    final now = DateTime.now();
    final formattedNow = DateFormat('yyyy-MM-dd HH:mm (EEEE)', 'vi').format(now);

    // Xây dựng System Prompt phân tích ngữ cảnh thời gian chính xác
    final prompt = '''
Bạn là trợ lý thông minh hỗ trợ lên lịch cá nhân.
Thời điểm hiện tại trên máy người dùng là: $formattedNow.

Nhiệm vụ: Phân tích đoạn yêu cầu/lời nói tự nhiên sau đây của người dùng và trích xuất thành định dạng JSON chuẩn.
Đoạn người dùng nói: "$naturalInputText"

Yêu cầu định dạng JSON trả về CHỈ DUY NHẤT một chuỗi JSON hợp lệ (không kèm Markdown ```json, không giải thích gì thêm) theo mẫu:
{
  "title": "Tiêu đề ngắn gọn của sự kiện",
  "description": "Chi tiết lời nhắc để đọc bằng giọng nói khi báo thức",
  "date_time": "YYYY-MM-DDTHH:mm:ss",
  "reminder_minutes": 15,
  "is_alarm_enabled": true,
  "category": "Công việc"
}

Quy tắc thời gian:
- Nếu người dùng nói "sáng mai", hãy cộng 1 ngày từ hôm nay và chọn giờ tương ứng.
- Nếu người dùng không nói giờ cụ thể, mặc định là 09:00 sáng.
- "category" chọn 1 trong các giá trị: "Công việc", "Cá nhân", "Họp", "Khẩn cấp".
- "reminder_minutes": số phút nhắc trước (0, 5, 10, 15, 30, 60). Nếu không nói, mặc định 15.
''';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.2, // Giảm temperature để kết quả JSON chuẩn xác nhất
          "responseMimeType": "application/json"
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi gọi Gemini API (${response.statusCode}): ${response.body}');
    }

    final data = json.decode(response.body);
    final String candidateText =
        data['candidates'][0]['content']['parts'][0]['text'];

    // Làm sạch chuỗi JSON nếu có bao bọc markdown
    String cleanJson = candidateText.trim();
    if (cleanJson.startsWith('```json')) {
      cleanJson = cleanJson.substring(7);
    }
    if (cleanJson.startsWith('```')) {
      cleanJson = cleanJson.substring(3);
    }
    if (cleanJson.endsWith('```')) {
      cleanJson = cleanJson.substring(0, cleanJson.length - 3);
    }
    cleanJson = cleanJson.trim();

    final parsedMap = json.decode(cleanJson);

    return EventModel(
      id: const Uuid().v4(),
      title: parsedMap['title'] ?? 'Sự kiện mới',
      description: parsedMap['description'] ?? '',
      dateTime: DateTime.tryParse(parsedMap['date_time'] ?? '') ?? now.add(const Duration(hours: 1)),
      reminderMinutes: parsedMap['reminder_minutes']?.toInt() ?? 15,
      isAlarmEnabled: parsedMap['is_alarm_enabled'] ?? true,
      category: parsedMap['category'] ?? 'Công việc',
    );
  }
}
