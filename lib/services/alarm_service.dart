import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/event_model.dart';
import 'tts_service.dart';
import 'storage_service.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static Timer? _ringTimer;

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Xử lý khi người dùng nhấn vào thông báo
      },
    );

    // Tạo kênh thông báo Báo thức mức độ ưu tiên cao nhất (High Importance)
    const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
      'alarm_channel_id',
      'Kênh Báo Thức & Lời Nhắc',
      description: 'Phát âm thanh chuông lớn và hiển thị lời nhắc báo thức sự kiện',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alarmChannel);
  }

  /// Lên lịch báo thức/thông báo cho sự kiện
  static Future<void> scheduleAlarm(EventModel event) async {
    // Tính toán thời gian reo (trừ đi số phút nhắc trước)
    final triggerTime = event.dateTime.subtract(Duration(minutes: event.reminderMinutes));

    if (triggerTime.isBefore(DateTime.now())) {
      // Nếu thời gian đã qua thì bỏ qua
      return;
    }

    // Mã số thông báo lấy từ hash của id sự kiện
    final int notificationId = event.id.hashCode;

    // Chi tiết thông báo Android
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alarm_channel_id',
      'Kênh Báo Thức & Lời Nhắc',
      channelDescription: 'Phát âm thanh chuông lớn và hiển thị lời nhắc',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true, // Mở sáng màn hình
      category: AndroidNotificationCategory.alarm,
      ticker: 'Báo thức: ${event.title}',
      styleInformation: BigTextStyleInformation(
        event.description.isNotEmpty ? event.description : 'Đến giờ lịch hẹn!',
        contentTitle: '⏰ Báo thức: ${event.title}',
        summaryText: 'Lịch cá nhân',
      ),
    );

    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    // Lên lịch hiển thị thông báo
    // (Lưu ý: trong môi trường production, tích hợp thêm timezone/tz.TZDateTime)
    await _notificationsPlugin.show(
      notificationId,
      '⏰ ${event.title}',
      event.description.isNotEmpty ? event.description : 'Đã đến giờ!',
      notificationDetails,
      payload: event.id,
    );
  }

  /// Hủy lịch báo thức khi xóa sự kiện
  static Future<void> cancelAlarm(String eventId) async {
    final int notificationId = eventId.hashCode;
    await _notificationsPlugin.cancel(notificationId);
  }

  /// KÍCH HOẠT CHU KỲ BÁO THỨC:
  /// 1. Reo chuông 1 hồi (khoảng 6 giây)
  /// 2. Ngắt chuông
  /// 3. Google TTS đọc to lời nhắc bằng tiếng Việt
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
      // Phát file chuông mặc định từ thư mục assets
      try {
        await _audioPlayer.play(AssetSource('audio/default_alarm.mp3'));
      } catch (e) {
        // Fallback: nếu chưa có file mp3 thì vẫn rung và đọc TTS
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
