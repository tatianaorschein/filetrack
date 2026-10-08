// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FileTrack';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get aboutTitle => 'About Us';

  @override
  String get settingsTitle => 'Settings & Sync';

  @override
  String get loginTitle => 'Login';

  @override
  String get userId => 'User ID';

  @override
  String get pinCode => 'PIN Code';

  @override
  String get loginButton => 'LOG IN';

  @override
  String get newDossier => 'New File';

  @override
  String get trackingAndReception => 'Tracking & Reception';

  @override
  String get exportPdfHistory => 'Export History (PDF)';

  @override
  String get lastKnownLocation => 'Last known location';

  @override
  String get transmissionHistory => 'Transmission History';

  @override
  String get aboutDescription =>
      'FileTrack is a file-tracking application developed by SDCAF of Mekin Hydroelectric Development Corporation (Hydro-Mekin).';
}
