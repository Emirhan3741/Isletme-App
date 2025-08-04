import 'package:flutter/material.dart';
import '../common/unified_calendar_page.dart';

class PsychologyCalendarPage extends StatelessWidget {
  const PsychologyCalendarPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const UnifiedCalendarPage(
      allowedModules: ['psychology', 'custom'],
      title: 'Psikoloji Takvimi',
    );
  }
}