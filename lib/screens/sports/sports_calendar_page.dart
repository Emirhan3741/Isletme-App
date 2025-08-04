import 'package:flutter/material.dart';
import '../common/unified_calendar_page.dart';

class SportsCalendarPage extends StatelessWidget {
  const SportsCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnifiedCalendarPage(
      allowedModules: ['sports', 'custom'],
      title: 'Spor Takvimi',
    );
  }
}