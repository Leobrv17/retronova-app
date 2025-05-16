// lib/services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  static const String _baseUrl = 'http://10.31.38.184:8000';

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
  };

  // Créer un utilisateur dans l'API
  Future<UserModel?> createUser(UserModel user) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/'),
        headers: headers,
        body: jsonEncode(user.toApiJson()),
      );

      if (response.statusCode == 200) {
        return UserModel.fromApi(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        print('Erreur : utilisateur avec ce Firebase ID existe déjà.');
        return null;
      } else {
        print('Erreur API: ${response.statusCode}, ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erreur lors de la création de l\'utilisateur: $e');
      return null;
    }
  }

  // Récupérer un utilisateur par son Firebase ID
  Future<UserModel?> getUserByFirebaseId(String firebaseId) async {
    try {
      // Utiliser la route correcte avec le paramètre firebase_id
      final response = await http.get(
        Uri.parse('$_baseUrl/users/firebase/$firebaseId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return UserModel.fromApi(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        print('Utilisateur non trouvé.');
        return null;
      } else {
        print('Erreur API: ${response.statusCode}, ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  // Récupérer un utilisateur par son ID système
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return UserModel.fromApi(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        print('Utilisateur avec ID $userId non trouvé.');
        return null;
      } else {
        print('Erreur API: ${response.statusCode}, ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  // Récupérer un utilisateur par son Public ID
  Future<UserModel?> getUserByPublicId(String publicId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users?publique_id=$publicId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return UserModel.fromApi(data[0]);
        } else {
          print('Aucun utilisateur trouvé avec le public ID: $publicId');
          return null;
        }
      } else {
        print('Erreur API: ${response.statusCode}, ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  // Mettre à jour un utilisateur
  Future<UserModel?> updateUser(UserModel user) async {
    try {
      if (user.id == null) {
        print('Erreur: Impossible de mettre à jour un utilisateur sans ID.');
        return null;
      }

      // Préparation du payload pour l'API en utilisant le format attendu
      final Map<String, dynamic> updateData = {
        'first_name': user.firstName,
        'last_name': user.lastName,
        'nb_ticket': user.nbTicket,
        'bar': user.bar,
        'firebase_id': user.firebaseId
      };

      final response = await http.put(
        Uri.parse('$_baseUrl/users/${user.id}'),
        headers: headers,
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        return UserModel.fromApi(jsonDecode(response.body));
      } else {
        print('Erreur API: ${response.statusCode}, ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'utilisateur: $e');
      return null;
    }
  }
}