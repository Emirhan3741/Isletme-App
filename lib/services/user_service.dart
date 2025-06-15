// CodeRabbit analyze fix: Dosya düzenlendi
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Kullanıcı ekle
  Future<void> addUser(UserModel user) async {
    final data = user.toMap();
    await _usersCollection.add(data);
  }

  // Kullanıcı güncelle
  Future<void> updateUser(UserModel user, String userId) async {
    await _usersCollection.doc(userId).update(user.toMap());
  }

  // Kullanıcı sil
  Future<void> deleteUser(String userId) async {
    await _usersCollection.doc(userId).delete();
  }

  // Tüm kullanıcıları getir
  Future<List<UserModel>> getUsers() async {
    final querySnapshot = await _usersCollection.orderBy('createdAt', descending: true).get();
    return querySnapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }
}
// Cleaned for Web Build by Cursor 