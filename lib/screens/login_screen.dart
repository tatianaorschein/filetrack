import 'package:flutter/material.dart';
import 'package:filetrack/screens/change_pin_screen.dart';
import 'package:filetrack/screens/dashboard_screen.dart';
import 'package:filetrack/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController(text: 'ADMIN001');
  final _pinController = TextEditingController();
  bool _isObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final id = _idController.text.trim();
    final pin = _pinController.text.trim();

    final result = await AuthService.instance.login(id, pin);

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    switch (result) {
      case LoginResult.mustChangePin:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Première connexion détectée. Vous devez modifier votre code PIN."),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ChangePinScreen()),
        );
        break;

      case LoginResult.success:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
        break;

      case LoginResult.userNotFound:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Identifiant introuvable. Vérifiez votre saisie."),
            backgroundColor: Colors.red,
          ),
        );
        break;

      case LoginResult.invalidCredentials:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Code PIN incorrect."),
            backgroundColor: Colors.red,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF005691).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.folder_special_rounded,
                      size: 64,
                      color: Color(0xFF005691),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "FileTrack",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF005691),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Hydro-Mekin - Suivi des dossiers",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Card Formulaire
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Connexion",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),

                          // Identifiant
                          TextFormField(
                            controller: _idController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: "Identifiant utilisateur",
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Veuillez entrer votre identifiant";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Code PIN
                          TextFormField(
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            obscureText: _isObscured,
                            maxLength: 6,
                            decoration: InputDecoration(
                              labelText: "Code PIN",
                              prefixIcon: const Icon(Icons.lock),
                              border: const OutlineInputBorder(),
                              counterText: "",
                              suffixIcon: IconButton(
                                icon: Icon(_isObscured
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () {
                                  setState(() {
                                    _isObscured = !_isObscured;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Veuillez entrer votre code PIN";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Bouton Se connecter
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
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
                                    "SE CONNECTER",
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

                  const SizedBox(height: 24),
                  Text(
                    "Identifiant par défaut : ADMIN001 | PIN initial : 1234",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
