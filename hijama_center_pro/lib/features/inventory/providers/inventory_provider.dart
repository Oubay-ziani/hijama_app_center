import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/providers/dashboard_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FirebaseFirestore get _db => FirebaseFirestore.instance;
String? get _uid => FirebaseAuth.instance.currentUser?.uid;

CollectionReference<Map<String, dynamic>> get _inventoryCol =>
    _db.collection('users').doc(_uid).collection('inventory');

CollectionReference<Map<String, dynamic>> get _purchasesCol =>
    _db.collection('users').doc(_uid).collection('purchases');

// ── Inventory Items List Provider ─────────────────────────────────────────────

final inventoryListProvider = FutureProvider<List<dynamic>>((ref) async {
  final snap = await _inventoryCol.orderBy('name').get();
  return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
});

// ── Low Stock Alerts Provider ────────────────────────────────────────────────

final lowStockAlertsProvider = FutureProvider<List<dynamic>>((ref) async {
  final snap = await _inventoryCol.get();
  final items = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  return items.where((item) {
    final qty = (item['quantity'] ?? 0) as num;
    final threshold = (item['minThreshold'] ?? 10) as num;
    return qty <= threshold;
  }).toList();
});

// ── Inventory Repository Provider ─────────────────────────────────────────────

final inventoryRepositoryProvider =
    Provider((ref) => InventoryRepository(ref));

class InventoryRepository {
  final Ref _ref;
  InventoryRepository(this._ref);

  Future<bool> createItem(Map<String, dynamic> data) async {
    try {
      await _inventoryCol.add({
        'name': data['name'] ?? '',
        'quantity': int.tryParse(data['quantity']?.toString() ?? '0') ?? 0,
        'purchasePrice':
            double.tryParse(data['purchasePrice']?.toString() ?? '0') ?? 0.0,
        'supplier': data['supplier'] ?? '',
        'minThreshold':
            int.tryParse(data['minThreshold']?.toString() ?? '10') ?? 10,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _ref.invalidate(inventoryListProvider);
      _ref.invalidate(dashboardStatsProvider);
      _ref.invalidate(dashboardAlertsProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateItem(String id, Map<String, dynamic> data) async {
    try {
      await _inventoryCol.doc(id).update({
        'name': data['name'],
        'purchasePrice':
            double.tryParse(data['purchasePrice']?.toString() ?? '0') ?? 0.0,
        'supplier': data['supplier'],
        'minThreshold':
            int.tryParse(data['minThreshold']?.toString() ?? '10') ?? 10,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _ref.invalidate(inventoryListProvider);
      _ref.invalidate(dashboardStatsProvider);
      _ref.invalidate(dashboardAlertsProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addRestockPurchase(Map<String, dynamic> data) async {
    final String? itemId = data['itemId'];
    final int qty = int.tryParse(data['quantity']?.toString() ?? '0') ?? 0;
    if (itemId == null || qty <= 0) return false;

    try {
      // Log purchase record
      await _purchasesCol.add({
        'itemId': itemId,
        'quantity': qty,
        'totalCost':
            double.tryParse(data['totalCost']?.toString() ?? '0') ?? 0.0,
        'supplier': data['supplier'] ?? '',
        'invoiceNumber': data['invoiceNumber'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Increment quantity on inventory item
      await _inventoryCol.doc(itemId).update({
        'quantity': FieldValue.increment(qty),
      });

      _ref.invalidate(inventoryListProvider);
      _ref.invalidate(dashboardStatsProvider);
      _ref.invalidate(dashboardAlertsProvider);
      return true;
    } catch (_) {
      return false;
    }
  }
}
