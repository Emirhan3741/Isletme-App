import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection names
  static const String usersCollection = 'users';
  static const String appointmentsCollection = 'appointments';
  static const String servicesCollection = 'services';
  static const String staffCollection = 'staff';
  static const String contractsCollection = 'contracts';
  static const String customersCollection = 'customers';
  static const String documentsCollection = 'documents';
  static const String transactionsCollection = 'transactions';
  static const String expensesCollection = 'expenses';
  static const String notesCollection = 'notes';
  static const String reportsCollection = 'reports';
  static const String settingsCollection = 'settings';
  static const String auditLogsCollection = 'audit_logs';

  // Current user helper
  String? get currentUserId => _auth.currentUser?.uid;

  User? get currentUser => _auth.currentUser;

  // ===== USERS COLLECTION =====

  /// Create user profile
  Future<String> createUserProfile({
    required Map<String, dynamic> userData,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final userDoc = {
        'id': userId,
        'email': currentUser?.email,
        'displayName': currentUser?.displayName,
        'photoURL': currentUser?.photoURL,
        'emailVerified': currentUser?.emailVerified ?? false,
        'sector': userData['sector'] ?? '',
        'role': userData['role'] ?? 'user',
        'permissions': userData['permissions'] ?? [],
        'businessInfo': userData['businessInfo'] ?? {},
        'personalInfo': userData['personalInfo'] ?? {},
        'preferences': userData['preferences'] ?? {},
        'subscriptionPlan': userData['subscriptionPlan'] ?? 'free',
        'isActive': true,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(usersCollection)
          .doc(userId)
          .set(userDoc, SetOptions(merge: true));
      
      if (kDebugMode) debugPrint('✅ User profile created: $userId');
      return userId;
    } on FirebaseException catch (e) {
      if (kDebugMode) debugPrint('❌ Firebase error creating user profile: ${e.code} - ${e.message}');
      
      // Index error kontrolü
      if (e.code == 'failed-precondition' && e.message?.contains('index') == true) {
        debugPrint('🔍 Index URL: ${_extractIndexUrlFromError(e.message ?? '')}');
      }
      
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Unexpected error creating user profile: $e');
      rethrow;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile([String? userId]) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return null;

    final doc = await _firestore.collection(usersCollection).doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  /// Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection(usersCollection).doc(userId).update(data);
  }

  // ===== APPOINTMENTS COLLECTION =====

  /// Create appointment
  Future<String> createAppointment({
    required Map<String, dynamic> appointmentData,
  }) async {
    return _handleFirestoreOperation<String>(
      'Create Appointment',
      () async {
        final userId = currentUserId;
        if (userId == null) throw Exception('User not authenticated');

        // Null kontrolü - kritik alanlar
        if (appointmentData['startDateTime'] == null) {
          throw Exception('Başlangıç tarihi zorunludur');
        }
        if (appointmentData['endDateTime'] == null) {
          throw Exception('Bitiş tarihi zorunludur');
        }

        final docRef = _firestore.collection(appointmentsCollection).doc();

        final appointmentDoc = {
          'id': docRef.id,
          'userId': userId,
          'ownerId': userId,
          'customerId': appointmentData['customerId'],
          'serviceId': appointmentData['serviceId'],
          'staffId': appointmentData['staffId'],
          'title': appointmentData['title'] ?? '',
          'description': appointmentData['description'] ?? '',
          'startDateTime': appointmentData['startDateTime'],
          'endDateTime': appointmentData['endDateTime'],
          'duration': appointmentData['duration'] ?? 60,
          'status': appointmentData['status'] ?? 'scheduled',
          'priority': appointmentData['priority'] ?? 'normal',
          'sector': appointmentData['sector'] ?? '',
          'location': appointmentData['location'] ?? '',
          'notes': appointmentData['notes'] ?? '',
          'price': appointmentData['price'] ?? 0.0,
          'currency': appointmentData['currency'] ?? 'TRY',
          'paymentStatus': appointmentData['paymentStatus'] ?? 'pending',
          'reminderSent': false,
          'documents': [],
          'metadata': appointmentData['metadata'] ?? {},
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await docRef.set(appointmentDoc);
        
        // Audit log kaydet
        await logAction(
          action: 'appointment_created',
          entityType: 'appointment',
          entityId: docRef.id,
          details: {
            'customerId': appointmentData['customerId'],
            'startDateTime': appointmentData['startDateTime'].toString(),
            'status': appointmentData['status'] ?? 'scheduled',
          },
        );
        
        return docRef.id;
      },
    );
  }

  /// Get appointments with filters
  Future<List<Map<String, dynamic>>> getAppointments({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? customerId,
    String? staffId,
    int limit = 50,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    Query query = _firestore
        .collection(appointmentsCollection)
        .where('userId', isEqualTo: userId);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    if (startDate != null) {
      query = query.where('startDateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('startDateTime',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    if (customerId != null) {
      query = query.where('customerId', isEqualTo: customerId);
    }

    if (staffId != null) {
      query = query.where('staffId', isEqualTo: staffId);
    }

    query = query.orderBy('startDateTime', descending: true).limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  // ===== SERVICES COLLECTION =====

  /// Create service
  Future<String> createService({
    required Map<String, dynamic> serviceData,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final docRef = _firestore.collection(servicesCollection).doc();

    final serviceDoc = {
      'id': docRef.id,
      'userId': userId,
      'ownerId': userId,
      'name': serviceData['name'],
      'description': serviceData['description'] ?? '',
      'category': serviceData['category'] ?? '',
      'sector': serviceData['sector'] ?? '',
      'duration': serviceData['duration'] ?? 60,
      'price': serviceData['price'] ?? 0.0,
      'currency': serviceData['currency'] ?? 'TRY',
      'isActive': serviceData['isActive'] ?? true,
      'staffIds': serviceData['staffIds'] ?? [],
      'requiresPreparation': serviceData['requiresPreparation'] ?? false,
      'preparationTime': serviceData['preparationTime'] ?? 0,
      'bufferTime': serviceData['bufferTime'] ?? 0,
      'maxAdvanceBooking': serviceData['maxAdvanceBooking'] ?? 30,
      'minAdvanceBooking': serviceData['minAdvanceBooking'] ?? 0,
      'allowOnlineBooking': serviceData['allowOnlineBooking'] ?? true,
      'metadata': serviceData['metadata'] ?? {},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(serviceDoc);
    return docRef.id;
  }

  /// Get services
  Future<List<Map<String, dynamic>>> getServices({
    bool? isActive,
    String? category,
    String? sector,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    Query query = _firestore
        .collection(servicesCollection)
        .where('userId', isEqualTo: userId);

    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive);
    }

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    if (sector != null) {
      query = query.where('sector', isEqualTo: sector);
    }

    query = query.orderBy('name');

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  // ===== STAFF COLLECTION =====

  /// Create staff member
  Future<String> createStaff({
    required Map<String, dynamic> staffData,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final docRef = _firestore.collection(staffCollection).doc();

    final staffDoc = {
      'id': docRef.id,
      'userId': userId,
      'ownerId': userId,
      'email': staffData['email'],
      'firstName': staffData['firstName'],
      'lastName': staffData['lastName'],
      'displayName': '${staffData['firstName']} ${staffData['lastName']}',
      'phone': staffData['phone'] ?? '',
      'role': staffData['role'] ?? 'staff',
      'department': staffData['department'] ?? '',
      'position': staffData['position'] ?? '',
      'sector': staffData['sector'] ?? '',
      'permissions': staffData['permissions'] ?? [],
      'serviceIds': staffData['serviceIds'] ?? [],
      'workingHours': staffData['workingHours'] ?? {},
      'isActive': staffData['isActive'] ?? true,
      'hireDate': staffData['hireDate'],
      'salary': staffData['salary'] ?? 0.0,
      'commissionRate': staffData['commissionRate'] ?? 0.0,
      'profileImageUrl': staffData['profileImageUrl'] ?? '',
      'bio': staffData['bio'] ?? '',
      'specializations': staffData['specializations'] ?? [],
      'metadata': staffData['metadata'] ?? {},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(staffDoc);
    return docRef.id;
  }

  /// Get staff members
  Future<List<Map<String, dynamic>>> getStaff({
    bool? isActive,
    String? department,
    String? role,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    Query query = _firestore
        .collection(staffCollection)
        .where('userId', isEqualTo: userId);

    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive);
    }

    if (department != null) {
      query = query.where('department', isEqualTo: department);
    }

    if (role != null) {
      query = query.where('role', isEqualTo: role);
    }

    query = query.orderBy('firstName');

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  // ===== CUSTOMERS COLLECTION =====

  /// Create customer
  Future<String> createCustomer({
    required Map<String, dynamic> customerData,
  }) async {
    return _handleFirestoreOperation<String>(
      'Create Customer',
      () async {
        final userId = currentUserId;
        if (userId == null) throw Exception('User not authenticated');

        // Null kontrolü - kritik alanlar
        if (customerData['firstName'] == null || customerData['firstName'].toString().trim().isEmpty) {
          throw Exception('İsim alanı zorunludur');
        }
        if (customerData['lastName'] == null || customerData['lastName'].toString().trim().isEmpty) {
          throw Exception('Soyisim alanı zorunludur');
        }

        final docRef = _firestore.collection(customersCollection).doc();

        final customerDoc = {
          'id': docRef.id,
          'userId': userId,
          'ownerId': userId,
          'firstName': customerData['firstName'],
          'lastName': customerData['lastName'],
          'displayName': '${customerData['firstName']} ${customerData['lastName']}',
          'email': customerData['email'] ?? '',
          'phone': customerData['phone'] ?? '',
          'dateOfBirth': customerData['dateOfBirth'],
          'gender': customerData['gender'] ?? '',
          'address': customerData['address'] ?? {},
          'sector': customerData['sector'] ?? '',
          'customerType': customerData['customerType'] ?? 'individual',
          'source': customerData['source'] ?? 'manual',
          'status': customerData['status'] ?? 'active',
          'notes': customerData['notes'] ?? '',
          'tags': customerData['tags'] ?? [],
          'preferences': customerData['preferences'] ?? {},
          'emergencyContact': customerData['emergencyContact'] ?? {},
          'medicalInfo': customerData['medicalInfo'] ?? {},
          'totalSpent': 0.0,
          'appointmentCount': 0,
          'lastAppointmentDate': null,
          'profileImageUrl': customerData['profileImageUrl'] ?? '',
          'metadata': customerData['metadata'] ?? {},
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await docRef.set(customerDoc);
        
        // Audit log kaydet
        await logAction(
          action: 'customer_created',
          entityType: 'customer',
          entityId: docRef.id,
          details: {
            'firstName': customerData['firstName'],
            'lastName': customerData['lastName'],
            'email': customerData['email'] ?? '',
            'phone': customerData['phone'] ?? '',
          },
        );
        
        return docRef.id;
      },
    );
  }

  /// Get customers
  Future<List<Map<String, dynamic>>> getCustomers({
    String? status,
    String? customerType,
    String? searchTerm,
    int limit = 50,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    Query query = _firestore
        .collection(customersCollection)
        .where('userId', isEqualTo: userId);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    if (customerType != null) {
      query = query.where('customerType', isEqualTo: customerType);
    }

    query = query.orderBy('firstName').limit(limit);

    final snapshot = await query.get();
    List<Map<String, dynamic>> customers =
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    // Client-side search if searchTerm provided
    if (searchTerm != null && searchTerm.isNotEmpty) {
      final searchLower = searchTerm.toLowerCase();
      customers = customers.where((customer) {
        final name =
            '${customer['firstName']} ${customer['lastName']}'.toLowerCase();
        final email = (customer['email'] as String? ?? '').toLowerCase();
        final phone = (customer['phone'] as String? ?? '').toLowerCase();
        return name.contains(searchLower) ||
            email.contains(searchLower) ||
            phone.contains(searchLower);
      }).toList();
    }

    return customers;
  }

  // ===== DOCUMENTS COLLECTION =====

  /// Create document record
  Future<String> createDocument({
    required Map<String, dynamic> documentData,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final docRef = _firestore.collection(documentsCollection).doc();

    final documentDoc = {
      'id': docRef.id,
      'userId': userId,
      'ownerId': userId,
      'type': documentData['type'] ?? 'general',
      'category': documentData['category'] ?? '',
      'title': documentData['title'],
      'description': documentData['description'] ?? '',
      'fileName': documentData['fileName'],
      'originalFileName': documentData['originalFileName'],
      'fileUrl': documentData['fileUrl'],
      'fileExtension': documentData['fileExtension'],
      'fileSizeBytes': documentData['fileSizeBytes'],
      'fileSizeMB': documentData['fileSizeMB'],
      'storagePath': documentData['storagePath'],
      'relatedEntityType': documentData[
          'relatedEntityType'], // appointment, customer, staff, etc.
      'relatedEntityId': documentData['relatedEntityId'],
      'sector': documentData['sector'] ?? '',
      'tags': documentData['tags'] ?? [],
      'isPublic': documentData['isPublic'] ?? false,
      'accessPermissions': documentData['accessPermissions'] ?? [],
      'expiryDate': documentData['expiryDate'],
      'version': documentData['version'] ?? 1,
      'parentDocumentId': documentData['parentDocumentId'],
      'metadata': documentData['metadata'] ?? {},
      'uploadedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(documentDoc);
    return docRef.id;
  }

  /// Get documents
  Future<List<Map<String, dynamic>>> getDocuments({
    String? type,
    String? category,
    String? relatedEntityType,
    String? relatedEntityId,
    int limit = 50,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    Query query = _firestore
        .collection(documentsCollection)
        .where('userId', isEqualTo: userId);

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    if (relatedEntityType != null) {
      query = query.where('relatedEntityType', isEqualTo: relatedEntityType);
    }

    if (relatedEntityId != null) {
      query = query.where('relatedEntityId', isEqualTo: relatedEntityId);
    }

    query = query.orderBy('uploadedAt', descending: true).limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  // ===== GENERIC CRUD OPERATIONS =====

  /// Generic create
  Future<String> createGenericDocument({
    required String collection,
    required Map<String, dynamic> data,
    String? docId,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    data['userId'] = userId;
    data['ownerId'] = userId;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    DocumentReference docRef;
    if (docId != null) {
      docRef = _firestore.collection(collection).doc(docId);
      data['id'] = docId;
    } else {
      docRef = _firestore.collection(collection).doc();
      data['id'] = docRef.id;
    }

    await docRef.set(data);
    return docRef.id;
  }

  /// Generic read
  Future<Map<String, dynamic>?> getGenericDocument({
    required String collection,
    required String docId,
  }) async {
    final doc = await _firestore.collection(collection).doc(docId).get();
    return doc.exists ? doc.data() : null;
  }

  /// Generic update
  Future<void> updateGenericDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection(collection).doc(docId).update(data);
  }

  /// Generic delete
  Future<void> deleteGenericDocument({
    required String collection,
    required String docId,
  }) async {
    await _firestore.collection(collection).doc(docId).delete();
  }

  /// Generic query
  Future<List<Map<String, dynamic>>> queryDocuments({
    required String collection,
    Map<String, dynamic>? where,
    String? orderBy,
    bool descending = false,
    int limit = 50,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    Query query =
        _firestore.collection(collection).where('userId', isEqualTo: userId);

    if (where != null) {
      where.forEach((key, value) {
        query = query.where(key, isEqualTo: value);
      });
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  // ===== AUDIT LOG =====

  /// Log user action
  Future<void> logAction({
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? details,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _firestore.collection(auditLogsCollection).add({
        'userId': userId,
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
        'details': details ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': '', // Can be populated if needed
        'userAgent': '', // Can be populated if needed
      });
    } catch (e) {
      if (kDebugMode) print('Audit log error: $e');
    }
  }

  // ===== BATCH OPERATIONS =====

  /// Batch write operations
  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    final batch = _firestore.batch();

    for (final operation in operations) {
      final type = operation['type'] as String;
      final collection = operation['collection'] as String;
      final docId = operation['docId'] as String? ?? '';
      final data = operation['data'] as Map<String, dynamic>?;

      final docRef = docId.isNotEmpty
          ? _firestore.collection(collection).doc(docId)
          : _firestore.collection(collection).doc();

      switch (type) {
        case 'set':
          batch.set(docRef, data!);
          break;
        case 'update':
          batch.update(docRef, data!);
          break;
        case 'delete':
          batch.delete(docRef);
          break;
      }
    }

    await batch.commit();
  }

  // ===== REAL-TIME LISTENERS =====

  /// Listen to collection changes
  Stream<List<Map<String, dynamic>>> listenToCollection({
    required String collection,
    Map<String, dynamic>? where,
    String? orderBy,
    bool descending = false,
    int limit = 50,
  }) {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    Query query =
        _firestore.collection(collection).where('userId', isEqualTo: userId);

    if (where != null) {
      where.forEach((key, value) {
        query = query.where(key, isEqualTo: value);
      });
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }

  /// Listen to document changes
  Stream<Map<String, dynamic>?> listenToDocument({
    required String collection,
    required String docId,
  }) {
    return _firestore.collection(collection).doc(docId).snapshots().map((doc) {
      return doc.exists ? doc.data() : null;
    });
  }

  // ===== ERROR HANDLING HELPERS =====

  /// Index URL'sini hata mesajından çıkart
  String _extractIndexUrlFromError(String errorMessage) {
    final RegExp urlRegex = RegExp(r'https://console\.firebase\.google\.com[^\s]*');
    final match = urlRegex.firstMatch(errorMessage);
    return match?.group(0) ?? 'Index URL bulunamadı';
  }

  /// Firestore hatalarını yakala ve logla
  Future<T> _handleFirestoreOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    try {
      final result = await operation();
      if (kDebugMode) debugPrint('✅ $operationName başarılı');
      return result;
    } on FirebaseException catch (e) {
      if (kDebugMode) debugPrint('❌ Firebase $operationName hatası: ${e.code} - ${e.message}');
      
      // Özel hata tipleri için loglama
      switch (e.code) {
        case 'failed-precondition':
          if (e.message?.contains('index') == true) {
            final indexUrl = _extractIndexUrlFromError(e.message ?? '');
            debugPrint('🔍 Eksik Index - URL: $indexUrl');
            debugPrint('💡 Çözüm: Bu URL\'yi tarayıcıda açın ve index oluşturun');
          }
          break;
        case 'permission-denied':
          debugPrint('🚫 Permission denied - Firestore rules kontrol edin');
          break;
        case 'unavailable':
          debugPrint('🌐 Firestore servis kullanılamıyor - Network kontrol edin');
          break;
        case 'deadline-exceeded':
          debugPrint('⏰ Firestore timeout - İşlem zaman aşımı');
          break;
      }
      
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Beklenmeyen $operationName hatası: $e');
      rethrow;
    }
  }
}
