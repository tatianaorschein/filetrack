import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:filetrack/models/service_model.dart';
import 'package:filetrack/models/user.dart';
import 'package:filetrack/services/database_helper.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  bool _isLoading = true;
  List<User> _users = [];
  List<ServiceModel> _services = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final users = await DatabaseHelper.instance.getAllUsers();
    final services = await DatabaseHelper.instance.getAllServices();
    setState(() {
      _users = users;
      _services = services;
      _isLoading = false;
    });
  }

  Future<void> _showUserDialog([User? userToEdit]) async {
    final isEditing = userToEdit != null;
    final idController = TextEditingController(text: userToEdit?.id ?? '');
    final nameController = TextEditingController(text: userToEdit?.name ?? '');
    final pinController = TextEditingController(text: isEditing ? '' : '1234');

    String selectedServiceId = userToEdit?.serviceId ??
        (_services.isNotEmpty ? _services.first.id : '');
    String selectedRole = userToEdit?.role ?? 'agent';
    bool resetPin = false;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? "Modifier l'utilisateur" : "Ajouter un Utilisateur"),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ID Utilisateur
                      TextFormField(
                        controller: idController,
                        enabled: !isEditing,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: "Identifiant (ex: AGENT002)",
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "L'identifiant est obligatoire";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Nom complet
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Nom complet",
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "Le nom est obligatoire";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Service rattaché
                      DropdownButtonFormField<String>(
                        value: selectedServiceId.isNotEmpty &&
                                _services.any((s) => s.id == selectedServiceId)
                            ? selectedServiceId
                            : null,
                        decoration: const InputDecoration(
                          labelText: "Service rattaché",
                          border: OutlineInputBorder(),
                        ),
                        items: _services.map((s) {
                          return DropdownMenuItem(
                            value: s.id,
                            child: Text("${s.name} (${s.id})"),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedServiceId = val);
                          }
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return "Veuillez sélectionner un service";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Rôle
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(
                          labelText: "Rôle",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: "agent", child: Text("Agent")),
                          DropdownMenuItem(value: "admin", child: Text("Administrateur")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedRole = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      if (!isEditing) ...[
                        // Code PIN initial
                        TextFormField(
                          controller: pinController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: "PIN Initial (par défaut: 1234)",
                            border: OutlineInputBorder(),
                            counterText: "",
                          ),
                          validator: (val) {
                            if (val == null || val.trim().length < 4) {
                              return "Au moins 4 chiffres requis";
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        CheckboxListTile(
                          title: const Text("Réinitialiser le PIN à 1234"),
                          subtitle: const Text("Exigera le changement de PIN à la reconnexion"),
                          value: resetPin,
                          onChanged: (val) {
                            setDialogState(() => resetPin = val ?? false);
                          },
                        ),
                      ],
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

                    final pinToUse = isEditing
                        ? (resetPin ? '1234' : null)
                        : pinController.text.trim();

                    final pinHash = pinToUse != null
                        ? sha256.convert(utf8.encode(pinToUse)).toString()
                        : userToEdit!.pinHash;

                    final newUser = User(
                      id: idController.text.trim().toUpperCase(),
                      name: nameController.text.trim(),
                      serviceId: selectedServiceId,
                      pinHash: pinHash,
                      role: selectedRole,
                      mustChangePin: isEditing ? (resetPin ? true : userToEdit!.mustChangePin) : true,
                    );

                    if (isEditing) {
                      await DatabaseHelper.instance.updateUser(newUser);
                    } else {
                      await DatabaseHelper.instance.insertUser(newUser);
                    }

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    _loadData();
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
      },
    );
  }

  Future<void> _confirmDeleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer l'utilisateur"),
        content: Text("Voulez-vous vraiment supprimer l'utilisateur '${user.name}' (${user.id}) ?"),
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
      await DatabaseHelper.instance.deleteUser(user.id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des Utilisateurs"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text("Aucun utilisateur trouvé."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: user.isAdmin
                              ? Colors.amber.shade800
                              : const Color(0xFF005691),
                          foregroundColor: Colors.white,
                          child: Icon(user.isAdmin
                              ? Icons.admin_panel_settings
                              : Icons.person),
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "ID: ${user.id} | Service: ${user.serviceId}\nRôle: ${user.role.toUpperCase()}",
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showUserDialog(user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteUser(user),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text("Nouvel Utilisateur"),
        backgroundColor: const Color(0xFF005691),
        foregroundColor: Colors.white,
      ),
    );
  }
}
