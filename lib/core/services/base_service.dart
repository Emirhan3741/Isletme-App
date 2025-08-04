import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/base_model.dart';
import '../constants/app_constants.dart';

abstract class BaseService<T extends BaseModel> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection adı her service'te override edilmeli
  String get collectionName;

  // Model factory method her service'te override edilmeli
  T fromMap(Map<String, dynamic> map);

  // Mevcut kullanıcı ID'si
  String? get currentUserId => _auth.currentUser?.uid;

  // Collection referansı
  CollectionReference get collection => _firestore.collection(collectionName);

  // Kullanıcı bazlı collection referansı
  Query get userCollection {
    if (currentUserId == null) throw Exception('Kullanıcı oturum açmamış');
    return collection.where('userId', isEqualTo: currentUserId);
  }

  // CRUD İşlemleri

  // Ekleme
  Future<String> add(T model) async {
    if (currentUserId == null) throw Exception('Kullanıcı oturum açmamış');

    final docRef = await collection.add(model.toMap());
    return docRef.id;
  }

  // Güncelleme
  Future<void> update(T model) async {
    if (currentUserId == null) throw Exception('Kullanıcı oturum açmamış');

    await collection.doc(model.id).update(model.toMap());
  }

  // Silme
  Future<void> delete(String id) async {
    if (currentUserId == null) throw Exception('Kullanıcı oturum açmamış');

    await collection.doc(id).delete();
  }

  // Soft delete (isActive = false)
  Future<void> softDelete(String id) async {
    if (currentUserId == null) throw Exception('Kullanıcı oturum açmamış');

    await collection.doc(id).update({
      'isActive': false,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ID ile getirme
  Future<T?> getById(String id) async {
    if (currentUserId == null) return null;

    final doc = await collection.doc(id).get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return fromMap(data);
  }

  // Tüm kayıtları getirme (Stream)
  Stream<List<T>> getAll({
    bool activeOnly = true,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    if (currentUserId == null) return Stream.value([]);

    Query query = userCollection;

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return fromMap(data);
      }).toList();
    });
  }

  // Sayfalı getirme
  Future<List<T>> getPaginated({
    DocumentSnapshot? startAfter,
    int limit = AppConstants.defaultPageSize,
    bool activeOnly = true,
    String? orderBy,
    bool descending = false,
  }) async {
    if (currentUserId == null) return [];

    Query query = userCollection;

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return fromMap(data);
    }).toList();
  }

  // Arama
  Stream<List<T>> search({
    required String field,
    required String searchTerm,
    bool activeOnly = true,
    int? limit,
  }) {
    if (currentUserId == null) return Stream.value([]);

    Query query = userCollection;

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    // Firestore'da text search için >= ve < kullanımı
    query = query
        .where(field, isGreaterThanOrEqualTo: searchTerm)
        .where(field, isLessThan: searchTerm + '\uf8ff');

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return fromMap(data);
      }).toList();
    });
  }

  // Filtreleme
  Stream<List<T>> filter({
    Map<String, dynamic>? whereConditions,
    String? orderBy,
    bool descending = false,
    int? limit,
    bool activeOnly = true,
  }) {
    if (currentUserId == null) return Stream.value([]);

    Query query = userCollection;

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    // Where koşullarını ekle
    if (whereConditions != null) {
      whereConditions.forEach((field, value) {
        if (value != null) {
          query = query.where(field, isEqualTo: value);
        }
      });
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return fromMap(data);
      }).toList();
    });
  }

  // Sayı getirme
  Future<int> getCount({bool activeOnly = true}) async {
    if (currentUserId == null) return 0;

    Query query = userCollection;

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  // Toplu işlemler
  Future<void> batchUpdate(List<T> models) async {
    if (currentUserId == null) throw Exception('Kullanıcı oturum açmamış');

    final batch = _firestore.batch();

    for (final model in models) {
      batch.update(collection.doc(model.id), model.toMap());
    }

    await batch.commit();
  }

  Future<void> batchDelete(List<String> ids) async {
    if (currentUserId == null) throw Exception('Kullanıcı oturum açmamış');

    final batch = _firestore.batch();

    for (final id in ids) {
      batch.delete(collection.doc(id));
    }

    await batch.commit();
  }

  // Sektör bazlı filtreleme
  Stream<List<T>> getBySector(
    String sector, {
    bool activeOnly = true,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    if (currentUserId == null) return Stream.value([]);

    Query query = userCollection.where('sector', isEqualTo: sector);

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return fromMap(data);
      }).toList();
    });
  }

  // Tarih aralığı filtreleme
  Stream<List<T>> getByDateRange({
    required String dateField,
    DateTime? startDate,
    DateTime? endDate,
    bool activeOnly = true,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    if (currentUserId == null) return Stream.value([]);

    Query query = userCollection;

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    if (startDate != null) {
      query = query.where(dateField,
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where(dateField,
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return fromMap(data);
      }).toList();
    });
  }
}
