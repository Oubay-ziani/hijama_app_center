import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/inventory_provider.dart';

class RestockFormScreen extends ConsumerStatefulWidget {
  const RestockFormScreen({super.key});

  @override
  ConsumerState<RestockFormScreen> createState() => _RestockFormScreenState();
}

class _RestockFormScreenState extends ConsumerState<RestockFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedItemId;
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _supplierController = TextEditingController();
  final _invoiceController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    _supplierController.dispose();
    _invoiceController.dispose();
    super.dispose();
  }

  void _saveRestock() async {
    if (_selectedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item to restock'), backgroundColor: AppColors.warningRed),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final payload = {
      'itemId': _selectedItemId,
      'quantity': int.tryParse(_quantityController.text) ?? 0,
      'totalCost': double.tryParse(_costController.text) ?? 0.0,
      'supplier': _supplierController.text.trim(),
      'invoiceNumber': _invoiceController.text.trim(),
    };

    final success = await ref.read(inventoryRepositoryProvider).addRestockPurchase(payload);

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inventory restock recorded successfully!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        context.pop(); // Go back
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to record restock purchase'), backgroundColor: AppColors.warningRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Supply Restock'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Item Selection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Inventory Supply',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen),
                            ),
                            const SizedBox(height: 16),
                            inventoryAsync.when(
                              data: (items) {
                                return DropdownButtonFormField<String>(
                                  value: _selectedItemId,
                                  decoration: const InputDecoration(
                                    labelText: 'Select Item',
                                    prefixIcon: Icon(Icons.inventory_2_outlined),
                                  ),
                                  items: items.map((item) {
                                    return DropdownMenuItem<String>(
                                      value: item['id'],
                                      child: Text('${item['name']} (Current: ${item['quantity']})'),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedItemId = val;
                                      if (val != null) {
                                        // Auto-populate default supplier if known
                                        final matched = items.firstWhere((it) => it['id'] == val);
                                        _supplierController.text = matched['supplier'] ?? '';
                                      }
                                    });
                                  },
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
                              error: (e, _) => Text('Error loading inventory list: $e'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Billing & Quantities Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Restock Billing & Quantity',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Purchase Quantity',
                                prefixIcon: Icon(Icons.plus_one_outlined),
                              ),
                              validator: (value) {
                                if (value == null || int.tryParse(value) == null || int.parse(value) <= 0) {
                                  return 'Enter a valid positive count';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _costController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Total Cost Paid (DA)',
                                prefixIcon: Icon(Icons.payments_outlined),
                              ),
                              validator: (value) {
                                if (value == null || double.tryParse(value) == null || double.parse(value) < 0) {
                                  return 'Enter total purchase cost';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Supplier & Invoices Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Supplier Info & Invoices',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _supplierController,
                              decoration: const InputDecoration(
                                labelText: 'Supplier Name',
                                prefixIcon: Icon(Icons.storefront_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter supplier name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _invoiceController,
                              decoration: const InputDecoration(
                                labelText: 'Invoice / Receipt Number',
                                prefixIcon: Icon(Icons.receipt_long_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Restock Button
                    ElevatedButton(
                      onPressed: _saveRestock,
                      child: const Text('Record Stock Addition', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
