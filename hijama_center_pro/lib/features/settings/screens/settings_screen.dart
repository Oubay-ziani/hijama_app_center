import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();
  
  bool _isChangingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('كلمة المرور الجديدة وتأكيدها غير متطابقين!'),
          backgroundColor: AppColors.warningRed,
        ),
      );
      return;
    }

    setState(() => _isChangingPassword = true);

    final success = await ref.read(authProvider.notifier).changePassword(
          _currentPasswordController.text,
          _newPasswordController.text,
        );

    setState(() => _isChangingPassword = false);

    if (mounted) {
      if (success) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تم تحديث كلمة المرور بنجاح!'),
              ],
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('فشل تحديث كلمة المرور. تحقق من كلمة المرور الحالية.'),
              ],
            ),
            backgroundColor: AppColors.warningRed,
          ),
        );
      }
    }
  }

  void _showEditCenterProfileModal() {
    final center = ref.read(centerProfileProvider);
    final nameCtrl = TextEditingController(text: center.centerName);
    final specCtrl = TextEditingController(text: center.specialistName);
    final phoneCtrl = TextEditingController(text: center.phone);
    final addressCtrl = TextEditingController(text: center.address);
    final currencyCtrl = TextEditingController(text: center.currency);
    final footerCtrl = TextEditingController(text: center.receiptFooter);
    final licenseCtrl = TextEditingController(text: center.licenseNumber);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                              child: const Icon(Icons.local_hospital_rounded, color: AppColors.primaryGreen),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'بيانات وهوية المركز',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'اسم المركز / العيادة',
                        prefixIcon: Icon(Icons.business_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال اسم المركز' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: specCtrl,
                      decoration: const InputDecoration(
                        labelText: 'اسم الأخصائي / المعالج المسؤول',
                        prefixIcon: Icon(Icons.person_pin_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'رقم الهاتف / واتساب',
                              prefixIcon: Icon(Icons.phone_rounded),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: currencyCtrl,
                            decoration: const InputDecoration(
                              labelText: 'رمز العملة',
                              prefixIcon: Icon(Icons.monetization_on_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'العنوان والمدينة',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: licenseCtrl,
                      decoration: const InputDecoration(
                        labelText: 'رقم الاعتماد الطبي / الرخصة',
                        prefixIcon: Icon(Icons.verified_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: footerCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'عبارة أسفل الوصفة والتقارير',
                        prefixIcon: Icon(Icons.format_quote_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('حفظ هوية المركز', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          await ref.read(centerProfileProvider.notifier).updateProfile(
                                centerName: nameCtrl.text.trim(),
                                specialistName: specCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                address: addressCtrl.text.trim(),
                                currency: currencyCtrl.text.trim(),
                                receiptFooter: footerCtrl.text.trim(),
                                licenseNumber: licenseCtrl.text.trim(),
                              );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم حفظ بيانات المركز بنجاح!'),
                                backgroundColor: AppColors.primaryGreen,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditClinicalDefaultsModal() {
    final hijama = ref.read(hijamaDefaultsProvider);
    final priceCtrl = TextEditingController(text: hijama.defaultPrice.toStringAsFixed(0));
    final cupsCtrl = TextEditingController(text: hijama.defaultCups.toString());
    final stockCtrl = TextEditingController(text: hijama.lowStockThreshold.toString());
    final bpCtrl = TextEditingController(text: hijama.highBpThreshold.toString());
    final fastingCtrl = TextEditingController(text: hijama.fastingHours.toString());
    final whatsappCtrl = TextEditingController(text: hijama.whatsappTemplate);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.tealAccent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.healing_rounded, color: AppColors.tealAccent),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'بروتوكول وإعدادات الحجامة',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'السعر الافتراضي للحصة',
                              prefixIcon: Icon(Icons.price_check_rounded),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || double.tryParse(v) == null ? 'قيمة غير صحيحة' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: cupsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'كؤوس الحصة الافتراضية',
                              prefixIcon: Icon(Icons.bubble_chart_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || int.tryParse(v) == null ? 'قيمة غير صحيحة' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'حد تنبيه نقص المخزون',
                              prefixIcon: Icon(Icons.inventory_2_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || int.tryParse(v) == null ? 'قيمة غير صحيحة' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: bpCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'حد تحذير ضغط الدم (Sys)',
                              prefixIcon: Icon(Icons.favorite_border_rounded),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || int.tryParse(v) == null ? 'قيمة غير صحيحة' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: fastingCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ساعات الصيام الموصى بها قبل الجلسة',
                        prefixIcon: Icon(Icons.timer_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || int.tryParse(v) == null ? 'قيمة غير صحيحة' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: whatsappCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'قالب رسالة تذكير الموعد (واتساب)',
                        helperText: 'استخدم {date} للتاريخ و {time} للتوقيت',
                        prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tealAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('حفظ بروتوكول الحجامة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          await ref.read(hijamaDefaultsProvider.notifier).updateClinicalDefaults(
                                defaultPrice: double.parse(priceCtrl.text.trim()),
                                defaultCups: int.parse(cupsCtrl.text.trim()),
                                lowStockThreshold: int.parse(stockCtrl.text.trim()),
                                highBpThreshold: int.parse(bpCtrl.text.trim()),
                                fastingHours: int.parse(fastingCtrl.text.trim()),
                                whatsappTemplate: whatsappCtrl.text.trim(),
                              );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم حفظ بروتوكول الحجامة بنجاح!'),
                                backgroundColor: AppColors.primaryGreen,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showClinicQrDialog() {
    final center = ref.read(centerProfileProvider);
    final qrData = 'MECARD:N:${center.centerName};TEL:${center.phone};ADR:${center.address};NOTE:${center.specialistName} - ${center.receiptFooter};;';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_2_rounded, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('رمز QR الخاص بالمركز', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'يمكن للمرضى مسح هذا الرمز لحفظ بيانات المركز ورقم الواتساب مباشرة على هواتفهم:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(center.centerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(center.phone, style: const TextStyle(color: AppColors.tealAccent, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('نسخ البيانات'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '${center.centerName}\nالهاتف: ${center.phone}\nالعنوان: ${center.address}'));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نسخ بيانات المركز إلى الحافظة')),
              );
            },
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showDatabaseExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cloud_download_rounded, color: AppColors.infoBlue),
            SizedBox(width: 8),
            Text('النسخ الاحتياطي السحابي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'جميع بيانات المركز (المرضى، الجلسات، المخزون، والمداخيل) متزامنة تلقائياً وبأمان عبر سحابة Google Firebase Cloud Firestore المشفرة.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 18),
                SizedBox(width: 8),
                Text('حالة المزامنة: متصل ومتزامن (Live Sync)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.security, color: AppColors.tealAccent, size: 18),
                SizedBox(width: 8),
                Text('تشفير البيانات: AES-256 Cloud Shield', style: TextStyle(fontSize: 13)),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('تصدير كتقرير PDF شامل'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/reports/export');
            },
          ),
          TextButton(
            child: const Text('إغلاق'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final language = ref.watch(languageProvider);
    final user = ref.watch(authProvider).user;
    final center = ref.watch(centerProfileProvider);
    final hijama = ref.watch(hijamaDefaultsProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.settings_suggest_rounded, color: AppColors.primaryAccent),
            const SizedBox(width: 10),
            Text(l10n.settings, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_rounded),
            tooltip: 'رمز QR للمركز',
            onPressed: _showClinicQrDialog,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'تصدير التقارير',
            onPressed: () => context.go('/reports/export'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. VIP Center Header Profile Card
            _buildCenterProfileHeader(center, isDark),
            const SizedBox(height: 18),

            // 2. Sunnah Hijama Days Alert & Prophetic Cupping Reminder Banner (Special Hijama Feature)
            _buildSunnahDaysBanner(hijama, isDark),
            const SizedBox(height: 18),

            // 3. Hijama Clinical Defaults & Protocols
            _buildSectionHeader('بروتوكول الحجامة والجلسات الافتراضية', Icons.medical_services_outlined, AppColors.tealAccent),
            const SizedBox(height: 8),
            _buildClinicalDefaultsCard(hijama, center, isDark),
            const SizedBox(height: 18),

            // 4. Preferences, Theme & Language
            _buildSectionHeader('المظهر والتخصيص واللغة', Icons.palette_outlined, AppColors.purpleAccent),
            const SizedBox(height: 8),
            _buildAppearanceCard(language, isDark),
            const SizedBox(height: 18),

            // 5. Notifications & Smart Clinical Reminders
            _buildSectionHeader('التنبيهات والمواعيد الذكية', Icons.notifications_active_outlined, AppColors.alertOrange),
            const SizedBox(height: 8),
            _buildNotificationsCard(hijama, isDark),
            const SizedBox(height: 18),

            // 6. Security & Password Section
            _buildSectionHeader('الأمان والحساب', Icons.lock_outline_rounded, AppColors.infoBlue),
            const SizedBox(height: 8),
            _buildSecurityCard(user, isDark),
            const SizedBox(height: 18),

            // 7. System Data, Backup & Cloud Sync
            _buildSectionHeader('البيانات والنسخ الاحتياطي', Icons.cloud_done_outlined, AppColors.primaryGreen),
            const SizedBox(height: 8),
            _buildDataBackupCard(isDark),
            const SizedBox(height: 24),

            // 8. Logout & License Footer
            _buildLogoutAndFooter(l10n),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 4) return;
          if (index == 0) context.go('/dashboard');
          if (index == 1) context.go('/sessions');
          if (index == 2) context.go('/customers');
          if (index == 3) context.go('/reports');
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

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.2),
        ),
      ],
    );
  }

  Widget _buildCenterProfileHeader(CenterProfile center, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [AppColors.primaryGreen, const Color(0xFF0B3D25)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                ),
                child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      center.centerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.person_pin, color: AppColors.primaryAccent, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            center.specialistName,
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primaryAccent, width: 0.8),
                          ),
                          child: Text(
                            center.licenseNumber,
                            style: const TextStyle(color: AppColors.primaryAccent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, color: Colors.white70, size: 15),
                    const SizedBox(width: 6),
                    Text(center.phone, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white70, size: 15),
                    const SizedBox(width: 4),
                    Text(center.address, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.monetization_on_outlined, color: AppColors.primaryAccent, size: 15),
                    const SizedBox(width: 4),
                    Text(center.currency, style: const TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text('تعديل هوية المركز', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _showEditCenterProfileModal,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.qr_code, size: 18),
                label: const Text('رمز المركز', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _showClinicQrDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSunnahDaysBanner(HijamaDefaults hijama, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132A1C) : const Color(0xFFECFDF5),
        border: Border.all(color: AppColors.primaryAccent.withOpacity(0.4), width: 1.2),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.brightness_3_rounded, color: AppColors.primaryAccent, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أيام الحجامة النبوية المستحبة (أيام السنة)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '17 ، 19 ، 21 من كل شهر قمري / هجري',
                      style: TextStyle(fontSize: 12, color: AppColors.primaryAccent, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Switch(
                value: hijama.sunnahDaysReminder,
                activeColor: AppColors.primaryAccent,
                onChanged: (val) {
                  ref.read(hijamaDefaultsProvider.notifier).toggleSunnahReminder();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(val ? 'تم تفعيل تنبيهات أيام السنة النبوية' : 'تم تعطيل تنبيهات أيام السنة'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'قال ﷺ: «من احتجم لسبع عشرة وتسع عشرة وإحدى وعشرين كان شفاء من كل داء». يوفر النظام إشعاراً مسبقاً لاستقبال وتجهيز حجوزات المرضى في هذه الأيام المباركة.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalDefaultsCard(HijamaDefaults hijama, CenterProfile center, bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'السعر الافتراضي',
                    value: '${hijama.defaultPrice.toStringAsFixed(0)} ${center.currency}',
                    icon: Icons.payments_outlined,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    title: 'الكؤوس الافتراضية',
                    value: '${hijama.defaultCups} كؤوس / حصة',
                    icon: Icons.bubble_chart_outlined,
                    color: AppColors.tealAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'تنبيه نقص المخزون',
                    value: 'أقل من ${hijama.lowStockThreshold} كأس',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.alertOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    title: 'تحذير ضغط الدم',
                    value: '> ${hijama.highBpThreshold} mmHg',
                    icon: Icons.favorite_border_rounded,
                    color: AppColors.warningRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: AppColors.tealAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'توجيه الصيام: يُنصح المريض بالصيام ${hijama.fastingHours} ساعات قبل الحصة',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                icon: const Icon(Icons.tune_rounded),
                label: const Text('تعديل معايير وبروتوكول الجلسات', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _showEditClinicalDefaultsModal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceCard(String language, bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('المظهر الداكن (Dark Mode)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('راحة العينين وتوفير البطارية'),
            value: isDark,
            activeColor: AppColors.primaryAccent,
            onChanged: (val) {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.indigo.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: isDark ? Colors.indigoAccent : Colors.amber.shade700,
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.language_rounded, color: AppColors.primaryGreen),
            ),
            title: const Text('لغة التطبيق / Langue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(language == 'ar' ? 'العربية' : language == 'fr' ? 'Français' : 'English'),
            trailing: DropdownButton<String>(
              value: language,
              underline: const SizedBox.shrink(),
              onChanged: (lang) {
                if (lang != null) {
                  ref.read(languageProvider.notifier).setLanguage(lang);
                }
              },
              items: const [
                DropdownMenuItem(value: 'ar', child: Text('🇩🇿 العربية')),
                DropdownMenuItem(value: 'fr', child: Text('🇫🇷 Français')),
                DropdownMenuItem(value: 'en', child: Text('🇬🇧 English')),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.tealAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.currency_exchange_rounded, color: AppColors.tealAccent),
            ),
            title: const Text('العملة المعتمدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('تغيير رمز العملة في كافة السجلات والفواتير'),
            trailing: DropdownButton<String>(
              value: ref.watch(centerProfileProvider).currency,
              underline: const SizedBox.shrink(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(centerProfileProvider.notifier).setCurrency(val);
                }
              },
              items: const [
                DropdownMenuItem(value: 'دج', child: Text('دج (دينار جزائري)')),
                DropdownMenuItem(value: 'ر.س', child: Text('ر.س (ريال سعودي)')),
                DropdownMenuItem(value: 'د.إ', child: Text('د.إ (درهم إماراتي)')),
                DropdownMenuItem(value: 'EUR €', child: Text('EUR € (يورو)')),
                DropdownMenuItem(value: 'USD \$', child: Text('USD \$ (دولار)')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard(HijamaDefaults hijama, bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('تنبيهات نقص المخزون', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('إشعار فوري عند انخفاض كؤوس الحجامة والمستلزمات'),
            value: hijama.stockAlerts,
            activeColor: AppColors.alertOrange,
            onChanged: (val) {
              ref.read(hijamaDefaultsProvider.notifier).toggleStockAlerts();
            },
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.alertOrange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: AppColors.alertOrange),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryAccent),
            ),
            title: const Text('قالب رسائل الواتساب للتذكير بالمواعيد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              hijama.whatsappTemplate,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: _showEditClinicalDefaultsModal,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(Map<String, dynamic>? user, bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
                  child: const Icon(Icons.admin_panel_settings, color: AppColors.primaryGreen, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الحساب المسجل (Admin Manager)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        user?['email'] ?? 'clinic_admin@hijama.pro',
                        style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('نشط ومحمي', style: TextStyle(color: AppColors.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 24),
            Form(
              key: _passwordFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('تغيير كلمة المرور', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور الحالية',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال كلمة المرور الحالية' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور الجديدة',
                      prefixIcon: const Icon(Icons.lock_reset),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    validator: (v) => v == null || v.length < 6 ? 'يجب أن لا تقل عن 6 أحرف' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور الجديدة',
                      prefixIcon: const Icon(Icons.check_circle_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'يرجى تأكيد كلمة المرور' : null,
                  ),
                  const SizedBox(height: 14),
                  _isChangingPassword
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                      : ElevatedButton.icon(
                          onPressed: _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text('تحديث كلمة المرور'),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataBackupCard(bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.infoBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cloud_sync_rounded, color: AppColors.infoBlue),
            ),
            title: const Text('حالة المزامنة السحابية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Firestore Cloud Sync: متصل ومؤمن 24/7'),
            trailing: const Icon(Icons.info_outline, size: 18),
            onTap: _showDatabaseExportDialog,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primaryGreen),
            ),
            title: const Text('التقارير الشهرية وتصدير PDF / Excel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('إنشاء واستخراج تقارير مالية وطبية كاملة للعيادة'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => context.go('/reports/export'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutAndFooter(AppLocalizations l10n) {
    return Column(
      children: [
        Card(
          elevation: 0,
          color: AppColors.warningRed.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.warningRed.withOpacity(0.3)),
          ),
          child: ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.warningRed),
            title: Text(
              l10n.logout,
              style: const TextStyle(color: AppColors.warningRed, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('إنهاء الجلسة وتسجيل الخروج من النظام'),
            trailing: const Icon(Icons.exit_to_app_rounded, color: AppColors.warningRed),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('تأكيد تسجيل الخروج'),
                  content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج من مركز الحجامة برو؟'),
                  actions: [
                    TextButton(
                      child: const Text('إلغاء'),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warningRed,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('تسجيل الخروج'),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified, color: AppColors.primaryGreen, size: 16),
            const SizedBox(width: 6),
            Text(
              'مركز الحجامة برو | Hijama Center Pro v2.4.0 Ultimate Edition',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
