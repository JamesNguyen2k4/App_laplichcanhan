import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/event_model.dart';
import '../screens/alarm_ring_screen.dart';
import 'tts_service.dart';
import 'storage_service.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static Timer? _ringTimer;

  /// Global navigator key để có thể mở màn hình Báo thức từ bất kỳ đâu
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Khởi tạo hệ thống thông báo, timezone và xử lý payload khi mở app
  static Future<void> init() async {
    // 1. Khởi tạo cơ sở dữ liệu múi giờ
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    } catch (_) {
      // Dùng múi giờ mặc định của thiết bị nếu không tìm thấy chuỗi định danh
    }

    // 2. Cấu hình icon thông báo Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _handleAlarmPayload(payload);
        }
      },
    );

    // 3. Tạo kênh thông báo Báo thức mức độ ưu tiên cao nhất (High Importance / Alarm)
    const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
      'alarm_channel_id',
      'Kênh Báo Thức & Lời Nhắc',
      description: 'Phát âm thanh chuông lớn và hiển thị lời nhắc báo thức sự kiện',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(alarmChannel);

    // 4. Xin quyền thông báo (Android 13+) & quyền báo thức chính xác (Android 12+)
    await requestPermissions();

    // 5. Kiểm tra xem app có được khởi động từ việc bấm vào thông báo không
    final launchDetails = await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      final payload = launchDetails.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 600), () {
          _handleAlarmPayload(payload);
        });
      }
    }
  }

  /// Xin cấp quyền Android 13/14+ để thông báo và báo thức hoạt động chính xác
  static Future<void> requestPermissions() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  /// Lên lịch báo thức/thông báo chuẩn xác từng giây (kể cả khi tắt app / màn hình khóa)
  static Future<void> scheduleAlarm(EventModel event) async {
    if (!event.isAlarmEnabled) return;

    // Tính toán thời gian reo (trừ đi số phút nhắc trước)
    final triggerTime = event.dateTime.subtract(Duration(minutes: event.reminderMinutes));

    if (triggerTime.isBefore(DateTime.now())) {
      // Nếu thời gian đã trôi qua thì không lên lịch
      return;
    }

    final int notificationId = event.id.hashCode;

    // Chi tiết thông báo Android hỗ trợ Full Screen Intent
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alarm_channel_id',
      'Kênh Báo Thức & Lời Nhắc',
      channelDescription: 'Phát âm thanh chuông lớn và hiển thị lời nhắc',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true, // Sáng màn hình khóa và hiện giao diện báo thức
      category: AndroidNotificationCategory.alarm,
      ticker: 'Báo thức: ${event.title}',
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      styleInformation: BigTextStyleInformation(
        event.description.isNotEmpty ? event.description : 'Đến giờ lịch hẹn: ${event.title}',
        contentTitle: '⏰ Báo thức: ${event.title}',
        summaryText: 'Lịch cá nhân',
      ),
    );

    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    final tz.TZDateTime tzTriggerTime = tz.TZDateTime.from(triggerTime, tz.local);

    // Dùng zonedSchedule với exactAllowWhileIdle để Android AlarmManager đánh thức CPU chính xác từng giây
    await _notificationsPlugin.zonedSchedule(
      notificationId,
      '⏰ ${event.title}',
      event.description.isNotEmpty ? event.description : 'Đã đến giờ!',
      tzTriggerTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: event.id,
    );
  }

  /// Hủy lịch báo thức khi xóa hoặc sửa sự kiện
  static Future<void> cancelAlarm(String eventId) async {
    final int notificationId = eventId.hashCode;
    await _notificationsPlugin.cancel(notificationId);
  }

  /// Xử lý payload khi người dùng bấm vào notification để mở AlarmRingScreen
  static void _handleAlarmPayload(String eventId) {
    final event = StorageService.getEventById(eventId);
    if (event != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => AlarmRingScreen(event: event),
        ),
      );
    }
  }

  /// KÍCH HOẠT CHU KỲ BÁO THỨC:
  /// 1. Reo chuông 1 hồi (khoảng 6 giây)
  /// 2. Ngắt chuông
  /// 3. VieNeu-TTS / Google TTS đọc to lời nhắc bằng tiếng Việt chuẩn
  static Future<void> triggerAlarmCycle(EventModel event, {int ringDurationSeconds = 6}) async {
    try {
      // 1. Bắt đầu phát chuông
      await _playAlarmSound();

      // 2. Đặt thời gian ngắt 1 hồi chuông
      _ringTimer?.cancel();
      _ringTimer = Timer(Duration(seconds: ringDurationSeconds), () async {
        // Ngắt âm thanh chuông
        await _audioPlayer.stop();

        // 3. Kích hoạt giọng nói tiếng Việt đọc to lời nhắc
        await TtsService.speakEventReminder(
          event.id,
          event.title,
          event.description,
          onComplete: () {
            // Khi đọc xong, có thể tiếp tục xử lý hoặc chờ người dùng tắt
          },
        );
      });
    } catch (e) {
      // ignore: avoid_print
      print("Lỗi kích hoạt chuông: $e");
    }
  }

  /// Phát âm thanh chuông
  static Future<void> _playAlarmSound() async {
    final customRingtone = StorageService.getCustomRingtone();
    if (customRingtone != null && customRingtone.isNotEmpty) {
      await _audioPlayer.play(DeviceFileSource(customRingtone));
    } else {
      // Kiểm tra file chuông mặc định có tồn tại trong assets chưa trước khi phát
      try {
        await rootBundle.load('assets/audio/default_alarm.mp3');
        await _audioPlayer.play(AssetSource('audio/default_alarm.mp3'));
      } catch (_) {
        // Chưa chép file default_alarm.mp3 vào assets/audio/ -> bỏ qua chuông, vẫn chạy đếm giờ đọc TTS
      }
    }
  }

  /// Tắt toàn bộ chuông và giọng đọc (khi bấm Tắt trên màn hình)
  static Future<void> stopAlarm() async {
    _ringTimer?.cancel();
    await _audioPlayer.stop();
    await TtsService.stop();
  }
}
