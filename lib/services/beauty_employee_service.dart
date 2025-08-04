import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BeautyEmployeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;
  String? get _salonId => _userId;

  /// Get salon employees stream
  Stream<List<Map<String, dynamic>>> getSalonEmployees() {
    if (_salonId == null) return Stream.value([]);

    return _firestore
        .collection('salons')
        .doc(_salonId)
        .collection('employees')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  /// Get salon employees as Future
  Future<List<Map<String, dynamic>>> getEmployees() async {
    if (_salonId == null) return [];

    final snapshot = await _firestore
        .collection('salons')
        .doc(_salonId)
        .collection('employees')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  /// Add employee
  Future<void> addEmployee(Map<String, dynamic> employeeData) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');
    if (_salonId == null) throw Exception('Salon ID bulunamadı');

    employeeData['userId'] = _userId;
    employeeData['salonId'] = _salonId;
    employeeData['createdAt'] = FieldValue.serverTimestamp();
    employeeData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('salons')
        .doc(_salonId)
        .collection('employees')
        .add(employeeData);
  }

  /// Update employee
  Future<void> updateEmployee(
      String employeeId, Map<String, dynamic> employeeData) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');
    if (_salonId == null) throw Exception('Salon ID bulunamadı');
    if (employeeId.isEmpty) throw Exception('Çalışan ID boş olamaz');

    employeeData['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('salons')
        .doc(_salonId)
        .collection('employees')
        .doc(employeeId)
        .update(employeeData);
  }

  /// Delete employee with validation
  Future<void> deleteEmployee(String employeeId) async {
    if (_userId == null) throw Exception('Kullanıcı oturum açmamış');
    if (_salonId == null || _salonId!.isEmpty) {
      throw Exception('Salon ID bulunamadı veya geçersiz');
    }
    if (employeeId.isEmpty) {
      throw Exception('Çalışan ID boş olamaz');
    }

    try {
      await _firestore
          .collection('salons')
          .doc(_salonId)
          .collection('employees')
          .doc(employeeId)
          .delete();
    } catch (e) {
      throw Exception('Çalışan silme hatası: $e');
    }
  }

  /// Get single employee
  Future<Map<String, dynamic>?> getEmployee(String employeeId) async {
    if (_salonId == null || employeeId.isEmpty) return null;

    final doc = await _firestore
        .collection('salons')
        .doc(_salonId)
        .collection('employees')
        .doc(employeeId)
        .get();

    if (doc.exists) {
      return {...doc.data()!, 'id': doc.id};
    }
    return null;
  }

  /// Get active employees for dropdowns
  Future<List<Map<String, dynamic>>> getActiveEmployees() async {
    if (_salonId == null) return [];

    final snapshot = await _firestore
        .collection('salons')
        .doc(_salonId)
        .collection('employees')
        .where('status', isEqualTo: 'active')
        .orderBy('name')
        .get();

    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  /// Initialize salon document if it doesn't exist
  Future<void> initializeSalon() async {
    if (_userId == null || _salonId == null) return;

    final salonDoc = await _firestore.collection('salons').doc(_salonId).get();

    if (!salonDoc.exists) {
      await _firestore.collection('salons').doc(_salonId).set({
        'ownerId': _userId,
        'createdAt': FieldValue.serverTimestamp(),
        'salonType': 'beauty',
        'isActive': true,
      });
    }
  }
}
