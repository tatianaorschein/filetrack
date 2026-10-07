import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:filetrack/models/user.dart';
import 'package:filetrack/services/database_helper.dart';

class AttachmentService {
  static final AttachmentService instance = AttachmentService._init();

  AttachmentService._init();

  /// Sélection d'un fichier au format PDF uniquement
  Future<File?> pickPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      if (file.path.toLowerCase().endsWith('.pdf')) {
        return file;
      }
    }
    return null;
  }

  /// Sauvegarde du fichier PDF dans le stockage local réservé à l'application
  Future<String?> saveAttachmentLocally(File file, String dossierId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory(p.join(appDir.path, 'attachments', dossierId));

      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      final fileName = "scan_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final savedFile = await file.copy(p.join(attachmentsDir.path, fileName));

      return savedFile.path;
    } catch (e) {
      return null;
    }
  }

  /// Règle Métier Sécurisée :
  /// Seuls les services et utilisateurs impliqués dans la chaîne de transmission
  /// du dossier peuvent accéder à la pièce jointe.
  Future<bool> canUserAccessAttachment(User? user, String dossierId) async {
    if (user == null) return false;

    final dossier = await DatabaseHelper.instance.getDossierById(dossierId);
    if (dossier == null) return false;

    final transmissions = await DatabaseHelper.instance.getTransmissionsByDossier(dossierId);

    final involvedServices = <String>{};
    final involvedUsers = <String>{};

    // Service créateur du dossier
    involvedServices.add(dossier.creatorServiceId);

    // Services et Utilisateurs impliqués dans l'historique des transmissions
    for (var tr in transmissions) {
      involvedServices.add(tr.senderServiceId);
      involvedServices.add(tr.receiverServiceId);

      involvedUsers.add(tr.senderUserId);
      if (tr.receiverUserId != null && tr.receiverUserId!.isNotEmpty) {
        involvedUsers.add(tr.receiverUserId!);
      }
    }

    // L'utilisateur a accès si son service ou son identifiant personnel est dans la chaîne
    final isServiceInvolved = involvedServices.contains(user.serviceId);
    final isUserInvolved = involvedUsers.contains(user.id);

    return isServiceInvolved || isUserInvolved;
  }

  /// Ouverture de la pièce jointe avec double vérification logique métier
  Future<OpenResult> openAttachment(User? user, String dossierId, String attachmentPath) async {
    final hasAccess = await canUserAccessAttachment(user, dossierId);

    if (!hasAccess) {
      return OpenResult(
        type: ResultType.noAppToOpen,
        message: "Accès refusé : Votre service n'est pas impliqué dans ce dossier.",
      );
    }

    final file = File(attachmentPath);
    if (!await file.exists()) {
      return OpenResult(
        type: ResultType.fileNotFound,
        message: "Le fichier PDF joint n'existe pas localement.",
      );
    }

    return await OpenFilex.open(attachmentPath);
  }
}
