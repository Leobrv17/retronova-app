// lib/services/friend_service.dart - Version complète
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/friend_model.dart';
import '../models/user_model.dart';

class FriendService {
  // Base API URL
  final String baseUrl = 'http://192.168.98.215:8000';
  final http.Client _client = http.Client();

  // Helper to get authentication token
  Future<String?> _getAuthToken() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Getting auth token for user: ${user.uid}');
        final token = await user.getIdToken();
        if (token != null && token.isNotEmpty) {
          return token;
        }
      }
      return null;
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  // Headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // Get all friends
  // lib/services/friend_service.dart

  Future<List<Friend>> getAllFriends() async {
    try {
      final headers = await _getHeaders();
      print('Fetching all friends from API');

      // Ajout d'un log de l'URL complète pour vérification
      final url = '$baseUrl/friends';
      print('API URL: $url');

      final response = await _client.get(Uri.parse(url), headers: headers);

      print('Friends API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Friends API response body: ${response.body}');
        final List<dynamic> data = json.decode(response.body);
        final friends = data.map((json) => Friend.fromJson(json)).toList();

        // Afficher les détails de chaque ami pour le débogage
        for (var friend in friends) {
          print(
            'Friend ID: ${friend.id}, From: ${friend.friendFromId}, To: ${friend.friendToId}, Accept: ${friend.accept}',
          );
        }

        // Enrichir les données des amis avec les noms d'utilisateur
        await _enrichFriendsWithUserDetails(friends);

        return friends;
      } else {
        print(
          'Failed to load friends: ${response.statusCode}, ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Error fetching friends: $e');
      return [];
    }
  }

  // Enrichir les données des amis avec les informations utilisateur (pseudo, publique_id)
  Future<void> _enrichFriendsWithUserDetails(List<Friend> friends) async {
    try {
      // Récupérer toutes les informations utilisateur en une seule requête
      final headers = await _getHeaders();
      final response = await _client.get(
        Uri.parse('$baseUrl/users'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersData = json.decode(response.body);
        final Map<String, UserModel> usersById = {};

        // Créer un map pour recherche rapide
        for (var userData in usersData) {
          final user = UserModel.fromApi(userData);
          if (user.id != null) {
            usersById[user.id!] = user;
          }
        }

        // Mettre à jour les objets Friend avec les informations utilisateur
        for (var i = 0; i < friends.length; i++) {
          final friend = friends[i];

          // Trouver les informations de l'expéditeur
          if (usersById.containsKey(friend.friendFromId)) {
            final fromUser = usersById[friend.friendFromId]!;
            friends[i] = friend.copyWith(
              friendFromPublicId: fromUser.publiqueId,
              friendFromName:
                  '${fromUser.firstName} ${fromUser.lastName}'.trim(),
            );
          }

          // Trouver les informations du destinataire
          if (usersById.containsKey(friend.friendToId)) {
            final toUser = usersById[friend.friendToId]!;
            friends[i] = friend.copyWith(
              friendToPublicId: toUser.publiqueId,
              friendToName: '${toUser.firstName} ${toUser.lastName}'.trim(),
            );
          }
        }
      }
    } catch (e) {
      print('Error enriching friends with user details: $e');
    }
  }

  // Find a user by their Firebase ID
  Future<UserModel?> findUserByFirebaseId(String firebaseId) async {
    try {
      print('Finding user with Firebase ID: $firebaseId');
      final headers = await _getHeaders();
      // Corriger l'URL pour utiliser le paramètre de requête au lieu d'un chemin spécifique
      final response = await _client.get(
        Uri.parse('$baseUrl/users/firebase/$firebaseId'),
        headers: headers,
      );

      print('Find user response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print("hello, ${data}");
        if (data.isNotEmpty) {
          print('User found');
          return UserModel.fromApi(data);
        } else {
          print('No users found with Firebase ID: $firebaseId');
        }
      } else {
        print(
          'Failed to find user by Firebase ID: ${response.statusCode}, ${response.body}',
        );
      }
      return null;
    } catch (e) {
      print('Error finding user by Firebase ID: $e');
      return null;
    }
  }

  // Find a user by their Public ID
  Future<UserModel?> findUserByPublicId(String publicId) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.get(
        Uri.parse('$baseUrl/users'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (var userData in data) {
          final user = UserModel.fromApi(userData);
          if (user.publiqueId == publicId) {
            return user;
          }
        }
      }
      print('User with Public ID $publicId not found');
      return null;
    } catch (e) {
      print('Error finding user by Public ID: $e');
      return null;
    }
  }

  // Create friend request using public ID
  Future<Friend?> createFriendRequestByPublicId(String targetPublicId) async {
    try {
      // 1. Récupérer l'utilisateur actuel (Firebase Auth)
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Not logged in');
      }

      // 2. Récupérer l'utilisateur système correspondant au public ID cible
      final targetUser = await findUserByPublicId(targetPublicId);
      if (targetUser == null) {
        throw Exception('User with public ID $targetPublicId not found');
      }

      // 3. Récupérer l'utilisateur système correspondant à l'utilisateur actuel
      final currentSystemUser = await findUserByFirebaseId(currentUser.uid);
      if (currentSystemUser == null) {
        throw Exception('Current user not found in system');
      }

      // 4. Créer la demande d'ami
      final requestBody = {
        'friend_from_id': currentSystemUser.id,
        'friend_to_id': targetUser.id,
        'accept': false,
        'decline': false,
        'delete': false,
      };

      print('Creating friend request: $requestBody');
      final headers = await _getHeaders();
      final response = await _client.post(
        Uri.parse('$baseUrl/friends/'),
        headers: headers,
        body: json.encode(requestBody),
      );

      print('Create friend request response: ${response.statusCode}');

      if (response.statusCode == 200) {
        Friend friend = Friend.fromJson(json.decode(response.body));

        // Enrichir avec les données utilisateur
        friend = friend.copyWith(
          friendFromPublicId: currentSystemUser.publiqueId,
          friendFromName:
              '${currentSystemUser.firstName} ${currentSystemUser.lastName}'
                  .trim(),
          friendToPublicId: targetUser.publiqueId,
          friendToName: '${targetUser.firstName} ${targetUser.lastName}'.trim(),
        );

        return friend;
      } else if (response.statusCode == 400) {
        final errorMessage = json.decode(response.body)['detail'];
        throw Exception(errorMessage);
      } else {
        throw Exception(
          'Failed to create friend request: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error creating friend request: $e');
      rethrow;
    }
  }

  // Accept friend request
  Future<Friend?> acceptFriendRequest(String friendId) async {
    try {
      print('Accepting friend request ID: $friendId');
      final headers = await _getHeaders();

      // Ajouter des logs pour suivre l'exécution
      print('Sending PUT request to: $baseUrl/friends/$friendId');

      final requestBody = {'accept': true, 'decline': false};

      print('Request body: $requestBody');

      final response = await _client.put(
        Uri.parse('$baseUrl/friends/$friendId'),
        headers: headers,
        body: json.encode(requestBody),
      );

      print('Accept friend response status: ${response.statusCode}');
      print('Accept friend response body: ${response.body}');

      if (response.statusCode == 200) {
        Friend friend = Friend.fromJson(json.decode(response.body));

        // Enrichir avec les informations utilisateur
        final List<Friend> friends = [friend];
        await _enrichFriendsWithUserDetails(friends);

        return friends.first;
      } else if (response.statusCode == 404) {
        print('Friend not found with ID: $friendId');
        return null;
      } else {
        print(
          'Failed to accept friend request: ${response.statusCode}, ${response.body}',
        );
        throw Exception(
          'Failed to accept friend request: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error accepting friend request: $e');
      rethrow;
    }
  }

  // Decline friend request
  Future<Friend?> declineFriendRequest(String friendId) async {
    try {
      print('Declining friend request ID: $friendId');
      final headers = await _getHeaders();

      final requestBody = {'accept': false, 'decline': true};

      final response = await _client.put(
        Uri.parse('$baseUrl/friends/$friendId'),
        headers: headers,
        body: json.encode(requestBody),
      );

      print('Decline friend response status: ${response.statusCode}');
      print('Decline friend response body: ${response.body}');

      if (response.statusCode == 200) {
        return Friend.fromJson(json.decode(response.body));
      } else {
        print(
          'Failed to decline friend request: ${response.statusCode}, ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error declining friend request: $e');
      return null;
    }
  }

  // Get pending requests from current user (où l'utilisateur actuel est l'expéditeur)
  Future<List<Friend>> getOutgoingRequests(String currentUserId) async {
    final allFriends = await getAllFriends();
    return allFriends
        .where(
          (friend) =>
              friend.friendFromId == currentUserId &&
              !friend.accept &&
              !friend.decline &&
              !friend.delete,
        )
        .toList();
  }

  // Get pending requests to current user (où l'utilisateur actuel est le destinataire)
  Future<List<Friend>> getIncomingRequests(String currentUserId) async {
    final allFriends = await getAllFriends();
    return allFriends
        .where(
          (friend) =>
              friend.friendToId == currentUserId &&
              !friend.accept &&
              !friend.decline &&
              !friend.delete,
        )
        .toList();
  }

  // Get confirmed friends
  Future<List<Friend>> getConfirmedFriends(String currentUserId) async {
    final allFriends = await getAllFriends();
    return allFriends
        .where(
          (friend) =>
              (friend.friendFromId == currentUserId ||
                  friend.friendToId == currentUserId) &&
              friend.accept &&
              !friend.decline &&
              !friend.delete,
        )
        .toList();
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      print('Searching users with query: $query');
      final headers = await _getHeaders();
      final response = await _client.get(
        Uri.parse('$baseUrl/users'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        print('Search users response received');
        final List<dynamic> data = json.decode(response.body);
        final List<UserModel> allUsers =
            data.map((json) => UserModel.fromApi(json)).toList();

        // Filter users locally based on the query
        if (query.isEmpty) {
          // Return all users if no query is provided
          return allUsers;
        } else {
          // Filter by name or public ID if query is provided
          return allUsers.where((user) {
            final firstName = user.firstName?.toLowerCase() ?? '';
            final lastName = user.lastName?.toLowerCase() ?? '';
            final fullName = '$firstName $lastName'.trim().toLowerCase();
            final publicId = user.publiqueId?.toLowerCase() ?? '';
            final searchQuery = query.toLowerCase();

            return firstName.contains(searchQuery) ||
                lastName.contains(searchQuery) ||
                fullName.contains(searchQuery) ||
                publicId.contains(searchQuery);
          }).toList();
        }
      } else {
        print(
          'Failed to search users: ${response.statusCode}, ${response.body}',
        );
        throw Exception('Failed to search users: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching users: $e');
      rethrow;
    }
  }

  Future<Friend?> deleteFriend(String friendId) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.delete(
        Uri.parse('$baseUrl/friends/$friendId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Friend.fromJson(json.decode(response.body));
      } else {
        print(
          'Failed to delete friend: ${response.statusCode}, ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error deleting friend: $e');
      return null;
    }
  }
}
