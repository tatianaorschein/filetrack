import 'package:flutter/material.dart';
import 'package:filetrack/screens/dashboard_screen.dart';
import 'package:filetrack/services/auth_service.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isObscuredOld = true;
  bool _isObscuredNew = true;
  bool _isObscuredConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final oldPin = _oldPinController.text.trim();
    final newPin = _newPinController.text.trim();

    final success = await AuthService.instance.changePin(
      oldPin: oldPin,
      newPin: newPin,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Code PIN modifié avec succès !"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("L'ancien code PIN saisi est incorrect."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Changement de PIN Obligatoire"),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.security_rounded,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  "Changement de code PIN requis",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Bonjour ${user?.name ?? ''} (${user?.id ?? ''}). Pour des raisons de sécurité, vous devez changer votre code PIN initial avant de continuer.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 32),

                // Ancien PIN
                TextFormField(
                  controller: _oldPinController,
                  keyboardType: TextInputType.number,
                  obscureText: _isObscuredOld,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: "Ancien PIN (ex: 1234)",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    counterText: "",
                    suffixIcon: IconButton(
                      icon: Icon(_isObscuredOld ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _isObscuredOld = !_isObscuredOld),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Entrez l'ancien code PIN";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Nouveau PIN
                TextFormField(
                  controller: _newPinController,
                  keyboardType: TextInputType.number,
                  obscureText: _isObscuredNew,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: "Nouveau PIN (4 à 6 chiffres)",
                    prefixIcon: const Icon(Icons.lock_reset),
                    border: const OutlineInputBorder(),
                    counterText: "",
                    suffixIcon: IconButton(
                      icon: Icon(_isObscuredNew ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _isObscuredNew = !_isObscuredNew),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 4) {
                      return "Le nouveau PIN doit comporter au moins 4 chiffres";
                    }
                    if (value.trim() == _oldPinController.text.trim()) {
                      return "Le nouveau PIN doit être différent de l'ancien";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirmer le nouveau PIN
                TextFormField(
                  controller: _confirmPinController,
                  keyboardType: TextInputType.number,
                  obscureText: _isObscuredConfirm,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: "Confirmer le nouveau PIN",
                    prefixIcon: const Icon(Icons.check_circle_outline),
                    border: const OutlineInputBorder(),
                    counterText: "",
                    suffixIcon: IconButton(
                      icon: Icon(_isObscuredConfirm ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _isObscuredConfirm = !_isObscuredConfirm),
                    ),
                  ),
                  validator: (value) {
                    if (value != _newPinController.text) {
                      return "Les codes PIN ne correspondent pas";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Bouton Valider
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleChangePin,
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
                          "ENREGISTRER LE NOUVEAU PIN",
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
