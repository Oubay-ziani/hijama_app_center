import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/providers/dashboard_provider.dart';
import '../../customers/providers/customers_provider.dart';
import '../../inventory/providers/inventory_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FirebaseFirestore get _db => FirebaseFirestore.instance;
String? get _uid => FirebaseAuth.instance.currentUser?.uid;

CollectionReference<Map<String, dynamic>> get _sessionsCol =>
    _db.collection('users').doc(_uid).collection('sessions');

CollectionReference<Map<String, dynamic>> get _customersCol =>
    _db.collection('users').doc(_uid).collection('customers');

CollectionReference<Map<String, dynamic>> get _inventoryCol =>
    _db.collection('users').doc(_uid).collection('inventory');

// ── Filter State Providers ───────────────────────────────────────────────────

final sessionSearchQueryProvider = StateProvider<String>((ref) => '');
final sessionStatusFilterProvider = StateProvider<String>((ref) => 'ALL'); // ALL, RESERVED, CONFIRMED, COMPLETED, CANCELLED
final sessionMonthFilterProvider = StateProvider<DateTime?>((ref) => null);

// ── All Sessions List Provider ───────────────────────────────────────────────

final sessionsListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  if (_uid == null) return [];
  final query = ref.watch(sessionSearchQueryProvider).trim().toLowerCase();
  final statusFilter = ref.watch(sessionStatusFilterProvider);
  final monthFilter = ref.watch(sessionMonthFilterProvider);

  final snap = await _sessionsCol.get();

  final docs = snap.docs.map((d) {
    final data = d.data();
    return {'id': d.id, ...data};
  }).toList();

  // Sort descending by scheduledAt / date / createdAt
  docs.sort((a, b) {
    final dtA = _parseDateTime(a['scheduledAt'] ?? a['date'] ?? a['createdAt']);
    final dtB = _parseDateTime(b['scheduledAt'] ?? b['date'] ?? b['createdAt']);
    return dtB.compareTo(dtA);
  });

  return docs.where((s) {
    // Status Filter
    if (statusFilter != 'ALL') {
      final status = (s['status'] ?? 'COMPLETED').toString().toUpperCase();
      if (status != statusFilter.toUpperCase()) return false;
    }

    // Month Filter
    if (monthFilter != null) {
      final sDate = _parseDateTime(s['scheduledAt'] ?? s['date'] ?? s['createdAt']);
      if (sDate.year != monthFilter.year || sDate.month != monthFilter.month) {
        return false;
      }
    }

    // Search Query (Customer Name or Phone)
    if (query.isNotEmpty) {
      final name = (s['customerName'] ?? s['customer_name'] ?? s['name'] ?? '').toString().toLowerCase();
      final phone = (s['customerPhone'] ?? s['customer_phone'] ?? s['phone'] ?? '').toString().toLowerCase();
      return name.contains(query) || phone.contains(query);
    }

    return true;
  }).toList();
});

// ── Today's Sessions Provider ────────────────────────────────────────────────

final todaySessionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  if (_uid == null) return [];
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

  final snap = await _sessionsCol.get();

  final todayDocs = snap.docs.map((d) => {'id': d.id, ...d.data()}).where((s) {
    final dt = _parseDateTime(s['scheduledAt'] ?? s['date'] ?? s['createdAt']);
    return dt.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
           dt.isBefore(todayEnd.add(const Duration(seconds: 1)));
  }).toList();

  todayDocs.sort((a, b) {
    final dtA = _parseDateTime(a['scheduledAt'] ?? a['date'] ?? a['createdAt']);
    final dtB = _parseDateTime(b['scheduledAt'] ?? b['date'] ?? b['createdAt']);
    return dtA.compareTo(dtB);
  });

  return todayDocs;
});

// ── Customer Sessions Provider ───────────────────────────────────────────────

final customerSessionsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, customerId) async {
  if (_uid == null) return [];
  final snap = await _sessionsCol
      .where('customerId', isEqualTo: customerId)
      .get();

  final docs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  docs.sort((a, b) {
    final dtA = _parseDateTime(a['scheduledAt'] ?? a['date'] ?? a['createdAt']);
    final dtB = _parseDateTime(b['scheduledAt'] ?? b['date'] ?? b['createdAt']);
    return dtB.compareTo(dtA);
  });
  return docs;
});

// ── Single Session Detail Provider ───────────────────────────────────────────

final sessionDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final snap = await _sessionsCol.doc(id).get();
  if (!snap.exists) throw Exception('Session not found');
  return {'id': snap.id, ...snap.data()!};
});

// ── Helper Date Parser ───────────────────────────────────────────────────────

DateTime _parseDateTime(dynamic val) {
  if (val is Timestamp) return val.toDate();
  if (val is String) {
    final parsed = DateTime.tryParse(val);
    if (parsed != null) return parsed;
  }
  if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
  return DateTime.now();
}

// ── Sessions Repository Provider ─────────────────────────────────────────────

final sessionsRepositoryProvider =
    Provider((ref) => SessionsRepository(ref));

class SessionsRepository {
  final Ref _ref;
  SessionsRepository(this._ref);

  /// Create a new Booking / Session
  Future<String?> createBooking({
    required String? customerId,
    required String customerName,
    required String customerPhone,
    required DateTime scheduledAt,
    String sessionType = 'WET_CUPPING',
    String? bodyArea,
    String? therapistNotes,
    String? notes,
    String status = 'RESERVED', // RESERVED, CONFIRMED, COMPLETED
    double price = 0.0,
    int cupsUsed = 0,
  }) async {
    try {
      if (_uid == null) return null;

      String finalCustomerId = customerId ?? '';

      // If no customerId provided, look up or create client
      if (finalCustomerId.isEmpty) {
        final existingCust = await _customersCol
            .where('phone', isEqualTo: customerPhone.trim())
            .limit(1)
            .get();

        if (existingCust.docs.isNotEmpty) {
          finalCustomerId = existingCust.docs.first.id;
        } else {
          final newCustRef = await _customersCol.add({
            'fullName': customerName.trim(),
            'phone': customerPhone.trim(),
            'createdAt': FieldValue.serverTimestamp(),
            'totalSpent': 0.0,
            'totalCups': 0,
            'sessionCount': 0,
            'lastVisit': null,
          });
          finalCustomerId = newCustRef.id;
          _ref.invalidate(customersListProvider);
        }
      }

      final docRef = await _sessionsCol.add({
        'customerId': finalCustomerId,
        'customerName': customerName.trim(),
        'customerPhone': customerPhone.trim(),
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'date': Timestamp.fromDate(scheduledAt),
        'sessionType': sessionType,
        'bodyArea': bodyArea?.trim() ?? '',
        'therapistNotes': therapistNotes?.trim() ?? '',
        'notes': notes?.trim() ?? '',
        'status': status.toUpperCase(),
        'price': price,
        'pricePaid': price,
        'cupsUsed': cupsUsed,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _invalidateAll();
      return docRef.id;
    } catch (_) {
      return null;
    }
  }

  /// Direct session creation method (for forms)
  Future<bool> createSession(Map<String, dynamic> data) async {
    try {
      final customerId = data['customerId'] as String?;
      final sessionType = (data['sessionType'] ?? 'WET_CUPPING').toString();
      final price = (data['price'] ?? data['pricePaid'] ?? data['totalCost'] ?? 0) as num;
      final cupsUsed = (data['cupsUsed'] ?? 0) as num;
      final notes = (data['notes'] ?? '').toString();

      final res = await createBooking(
        customerId: customerId,
        customerName: data['customerName'] ?? 'عميل',
        customerPhone: data['customerPhone'] ?? '',
        scheduledAt: DateTime.now(),
        sessionType: sessionType,
        notes: notes,
        status: 'COMPLETED',
        price: price.toDouble(),
        cupsUsed: cupsUsed.toInt(),
      );

      if (res != null) {
        if (price > 0 || cupsUsed > 0) {
          await completeSession(
            sessionId: res,
            price: price.toDouble(),
            cupsUsed: cupsUsed.toInt(),
            notes: notes,
          );
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Complete Session Details (Log price, cups used, and complete the workflow)
  Future<bool> completeSession({
    required String sessionId,
    required double price,
    required int cupsUsed,
    String? notes,
    String? bodyArea,
    String? therapistNotes,
  }) async {
    try {
      if (_uid == null) return false;

      final sessionDoc = await _sessionsCol.doc(sessionId).get();
      if (!sessionDoc.exists) return false;
      final sessionData = sessionDoc.data()!;
      final customerId = sessionData['customerId'] as String?;
      final previousStatus = (sessionData['status'] ?? 'RESERVED').toString().toUpperCase();
      final previousPrice = (sessionData['price'] ?? sessionData['pricePaid'] ?? 0) as num;
      final previousCups = (sessionData['cupsUsed'] ?? 0) as num;

      final batch = _db.batch();

      // 1. Update Session Document
      final sessionRef = _sessionsCol.doc(sessionId);
      batch.update(sessionRef, {
        'status': 'COMPLETED',
        'price': price,
        'pricePaid': price,
        'cupsUsed': cupsUsed,
        if (notes != null) 'notes': notes.trim(),
        if (bodyArea != null) 'bodyArea': bodyArea.trim(),
        if (therapistNotes != null) 'therapistNotes': therapistNotes.trim(),
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update Customer Profile Stats if customerId exists
      if (customerId != null && customerId.isNotEmpty) {
        final custRef = _customersCol.doc(customerId);
        final priceDelta = previousStatus == 'COMPLETED' ? (price - previousPrice) : price;
        final cupsDelta = previousStatus == 'COMPLETED' ? (cupsUsed - previousCups) : cupsUsed;
        final countIncrement = previousStatus == 'COMPLETED' ? 0 : 1;

        batch.set(custRef, {
          'totalSpent': FieldValue.increment(priceDelta),
          'totalCups': FieldValue.increment(cupsDelta),
          'sessionCount': FieldValue.increment(countIncrement),
          'lastVisit': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // 3. Deduct Cups from Inventory
      if (cupsUsed > 0) {
        final cupsDelta = previousStatus == 'COMPLETED' ? (cupsUsed - previousCups.toInt()) : cupsUsed;
        if (cupsDelta != 0) {
          final inventorySnap = await _inventoryCol.where('name', isEqualTo: 'كؤوس الحجامة / Cupping Cups').limit(1).get();
          if (inventorySnap.docs.isNotEmpty) {
            batch.update(inventorySnap.docs.first.reference, {
              'quantity': FieldValue.increment(-cupsDelta),
            });
          } else {
            // Check any item containing 'cups' or 'كؤوس'
            final allInv = await _inventoryCol.get();
            final cupItem = allInv.docs.where((d) {
              final name = (d.data()['name'] ?? '').toString().toLowerCase();
              return name.contains('cup') || name.contains('كؤوس') || name.contains('ventouse');
            }).firstOrNull;

            if (cupItem != null) {
              batch.update(cupItem.reference, {
                'quantity': FieldValue.increment(-cupsDelta),
              });
            }
          }
        }
      }

      await batch.commit();
      _invalidateAll(customerId: customerId, sessionId: sessionId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Update Session Status (e.g. RESERVED -> CONFIRMED -> CANCELLED)
  Future<bool> updateStatus(String sessionId, String newStatus) async {
    try {
      if (_uid == null) return false;
      await _sessionsCol.doc(sessionId).update({
        'status': newStatus.toUpperCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _invalidateAll(sessionId: sessionId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// General Session Update
  Future<bool> updateSession(String sessionId, Map<String, dynamic> data) async {
    try {
      if (_uid == null) return false;
      await _sessionsCol.doc(sessionId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _invalidateAll(sessionId: sessionId, customerId: data['customerId'] as String?);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Delete Session
  Future<bool> deleteSession(String sessionId) async {
    try {
      if (_uid == null) return false;
      final doc = await _sessionsCol.doc(sessionId).get();
      final customerId = doc.data()?['customerId'] as String?;
      await _sessionsCol.doc(sessionId).delete();
      _invalidateAll(sessionId: sessionId, customerId: customerId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Invalidate providers
  void _invalidateAll({String? customerId, String? sessionId}) {
    _ref.invalidate(sessionsListProvider);
    _ref.invalidate(todaySessionsProvider);
    _ref.invalidate(dashboardStatsProvider);
    _ref.invalidate(dashboardChartsProvider);
    _ref.invalidate(dashboardAlertsProvider);
    _ref.invalidate(inventoryListProvider);
    if (customerId != null) {
      _ref.invalidate(customerProfileProvider(customerId));
      _ref.invalidate(customerSessionsProvider(customerId));
      _ref.invalidate(customersListProvider);
    }
    if (sessionId != null) {
      _ref.invalidate(sessionDetailProvider(sessionId));
    }
  }
}
