import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/reminder_model.dart';

class ReminderService {
  final CollectionReference _remindersCollection =
      FirebaseFirestore.instance.collection('reminders');
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  Future<List<ReminderModel>> getAllReminders() async {
    if (_userId == null) return [];

    try {
      final snapshot = await _remindersCollection
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReminderModel.fromMap(
              {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addReminder(ReminderModel reminder) async {
    if (_userId == null) return;

    try {
      await _remindersCollection.add({
        ...reminder.toMap(),
        'userId': _userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    if (_userId == null || reminder.id.isEmpty) return;

    try {
      await _remindersCollection.doc(reminder.id).update({
        ...reminder.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteReminder(String id) async {
    if (_userId == null || id.isEmpty) return;

    try {
      await _remindersCollection.doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Stream metodları
  Stream<List<ReminderModel>> getRemindersStream() {
    if (_userId == null) return Stream.value([]);

    return _remindersCollection
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReminderModel.fromMap(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
            .toList());
  }
}
