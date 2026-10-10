import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/pdf_excel_service.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../customers/providers/customers_provider.dart';
import '../../appointments/providers/appointments_provider.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../../sessions/providers/sessions_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FirebaseFirestore get _db => FirebaseFirestore.instance;
String? get _uid => FirebaseAuth.instance.currentUser?.uid;

DocumentReference<Map<String, dynamic>> get _userDoc =>
    _db.collection('users').doc(_uid);

// ── Reports Repository Provider ───────────────────────────────────────────────

final reportsRepositoryProvider =
    Provider((ref) => ReportsRepository(ref));

class ReportsRepository {
  final Ref _ref;
  ReportsRepository(this._ref);

  // Trigger Daily PDF compilation on-device
  Future<bool> compileDailyReport() async {
    try {
      final stats = await _ref.read(dashboardStatsProvider.future);
      return await PdfExcelService.generateDailyReport(stats);
    } catch (_) {
      return false;
    }
  }

  // Trigger Monthly PDF compilation on-device
  Future<bool> compileMonthlyPdfReport(DateTime month) async {
    try {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final snapSessions = await _userDoc.collection('sessions').get();
      final snapExpenses = await _userDoc.collection('expenses').get();
      final snapPurchases = await _userDoc.collection('purchases').get();

      final allSessions = snapSessions.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      final allExpenses = snapExpenses.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      final allPurchases = snapPurchases.docs.map((d) => {'id': d.id, ...d.data()}).toList();

      final monthSessions = allSessions.where((s) {
        final raw = s['scheduledAt'] ?? s['date'] ?? s['createdAt'];
        DateTime d = DateTime.now();
        if (raw is Timestamp) {
          d = raw.toDate();
        } else if (raw is String) {
          d = DateTime.tryParse(raw) ?? DateTime.now();
        }
        return d.isAfter(start.subtract(const Duration(seconds: 1))) &&
               d.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();

      final monthCompleted = monthSessions.where((s) {
        return (s['status'] ?? 'COMPLETED').toString().toUpperCase() == 'COMPLETED';
      }).toList();

      final monthExpenses = allExpenses.where((e) {
        final raw = e['date'] ?? e['createdAt'];
        DateTime d = DateTime.now();
        if (raw is Timestamp) {
          d = raw.toDate();
        } else if (raw is String) {
          d = DateTime.tryParse(raw) ?? DateTime.now();
        }
        return d.isAfter(start.subtract(const Duration(seconds: 1))) &&
               d.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();

      double totalRevenue = monthCompleted.fold(0.0, (acc, s) {
        return acc + ((s['price'] ?? s['pricePaid'] ?? s['cost'] ?? 0) as num).toDouble();
      });

      int totalCups = monthCompleted.fold(0, (acc, s) {
        return acc + ((s['cupsUsed'] ?? s['cups_used'] ?? 0) as num).toInt();
      });

      double totalExpenses = monthExpenses.fold(0.0, (acc, e) {
        return acc + ((e['amount'] ?? 0) as num).toDouble();
      });

      for (final p in allPurchases) {
        final raw = p['date'] ?? p['createdAt'];
        DateTime d = DateTime.now();
        if (raw is Timestamp) {
          d = raw.toDate();
        } else if (raw is String) {
          d = DateTime.tryParse(raw) ?? DateTime.now();
        }
        if (d.isAfter(start.subtract(const Duration(seconds: 1))) && d.isBefore(end.add(const Duration(seconds: 1)))) {
          totalExpenses += ((p['totalCost'] ?? 0) as num).toDouble();
        }
      }

      return await PdfExcelService.generateMonthlyPdfReport(
        clinicName: 'مركز الحجامة برو / Hijama Center Pro',
        month: month,
        totalSessions: monthCompleted.length,
        totalRevenue: totalRevenue,
        totalCups: totalCups,
        totalExpenses: totalExpenses,
        netProfit: totalRevenue - totalExpenses,
        sessions: monthCompleted,
        expenses: monthExpenses,
      );
    } catch (_) {
      return false;
    }
  }

  // Trigger Inventory PDF compilation on-device
  Future<bool> compileInventoryReport() async {
    try {
      final items = await _ref.read(inventoryListProvider.future);
      return await PdfExcelService.generateInventoryReport(items);
    } catch (_) {
      return false;
    }
  }

  // Trigger Monthly Excel sheet compilation on-device
  Future<bool> compileMonthlyExcel() async {
    try {
      final now = DateTime.now();
      final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
      final cutoff = Timestamp.fromDate(oneMonthAgo);

      // Retrieve documents from the past 30 days from Firestore
      final sessionsSnap = await _userDoc
          .collection('sessions')
          .where('createdAt', isGreaterThanOrEqualTo: cutoff)
          .get();
      final expensesSnap = await _userDoc
          .collection('expenses')
          .where('createdAt', isGreaterThanOrEqualTo: cutoff)
          .get();
      final purchasesSnap = await _userDoc
          .collection('purchases')
          .where('createdAt', isGreaterThanOrEqualTo: cutoff)
          .get();

      final sessions = sessionsSnap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();
      final expenses = expensesSnap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();
      final purchases = purchasesSnap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();

      return await PdfExcelService.generateMonthlyFinancialExcel(
          sessions, expenses, purchases);
    } catch (_) {
      return false;
    }
  }

  // Trigger Session Invoice PDF compilation on-device
  Future<bool> compileSessionInvoice(String sessionId) async {
    try {
      final session =
          await _ref.read(sessionDetailProvider(sessionId).future);
      return await PdfExcelService.generateSessionInvoice(session);
    } catch (_) {
      return false;
    }
  }

  // Export full backup as JSON from Firestore
  Future<Map<String, dynamic>?> exportBackup() async {
    try {
      final uid = _uid;
      if (uid == null) return null;

      final collections = [
        'customers',
        'sessions',
        'appointments',
        'inventory',
        'purchases',
        'expenses',
        'employees',
      ];

      final backup = <String, dynamic>{'uid': uid};

      for (final col in collections) {
        final snap = await _userDoc.collection(col).get();
        backup[col] =
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      }

      return {'success': true, 'data': backup};
    } catch (_) {
      return null;
    }
  }

  // Import backup JSON into Firestore (batch writes)
  Future<bool> importBackup(Map<String, dynamic> backupData) async {
    try {
      final uid = _uid;
      if (uid == null) return false;

      final data =
          backupData['data'] as Map<String, dynamic>? ?? backupData;

      final batch = _db.batch();

      final collections = [
        'customers',
        'sessions',
        'appointments',
        'inventory',
        'purchases',
        'expenses',
        'employees',
      ];

      for (final col in collections) {
        final items = data[col] as List<dynamic>? ?? [];
        for (final item in items) {
          final map = Map<String, dynamic>.from(item as Map);
          final id = map.remove('id') as String?;
          final ref = id != null
              ? _userDoc.collection(col).doc(id)
              : _userDoc.collection(col).doc();
          batch.set(ref, map, SetOptions(merge: true));
        }
      }

      await batch.commit();

      // Invalidate all app states to reload fresh data from imported backup
      _ref.invalidate(dashboardStatsProvider);
      _ref.invalidate(dashboardChartsProvider);
      _ref.invalidate(dashboardAlertsProvider);
      _ref.invalidate(customersListProvider);
      _ref.invalidate(appointmentsListProvider);
      _ref.invalidate(inventoryListProvider);
      return true;
    } catch (_) {
      return false;
    }
  }
}
