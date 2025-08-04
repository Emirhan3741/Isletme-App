import 'package:flutter/material.dart';
import '../common/unified_calendar_page.dart';

class BeautyCalendarPage extends StatelessWidget {
  const BeautyCalendarPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const UnifiedCalendarPage(
      allowedModules: ['beauty', 'custom'],
      title: 'Güzellik Salonu Takvimi',
    );
  }
}