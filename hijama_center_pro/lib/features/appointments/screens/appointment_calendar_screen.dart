import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/appointments_provider.dart';

class AppointmentCalendarScreen extends ConsumerStatefulWidget {
  const AppointmentCalendarScreen({super.key});

  @override
  ConsumerState<AppointmentCalendarScreen> createState() => _AppointmentCalendarScreenState();
}

class _AppointmentCalendarScreenState extends ConsumerState<AppointmentCalendarScreen> {
  String _statusFilter = 'ALL'; // ALL, PENDING, COMPLETED, CANCELLED

  void _updateStatus(String id, String status) async {
    final success = await ref.read(appointmentsRepositoryProvider).updateAppointment(id, {'status': status});
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment status marked as $status'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status'), backgroundColor: AppColors.warningRed),
        );
      }
    }
  }

  void _deleteAppointment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment?'),
        content: const Text('Are you sure you want to remove this appointment record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.warningRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(appointmentsRepositoryProvider).deleteAppointment(id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete appointment')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appointmentsAsync = ref.watch(appointmentsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appointments),
      ),
      body: Column(
        children: [
          // Filter Tabs (Pending, Completed, Cancelled, All)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('PENDING', 'Pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('COMPLETED', 'Completed'),
                  const SizedBox(width: 8),
                  _buildFilterChip('CANCELLED', 'Cancelled'),
                ],
              ),
            ),
          ),

          // Appointment list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(appointmentsListProvider);
              },
              child: appointmentsAsync.when(
                data: (appointments) {
                  // Filter client-side based on status
                  final filtered = appointments.where((appt) {
                    if (_statusFilter == 'ALL') return true;
                    return appt['status'] == _statusFilter;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('No appointments scheduled for this filter.'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final appt = filtered[index];
                      final id = appt['id'];
                      final custId = appt['customer_id'];
                      final custName = appt['customer_name'];
                      final custPhone = appt['customer_phone'];
                      final type = appt['session_type'];
                      final time = DateTime.parse(appt['scheduled_at']);
                      final status = appt['status'];
                      final notes = appt['notes'] ?? '';

                      Color statusColor;
                      if (status == 'COMPLETED') {
                        statusColor = Colors.green;
                      } else if (status == 'CANCELLED') {
                        statusColor = Colors.grey;
                      } else {
                        statusColor = AppColors.alertOrange; // Pending
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row with Time and Status Badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${time.day}/${time.month}/${time.year} @ ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: statusColor, width: 0.5),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              
                              // Customer summary
                              Text(
                                custName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text('Phone: $custPhone', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              const SizedBox(height: 6),

                              // Session type
                              Row(
                                children: [
                                  const Icon(Icons.spa, size: 14, color: AppColors.primaryGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    type.toString().replaceAll('_', ' '),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryGreen,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              if (notes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Notes: $notes',
                                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                                ),
                              ],
                              const Divider(height: 20),

                              // Quick card actions
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Delete option
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.warningRed, size: 20),
                                    onPressed: () => _deleteAppointment(id),
                                  ),
                                  const Spacer(),
                                  if (status == 'PENDING') ...[
                                    TextButton(
                                      onPressed: () => _updateStatus(id, 'CANCELLED'),
                                      style: TextButton.styleFrom(foregroundColor: Colors.grey),
                                      child: const Text('Cancel'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        // Complete appointment & go to Record Treatment
                                        _updateStatus(id, 'COMPLETED');
                                        context.go('/sessions/new?customerId=$custId');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryGreen,
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        minimumSize: const Size(60, 36),
                                      ),
                                      child: const Text('Complete & Log'),
                                    ),
                                  ] else ...[
                                    TextButton(
                                      onPressed: () {
                                        context.go('/appointments/edit/$id');
                                      },
                                      child: const Text('Reschedule'),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
                error: (e, _) => Center(child: Text('Error loading appointments: $e')),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        onPressed: () {
          context.go('/appointments/new');
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 2) return;
          if (index == 0) context.go('/dashboard');
          if (index == 1) context.go('/customers');
          if (index == 3) context.go('/inventory');
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

  Widget _buildFilterChip(String status, String label) {
    final selected = _statusFilter == status;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primaryGreen.withOpacity(0.15),
      labelStyle: TextStyle(
        color: selected ? AppColors.primaryGreen : Colors.grey,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _statusFilter = status);
        }
      },
    );
  }
}
