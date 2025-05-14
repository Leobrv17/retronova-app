// lib/models/friend_model.dart
import 'dart:convert';

class Friend {
  final String id;
  final String friendFromId;
  final String friendToId;
  bool accept;
  bool decline;
  bool delete;

  Friend({
    required this.id,
    required this.friendFromId,
    required this.friendToId,
    this.accept = false,
    this.decline = false,
    this.delete = false,
  });

  // Convert from JSON object
  factory Friend.fromJson(Map<String, dynamic> json) {
    print('Parsing friend from JSON: $json');
    return Friend(
      id: json['id'],
      friendFromId: json['friend_from_id'],
      friendToId: json['friend_to_id'],
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
    bool? accept,
    bool? decline,
    bool? delete,
  }) {
    return Friend(
      id: id ?? this.id,
      friendFromId: friendFromId ?? this.friendFromId,
      friendToId: friendToId ?? this.friendToId,
      accept: accept ?? this.accept,
      decline: decline ?? this.decline,
      delete: delete ?? this.delete,
    );
  }
}

// Class to handle friend requests
class FriendRequest {
  final String userId;
  final String targetUserId;

  FriendRequest({
    required this.userId,
    required this.targetUserId,
  });

  Map<String, dynamic> toJson() {
    return {
      'friend_from_id': userId,
      'friend_to_id': targetUserId,
      'accept': false,
      'decline': false,
      'delete': false,
    };
  }
}