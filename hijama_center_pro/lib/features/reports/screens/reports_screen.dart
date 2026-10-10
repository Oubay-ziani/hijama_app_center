import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../statistics/providers/statistics_provider.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isGeneratingPdf = false;
  bool _isGeneratingExcel = false;

  void _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'اختر شهر التقرير',
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  void _exportMonthlyPdf() async {
    setState(() => _isGeneratingPdf = true);
    final repo = ref.read(reportsRepositoryProvider);
    final success = await repo.compileMonthlyPdfReport(_selectedMonth);
    setState(() => _isGeneratingPdf = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('تم إنشاء تقرير شهر ${DateFormat('MMMM yyyy').format(_selectedMonth)} بصيغة PDF بنجاح!'),
              ],
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل إنشاء تقرير PDF'),
            backgroundColor: AppColors.warningRed,
          ),
        );
      }
    }
  }

  void _exportExcel() async {
    setState(() => _isGeneratingExcel = true);
    final repo = ref.read(reportsRepositoryProvider);
    final success = await repo.compileMonthlyExcel();
    setState(() => _isGeneratingExcel = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تصدير ملف الإكسيل بنجاح!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل تصدير الإكسيل'), backgroundColor: AppColors.warningRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Temporary stats filter to show preview for selected month
    final statsFilter = StatsPeriodFilter(
      type: StatsPeriodType.specificMonth,
      specificMonth: _selectedMonth,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير الشهرية / Rapports'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Selector Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.calendar_month, color: AppColors.primaryGreen, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('شهر التقرير / Mois du rapport', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('MMMM yyyy').format(_selectedMonth),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _pickMonth,
                      icon: const Icon(Icons.edit_calendar, size: 16),
                      label: const Text('تغيير الشهر'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                        foregroundColor: isDark ? Colors.white : AppColors.lightTextPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: const Size(60, 36),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Monthly Report Preview & Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'معاينة التقرير الشهري',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'A4 Printable PDF',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Information items
                    _buildPreviewRow('اسم المركز:', 'مركز الحجامة برو / Hijama Center Pro'),
                    _buildPreviewRow('الفترة:', DateFormat('MMMM yyyy').format(_selectedMonth)),
                    _buildPreviewRow('المحتويات:', 'الحصص المكتملة • المداخيل • الكؤوس المستعملة • المصاريف • صافي الأرباح'),
                    const Divider(height: 24),

                    // Primary PDF Export Button
                    ElevatedButton.icon(
                      onPressed: _isGeneratingPdf ? null : _exportMonthlyPdf,
                      icon: _isGeneratingPdf
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.picture_as_pdf_rounded),
                      label: Text(
                        _isGeneratingPdf ? 'جاري إنشاء ملف PDF...' : 'تصدير التقرير الشهري PDF / Exporter PDF',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Excel Export Option
                    OutlinedButton.icon(
                      onPressed: _isGeneratingExcel ? null : _exportExcel,
                      icon: _isGeneratingExcel
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.table_chart_outlined),
                      label: Text(_isGeneratingExcel ? 'جاري التصدير...' : 'تصدير جدول الحسابات إكسيل (Excel)'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Additional Quick Tools (Daily summary, Inventory sheet)
            const Text(
              'تقارير إضافية',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.tealAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.today, color: AppColors.tealAccent),
                ),
                title: const Text('تقرير العمليات اليومي (Daily Report)'),
                subtitle: const Text('ملخص فوري لنشاط اليوم بصيغة PDF'),
                trailing: const Icon(Icons.download, size: 20),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final success = await ref.read(reportsRepositoryProvider).compileDailyReport();
                  if (success) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('تم تصدير التقرير اليومي بنجاح')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.statusConfirmed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.checklist_rtl_rounded, color: AppColors.statusConfirmed),
                ),
                title: const Text('كشف المخزون وجرد الكؤوس (Inventory PDF)'),
                subtitle: const Text('قائمة مستلزمات المركز وحدود النقص'),
                trailing: const Icon(Icons.download, size: 20),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final success = await ref.read(reportsRepositoryProvider).compileInventoryReport();
                  if (success) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('تم تصدير كشف المخزون بنجاح')),
                    );
                  }
                },
              ),
            ),
          ],
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

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
