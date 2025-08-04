import 'package:flutter/material.dart';
import '../common/unified_calendar_page.dart';

class LawyerCalendarPage extends StatelessWidget {
  const LawyerCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnifiedCalendarPage(
      allowedModules: ['lawyer', 'custom'],
      title: 'Hukuk Takvimi',
    );
  }
}