import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/storage_service.dart';
import 'services/alarm_service.dart';
import 'services/tts_service.dart';
import 'screens/home_calendar_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo định dạng ngày giờ tiếng Việt
  await initializeDateFormatting('vi_VN', null);

  // Khởi tạo các dịch vụ nền tảng
  await StorageService.init();
  await AlarmService.init();
  await TtsService.init();

  runApp(const ScheduleAlarmApp());
}

class ScheduleAlarmApp extends StatelessWidget {
  const ScheduleAlarmApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lịch & Báo Thức AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo,
          secondary: Colors.deepOrange,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      // Cấu hình ngôn ngữ Tiếng Việt cho toàn bộ App
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('vi', 'VN'),
      home: const HomeCalendarScreen(),
    );
  }
}
