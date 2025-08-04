// CodeRabbit analyze fix: Dosya düzenlendi
// Refactored by Cursor

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Kullanıcı ekle
  Future<void> addUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('Kullanıcı eklenirken hata oluştu: $e');
    }
  }

  // Kullanıcı güncelle
  Future<void> updateUser(UserModel user, String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        ...user.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Kullanıcı güncellenirken hata oluştu: $e');
    }
  }

  // Kullanıcı sil
  Future<void> deleteUser(String userId) async {
    await _usersCollection.doc(userId).delete();
  }

  // Tüm kullanıcıları getir
  Future<List<UserModel>> getUsers() async {
    final snapshot = await _usersCollection.get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserModel>> getAllWorkers() async {
    final snapshot =
        await _usersCollection.where('role', isEqualTo: 'worker').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<UserModel?> getUserById(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Stream metodları
  Stream<List<UserModel>> getUsersStream() {
    return _usersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
            .toList());
  }

  Stream<List<UserModel>> getWorkersStream() {
    return _usersCollection
        .where('role', isEqualTo: 'worker')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
            .toList());
  }

  Stream<UserModel?> getUserByIdStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) => doc.exists
        ? UserModel.fromMap(
            {...doc.data() as Map<String, dynamic>, 'id': doc.id})
        : null);
  }

  // Alias methods for backward compatibility
  Future<UserModel?> getUser(String userId) async {
    return await getUserById(userId);
  }

  Future<void> createUser(UserModel user) async {
    return await addUser(user);
  }
}
// Cleaned for Web Build by Cursor
