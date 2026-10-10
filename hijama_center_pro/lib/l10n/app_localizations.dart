import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Hijama Center Pro'**
  String get appTitle;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get customers;

  /// No description provided for @appointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointments;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @employees.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get employees;

  /// No description provided for @newSession.
  ///
  /// In en, this message translates to:
  /// **'New Booking'**
  String get newSession;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get confirmBooking;

  /// No description provided for @completeSession.
  ///
  /// In en, this message translates to:
  /// **'Log Session Details'**
  String get completeSession;

  /// No description provided for @saveSession.
  ///
  /// In en, this message translates to:
  /// **'Save Session'**
  String get saveSession;

  /// No description provided for @sessionPrice.
  ///
  /// In en, this message translates to:
  /// **'Session Price (DA)'**
  String get sessionPrice;

  /// No description provided for @cupsCount.
  ///
  /// In en, this message translates to:
  /// **'Cups Used'**
  String get cupsCount;

  /// No description provided for @todayBookings.
  ///
  /// In en, this message translates to:
  /// **'Today Bookings'**
  String get todayBookings;

  /// No description provided for @todayRevenue.
  ///
  /// In en, this message translates to:
  /// **'Today Revenue'**
  String get todayRevenue;

  /// No description provided for @todayCups.
  ///
  /// In en, this message translates to:
  /// **'Today Cups'**
  String get todayCups;

  /// No description provided for @monthRevenue.
  ///
  /// In en, this message translates to:
  /// **'This Month Revenue'**
  String get monthRevenue;

  /// No description provided for @monthCups.
  ///
  /// In en, this message translates to:
  /// **'This Month Cups'**
  String get monthCups;

  /// No description provided for @totalCustomers.
  ///
  /// In en, this message translates to:
  /// **'Total Patients'**
  String get totalCustomers;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get profit;

  /// No description provided for @avgPrice.
  ///
  /// In en, this message translates to:
  /// **'Avg. Price / Session'**
  String get avgPrice;

  /// No description provided for @avgCups.
  ///
  /// In en, this message translates to:
  /// **'Avg. Cups / Session'**
  String get avgCups;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock & Consumption'**
  String get stock;

  /// No description provided for @lowStockAlert.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStockAlert;

  /// No description provided for @restock.
  ///
  /// In en, this message translates to:
  /// **'Restock Cups'**
  String get restock;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @monthlyReport.
  ///
  /// In en, this message translates to:
  /// **'Monthly Report'**
  String get monthlyReport;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @statusReserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get statusReserved;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @dryCupping.
  ///
  /// In en, this message translates to:
  /// **'Dry Cupping'**
  String get dryCupping;

  /// No description provided for @wetCupping.
  ///
  /// In en, this message translates to:
  /// **'Wet Cupping'**
  String get wetCupping;

  /// No description provided for @massage.
  ///
  /// In en, this message translates to:
  /// **'Massage Therapy'**
  String get massage;

  /// No description provided for @relaxation.
  ///
  /// In en, this message translates to:
  /// **'Relaxation Therapy'**
  String get relaxation;

  /// No description provided for @preventive.
  ///
  /// In en, this message translates to:
  /// **'Preventive Cupping'**
  String get preventive;

  /// No description provided for @curative.
  ///
  /// In en, this message translates to:
  /// **'Curative Cupping'**
  String get curative;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'New Patient'**
  String get addCustomer;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @medicalNotes.
  ///
  /// In en, this message translates to:
  /// **'Medical Notes'**
  String get medicalNotes;

  /// No description provided for @chronicDiseases.
  ///
  /// In en, this message translates to:
  /// **'Chronic Diseases'**
  String get chronicDiseases;

  /// No description provided for @bloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure'**
  String get bloodPressure;

  /// No description provided for @hijamaHistory.
  ///
  /// In en, this message translates to:
  /// **'Past Hijama History'**
  String get hijamaHistory;

  /// No description provided for @bodyArea.
  ///
  /// In en, this message translates to:
  /// **'Treated Body Area'**
  String get bodyArea;

  /// No description provided for @therapistNotes.
  ///
  /// In en, this message translates to:
  /// **'Therapist Notes'**
  String get therapistNotes;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone...'**
  String get search;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @selectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select Month'**
  String get selectMonth;

  /// No description provided for @customPeriod.
  ///
  /// In en, this message translates to:
  /// **'Custom Period'**
  String get customPeriod;

  /// No description provided for @pricePaid.
  ///
  /// In en, this message translates to:
  /// **'Price Paid (DA)'**
  String get pricePaid;

  /// No description provided for @cupsUsed.
  ///
  /// In en, this message translates to:
  /// **'Cups Used'**
  String get cupsUsed;

  /// No description provided for @materials.
  ///
  /// In en, this message translates to:
  /// **'Materials Used'**
  String get materials;

  /// No description provided for @warnings.
  ///
  /// In en, this message translates to:
  /// **'Medical Warnings'**
  String get warnings;

  /// No description provided for @debt.
  ///
  /// In en, this message translates to:
  /// **'Remaining Debt'**
  String get debt;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @recordSession.
  ///
  /// In en, this message translates to:
  /// **'Record Session'**
  String get recordSession;

  /// No description provided for @upcomingAppts.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Agenda'**
  String get upcomingAppts;

  /// No description provided for @lowStockWarning.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alert'**
  String get lowStockWarning;

  /// No description provided for @unpaidClients.
  ///
  /// In en, this message translates to:
  /// **'Debtor Clients'**
  String get unpaidClients;

  /// No description provided for @loyaltyPoints.
  ///
  /// In en, this message translates to:
  /// **'Loyalty Points'**
  String get loyaltyPoints;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
