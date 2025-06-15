import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _customersCollection => _firestore.collection('customers');

  // Müşteri ekle
  Future<void> addCustomer(CustomerModel customer) async {
    final data = customer.toMap();
    await _customersCollection.add(data);
  }

  // Müşteri güncelle
  Future<void> updateCustomer(CustomerModel customer) async {
    await _customersCollection.doc(customer.id).update(customer.toMap());
  }

  // Müşteri sil
  Future<void> deleteCustomer(String customerId) async {
    await _customersCollection.doc(customerId).delete();
  }

  // Tüm müşterileri getir
  Future<List<CustomerModel>> getCustomers() async {
    final querySnapshot = await _customersCollection.orderBy('createdAt', descending: true).get();
    return querySnapshot.docs.map((doc) => CustomerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }
}
// Cleaned for Web Build by Cursor 