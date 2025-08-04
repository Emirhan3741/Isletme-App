import 'package:flutter/material.dart';

class AppConstants {
  // Uygulama temel bilgileri
  static const String appName = 'Randevu ERP';
  static const Color secondaryColor = Color(0xFF00BCD4);
  static const Color textMedium = Color(0xFF666666);
  
  // Collection isimleri - geçici placeholder'lar
  static const String lawyerTransactionsCollection = 'lawyer_transactions';
  static const String lawyerNotesCollection = 'lawyer_notes';
  static const String lawyerTodosCollection = 'lawyer_todos';
  static const String lawyerRemindersCollection = 'lawyer_reminders';
  static const String lawyerContractsCollection = 'lawyer_contracts';
  static const String sportsProgramsCollection = 'sports_programs';
  static const String sportsMembersCollection = 'sports_members';
  static const String sportsPaymentsCollection = 'sports_payments';
  static const String sportsExpensesCollection = 'sports_expenses';
  static const String educationStudentsCollection = 'education_students';
  static const String educationCoursesCollection = 'education_courses';
  static const String educationPaymentsCollection = 'education_payments';
  static const String educationExpensesCollection = 'education_expenses';
  static const String educationTeachersCollection = 'education_teachers';
  static const String educationSettingsCollection = 'education_settings';
  static const String psychologyClientsCollection = 'psychology_clients';
  static const String psychologyPaymentsCollection = 'psychology_payments';
  static const String psychologyExpensesCollection = 'psychology_expenses';
  static const String psychologyAppointmentsCollection = 'psychology_appointments';
  static const String veterinaryPatientsCollection = 'veterinary_patients';
  static const String veterinaryPaymentsCollection = 'veterinary_payments';
  static const String realEstateClientsCollection = 'real_estate_clients';
  static const String realEstatePaymentsCollection = 'real_estate_payments';
  static const String realEstateExpensesCollection = 'real_estate_expenses';
  static const String remindersCollection = 'reminders';
  static const String sportsNotesCollection = 'sports_notes';
  static const String customizationSettingsCollection = 'customization_settings';
  static const String clinicClientsCollection = 'clinic_clients';
  
  // Sayfalama için default değer
  static const int defaultPageSize = 20;
  
  // Çeşitli collections
  static const String usersCollection = 'users';
  static const String notificationsCollection = 'notifications';
  static const String settingsCollection = 'settings';
  static const String auditLogsCollection = 'audit_logs';
  static const String documentsCollection = 'documents';
  // App Version
  static const String appVersion = '1.0.0';

  // Basic Colors - SINGLE SOURCE OF TRUTH
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFFF5722);
  static const Color infoColor = Color(0xFF2196F3);
  static const Color warningColor = Color(0xFFFF9800);
  
  // Text Colors - UNIQUE DEFINITIONS
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color textDark = Color(0xFF000000);
  
  // Surface & Border Colors
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFE0E0E0);

  // Border Radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double radiusMedium = borderRadiusMedium; // Alias for backwards compatibility
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;
  
  // Elevation
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  
  // Padding & Margins
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Panel Colors
  static const Map<String, Color> panelColors = {
    'lawyer': Color(0xFF8B4513),
    'beauty': Color(0xFFE91E63),
    'veterinary': Color(0xFF4CAF50),
    'education': Color(0xFF9C27B0),
    'sports': Color(0xFFFF9800),
    'consulting': Color(0xFF607D8B),
    'real_estate': Color(0xFF795548),
  };

  // Animation Durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Common Collection Names - DUPLIKASYON KALDIRILDI
  static const String appointmentsCollection = 'appointments';
  static const String customersCollection = 'customers';
  static const String expensesCollection = 'expenses';
  static const String servicesCollection = 'services';
  static const String notesCollection = 'notes';
  static const String reportsCollection = 'reports';
  static const String employeesCollection = 'employees';
  static const String transactionsCollection = 'transactions';

  // Beauty Collections
  static const String beautyAppointmentsCollection = 'beauty_appointments';
  static const String beautyCustomersCollection = 'beauty_customers';
  static const String beautyEmployeesCollection = 'beauty_employees';
  static const String beautyServicesCollection = 'beauty_services';

  // Lawyer Collections
  static const String lawyerCasesCollection = 'lawyer_cases';
  static const String courtDatesCollection = 'court_dates';
  static const String lawyerHearingsCollection = 'lawyer_hearings';
  static const String lawyerClientsCollection = 'lawyer_clients';

  // Veterinary Collections
  static const String veterinaryAppointmentsCollection = 'veterinary_appointments';
  static const String veterinaryTreatmentsCollection = 'veterinary_treatments';
  static const String veterinaryVaccinationsCollection = 'veterinary_vaccinations';

  // Education Collections
  static const String educationAppointmentsCollection = 'education_appointments';
  static const String educationExamsCollection = 'education_exams';
  static const String educationGradesCollection = 'education_grades';

  // Sports Collections
  static const String sportsSessionsCollection = 'sports_sessions';
  static const String sportsAppointmentsCollection = 'sports_appointments';

  // Real Estate Collections
  static const String realEstateAppointmentsCollection = 'real_estate_appointments';
  static const String realEstatePropertiesCollection = 'real_estate_properties';

  // Clinic Collections
  static const String clinicPatientsCollection = 'clinic_patients';
  static const String clinicServicesCollection = 'clinic_services';
  static const String clinicEmployeesCollection = 'clinic_employees';
  static const String clinicDocumentsCollection = 'clinic_documents';
  static const String clinicNotesCollection = 'clinic_notes';
  static const String clinicPaymentsCollection = 'clinic_payments';
  static const String clinicExpensesCollection = 'clinic_expenses';
  static const String clinicAppointmentsCollection = 'clinic_appointments';
  static const String clinicTreatmentsCollection = 'clinic_treatments';

  // Psychology Collections
  static const String psychologyServicesCollection = 'psychology_services';
  static const String psychologySessionsCollection = 'psychology_sessions';

  // User Collections
  static const String userProfilesCollection = 'user_profiles';

  // Getter methods for backwards compatibility
  static double get borderRadius => borderRadiusMedium;
  static Color get textColor => textPrimary;
}