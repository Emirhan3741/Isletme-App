import 'package:flutter/material.dart';
import '../common/unified_calendar_page.dart';

class ClinicCalendarPage extends StatelessWidget {
  const ClinicCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnifiedCalendarPage(
      allowedModules: ['clinic', 'custom'],
      title: 'Klinik Takvimi',
    );
  }
}