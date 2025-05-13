// screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // États du formulaire
  String email = '';
  String password = '';
  String error = '';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[400],
        elevation: 0.0,
        title: const Text('Connexion'),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: loading
            ? const Center(child: SpinKitChasingDots(color: Colors.blue, size: 50.0))
            : Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20.0),
                // Logo ou Image
                Icon(
                  Icons.account_circle,
                  size: 100.0,
                  color: Colors.blue[400],
                ),
                const SizedBox(height: 20.0),
                // Champ email
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Email',
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: const Icon(Icons.email),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue[100]!, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue[400]!, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  validator: (val) => val!.isEmpty ? 'Entrez un email' : null,
                  onChanged: (val) {
                    setState(() => email = val);
                  },
                ),
                const SizedBox(height: 20.0),
                // Champ mot de passe
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Mot de passe',
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: const Icon(Icons.lock),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue[100]!, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue[400]!, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  validator: (val) => val!.length < 6 ? 'Entrez un mot de passe de 6+ caractères' : null,
                  obscureText: true,
                  onChanged: (val) {
                    setState(() => password = val);
                  },
                ),
                const SizedBox(height: 20.0),
                // Bouton de connexion
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[400],
                    padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text(
                    'SE CONNECTER',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => loading = true);

                      try {
                        await Provider.of<AuthService>(context, listen: false).signInWithEmailAndPassword(
                          email: email,
                          password: password,
                        );
                        // Pas besoin de navigation ici car le Wrapper s'en chargera

                      } catch (e) {
                        String errorMessage = 'Identifiants incorrects';

                        // Gérer les erreurs spécifiques
                        if (e.toString().contains('user-not-found')) {
                          errorMessage = 'Aucun utilisateur trouvé avec cet email';
                        } else if (e.toString().contains('wrong-password')) {
                          errorMessage = 'Mot de passe incorrect';
                        } else if (e.toString().contains('invalid-email')) {
                          errorMessage = 'Format d\'email invalide';
                        } else if (e.toString().contains('user-disabled')) {
                          errorMessage = 'Compte désactivé';
                        } else if (e.toString().contains('too-many-requests')) {
                          errorMessage = 'Trop de tentatives, réessayez plus tard';
                        }

                        setState(() {
                          error = errorMessage;
                          loading = false;
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 12.0),
                Text(
                  error,
                  style: const TextStyle(color: Colors.red, fontSize: 14.0),
                ),
                const SizedBox(height: 20.0),
                // Lien vers la page d'inscription
                TextButton(
                  child: Text(
                    'Pas encore de compte ? Inscrivez-vous',
                    style: TextStyle(color: Colors.blue[800]),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                ),
                // Lien de récupération de mot de passe
                TextButton(
                  child: Text(
                    'Mot de passe oublié ?',
                    style: TextStyle(color: Colors.blue[800]),
                  ),
                  onPressed: () {
                    // Afficher une boîte de dialogue pour récupérer le mot de passe
                    _showForgotPasswordDialog();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez votre adresse email pour recevoir un lien de réinitialisation'),
            const SizedBox(height: 16),
            TextFormField(
              controller: resetEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isNotEmpty) {
                try {
                  await Provider.of<AuthService>(context, listen: false)
                      .resetPassword(email);

                  // Fermer la boîte de dialogue
                  Navigator.pop(context);

                  // Afficher un message de confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email de réinitialisation envoyé. Vérifiez votre boîte de réception.'),
                      duration: Duration(seconds: 5),
                    ),
                  );
                } catch (e) {
                  // Afficher un message d'erreur
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );

                  // Fermer la boîte de dialogue
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}