import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/inventory_provider.dart';
import '../../auth/providers/auth_provider.dart';

class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  final _supplierController = TextEditingController();
  final _thresholdController = TextEditingController();

  void _showItemDialog([Map<String, dynamic>? item]) {
    final isEditing = item != null;
    if (isEditing) {
      _nameController.text = item['name'] ?? '';
      _qtyController.text = (item['quantity'] ?? 0).toString();
      _priceController.text = (item['purchase_price'] ?? 0.0).toString();
      _supplierController.text = item['supplier'] ?? '';
      _thresholdController.text = (item['min_threshold'] ?? 10).toString();
    } else {
      _nameController.clear();
      _qtyController.clear();
      _priceController.clear();
      _supplierController.clear();
      _thresholdController.text = '10';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Inventory Item' : 'Register New Supply'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
              ),
              const SizedBox(height: 8),
              if (!isEditing) ...[
                TextField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Initial Quantity'),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Purchase Price (DA)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _supplierController,
                decoration: const InputDecoration(labelText: 'Supplier'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _thresholdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Low Stock Threshold (Min)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final payload = {
                'name': _nameController.text.trim(),
                'purchasePrice': double.tryParse(_priceController.text) ?? 0.0,
                'supplier': _supplierController.text.trim(),
                'minThreshold': int.tryParse(_thresholdController.text) ?? 10,
              };
              if (!isEditing) {
                payload['quantity'] = int.tryParse(_qtyController.text) ?? 0;
              }

              final repo = ref.read(inventoryRepositoryProvider);
              bool success;
              if (isEditing) {
                success = await repo.updateItem(item['id'], payload);
              } else {
                success = await repo.createItem(payload);
              }

              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? 'Item updated!' : 'Item registered successfully!'),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to save item details'), backgroundColor: AppColors.warningRed),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _supplierController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final inventoryAsync = ref.watch(inventoryListProvider);
    final userRole = ref.watch(authProvider.notifier).role;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventory),
        actions: [
          if (userRole == 'ADMIN') ...[
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showItemDialog(),
            ),
            IconButton(
              icon: const Icon(Icons.shopping_cart_checkout),
              onPressed: () {
                context.go('/inventory/restock');
              },
              tooltip: 'Restock Purchases',
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(inventoryListProvider);
        },
        child: inventoryAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Text('No supplies registered.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final name = item['name']?.toString() ?? 'Item';
                final quantity = item['quantity'] ?? 0;
                final price = double.tryParse(item['purchasePrice']?.toString() ?? item['purchase_price']?.toString() ?? '0') ?? 0.0;
                final supplier = item['supplier']?.toString() ?? 'Unknown';
                final minThresh = item['minThreshold'] ?? 10;
                final num qty = quantity is num ? quantity : (num.tryParse(quantity.toString()) ?? 0);
                final num thresh = minThresh is num ? minThresh : (num.tryParse(minThresh.toString()) ?? 10);
                String status = item['status']?.toString() ?? (qty <= 2 ? 'CRITICAL' : (qty <= thresh ? 'WARNING' : 'NORMAL'));

                Color levelColor;
                String statusLabel;
                if (status == 'CRITICAL') {
                  levelColor = AppColors.warningRed;
                  statusLabel = 'CRITICAL STOCK';
                } else if (status == 'WARNING') {
                  levelColor = AppColors.alertOrange;
                  statusLabel = 'LOW STOCK';
                } else {
                  levelColor = Colors.green;
                  statusLabel = 'OK';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: levelColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: levelColor, width: 0.5),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: levelColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Stock Count: $quantity units', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('Unit Price: ${price.toStringAsFixed(0)} DA'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Supplier: $supplier', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    trailing: userRole == 'ADMIN'
                        ? IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _showItemDialog(item),
                          )
                        : null,
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
          error: (e, _) => Center(child: Text('Error loading inventory: $e')),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 3) return;
          if (index == 0) context.go('/dashboard');
          if (index == 1) context.go('/customers');
          if (index == 2) context.go('/appointments');
          if (index == 4) context.go('/settings');
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.dashboard), label: l10n.dashboard),
          BottomNavigationBarItem(icon: const Icon(Icons.people), label: l10n.customers),
          BottomNavigationBarItem(icon: const Icon(Icons.calendar_today), label: l10n.appointments),
          BottomNavigationBarItem(icon: const Icon(Icons.inventory), label: l10n.inventory),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: l10n.settings),
        ],
      ),
    );
  }
}
