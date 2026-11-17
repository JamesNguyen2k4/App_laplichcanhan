import 'package:flutter_test/flutter_test.dart';
import 'package:duan_len_lich_ca_nhan/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ScheduleAlarmApp());
    expect(find.byType(ScheduleAlarmApp), findsOneWidget);
  });
}
