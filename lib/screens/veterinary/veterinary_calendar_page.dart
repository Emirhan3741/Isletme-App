import 'package:flutter/material.dart';
import '../common/unified_calendar_page.dart';

class VeterinaryCalendarPage extends StatelessWidget {
  const VeterinaryCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnifiedCalendarPage(
      allowedModules: ['veterinary', 'custom'],
      title: 'Veteriner Takvimi',
    );
  }
}