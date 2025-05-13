// screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = false;
  bool isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _pseudoController = TextEditingController();
  String? _cachedDisplayName;

  @override
  void initState() {
    super.initState();
    // Charger initialement le displayName
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      // Forcer un rechargement de l'utilisateur pour obtenir les données les plus récentes
      try {
        await user.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;

        setState(() {
          _cachedDisplayName = refreshedUser?.displayName;
        });

        print('Données utilisateur chargées: displayName = $_cachedDisplayName');
      } catch (e) {
        print('Erreur lors du rechargement de l\'utilisateur: $e');
      }
    }
  }

  @override
  void dispose() {
    _pseudoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    // Si utilisateur déconnecté
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Vous devez être connecté pour accéder à votre profil'),
        ),
      );
    }

    // Utilisez le displayName mis en cache ou celui de l'utilisateur actuel ou une valeur par défaut
    final displayName = _cachedDisplayName ?? user.displayName ?? 'Utilisateur';

    // Mettre à jour le contrôleur en mode édition si nécessaire
    if (isEditing && _pseudoController.text.isEmpty) {
      _pseudoController.text = displayName;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
          ),
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                  _pseudoController.text = displayName;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  isEditing = false;
                  _pseudoController.text = '';
                });
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: isEditing
            ? _buildEditForm()
            : _buildProfileView(user, displayName),
      ),
    );
  }

  Widget _buildProfileView(User user, String displayName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Debug info (peut être supprimé en production)
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User ID: ${user.uid}'),
              Text('Auth DisplayName: ${user.displayName}'),
              Text('Cached DisplayName: $_cachedDisplayName'),
              Text('Email: ${user.email}'),
            ],
          ),
        ),

        // Avatar et informations de base
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.blue,
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
            style: const TextStyle(fontSize: 40, color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(user.email ?? 'Pas d\'email'),

        const SizedBox(height: 32),

        // Statistiques
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Parties', '0'),
            _buildStatItem('Victoires', '0'),
            _buildStatItem('Niveau', '1'),
          ],
        ),

        const SizedBox(height: 32),

        // Informations personnelles
        _buildProfileSection(
          title: 'Informations personnelles',
          children: [
            _buildInfoRow(Icons.person, 'Pseudo', displayName),
            _buildInfoRow(Icons.email, 'Email', user.email ?? 'Pas d\'email'),
            _buildInfoRow(
                Icons.calendar_today,
                'Date d\'inscription',
                'Mai 2025'
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Paramètres
        _buildProfileSection(
          title: 'Paramètres',
          children: [
            _buildToggleRow(Icons.notifications, 'Notifications', true),
            _buildToggleRow(Icons.dark_mode, 'Mode sombre', false),
            _buildToggleRow(Icons.volume_up, 'Sons', true),
          ],
        ),

        const SizedBox(height: 24),

        // Bouton de déconnexion
        ElevatedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.exit_to_app),
          label: const Text('Se déconnecter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _signOut() async {
    try {
      setState(() => isLoading = true);
      await Provider.of<AuthService>(context, listen: false).signOut();
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Modifier votre profil',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Champ Pseudo
          TextFormField(
            controller: _pseudoController,
            decoration: const InputDecoration(
              labelText: 'Pseudo',
              hintText: 'Entrez votre nouveau pseudo',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un pseudo';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Boutons d'action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    isEditing = false;
                    _pseudoController.text = '';
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final newPseudo = _pseudoController.text.trim();

    setState(() => isLoading = true);

    try {
      // Utiliser le service d'authentification
      await Provider.of<AuthService>(context, listen: false).updateUserProfile(
        pseudo: newPseudo,
      );

      // Mettre à jour le cache local
      setState(() {
        _cachedDisplayName = newPseudo;
        isEditing = false;
        isLoading = false;
        _pseudoController.text = '';
      });

      // Recharger les données
      await _loadUserData();

      // Afficher un message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès')),
      );
    } catch (e) {
      print('Erreur lors de la mise à jour du profil: $e');

      if (mounted) {
        setState(() => isLoading = false);

        // Afficher un message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(IconData icon, String title, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              // Fonctionnalité à implémenter plus tard
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title ${newValue ? "activé" : "désactivé"}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }
}