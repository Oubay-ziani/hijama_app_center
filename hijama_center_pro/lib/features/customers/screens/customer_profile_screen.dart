import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../sessions/providers/sessions_provider.dart';
import '../../sessions/widgets/new_booking_modal.dart';
import '../../sessions/widgets/session_card.dart';
import '../providers/customers_provider.dart';

class CustomerProfileScreen extends ConsumerWidget {
  final String customerId;
  const CustomerProfileScreen({super.key, required this.customerId});

  void _deleteProfile(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف ملف العميل؟'),
        content: const Text('هل أنت متأكد من حذف هذا العميل وجميع سجلاته الطبية؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.warningRed),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(customersRepositoryProvider).deleteCustomer(customerId);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف العميل بنجاح')),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل حذف العميل'), backgroundColor: AppColors.warningRed),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(customerProfileProvider(customerId));
    final customerSessionsAsync = ref.watch(customerSessionsProvider(customerId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ملف العميل / Profil Client'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'تعديل البيانات',
            onPressed: () {
              context.go('/customers/edit/$customerId');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'حذف العميل',
            onPressed: () => _deleteProfile(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customerProfileProvider(customerId));
          ref.invalidate(customerSessionsProvider(customerId));
        },
        child: profileAsync.when(
          data: (profile) {
            final name = (profile['fullName'] ?? profile['full_name'] ?? profile['name'] ?? 'عميل').toString();
            final phone = (profile['phone'] ?? '').toString();
            final age = profile['age'] ?? 0;
            final gender = (profile['gender'] ?? 'MALE').toString().toUpperCase();
            final totalSpent = double.tryParse(profile['totalSpent']?.toString() ?? profile['total_spent']?.toString() ?? '0') ?? 0.0;
            final sessionCount = int.tryParse(profile['sessionCount']?.toString() ?? profile['session_count']?.toString() ?? '0') ?? 0;
            final totalCups = int.tryParse(profile['totalCups']?.toString() ?? profile['total_cups']?.toString() ?? '0') ?? 0;

            final medicalNotes = (profile['medicalNotes'] ?? profile['medical_notes'] ?? '').toString();
            final chronicDiseases = (profile['chronicDiseases'] ?? profile['chronic_diseases'] ?? '').toString();
            final bloodPressure = (profile['bloodPressureStatus'] ?? profile['blood_pressure_status'] ?? '').toString();
            final hijamaHistory = (profile['previousHijamaHistory'] ?? profile['previous_hijama_history'] ?? '').toString();
            final generalNotes = (profile['notes'] ?? '').toString();

            final rawLastVisit = profile['lastVisit'] ?? profile['last_visit'];
            String lastVisitStr = 'لا توجد زيارات سابقة';
            if (rawLastVisit is Timestamp) {
              lastVisitStr = DateFormat('dd/MM/yyyy').format(rawLastVisit.toDate());
            } else if (rawLastVisit is String && rawLastVisit.isNotEmpty) {
              final dt = DateTime.tryParse(rawLastVisit);
              if (dt != null) lastVisitStr = DateFormat('dd/MM/yyyy').format(dt);
            }

            final isFemale = gender == 'FEMALE';

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Header Profile Card ─────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: isFemale
                                ? Colors.pink.withOpacity(0.15)
                                : AppColors.primaryGreen.withOpacity(0.15),
                            child: Icon(
                              isFemale ? Icons.female : Icons.male,
                              color: isFemale ? Colors.pink : AppColors.primaryGreen,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.phone, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(phone.isNotEmpty ? phone : 'لا يوجد هاتف', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                  ],
                                ),
                                if (age > 0) ...[
                                  const SizedBox(height: 2),
                                  Text('$age سنة • ${isFemale ? 'أنثى' : 'ذكر'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── 2. Direct Action: حجز حصة لهذا العميل ──────────────────
                  ElevatedButton.icon(
                    onPressed: () {
                      NewBookingModal.show(
                        context,
                        customerId: customerId,
                        customerName: name,
                        customerPhone: phone,
                      );
                    },
                    icon: const Icon(Icons.add_task_rounded),
                    label: const Text('حجز حصة جديدة لهذا العميل / Nouvelle séance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── 3. Lifetime Stats Grid ─────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _buildProfileStatCard(
                          title: 'الحصص السابقة',
                          value: '$sessionCount',
                          icon: Icons.history,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildProfileStatCard(
                          title: 'مجموع المدفوعات',
                          value: '${totalSpent.toStringAsFixed(0)} DA',
                          icon: Icons.monetization_on,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildProfileStatCard(
                          title: 'الكؤوس المستعملة',
                          value: '$totalCups',
                          icon: Icons.medical_services,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available, size: 18, color: AppColors.primaryGreen),
                          const SizedBox(width: 8),
                          const Text('تاريخ آخر زيارة:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text(lastVisitStr, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── 4. Medical Notes & Information ─────────────────────────
                  if (medicalNotes.isNotEmpty || chronicDiseases.isNotEmpty || bloodPressure.isNotEmpty || generalNotes.isNotEmpty) ...[
                    const Text('المعلومات الطبية والملاحظات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (chronicDiseases.isNotEmpty)
                              _buildInfoRow('الأمراض المزمنة:', chronicDiseases, isWarning: true),
                            if (bloodPressure.isNotEmpty)
                              _buildInfoRow('ضغط الدم:', bloodPressure),
                            if (hijamaHistory.isNotEmpty)
                              _buildInfoRow('تاريخ الحجامة السابقة:', hijamaHistory),
                            if (medicalNotes.isNotEmpty)
                              _buildInfoRow('ملاحظات طبية:', medicalNotes),
                            if (generalNotes.isNotEmpty)
                              _buildInfoRow('ملاحظات عامة:', generalNotes),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ── 5. Chronological Past Sessions History ─────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('سجل الزيارات والحصص السابقة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: () => ref.invalidate(customerSessionsProvider(customerId)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  customerSessionsAsync.when(
                    data: (sessions) {
                      if (sessions.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(
                              child: Text('لا توجد حصص مسجلة لهذا العميل بعد.'),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          return SessionCard(session: sessions[index]);
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(color: AppColors.primaryGreen),
                      ),
                    ),
                    error: (e, _) => Center(child: Text('خطأ في تحميل الحصص: $e')),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          ),
          error: (e, _) => Center(child: Text('خطأ في تحميل ملف العميل: $e')),
        ),
      ),
    );
  }

  Widget _buildProfileStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isWarning ? AppColors.warningRed : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isWarning ? AppColors.warningRed : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
