import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/sessions_provider.dart';
import 'complete_session_modal.dart';

class SessionCard extends ConsumerWidget {
  final Map<String, dynamic> session;
  final VoidCallback? onTap;

  const SessionCard({
    super.key,
    required this.session,
    this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return AppColors.statusCompleted;
      case 'CONFIRMED':
        return AppColors.statusConfirmed;
      case 'CANCELLED':
        return AppColors.statusCancelled;
      case 'RESERVED':
      default:
        return AppColors.statusReserved;
    }
  }

  String _getStatusText(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return l10n.statusCompleted;
      case 'CONFIRMED':
        return l10n.statusConfirmed;
      case 'CANCELLED':
        return l10n.statusCancelled;
      case 'RESERVED':
      default:
        return l10n.statusReserved;
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warningRed),
            SizedBox(width: 8),
            Text('حذف الحصة؟'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذه الحصة؟ سيتم تحديث الإحصائيات والمخزون تلقائيًا.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.warningRed),
            child: const Text('تأكيد الحذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(sessionsRepositoryProvider).deleteSession(id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الحصة بنجاح')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل حذف الحصة'), backgroundColor: AppColors.warningRed),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final id = session['id'] as String? ?? '';
    final name = (session['customerName'] ?? session['customer_name'] ?? session['name'] ?? 'عميل غير مسجل').toString();
    final phone = (session['customerPhone'] ?? session['customer_phone'] ?? session['phone'] ?? '').toString();
    final rawDate = session['scheduledAt'] ?? session['date'] ?? session['createdAt'];
    DateTime date = DateTime.now();
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    }

    final status = (session['status'] ?? 'RESERVED').toString().toUpperCase();
    final isCompleted = status == 'COMPLETED';
    final price = double.tryParse(session['price']?.toString() ?? session['pricePaid']?.toString() ?? session['cost']?.toString() ?? '0') ?? 0.0;
    final cups = int.tryParse(session['cupsUsed']?.toString() ?? session['cups_used']?.toString() ?? '0') ?? 0;
    final type = (session['sessionType'] ?? session['session_type'] ?? 'WET_CUPPING').toString();
    final bodyArea = (session['bodyArea'] ?? session['body_area'] ?? '').toString();
    final notes = (session['notes'] ?? '').toString();

    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Date, Time & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${DateFormat('dd/MM/yyyy').format(date)} @ ${DateFormat('HH:mm').format(date)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _getStatusText(context, status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Customer Name & Phone
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                        if (phone.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              phone,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Cupping type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      type.replaceAll('_', ' '),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              if (bodyArea.isNotEmpty || notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                if (bodyArea.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.accessibility_new, size: 14, color: AppColors.tealAccent),
                      const SizedBox(width: 4),
                      Text(
                        bodyArea,
                        style: const TextStyle(fontSize: 12, color: AppColors.tealAccent, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                if (notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'ملاحظة: $notes',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],

              const Divider(height: 20),

              // Bottom Row: Financial outcome (if completed) OR Action Button (if pending)
              if (isCompleted) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${price.toStringAsFixed(0)} DA',
                            style: const TextStyle(
                              color: AppColors.primaryAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$cups كؤوس',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'تعديل السعر والكؤوس',
                          onPressed: () {
                            CompleteSessionModal.show(
                              context,
                              sessionId: id,
                              customerName: name,
                              customerPhone: phone,
                              initialPrice: price,
                              initialCups: cups,
                              initialNotes: notes,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.warningRed),
                          tooltip: 'حذف الحصة',
                          onPressed: () => _confirmDelete(context, ref, id),
                        ),
                      ],
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.warningRed, size: 20),
                      onPressed: () => _confirmDelete(context, ref, id),
                    ),
                    const Spacer(),
                    if (status != 'CANCELLED') ...[
                      TextButton(
                        onPressed: () {
                          ref.read(sessionsRepositoryProvider).updateStatus(id, 'CANCELLED');
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.grey),
                        child: const Text('إلغاء'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    ElevatedButton.icon(
                      onPressed: () {
                        CompleteSessionModal.show(
                          context,
                          sessionId: id,
                          customerName: name,
                          customerPhone: phone,
                        );
                      },
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: Text(l10n.completeSession),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: const Size(60, 36),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
