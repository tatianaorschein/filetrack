import 'dart:io';
import 'package:flutter/material.dart';
import 'package:filetrack/models/dossier.dart';
import 'package:filetrack/models/service_model.dart';
import 'package:filetrack/models/transmission.dart';
import 'package:filetrack/services/attachment_service.dart';
import 'package:filetrack/services/auth_service.dart';
import 'package:filetrack/services/database_helper.dart';

class TransmitDossierScreen extends StatefulWidget {
  final Dossier dossier;

  const TransmitDossierScreen({super.key, required this.dossier});

  @override
  State<TransmitDossierScreen> createState() => _TransmitDossierScreenState();
}

class _TransmitDossierScreenState extends State<TransmitDossierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observationController = TextEditingController();
  final _externalOrgController = TextEditingController();

  String _type = 'interne'; // 'interne' ou 'externe'
  String? _selectedReceiverServiceId;
  List<ServiceModel> _services = [];
  File? _selectedPdfFile;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _observationController.dispose();
    _externalOrgController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    final currentUser = AuthService.instance.currentUser;
    final allServices = await DatabaseHelper.instance.getAllServices();

    final availableServices = allServices
        .where((s) => s.id != currentUser?.serviceId)
        .toList();

    setState(() {
      _services = availableServices;
      if (availableServices.isNotEmpty) {
        _selectedReceiverServiceId = availableServices.first.id;
      }
      _isLoading = false;
    });
  }

  Future<void> _pickPdfAttachment() async {
    final pdf = await AttachmentService.instance.pickPdfFile();
    if (pdf != null) {
      setState(() => _selectedPdfFile = pdf);
    }
  }

  Future<void> _handleTransmit() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return;

    if (_type == 'interne' && _selectedReceiverServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner un service destinataire.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    String? savedAttachmentPath;
    if (_selectedPdfFile != null) {
      savedAttachmentPath = await AttachmentService.instance.saveAttachmentLocally(
        _selectedPdfFile!,
        widget.dossier.id,
      );
    }

    final nowStr = DateTime.now().toIso8601String();
    final receiverId = _type == 'interne' ? _selectedReceiverServiceId! : 'EXTERNE';
    final extOrg = _type == 'externe' ? _externalOrgController.text.trim() : null;

    final newTransmission = Transmission(
      id: "TR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}",
      dossierId: widget.dossier.id,
      senderServiceId: currentUser.serviceId,
      senderUserId: currentUser.id,
      receiverServiceId: receiverId,
      dateTime: nowStr,
      observation: _observationController.text.trim(),
      type: _type,
      externalOrganization: extOrg,
      attachmentPath: savedAttachmentPath,
      status: "émis",
    );

    final newDossierStatus = _type == 'interne'
        ? "En transit vers $receiverId"
        : "Transmis à l'externe ($extOrg)";

    await DatabaseHelper.instance.insertTransmission(newTransmission);
    await DatabaseHelper.instance.updateDossierStatus(widget.dossier.id, newDossierStatus);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Transmission du dossier ${widget.dossier.id} enregistrée !"),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Transmettre : ${widget.dossier.id}"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Carte résumé dossier
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.dossier.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text("Réf : ${widget.dossier.id}"),
                              Text("Service émetteur : ${user?.serviceId}"),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sélection Type de transmission
                      const Text(
                        "Type de transmission",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Interne"),
                              subtitle: const Text("Autre service Hydro-Mekin"),
                              value: "interne",
                              groupValue: _type,
                              onChanged: (val) {
                                if (val != null) setState(() => _type = val);
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Externe"),
                              subtitle: const Text("Organisme extérieur"),
                              value: "externe",
                              groupValue: _type,
                              onChanged: (val) {
                                if (val != null) setState(() => _type = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Choix du destinataire selon le type
                      if (_type == 'interne') ...[
                        DropdownButtonFormField<String>(
                          value: _selectedReceiverServiceId,
                          decoration: const InputDecoration(
                            labelText: "Service destinataire",
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                          ),
                          items: _services.map((s) {
                            return DropdownMenuItem(
                              value: s.id,
                              child: Text("${s.name} (${s.id})"),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedReceiverServiceId = val);
                          },
                          validator: (val) {
                            if (_type == 'interne' && (val == null || val.isEmpty)) {
                              return "Sélectionnez un service destinataire";
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _externalOrgController,
                          decoration: const InputDecoration(
                            labelText: "Organisme externe destinataire",
                            hintText: "ex: Ministère de l'Eau et de l'Énergie",
                            prefixIcon: Icon(Icons.account_balance),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (_type == 'externe' && (val == null || val.trim().isEmpty)) {
                              return "Indiquez le nom de l'organisme externe";
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Section Pièce jointe PDF
                      Card(
                        color: Colors.grey.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.attach_file, color: Color(0xFF005691)),
                                  SizedBox(width: 8),
                                  Text(
                                    "Pièce jointe (PDF uniquement)",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_selectedPdfFile != null) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.picture_as_pdf, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedPdfFile!.path.split(Platform.pathSeparator).last,
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.grey),
                                      onPressed: () => setState(() => _selectedPdfFile = null),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                OutlinedButton.icon(
                                  onPressed: _pickPdfAttachment,
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text("Sélectionner un document PDF"),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Observation / Motif
                      TextFormField(
                        controller: _observationController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: "Observation / Motif de transmission",
                          hintText: "ex: Transmis pour étude et validation financière",
                          prefixIcon: Icon(Icons.notes),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "Veuillez entrer une observation";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // Bouton Valider l'envoi
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _handleTransmit,
                        icon: const Icon(Icons.send),
                        label: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "VALIDER L'EXPÉDITION",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF005691),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
