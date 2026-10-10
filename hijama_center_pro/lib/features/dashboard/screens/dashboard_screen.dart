import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sessions/providers/sessions_provider.dart';
import '../../sessions/widgets/new_booking_modal.dart';
import '../../sessions/widgets/session_card.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userName = ref.watch(authProvider.notifier).name ?? 'دكتور / المعالج';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statsAsync = ref.watch(dashboardStatsProvider);
    final todaySessionsAsync = ref.watch(todaySessionsProvider);
    final alertsAsync = ref.watch(dashboardAlertsProvider);

    final todayStr = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.appTitle,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white70),
            ),
            Text(
              '${l10n.hello}، $userName',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
            onPressed: () {
              ref.invalidate(dashboardStatsProvider);
              ref.invalidate(todaySessionsProvider);
              ref.invalidate(dashboardAlertsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(todaySessionsProvider);
          ref.invalidate(dashboardAlertsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Hero Primary Action: حجز حصة / Nouvelle séance ──────────
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryGreen, Color(0xFF137547)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      NewBookingModal.show(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.newSession,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Nouvelle séance / تسجيل موعد جديد',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: AppColors.primaryGreen,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── 2. Low Stock Alerts Banner ─────────────────────────────────
              alertsAsync.when(
                data: (alerts) {
                  if (alerts.isEmpty) return const SizedBox.shrink();
                  final alert = alerts.first;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.alertOrange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.alertOrange.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.alertOrange, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            alert['message'] ?? 'المخزون منخفض',
                            style: const TextStyle(
                              color: AppColors.alertOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/inventory'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.alertOrange,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          child: const Text('تزويد', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // ── 3. Top 5 Key KPI Summary Cards ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ملخص النشاط اليوم والشهري',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    todayStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              statsAsync.when(
                data: (stats) {
                  final bookingsToday = stats['bookingsToday'] ?? 0;
                  final revenueToday = (stats['revenueToday'] as num?)?.toDouble() ?? 0.0;
                  final cupsToday = stats['cupsToday'] ?? 0;
                  final revenueThisMonth = (stats['revenueThisMonth'] as num?)?.toDouble() ?? 0.0;
                  final cupsThisMonth = stats['cupsThisMonth'] ?? 0;

                  return Column(
                    children: [
                      // Today 3 Cards Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildKPICard(
                              context,
                              title: l10n.todayBookings,
                              value: '$bookingsToday',
                              icon: Icons.assignment_turned_in_outlined,
                              color: AppColors.statusConfirmed,
                              subtitle: 'حصة اليوم',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildKPICard(
                              context,
                              title: l10n.todayRevenue,
                              value: '${revenueToday.toStringAsFixed(0)} DA',
                              icon: Icons.monetization_on_outlined,
                              color: AppColors.primaryAccent,
                              subtitle: 'مداخيل اليوم',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildKPICard(
                              context,
                              title: l10n.todayCups,
                              value: '$cupsToday',
                              icon: Icons.medical_services_outlined,
                              color: Colors.deepPurpleAccent,
                              subtitle: 'كؤوس اليوم',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Month 2 Cards Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildKPICard(
                              context,
                              title: l10n.monthRevenue,
                              value: '${revenueThisMonth.toStringAsFixed(0)} DA',
                              icon: Icons.account_balance_wallet_outlined,
                              color: AppColors.primaryGreen,
                              subtitle: 'إجمالي مداخيل الشهر',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildKPICard(
                              context,
                              title: l10n.monthCups,
                              value: '$cupsThisMonth كأس',
                              icon: Icons.inventory_2_outlined,
                              color: AppColors.tealAccent,
                              subtitle: 'استهلاك كؤوس الشهر',
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: AppColors.primaryGreen),
                  ),
                ),
                error: (err, _) => Center(child: Text('خطأ في تحميل الإحصائيات: $err')),
              ),
              const SizedBox(height: 24),

              // ── 4. Today's Sessions Queue (جدول ومواعيد اليوم) ─────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.today_rounded, size: 20, color: AppColors.primaryGreen),
                      const SizedBox(width: 6),
                      Text(
                        l10n.upcomingAppts,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => context.go('/sessions'),
                    icon: const Icon(Icons.arrow_forward_ios, size: 12),
                    label: const Text('عرض الكل'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              todaySessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'لا توجد حصص مجدولة لليوم',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'اضغط على "حجز حصة جديدة" لإضافة عميل أو موعد',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: () => NewBookingModal.show(context),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('حجز حصة الآن'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  minimumSize: const Size(140, 40),
                                ),
                              ),
                            ],
                          ),
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
                error: (e, _) => Center(child: Text('خطأ في تحميل جدول اليوم: $e')),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) context.go('/sessions');
          if (index == 2) context.go('/customers');
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

  Widget _buildKPICard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
