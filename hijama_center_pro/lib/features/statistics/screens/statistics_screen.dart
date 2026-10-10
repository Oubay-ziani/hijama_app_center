import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../expenses/widgets/add_expense_modal.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../providers/statistics_provider.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _activeChartType = 0; // 0 = Revenue, 1 = Sessions, 2 = Cups

  void _pickSpecificMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'اختر الشهر والسنة',
    );

    if (picked != null) {
      ref.read(selectedStatsFilterProvider.notifier).state = StatsPeriodFilter(
        type: StatsPeriodType.specificMonth,
        specificMonth: DateTime(picked.year, picked.month),
      );
    }
  }

  void _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 14)),
        end: now,
      ),
    );

    if (picked != null) {
      ref.read(selectedStatsFilterProvider.notifier).state = StatsPeriodFilter(
        type: StatsPeriodType.customRange,
        customRange: picked,
      );
    }
  }

  void _showRestockDialog() {
    final qtyController = TextEditingController(text: '100');
    final costController = TextEditingController(text: '3000');
    final supplierController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('تزويد كؤوس الحجامة'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد الكؤوس المشتراة *',
                suffixText: 'كأس',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'تكلفة الشراء الإجمالية (دج) *',
                suffixText: 'DA',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: supplierController,
              decoration: const InputDecoration(
                labelText: 'المورد (اختياري)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(qtyController.text) ?? 0;
              final cost = double.tryParse(costController.text) ?? 0.0;
              if (qty > 0) {
                // Find or create cups item in inventory
                final invList = await ref.read(inventoryListProvider.future);
                final cupItem = invList.where((i) {
                  final n = (i['name'] ?? '').toString().toLowerCase();
                  return n.contains('cup') || n.contains('كؤوس') || n.contains('ventouse');
                }).firstOrNull;

                String itemId;
                if (cupItem != null) {
                  itemId = cupItem['id'];
                } else {
                  await ref.read(inventoryRepositoryProvider).createItem({
                    'name': 'كؤوس الحجامة / Cupping Cups',
                    'quantity': qty,
                    'purchasePrice': cost,
                    'minThreshold': 15,
                  });
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  ref.invalidate(statisticsSummaryProvider);
                  return;
                }

                await ref.read(inventoryRepositoryProvider).addRestockPurchase({
                  'itemId': itemId,
                  'quantity': qty,
                  'totalCost': cost,
                  'supplier': supplierController.text.trim(),
                });

                if (ctx.mounted) Navigator.of(ctx).pop();
                ref.invalidate(statisticsSummaryProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تمت إضافة $qty كأس إلى المخزون بنجاح')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: const Text('حفظ الشحنة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentFilter = ref.watch(selectedStatsFilterProvider);
    final statsAsync = ref.watch(statisticsSummaryProvider);
    final expensesAsync = ref.watch(expensesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics / Statistiques'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(statisticsSummaryProvider);
              ref.invalidate(expensesListProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(statisticsSummaryProvider);
          ref.invalidate(expensesListProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Period Selector Chips ───────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPeriodChip(StatsPeriodType.today, l10n.today, currentFilter.type),
                    const SizedBox(width: 8),
                    _buildPeriodChip(StatsPeriodType.thisWeek, l10n.thisWeek, currentFilter.type),
                    const SizedBox(width: 8),
                    _buildPeriodChip(StatsPeriodType.thisMonth, l10n.thisMonth, currentFilter.type),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_month_outlined, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            currentFilter.type == StatsPeriodType.specificMonth && currentFilter.specificMonth != null
                                ? DateFormat('MMMM yyyy').format(currentFilter.specificMonth!)
                                : l10n.selectMonth,
                          ),
                        ],
                      ),
                      selected: currentFilter.type == StatsPeriodType.specificMonth,
                      selectedColor: AppColors.primaryGreen.withOpacity(0.18),
                      onSelected: (val) {
                        _pickSpecificMonth();
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.date_range_outlined, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            currentFilter.type == StatsPeriodType.customRange && currentFilter.customRange != null
                                ? '${DateFormat('dd/MM').format(currentFilter.customRange!.start)} - ${DateFormat('dd/MM').format(currentFilter.customRange!.end)}'
                                : l10n.customPeriod,
                          ),
                        ],
                      ),
                      selected: currentFilter.type == StatsPeriodType.customRange,
                      selectedColor: AppColors.primaryGreen.withOpacity(0.18),
                      onSelected: (val) {
                        _pickCustomRange();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── 2. Statistics Summary Cards Grid ───────────────────────────
              statsAsync.when(
                data: (data) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Financial Summary 3 Cards Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatTile(
                              title: 'المداخيل (CA)',
                              value: '${data.totalRevenue.toStringAsFixed(0)} DA',
                              icon: Icons.account_balance_wallet_outlined,
                              color: AppColors.primaryGreen,
                              subtitle: '${data.completedSessions} حصة مكتملة',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatTile(
                              title: 'المصاريف (Dépenses)',
                              value: '${data.totalExpenses.toStringAsFixed(0)} DA',
                              icon: Icons.money_off_outlined,
                              color: AppColors.warningRed,
                              subtitle: 'تكاليف ومستلزمات',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Net Profit Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: data.netProfit >= 0
                              ? AppColors.primaryGreen.withOpacity(0.08)
                              : AppColors.warningRed.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: data.netProfit >= 0 ? AppColors.primaryGreen : AppColors.warningRed,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'صافي الأرباح (Bénéfice net)',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'المداخيل - المصاريف',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            Text(
                              '${data.netProfit.toStringAsFixed(0)} DA',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: data.netProfit >= 0 ? AppColors.primaryGreen : AppColors.warningRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Operational 3 KPIs Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatTile(
                              title: 'الكؤوس المستعملة',
                              value: '${data.totalCupsUsed}',
                              icon: Icons.medical_services_outlined,
                              color: Colors.blueAccent,
                              subtitle: 'مجموع الاستهلاك',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatTile(
                              title: 'متوسط سعر الحصة',
                              value: '${data.avgSessionPrice.toStringAsFixed(0)} DA',
                              icon: Icons.price_change_outlined,
                              color: Colors.teal,
                              subtitle: 'لكل حصة',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatTile(
                              title: 'متوسط الكؤوس',
                              value: data.avgCupsPerSession.toStringAsFixed(1),
                              icon: Icons.format_list_numbered_outlined,
                              color: Colors.deepPurpleAccent,
                              subtitle: 'كؤوس / حصة',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── 3. Dynamic Activity Charts (fl_chart) ───────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'تطور النشاط اليومي',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          // Toggle Chart Metric (Revenue / Sessions / Cups)
                          SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 0, label: Text('المداخيل', style: TextStyle(fontSize: 10))),
                              ButtonSegment(value: 1, label: Text('الحصص', style: TextStyle(fontSize: 10))),
                              ButtonSegment(value: 2, label: Text('الكؤوس', style: TextStyle(fontSize: 10))),
                            ],
                            selected: {_activeChartType},
                            onSelectionChanged: (set) {
                              setState(() => _activeChartType = set.first);
                            },
                            style: SegmentedButton.styleFrom(
                              selectedBackgroundColor: AppColors.primaryGreen,
                              selectedForegroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Bar Chart Box
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
                          child: SizedBox(
                            height: 190,
                            child: data.dailyData.isEmpty
                                ? const Center(child: Text('لا توجد بيانات للفترة المحددة'))
                                : _buildDynamicBarChart(data.dailyData, _activeChartType),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── 4. Cups Stock & Consumption Section ────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.inventory_2_rounded, size: 20, color: AppColors.primaryGreen),
                              SizedBox(width: 6),
                              Text(
                                'مخزون الكؤوس والاستهلاك',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _showRestockDialog,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('تزويد كؤوس'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: const Size(60, 34),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Stock Alert if low
                      if (data.isLowStock)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warningRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warningRed),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppColors.warningRed),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '⚠️ المخزون منخفض جدًا: تبقى ${data.currentCupStock} كؤوس فقط!',
                                  style: const TextStyle(
                                    color: AppColors.warningRed,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Stock Equation Card: Initial + Purchases - Used = Current
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStockMiniTile('المخزون الحالي', '${data.currentCupStock} كأس', AppColors.primaryGreen),
                                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                  _buildStockMiniTile('المستعمل بالفترة', '${data.totalCupsUsed} كأس', Colors.blueAccent),
                                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                  _buildStockMiniTile('شحنات مشتراة', '${data.totalCupsPurchased} كأس', Colors.purple),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── 5. Expenses Management Section ─────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 20, color: AppColors.warningRed),
                              SizedBox(width: 6),
                              Text(
                                'المصاريف والنفقات',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => AddExpenseModal.show(context),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('إضافة مصروف'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warningRed,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: const Size(60, 34),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Expenses List
                      expensesAsync.when(
                        data: (expenses) {
                          if (expenses.isEmpty) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Center(child: Text('لا توجد مصاريف مسجلة')),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: expenses.take(5).length,
                            itemBuilder: (context, index) {
                              final exp = expenses[index];
                              final id = exp['id'] as String;
                              final cat = exp['category'] ?? 'مصروف';
                              final amt = ((exp['amount'] ?? 0) as num).toDouble();
                              final desc = exp['description'] ?? '';
                              final rawDate = exp['date'] ?? exp['createdAt'];
                              final date = rawDate != null ? DateFormat('dd/MM/yyyy').format((rawDate as dynamic).toDate()) : '';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.warningRed.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.money_off, color: AppColors.warningRed, size: 18),
                                  ),
                                  title: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text(
                                    desc.isNotEmpty ? '$desc • $date' : date,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '-${amt.toStringAsFixed(0)} DA',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.warningRed,
                                          fontSize: 14,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                        onPressed: () {
                                          ref.read(expensesRepositoryProvider).deleteExpense(id);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 40),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: AppColors.primaryGreen),
                  ),
                ),
                error: (e, _) => Center(child: Text('خطأ في تحميل الإحصائيات: $e')),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 3) return;
          if (index == 0) context.go('/dashboard');
          if (index == 1) context.go('/sessions');
          if (index == 2) context.go('/customers');
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

  Widget _buildPeriodChip(StatsPeriodType type, String label, StatsPeriodType currentType) {
    final isSelected = currentType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryGreen.withOpacity(0.18),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryGreen : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (val) {
        if (val) {
          ref.read(selectedStatsFilterProvider.notifier).state = StatsPeriodFilter(type: type);
        }
      },
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                ),
                Icon(icon, color: color, size: 16),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockMiniTile(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildDynamicBarChart(List<DailyChartDataPoint> data, int metricType) {
    final maxVal = data.map((d) {
      if (metricType == 0) return d.revenue;
      if (metricType == 1) return d.sessionsCount.toDouble();
      return d.cupsUsed.toDouble();
    }).fold<double>(0.0, (a, b) => a > b ? a : b);

    Color barColor;
    if (metricType == 0) {
      barColor = AppColors.primaryGreen;
    } else if (metricType == 1) {
      barColor = AppColors.statusConfirmed;
    } else {
      barColor = Colors.deepPurpleAccent;
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal > 0 ? maxVal * 1.25 : 10,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = data[group.x.toInt()];
              String valStr = rod.toY.toStringAsFixed(0);
              if (metricType == 0) valStr += ' DA';
              if (metricType == 2) valStr += ' كؤوس';
              return BarTooltipItem(
                '${item.label}\n$valStr',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                // Show label every few days if many points
                if (data.length > 10 && idx % 3 != 0) return const SizedBox.shrink();
                return Text(
                  data[idx].label,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          final idx = entry.key;
          final d = entry.value;
          double yVal = d.revenue;
          if (metricType == 1) yVal = d.sessionsCount.toDouble();
          if (metricType == 2) yVal = d.cupsUsed.toDouble();

          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: yVal,
                color: barColor,
                width: data.length > 15 ? 8 : 14,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
