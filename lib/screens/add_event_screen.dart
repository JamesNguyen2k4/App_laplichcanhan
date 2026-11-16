import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';
import '../services/storage_service.dart';
import '../services/alarm_service.dart';

class AddEventScreen extends StatefulWidget {
  final DateTime initialDate;
  final EventModel? eventToEdit;

  const AddEventScreen({
    Key? key,
    required this.initialDate,
    this.eventToEdit,
  }) : super(key: key);

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  int _reminderMinutes = 15;
  bool _isAlarmEnabled = true;
  String _category = 'Công việc';

  final List<String> _categories = ['Công việc', 'Cá nhân', 'Họp', 'Khẩn cấp', 'Khác'];
  final List<int> _reminderOptions = [0, 5, 10, 15, 30, 60];

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      final e = widget.eventToEdit!;
      _titleController = TextEditingController(text: e.title);
      _descriptionController = TextEditingController(text: e.description);
      _selectedDate = e.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(e.dateTime);
      _reminderMinutes = e.reminderMinutes;
      _isAlarmEnabled = e.isAlarmEnabled;
      _category = e.category;
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedDate = widget.initialDate;
      _selectedTime = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final event = EventModel(
      id: widget.eventToEdit?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dateTime: finalDateTime,
      reminderMinutes: _reminderMinutes,
      isAlarmEnabled: _isAlarmEnabled,
      category: _category,
    );

    if (widget.eventToEdit != null) {
      await StorageService.updateEvent(event);
    } else {
      await StorageService.addEvent(event);
    }

    if (_isAlarmEnabled) {
      await AlarmService.scheduleAlarm(event);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.eventToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Chỉnh sửa Lịch hẹn' : 'Tạo Lịch hẹn mới'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Tiêu đề
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề sự kiện *',
                hintText: 'Ví dụ: Họp dự án, Đi khám sức khỏe...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event_note),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Vui lòng nhập tiêu đề sự kiện';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Lời nhắc / Ghi chú (dùng cho TTS đọc)
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Lời nhắc chi tiết (TTS sẽ đọc to câu này)',
                hintText: 'Ví dụ: Nhớ mang tài liệu kế toán và hợp đồng',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.record_voice_over),
              ),
            ),
            const SizedBox(height: 16),

            // Chọn Ngày & Giờ
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text('${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nhắc trước bao nhiêu phút
            DropdownButtonFormField<int>(
              value: _reminderMinutes,
              decoration: const InputDecoration(
                labelText: 'Thời gian nhắc trước',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notifications_active),
              ),
              items: _reminderOptions.map((min) {
                return DropdownMenuItem(
                  value: min,
                  child: Text(min == 0 ? 'Đúng giờ' : 'Trước $min phút'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _reminderMinutes = val);
              },
            ),
            const SizedBox(height: 16),

            // Danh mục
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Danh mục sự kiện',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
            const SizedBox(height: 16),

            // Bật / Tắt Báo thức & Giọng đọc
            SwitchListTile(
              title: const Text('Bật chuông báo thức & Đọc lời nhắc'),
              subtitle: const Text('Reo 1 hồi chuông và đọc to ghi chú bằng tiếng Việt'),
              value: _isAlarmEnabled,
              activeColor: Colors.indigo,
              onChanged: (val) {
                setState(() => _isAlarmEnabled = val);
              },
            ),
            const SizedBox(height: 24),

            // Nút Lưu
            ElevatedButton(
              onPressed: _saveEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                isEdit ? 'LƯU THAY ĐỔI' : 'TẠO LỊCH HẸN',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
