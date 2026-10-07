import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:filetrack/models/dossier.dart';
import 'package:filetrack/models/transmission.dart';
import 'package:filetrack/services/api_service.dart';
import 'package:filetrack/services/database_helper.dart';

class SyncService {
  static final SyncService instance = SyncService._init();

  SyncService._init();

  final ValueNotifier<bool> isSyncing = ValueNotifier<bool>(false);
  final ValueNotifier<String> lastSyncStatus = ValueNotifier<String>("Jamais synchronisé");

  Timer? _autoSyncTimer;

  void startAutoSyncTimer() {
    _autoSyncTimer?.cancel();
    // Tentative automatique de synchronisation toutes les 2 minutes
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      runFullSync();
    });
  }

  void stopAutoSyncTimer() {
    _autoSyncTimer?.cancel();
  }

  /// Moteur de Synchronisation Bidirectionnelle (Push local ➔ Serveur / Pull Serveur ➔ Local)
  Future<bool> runFullSync() async {
    if (isSyncing.value) return false;

    isSyncing.value = true;
    lastSyncStatus.value = "Synchronisation en cours...";

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastTimestamp = prefs.getString('last_sync_timestamp') ?? "1970-01-01T00:00:00.000Z";

      // --- ÉTAPE 1 : PUSH (Envoi des données locales non synchronisées vers le serveur) ---
      final unsyncedDossiers = await DatabaseHelper.instance.getUnsyncedDossiers();
      final unsyncedTransmissions = await DatabaseHelper.instance.getUnsyncedTransmissions();

      if (unsyncedDossiers.isNotEmpty || unsyncedTransmissions.isNotEmpty) {
        final syncedIds = await ApiService.instance.pushLocalData(
          dossiers: unsyncedDossiers,
          transmissions: unsyncedTransmissions,
        );

        if (syncedIds != null) {
          final dossierIdsToMark = unsyncedDossiers
              .where((d) => syncedIds.contains(d.id))
              .map((d) => d.id)
              .toList();
          final transmissionIdsToMark = unsyncedTransmissions
              .where((t) => syncedIds.contains(t.id))
              .map((t) => t.id)
              .toList();

          await DatabaseHelper.instance.markDossiersAsSynced(dossierIdsToMark);
          await DatabaseHelper.instance.markTransmissionsAsSynced(transmissionIdsToMark);
        }
      }

      // --- ÉTAPE 2 : PULL (Récupération des modifications distantes depuis le serveur) ---
      final remoteData = await ApiService.instance.pullRemoteData(lastTimestamp);

      if (remoteData != null) {
        // Intégration des dossiers distants
        if (remoteData['dossiers'] != null) {
          final List remoteDossiersJson = remoteData['dossiers'];
          for (var item in remoteDossiersJson) {
            final dossier = Dossier.fromMap(Map<String, dynamic>.from(item));
            await DatabaseHelper.instance.insertDossier(dossier);
            await DatabaseHelper.instance.markDossiersAsSynced([dossier.id]);
          }
        }

        // Intégration des transmissions distantes
        if (remoteData['transmissions'] != null) {
          final List remoteTransmissionsJson = remoteData['transmissions'];
          for (var item in remoteTransmissionsJson) {
            final tr = Transmission.fromMap(Map<String, dynamic>.from(item));
            await DatabaseHelper.instance.insertTransmission(tr);
            await DatabaseHelper.instance.markTransmissionsAsSynced([tr.id]);

            // Mise à jour du statut du dossier local
            final newStatus = tr.type == 'externe'
                ? "Transmis à l'externe (${tr.externalOrganization ?? ''})"
                : tr.status == 'reçu'
                    ? "Reçu au service ${tr.receiverServiceId}"
                    : "En transit vers ${tr.receiverServiceId}";
            await DatabaseHelper.instance.updateDossierStatus(tr.dossierId, newStatus);
          }
        }

        // --- ÉTAPE 3 : UPLOAD OPTIONNEL DES PIÈCES JOINTES CLOUD ---
        final syncCloudPdf = prefs.getBool('sync_attachments_cloud') ?? false;
        if (syncCloudPdf) {
          for (var tr in unsyncedTransmissions) {
            if (tr.attachmentPath != null && tr.attachmentPath!.isNotEmpty) {
              final pdfFile = File(tr.attachmentPath!);
              if (await pdfFile.exists()) {
                await ApiService.instance.uploadAttachment(
                  dossierId: tr.dossierId,
                  transmissionId: tr.id,
                  file: pdfFile,
                );
              }
            }
          }
        }

        // Mise à jour du timestamp de dernière synchro
        final serverTime = remoteData['server_timestamp'] as String? ?? DateTime.now().toIso8601String();
        await prefs.setString('last_sync_timestamp', serverTime);

        final timeFormatted = DateTime.now().toString().substring(11, 16);
        lastSyncStatus.value = "Synchronisé à $timeFormatted";
        isSyncing.value = false;
        return true;
      } else {
        lastSyncStatus.value = "Mode Hors-Ligne (Serveur injoignable)";
      }
    } catch (_) {
      lastSyncStatus.value = "Erreur de connexion serveur";
    }

    isSyncing.value = false;
    return false;
  }
}
