// lib/providers/friend_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend_model.dart';
import '../models/user_model.dart';
import '../services/friend_service.dart';

class FriendProvider with ChangeNotifier {
  final FriendService _friendService = FriendService();

  // User info
  String? _currentUserId;

  // Friends lists
  List<Friend> _incomingRequests = [];
  List<Friend> _outgoingRequests = [];
  List<Friend> _confirmedFriends = [];
  Map<String, UserModel> _userCache = {};

  // Loading states
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Friend> get incomingRequests => _incomingRequests;
  List<Friend> get outgoingRequests => _outgoingRequests;
  List<Friend> get confirmedFriends => _confirmedFriends;
  Map<String, UserModel> get userCache => _userCache;

  // Initialize provider
  Future<void> initialize() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _currentUserId = currentUser.uid;
      await loadAllFriendData();
    }
  }

  // Load all friend data
  Future<void> loadAllFriendData() async {
    if (_currentUserId == null) return;

    _setLoading(true);
    _clearError();

    try {
      _incomingRequests = await _friendService.getIncomingFriendRequests(_currentUserId!);
      _outgoingRequests = await _friendService.getOutgoingFriendRequests(_currentUserId!);
      _confirmedFriends = await _friendService.getConfirmedFriends(_currentUserId!);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load friends: $e');
    }
  }

  // Send friend request
  Future<void> sendFriendRequest(String targetFirebaseId) async {
    if (_currentUserId == null) return;

    _setLoading(true);
    _clearError();

    try {
      final request = FriendRequest(
        userId: _currentUserId!,
        targetUserId: targetFirebaseId,
      );

      final newFriend = await _friendService.createFriendRequest(request);
      _outgoingRequests.add(newFriend);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to send friend request: $e');
    }
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String friendId) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedFriend = await _friendService.acceptFriendRequest(friendId);

      // Remove from incoming requests
      _incomingRequests.removeWhere((friend) => friend.id == friendId);

      // Add to confirmed friends
      _confirmedFriends.add(updatedFriend);

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to accept friend request: $e');
    }
  }

  // Decline friend request
  Future<void> declineFriendRequest(String friendId) async {
    _setLoading(true);
    _clearError();

    try {
      await _friendService.declineFriendRequest(friendId);

      // Remove from incoming requests
      _incomingRequests.removeWhere((friend) => friend.id == friendId);

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to decline friend request: $e');
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