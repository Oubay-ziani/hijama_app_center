import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../sessions/widgets/new_booking_modal.dart';
import '../providers/customers_provider.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customersAsync = ref.watch(customersListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customers),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: l10n.addCustomer,
            onPressed: () => context.go('/customers/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.search,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(customerSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                ref.read(customerSearchQueryProvider.notifier).state = val;
              },
            ),
          ),

          // Customers List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(customersListProvider);
              },
              child: customersAsync.when(
                data: (customers) {
                  if (customers.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 56,
                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'لا يوجد عملاء مسجلون',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'أضف عميلك الأول أو احجز حصة جديدة',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => context.go('/customers/new'),
                              icon: const Icon(Icons.add),
                              label: Text(l10n.addCustomer),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      final id = customer['id']?.toString() ?? '';
                      final name = (customer['fullName'] ?? customer['full_name'] ?? customer['name'] ?? 'عميل').toString();
                      final phone = (customer['phone'] ?? '').toString();
                      final gender = (customer['gender'] ?? 'MALE').toString().toUpperCase();
                      final age = customer['age'] ?? 0;
                      final totalSpent = double.tryParse(customer['totalSpent']?.toString() ?? customer['total_spent']?.toString() ?? '0') ?? 0.0;
                      final sessionCount = int.tryParse(customer['sessionCount']?.toString() ?? customer['session_count']?.toString() ?? '0') ?? 0;
                      final totalCups = int.tryParse(customer['totalCups']?.toString() ?? customer['total_cups']?.toString() ?? '0') ?? 0;
                      final rawLastVisit = customer['lastVisit'] ?? customer['last_visit'];
                      String lastVisitStr = 'لا توجد زيارات سابقة';
                      if (rawLastVisit is Timestamp) {
                        lastVisitStr = DateFormat('dd/MM/yyyy').format(rawLastVisit.toDate());
                      } else if (rawLastVisit is String && rawLastVisit.isNotEmpty) {
                        final dt = DateTime.tryParse(rawLastVisit);
                        if (dt != null) lastVisitStr = DateFormat('dd/MM/yyyy').format(dt);
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            context.go('/customers/profile/$id');
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: gender == 'FEMALE'
                                          ? Colors.pink.withOpacity(0.12)
                                          : AppColors.primaryGreen.withOpacity(0.12),
                                      child: Icon(
                                        gender == 'FEMALE' ? Icons.female : Icons.male,
                                        color: gender == 'FEMALE' ? Colors.pink : AppColors.primaryGreen,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            phone.isNotEmpty ? phone : (age > 0 ? '$age سنة' : ''),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Quick New Booking Button for this Client
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryGreen),
                                      tooltip: 'حجز حصة جديدة لهذا العميل',
                                      onPressed: () {
                                        NewBookingModal.show(
                                          context,
                                          customerId: id,
                                          customerName: name,
                                          customerPhone: phone,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                // Customer KPI Mini Row (Sessions, Total Spent, Last Visit)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildMiniStat('الحصص', '$sessionCount حصص', AppColors.primaryGreen),
                                    _buildMiniStat('إجمالي المدفوع', '${totalSpent.toStringAsFixed(0)} DA', AppColors.primaryAccent),
                                    _buildMiniStat('الكؤوس', '$totalCups كأس', Colors.blueAccent),
                                    _buildMiniStat('آخر زيارة', lastVisitStr, Colors.grey),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryGreen),
                ),
                error: (e, _) => Center(child: Text('خطأ في تحميل قائمة العملاء: $e')),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: Text(l10n.addCustomer),
        onPressed: () => context.go('/customers/new'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 2) return;
          if (index == 0) context.go('/dashboard');
          if (index == 1) context.go('/sessions');
          if (index == 3) context.go('/reports');
          if (index == 4) context.go('/settings');
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.dashboard_rounded), label: l10n.dashboard),
          BottomNavigationBarItem(icon: const Icon(Icons.history_rounded), label: l10n.history),
          BottomNavigationBarItem(icon: const Icon(Icons.people_alt_rounded), label: l10n.customers),
          BottomNavigationBarItem(icon: const Icon(Icons.bar_chart_rounded), label: 'الإحصائيات'),
          BottomNavigationBarItem(icon: const Icon(Icons.settings_rounded), label: l10n.settings),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
