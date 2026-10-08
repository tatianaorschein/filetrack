// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'FileTrack';

  @override
  String get dashboardTitle => 'Tableau de bord';

  @override
  String get aboutTitle => 'À Propos';

  @override
  String get settingsTitle => 'Réglages & Synchronisation';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get userId => 'Identifiant utilisateur';

  @override
  String get pinCode => 'Code PIN';

  @override
  String get loginButton => 'SE CONNECTER';

  @override
  String get newDossier => 'Nouveau Dossier';

  @override
  String get trackingAndReception => 'Suivi & Réception';

  @override
  String get exportPdfHistory => 'Exporter Historique (PDF)';

  @override
  String get lastKnownLocation => 'Dernier emplacement connu';

  @override
  String get transmissionHistory => 'Historique des Transmissions';

  @override
  String get aboutDescription =>
      'FileTrack est une application de suivi des dossiers, réalisée par la SDCAF de la société Mekin Hydroelectric Development Corporation (Hydro-Mekin).';
}
