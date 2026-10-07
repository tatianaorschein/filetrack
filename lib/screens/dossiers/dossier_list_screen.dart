import 'package:flutter/material.dart';
import 'package:filetrack/models/dossier.dart';
import 'package:filetrack/models/transmission.dart';
import 'package:filetrack/screens/dossiers/create_dossier_screen.dart';
import 'package:filetrack/screens/dossiers/dossier_detail_screen.dart';
import 'package:filetrack/services/auth_service.dart';
import 'package:filetrack/services/database_helper.dart';

class DossierListScreen extends StatefulWidget {
  const DossierListScreen({super.key});

  @override
  State<DossierListScreen> createState() => _DossierListScreenState();
}

class _DossierListScreenState extends State<DossierListScreen> {
  bool _isLoading = true;
  List<Dossier> _allDossiers = [];
  List<Transmission> _pendingTransmissions = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final currentUser = AuthService.instance.currentUser;

    final dossiers = await DatabaseHelper.instance.getAllDossiers();
    List<Transmission> pending = [];

    if (currentUser != null) {
      pending = await DatabaseHelper.instance
          .getPendingTransmissionsForService(currentUser.serviceId);
    }

    setState(() {
      _allDossiers = dossiers;
      _pendingTransmissions = pending;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    final myServiceDossiers = _allDossiers.where((d) {
      return d.creatorServiceId == user?.serviceId ||
          d.currentStatus.contains(user?.serviceId ?? '');
    }).toList();

    final filteredAll = _allDossiers.where((d) {
      final query = _searchQuery.toLowerCase();
      return d.id.toLowerCase().contains(query) ||
          d.title.toLowerCase().contains(query);
    }).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Suivi des Dossiers"),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Mon Service (${user?.serviceId})"),
              Tab(
                child: Row(
                  children: [
                    const Text("À Recevoir"),
                    if (_pendingTransmissions.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Badge(
                        label: Text(_pendingTransmissions.length.toString()),
                        backgroundColor: Colors.orange,
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: "Tous les Dossiers"),
            ],
          ),
        ),
        body: Column(
          children: [
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: "Rechercher par numéro ou titre...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _buildDossierListView(myServiceDossiers),
                        _buildPendingListView(),
                        _buildDossierListView(filteredAll),
                      ],
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateDossierScreen()),
            );
            if (result == true) _loadData();
          },
          icon: const Icon(Icons.add),
          label: const Text("Créer un dossier"),
          backgroundColor: const Color(0xFF005691),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDossierListView(List<Dossier> dossiers) {
    if (dossiers.isEmpty) {
      return const Center(child: Text("Aucun dossier trouvé."));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: dossiers.length,
      itemBuilder: (context, index) {
        final dossier = dossiers[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF005691),
              foregroundColor: Colors.white,
              child: Icon(Icons.folder_rounded),
            ),
            title: Text(
              dossier.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text("ID: ${dossier.id} | Créateur: ${dossier.creatorServiceId}"),
            trailing: Chip(
              label: Text(dossier.currentStatus, style: const TextStyle(fontSize: 11)),
              backgroundColor: Colors.blue.shade50,
            ),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DossierDetailScreen(dossierId: dossier.id),
                ),
              );
              _loadData();
            },
          ),
        );
      },
    );
  }

  Widget _buildPendingListView() {
    if (_pendingTransmissions.isEmpty) {
      return const Center(child: Text("Aucune transmission en attente de réception."));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: _pendingTransmissions.length,
      itemBuilder: (context, index) {
        final tr = _pendingTransmissions[index];
        return Card(
          color: Colors.amber.shade50,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              child: Icon(Icons.move_to_inbox_rounded),
            ),
            title: Text("Dossier ID : ${tr.dossierId}"),
            subtitle: Text("Expédié par : ${tr.senderServiceId} (Agent ${tr.senderUserId})\nNote: ${tr.observation}"),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right, color: Colors.orange),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DossierDetailScreen(dossierId: tr.dossierId),
                ),
              );
              _loadData();
            },
          ),
        );
      },
    );
  }
}
