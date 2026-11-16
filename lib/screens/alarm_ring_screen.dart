import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/alarm_service.dart';

class AlarmRingScreen extends StatefulWidget {
  final EventModel event;

  const AlarmRingScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Kích hoạt chu kỳ: Chuông 6s -> Ngắt -> Đọc tiếng Việt
    AlarmService.triggerAlarmCycle(widget.event);
  }

  @override
  void dispose() {
    _animController.dispose();
    AlarmService.stopAlarm();
    super.dispose();
  }

  void _dismissAlarm() async {
    await AlarmService.stopAlarm();
    if (mounted) Navigator.of(context).pop();
  }

  void _snoozeAlarm() async {
    await AlarmService.stopAlarm();
    // Báo lại sau 5 phút
    final snoozeEvent = widget.event.copyWith(
      dateTime: DateTime.now().add(const Duration(minutes: 5)),
      reminderMinutes: 0,
    );
    await AlarmService.scheduleAlarm(snoozeEvent);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Phần trên: Icon chuông nhấp nháy
              Column(
                children: [
                  ScaleTransition(
                    scale: Tween(begin: 1.0, end: 1.25).animate(_animController),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.alarm_on,
                        size: 80,
                        color: Colors.amberAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'ĐẾN GIỜ BÁO THỨC',
                    style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 2,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.event.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.event.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '📝 ${widget.event.description}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ],
              ),

              // Phần dưới: Nút Tắt và Nút Báo lại
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _dismissAlarm,
                      icon: const Icon(Icons.alarm_off, size: 28),
                      label: const Text('TẮT BÁO THỨC', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _snoozeAlarm,
                      icon: const Icon(Icons.snooze, color: Colors.white),
                      label: const Text('Báo lại sau 5 phút', style: TextStyle(fontSize: 16, color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
