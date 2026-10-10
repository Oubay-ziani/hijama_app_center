import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/providers/dashboard_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FirebaseFirestore get _db => FirebaseFirestore.instance;
String? get _uid => FirebaseAuth.instance.currentUser?.uid;

CollectionReference<Map<String, dynamic>> get _expensesCol =>
    _db.collection('users').doc(_uid).collection('expenses');

// ── Expenses List Provider ───────────────────────────────────────────────────

final expensesListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  if (_uid == null) return [];
  try {
    final snap = await _expensesCol.orderBy('date', descending: true).get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  } catch (_) {
    final snap = await _expensesCol.get();
    final list = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    list.sort((a, b) {
      final dateA = (a['date'] ?? a['createdAt'])?.toString() ?? '';
      final dateB = (b['date'] ?? b['createdAt'])?.toString() ?? '';
      return dateB.compareTo(dateA);
    });
    return list;
  }
});

// ── Expenses Repository Provider ─────────────────────────────────────────────

final expensesRepositoryProvider = Provider((ref) => ExpensesRepository(ref));

class ExpensesRepository {
  final Ref _ref;
  ExpensesRepository(this._ref);

  Future<bool> createExpense({
    required String category,
    required double amount,
    required DateTime date,
    String? description,
  }) async {
    try {
      if (_uid == null) return false;
      await _expensesCol.add({
        'category': category,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'description': description?.trim() ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _ref.invalidate(expensesListProvider);
      _ref.invalidate(dashboardStatsProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateExpense(String id, Map<String, dynamic> data) async {
    try {
      if (_uid == null) return false;
      await _expensesCol.doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _ref.invalidate(expensesListProvider);
      _ref.invalidate(dashboardStatsProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    try {
      if (_uid == null) return false;
      await _expensesCol.doc(id).delete();
      _ref.invalidate(expensesListProvider);
      _ref.invalidate(dashboardStatsProvider);
      return true;
    } catch (_) {
      return false;
    }
  }
}
