import 'package:flutter/material.dart';
import '../common/unified_calendar_page.dart';

class EducationCalendarPage extends StatelessWidget {
  const EducationCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnifiedCalendarPage(
      allowedModules: ['education', 'custom'],
      title: 'Eğitim Takvimi',
    );
  }
}