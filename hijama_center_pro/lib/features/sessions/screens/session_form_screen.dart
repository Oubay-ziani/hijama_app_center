import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../customers/providers/customers_provider.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../providers/sessions_provider.dart';

class SessionFormScreen extends ConsumerStatefulWidget {
  final String? customerId;
  const SessionFormScreen({super.key, this.customerId});

  @override
  ConsumerState<SessionFormScreen> createState() => _SessionFormScreenState();
}

class _SessionFormScreenState extends ConsumerState<SessionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String _sessionType = 'WET_CUPPING';
  final _pricePaidController = TextEditingController(text: '0');
  final _totalCostController = TextEditingController(text: '1500');
  final _cupsUsedController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  // Selected materials mapping: { itemId: quantity }
  final Map<String, int> _selectedMaterials = {};
  
  bool _isLoading = false;
  String? _customerName;

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) {
      _loadCustomerName();
    }
  }

  void _loadCustomerName() async {
    try {
      final customer = await ref.read(customerProfileProvider(widget.customerId!).future);
      setState(() {
        _customerName = customer['full_name'];
        // Apply discount if loyalty discount_pct is active
        final discountPct = double.parse(customer['loyalty']?['discount_pct']?.toString() ?? '0');
        if (discountPct > 0) {
          final originalCost = double.tryParse(_totalCostController.text) ?? 1500.0;
          final discountedCost = originalCost * (1 - (discountPct / 100.0));
          _totalCostController.text = discountedCost.toStringAsFixed(0);
          _pricePaidController.text = discountedCost.toStringAsFixed(0);
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _pricePaidController.dispose();
    _totalCostController.dispose();
    _cupsUsedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitSession() async {
    if (widget.customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No patient selected.'), backgroundColor: AppColors.warningRed),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Format materials list: [{ id, quantityUsed }]
    final materialsList = _selectedMaterials.entries
        .map((e) => {'id': e.key, 'quantityUsed': e.value})
        .toList();

    final payload = {
      'customerId': widget.customerId,
      'sessionType': _sessionType,
      'pricePaid': double.tryParse(_pricePaidController.text) ?? 0.0,
      'totalCost': double.tryParse(_totalCostController.text) ?? 0.0,
      'cupsUsed': int.tryParse(_cupsUsedController.text) ?? 0,
      'notes': _notesController.text.trim(),
      'materials': materialsList,
    };

    final success = await ref.read(sessionsRepositoryProvider).createSession(payload);

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session recorded successfully!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        // Refresh customer details
        ref.invalidate(customerProfileProvider(widget.customerId!));
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save session. Check item stock levels.'),
            backgroundColor: AppColors.warningRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final inventoryAsync = ref.watch(inventoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recordSession),
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
                    // Patient Indicator Header
                    if (_customerName != null)
                      Card(
                        color: AppColors.primaryGreen.withOpacity(0.06),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: AppColors.primaryGreen, width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              const Icon(Icons.person, color: AppColors.primaryGreen),
                              const SizedBox(width: 12),
                              Text(
                                'Recording treatment for: $_customerName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // 1. Session Type & Notes Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Treatment Details',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _sessionType,
                              decoration: const InputDecoration(
                                labelText: 'Treatment Type',
                                prefixIcon: Icon(Icons.spa_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'DRY_CUPPING', child: Text('Dry Cupping')),
                                DropdownMenuItem(value: 'WET_CUPPING', child: Text('Wet Cupping')),
                                DropdownMenuItem(value: 'MASSAGE', child: Text('Massage')),
                                DropdownMenuItem(value: 'RELAXATION', child: Text('Relaxation')),
                                DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _sessionType = val);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _cupsUsedController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.cupsUsed,
                                prefixIcon: const Icon(Icons.circle_outlined),
                              ),
                              validator: (value) {
                                if (value == null || int.tryParse(value) == null) {
                                  return 'Enter a number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Observation / Notes',
                                prefixIcon: Icon(Icons.edit_note_outlined),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Billing details Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Financial Billing (DA)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _totalCostController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Total Session Cost',
                                prefixIcon: Icon(Icons.money),
                              ),
                              onChanged: (v) {
                                setState(() {}); // Refresh calculated debt
                              },
                              validator: (value) {
                                if (value == null || double.tryParse(value) == null) {
                                  return 'Enter total cost';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _pricePaidController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Amount Paid Now',
                                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                              ),
                              onChanged: (v) {
                                setState(() {}); // Refresh calculated debt
                              },
                              validator: (value) {
                                if (value == null || double.tryParse(value) == null) {
                                  return 'Enter paid amount';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Outstanding Debt Calculator Banner
                            (() {
                              final cost = double.tryParse(_totalCostController.text) ?? 0.0;
                              final paid = double.tryParse(_pricePaidController.text) ?? 0.0;
                              final debt = cost - paid;

                              if (debt > 0) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.warningRed.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.warningRed.withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline, color: AppColors.warningRed, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Outstanding Debt: ${debt.toStringAsFixed(0)} DA',
                                        style: const TextStyle(
                                          color: AppColors.warningRed,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Fully Paid (No Debt)',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }()),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Consumables Section Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Consumables Checklist',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Select medical accessories used in this session to automatically deduct from stock counts.',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 16),

                            inventoryAsync.when(
                              data: (items) {
                                return Column(
                                  children: [
                                    // Dropdown selector to add an item
                                    DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: 'Add Supply Item',
                                        prefixIcon: Icon(Icons.add_shopping_cart_outlined),
                                      ),
                                      items: items.map((item) {
                                        return DropdownMenuItem<String>(
                                          value: item['id'],
                                          child: Text('${item['name']} (Stock: ${item['quantity']})'),
                                        );
                                      }).toList(),
                                      onChanged: (id) {
                                        if (id != null) {
                                          setState(() {
                                            if (!_selectedMaterials.containsKey(id)) {
                                              _selectedMaterials[id] = 1;
                                            }
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Displaying selected materials list
                                    if (_selectedMaterials.isEmpty)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: 12.0),
                                          child: Text(
                                            'No supplies listed yet.',
                                            style: TextStyle(color: Colors.grey, fontSize: 13),
                                          ),
                                        ),
                                      )
                                    else
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _selectedMaterials.length,
                                        itemBuilder: (context, index) {
                                          final id = _selectedMaterials.keys.elementAt(index);
                                          final qty = _selectedMaterials[id]!;
                                          final item = items.firstWhere((it) => it['id'] == id);

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item['name'],
                                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                                  onPressed: () {
                                                    setState(() {
                                                      if (qty > 1) {
                                                        _selectedMaterials[id] = qty - 1;
                                                      } else {
                                                        _selectedMaterials.remove(id);
                                                      }
                                                    });
                                                  },
                                                ),
                                                Text(
                                                  '$qty',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                                  onPressed: () {
                                                    setState(() {
                                                      if (qty < item['quantity']) {
                                                        _selectedMaterials[id] = qty + 1;
                                                      } else {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text('Cannot exceed available stock of ${item['quantity']}')),
                                                        );
                                                      }
                                                    });
                                                  },
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: AppColors.warningRed),
                                                  onPressed: () {
                                                    setState(() {
                                                      _selectedMaterials.remove(id);
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
                              error: (e, _) => Text('Error loading inventory list: $e'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Log Treatment Button
                    ElevatedButton(
                      onPressed: _submitSession,
                      child: const Text('Log Treatment Session', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
