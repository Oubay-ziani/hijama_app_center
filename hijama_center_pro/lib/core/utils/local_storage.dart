import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive persistence for Center Profile, Clinical Defaults, and UI preferences.
class LocalStorage {
  static const String _keyLanguage = 'app_language';
  static const String _keyThemeMode = 'app_theme_mode';

  // Clinic & Center Profile
  static const String _keyCenterName = 'center_name';
  static const String _keySpecialistName = 'specialist_name';
  static const String _keyPhone = 'center_phone';
  static const String _keyAddress = 'center_address';
  static const String _keyCurrency = 'center_currency';
  static const String _keyReceiptFooter = 'center_receipt_footer';
  static const String _keyLicenseNumber = 'center_license_number';

  // Hijama Clinical Defaults
  static const String _keyDefaultPrice = 'default_session_price';
  static const String _keyDefaultCups = 'default_cups_count';
  static const String _keyLowStockThreshold = 'low_stock_threshold';
  static const String _keyHighBpThreshold = 'high_bp_threshold';
  static const String _keyFastingHours = 'pre_session_fasting_hours';
  static const String _keyWhatsappTemplate = 'whatsapp_template';
  static const String _keySunnahDaysReminder = 'sunnah_days_reminder';
  static const String _keyStockAlerts = 'stock_alerts_enabled';

  static late SharedPreferences _prefs;

  // Initialize preferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Language
  static Future<void> saveLanguage(String langCode) async {
    await _prefs.setString(_keyLanguage, langCode);
  }

  static String getLanguage() {
    return _prefs.getString(_keyLanguage) ?? 'ar';
  }

  // Theme Mode
  static Future<void> saveThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }

  static String getThemeMode() {
    return _prefs.getString(_keyThemeMode) ?? 'light';
  }

  // Clinic Profile
  static Future<void> saveCenterName(String value) async => _prefs.setString(_keyCenterName, value);
  static String getCenterName() => _prefs.getString(_keyCenterName) ?? 'مركز الحجامة والعلاج الطبيعي برو';

  static Future<void> saveSpecialistName(String value) async => _prefs.setString(_keySpecialistName, value);
  static String getSpecialistName() => _prefs.getString(_keySpecialistName) ?? 'الأخصائي المعالج';

  static Future<void> savePhone(String value) async => _prefs.setString(_keyPhone, value);
  static String getPhone() => _prefs.getString(_keyPhone) ?? '0550 00 00 00';

  static Future<void> saveAddress(String value) async => _prefs.setString(_keyAddress, value);
  static String getAddress() => _prefs.getString(_keyAddress) ?? 'الجزائر العاصمة';

  static Future<void> saveCurrency(String value) async => _prefs.setString(_keyCurrency, value);
  static String getCurrency() => _prefs.getString(_keyCurrency) ?? 'دج';

  static Future<void> saveReceiptFooter(String value) async => _prefs.setString(_keyReceiptFooter, value);
  static String getReceiptFooter() => _prefs.getString(_keyReceiptFooter) ?? 'طهور وشفاكم الله وعافاكم';

  static Future<void> saveLicenseNumber(String value) async => _prefs.setString(_keyLicenseNumber, value);
  static String getLicenseNumber() => _prefs.getString(_keyLicenseNumber) ?? 'HJ-2024-PRO';

  // Hijama Defaults
  static Future<void> saveDefaultPrice(double value) async => _prefs.setDouble(_keyDefaultPrice, value);
  static double getDefaultPrice() => _prefs.getDouble(_keyDefaultPrice) ?? 2500.0;

  static Future<void> saveDefaultCups(int value) async => _prefs.setInt(_keyDefaultCups, value);
  static int getDefaultCups() => _prefs.getInt(_keyDefaultCups) ?? 6;

  static Future<void> saveLowStockThreshold(int value) async => _prefs.setInt(_keyLowStockThreshold, value);
  static int getLowStockThreshold() => _prefs.getInt(_keyLowStockThreshold) ?? 20;

  static Future<void> saveHighBpThreshold(int value) async => _prefs.setInt(_keyHighBpThreshold, value);
  static int getHighBpThreshold() => _prefs.getInt(_keyHighBpThreshold) ?? 140;

  static Future<void> saveFastingHours(int value) async => _prefs.setInt(_keyFastingHours, value);
  static int getFastingHours() => _prefs.getInt(_keyFastingHours) ?? 3;

  static Future<void> saveWhatsappTemplate(String value) async => _prefs.setString(_keyWhatsappTemplate, value);
  static String getWhatsappTemplate() => _prefs.getString(_keyWhatsappTemplate) ?? 'السلام عليكم ورحمة الله، نؤكد موعدكم للحجامة يوم {date} على الساعة {time}. يُرجى الصيام عن الأكل الدسم 3 ساعات قبل الجلسة.';

  static Future<void> saveSunnahDaysReminder(bool value) async => _prefs.setBool(_keySunnahDaysReminder, value);
  static bool getSunnahDaysReminder() => _prefs.getBool(_keySunnahDaysReminder) ?? true;

  static Future<void> saveStockAlerts(bool value) async => _prefs.setBool(_keyStockAlerts, value);
  static bool getStockAlerts() => _prefs.getBool(_keyStockAlerts) ?? true;
}
