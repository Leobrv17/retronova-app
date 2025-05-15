// lib/models/friend_model.dart
import 'dart:convert';

class Friend {
  final String id;
  final String friendFromId;
  final String friendToId;
  // Nouveaux champs pour stocker les noms d'utilisateur
  final String? friendFromPublicId;
  final String? friendToPublicId;
  final String? friendFromName;
  final String? friendToName;
  bool accept;
  bool decline;
  bool delete;

  Friend({
    required this.id,
    required this.friendFromId,
    required this.friendToId,
    this.friendFromPublicId,
    this.friendToPublicId,
    this.friendFromName,
    this.friendToName,
    this.accept = false,
    this.decline = false,
    this.delete = false,
  });

  // Convert from JSON object
  factory Friend.fromJson(Map<String, dynamic> json) {
    print("Parsing friend JSON: $json"); // Log pour debug
    return Friend(
      id: json['id'],
      friendFromId: json['friend_from_id'],
      friendToId: json['friend_to_id'],
      friendFromPublicId: json['friend_from_public_id'],
      friendToPublicId: json['friend_to_public_id'],
      friendFromName: json['friend_from_name'],
      friendToName: json['friend_to_name'],
      accept: json['accept'] ?? false,
      decline: json['decline'] ?? false,
      delete: json['delete'] ?? false,
    );
  }

  // Convert to JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'friend_from_id': friendFromId,
      'friend_to_id': friendToId,
      'friend_from_public_id': friendFromPublicId,
      'friend_to_public_id': friendToPublicId,
      'friend_from_name': friendFromName,
      'friend_to_name': friendToName,
      'accept': accept,
      'decline': decline,
      'delete': delete,
    };
  }

  // Create a request object for sending to the API
  Map<String, dynamic> toRequestJson() {
    return {
      'friend_from_id': friendFromId,
      'friend_to_id': friendToId,
      'accept': accept,
      'decline': decline,
      'delete': delete,
    };
  }

  // Create an update request object for sending to the API
  Map<String, dynamic> toUpdateJson() {
    return {
      'accept': accept,
      'decline': decline,
      'delete': delete,
    };
  }

  // Copy method to create a new instance with updated fields
  Friend copyWith({
    String? id,
    String? friendFromId,
    String? friendToId,
    String? friendFromPublicId,
    String? friendToPublicId,
    String? friendFromName,
    String? friendToName,
    bool? accept,
    bool? decline,
    bool? delete,
  }) {
    return Friend(
      id: id ?? this.id,
      friendFromId: friendFromId ?? this.friendFromId,
      friendToId: friendToId ?? this.friendToId,
      friendFromPublicId: friendFromPublicId ?? this.friendFromPublicId,
      friendToPublicId: friendToPublicId ?? this.friendToPublicId,
      friendFromName: friendFromName ?? this.friendFromName,
      friendToName: friendToName ?? this.friendToName,
      accept: accept ?? this.accept,
      decline: decline ?? this.decline,
      delete: delete ?? this.delete,
    );
  }

  // Obtenir le nom ou l'identifiant public de l'autre utilisateur selon le point de vue
  String getOtherUserDisplayName(String currentUserId) {
    final bool isCurrentUserSender = friendFromId == currentUserId;

    if (isCurrentUserSender) {
      // L'utilisateur actuel est l'expéditeur, renvoyer les infos du destinataire
      return friendToName ?? friendToPublicId ?? "Utilisateur ${friendToId.substring(0, 8)}";
    } else {
      // L'utilisateur actuel est le destinataire, renvoyer les infos de l'expéditeur
      return friendFromName ?? friendFromPublicId ?? "Utilisateur ${friendFromId.substring(0, 8)}";
    }
  }

  // Obtenir l'ID de l'autre utilisateur selon le point de vue
  String getOtherUserId(String currentUserId) {
    return friendFromId == currentUserId ? friendToId : friendFromId;
  }
}

// Class to handle friend requests
class FriendRequest {
  final String userId;     // Identifiant du demandeur
  final String targetId;   // Identifiant de la cible

  FriendRequest({
    required this.userId,
    required this.targetId,
  });

  Map<String, dynamic> toJson() {
    return {
      'friend_from_id': userId,
      'friend_to_id': targetId,
      'accept': false,
      'decline': false,
      'delete': false,
    };
  }
}