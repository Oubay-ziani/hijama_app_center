import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FirebaseFirestore get _db => FirebaseFirestore.instance;
String? get _uid => FirebaseAuth.instance.currentUser?.uid;

CollectionReference<Map<String, dynamic>> get _employeesCol =>
    _db.collection('users').doc(_uid).collection('employees');

// ── Employees List Provider ───────────────────────────────────────────────────

final employeesListProvider = FutureProvider<List<dynamic>>((ref) async {
  final snap = await _employeesCol.orderBy('name').get();
  return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
});

// ── Employees Repository Provider ─────────────────────────────────────────────

final employeesRepositoryProvider =
    Provider((ref) => EmployeesRepository(ref));

class EmployeesRepository {
  final Ref _ref;
  EmployeesRepository(this._ref);

  Future<bool> createEmployee(Map<String, dynamic> data) async {
    try {
      await _employeesCol.add({
        'name': data['name'] ?? '',
        'email': data['email'] ?? '',
        'role': data['role'] ?? 'employee',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _ref.invalidate(employeesListProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteEmployee(String id) async {
    try {
      await _employeesCol.doc(id).delete();
      _ref.invalidate(employeesListProvider);
      return true;
    } catch (_) {
      return false;
    }
  }
}
