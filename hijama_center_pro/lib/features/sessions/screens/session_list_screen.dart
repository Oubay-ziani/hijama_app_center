import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/sessions_provider.dart';
import '../widgets/new_booking_modal.dart';
import '../widgets/session_card.dart';

class SessionListScreen extends ConsumerStatefulWidget {
  const SessionListScreen({super.key});

  @override
  ConsumerState<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends ConsumerState<SessionListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _pickMonthFilter() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(sessionMonthFilterProvider) ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'اختر الشهر للتصفية',
    );

    if (picked != null) {
      ref.read(sessionMonthFilterProvider.notifier).state = DateTime(picked.year, picked.month);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessionsAsync = ref.watch(sessionsListProvider);
    final currentStatus = ref.watch(sessionStatusFilterProvider);
    final currentMonth = ref.watch(sessionMonthFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.history),
        actions: [
          IconButton(
            icon: Icon(
              currentMonth == null ? Icons.calendar_today_outlined : Icons.calendar_month,
              color: currentMonth != null ? AppColors.primaryAccent : Colors.white,
            ),
            tooltip: 'تصفية حسب الشهر',
            onPressed: _pickMonthFilter,
          ),
          if (currentMonth != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              tooltip: 'إلغاء تصفية الشهر',
              onPressed: () {
                ref.read(sessionMonthFilterProvider.notifier).state = null;
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Filter Bar ─────────────────────────────────────────────
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
                          ref.read(sessionSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                ref.read(sessionSearchQueryProvider.notifier).state = val;
              },
            ),
          ),

          // ── Active Month Filter Indicator (if any) ──────────────────────────
          if (currentMonth != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_alt_outlined, size: 14, color: AppColors.primaryGreen),
                        const SizedBox(width: 4),
                        Text(
                          'تصفية الشهر: ${DateFormat('MMMM yyyy').format(currentMonth)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Status Filter Chips ─────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Row(
              children: [
                _buildStatusChip('ALL', l10n.filterAll, currentStatus),
                const SizedBox(width: 6),
                _buildStatusChip('RESERVED', l10n.statusReserved, currentStatus, color: AppColors.statusReserved),
                const SizedBox(width: 6),
                _buildStatusChip('CONFIRMED', l10n.statusConfirmed, currentStatus, color: AppColors.statusConfirmed),
                const SizedBox(width: 6),
                _buildStatusChip('COMPLETED', l10n.statusCompleted, currentStatus, color: AppColors.statusCompleted),
                const SizedBox(width: 6),
                _buildStatusChip('CANCELLED', l10n.statusCancelled, currentStatus, color: AppColors.statusCancelled),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // ── Sessions List ──────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(sessionsListProvider);
              },
              child: sessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy_outlined,
                              size: 56,
                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'لا توجد حصص مطابقة',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'يمكنك حجز حصة جديدة عبر الزر أدناه',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => NewBookingModal.show(context),
                              icon: const Icon(Icons.add),
                              label: Text(l10n.newSession),
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
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      return SessionCard(session: sessions[index]);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryGreen),
                ),
                error: (e, _) => Center(child: Text('خطأ في تحميل سجل الحصص: $e')),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.newSession),
        onPressed: () => NewBookingModal.show(context),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) return;
          if (index == 0) context.go('/dashboard');
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

  Widget _buildStatusChip(String statusKey, String label, String currentStatus, {Color? color}) {
    final isSelected = currentStatus == statusKey;
    final chipColor = color ?? AppColors.primaryGreen;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: chipColor.withOpacity(0.18),
      labelStyle: TextStyle(
        color: isSelected ? chipColor : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          ref.read(sessionStatusFilterProvider.notifier).state = statusKey;
        }
      },
    );
  }
}
