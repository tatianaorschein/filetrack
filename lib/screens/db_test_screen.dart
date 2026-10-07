import 'package:flutter/material.dart';
import 'package:filetrack/models/dossier.dart';
import 'package:filetrack/models/service_model.dart';
import 'package:filetrack/models/transmission.dart';
import 'package:filetrack/models/user.dart';
import 'package:filetrack/services/database_helper.dart';

class DbTestScreen extends StatefulWidget {
  const DbTestScreen({super.key});

  @override
  State<DbTestScreen> createState() => _DbTestScreenState();
}

class _DbTestScreenState extends State<DbTestScreen> {
  bool _isLoading = true;
  List<ServiceModel> _services = [];
  List<User> _users = [];
  List<Dossier> _dossiers = [];
  List<Transmission> _transmissions = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });

    final services = await DatabaseHelper.instance.getAllServices();
    final users = await DatabaseHelper.instance.getAllUsers();
    final dossiers = await DatabaseHelper.instance.getAllDossiers();
    final transmissions = await DatabaseHelper.instance.getAllTransmissions();

    setState(() {
      _services = services;
      _users = users;
      _dossiers = dossiers;
      _transmissions = transmissions;
      _isLoading = false;
    });
  }

  Future<void> _addTestDossierAndTransmission() async {
    final newId = "DOS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
    final newDossier = Dossier(
      id: newId,
      title: "Dossier Test Hydro-Mekin $newId",
      createdAt: DateTime.now().toIso8601String(),
      creatorServiceId: "SERV_SDCAF",
      currentStatus: "Créé",
    );

    await DatabaseHelper.instance.insertDossier(newDossier);

    final newTransmission = Transmission(
      id: "TR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
      dossierId: newId,
      senderServiceId: "SERV_SDCAF",
      senderUserId: "ADMIN001",
      receiverServiceId: "SERV_DG",
      dateTime: DateTime.now().toIso8601String(),
      observation: "Transmission de test pour validation SQLite",
      type: "interne",
      status: "émis",
    );

    await DatabaseHelper.instance.insertTransmission(newTransmission);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Dossier $newId et transmission insérés avec succès !"),
          backgroundColor: Colors.green,
        ),
      );
    }

    await _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Test Base de Données SQLite"),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Services"),
              Tab(text: "Utilisateurs"),
              Tab(text: "Dossiers"),
              Tab(text: "Transmissions"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildServicesList(),
                  _buildUsersList(),
                  _buildDossiersList(),
                  _buildTransmissionsList(),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addTestDossierAndTransmission,
          icon: const Icon(Icons.add),
          label: const Text("Tester l'insertion"),
        ),
      ),
    );
  }

  Widget _buildServicesList() {
    if (_services.isEmpty) {
      return const Center(child: Text("Aucun service trouvé."));
    }
    return ListView.builder(
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        return ListTile(
          leading: const Icon(Icons.business_rounded, color: Color(0xFF005691)),
          title: Text(service.name),
          subtitle: Text("${service.id} - ${service.description}"),
        );
      },
    );
  }

  Widget _buildUsersList() {
    if (_users.isEmpty) {
      return const Center(child: Text("Aucun utilisateur trouvé."));
    }
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return ListTile(
          leading: const Icon(Icons.person_rounded, color: Color(0xFF005691)),
          title: Text(user.name),
          subtitle: Text("ID: ${user.id} | Service: ${user.serviceId} | Rôle: ${user.role}"),
          trailing: user.mustChangePin
              ? const Chip(
                  label: Text("PIN à changer", style: TextStyle(fontSize: 10)),
                  backgroundColor: Colors.amberAccent,
                )
              : null,
        );
      },
    );
  }

  Widget _buildDossiersList() {
    if (_dossiers.isEmpty) {
      return const Center(child: Text("Aucun dossier enregistré."));
    }
    return ListView.builder(
      itemCount: _dossiers.length,
      itemBuilder: (context, index) {
        final dossier = _dossiers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.folder_rounded, color: Color(0xFF005691)),
            title: Text(dossier.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Réf: ${dossier.id} | Créateur: ${dossier.creatorServiceId}"),
            trailing: Chip(
              label: Text(dossier.currentStatus),
              backgroundColor: Colors.blue.shade100,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransmissionsList() {
    if (_transmissions.isEmpty) {
      return const Center(child: Text("Aucune transmission enregistrée."));
    }
    return ListView.builder(
      itemCount: _transmissions.length,
      itemBuilder: (context, index) {
        final tr = _transmissions[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF0088CC)),
            title: Text("Transmission ${tr.id} (Dossier: ${tr.dossierId})"),
            subtitle: Text("De ${tr.senderServiceId} vers ${tr.receiverServiceId}\nObs: ${tr.observation}"),
            isThreeLine: true,
            trailing: Chip(
              label: Text(tr.status),
              backgroundColor: Colors.green.shade100,
            ),
          ),
        );
      },
    );
  }
}
