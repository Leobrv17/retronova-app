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
  String? displayName; // Nom d'affichage (généralement depuis Firebase Auth)

  UserModel({
    required this.firstName,
    required this.lastName,
    required this.nbTicket,
    required this.bar,
    required this.firebaseId,
    this.id,
    this.publiqueId,
    this.displayName,
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
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      nbTicket: json['nb_ticket'] ?? 0,
      bar: json['bar'] ?? false,
      firebaseId: json['firebase_id'] ?? '',
      id: json['id'],
      publiqueId: json['publique_id'],
    );
  }

  // Créer une copie avec des modifications
  UserModel copyWith({
    String? firstName,
    String? lastName,
    int? nbTicket,
    bool? bar,
    String? firebaseId,
    String? id,
    String? publiqueId,
    String? displayName,
  }) {
    return UserModel(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nbTicket: nbTicket ?? this.nbTicket,
      bar: bar ?? this.bar,
      firebaseId: firebaseId ?? this.firebaseId,
      id: id ?? this.id,
      publiqueId: publiqueId ?? this.publiqueId,
      displayName: displayName ?? this.displayName,
    );
  }

  // Méthode pour obtenir le meilleur nom d'affichage disponible
  String getBestDisplayName() {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }

    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    if (publiqueId != null && publiqueId!.isNotEmpty) {
      return publiqueId!;
    }

    return 'Utilisateur';
  }
}