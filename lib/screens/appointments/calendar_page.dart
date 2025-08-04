import 'package:flutter/material.dart';
import '../common/unified_calendar_page.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const UnifiedCalendarPage(
      // Tüm modülleri göster
      title: 'Genel Takvim',
    );
  }
}