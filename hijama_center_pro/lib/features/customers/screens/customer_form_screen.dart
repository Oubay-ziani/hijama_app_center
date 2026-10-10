import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/customers_provider.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final String? customerId;
  const CustomerFormScreen({super.key, this.customerId});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'MALE';
  final _medicalNotesController = TextEditingController();
  final _chronicDiseasesController = TextEditingController();
  final _bloodPressureController = TextEditingController();
  final _hijamaHistoryController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isInit = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _medicalNotesController.dispose();
    _chronicDiseasesController.dispose();
    _bloodPressureController.dispose();
    _hijamaHistoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit && widget.customerId != null) {
      _loadCustomerData();
    }
  }

  void _loadCustomerData() async {
    setState(() => _isLoading = true);
    try {
      final customer = await ref.read(customerProfileProvider(widget.customerId!).future);
      _fullNameController.text = customer['full_name'] ?? '';
      _phoneController.text = customer['phone'] ?? '';
      _ageController.text = (customer['age'] ?? 0).toString();
      _gender = customer['gender'] ?? 'MALE';
      _medicalNotesController.text = customer['medical_notes'] ?? '';
      _chronicDiseasesController.text = customer['chronic_diseases'] ?? '';
      _bloodPressureController.text = customer['blood_pressure_status'] ?? '';
      _hijamaHistoryController.text = customer['previous_hijama_history'] ?? '';
      _notesController.text = customer['notes'] ?? '';
      _isInit = true;
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load customer profile details')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final payload = {
      'fullName': _fullNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'age': int.tryParse(_ageController.text) ?? 0,
      'gender': _gender,
      'medicalNotes': _medicalNotesController.text.trim(),
      'chronicDiseases': _chronicDiseasesController.text.trim(),
      'bloodPressureStatus': _bloodPressureController.text.trim(),
      'previousHijamaHistory': _hijamaHistoryController.text.trim(),
      'notes': _notesController.text.trim(),
    };

    final repo = ref.read(customersRepositoryProvider);
    bool success;
    if (widget.customerId != null) {
      success = await repo.updateCustomer(widget.customerId!, payload);
    } else {
      success = await repo.createCustomer(payload);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.customerId != null ? 'Customer updated successfully!' : 'Customer registered successfully!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving customer data. Please verify inputs.'),
            backgroundColor: AppColors.warningRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.customerId != null;

    if (_isLoading && !isEditing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Customer Profile' : l10n.addCustomer),
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
                    // Base Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personal Information',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _fullNameController,
                              decoration: InputDecoration(
                                labelText: l10n.fullName,
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter full name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: l10n.phone,
                                prefixIcon: const Icon(Icons.phone_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _ageController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: l10n.age,
                                      prefixIcon: const Icon(Icons.cake_outlined),
                                    ),
                                    validator: (value) {
                                      if (value == null || int.tryParse(value) == null) {
                                        return 'Enter valid age';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _gender,
                                    decoration: InputDecoration(
                                      labelText: l10n.gender,
                                      prefixIcon: const Icon(Icons.wc),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'MALE', child: Text('Male')),
                                      DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                                      DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _gender = val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Medical Context Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Medical Information',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _bloodPressureController,
                              decoration: InputDecoration(
                                labelText: l10n.bloodPressure,
                                prefixIcon: const Icon(Icons.favorite_border),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _chronicDiseasesController,
                              decoration: InputDecoration(
                                labelText: l10n.chronicDiseases,
                                prefixIcon: const Icon(Icons.healing_outlined),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _medicalNotesController,
                              decoration: InputDecoration(
                                labelText: l10n.medicalNotes,
                                prefixIcon: const Icon(Icons.description_outlined),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _hijamaHistoryController,
                              decoration: InputDecoration(
                                labelText: l10n.hijamaHistory,
                                prefixIcon: const Icon(Icons.history),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'General Notes',
                                prefixIcon: Icon(Icons.note_alt_outlined),
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveForm,
                      child: Text(
                        l10n.save,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
