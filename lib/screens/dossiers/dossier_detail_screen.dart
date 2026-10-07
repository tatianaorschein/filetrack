import 'dart:io';
import 'package:flutter/material.dart';
import 'package:filetrack/models/dossier.dart';
import 'package:filetrack/models/transmission.dart';
import 'package:filetrack/screens/dossiers/transmit_dossier_screen.dart';
import 'package:filetrack/services/attachment_service.dart';
import 'package:filetrack/services/auth_service.dart';
import 'package:filetrack/services/database_helper.dart';

class DossierDetailScreen extends StatefulWidget {
  final String dossierId;

  const DossierDetailScreen({super.key, required this.dossierId});

  @override
  State<DossierDetailScreen> createState() => _DossierDetailScreenState();
}

class _DossierDetailScreenState extends State<DossierDetailScreen> {
  Dossier? _dossier;
  List<Transmission> _transmissions = [];
  bool _hasAttachmentAccess = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDossierDetails();
  }

  Future<void> _loadDossierDetails() async {
    setState(() => _isLoading = true);
    final currentUser = AuthService.instance.currentUser;

    final dossier = await DatabaseHelper.instance.getDossierById(widget.dossierId);
    final transmissions = await DatabaseHelper.instance.getTransmissionsByDossier(widget.dossierId);

    // Vérification de la règle d'accès métier à la pièce jointe
    final hasAccess = await AttachmentService.instance.canUserAccessAttachment(
      currentUser,
      widget.dossierId,
    );

    setState(() {
      _dossier = dossier;
      _transmissions = transmissions;
      _hasAttachmentAccess = hasAccess;
      _isLoading = false;
    });
  }

  Future<void> _openPdf(String attachmentPath) async {
    final currentUser = AuthService.instance.currentUser;
    final result = await AttachmentService.instance.openAttachment(
      currentUser,
      widget.dossierId,
      attachmentPath,
    );

    if (result.message.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _validateReception(Transmission latestTransmission) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Valider la réception"),
        content: Text(
          "Confirmez-vous la réception physique/administrative du dossier ${widget.dossierId} au nom du service ${currentUser.serviceId} ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Valider Réception", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final nowStr = DateTime.now().toIso8601String();

      final receptionRecord = Transmission(
        id: "TR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}",
        dossierId: widget.dossierId,
        senderServiceId: latestTransmission.senderServiceId,
        senderUserId: latestTransmission.senderUserId,
        receiverServiceId: currentUser.serviceId,
        receiverUserId: currentUser.id,
        dateTime: nowStr,
        observation: "Réception validée par ${currentUser.name} (${currentUser.id})",
        type: latestTransmission.type,
        attachmentPath: latestTransmission.attachmentPath,
        status: "reçu",
      );

      await DatabaseHelper.instance.insertTransmission(receptionRecord);
      await DatabaseHelper.instance.updateDossierStatus(
        widget.dossierId,
        "Reçu au service ${currentUser.serviceId}",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Réception du dossier validée avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadDossierDetails();
    }
  }

  Future<void> _validateExternalReturn(Transmission latestExternalTransmission) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return;

    final notesController = TextEditingController();
    File? newScannedPdf;
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Retour Externe : ${latestExternalTransmission.externalOrganization}"),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Valider le retour effectif du dossier depuis l'organisme extérieur."),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: "Observations / Remarques de retour",
                        hintText: "ex: Dossier visé et approuvé par le Ministère",
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "Veuillez entrer une observation";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    if (newScannedPdf != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              newScannedPdf!.path.split(Platform.pathSeparator).last,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setDialogState(() => newScannedPdf = null),
                          ),
                        ],
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: () async {
                          final pdf = await AttachmentService.instance.pickPdfFile();
                          if (pdf != null) {
                            setDialogState(() => newScannedPdf = pdf);
                          }
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text("Nouveau Scan PDF de retour (Optionnel)", style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text("Annuler"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(ctx).pop(true);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005691)),
                child: const Text("Valider le Retour", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true) {
      String? savedAttachmentPath = latestExternalTransmission.attachmentPath;
      if (newScannedPdf != null) {
        savedAttachmentPath = await AttachmentService.instance.saveAttachmentLocally(
          newScannedPdf!,
          widget.dossierId,
        );
      }

      final nowStr = DateTime.now().toIso8601String();
      final orgName = latestExternalTransmission.externalOrganization ?? 'Organisme externe';

      final returnTransmission = Transmission(
        id: "TR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}",
        dossierId: widget.dossierId,
        senderServiceId: "EXTERNE ($orgName)",
        senderUserId: currentUser.id,
        receiverServiceId: currentUser.serviceId,
        receiverUserId: currentUser.id,
        dateTime: nowStr,
        observation: "RETOUR EXTERNE ($orgName) : ${notesController.text.trim()}",
        type: "externe",
        externalOrganization: orgName,
        attachmentPath: savedAttachmentPath,
        status: "reçu",
      );

      await DatabaseHelper.instance.insertTransmission(returnTransmission);
      await DatabaseHelper.instance.updateDossierStatus(
        widget.dossierId,
        "Retourné de l'externe - Disponible à ${currentUser.serviceId}",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Retour du dossier de $orgName validé !"),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadDossierDetails();
    }
  }

  Future<void> _rejectTransmission(Transmission latestTransmission) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return;

    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Rejeter la transmission"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Indiquez le motif du rejet du dossier :"),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Motif du rejet",
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Le motif de rejet est obligatoire";
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Rejeter", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final nowStr = DateTime.now().toIso8601String();

      final rejectionRecord = Transmission(
        id: "TR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}",
        dossierId: widget.dossierId,
        senderServiceId: latestTransmission.senderServiceId,
        senderUserId: latestTransmission.senderUserId,
        receiverServiceId: currentUser.serviceId,
        receiverUserId: currentUser.id,
        dateTime: nowStr,
        observation: "REJET : ${reasonController.text.trim()}",
        type: latestTransmission.type,
        attachmentPath: latestTransmission.attachmentPath,
        status: "rejeté",
      );

      await DatabaseHelper.instance.insertTransmission(rejectionRecord);
      await DatabaseHelper.instance.updateDossierStatus(
        widget.dossierId,
        "Rejeté par ${currentUser.serviceId}",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Transmission rejetée."),
            backgroundColor: Colors.red,
          ),
        );
      }

      _loadDossierDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.instance.currentUser;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Dossier ${widget.dossierId}")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_dossier == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Dossier Introuvable")),
        body: const Center(child: Text("Dossier non trouvé dans la base.")),
      );
    }

    final latestTransmission = _transmissions.isNotEmpty ? _transmissions.last : null;

    final isPendingReceptionForMyService = latestTransmission != null &&
        latestTransmission.status == 'émis' &&
        latestTransmission.receiverServiceId == currentUser?.serviceId;

    final isExternalInTransitFromMyService = latestTransmission != null &&
        latestTransmission.type == 'externe' &&
        latestTransmission.status == 'émis' &&
        latestTransmission.senderServiceId == currentUser?.serviceId;

    final isCurrentlyHeldByMyService = (latestTransmission != null &&
            latestTransmission.receiverServiceId == currentUser?.serviceId &&
            latestTransmission.status == 'reçu') ||
        (_dossier!.creatorServiceId == currentUser?.serviceId && _transmissions.length == 1);

    return Scaffold(
      appBar: AppBar(
        title: Text("Parcours : ${_dossier!.id}"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fiche résumé dossier
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dossier!.id,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF005691),
                          ),
                        ),
                        Chip(
                          label: Text(
                            _dossier!.currentStatus,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Colors.blue.shade100,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _dossier!.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const Divider(height: 24),
                    Text("Service créateur : ${_dossier!.creatorServiceId}"),
                    Text("Date de création : ${_dossier!.createdAt.substring(0, 10)}"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Actions Réception Interne
            if (isPendingReceptionForMyService) ...[
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.pending_actions_rounded, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            "Transmission en attente de réception",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _validateReception(latestTransmission),
                              icon: const Icon(Icons.check_circle),
                              label: const Text("Valider Réception"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _rejectTransmission(latestTransmission),
                            icon: const Icon(Icons.cancel),
                            label: const Text("Rejeter"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Circuit Externe : Validation du retour
            if (isExternalInTransitFromMyService) ...[
              Card(
                color: Colors.purple.shade50,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance, color: Colors.purple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Circuit Externe : Transmis à ${latestTransmission.externalOrganization ?? 'Organisme externe'}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _validateExternalReturn(latestTransmission),
                        icon: const Icon(Icons.assignment_return),
                        label: const Text("VALIDER LE RETOUR DE L'ORGANISME EXTERNE"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // En-tête Historique & Relance Transmission Interne
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Historique des Transmissions",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF005691),
                      ),
                ),
                if (isCurrentlyHeldByMyService)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TransmitDossierScreen(dossier: _dossier!),
                        ),
                      );
                      if (result == true) _loadDossierDetails();
                    },
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text("Transmettre"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005691),
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Timeline des étapes
            if (_transmissions.isEmpty)
              const Center(child: Text("Aucune transmission dans l'historique."))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transmissions.length,
                itemBuilder: (context, index) {
                  final tr = _transmissions[index];
                  final isLast = index == _transmissions.length - 1;

                  Color statusColor = Colors.blue;
                  if (tr.status == 'reçu') statusColor = Colors.green;
                  if (tr.status == 'rejeté') statusColor = Colors.red;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Colonne indicateur graphique
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: statusColor,
                            child: Icon(
                              tr.status == 'reçu'
                                  ? Icons.check
                                  : tr.status == 'rejeté'
                                      ? Icons.close
                                      : Icons.arrow_forward,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 70,
                              color: Colors.grey[300],
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Carte détail transmission
                      Expanded(
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      tr.type == 'externe'
                                          ? "Étape Externe (${tr.externalOrganization ?? ''})"
                                          : "${tr.senderServiceId} ➔ ${tr.receiverServiceId}",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      tr.dateTime.substring(0, 10),
                                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text("Émis par: ${tr.senderUserId}"),
                                if (tr.receiverUserId != null)
                                  Text("Validé/Reçu par: ${tr.receiverUserId}"),
                                if (tr.observation.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    "Obs: ${tr.observation}",
                                    style: const TextStyle(fontStyle: FontStyle.italic),
                                  ),
                                ],

                                // Affichage et contrôle d'accès de la pièce jointe PDF
                                if (tr.attachmentPath != null && tr.attachmentPath!.isNotEmpty) ...[
                                  const Divider(height: 16),
                                  if (_hasAttachmentAccess) ...[
                                    OutlinedButton.icon(
                                      onPressed: () => _openPdf(tr.attachmentPath!),
                                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                      label: const Text(
                                        "Consulter la Pièce Jointe (PDF)",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.lock, size: 16, color: Colors.red),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "Pièce jointe protégée (accès restreint aux services de la chaîne)",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
