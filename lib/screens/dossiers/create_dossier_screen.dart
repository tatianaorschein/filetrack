import 'package:flutter/material.dart';
import 'package:filetrack/models/dossier.dart';
import 'package:filetrack/models/transmission.dart';
import 'package:filetrack/services/auth_service.dart';
import 'package:filetrack/services/database_helper.dart';

class CreateDossierScreen extends StatefulWidget {
  const CreateDossierScreen({super.key});

  @override
  State<CreateDossierScreen> createState() => _CreateDossierScreenState();
}

class _CreateDossierScreenState extends State<CreateDossierScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  final _titleController = TextEditingController();
  final _observationController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final year = DateTime.now().year;
    final randomSuffix = (DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    _idController = TextEditingController(text: "DOS-$year-$randomSuffix");
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateDossier() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expirée. Reconnectez-vous.")),
      );
      return;
    }

    final dossierId = _idController.text.trim().toUpperCase();
    final title = _titleController.text.trim();
    final observation = _observationController.text.trim();
    final nowStr = DateTime.now().toIso8601String();

    // 1. Création du dossier
    final newDossier = Dossier(
      id: dossierId,
      title: title,
      createdAt: nowStr,
      creatorServiceId: currentUser.serviceId,
      currentStatus: "Disponible au service ${currentUser.serviceId}",
    );

    // 2. Première transmission initiale (Création)
    final initialTransmission = Transmission(
      id: "TR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}",
      dossierId: dossierId,
      senderServiceId: currentUser.serviceId,
      senderUserId: currentUser.id,
      receiverServiceId: currentUser.serviceId,
      receiverUserId: currentUser.id,
      dateTime: nowStr,
      observation: observation.isNotEmpty ? observation : "Création initiale du dossier",
      type: "interne",
      status: "reçu",
    );

    await DatabaseHelper.instance.insertDossier(newDossier);
    await DatabaseHelper.instance.insertTransmission(initialTransmission);

    setState(() => _isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Dossier $dossierId créé avec succès !"),
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
        title: const Text("Nouveau Dossier"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Information Service créateur
                Card(
                  color: Colors.blue.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF005691)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Service Émetteur : ${user?.serviceId ?? ''}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF005691),
                                ),
                              ),
                              Text(
                                "Agent créateur : ${user?.name ?? ''} (${user?.id ?? ''})",
                                style: TextStyle(color: Colors.grey[800], fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Référence Dossier
                TextFormField(
                  controller: _idController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: "Identifiant / Numéro du dossier",
                    prefixIcon: Icon(Icons.tag),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Veuillez indiquer un identifiant de dossier";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Titre / Objet
                TextFormField(
                  controller: _titleController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Objet / Titre du dossier",
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Veuillez entrer l'objet ou titre du dossier";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Observation de création
                TextFormField(
                  controller: _observationController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Observation / Note initiale (Optionnel)",
                    prefixIcon: Icon(Icons.note_alt_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 28),

                // Bouton enregistrer
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreateDossier,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005691),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "CRÉER LE DOSSIER",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
