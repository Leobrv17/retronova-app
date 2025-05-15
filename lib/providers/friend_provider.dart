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
    if (_currentUserId == null) {
      print("Cannot load friend data - missing Firebase user ID: $_currentUserId");
      _setError("Impossible de charger les données d'amis - utilisateur non identifié");
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // Récupérer les dernières informations de l'utilisateur pour éviter les problèmes de cache
      final userModel = await _friendService.findUserByFirebaseId(_currentUserId!);
      if (userModel != null) {
        _currentUserSystemId = userModel.id;
        _currentUserPublicId = userModel.publiqueId;
        print("Updated system UUID for current user: $_currentUserSystemId");
        print("Updated public ID for current user: $_currentUserPublicId");
      } else {
        print("Could not find system user with Firebase ID: $_currentUserId");
        _setError("Utilisateur non trouvé dans le système. Veuillez vous déconnecter et vous reconnecter.");
        _setLoading(false);
        return;
      }

      // Vérifier à nouveau que l'ID système est disponible
      if (_currentUserSystemId == null) {
        print("Cannot load friend data - missing system ID after refresh");
        _setError("Impossible de charger les données d'amis - ID système manquant");
        _setLoading(false);
        return;
      }

      print("Loading all friend data for user ID: $_currentUserSystemId");

      // Get all friendships
      final allFriends = await _friendService.getAllFriends();
      print("Found ${allFriends.length} total friendships");

      // Debug: afficher toutes les amitiés pour vérification
      for (var friend in allFriends) {
        print("Friendship: ID=${friend.id}, From=${friend.friendFromId}, To=${friend.friendToId}, Accept=${friend.accept}, Decline=${friend.decline}, Delete=${friend.delete}");
      }

      // Filter friendships using the system UUID
      _incomingRequests = allFriends.where((friend) {
        print("from : ${friend.friendFromId}, to ${friend.friendToId}, current ${_currentUserSystemId}");
        bool isIncoming = friend.friendToId == _currentUserSystemId &&
            !friend.accept &&
            !friend.decline &&
            !friend.delete;
        if (isIncoming) {
          print("Found incoming request: ${friend.id} from ${friend.friendFromId}");
        }
        return isIncoming;
      }).toList();

      _outgoingRequests = allFriends.where((friend) {
        bool isOutgoing = friend.friendFromId == _currentUserSystemId &&
            !friend.accept &&
            !friend.decline &&
            !friend.delete;
        if (isOutgoing) {
          print("Found outgoing request: ${friend.id} to ${friend.friendToId}");
        }
        return isOutgoing;
      }).toList();

      _confirmedFriends = allFriends.where((friend) {
        bool isConfirmed = (friend.friendFromId == _currentUserSystemId ||
            friend.friendToId == _currentUserSystemId) &&
            friend.accept &&
            !friend.decline &&
            !friend.delete;
        if (isConfirmed) {
          print("Found confirmed friend: ${friend.id}");
        }
        return isConfirmed;
      }).toList();

      print("Incoming requests: ${_incomingRequests.length}");
      print("Outgoing requests: ${_outgoingRequests.length}");
      print("Confirmed friends: ${_confirmedFriends.length}");

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print("Error loading friend data: $e");
      _setError('Erreur lors du chargement des amis: $e');
      _setLoading(false);
      notifyListeners();
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

        // Reload all friend data to ensure consistency
        await loadAllFriendData();
      } else {
        print('Provider: Friend request not found or could not be accepted');
        _setError('Demande d\'ami introuvable ou ne peut pas être acceptée');
        _setLoading(false);
        notifyListeners();
      }
    } catch (e) {
      print('Provider: Error accepting friend request: $e');
      _setError('Échec de l\'acceptation de la demande d\'ami: $e');
      _setLoading(false);
      notifyListeners();
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

        // Reload all friend data to ensure consistency
        await loadAllFriendData();
      } else {
        print('Provider: Friend request not found or could not be declined');
        _setError('Demande d\'ami introuvable ou ne peut pas être refusée');
        _setLoading(false);
        notifyListeners();
      }
    } catch (e) {
      print('Provider: Error declining friend request: $e');
      _setError('Échec du refus de la demande d\'ami: $e');
      _setLoading(false);
      notifyListeners();
    }
  }

  // Cancel outgoing friend request
  Future<void> cancelFriendRequest(String friendId) async {
    _setLoading(true);
    _clearError();

    try {
      await _friendService.deleteFriend(friendId);

      // Reload all friend data to ensure consistency
      await loadAllFriendData();
    } catch (e) {
      _setError('Failed to cancel friend request: $e');
      _setLoading(false);
      notifyListeners();
    }
  }

  // Remove friend
  Future<void> removeFriend(String friendId) async {
    _setLoading(true);
    _clearError();

    try {
      await _friendService.deleteFriend(friendId);

      // Reload all friend data to ensure consistency
      await loadAllFriendData();
    } catch (e) {
      _setError('Failed to remove friend: $e');
      _setLoading(false);
      notifyListeners();
    }
  }

  // Send friend request by public ID
  Future<void> sendFriendRequestByPublicId(String targetPublicId) async {
    _setLoading(true);
    _clearError();

    try {
      final newFriend = await _friendService.createFriendRequestByPublicId(targetPublicId);
      if (newFriend != null) {
        // Reload all friend data to ensure consistency
        await loadAllFriendData();
      } else {
        _setLoading(false);
        _setError('Erreur lors de l\'envoi de la demande d\'ami');
        notifyListeners();
      }
    } catch (e) {
      _setError('Échec de l\'envoi de la demande d\'ami: $e');
      _setLoading(false);
      notifyListeners();
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
      _setLoading(false);
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