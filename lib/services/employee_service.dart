import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/employee_model.dart';

class EmployeeService {
  Future<List<EmployeeModel>> getAllEmployees() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'worker')
        .get();
    return snapshot.docs
        .map((doc) => EmployeeModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
