import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Tüm modüller için ortak takvim eventi modeli
class CalendarEvent {
  /// Etkinlik ID'si
  final String id;
  
  /// Etkinlik başlığı
  final String title;
  
  /// Etkinlik türü (çeviri anahtarı)
  final String type;
  
  /// Etkinlik türü anahtarı (logic için)
  final String typeKey;
  
  /// Kaynak modül (beauty, lawyer, psychology, vb.)
  final String sourceModule;
  
  /// Etkinlik tarihi
  final DateTime date;
  
  /// Etkinlik zamanı (HH:mm formatında)
  final String time;
  
  /// Bitiş tarihi (opsiyonel)
  final DateTime? endDate;
  
  /// Bitiş zamanı (opsiyonel)
  final String? endTime;
  
  /// Açıklama
  final String description;
  
  /// Miktar (ödeme, gelir vb. için)
  final double amount;
  
  /// Etkinlik rengi
  final Color color;
  
  /// Müşteri adı
  final String customerName;
  
  /// Personel/çalışan adı
  final String employeeName;
  
  /// Hizmet adı
  final String serviceName;
  
  /// Durum (confirmed, pending, cancelled, completed)
  final String status;
  
  /// Öncelik (low, medium, high, urgent)
  final String priority;
  
  /// Konumun sı 
  final String location;
  
  /// Not/memo
  final String notes;
  
  /// Kullanıcı ID'si
  final String userId;
  
  /// Oluşturma tarihi
  final DateTime createdAt;
  
  /// Son güncellenme tarihi
  final DateTime? updatedAt;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.typeKey,
    required this.sourceModule,
    required this.date,
    required this.userId,
    required this.createdAt,
    this.time = '',
    this.endDate,
    this.endTime,
    this.description = '',
    this.amount = 0.0,
    this.color = Colors.blue,
    this.customerName = '',
    this.employeeName = '',
    this.serviceName = '',
    this.status = 'pending',
    this.priority = 'medium',
    this.location = '',
    this.notes = '',
    this.updatedAt,
  });

  /// Firestore DocumentSnapshot'tan CalendarEvent oluştur
  factory CalendarEvent.fromSnapshot(
    DocumentSnapshot snapshot,
    String sourceModule,
    String typeKey,
    String type,
    Color color,
  ) {
    final data = snapshot.data() as Map<String, dynamic>;
    
    // Tarih alanlarını kontrol et
    DateTime? eventDate;
    if (data.containsKey('appointmentDate') && data['appointmentDate'] != null) {
      eventDate = (data['appointmentDate'] as Timestamp).toDate();
    } else if (data.containsKey('date') && data['date'] != null) {
      eventDate = (data['date'] as Timestamp).toDate();
    } else if (data.containsKey('sessionDate') && data['sessionDate'] != null) {
      eventDate = (data['sessionDate'] as Timestamp).toDate();
    } else if (data.containsKey('caseDate') && data['caseDate'] != null) {
      eventDate = (data['caseDate'] as Timestamp).toDate();
    } else if (data.containsKey('meetingDate') && data['meetingDate'] != null) {
      eventDate = (data['meetingDate'] as Timestamp).toDate();
    } else if (data.containsKey('visitDate') && data['visitDate'] != null) {
      eventDate = (data['visitDate'] as Timestamp).toDate();
    } else if (data.containsKey('examDate') && data['examDate'] != null) {
      eventDate = (data['examDate'] as Timestamp).toDate();
    } else if (data.containsKey('createdAt') && data['createdAt'] != null) {
      eventDate = (data['createdAt'] as Timestamp).toDate();
    } else {
      eventDate = DateTime.now();
    }

    // Bitiş tarihi
    DateTime? eventEndDate;
    if (data.containsKey('endDate') && data['endDate'] != null) {
      eventEndDate = (data['endDate'] as Timestamp).toDate();
    }

    // Zaman alanları
    String eventTime = '';
    if (data.containsKey('time') && data['time'] is String) {
      eventTime = data['time'] as String;
    } else if (data.containsKey('appointmentTime') && data['appointmentTime'] is String) {
      eventTime = data['appointmentTime'] as String;
    } else if (data.containsKey('sessionTime') && data['sessionTime'] is String) {
      eventTime = data['sessionTime'] as String;
    }

    String eventEndTime = '';
    if (data.containsKey('endTime') && data['endTime'] is String) {
      eventEndTime = data['endTime'] as String;
    }

    // Başlık oluştur
    String title = '';
    if (data.containsKey('title') && data['title'] is String) {
      title = data['title'] as String;
    } else if (data.containsKey('service') && data['service'] is String) {
      title = data['service'] as String;
    } else if (data.containsKey('caseName') && data['caseName'] is String) {
      title = data['caseName'] as String;
    } else if (data.containsKey('sessionType') && data['sessionType'] is String) {
      title = data['sessionType'] as String;
    } else if (data.containsKey('subject') && data['subject'] is String) {
      title = data['subject'] as String;
    } else {
      title = type;
    }

    // Müşteri adı
    String customerName = '';
    if (data.containsKey('customerName') && data['customerName'] is String) {
      customerName = data['customerName'] as String;
    } else if (data.containsKey('clientName') && data['clientName'] is String) {
      customerName = data['clientName'] as String;
    } else if (data.containsKey('patientName') && data['patientName'] is String) {
      customerName = data['patientName'] as String;
    } else if (data.containsKey('ownerName') && data['ownerName'] is String) {
      customerName = data['ownerName'] as String;
    }

    // Personel adı
    String employeeName = '';
    if (data.containsKey('employeeName') && data['employeeName'] is String) {
      employeeName = data['employeeName'] as String;
    } else if (data.containsKey('therapistName') && data['therapistName'] is String) {
      employeeName = data['therapistName'] as String;
    } else if (data.containsKey('doctorName') && data['doctorName'] is String) {
      employeeName = data['doctorName'] as String;
    } else if (data.containsKey('lawyerName') && data['lawyerName'] is String) {
      employeeName = data['lawyerName'] as String;
    }

    // Hizmet adı
    String serviceName = '';
    if (data.containsKey('service') && data['service'] is String) {
      serviceName = data['service'] as String;
    } else if (data.containsKey('serviceName') && data['serviceName'] is String) {
      serviceName = data['serviceName'] as String;
    } else if (data.containsKey('treatmentType') && data['treatmentType'] is String) {
      serviceName = data['treatmentType'] as String;
    }

    // Açıklama
    String description = '';
    if (data.containsKey('description') && data['description'] is String) {
      description = data['description'] as String;
    } else if (data.containsKey('notes') && data['notes'] is String) {
      description = data['notes'] as String;
    } else if (data.containsKey('caseDescription') && data['caseDescription'] is String) {
      description = data['caseDescription'] as String;
    }

    // Miktar
    double amount = 0.0;
    if (data.containsKey('amount') && data['amount'] != null) {
      if (data['amount'] is num) {
        amount = (data['amount'] as num).toDouble();
      }
    } else if (data.containsKey('price') && data['price'] != null) {
      if (data['price'] is num) {
        amount = (data['price'] as num).toDouble();
      }
    } else if (data.containsKey('fee') && data['fee'] != null) {
      if (data['fee'] is num) {
        amount = (data['fee'] as num).toDouble();
      }
    }

    // Durum
    String status = 'pending';
    if (data.containsKey('status') && data['status'] is String) {
      status = data['status'] as String;
    }

    // Öncelik
    String priority = 'medium';
    if (data.containsKey('priority') && data['priority'] is String) {
      priority = data['priority'] as String;
    }

    // Konum
    String location = '';
    if (data.containsKey('location') && data['location'] is String) {
      location = data['location'] as String;
    } else if (data.containsKey('courtroom') && data['courtroom'] is String) {
      location = data['courtroom'] as String;
    } else if (data.containsKey('room') && data['room'] is String) {
      location = data['room'] as String;
    }

    // Notlar
    String notes = '';
    if (data.containsKey('notes') && data['notes'] is String) {
      notes = data['notes'] as String;
    } else if (data.containsKey('memo') && data['memo'] is String) {
      notes = data['memo'] as String;
    }

    // Kullanıcı ID'si
    String userId = '';
    if (data.containsKey('userId') && data['userId'] is String) {
      userId = data['userId'] as String;
    }

    // Tarihler
    DateTime createdAt = DateTime.now();
    if (data.containsKey('createdAt') && data['createdAt'] != null) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    }

    DateTime? updatedAt;
    if (data.containsKey('updatedAt') && data['updatedAt'] != null) {
      updatedAt = (data['updatedAt'] as Timestamp).toDate();
    }

    return CalendarEvent(
      id: snapshot.id,
      title: title,
      type: type,
      typeKey: typeKey,
      sourceModule: sourceModule,
      date: eventDate,
      time: eventTime,
      endDate: eventEndDate,
      endTime: eventEndTime.isEmpty ? null : eventEndTime,
      description: description,
      amount: amount,
      color: color,
      customerName: customerName,
      employeeName: employeeName,
      serviceName: serviceName,
      status: status,
      priority: priority,
      location: location,
      notes: notes,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Map'e dönüştür
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'typeKey': typeKey,
      'sourceModule': sourceModule,
      'date': Timestamp.fromDate(date),
      'time': time,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'endTime': endTime,
      'description': description,
      'amount': amount,
      'customerName': customerName,
      'employeeName': employeeName,
      'serviceName': serviceName,
      'status': status,
      'priority': priority,
      'location': location,
      'notes': notes,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Kopya oluştur
  CalendarEvent copyWith({
    String? id,
    String? title,
    String? type,
    String? typeKey,
    String? sourceModule,
    DateTime? date,
    String? time,
    DateTime? endDate,
    String? endTime,
    String? description,
    double? amount,
    Color? color,
    String? customerName,
    String? employeeName,
    String? serviceName,
    String? status,
    String? priority,
    String? location,
    String? notes,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      typeKey: typeKey ?? this.typeKey,
      sourceModule: sourceModule ?? this.sourceModule,
      date: date ?? this.date,
      time: time ?? this.time,
      endDate: endDate ?? this.endDate,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      color: color ?? this.color,
      customerName: customerName ?? this.customerName,
      employeeName: employeeName ?? this.employeeName,
      serviceName: serviceName ?? this.serviceName,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CalendarEvent{id: $id, title: $title, type: $type, sourceModule: $sourceModule, date: $date}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEvent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sourceModule == other.sourceModule;

  @override
  int get hashCode => id.hashCode ^ sourceModule.hashCode;
}