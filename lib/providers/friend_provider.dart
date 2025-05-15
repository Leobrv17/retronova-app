// lib/providers/friend_provider.dart - Version complète
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend_model.dart';
import '../models/user_model.dart';
import '../services/friend_service.dart';

class FriendProvider with ChangeNotifier {
  final FriendService _friendService = FriendService();

  // User info
  String? _currentUserId; // Firebase ID
  String? _currentUserSystemId; // System UUID
  String? _currentUserPublicId; // Public ID

  // Friends lists
  List<Friend> _incomingRequests = [];
  List<Friend> _outgoingRequests = [];
  List<Friend> _confirmedFriends = [];

  // Loading states
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Friend> get incomingRequests => _incomingRequests;
  List<Friend> get outgoingRequests => _outgoingRequests;
  List<Friend> get confirmedFriends => _confirmedFriends;
  String? get currentUserSystemId => _currentUserSystemId;
  String? get currentUserPublicId => _currentUserPublicId;

  // Initialize provider
  Future<void> initialize() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _currentUserId = currentUser.uid;
      print("FriendProvider initialized with Firebase user ID: $_currentUserId");

      // Réinitialiser les états d'erreur
      _clearError();
      _setLoading(true);

      try {
        // Get the system UUID for the current user
        final userModel = await _friendService.findUserByFirebaseId(_currentUserId!);
        if (userModel != null) {
          _currentUserSystemId = userModel.id;
          _currentUserPublicId = userModel.publiqueId;
          print("Found system UUID for current user: $_currentUserSystemId");
          print("Found public ID for current user: $_currentUserPublicId");

          // Une fois que nous avons l'identifiant système, charger les données d'amis
          await loadAllFriendData();
        } else {
          print("Could not find system user with Firebase ID: $_currentUserId");
          _setError("Utilisateur non trouvé dans le système. Veuillez vous déconnecter et vous reconnecter.");
        }
      } catch (e) {
        print("Error during provider initialization: $e");
        _setError('Erreur lors de l\'initialisation: $e');
      } finally {
        _setLoading(false);
      }
    } else {
      print("FriendProvider could not initialize - no current user");
      _setError("Aucun utilisateur connecté");
      _setLoading(false);
    }
  }

  // Load all friend data
  Future<void> loadAllFriendData() async {
    if (_currentUserId == null || _currentUserSystemId == null) {
      print("Cannot load friend data - missing user IDs. Firebase ID: $_currentUserId, System ID: $_currentUserSystemId");
      _setError("Impossible de charger les données d'amis - utilisateur non identifié");
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      print("Loading all friend data for user ID: $_currentUserSystemId");

      // Get all friendships
      final allFriends = await _friendService.getAllFriends();
      print("Found ${allFriends.length} total friendships");

      // Filter friendships using the system UUID
      _incomingRequests = allFriends.where((friend) =>
      friend.friendToId == _currentUserSystemId &&
          !friend.accept &&
          !friend.decline &&
          !friend.delete
      ).toList();

      _outgoingRequests = allFriends.where((friend) =>
      friend.friendFromId == _currentUserSystemId &&
          !friend.accept &&
          !friend.decline &&
          !friend.delete
      ).toList();

      _confirmedFriends = allFriends.where((friend) =>
      (friend.friendFromId == _currentUserSystemId || friend.friendToId == _currentUserSystemId) &&
          friend.accept &&
          !friend.decline &&
          !friend.delete
      ).toList();

      print("Incoming requests: ${_incomingRequests.length}");
      print("Outgoing requests: ${_outgoingRequests.length}");
      print("Confirmed friends: ${_confirmedFriends.length}");

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print("Error loading friend data: $e");
      _setError('Erreur lors du chargement des amis: $e');
    }
  }

  // Send friend request by public ID
  Future<void> sendFriendRequestByPublicId(String targetPublicId) async {
    _setLoading(true);
    _clearError();

    try {
      final newFriend = await _friendService.createFriendRequestByPublicId(targetPublicId);
      if (newFriend != null) {
        _outgoingRequests.add(newFriend);
      }
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Échec de l\'envoi de la demande d\'ami: $e');
    }
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String friendId) async {
    _setLoading(true);
    _clearError();

    try {
      print('Provider: Attempting to accept friend request: $friendId');
      final updatedFriend = await _friendService.acceptFriendRequest(friendId);

      if (updatedFriend != null) {
        print('Provider: Friend request accepted successfully');

        // Remove from incoming requests
        print('Provider: Removing request from incoming list');
        _incomingRequests.removeWhere((friend) => friend.id == friendId);

        // Add to confirmed friends
        print('Provider: Adding to confirmed friends list');
        _confirmedFriends.add(updatedFriend);

        print('Provider: Notifying listeners of changes');
        _setLoading(false);
        notifyListeners();
      } else {
        print('Provider: Friend request not found or could not be accepted');
        _setError('Demande d\'ami introuvable ou ne peut pas être acceptée');
      }
    } catch (e) {
      print('Provider: Error accepting friend request: $e');
      _setError('Échec de l\'acceptation de la demande d\'ami: $e');
    }
  }

  // Decline friend request
  Future<void> declineFriendRequest(String friendId) async {
    _setLoading(true);
    _clearError();

    try {
      print('Provider: Attempting to decline friend request: $friendId');
      final updatedFriend = await _friendService.declineFriendRequest(friendId);

      if (updatedFriend != null) {
        print('Provider: Friend request declined successfully');

        // Remove from incoming requests
        print('Provider: Removing request from incoming list');
        _incomingRequests.removeWhere((friend) => friend.id == friendId);

        print('Provider: Notifying listeners of changes');
        _setLoading(false);
        notifyListeners();
      } else {
        print('Provider: Friend request not found or could not be declined');
        _setError('Demande d\'ami introuvable ou ne peut pas être refusée');
      }
    } catch (e) {
      print('Provider: Error declining friend request: $e');
      _setError('Échec du refus de la demande d\'ami: $e');
    }
  }

  // Cancel outgoing friend request
  Future<void> cancelFriendRequest(String friendId) async {
    _setLoading(true);
    _clearError();

    try {
      await _friendService.deleteFriend(friendId);

      // Remove from outgoing requests
      _outgoingRequests.removeWhere((friend) => friend.id == friendId);

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to cancel friend request: $e');
    }
  }

  // Remove friend
  Future<void> removeFriend(String friendId) async {
    _setLoading(true);
    _clearError();

    try {
      await _friendService.deleteFriend(friendId);

      // Remove from confirmed friends
      _confirmedFriends.removeWhere((friend) => friend.id == friendId);

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove friend: $e');
    }
  }

  // Search users to add as friends
  Future<List<UserModel>> searchUsers(String query) async {
    _setLoading(true);
    _clearError();

    try {
      final results = await _friendService.searchUsers(query);
      _setLoading(false);
      return results;
    } catch (e) {
      _setError('Failed to search users: $e');
      return [];
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String errorMessage) {
    _error = errorMessage;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}