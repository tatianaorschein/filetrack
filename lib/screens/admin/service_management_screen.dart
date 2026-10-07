import 'package:flutter/material.dart';
import 'package:filetrack/models/service_model.dart';
import 'package:filetrack/services/database_helper.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({super.key});

  @override
  State<ServiceManagementScreen> createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  bool _isLoading = true;
  List<ServiceModel> _services = [];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    final services = await DatabaseHelper.instance.getAllServices();
    setState(() {
      _services = services;
      _isLoading = false;
    });
  }

  Future<void> _showServiceDialog([ServiceModel? serviceToEdit]) async {
    final isEditing = serviceToEdit != null;
    final idController = TextEditingController(text: serviceToEdit?.id ?? '');
    final nameController = TextEditingController(text: serviceToEdit?.name ?? '');
    final descController = TextEditingController(text: serviceToEdit?.description ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? "Modifier le Service" : "Ajouter un Service"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: idController,
                    enabled: !isEditing, // ID non modifiable en édition
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: "Code Service (ex: SERV_RH)",
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return "Le code du service est obligatoire";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Nom du Service",
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return "Le nom du service est obligatoire";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final newService = ServiceModel(
                  id: idController.text.trim().toUpperCase(),
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                );

                if (isEditing) {
                  await DatabaseHelper.instance.updateService(newService);
                } else {
                  await DatabaseHelper.instance.insertService(newService);
                }

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                _loadServices();
              },
        style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005691),
              foregroundColor: Colors.white,),
              child: Text(isEditing ? "Enregistrer" : "Ajouter"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteService(ServiceModel service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer le service"),
        content: Text("Voulez-vous vraiment supprimer le service '${service.name}' (${service.id}) ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Supprimer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteService(service.id);
      _loadServices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des Services"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? const Center(child: Text("Aucun service enregistré."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF005691),
                          foregroundColor: Colors.white,
                          child: Icon(Icons.business_rounded),
                        ),
                        title: Text(
                          service.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("ID: ${service.id}\n${service.description}"),
                        isThreeLine: service.description.isNotEmpty,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showServiceDialog(service),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteService(service),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showServiceDialog(),
        icon: const Icon(Icons.add),
        label: const Text("Nouveau Service"),
        backgroundColor: const Color(0xFF005691),
        foregroundColor: Colors.white,
      ),
    );
  }
}
