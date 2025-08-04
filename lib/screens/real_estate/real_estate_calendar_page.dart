import 'package:flutter/material.dart';
import '../common/unified_calendar_page.dart';

class RealEstateCalendarPage extends StatelessWidget {
  const RealEstateCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnifiedCalendarPage(
      allowedModules: ['real_estate', 'custom'],
      title: 'Emlak Takvimi',
    );
  }
}