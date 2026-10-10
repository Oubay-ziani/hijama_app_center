import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/local_storage.dart';
import '../providers/sessions_provider.dart';

class CompleteSessionModal extends ConsumerStatefulWidget {
  final String sessionId;
  final String customerName;
  final String? customerPhone;
  final double? initialPrice;
  final int? initialCups;
  final String? initialNotes;

  const CompleteSessionModal({
    super.key,
    required this.sessionId,
    required this.customerName,
    this.customerPhone,
    this.initialPrice,
    this.initialCups,
    this.initialNotes,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String sessionId,
    required String customerName,
    String? customerPhone,
    double? initialPrice,
    int? initialCups,
    String? initialNotes,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CompleteSessionModal(
        sessionId: sessionId,
        customerName: customerName,
        customerPhone: customerPhone,
        initialPrice: initialPrice,
        initialCups: initialCups,
        initialNotes: initialNotes,
      ),
    );
  }

  @override
  ConsumerState<CompleteSessionModal> createState() => _CompleteSessionModalState();
}

class _CompleteSessionModalState extends ConsumerState<CompleteSessionModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceController;
  late final TextEditingController _cupsController;
  late final TextEditingController _notesController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final defaultPrice = widget.initialPrice ?? LocalStorage.getDefaultPrice();
    final defaultCups = widget.initialCups ?? LocalStorage.getDefaultCups();

    _priceController = TextEditingController(
      text: defaultPrice > 0 ? defaultPrice.toStringAsFixed(0) : '2500',
    );
    _cupsController = TextEditingController(
      text: defaultCups > 0 ? defaultCups.toString() : '6',
    );
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _priceController.dispose();
    _cupsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text) ?? 0.0;
    final cups = int.tryParse(_cupsController.text) ?? 0;

    setState(() => _isLoading = true);

    final repo = ref.read(sessionsRepositoryProvider);
    final success = await repo.completeSession(
      sessionId: widget.sessionId,
      price: price,
      cupsUsed: cups,
      notes: _notesController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('تم حفظ تفاصيل الحصة بنجاح ($price دج - $cups كأس)'),
              ],
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء حفظ تفاصيل الحصة'),
            backgroundColor: AppColors.warningRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.price_check_rounded,
                        color: AppColors.primaryAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.completeSession,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.customerName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // Price Input
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: '${l10n.sessionPrice} *',
                hintText: '2500',
                prefixIcon: const Icon(Icons.monetization_on_outlined, color: AppColors.primaryGreen),
                suffixText: 'DA',
                suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'يرجى إدخال سعر الحصة';
                }
                if (double.tryParse(val) == null) {
                  return 'يرجى إدخال رقم صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Cups Used Input
            TextFormField(
              controller: _cupsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: '${l10n.cupsCount} *',
                hintText: '12',
                prefixIcon: const Icon(Icons.medical_services_outlined, color: AppColors.primaryGreen),
                suffixText: 'كأس / Ventouses',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'يرجى إدخال عدد الكؤوس المستعملة';
                }
                if (int.tryParse(val) == null) {
                  return 'يرجى إدخال عدد صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Quick Cups Stepper chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [6, 8, 10, 12, 14, 16, 20].map((count) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: ActionChip(
                      label: Text('$count كؤوس'),
                      backgroundColor: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                      onPressed: () {
                        setState(() {
                          _cupsController.text = count.toString();
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: '${l10n.notes} (اختياري)',
                hintText: 'ملاحظات حول الحصة، استجابة المريض، التوصيات...',
                prefixIcon: const Icon(Icons.edit_note_outlined),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          l10n.saveSession,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
