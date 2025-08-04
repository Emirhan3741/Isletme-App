import 'package:cloud_firestore/cloud_firestore.dart';

/// Kullanıcının bildirim tercihlerini temsil eden model
class NotificationPreferences {
  final bool dailySummary; // Günlük özet bildirimi (19:00)
  final bool appointmentReminder; // Randevu hatırlatması (1 saat önce)
  final bool meetingReminder; // Görüşme hatırlatması (1 saat önce)
  final bool hearingReminder; // Duruşma hatırlatması (1 saat önce)
  final bool todoReminder; // To-do hatırlatması (1 saat önce)
  final bool eventReminder; // Etkinlik hatırlatması (1 saat önce)
  final bool noteReminder; // Not hatırlatması (1 saat önce)

  const NotificationPreferences({
    this.dailySummary = true,
    this.appointmentReminder = true,
    this.meetingReminder = true,
    this.hearingReminder = true,
    this.todoReminder = true,
    this.eventReminder = true,
    this.noteReminder = false,
  });

  /// Firestore dokümanından NotificationPreferences oluştur
  factory NotificationPreferences.fromFirestore(Map<String, dynamic> data) {
    return NotificationPreferences(
      dailySummary: data['dailySummary'] ?? true,
      appointmentReminder: data['appointmentReminder'] ?? true,
      meetingReminder: data['meetingReminder'] ?? true,
      hearingReminder: data['hearingReminder'] ?? true,
      todoReminder: data['todoReminder'] ?? true,
      eventReminder: data['eventReminder'] ?? true,
      noteReminder: data['noteReminder'] ?? false,
    );
  }

  /// Firestore'a kaydetmek için Map'e dönüştür
  Map<String, dynamic> toFirestore() {
    return {
      'dailySummary': dailySummary,
      'appointmentReminder': appointmentReminder,
      'meetingReminder': meetingReminder,
      'hearingReminder': hearingReminder,
      'todoReminder': todoReminder,
      'eventReminder': eventReminder,
      'noteReminder': noteReminder,
    };
  }

  /// copyWith metodu
  NotificationPreferences copyWith({
    bool? dailySummary,
    bool? appointmentReminder,
    bool? meetingReminder,
    bool? hearingReminder,
    bool? todoReminder,
    bool? eventReminder,
    bool? noteReminder,
  }) {
    return NotificationPreferences(
      dailySummary: dailySummary ?? this.dailySummary,
      appointmentReminder: appointmentReminder ?? this.appointmentReminder,
      meetingReminder: meetingReminder ?? this.meetingReminder,
      hearingReminder: hearingReminder ?? this.hearingReminder,
      todoReminder: todoReminder ?? this.todoReminder,
      eventReminder: eventReminder ?? this.eventReminder,
      noteReminder: noteReminder ?? this.noteReminder,
    );
  }

  /// Belirli bir işlem türü için hatırlatma açık mı?
  bool isReminderEnabledForType(String itemType) {
    switch (itemType) {
      case 'appointment':
        return appointmentReminder;
      case 'meeting':
        return meetingReminder;
      case 'hearing':
        return hearingReminder;
      case 'task':
        return todoReminder;
      case 'event':
        return eventReminder;
      case 'note':
        return noteReminder;
      default:
        return false;
    }
  }

  /// Varsayılan ayarlar
  static const NotificationPreferences defaultPreferences = NotificationPreferences();

  /// Tüm hatırlatmaları kapat
  static const NotificationPreferences allDisabled = NotificationPreferences(
    dailySummary: false,
    appointmentReminder: false,
    meetingReminder: false,
    hearingReminder: false,
    todoReminder: false,
    eventReminder: false,
    noteReminder: false,
  );

  /// Sadece günlük özet açık
  static const NotificationPreferences onlyDailySummary = NotificationPreferences(
    dailySummary: true,
    appointmentReminder: false,
    meetingReminder: false,
    hearingReminder: false,
    todoReminder: false,
    eventReminder: false,
    noteReminder: false,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is NotificationPreferences &&
        other.dailySummary == dailySummary &&
        other.appointmentReminder == appointmentReminder &&
        other.meetingReminder == meetingReminder &&
        other.hearingReminder == hearingReminder &&
        other.todoReminder == todoReminder &&
        other.eventReminder == eventReminder &&
        other.noteReminder == noteReminder;
  }

  @override
  int get hashCode {
    return dailySummary.hashCode ^
        appointmentReminder.hashCode ^
        meetingReminder.hashCode ^
        hearingReminder.hashCode ^
        todoReminder.hashCode ^
        eventReminder.hashCode ^
        noteReminder.hashCode;
  }

  @override
  String toString() {
    return 'NotificationPreferences('
        'dailySummary: $dailySummary, '
        'appointmentReminder: $appointmentReminder, '
        'meetingReminder: $meetingReminder, '
        'hearingReminder: $hearingReminder, '
        'todoReminder: $todoReminder, '
        'eventReminder: $eventReminder, '
        'noteReminder: $noteReminder)';
  }
}