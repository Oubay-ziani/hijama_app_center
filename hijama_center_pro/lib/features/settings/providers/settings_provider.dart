import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/local_storage.dart';

// Language Provider
class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super(LocalStorage.getLanguage());

  void setLanguage(String langCode) async {
    await LocalStorage.saveLanguage(langCode);
    state = langCode;
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

// Theme Mode Provider
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_parseThemeMode(LocalStorage.getThemeMode()));

  static ThemeMode _parseThemeMode(String mode) {
    if (mode == 'dark') return ThemeMode.dark;
    return ThemeMode.light;
  }

  void toggleTheme() async {
    if (state == ThemeMode.light) {
      await LocalStorage.saveThemeMode('dark');
      state = ThemeMode.dark;
    } else {
      await LocalStorage.saveThemeMode('light');
      state = ThemeMode.light;
    }
  }

  void setThemeMode(ThemeMode mode) async {
    await LocalStorage.saveThemeMode(mode == ThemeMode.dark ? 'dark' : 'light');
    state = mode;
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

// Center Profile State Model
class CenterProfile {
  final String centerName;
  final String specialistName;
  final String phone;
  final String address;
  final String currency;
  final String receiptFooter;
  final String licenseNumber;

  CenterProfile({
    required this.centerName,
    required this.specialistName,
    required this.phone,
    required this.address,
    required this.currency,
    required this.receiptFooter,
    required this.licenseNumber,
  });

  CenterProfile copyWith({
    String? centerName,
    String? specialistName,
    String? phone,
    String? address,
    String? currency,
    String? receiptFooter,
    String? licenseNumber,
  }) {
    return CenterProfile(
      centerName: centerName ?? this.centerName,
      specialistName: specialistName ?? this.specialistName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      currency: currency ?? this.currency,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      licenseNumber: licenseNumber ?? this.licenseNumber,
    );
  }
}

class CenterProfileNotifier extends StateNotifier<CenterProfile> {
  CenterProfileNotifier()
      : super(
          CenterProfile(
            centerName: LocalStorage.getCenterName(),
            specialistName: LocalStorage.getSpecialistName(),
            phone: LocalStorage.getPhone(),
            address: LocalStorage.getAddress(),
            currency: LocalStorage.getCurrency(),
            receiptFooter: LocalStorage.getReceiptFooter(),
            licenseNumber: LocalStorage.getLicenseNumber(),
          ),
        );

  Future<void> updateProfile({
    required String centerName,
    required String specialistName,
    required String phone,
    required String address,
    required String currency,
    required String receiptFooter,
    required String licenseNumber,
  }) async {
    await LocalStorage.saveCenterName(centerName);
    await LocalStorage.saveSpecialistName(specialistName);
    await LocalStorage.savePhone(phone);
    await LocalStorage.saveAddress(address);
    await LocalStorage.saveCurrency(currency);
    await LocalStorage.saveReceiptFooter(receiptFooter);
    await LocalStorage.saveLicenseNumber(licenseNumber);

    state = CenterProfile(
      centerName: centerName,
      specialistName: specialistName,
      phone: phone,
      address: address,
      currency: currency,
      receiptFooter: receiptFooter,
      licenseNumber: licenseNumber,
    );
  }

  Future<void> setCurrency(String currency) async {
    await LocalStorage.saveCurrency(currency);
    state = state.copyWith(currency: currency);
  }
}

final centerProfileProvider = StateNotifierProvider<CenterProfileNotifier, CenterProfile>((ref) {
  return CenterProfileNotifier();
});

// Hijama Clinical Defaults State Model
class HijamaDefaults {
  final double defaultPrice;
  final int defaultCups;
  final int lowStockThreshold;
  final int highBpThreshold;
  final int fastingHours;
  final String whatsappTemplate;
  final bool sunnahDaysReminder;
  final bool stockAlerts;

  HijamaDefaults({
    required this.defaultPrice,
    required this.defaultCups,
    required this.lowStockThreshold,
    required this.highBpThreshold,
    required this.fastingHours,
    required this.whatsappTemplate,
    required this.sunnahDaysReminder,
    required this.stockAlerts,
  });

  HijamaDefaults copyWith({
    double? defaultPrice,
    int? defaultCups,
    int? lowStockThreshold,
    int? highBpThreshold,
    int? fastingHours,
    String? whatsappTemplate,
    bool? sunnahDaysReminder,
    bool? stockAlerts,
  }) {
    return HijamaDefaults(
      defaultPrice: defaultPrice ?? this.defaultPrice,
      defaultCups: defaultCups ?? this.defaultCups,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      highBpThreshold: highBpThreshold ?? this.highBpThreshold,
      fastingHours: fastingHours ?? this.fastingHours,
      whatsappTemplate: whatsappTemplate ?? this.whatsappTemplate,
      sunnahDaysReminder: sunnahDaysReminder ?? this.sunnahDaysReminder,
      stockAlerts: stockAlerts ?? this.stockAlerts,
    );
  }
}

class HijamaDefaultsNotifier extends StateNotifier<HijamaDefaults> {
  HijamaDefaultsNotifier()
      : super(
          HijamaDefaults(
            defaultPrice: LocalStorage.getDefaultPrice(),
            defaultCups: LocalStorage.getDefaultCups(),
            lowStockThreshold: LocalStorage.getLowStockThreshold(),
            highBpThreshold: LocalStorage.getHighBpThreshold(),
            fastingHours: LocalStorage.getFastingHours(),
            whatsappTemplate: LocalStorage.getWhatsappTemplate(),
            sunnahDaysReminder: LocalStorage.getSunnahDaysReminder(),
            stockAlerts: LocalStorage.getStockAlerts(),
          ),
        );

  Future<void> updateClinicalDefaults({
    required double defaultPrice,
    required int defaultCups,
    required int lowStockThreshold,
    required int highBpThreshold,
    required int fastingHours,
    required String whatsappTemplate,
  }) async {
    await LocalStorage.saveDefaultPrice(defaultPrice);
    await LocalStorage.saveDefaultCups(defaultCups);
    await LocalStorage.saveLowStockThreshold(lowStockThreshold);
    await LocalStorage.saveHighBpThreshold(highBpThreshold);
    await LocalStorage.saveFastingHours(fastingHours);
    await LocalStorage.saveWhatsappTemplate(whatsappTemplate);

    state = state.copyWith(
      defaultPrice: defaultPrice,
      defaultCups: defaultCups,
      lowStockThreshold: lowStockThreshold,
      highBpThreshold: highBpThreshold,
      fastingHours: fastingHours,
      whatsappTemplate: whatsappTemplate,
    );
  }

  Future<void> toggleSunnahReminder() async {
    final next = !state.sunnahDaysReminder;
    await LocalStorage.saveSunnahDaysReminder(next);
    state = state.copyWith(sunnahDaysReminder: next);
  }

  Future<void> toggleStockAlerts() async {
    final next = !state.stockAlerts;
    await LocalStorage.saveStockAlerts(next);
    state = state.copyWith(stockAlerts: next);
  }
}

final hijamaDefaultsProvider = StateNotifierProvider<HijamaDefaultsNotifier, HijamaDefaults>((ref) {
  return HijamaDefaultsNotifier();
});

