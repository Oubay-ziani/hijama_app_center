import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../customers/providers/customers_provider.dart';
import '../providers/appointments_provider.dart';

class AppointmentFormScreen extends ConsumerStatefulWidget {
  final String? appointmentId;
  const AppointmentFormScreen({super.key, this.appointmentId});

  @override
  ConsumerState<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends ConsumerState<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCustomerId;
  String _sessionType = 'WET_CUPPING';
  DateTime _selectedDateTime = DateTime.now().add(const Duration(days: 1));
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    // Default scheduled time round-up
    _selectedDateTime = DateTime(_selectedDateTime.year, _selectedDateTime.month, _selectedDateTime.day, 10, 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit && widget.appointmentId != null) {
      _loadAppointmentData();
    }
  }

  void _loadAppointmentData() async {
    setState(() => _isLoading = true);
    try {
      final appt = await ref.read(appointmentDetailProvider(widget.appointmentId!).future);
      _selectedCustomerId = appt['customer_id'];
      _sessionType = appt['session_type'] ?? 'WET_CUPPING';
      _selectedDateTime = DateTime.parse(appt['scheduled_at']);
      _notesController.text = appt['notes'] ?? '';
      _isInit = true;
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load appointment details')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _saveForm() async {
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient.'), backgroundColor: AppColors.warningRed),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final payload = {
      'customerId': _selectedCustomerId,
      'sessionType': _sessionType,
      'scheduledAt': _selectedDateTime.toUtc().toIso8601String(),
      'notes': _notesController.text.trim(),
    };

    final repo = ref.read(appointmentsRepositoryProvider);
    bool success;
    if (widget.appointmentId != null) {
      success = await repo.updateAppointment(widget.appointmentId!, payload);
    } else {
      success = await repo.createAppointment(payload);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.appointmentId != null ? 'Appointment rescheduled successfully!' : 'Appointment scheduled successfully!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving appointment schedule. Please try again.'),
            backgroundColor: AppColors.warningRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customersAsync = ref.watch(customersListProvider);
    final isEditing = widget.appointmentId != null;

    if (_isLoading && !isEditing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Reschedule Appointment' : 'Schedule Appointment'),
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
                    // Patient Selection Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Patient Information',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen),
                            ),
                            const SizedBox(height: 16),
                            customersAsync.when(
                              data: (customers) {
                                return DropdownButtonFormField<String>(
                                  value: _selectedCustomerId,
                                  decoration: InputDecoration(
                                    labelText: l10n.customers,
                                    prefixIcon: const Icon(Icons.person_outline),
                                  ),
                                  disabledHint: _selectedCustomerId != null
                                      ? Text(
                                          customers.firstWhere(
                                            (c) => c['id'] == _selectedCustomerId,
                                            orElse: () => {'full_name': 'Loading...'},
                                          )['full_name'],
                                        )
                                      : null,
                                  items: customers.map((c) {
                                    return DropdownMenuItem<String>(
                                      value: c['id'],
                                      child: Text('${c['full_name']} (${c['phone']})'),
                                    );
                                  }).toList(),
                                  onChanged: isEditing
                                      ? null // Cannot change patient on edit
                                      : (val) {
                                          setState(() => _selectedCustomerId = val);
                                        },
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
                              error: (e, _) => Text('Error loading customers: $e'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Schedule Date/Time pickers Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Timing & Treatment Type',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen),
                            ),
                            const SizedBox(height: 16),
                            
                            // Session Type dropdown
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
                            const SizedBox(height: 16),

                            // Date picker row
                            ListTile(
                              leading: const Icon(Icons.calendar_today, color: AppColors.primaryGreen),
                              title: const Text('Appointment Date'),
                              subtitle: Text('${_selectedDateTime.day}/${_selectedDateTime.month}/${_selectedDateTime.year}'),
                              trailing: OutlinedButton(
                                onPressed: _pickDate,
                                child: const Text('Change'),
                              ),
                            ),
                            const Divider(),
                            
                            // Time picker row
                            ListTile(
                              leading: const Icon(Icons.access_time, color: AppColors.primaryGreen),
                              title: const Text('Appointment Time'),
                              subtitle: Text('${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}'),
                              trailing: OutlinedButton(
                                onPressed: _pickTime,
                                child: const Text('Change'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Observations / Notes Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Appointment Guidelines / Notes',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Notes',
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
                        isEditing ? 'Reschedule Appointment' : 'Save Appointment Schedule',
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
