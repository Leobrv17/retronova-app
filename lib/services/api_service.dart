// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
  };

  // Créer un utilisateur dans l'API
  Future<UserModel?> createUser(UserModel user) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/'),
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
}
