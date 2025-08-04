import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_constants.dart';
import '../models/calendar_event_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Tüm modüllerden takvim verilerini çeken birleşik servis
class UnifiedCalendarService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Belirtilen tarih aralığında tüm etkinlikleri getir
  static Stream<List<CalendarEvent>> getCalendarEvents({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? modules,
    List<String>? eventTypes,
  }) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    // Varsayılan tarih aralığı (son 3 ay - gelecek 6 ay)
    startDate ??= DateTime.now().subtract(const Duration(days: 90));
    endDate ??= DateTime.now().add(const Duration(days: 180));

    // Tüm veri akışlarını birleştir
    final streams = <Stream<List<CalendarEvent>>>[];

    // Beauty Salon Module
    if (modules == null || modules.contains('beauty')) {
      streams.add(_getBeautyEvents(user.uid, startDate, endDate));
    }

    // Psychology Module
    if (modules == null || modules.contains('psychology')) {
      streams.add(_getPsychologyEvents(user.uid, startDate, endDate));
    }

    // Lawyer Module
    if (modules == null || modules.contains('lawyer')) {
      streams.add(_getLawyerEvents(user.uid, startDate, endDate));
    }

    // Veterinary Module
    if (modules == null || modules.contains('veterinary')) {
      streams.add(_getVeterinaryEvents(user.uid, startDate, endDate));
    }

    // Real Estate Module
    if (modules == null || modules.contains('real_estate')) {
      streams.add(_getRealEstateEvents(user.uid, startDate, endDate));
    }

    // Sports Module
    if (modules == null || modules.contains('sports')) {
      streams.add(_getSportsEvents(user.uid, startDate, endDate));
    }

    // Education Module
    if (modules == null || modules.contains('education')) {
      streams.add(_getEducationEvents(user.uid, startDate, endDate));
    }

    // Clinic Module
    if (modules == null || modules.contains('clinic')) {
      streams.add(_getClinicEvents(user.uid, startDate, endDate));
    }

    // Tüm stream'leri birleştir
    return _combineStreams(streams);
  }

  /// Beauty Salon etkinliklerini getir
  static Stream<List<CalendarEvent>> _getBeautyEvents(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection(AppConstants.appointmentsCollection)
        .where('userId', isEqualTo: userId)
        .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CalendarEvent.fromSnapshot(
          doc,
          'beauty',
          'appointment',
          'Randevu',
          Colors.pink,
        );
      }).toList();
    });
  }

  /// Psychology etkinliklerini getir
  static Stream<List<CalendarEvent>> _getPsychologyEvents(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final streams = <Stream<List<CalendarEvent>>>[];

    // Psychology Sessions
    streams.add(
      _firestore
          .collection(AppConstants.psychologySessionsCollection)
          .where('userId', isEqualTo: userId)
          .where('sessionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('sessionDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CalendarEvent.fromSnapshot(
            doc,
            'psychology',
            'session',
            'Seans',
            Colors.purple,
          );
        }).toList();
      }),
    );

    // Psychology Appointments
    streams.add(
      _firestore
          .collection(AppConstants.psychologyAppointmentsCollection)
          .where('userId', isEqualTo: userId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CalendarEvent.fromSnapshot(
            doc,
            'psychology',
            'appointment',
            'Randevu',
            Colors.deepPurple,
          );
        }).toList();
      }),
    );

    return _combineStreams(streams);
  }

  /// Lawyer etkinliklerini getir
  static Stream<List<CalendarEvent>> _getLawyerEvents(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final streams = <Stream<List<CalendarEvent>>>[];

    // Lawyer Cases
    streams.add(
      _firestore
          .collection(AppConstants.lawyerCasesCollection)
          .where('userId', isEqualTo: userId)
          .where('caseDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('caseDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CalendarEvent.fromSnapshot(
            doc,
            'lawyer',
            'case',
            'Dava',
            Colors.brown,
          );
        }).toList();
      }),
    );

    // Court Dates
    streams.add(
      _firestore
          .collection(AppConstants.courtDatesCollection)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CalendarEvent.fromSnapshot(
            doc,
            'lawyer',
            'court_date',
            'Duruşma',
            Colors.red,
          );
        }).toList();
      }),
    );

    // Lawyer Hearings
    streams.add(
      _firestore
          .collection(AppConstants.lawyerHearingsCollection)
          .where('userId', isEqualTo: userId)
          .where('hearingDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('hearingDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CalendarEvent.fromSnapshot(
            doc,
            'lawyer',
            'hearing',
            'Duruşma',
            Colors.deepOrange,
          );
        }).toList();
      }),
    );

    return _combineStreams(streams);
  }

  /// Veterinary etkinliklerini getir
  static Stream<List<CalendarEvent>> _getVeterinaryEvents(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final streams = <Stream<List<CalendarEvent>>>[];

    // Veterinary Appointments
    streams.add(
      _firestore
          .collection(AppConstants.veterinaryAppointmentsCollection)
          .where('kullaniciId', isEqualTo: userId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CalendarEvent.fromSnapshot(
            doc,
            'veterinary',
            'appointment',
            'Randevu',
            Colors.green,
          );
        }).toList();
      }),
    );

    // Veterinary Treatments
    streams.add(
      _firestore
          .collection(AppConstants.veterinaryTreatmentsCollection)
          .where('userId', isEqualTo: userId)
          .where('treatmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('treatmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CalendarEvent.fromSnapshot(
            doc,
            'veterinary',
            'treatment',
            'Tedavi',
            Colors.teal,
          );
        }).toList();
      }),
    );

    // Veterinary Vaccinations
    streams.add(
      _firestore
          .collection(AppConstants.veterinaryVaccinationsCollection)
          .where('userId', isEqualTo: userId)
          .where('vaccinationDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('vaccinationDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CalendarEvent.fromSnapshot(
            doc,
            'veterinary',
            'vaccination',
            'Aşı',
            Colors.lightGreen,
          );
        }).toList();
      }),
    );

    return _combineStreams(streams);
  }

  /// Real Estate etkinliklerini getir
  static Stream<List<CalendarEvent>> _getRealEstateEvents(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final streams = <Stream<List<CalendarEvent>>>[];

    // Real Estate Appointments
    streams.add(
      _firestore
          .collection(AppConstants.realEstateAppointmentsCollection)
          .where('userId', isEqualTo: userId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CalendarEvent.fromSnapshot(
            doc,
            'real_estate',
            'appointment',
            'Randevu',
            Colors.orange,
          );
        }).toList();
      }),
    );

    return _combineStreams(streams);
  }

  /// Sports etkinliklerini getir
  static Stream<List<CalendarEvent>> _getSportsEvents(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final streams = <Stream<List<CalendarEvent>>>[];

    // Sports Sessions
    streams.add(
      _firestore
          .collection(AppConstants.sportsSessionsCollection)
          .where('userId', isEqualTo: userId)
          .where('sessionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('sessionDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CalendarEvent.fromSnapshot(
            doc,
            'sports',
            'session',
            'Seans',
            Colors.blue,
          );
        }).toList();
      }),
    );

    // Sports Appointments
    streams.add(
      _firestore
          .collection(AppConstants.sportsAppointmentsCollection)
          .where('userId', isEqualTo: userId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CalendarEvent.fromSnapshot(
            doc,
            'sports',
            'appointment',
            'Randevu',
            Colors.indigo,
          );
        }).toList();
      }),
    );

    return _combineStreams(streams);
  }

  /// Education etkinliklerini getir
  static Stream<List<CalendarEvent>> _getEducationEvents(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final streams = <Stream<List<CalendarEvent>>>[];

    // Education Appointments
    streams.add(
      _firestore
          .collection(AppConstants.educationAppointmentsCollection)
          .where('userId', isEqualTo: userId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CalendarEvent.fromSnapshot(
            doc,
            'education',
            'appointment',
            'Ders',
            Colors.cyan,
          );
        }).toList();
      }),
    );

    // Education Exams
    streams.add(
      _firestore
          .collection(AppConstants.educationExamsCollection)
          .where('userId', isEqualTo: userId)
          .where('examDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('examDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CalendarEvent.fromSnapshot(
            doc,
            'education',
            'exam',
            'Sınav',
            Colors.red,
          );
        }).toList();
      }),
    );

    return _combineStreams(streams);
  }

  /// Clinic etkinliklerini getir
  static Stream<List<CalendarEvent>> _getClinicEvents(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final streams = <Stream<List<CalendarEvent>>>[];

    // Clinic Appointments
    streams.add(
      _firestore
          .collection(AppConstants.clinicAppointmentsCollection)
          .where('userId', isEqualTo: userId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CalendarEvent.fromSnapshot(
            doc,
            'clinic',
            'appointment',
            'Randevu',
            Colors.lightBlue,
          );
        }).toList();
      }),
    );

    // Clinic Treatments
    streams.add(
      _firestore
          .collection(AppConstants.clinicTreatmentsCollection)
          .where('userId', isEqualTo: userId)
          .where('treatmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('treatmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CalendarEvent.fromSnapshot(
            doc,
            'clinic',
            'treatment',
            'Tedavi',
            Colors.blueGrey,
          );
        }).toList();
      }),
    );

    return _combineStreams(streams);
  }

  /// Generic Notes ve Custom Events
  static Stream<List<CalendarEvent>> getCustomEvents(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final streams = <Stream<List<CalendarEvent>>>[];

    // Notes with dates
    streams.add(
      _firestore
          .collection(AppConstants.notesCollection)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CalendarEvent.fromSnapshot(
            doc,
            'custom',
            'note',
            'Not',
            Colors.amber,
          );
        }).toList();
      }),
    );

    // Reminders
    streams.add(
      _firestore
          .collection(AppConstants.remindersCollection)
          .where('userId', isEqualTo: userId)
          .where('reminderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('reminderDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CalendarEvent.fromSnapshot(
            doc,
            'custom',
            'reminder',
            'Hatırlatıcı',
            Colors.yellowAccent,
          );
        }).toList();
      }),
    );

    return _combineStreams(streams);
  }

  /// Birden fazla stream'i birleştir
  static Stream<List<CalendarEvent>> _combineStreams(
    List<Stream<List<CalendarEvent>>> streams,
  ) {
    if (streams.isEmpty) {
      return Stream.value([]);
    }

    if (streams.length == 1) {
      return streams.first;
    }

    // Basit stream merger - her stream değişikliğinde tüm verileri yeniden topla
    late StreamController<List<CalendarEvent>> controller;
    final List<List<CalendarEvent>> currentValues = List.filled(streams.length, []);
    final List<StreamSubscription> subscriptions = [];
    
    controller = StreamController<List<CalendarEvent>>(
      onListen: () {
        for (int i = 0; i < streams.length; i++) {
          subscriptions.add(streams[i].listen(
            (events) {
              currentValues[i] = events;
              final allEvents = currentValues.expand((e) => e).toList();
              controller.add(allEvents);
            },
            onError: (error) {
              // Hatayı görmezden gel, diğer stream'ler çalışmaya devam etsin
            },
          ));
        }
      },
      onCancel: () {
        for (final subscription in subscriptions) {
          subscription.cancel();
        }
      },
    );
    
    return controller.stream;
  }

  /// Belirli bir tarih için etkinlikleri getir
  static Stream<List<CalendarEvent>> getEventsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return getCalendarEvents(
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  /// Belirli bir modüldeki etkinlikleri getir
  static Stream<List<CalendarEvent>> getEventsForModule(
    String module, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return getCalendarEvents(
      startDate: startDate,
      endDate: endDate,
      modules: [module],
    );
  }

  /// Etkinlik sayılarını modül bazında getir
  static Stream<Map<String, int>> getEventCountsByModule({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return getCalendarEvents(
      startDate: startDate,
      endDate: endDate,
    ).map((events) {
      final counts = <String, int>{};
      for (final event in events) {
        counts[event.sourceModule] = (counts[event.sourceModule] ?? 0) + 1;
      }
      return counts;
    });
  }

  /// Modül renkleri
  static Color getModuleColor(String module) {
    switch (module) {
      case 'beauty':
        return Colors.pink;
      case 'psychology':
        return Colors.purple;
      case 'lawyer':
        return Colors.brown;
      case 'veterinary':
        return Colors.green;
      case 'real_estate':
        return Colors.orange;
      case 'sports':
        return Colors.blue;
      case 'education':
        return Colors.cyan;
      case 'clinic':
        return Colors.lightBlue;
      case 'custom':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  /// Modül isimleri
  static String getModuleName(String module, AppLocalizations localizations) {
    switch (module) {
      case 'beauty':
        return localizations.beautySalon;
      case 'psychology':
        return 'Psikoloji';
      case 'lawyer':
        return 'Hukuk';
      case 'veterinary':
        return 'Veteriner';
      case 'real_estate':
        return 'Emlak';
      case 'sports':
        return 'Spor';
      case 'education':
        return 'Eğitim';
      case 'clinic':
        return 'Klinik';
      case 'custom':
        return 'Kişisel';
      default:
        return module;
    }
  }
}