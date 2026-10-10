import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../customers/providers/customers_provider.dart';
import '../providers/sessions_provider.dart';

class NewBookingModal extends ConsumerStatefulWidget {
  final String? preselectedCustomerId;
  final String? preselectedCustomerName;
  final String? preselectedCustomerPhone;

  const NewBookingModal({
    super.key,
    this.preselectedCustomerId,
    this.preselectedCustomerName,
    this.preselectedCustomerPhone,
  });

  static Future<bool?> show(
    BuildContext context, {
    String? customerId,
    String? customerName,
    String? customerPhone,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NewBookingModal(
        preselectedCustomerId: customerId,
        preselectedCustomerName: customerName,
        preselectedCustomerPhone: customerPhone,
      ),
    );
  }

  @override
  ConsumerState<NewBookingModal> createState() => _NewBookingModalState();
}

class _NewBookingModalState extends ConsumerState<NewBookingModal> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCustomerId;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _bodyAreaController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _sessionType = 'WET_CUPPING';
  String _bookingStatus = 'CONFIRMED'; // RESERVED or CONFIRMED
  bool _isLoading = false;
  bool _isNewCustomer = true;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedCustomerId != null) {
      _selectedCustomerId = widget.preselectedCustomerId;
      _nameController.text = widget.preselectedCustomerName ?? '';
      _phoneController.text = widget.preselectedCustomerPhone ?? '';
      _isNewCustomer = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _bodyAreaController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final repo = ref.read(sessionsRepositoryProvider);
    final resultId = await repo.createBooking(
      customerId: _selectedCustomerId,
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      scheduledAt: scheduledDateTime,
      sessionType: _sessionType,
      bodyArea: _bodyAreaController.text.trim(),
      notes: _notesController.text.trim(),
      status: _bookingStatus,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (resultId != null) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تم تأكيد الحجز بنجاح / Réservation enregistrée'),
              ],
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء حفظ الحجز. يرجى المحاولة مجددًا.'),
            backgroundColor: AppColors.warningRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customersAsync = ref.watch(customersListProvider);
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
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

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.add_task_rounded,
                          color: AppColors.primaryGreen,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.newSession,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),

              // Customer Selection Toggle (Existing vs New)
              customersAsync.when(
                data: (customers) {
                  if (customers.isEmpty) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isNewCustomer = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_isNewCustomer
                                    ? (isDark ? AppColors.darkSurface : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !_isNewCustomer
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 4,
                                        )
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'اختيار عميل مسجل',
                                  style: TextStyle(
                                    fontWeight: !_isNewCustomer ? FontWeight.bold : FontWeight.normal,
                                    color: !_isNewCustomer ? AppColors.primaryGreen : Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isNewCustomer = true;
                                _selectedCustomerId = null;
                                _nameController.clear();
                                _phoneController.clear();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _isNewCustomer
                                    ? (isDark ? AppColors.darkSurface : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _isNewCustomer
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 4,
                                        )
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'عميل جديد',
                                  style: TextStyle(
                                    fontWeight: _isNewCustomer ? FontWeight.bold : FontWeight.normal,
                                    color: _isNewCustomer ? AppColors.primaryGreen : Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Existing Customer Dropdown Search
              if (!_isNewCustomer)
                customersAsync.when(
                  data: (customers) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: DropdownButtonFormField<String>(
                        value: _selectedCustomerId,
                        decoration: const InputDecoration(
                          labelText: 'اختر العميل / Client',
                          prefixIcon: Icon(Icons.person_search_outlined),
                        ),
                        items: customers.map<DropdownMenuItem<String>>((c) {
                          final name = c['fullName'] ?? c['full_name'] ?? c['name'] ?? 'بدون اسم';
                          final phone = c['phone'] ?? '';
                          return DropdownMenuItem<String>(
                            value: c['id'] as String,
                            child: Text('$name ($phone)', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCustomerId = val;
                            final selected = customers.firstWhere((c) => c['id'] == val, orElse: () => {});
                            _nameController.text = (selected['fullName'] ?? selected['full_name'] ?? selected['name'] ?? '').toString();
                            _phoneController.text = (selected['phone'] ?? '').toString();
                          });
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'يرجى اختيار عميل';
                          }
                          return null;
                        },
                      ),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

              // Client Name Input
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '${l10n.fullName} *',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'الاسم واللقب مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Client Phone Input
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: '${l10n.phone} *',
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'رقم الهاتف مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Date & Time Selectors Row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primaryGreen),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_selectedDate),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_outlined, size: 18, color: AppColors.primaryGreen),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedTime.format(context),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Session Type Selector
              DropdownButtonFormField<String>(
                value: _sessionType,
                decoration: const InputDecoration(
                  labelText: 'نوع الحجامة / Type de séance',
                  prefixIcon: Icon(Icons.spa_outlined),
                ),
                items: [
                  DropdownMenuItem(value: 'WET_CUPPING', child: Text(l10n.wetCupping)),
                  DropdownMenuItem(value: 'DRY_CUPPING', child: Text(l10n.dryCupping)),
                  DropdownMenuItem(value: 'PREVENTIVE', child: Text(l10n.preventive)),
                  DropdownMenuItem(value: 'CURATIVE', child: Text(l10n.curative)),
                  DropdownMenuItem(value: 'MASSAGE', child: Text(l10n.massage)),
                  DropdownMenuItem(value: 'RELAXATION', child: Text(l10n.relaxation)),
                  DropdownMenuItem(value: 'OTHER', child: Text(l10n.other)),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _sessionType = val);
                },
              ),
              const SizedBox(height: 12),

              // Body Area (Optional)
              TextFormField(
                controller: _bodyAreaController,
                decoration: InputDecoration(
                  labelText: '${l10n.bodyArea} (اختياري)',
                  hintText: 'مثال: الظهر، الرأس، الرقبة، الأكتاف...',
                  prefixIcon: const Icon(Icons.accessibility_new_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Notes (Optional)
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: '${l10n.notes} (اختياري)',
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 14),

              // Status Selector (Reserved vs Confirmed)
              Row(
                children: [
                  const Text('حالة الحجز:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: Text(l10n.statusConfirmed),
                    selected: _bookingStatus == 'CONFIRMED',
                    selectedColor: AppColors.statusConfirmed.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _bookingStatus == 'CONFIRMED' ? AppColors.statusConfirmed : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _bookingStatus = 'CONFIRMED');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(l10n.statusReserved),
                    selected: _bookingStatus == 'RESERVED',
                    selectedColor: AppColors.statusReserved.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _bookingStatus == 'RESERVED' ? AppColors.statusReserved : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _bookingStatus = 'RESERVED');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Primary Confirm Button
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
                          const Icon(Icons.check_circle_outline, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            l10n.confirmBooking,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
