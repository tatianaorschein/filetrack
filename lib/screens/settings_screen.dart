import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:filetrack/services/api_service.dart';
import 'package:filetrack/services/sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _serverUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _isApiKeyObscured = true;
  bool _syncCloudPdf = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final url = await ApiService.instance.getBaseUrl();
    final apiKey = await ApiService.instance.getApiKey();
    final prefs = await SharedPreferences.getInstance();
    final cloudPdf = prefs.getBool('sync_attachments_cloud') ?? false;

    setState(() {
      _serverUrlController.text = url;
      _apiKeyController.text = apiKey;
      _syncCloudPdf = cloudPdf;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final newUrl = _serverUrlController.text.trim();
    if (newUrl.isEmpty) return;

    await ApiService.instance.setBaseUrl(newUrl);
    await ApiService.instance.setApiKey(_apiKeyController.text.trim());

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sync_attachments_cloud', _syncCloudPdf);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Réglages serveur et clé API enregistrés avec succès !"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Réglages & Synchronisation"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Serveur Central Supabase / API
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.dns_rounded, color: Color(0xFF005691)),
                              SizedBox(width: 8),
                              Text(
                                "Serveur Central API / Supabase",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // URL du Serveur
                          TextFormField(
                            controller: _serverUrlController,
                            decoration: const InputDecoration(
                              labelText: "URL de l'API REST du serveur",
                              hintText: "https://xxxx.supabase.co/rest/v1",
                              prefixIcon: Icon(Icons.link),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Clé API (apikey Supabase)
                          TextFormField(
                            controller: _apiKeyController,
                            obscureText: _isApiKeyObscured,
                            decoration: InputDecoration(
                              labelText: "Clé API (apikey / Supabase Anon Key)",
                              hintText: "eyJhbGciOi...",
                              prefixIcon: const Icon(Icons.key),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_isApiKeyObscured
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () {
                                  setState(() => _isApiKeyObscured = !_isApiKeyObscured);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Bouton Enregistrer
                          ElevatedButton.icon(
                            onPressed: _saveSettings,
                            icon: const Icon(Icons.save),
                            label: const Text("ENREGISTRER LA CONFIGURATION"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005691),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(44),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section Option Stockage Cloud PDF
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: SwitchListTile(
                      title: const Text(
                        "Stockage Centralisé des Pièces Jointes",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        "Activer l'envoi automatique des scans PDF vers le serveur central en arrière-plan.",
                      ),
                      secondary: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF0088CC)),
                      value: _syncCloudPdf,
                      onChanged: (val) {
                        setState(() => _syncCloudPdf = val);
                        _saveSettings();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section État & Lancement Manuel de Synchro
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.sync_rounded, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                "État de la Synchronisation",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ValueListenableBuilder<String>(
                            valueListenable: SyncService.instance.lastSyncStatus,
                            builder: (context, status, _) {
                              return Text(
                                "Statut : $status",
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          ValueListenableBuilder<bool>(
                            valueListenable: SyncService.instance.isSyncing,
                            builder: (context, syncing, _) {
                              return ElevatedButton.icon(
                                onPressed: syncing
                                    ? null
                                    : () async {
                                        final success = await SyncService.instance.runFullSync();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(success
                                                  ? "Synchronisation réussie avec le serveur !"
                                                  : "Échec de synchro : Vérifiez l'URL, la clé API et la connexion."),
                                              backgroundColor: success ? Colors.green : Colors.orange,
                                            ),
                                          );
                                        }
                                      },
                                icon: syncing
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.sync),
                                label: Text(syncing ? "Synchronisation..." : "SYNCHRONISER MAINTENANT"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(44),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
