// services/auth_service.dart (version corrigée avec updateDisplayName)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:retronova_app/models/user_model.dart';
import 'package:retronova_app/services/api_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // État de l'utilisateur actuel
  Stream<User?> get user => _auth.authStateChanges();

  // Obtenir l'utilisateur actuel
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Inscription avec email et mot de passe
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String pseudo,
    required String nom,
    required String prenom,
  }) async {
    try {
      print('Tentative d\'inscription avec email: $email, pseudo: $pseudo');

      // 1. Créer l'utilisateur avec Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await result.user?.updateDisplayName(pseudo);
      await result.user?.reload();

      final String firebaseId = result.user?.uid ?? '';

      final apiService = ApiService(baseUrl: 'http://10.31.38.184:8000');

      final newUser = UserModel(
        firstName: nom,
        lastName: prenom,
        nbTicket: 0,
        bar: false,
        firebaseId: firebaseId,
      );

      final createdUser = await apiService.createUser(newUser);

      if (createdUser != null) {
        print('Utilisateur créé avec ID: ${createdUser.id}');
      } else {
        print('Erreur lors de la création.');
      }

      return result;
    } catch (e) {
      print('Erreur lors de l\'inscription: $e');
      rethrow;
    }
  }

  // Méthode standard pour mettre à jour le displayName
  Future<void> _updateUserDisplayName(User user, String displayName) async {
    try {
      // Essayer d'utiliser la méthode directe
      await user.updateDisplayName(displayName);
      await user.reload();
      print(
        'DisplayName mis à jour avec la méthode standard: ${user.displayName}',
      );
    } catch (e) {
      print('Erreur lors de la mise à jour standard du displayName: $e');
      rethrow;
    }
  }

  Future<void> _fallbackUpdateDisplayName(User user, String displayName) async {
    try {
      // Tentative de forcer le rafraîchissement du token
      try {
        final idToken = await user.getIdToken(true);
        if (idToken != null && idToken.isNotEmpty) {
          print('Token forcé à se rafraîchir: ${idToken.substring(0, 10)}...');
        } else {
          print('Token obtenu mais vide');
        }
      } catch (e) {
        print('Erreur lors du rafraîchissement du token: $e');
      }

      // Recharger l'utilisateur puis essayer à nouveau
      await _auth.currentUser?.reload();
      final refreshedUser = _auth.currentUser;

      if (refreshedUser != null) {
        await refreshedUser.updateDisplayName(displayName);
        await refreshedUser.reload();
        print('DisplayName mis à jour avec méthode alternative: ${refreshedUser.displayName}');
      }
    } catch (e) {
      print('Erreur lors de la mise à jour alternative du displayName: $e');
      // Continuer malgré l'erreur
    }
  }

  // Connexion avec email et mot de passe
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print(
        'Connexion réussie. Email: ${result.user?.email}, DisplayName: ${result.user?.displayName}',
      );
      return result;
    } catch (e) {
      print('Erreur lors de la connexion: $e');
      rethrow;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('Utilisateur déconnecté');
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
      rethrow;
    }
  }

  // Mise à jour du profil utilisateur
  Future<void> updateUserProfile({
    required String pseudo,
    String? nom,
    String? prenom,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      await currentUser.updateDisplayName(pseudo);
      await currentUser.reload();

      print('Profil mis à jour. Nouveau displayName: ${currentUser.displayName}');

      if (currentUser.displayName != pseudo) {
        print('Avertissement: Le displayName n\'a pas été mis à jour immédiatement.');
        // Vous pourriez choisir de réessayer ici ou de signaler l'erreur à l'UI
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du profil: $e');
      rethrow;
    }
  }

  // Pour compatibilité avec l'ancienne interface
  Future<void> updateUserPseudo(String newPseudo) async {
    return updateUserProfile(pseudo: newPseudo);
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Email de réinitialisation envoyé à: $email');
    } catch (e) {
      print('Erreur lors de l\'envoi de l\'email de réinitialisation: $e');
      rethrow;
    }
  }
}
