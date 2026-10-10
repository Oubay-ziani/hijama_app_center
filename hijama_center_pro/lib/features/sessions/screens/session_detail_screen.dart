import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../reports/providers/reports_provider.dart';
import '../providers/sessions_provider.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  bool _isGeneratingPdf = false;

  void _downloadInvoice() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final success = await ref.read(reportsRepositoryProvider).compileSessionInvoice(widget.sessionId);
      
      if (mounted) {
        if (success) {
          // Success
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Invoice Ready'),
                ],
              ),
              content: const Text(
                'The official medical invoice PDF has been compiled successfully on your device. You can now view or print it.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          throw Exception('Failed');
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to compile invoice PDF locally.'),
            backgroundColor: AppColors.warningRed,
          ),
        );
      }
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionDetailProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
      ),
      body: sessionAsync.when(
        data: (session) {
          final type = session['sessionType'] ?? session['session_type'] ?? 'Hijama';
          final rawDate = session['date'] ?? session['createdAt'];
          final date = rawDate is Timestamp
              ? rawDate.toDate()
              : (DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now());
          final cups = session['cupsUsed'] ?? session['cups_used'] ?? 0;
          final notes = session['notes'] ?? '';
          final patientName = session['customerName'] ?? session['customer_name'] ?? session['patientName'] ?? '';
          final patientPhone = session['customerPhone'] ?? session['customer_phone'] ?? '';
          final staffName = session['employeeName'] ?? session['employee_name'] ?? 'Therapist';
          final price = double.tryParse(session['pricePaid']?.toString() ?? session['price_paid']?.toString() ?? session['price']?.toString() ?? '0') ?? 0.0;
          final cost = double.tryParse(session['totalCost']?.toString() ?? session['total_cost']?.toString() ?? session['cost']?.toString() ?? '0') ?? 0.0;
          final debt = double.tryParse(session['debtAmount']?.toString() ?? session['debt_amount']?.toString() ?? '0') ?? 0.0;
          final materials = session['materials'] as List<dynamic>? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Session Type & Date Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.medical_services_outlined,
                          size: 48,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          type.toString().replaceAll('_', ' '),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Date: ${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'Therapist: $staffName',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Patient summary card
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline, color: AppColors.primaryGreen),
                    title: Text(
                      patientName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Phone: $patientPhone'),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 14),
                      onPressed: () {
                        context.go('/customers/profile/${session['customer_id']}');
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Billing Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Billing summary',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen),
                        ),
                        const Divider(),
                        _buildRow('Subtotal Cost', '${cost.toStringAsFixed(0)} DA'),
                        _buildRow('Amount Paid', '${price.toStringAsFixed(0)} DA'),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Outstanding Debt',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${debt.toStringAsFixed(0)} DA',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: debt > 0 ? AppColors.warningRed : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Clinical Details
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Clinical Summary',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen),
                        ),
                        const Divider(),
                        _buildRow('Cups Applied', '$cups cups'),
                        const SizedBox(height: 8),
                        const Text(
                          'Operator Notes:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notes.isEmpty ? 'No therapist notes logged.' : notes,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Materials Consumed
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Materials Consumed',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen),
                        ),
                        const Divider(),
                        if (materials.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text(
                                'No accessory items registered for this session.',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: materials.length,
                            itemBuilder: (context, index) {
                              final mat = materials[index];
                              final name = mat['item_name'];
                              final qty = mat['quantity_used'];
                              final price = double.parse(mat['purchase_price']?.toString() ?? '0');
                              final costVal = qty * price;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('$name (x$qty)'),
                                    Text('${costVal.toStringAsFixed(0)} DA equivalent'),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                _isGeneratingPdf
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                    : ElevatedButton.icon(
                        onPressed: _downloadInvoice,
                        icon: const Icon(Icons.print),
                        label: const Text('Download Medical Invoice'),
                      ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
        error: (err, _) => Center(child: Text('Error loading session: $err')),
      ),
    );
  }

  Widget _buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
