import 'package:flutter/material.dart' show DateTimeRange;
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

// ── Period Enum & State ───────────────────────────────────────────────────────

enum StatsPeriodType {
  today,
  thisWeek,
  thisMonth,
  specificMonth,
  customRange,
}

class StatsPeriodFilter {
  final StatsPeriodType type;
  final DateTime? specificMonth; // year & month
  final DateTimeRange? customRange;

  const StatsPeriodFilter({
    required this.type,
    this.specificMonth,
    this.customRange,
  });

  DateTimeRange getRange() {
    final now = DateTime.now();
    switch (type) {
      case StatsPeriodType.today:
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case StatsPeriodType.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case StatsPeriodType.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case StatsPeriodType.specificMonth:
        final m = specificMonth ?? now;
        final start = DateTime(m.year, m.month, 1);
        final end = DateTime(m.year, m.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case StatsPeriodType.customRange:
        if (customRange != null) {
          final start = DateTime(customRange!.start.year, customRange!.start.month, customRange!.start.day);
          final end = DateTime(customRange!.end.year, customRange!.end.month, customRange!.end.day, 23, 59, 59);
          return DateTimeRange(start: start, end: end);
        }
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
    }
  }
}

final selectedStatsFilterProvider = StateProvider<StatsPeriodFilter>((ref) {
  return const StatsPeriodFilter(type: StatsPeriodType.thisMonth);
});

// ── Daily Data Point for Charts ──────────────────────────────────────────────

class DailyChartDataPoint {
  final DateTime date;
  final String label;
  final double revenue;
  final int sessionsCount;
  final int cupsUsed;

  DailyChartDataPoint({
    required this.date,
    required this.label,
    required this.revenue,
    required this.sessionsCount,
    required this.cupsUsed,
  });
}

// ── Comprehensive Statistics Model ────────────────────────────────────────────

class StatisticsData {
  final DateTimeRange range;
  final int totalBookings;
  final int completedSessions;
  final double totalRevenue; // Chiffre d'affaires
  final int totalCupsUsed;
  final double totalExpenses;
  final double netProfit;
  final double avgSessionPrice;
  final double avgCupsPerSession;
  final List<DailyChartDataPoint> dailyData;
  final Map<String, double> expensesByCategory;
  final int currentCupStock;
  final int totalCupsPurchased;
  final bool isLowStock;

  StatisticsData({
    required this.range,
    required this.totalBookings,
    required this.completedSessions,
    required this.totalRevenue,
    required this.totalCupsUsed,
    required this.totalExpenses,
    required this.netProfit,
    required this.avgSessionPrice,
    required this.avgCupsPerSession,
    required this.dailyData,
    required this.expensesByCategory,
    required this.currentCupStock,
    required this.totalCupsPurchased,
    required this.isLowStock,
  });
}

// ── Statistics Provider ───────────────────────────────────────────────────────

final statisticsSummaryProvider = FutureProvider<StatisticsData>((ref) async {
  final doc = _userDoc;
  final filter = ref.watch(selectedStatsFilterProvider);
  final range = filter.getRange();

  if (doc == null) {
    return StatisticsData(
      range: range,
      totalBookings: 0,
      completedSessions: 0,
      totalRevenue: 0.0,
      totalCupsUsed: 0,
      totalExpenses: 0.0,
      netProfit: 0.0,
      avgSessionPrice: 0.0,
      avgCupsPerSession: 0.0,
      dailyData: [],
      expensesByCategory: {},
      currentCupStock: 0,
      totalCupsPurchased: 0,
      isLowStock: false,
    );
  }

  final results = await Future.wait([
    doc.collection('sessions').get(),
    doc.collection('expenses').get(),
    doc.collection('inventory').get(),
    doc.collection('purchases').get(),
  ]);

  final allSessions = results[0].docs.map((d) => {'id': d.id, ...d.data()}).toList();
  final allExpenses = results[1].docs.map((d) => {'id': d.id, ...d.data()}).toList();
  final allInventory = results[2].docs.map((d) => {'id': d.id, ...d.data()}).toList();
  final allPurchases = results[3].docs.map((d) => {'id': d.id, ...d.data()}).toList();

  // Filter sessions in date range
  final filteredSessions = allSessions.where((s) {
    final dt = _parseDateTime(s['scheduledAt'] ?? s['date'] ?? s['createdAt']);
    return dt.isAfter(range.start.subtract(const Duration(seconds: 1))) &&
           dt.isBefore(range.end.add(const Duration(seconds: 1)));
  }).toList();

  // Filter expenses in date range
  final filteredExpenses = allExpenses.where((e) {
    final dt = _parseDateTime(e['date'] ?? e['createdAt']);
    return dt.isAfter(range.start.subtract(const Duration(seconds: 1))) &&
           dt.isBefore(range.end.add(const Duration(seconds: 1)));
  }).toList();

  // Filter purchases in date range
  final filteredPurchases = allPurchases.where((p) {
    final dt = _parseDateTime(p['date'] ?? p['createdAt']);
    return dt.isAfter(range.start.subtract(const Duration(seconds: 1))) &&
           dt.isBefore(range.end.add(const Duration(seconds: 1)));
  }).toList();

  // Calculations
  final totalBookings = filteredSessions.length;
  final completedSessionsList = filteredSessions.where((s) {
    final status = (s['status'] ?? 'COMPLETED').toString().toUpperCase();
    return status == 'COMPLETED';
  }).toList();

  final completedSessions = completedSessionsList.length;

  final totalRevenue = completedSessionsList.fold<double>(0.0, (acc, s) {
    final p = (s['price'] ?? s['pricePaid'] ?? s['cost'] ?? 0) as num;
    return acc + p.toDouble();
  });

  final totalCupsUsed = completedSessionsList.fold<int>(0, (acc, s) {
    final c = (s['cupsUsed'] ?? s['cups_used'] ?? 0) as num;
    return acc + c.toInt();
  });

  // Expenses summary
  final Map<String, double> expensesByCategory = {};
  double totalExpenses = 0.0;

  for (final e in filteredExpenses) {
    final cat = (e['category'] ?? 'أخرى / Other').toString();
    final amt = ((e['amount'] ?? 0) as num).toDouble();
    totalExpenses += amt;
    expensesByCategory[cat] = (expensesByCategory[cat] ?? 0.0) + amt;
  }

  // Add inventory purchases to total expenses if not counted separately
  for (final p in filteredPurchases) {
    final amt = ((p['totalCost'] ?? 0) as num).toDouble();
    if (amt > 0) {
      totalExpenses += amt;
      expensesByCategory['كؤوس ومستلزمات / Supplies'] =
          (expensesByCategory['كؤوس ومستلزمات / Supplies'] ?? 0.0) + amt;
    }
  }

  final netProfit = totalRevenue - totalExpenses;
  final avgSessionPrice = completedSessions > 0 ? (totalRevenue / completedSessions) : 0.0;
  final avgCupsPerSession = completedSessions > 0 ? (totalCupsUsed / completedSessions) : 0.0;

  // Build Daily Chart Data
  final daysDiff = range.end.difference(range.start).inDays + 1;
  final List<DailyChartDataPoint> dailyData = [];

  if (daysDiff <= 31) {
    for (int i = 0; i < daysDiff; i++) {
      final curDate = range.start.add(Duration(days: i));
      final dayStart = DateTime(curDate.year, curDate.month, curDate.day);
      final dayEnd = DateTime(curDate.year, curDate.month, curDate.day, 23, 59, 59);

      final daySessions = completedSessionsList.where((s) {
        final dt = _parseDateTime(s['scheduledAt'] ?? s['date'] ?? s['createdAt']);
        return dt.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
               dt.isBefore(dayEnd.add(const Duration(seconds: 1)));
      }).toList();

      final dayRevenue = daySessions.fold<double>(0.0, (acc, s) => acc + ((s['price'] ?? s['pricePaid'] ?? 0) as num).toDouble());
      final dayCups = daySessions.fold<int>(0, (acc, s) => acc + ((s['cupsUsed'] ?? s['cups_used'] ?? 0) as num).toInt());

      dailyData.add(DailyChartDataPoint(
        date: curDate,
        label: '${curDate.day}/${curDate.month}',
        revenue: dayRevenue,
        sessionsCount: daySessions.length,
        cupsUsed: dayCups,
      ));
    }
  }

  // Inventory & Cup stock calculation
  int currentCupStock = 0;
  int totalCupsPurchased = 0;
  bool isLowStock = false;

  for (final item in allInventory) {
    final name = (item['name'] ?? '').toString().toLowerCase();
    final qty = ((item['quantity'] ?? 0) as num).toInt();
    final threshold = ((item['minThreshold'] ?? 10) as num).toInt();

    if (name.contains('cup') || name.contains('كؤوس') || name.contains('ventouse') || allInventory.length == 1) {
      currentCupStock += qty;
      if (qty <= threshold) {
        isLowStock = true;
      }
    }
  }

  for (final p in allPurchases) {
    totalCupsPurchased += ((p['quantity'] ?? 0) as num).toInt();
  }

  return StatisticsData(
    range: range,
    totalBookings: totalBookings,
    completedSessions: completedSessions,
    totalRevenue: totalRevenue,
    totalCupsUsed: totalCupsUsed,
    totalExpenses: totalExpenses,
    netProfit: netProfit,
    avgSessionPrice: avgSessionPrice,
    avgCupsPerSession: avgCupsPerSession,
    dailyData: dailyData,
    expensesByCategory: expensesByCategory,
    currentCupStock: currentCupStock,
    totalCupsPurchased: totalCupsPurchased,
    isLowStock: isLowStock || currentCupStock <= 15,
  );
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
