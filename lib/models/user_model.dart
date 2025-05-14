// lib/models/user_model.dart
class UserModel {
  final String firstName;
  final String lastName;
  final int nbTicket;
  final bool bar;
  final String firebaseId;

  // Champs en retour uniquement (en lecture)
  final String? id;
  final String? publiqueId;

  UserModel({
    required this.firstName,
    required this.lastName,
    required this.nbTicket,
    required this.bar,
    required this.firebaseId,
    this.id,
    this.publiqueId,
  });

  // Pour envoyer à l'API
  Map<String, dynamic> toApiJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'nb_ticket': nbTicket,
      'bar': bar,
      'firebase_id': firebaseId,
    };
  }

  // Pour parser la réponse de l'API
  factory UserModel.fromApi(Map<String, dynamic> json) {
    return UserModel(
      firstName: json['first_name'],
      lastName: json['last_name'],
      nbTicket: json['nb_ticket'],
      bar: json['bar'],
      firebaseId: json['firebase_id'],
      id: json['id'],
      publiqueId: json['publique_id'],
    );
  }
}
