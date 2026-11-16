import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/storage_service.dart';
import '../services/alarm_service.dart';
import 'add_event_screen.dart';
import 'ai_assistant_dialog.dart';
import 'settings_screen.dart';
import 'alarm_ring_screen.dart';

class HomeCalendarScreen extends StatefulWidget {
  const HomeCalendarScreen({Key? key}) : super(key: key);

  @override
  State<HomeCalendarScreen> createState() => _HomeCalendarScreenState();
}

class _HomeCalendarScreenState extends State<HomeCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<EventModel> _allEvents = [];
  List<EventModel> _selectedEvents = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    final events = StorageService.getEvents();
    setState(() {
      _allEvents = events;
      _selectedEvents = _getEventsForDay(_selectedDay);
    });
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    return _allEvents.where((e) {
      return isSameDay(e.dateTime, day);
    }).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents = _getEventsForDay(selectedDay);
      });
    }
  }

  void _deleteEvent(EventModel event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa lịch hẹn "${event.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.deleteEvent(event.id);
      await AlarmService.cancelAlarm(event.id);
      _loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa lịch hẹn')),
        );
      }
    }
  }

  void _openAiAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiAssistantDialog(
        onEventAdded: _loadEvents,
      ),
    );
  }

  void _openAddEvent() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddEventScreen(initialDate: _selectedDay),
      ),
    );
    if (result == true) {
      _loadEvents();
    }
  }

  void _openEditEvent(EventModel event) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddEventScreen(
          initialDate: event.dateTime,
          eventToEdit: event,
        ),
      ),
    );
    if (result == true) {
      _loadEvents();
    }
  }

  void _testAlarmScreen(EventModel event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AlarmRingScreen(event: event),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Khẩn cấp':
        return Colors.red;
      case 'Họp':
        return Colors.orange;
      case 'Cá nhân':
        return Colors.green;
      case 'Công việc':
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, dd/MM/yyyy', 'vi').format(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch Cá Nhân & Báo Thức',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // Nút nhảy về ngày Hôm nay
          IconButton(
            tooltip: 'Hôm nay',
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
                _selectedEvents = _getEventsForDay(_selectedDay);
              });
            },
          ),
          // Nút Cài đặt (API Key, Âm thanh)
          IconButton(
            tooltip: 'Cài đặt',
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. GIAO DIỆN LỊCH THÁNG
          Card(
            margin: const EdgeInsets.all(8.0),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: TableCalendar<EventModel>(
              locale: 'vi_VN',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              eventLoader: _getEventsForDay,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: Colors.indigo,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.indigo.shade200,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.deepOrange,
                  shape: BoxShape.circle,
                ),
              ),
              onDaySelected: _onDaySelected,
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),

          // 2. THANH TIÊU ĐỀ NGÀY ĐANG CHỌN
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
                Text(
                  '${_selectedEvents.length} lịch hẹn',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),

          // 3. DANH SÁCH SỰ KIỆN TRONG NGÀY
          Expanded(
            child: _selectedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.event_available, size: 54, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'Chưa có lịch hẹn nào trong ngày này',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    itemCount: _selectedEvents.length,
                    itemBuilder: (ctx, index) {
                      final event = _selectedEvents[index];
                      final timeStr = DateFormat('HH:mm').format(event.dateTime);
                      final catColor = _getCategoryColor(event.category);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: catColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  event.category,
                                  style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            event.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (event.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  event.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (event.isAlarmEnabled) ...[
                                    const Icon(Icons.alarm, size: 14, color: Colors.deepOrange),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Báo thức & Đọc TTS',
                                      style: TextStyle(fontSize: 11, color: Colors.deepOrange.shade800),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (event.reminderMinutes > 0)
                                    Text(
                                      'Nhắc trước ${event.reminderMinutes}p',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'test_alarm') {
                                _testAlarmScreen(event);
                              } else if (value == 'edit') {
                                _openEditEvent(event);
                              } else if (value == 'delete') {
                                _deleteEvent(event);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'test_alarm',
                                child: Row(
                                  children: [
                                    Icon(Icons.play_circle_fill, color: Colors.indigo, size: 20),
                                    SizedBox(width: 8),
                                    Text('Thử Chuông & Đọc TTS'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: Colors.blue, size: 20),
                                    SizedBox(width: 8),
                                    Text('Chỉnh sửa'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red, size: 20),
                                    SizedBox(width: 8),
                                    Text('Xóa lịch'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // 4. HAI NÚT BẤM NHANH (GEMINI AI TRỢ LÝ + TẠO THỦ CÔNG)
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Nút Trợ lý Gemini AI (Mic / Giọng nói / Text tự nhiên)
          FloatingActionButton.extended(
            heroTag: 'gemini_ai_fab',
            onPressed: _openAiAssistant,
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.mic, size: 22),
            label: const Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: Colors.amberAccent),
                SizedBox(width: 6),
                Text('AI Lên Lịch'),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Nút tạo thủ công (+)
          FloatingActionButton(
            heroTag: 'add_manual_fab',
            onPressed: _openAddEvent,
            backgroundColor: Colors.white,
            foregroundColor: Colors.indigo,
            child: const Icon(Icons.add, size: 28),
          ),
        ],
      ),
    );
  }
}
