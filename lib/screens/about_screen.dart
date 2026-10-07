import 'package:flutter/material.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _language = 'FR'; // 'FR' ou 'EN'

  static const String textFr =
      "FileTrack est une application de suivi des dossiers, réalisée par la SDCAF de la société Mekin Hydroelectric Development Corporation (Hydro-Mekin).";

  static const String textEn =
      "FileTrack is a file-tracking application developed by SDCAF of Mekin Hydroelectric Development Corporation (Hydro-Mekin).";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_language == 'FR' ? "À Propos" : "About Us"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF005691).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_special_rounded,
                  size: 72,
                  color: Color(0xFF005691),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "FileTrack",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF005691),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                "Version 1.0.0",
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Sélecteur de Langue (FR / EN)
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'FR', label: Text("Français")),
                  ButtonSegment(value: 'EN', label: Text("English")),
                ],
                selected: {_language},
                onSelectionChanged: (newSelection) {
                  setState(() => _language = newSelection.first);
                },
              ),
              const SizedBox(height: 32),

              // Texte explicatif imposé
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    _language == 'FR' ? textFr : textEn,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                "Mekin Hydroelectric Development Corporation (Hydro-Mekin)\nSDCAF © 2026",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
