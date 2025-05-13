// screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // États du formulaire
  String email = '';
  String password = '';
  String confirmPassword = '';
  String pseudo = '';
  String nom = '';
  String prenom = '';
  String error = '';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[400],
        elevation: 0.0,
        title: const Text('Inscription'),
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
                const SizedBox(height: 10.0),
                // Logo ou Image
                Icon(
                  Icons.person_add,
                  size: 80.0,
                  color: Colors.blue[400],
                ),
                const SizedBox(height: 10.0),

                // Champ pseudo (obligatoire)
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Pseudo',
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: const Icon(Icons.person),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue[100]!, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue[400]!, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  validator: (val) => val!.isEmpty ? 'Entrez un pseudo' : null,
                  onChanged: (val) {
                    setState(() => pseudo = val);
                  },
                ),
                const SizedBox(height: 10.0),

                // Champ nom (optionnel)
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Nom (optionnel)',
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: const Icon(Icons.person_outline),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue[100]!, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue[400]!, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => nom = val);
                  },
                ),
                const SizedBox(height: 10.0),

                // Champ prénom (optionnel)
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Prénom (optionnel)',
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: const Icon(Icons.person_outline),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue[100]!, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue[400]!, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => prenom = val);
                  },
                ),
                const SizedBox(height: 10.0),

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
                  validator: (val) {
                    if (val!.isEmpty) {
                      return 'Entrez un email';
                    }
                    // Vérification basique du format email
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                      return 'Entrez un email valide';
                    }
                    return null;
                  },
                  onChanged: (val) {
                    setState(() => email = val);
                  },
                ),
                const SizedBox(height: 10.0),

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
                const SizedBox(height: 10.0),

                // Champ confirmation mot de passe
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Confirmer le mot de passe',
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue[100]!, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue[400]!, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  validator: (val) {
                    if (val!.isEmpty) {
                      return 'Confirmez votre mot de passe';
                    }
                    if (val != password) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                  obscureText: true,
                  onChanged: (val) {
                    setState(() => confirmPassword = val);
                  },
                ),
                const SizedBox(height: 20.0),

                // Bouton d'inscription
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[400],
                    padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text(
                    'S\'INSCRIRE',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => loading = true);

                      try {
                        // Utiliser le service d'authentification pour créer l'utilisateur
                        await Provider.of<AuthService>(context, listen: false).registerWithEmailAndPassword(
                          email: email,
                          password: password,
                          pseudo: pseudo,
                          nom: nom,
                          prenom: prenom,
                        );

                        // Pas besoin de navigation ici car le Wrapper s'en chargera automatiquement
                      } catch (e) {
                        String errorMessage = 'Erreur d\'inscription';

                        // Gérer les erreurs spécifiques
                        if (e.toString().contains('email-already-in-use')) {
                          errorMessage = 'Cet email est déjà utilisé';
                        } else if (e.toString().contains('weak-password')) {
                          errorMessage = 'Mot de passe trop faible';
                        } else if (e.toString().contains('invalid-email')) {
                          errorMessage = 'Format d\'email invalide';
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
                const SizedBox(height: 10.0),

                // Lien vers la page de connexion
                TextButton(
                  child: Text(
                    'Déjà inscrit ? Connectez-vous',
                    style: TextStyle(color: Colors.blue[800]),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}