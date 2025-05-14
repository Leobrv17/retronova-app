// lib/services/friend_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/friend_model.dart';
import '../models/user_model.dart';

class FriendService {
  // Base API URL
  final String baseUrl = 'http://10.31.38.184:8000/friends';
  final String usersUrl = 'http://10.31.38.184:8000/users';

  // HTTP Client with client options
  final http.Client _client = http.Client();

  // Helper to get authentication token
  Future<String?> _getAuthToken() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Getting auth token for user: ${user.uid}');
        final token = await user.getIdToken();
        if (token != null && token.isNotEmpty) {
          print('Successfully obtained token');
          return token;
        } else {
          print('Empty token received from Firebase');
        }
      } else {
        print('No authenticated user found for token request');
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
    print('Auth token for API request: ${token != null ? 'Found (${token.substring(0, 10)}...)' : 'Not found'}');
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // Get all friends
  Future<List<Friend>> getAllFriends() async {
    try {
      final headers = await _getHeaders();
      print('Getting all friendships from: $baseUrl');
      final response = await _client.get(Uri.parse(baseUrl), headers: headers);

      print('Friends API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Friends API response body: ${response.body}');
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Friend.fromJson(json)).toList();
      } else if (response.statusCode == 307 || response.statusCode == 302 || response.statusCode == 301) {
        // Handle redirects manually
        final redirectUrl = response.headers['location'];
        print('Redirecting to: $redirectUrl');

        if (redirectUrl != null) {
          final redirectResponse = await _client.get(
            Uri.parse(redirectUrl),
            headers: headers,
          );

          if (redirectResponse.statusCode == 200) {
            final List<dynamic> data = json.decode(redirectResponse.body);
            return data.map((json) => Friend.fromJson(json)).toList();
          }
        }
      }

      print('Failed to load friends: ${response.statusCode}, ${response.body}');
      return [];
    } catch (e) {
      print('Error fetching friends: $e');
      // Return empty list instead of throwing to prevent app crashes
      return [];
    }
  }

  // Get friend by ID
  Future<Friend> getFriendById(String friendId) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.get(
        Uri.parse('$baseUrl/$friendId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Friend.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load friend: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching friend: $e');
      rethrow;
    }
  }

  // Create friend request
  Future<Friend> createFriendRequest(FriendRequest request) async {
    try {
      // First get the UUIDs from the database using firebase IDs
      final fromUser = await findUserByFirebaseId(request.userId);
      final toUser = await findUserByFirebaseId(request.targetUserId);

      if (fromUser == null || toUser == null) {
        throw Exception('Could not find one of the users by Firebase ID');
      }

      // Now create the request with proper UUIDs
      final requestBody = {
        'friend_from_id': fromUser.id,
        'friend_to_id': toUser.id,
        'accept': false,
        'decline': false,
        'delete': false,
      };

      print('Creating friend request with: $requestBody');

      final headers = await _getHeaders();

      // Create a custom http.Client to manually handle redirects
      var client = http.Client();

      // Make the initial request
      var uri = Uri.parse(baseUrl);
      var response = await client.post(
        uri,
        headers: headers,
        body: json.encode(requestBody),
      );

      // Handle redirects manually
      if (response.statusCode == 307 || response.statusCode == 302 || response.statusCode == 301) {
        final redirectUrl = response.headers['location'];
        print('Redirecting to: $redirectUrl');

        if (redirectUrl != null) {
          // Follow the redirect manually
          if (redirectUrl.startsWith('/')) {
            // Handle relative URLs
            var baseUri = Uri.parse(baseUrl);
            uri = Uri(
                scheme: baseUri.scheme,
                host: baseUri.host,
                port: baseUri.port,
                path: redirectUrl
            );
          } else {
            uri = Uri.parse(redirectUrl);
          }

          // Make the redirected request
          response = await client.post(
            uri,
            headers: headers,
            body: json.encode(requestBody),
          );
        }
      }

      // Process the final response
      if (response.statusCode == 200) {
        return Friend.fromJson(json.decode(response.body));
      } else if (response.statusCode == 400) {
        // If the API returns that the friendship already exists
        final errorMessage = json.decode(response.body)['detail'];
        throw Exception(errorMessage);
      } else {
        print('API Response: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create friend request: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating friend request: $e');
      rethrow;
    }
  }

  // Update friend
  Future<Friend> updateFriend(String friendId, Friend friend) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.put(
        Uri.parse('$baseUrl/$friendId'),
        headers: headers,
        body: json.encode(friend.toUpdateJson()),
      );

      if (response.statusCode == 200) {
        return Friend.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update friend: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating friend: $e');
      rethrow;
    }
  }

  // Accept friend request
  Future<Friend> acceptFriendRequest(String friendId) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.put(
        Uri.parse('$baseUrl/$friendId'),
        headers: headers,
        body: json.encode({
          'accept': true,
          'decline': false,
        }),
      );

      if (response.statusCode == 200) {
        return Friend.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to accept friend request: ${response.statusCode}');
      }
    } catch (e) {
      print('Error accepting friend request: $e');
      rethrow;
    }
  }

  // Decline friend request
  Future<Friend> declineFriendRequest(String friendId) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.put(
        Uri.parse('$baseUrl/$friendId'),
        headers: headers,
        body: json.encode({
          'accept': false,
          'decline': true,
        }),
      );

      if (response.statusCode == 200) {
        return Friend.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to decline friend request: ${response.statusCode}');
      }
    } catch (e) {
      print('Error declining friend request: $e');
      rethrow;
    }
  }

  // Delete friend (mark as deleted)
  Future<Friend> deleteFriend(String friendId) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.delete(
        Uri.parse('$baseUrl/$friendId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Friend.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to delete friend: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting friend: $e');
      rethrow;
    }
  }

  // Find user by username or ID to add as friend
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.get(
        Uri.parse('$usersUrl'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final users = data.map((json) => UserModel.fromApi(json)).toList();

        // Filter users locally if query provided
        if (query.isNotEmpty) {
          return users.where((user) =>
          (user.firstName?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
              (user.lastName?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
              (user.publiqueId?.toLowerCase().contains(query.toLowerCase()) ?? false)
          ).toList();
        }

        return users;
      } else {
        throw Exception('Failed to search users: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching users: $e');
      rethrow;
    }
  }

  // Find a user by their Firebase ID to get their system UUID
  Future<UserModel?> findUserByFirebaseId(String firebaseId) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.get(
        Uri.parse('$usersUrl?firebase_id=$firebaseId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return UserModel.fromApi(data[0]);
        }
      }
      return null;
    } catch (e) {
      print('Error finding user by Firebase ID: $e');
      return null;
    }
  }

  // Get incoming friend requests (where you are friendToId and accept is false)
  Future<List<Friend>> getIncomingFriendRequests(String userId) async {
    try {
      final allFriends = await getAllFriends();

      // Filter for incoming requests (where user is the target and not accepted/declined yet)
      return allFriends.where((friend) =>
      friend.friendToId == userId &&
          !friend.accept &&
          !friend.decline &&
          !friend.delete
      ).toList();
    } catch (e) {
      print('Error getting incoming friend requests: $e');
      rethrow;
    }
  }

  // Get outgoing friend requests (where you are friendFromId and accept is false)
  Future<List<Friend>> getOutgoingFriendRequests(String userId) async {
    try {
      final allFriends = await getAllFriends();

      // Filter for outgoing requests (where user is the sender and not accepted/declined yet)
      return allFriends.where((friend) =>
      friend.friendFromId == userId &&
          !friend.accept &&
          !friend.decline &&
          !friend.delete
      ).toList();
    } catch (e) {
      print('Error getting outgoing friend requests: $e');
      rethrow;
    }
  }

  // Get confirmed friends (accept is true)
  Future<List<Friend>> getConfirmedFriends(String userId) async {
    try {
      final allFriends = await getAllFriends();

      // Filter for confirmed friends (where accept is true and user is either sender or receiver)
      return allFriends.where((friend) =>
      (friend.friendFromId == userId || friend.friendToId == userId) &&
          friend.accept &&
          !friend.decline &&
          !friend.delete
      ).toList();
    } catch (e) {
      print('Error getting confirmed friends: $e');
      rethrow;
    }
  }
}