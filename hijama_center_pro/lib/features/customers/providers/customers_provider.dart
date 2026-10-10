import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

FirebaseFirestore get _db => FirebaseFirestore.instance;
String? get _uid => FirebaseAuth.instance.currentUser?.uid;

CollectionReference<Map<String, dynamic>> get _customersCol =>
    _db.collection('users').doc(_uid).collection('customers');

// ── Search Query Provider ─────────────────────────────────────────────────────

final customerSearchQueryProvider = StateProvider<String>((ref) => '');

// ── Customers List Provider ───────────────────────────────────────────────────

final customersListProvider = FutureProvider<List<dynamic>>((ref) async {
  final query = ref.watch(customerSearchQueryProvider).trim().toLowerCase();

  final snap = await _customersCol.get();

  final docs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();

  docs.sort((a, b) {
    final nameA = (a['fullName'] ?? a['full_name'] ?? a['name'] ?? '').toString();
    final nameB = (b['fullName'] ?? b['full_name'] ?? b['name'] ?? '').toString();
    return nameA.toLowerCase().compareTo(nameB.toLowerCase());
  });

  if (query.isEmpty) return docs;

  return docs.where((c) {
    final name = (c['fullName'] ?? c['full_name'] ?? c['name'] ?? '').toString().toLowerCase();
    final phone = (c['phone'] ?? '').toString().toLowerCase();
    return name.contains(query) || phone.contains(query);
  }).toList();
});

// ── Single Customer Profile Provider ─────────────────────────────────────────

final customerProfileProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final snap = await _customersCol.doc(id).get();
  if (!snap.exists) throw Exception('Customer not found');
  return {'id': snap.id, ...snap.data()!};
});

// ── Customers Repository Provider ─────────────────────────────────────────────

final customersRepositoryProvider =
    Provider((ref) => CustomersRepository(ref));

class CustomersRepository {
  final Ref _ref;
  CustomersRepository(this._ref);

  Future<bool> createCustomer(Map<String, dynamic> data) async {
    try {
      await _customersCol.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _ref.invalidate(customersListProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateCustomer(String id, Map<String, dynamic> data) async {
    try {
      await _customersCol.doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _ref.invalidate(customersListProvider);
      _ref.invalidate(customerProfileProvider(id));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    try {
      await _customersCol.doc(id).delete();
      _ref.invalidate(customersListProvider);
      return true;
    } catch (_) {
      return false;
    }
  }
}
