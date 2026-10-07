import 'package:flutter/material.dart';
import 'package:filetrack/screens/about_screen.dart';
import 'package:filetrack/screens/admin/service_management_screen.dart';
import 'package:filetrack/screens/admin/user_management_screen.dart';
import 'package:filetrack/screens/dossiers/create_dossier_screen.dart';
import 'package:filetrack/screens/dossiers/dossier_list_screen.dart';
import 'package:filetrack/screens/db_test_screen.dart';
import 'package:filetrack/screens/login_screen.dart';
import 'package:filetrack/screens/settings_screen.dart';
import 'package:filetrack/services/auth_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Déconnexion"),
        content: const Text("Voulez-vous vraiment vous déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005691),
              foregroundColor: Colors.white,
            ),
            child: const Text("Déconnexion"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.instance.logout();
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("FileTrack - Tableau de bord"),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: "À Propos",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Réglages & Synchro",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Déconnexion",
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte de Profil Utilisateur
            Card(
              color: const Color(0xFF005691),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        user?.isAdmin == true
                            ? Icons.admin_panel_settings
                            : Icons.person,
                        size: 36,
                        color: const Color(0xFF005691),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Utilisateur',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "ID: ${user?.id ?? ''} | Service: ${user?.serviceId ?? ''}",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user?.role.toUpperCase() ?? 'AGENT',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Section Suivi des Dossiers
            Text(
              "Gestion des Dossiers",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF005691),
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDashCard(
                    context,
                    title: "Nouveau Dossier",
                    subtitle: "Créer un dossier",
                    icon: Icons.create_new_folder_rounded,
                    color: const Color(0xFF005691),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreateDossierScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDashCard(
                    context,
                    title: "Suivi & Réception",
                    subtitle: "Consulter & valider",
                    icon: Icons.folder_shared_rounded,
                    color: const Color(0xFF0088CC),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DossierListScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section Configuration & Synchro
            Text(
              "Synchronisation & Réglages",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF005691),
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDashCard(
                    context,
                    title: "Synchro Serveur",
                    subtitle: "Configuration API",
                    icon: Icons.sync_rounded,
                    color: Colors.green.shade700,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDashCard(
                    context,
                    title: "À Propos",
                    subtitle: "Infos Mekin",
                    icon: Icons.info_outline_rounded,
                    color: Colors.purple.shade700,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section Administration (Visible uniquement si Admin)
            if (user?.isAdmin == true) ...[
              Text(
                "Administration System",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF005691),
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDashCard(
                      context,
                      title: "Services",
                      subtitle: "Gérer les services",
                      icon: Icons.business_rounded,
                      color: Colors.blue.shade700,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ServiceManagementScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDashCard(
                      context,
                      title: "Utilisateurs",
                      subtitle: "Gérer le personnel",
                      icon: Icons.people_alt_rounded,
                      color: Colors.teal.shade700,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const UserManagementScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Section Outils / Diagnostics
            Text(
              "Base de données & Outils",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF005691),
                  ),
            ),
            const SizedBox(height: 12),
            _buildDashCard(
              context,
              title: "Test Base SQLite",
              subtitle: "Consulter et tester l'insertion dans les tables",
              icon: Icons.storage_rounded,
              color: Colors.deepOrange.shade700,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DbTestScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
