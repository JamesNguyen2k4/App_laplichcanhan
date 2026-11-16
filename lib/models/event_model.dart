import 'dart:convert';

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final int reminderMinutes; // Nhắc trước bao nhiêu phút (0 = đúng giờ)
  final bool isAlarmEnabled; // Bật chuông báo thức + giọng đọc TTS
  final String category;     // Công việc, Cá nhân, Họp, Khẩn cấp
  final bool isCompleted;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    this.reminderMinutes = 0,
    this.isAlarmEnabled = true,
    this.category = 'Công việc',
    this.isCompleted = false,
  });

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    int? reminderMinutes,
    bool? isAlarmEnabled,
    String? category,
    bool? isCompleted,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      isAlarmEnabled: isAlarmEnabled ?? this.isAlarmEnabled,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'reminderMinutes': reminderMinutes,
      'isAlarmEnabled': isAlarmEnabled,
      'category': category,
      'isCompleted': isCompleted,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      reminderMinutes: map['reminderMinutes']?.toInt() ?? 0,
      isAlarmEnabled: map['isAlarmEnabled'] ?? true,
      category: map['category'] ?? 'Công việc',
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory EventModel.fromJson(String source) => EventModel.fromMap(json.decode(source));
}
