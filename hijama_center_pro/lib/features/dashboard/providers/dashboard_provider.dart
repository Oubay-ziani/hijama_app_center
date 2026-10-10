import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FirebaseFirestore get _db => FirebaseFirestore.instance;
String? get _uid => FirebaseAuth.instance.currentUser?.uid;

DocumentReference<Map<String, dynamic>>? get _userDoc {
  final uid = _uid;
  if (uid == null) return null;
  return _db.collection('users').doc(uid);
}

// ── Dashboard Stats Provider ──────────────────────────────────────────────────

final dashboardStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final doc = _userDoc;
  if (doc == null) {
    return {
      'bookingsToday': 0,
      'revenueToday': 0.0,
      'cupsToday': 0,
      'revenueThisMonth': 0.0,
      'cupsThisMonth': 0,
      'totalCustomers': 0,
      'totalSessions': 0,
      'totalExpenses': 0.0,
      'netProfit': 0.0,
      'cupStock': 0,
      'isLowStock': false,
    };
  }

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  final results = await Future.wait([
    doc.collection('sessions').get(),
    doc.collection('customers').get(),
    doc.collection('expenses').get(),
    doc.collection('inventory').get(),
  ]);

  final allSessions = results[0].docs.map((d) => {'id': d.id, ...d.data()}).toList();
  final allCustomers = results[1].docs;
  final allExpenses = results[2].docs.map((d) => {'id': d.id, ...d.data()}).toList();
  final allInventory = results[3].docs.map((d) => {'id': d.id, ...d.data()}).toList();

  // 1. Today's Sessions & Bookings
  final todaySessions = allSessions.where((s) {
    final dt = _parseDateTime(s['scheduledAt'] ?? s['date'] ?? s['createdAt']);
    return dt.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
           dt.isBefore(todayEnd.add(const Duration(seconds: 1)));
  }).toList();

  final todayCompleted = todaySessions.where((s) {
    final status = (s['status'] ?? 'COMPLETED').toString().toUpperCase();
    return status == 'COMPLETED';
  }).toList();

  final double revenueToday = todayCompleted.fold(0.0, (acc, s) {
    return acc + ((s['price'] ?? s['pricePaid'] ?? s['cost'] ?? 0) as num).toDouble();
  });

  final int cupsToday = todayCompleted.fold(0, (acc, s) {
    return acc + ((s['cupsUsed'] ?? s['cups_used'] ?? 0) as num).toInt();
  });

  // 2. This Month's Completed Sessions & Revenue
  final monthSessions = allSessions.where((s) {
    final dt = _parseDateTime(s['scheduledAt'] ?? s['date'] ?? s['createdAt']);
    return dt.isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
           dt.isBefore(monthEnd.add(const Duration(seconds: 1)));
  }).toList();

  final monthCompleted = monthSessions.where((s) {
    final status = (s['status'] ?? 'COMPLETED').toString().toUpperCase();
    return status == 'COMPLETED';
  }).toList();

  final double revenueThisMonth = monthCompleted.fold(0.0, (acc, s) {
    return acc + ((s['price'] ?? s['pricePaid'] ?? s['cost'] ?? 0) as num).toDouble();
  });

  final int cupsThisMonth = monthCompleted.fold(0, (acc, s) {
    return acc + ((s['cupsUsed'] ?? s['cups_used'] ?? 0) as num).toInt();
  });

  // 3. Overall Totals
  final double totalRevenue = allSessions.where((s) => (s['status'] ?? 'COMPLETED').toString().toUpperCase() == 'COMPLETED').fold(0.0, (acc, s) {
    return acc + ((s['price'] ?? s['pricePaid'] ?? s['cost'] ?? 0) as num).toDouble();
  });

  final double totalExpenses = allExpenses.fold(0.0, (acc, d) {
    return acc + ((d['amount'] ?? 0) as num).toDouble();
  });

  // 4. Inventory Stock & Low Stock Check
  int cupStock = 0;
  bool isLowStock = false;
  for (final item in allInventory) {
    final name = (item['name'] ?? '').toString().toLowerCase();
    final qty = ((item['quantity'] ?? 0) as num).toInt();
    final threshold = ((item['minThreshold'] ?? 10) as num).toInt();
    if (name.contains('cup') || name.contains('كؤوس') || name.contains('ventouse') || allInventory.length == 1) {
      cupStock += qty;
      if (qty <= threshold) {
        isLowStock = true;
      }
    }
  }

  return {
    'bookingsToday': todaySessions.length,
    'revenueToday': revenueToday,
    'cupsToday': cupsToday,
    'revenueThisMonth': revenueThisMonth,
    'cupsThisMonth': cupsThisMonth,
    'totalCustomers': allCustomers.length,
    'totalSessions': allSessions.length,
    'totalRevenue': totalRevenue,
    'totalExpenses': totalExpenses,
    'netProfit': totalRevenue - totalExpenses,
    'cupStock': cupStock,
    'isLowStock': isLowStock || (allInventory.isNotEmpty && cupStock <= 15),
  };
});

// ── Charts Data Provider (Weekly revenue breakdown) ──────────────────────────

final dashboardChartsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final doc = _userDoc;
  final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  if (doc == null) {
    return {
      'weeklyRevenue': daysOfWeek.map((d) => {'day': d, 'revenue': 0.0}).toList(),
    };
  }

  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final weekStartMidnight = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

  final snap = await doc.collection('sessions').get();
  final sessionsDocs = snap.docs.map((d) => d.data()).where((s) {
    final dt = _parseDateTime(s['scheduledAt'] ?? s['date'] ?? s['createdAt']);
    return dt.isAfter(weekStartMidnight.subtract(const Duration(seconds: 1)));
  }).toList();

  final Map<int, double> weekdayRevenue = {
    for (int i = 1; i <= 7; i++) i: 0.0,
  };

  for (final data in sessionsDocs) {
    final status = (data['status'] ?? 'COMPLETED').toString().toUpperCase();
    if (status != 'COMPLETED') continue;

    final dt = _parseDateTime(data['scheduledAt'] ?? data['date'] ?? data['createdAt']);
    final day = dt.weekday; // 1 = Mon, 7 = Sun
    final amount = ((data['price'] ?? data['pricePaid'] ?? data['cost'] ?? 0) as num).toDouble();
    weekdayRevenue[day] = (weekdayRevenue[day] ?? 0.0) + amount;
  }

  final List<Map<String, dynamic>> weeklyList = [];
  for (int i = 1; i <= 7; i++) {
    weeklyList.add({
      'day': daysOfWeek[i - 1],
      'revenue': (weekdayRevenue[i] ?? 0.0) > 0 ? weekdayRevenue[i]! : 0.0,
    });
  }

  return {
    'weeklyRevenue': weeklyList,
  };
});

// ── Low Stock Alerts Provider ────────────────────────────────────────────────

final dashboardAlertsProvider = FutureProvider<List<dynamic>>((ref) async {
  final doc = _userDoc;
  if (doc == null) return [];

  final snap = await doc.collection('inventory').get();
  final lowItems = snap.docs
      .map((d) => {'id': d.id, ...d.data()})
      .where((item) {
        final qty = (item['quantity'] ?? 0) as num;
        final threshold = (item['minThreshold'] ?? 10) as num;
        return qty <= threshold;
      })
      .toList();

  return lowItems.map((item) {
    final qty = item['quantity'] ?? 0;
    final name = item['name'] ?? 'كؤوس الحجامة';
    final isCritical = (qty as num) <= 5;
    return {
      'status': isCritical ? 'CRITICAL' : 'WARNING',
      'message': '⚠️ المخزون منخفض: تبقى $qty كؤوس فقط ($name)',
    };
  }).toList();
});

DateTime _parseDateTime(dynamic val) {
  if (val is Timestamp) return val.toDate();
  if (val is String) {
    final parsed = DateTime.tryParse(val);
    if (parsed != null) return parsed;
  }
  if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
  return DateTime.now();
}
