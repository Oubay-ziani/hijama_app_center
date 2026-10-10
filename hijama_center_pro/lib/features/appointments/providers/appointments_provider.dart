import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/providers/dashboard_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FirebaseFirestore get _db => FirebaseFirestore.instance;
String? get _uid => FirebaseAuth.instance.currentUser?.uid;

CollectionReference<Map<String, dynamic>> get _appointmentsCol =>
    _db.collection('users').doc(_uid).collection('appointments');

// ── Appointments List Provider ────────────────────────────────────────────────

final appointmentsListProvider = FutureProvider<List<dynamic>>((ref) async {
  final snap = await _appointmentsCol
      .orderBy('dateTime', descending: false)
      .get();
  return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
});

// ── Single Appointment Detail Provider ───────────────────────────────────────

final appointmentDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final snap = await _appointmentsCol.doc(id).get();
  if (!snap.exists) throw Exception('Appointment not found');
  return {'id': snap.id, ...snap.data()!};
});

// ── Appointments Repository Provider ─────────────────────────────────────────

final appointmentsRepositoryProvider =
    Provider((ref) => AppointmentsRepository(ref));

class AppointmentsRepository {
  final Ref _ref;
  AppointmentsRepository(this._ref);

  Future<bool> createAppointment(Map<String, dynamic> data) async {
    try {
      await _appointmentsCol.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _ref.invalidate(appointmentsListProvider);
      _ref.invalidate(dashboardStatsProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateAppointment(String id, Map<String, dynamic> data) async {
    try {
      await _appointmentsCol.doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _ref.invalidate(appointmentsListProvider);
      _ref.invalidate(appointmentDetailProvider(id));
      _ref.invalidate(dashboardStatsProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAppointment(String id) async {
    try {
      await _appointmentsCol.doc(id).delete();
      _ref.invalidate(appointmentsListProvider);
      _ref.invalidate(dashboardStatsProvider);
      return true;
    } catch (_) {
      return false;
    }
  }
}
