import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Firebase & Services
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/daily_summary_service.dart';
import 'services/automation_service.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/auth_provider_enhanced.dart';
import 'providers/currency_provider.dart';
import 'providers/document_provider.dart';
import 'providers/daily_schedule_provider.dart';
import 'screens/notifications/notifications_page.dart';
import 'providers/settings_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/ai_chat_provider.dart';

// Utils & L10n
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'utils/firestore_auto_fix.dart';

// Core & Models
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';

// Screens
import 'screens/auth_wrapper_simple.dart';
import 'screens/auth_wrapper_enhanced.dart';
import 'screens/auth/sector_selection_enhanced.dart';
import 'screens/landing/landing_page.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/register_page.dart';
import 'screens/auth/employee_register_page.dart';

// Widgets
import 'widgets/ai_support_chat_widget.dart';

// Beauty Salon Screens
import 'screens/beauty/beauty_dashboard_page.dart';
import 'screens/beauty/beauty_customer_list_page.dart';
import 'screens/beauty/beauty_appointment_page.dart';
import 'screens/beauty/beauty_calendar_page.dart';
import 'screens/beauty/beauty_service_page.dart';
import 'screens/beauty/beauty_transaction_page.dart';
import 'screens/beauty/beauty_expense_page.dart';
import 'screens/beauty/beauty_reports_page.dart';
import 'screens/beauty/beauty_employee_page.dart';
import 'screens/beauty/beauty_notes_todo_page.dart';

// Lawyer Screens
import 'screens/lawyer/lawyer_dashboard_page.dart';
import 'screens/lawyer/lawyer_clients_page.dart';
import 'screens/lawyer/lawyer_cases_page.dart';
import 'screens/lawyer/lawyer_calendar_page.dart';
import 'screens/lawyer/lawyer_transactions_page.dart';
import 'screens/lawyer/lawyer_documents_page.dart';
import 'screens/lawyer/lawyer_reports_page.dart';
import 'screens/lawyer/lawyer_notes_page.dart';
import 'screens/lawyer/add_edit_client_page.dart';

// Clinic Screens
import 'screens/dashboards/clinic_dashboard.dart';

// Sports Screens
import 'screens/dashboards/sports_dashboard.dart';
import 'screens/sports/sports_sessions_page.dart';
import 'screens/sports/sports_calendar_page.dart';
import 'screens/sports/sports_programs_page.dart';
import 'screens/sports/sports_members_page.dart';
import 'screens/sports/sports_payments_page.dart';
import 'screens/sports/sports_expenses_page.dart';
import 'screens/sports/sports_services_page.dart';
import 'screens/sports/sports_coaches_page.dart';
import 'screens/sports/sports_documents_page.dart';
import 'screens/sports/sports_reports_page.dart';

// Education Screens
import 'screens/education/education_dashboard_page.dart';
import 'screens/education/education_students_page.dart';
import 'screens/education/add_edit_student_page.dart';
import 'screens/education/education_courses_page.dart';
import 'screens/education/education_calendar_page.dart';
import 'screens/education/education_payments_page.dart';
import 'screens/education/education_reports_page.dart';
import 'screens/education/education_documents_page.dart';
import 'screens/education/education_settings_page.dart';
import 'screens/education/education_exams_page.dart';
import 'screens/education/education_attendance_page.dart';
import 'screens/education/education_teachers_page.dart';
import 'screens/education/education_grades_page.dart';

// Psychology Screens
import 'screens/psychology/psychology_dashboard_page.dart';
import 'screens/psychology/psychology_clients_page.dart';
import 'screens/psychology/psychology_sessions_page.dart';

// Veterinary Screens
import 'screens/veterinary/veterinary_dashboard_page.dart';
import 'screens/veterinary/veterinary_patients_page.dart';
import 'screens/veterinary/add_edit_patient_page.dart';
import 'screens/veterinary/patient_detail_page.dart';
import 'screens/veterinary/veterinary_appointments_page.dart';
import 'screens/veterinary/veterinary_treatments_page.dart';
import 'screens/veterinary/veterinary_vaccinations_page.dart';
import 'screens/veterinary/veterinary_payments_page.dart';
import 'screens/veterinary/veterinary_expenses_page.dart';
import 'screens/veterinary/veterinary_calendar_page.dart';
import 'screens/veterinary/veterinary_inventory_page.dart';
import 'screens/veterinary/veterinary_documents_page.dart';
import 'screens/veterinary/veterinary_notes_page.dart';
import 'screens/veterinary/veterinary_reports_page.dart';
import 'screens/veterinary/veterinary_settings_page.dart';
// Veterinary Model
import 'core/models/veterinary_patient_model.dart';

// Real Estate Screens
import 'screens/real_estate/real_estate_dashboard_page.dart';

// Admin Screens
import 'screens/admin/admin_documents_approval_page.dart';
import 'screens/admin/admin_ai_chat_tracking_page.dart';
import 'pages/public/home_page.dart';
import 'screens/settings/notification_settings_page.dart';
import 'screens/auth/sector_selection_page.dart';
import 'screens/real_estate/real_estate_properties_page.dart';
import 'screens/real_estate/real_estate_clients_page.dart';
import 'screens/real_estate/real_estate_appointments_page.dart';
import 'screens/real_estate/real_estate_contracts_page.dart';
import 'screens/real_estate/real_estate_payments_page.dart';
import 'screens/real_estate/real_estate_expenses_page.dart';
import 'screens/real_estate/real_estate_calendar_page.dart';
import 'screens/real_estate/real_estate_documents_page.dart';
import 'screens/real_estate/real_estate_notes_page.dart';
import 'screens/real_estate/real_estate_reports_page.dart';
import 'screens/real_estate/real_estate_settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) debugPrint('Firebase initialized successfully');
    
    // 🔍 Firestore Index Tanılaması - Debug modda çalışır
    if (kDebugMode) {
      Future.delayed(const Duration(seconds: 3), () async {
        try {
          final autoFix = FirestoreAutoFix();
          final diagnostics = await autoFix.runDiagnostics();
          autoFix.printDetailedReport(diagnostics);
          
          // Eğer index sorunları varsa kullanıcıya bildir
          final indexTests = diagnostics['indexTests'] as Map<String, bool>;
          final failedTests = indexTests.entries.where((e) => !e.value).toList();
          
          if (failedTests.isNotEmpty) {
            debugPrint('\n🚨 ACİL: Firestore index sorunları tespit edildi!');
            debugPrint('📋 ÇÖZÜM: FIRESTORE_INDEX_URLS.md dosyasını açın');
            debugPrint('🔧 VEYA: firebase_deploy.bat çalıştırın');
          }
        } catch (e) {
          debugPrint('🔍 Firestore tanılama hatası: $e');
        }
      });
    }
  } catch (e) {
    if (kDebugMode) debugPrint('Firebase initialization error: $e');
  }

  // Initialize locale data for formatting
  await initializeDateFormatting();

      // Initialize notification service
    await NotificationService.initialize();

    // Initialize daily summary service
    DailySummaryService().initialize();

    // Request FCM permission for web notifications (Firebase Messaging)
    if (kIsWeb) {
      try {
        final messaging = FirebaseMessaging.instance;
        
        // Web için VAPID key set et
        await messaging.getToken(vapidKey: DefaultFirebaseOptions.vapidKey);
        
        await messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        
        // Get FCM token for web
        final token = await messaging.getToken();
        if (kDebugMode) debugPrint('📲 FCM Token: $token');
      } catch (e) {
        if (kDebugMode) debugPrint('FCM initialization error: $e');
      }
    }

    // Initialize automation service
    await AutomationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AuthProviderEnhanced()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => DailyScheduleProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => AIChatProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            navigatorKey: NotificationService.navigatorKey,

            // Localization Configuration
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: LocaleProvider.supportedLocales,
            locale: localeProvider.locale,

            // RTL Support
            builder: (context, child) {
              return Directionality(
                textDirection: localeProvider.isRTL
                    ? ui.TextDirection.rtl
                    : ui.TextDirection.ltr,
                child: child!,
              );
            },

            theme: AppTheme.lightTheme,
            routes: {
              '/': (context) => const AuthWrapperEnhanced(),
              '/auth-simple': (context) => const AuthWrapperSimple(),
              '/sector-selection': (context) => const SectorSelectionEnhanced(),
              '/landing': (context) => const LandingPage(),
              '/login': (context) => const LoginPage(),
              '/register': (context) => const RegisterPage(),
              '/auth-gate': (context) => const AuthWrapperEnhanced(),
              // Beauty Salon Routes
              '/beauty-dashboard': (context) => const BeautyDashboardPage(),
              '/beauty-customers': (context) => const BeautyCustomerListPage(),
              '/beauty-appointments': (context) =>
                  const BeautyAppointmentPage(),
              '/beauty-calendar': (context) => const BeautyCalendarPage(),
              '/beauty-services': (context) => const BeautyServicePage(),
              '/beauty-transactions': (context) =>
                  const BeautyTransactionPage(),
              '/beauty-expenses': (context) => const BeautyExpensePage(),
              '/beauty-reports': (context) => const BeautyReportsPage(),
              '/beauty-employees': (context) => const BeautyEmployeePage(),
              '/beauty-notes': (context) => const BeautyNotesTodoPage(),
              // Lawyer Routes
              '/lawyer-dashboard': (context) => const LawyerDashboardPage(),
              '/lawyer-clients': (context) => const LawyerClientsPage(),
              '/lawyer-add-client': (context) => const AddEditClientPage(),
              '/lawyer-cases': (context) => const LawyerCasesPage(),
              '/lawyer-calendar': (context) => const LawyerCalendarPage(),
              '/lawyer-transactions': (context) =>
                  const LawyerTransactionsPage(),
              '/lawyer-documents': (context) => const LawyerDocumentsPage(clientId: ''),
              '/lawyer-reports': (context) => const LawyerReportsPage(),
              '/lawyer-notes': (context) => const LawyerNotesPage(),
              // Clinic Routes
              '/clinic-dashboard': (context) => const ClinicDashboard(),
              // Sports Routes
              '/sports-dashboard': (context) => const SportsDashboard(),
              '/sports-sessions': (context) => const SportsSessionsPage(),
              '/sports-calendar': (context) => const SportsCalendarPage(),
              '/sports-programs': (context) => const SportsProgramsPage(),
              '/sports-members': (context) => const SportsMembersPage(),
              '/sports-payments': (context) => const SportsPaymentsPage(),
              '/sports-expenses': (context) => const SportsExpensesPage(),
              '/sports-services': (context) => const SportsServicesPage(),
              '/sports-coaches': (context) => const SportsCoachesPage(),
              '/sports-documents': (context) => const SportsDocumentsPage(customerId: ''),
              '/sports-reports': (context) => const SportsReportsPage(),
              // Education Routes
              '/education-dashboard': (context) =>
                  const EducationDashboardPage(),
              '/education-students': (context) => const EducationStudentsPage(),
              '/education-add-student': (context) => const AddEditStudentPage(),
              '/education-courses': (context) => const EducationCoursesPage(),
              '/education-calendar': (context) => const EducationCalendarPage(),
              '/education-payments': (context) => const EducationPaymentsPage(),
              '/education-reports': (context) => const EducationReportsPage(),
              '/education-documents': (context) =>
                  const EducationDocumentsPage(customerId: ''),
              '/education-settings': (context) => const EducationSettingsPage(),
              '/education-exams': (context) => const EducationExamsPage(),
              '/education-attendance': (context) =>
                  const EducationAttendancePage(),
              '/education-teachers': (context) => const EducationTeachersPage(),
              '/education-grades': (context) => const EducationGradesPage(),
              // Psychology Routes
              '/psychology-dashboard': (context) =>
                  const PsychologyDashboardPage(),
              '/psychology-clients': (context) => const PsychologyClientsPage(),
              '/psychology-sessions': (context) =>
                  const PsychologySessionsPage(),
              // Veterinary Routes
              '/veterinary-dashboard': (context) =>
                  const VeterinaryDashboardPage(),
              '/veterinary-patients': (context) =>
                  const VeterinaryPatientsPage(),
              '/veterinary-add-patient': (context) =>
                  const AddEditPatientPage(),
              // '/veterinary-patient-detail': Argüman gerektirdiği için onGenerateRoute'da işlenecek
              '/veterinary-appointments': (context) =>
                  const VeterinaryAppointmentsPage(),
              '/veterinary-treatments': (context) =>
                  const VeterinaryTreatmentsPage(),
              '/veterinary-vaccinations': (context) =>
                  const VeterinaryVaccinationsPage(),
              '/veterinary-payments': (context) =>
                  const VeterinaryPaymentsPage(),
              '/veterinary-expenses': (context) =>
                  const VeterinaryExpensesPage(),
              '/veterinary-calendar': (context) =>
                  const VeterinaryCalendarPage(),
              '/veterinary-inventory': (context) =>
                  const VeterinaryInventoryPage(),
              '/veterinary-documents': (context) =>
                  const VeterinaryDocumentsPage(customerId: ''),
              '/veterinary-notes': (context) => const VeterinaryNotesPage(),
              '/veterinary-reports': (context) => const VeterinaryReportsPage(),
              '/veterinary-settings': (context) =>
                  const VeterinarySettingsPage(),
              // Real Estate Routes
              '/real-estate-dashboard': (context) =>
                  const RealEstateDashboardPage(),
              '/real-estate-properties': (context) =>
                  const RealEstatePropertiesPage(),
              '/real-estate-clients': (context) =>
                  const RealEstateClientsPage(),
              '/real-estate-appointments': (context) =>
                  const RealEstateAppointmentsPage(),
              '/real-estate-contracts': (context) =>
                  const RealEstateContractsPage(),
              '/real-estate-payments': (context) =>
                  const RealEstatePaymentsPage(),
              '/real-estate-expenses': (context) =>
                  const RealEstateExpensesPage(),
              '/real-estate-calendar': (context) =>
                  const RealEstateCalendarPage(),
              '/real-estate-documents': (context) =>
                  const RealEstateDocumentsPage(customerId: ''),
              '/real-estate-notes': (context) => const RealEstateNotesPage(),
              '/real-estate-reports': (context) =>
                  const RealEstateReportsPage(),
              '/real-estate-settings': (context) =>
                  const RealEstateSettingsPage(),
              // Notifications Route
              '/notifications': (context) => const NotificationsPage(),
              // Admin Routes
              '/admin-documents': (context) => const AdminDocumentsApprovalPage(),
              '/admin-ai-chat': (context) => const AdminAIChatTrackingPage(),
        
        // 🏠 Public/Marketing Sayfaları
        '/public/home': (context) => const PublicHomePage(),
              '/notification-settings': (context) => const NotificationSettingsPage(),
              '/sector-selection': (context) => const SectorSelectionPage(),
            },
            // Parametre gerektiren route'lar için
            onGenerateRoute: (settings) {
              final uri = Uri.parse(settings.name ?? '');

              // Employee registration with invite code
              if (uri.path == '/register' &&
                  uri.queryParameters.containsKey('code')) {
                final role = uri.queryParameters['role'];
                final code = uri.queryParameters['code'];

                if (role == 'employee' && code != null && code.isNotEmpty) {
                  return MaterialPageRoute(
                    builder: (context) => EmployeeRegisterPage(code: code),
                  );
                }
              }

              // Veterinary patient detail
              if (settings.name == '/veterinary-patient-detail') {
                final patient = settings.arguments as VeterinaryPatient?;
                if (patient != null) {
                  return MaterialPageRoute(
                    builder: (context) => PatientDetailPage(patient: patient),
                  );
                }
              }
              return null; // Route bulunamadı
            },
            // Route bulunamadığında
            onUnknownRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const LandingPage(),
              );
            },
          ); // MaterialApp kapanışı
        }, // Consumer builder kapanışı
      ), // Consumer kapanışı
    ); // MultiProvider kapanışı
  }
}

