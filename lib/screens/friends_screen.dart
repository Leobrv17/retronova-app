// lib/screens/friends_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friend_provider.dart';
import '../models/friend_model.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize the friend provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("Friends Screen initialized - loading friend data");
      Provider.of<FriendProvider>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await Provider.of<FriendProvider>(context, listen: false)
          .searchUsers(_searchController.text.trim());

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching users: $e')),
      );
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Requests'),
            Tab(text: 'Add'),
          ],
        ),
      ),
      body: Consumer<FriendProvider>(
        builder: (context, friendProvider, child) {
          if (friendProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (friendProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${friendProvider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => friendProvider.loadAllFriendData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildFriendsTab(friendProvider),
              _buildRequestsTab(friendProvider),
              _buildAddFriendsTab(friendProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFriendsTab(FriendProvider friendProvider) {
    final confirmedFriends = friendProvider.confirmedFriends;

    if (confirmedFriends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'You don\'t have any friends yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _tabController.animateTo(2); // Switch to Add Friends tab
              },
              child: const Text('Add Friends'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => friendProvider.loadAllFriendData(),
      child: ListView.builder(
        itemCount: confirmedFriends.length,
        itemBuilder: (context, index) {
          final friend = confirmedFriends[index];
          // Determine if the current user is friend_from or friend_to
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          final isCurrentUserSender = friend.friendFromId == currentUserId;
          final friendUserId = isCurrentUserSender ? friend.friendToId : friend.friendFromId;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade200,
                child: Text(friendUserId.substring(0, 1).toUpperCase()),
              ),
              title: Text('Friend $friendUserId'),
              subtitle: Text('Since ${DateTime.now().toString().substring(0, 10)}'),
              trailing: IconButton(
                icon: const Icon(Icons.person_remove),
                onPressed: () => _showRemoveFriendDialog(context, friend, friendProvider),
                tooltip: 'Remove friend',
              ),
              onTap: () {
                // View friend profile or start chat
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestsTab(FriendProvider friendProvider) {
    final incomingRequests = friendProvider.incomingRequests;
    final outgoingRequests = friendProvider.outgoingRequests;

    if (incomingRequests.isEmpty && outgoingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mail_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No pending friend requests',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => friendProvider.loadAllFriendData(),
      child: ListView(
        children: [
          if (incomingRequests.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Incoming Requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...incomingRequests.map((request) => _buildIncomingRequestItem(request, friendProvider)),
          ],

          if (outgoingRequests.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Outgoing Requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...outgoingRequests.map((request) => _buildOutgoingRequestItem(request, friendProvider)),
          ],
        ],
      ),
    );
  }

  Widget _buildIncomingRequestItem(Friend request, FriendProvider friendProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade200,
          child: Text(request.friendFromId.substring(0, 1).toUpperCase()),
        ),
        title: Text('Request from: ${request.friendFromId.substring(0, 8)}...'),
        subtitle: const Text('Wants to be your friend'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => friendProvider.acceptFriendRequest(request.id),
              tooltip: 'Accept',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => friendProvider.declineFriendRequest(request.id),
              tooltip: 'Decline',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutgoingRequestItem(Friend request, FriendProvider friendProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade200,
          child: Text(request.friendToId.substring(0, 1).toUpperCase()),
        ),
        title: Text('Request to: ${request.friendToId.substring(0, 8)}...'),
        subtitle: const Text('Pending acceptance'),
        trailing: IconButton(
          icon: const Icon(Icons.cancel, color: Colors.grey),
          onPressed: () => friendProvider.cancelFriendRequest(request.id),
          tooltip: 'Cancel request',
        ),
      ),
    );
  }

  Widget _buildAddFriendsTab(FriendProvider friendProvider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search users',
                    hintText: 'Enter username or ID',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                        });
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isEmpty) {
                      setState(() {
                        _searchResults = [];
                      });
                    }
                  },
                  onSubmitted: (_) => _searchUsers(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _searchUsers,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Search'),
              ),
            ],
          ),
        ),

        if (_isSearching)
          const Center(child: CircularProgressIndicator())
        else if (_searchResults.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                // Get current user ID
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                // Skip rendering if this is the current user
                if (user.firebaseId == currentUserId) {
                  // If this is the last item and it's the current user, show a message if no other results
                  if (index == _searchResults.length - 1 && _searchResults.length == 1) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No users found except yourself'),
                      ),
                    );
                  }
                  return const SizedBox.shrink(); // Don't show current user
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade200,
                      child: Text(user.firstName?.substring(0, 1).toUpperCase() ?? 'U'),
                    ),
                    title: Text('${user.firstName} ${user.lastName}'),
                    subtitle: Text('ID: ${user.publiqueId}'),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        try {
                          await friendProvider.sendFriendRequest(user.firebaseId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Friend request sent to ${user.firstName}')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('Add Friend'),
                    ),
                    onTap: () {
                      // View user profile
                    },
                  ),
                );
              },
            ),
          )
        else if (_searchController.text.isNotEmpty)
            const Expanded(
              child: Center(
                child: Text('No users found'),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.search,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Search for users to add them as friends',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'You can search by username or public ID',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        _searchController.text = ''; // Example search term
                        _searchUsers();
                      },
                      child: const Text('Show All Users'),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  void _showRemoveFriendDialog(BuildContext context, Friend friend, FriendProvider friendProvider) {
    // Determine if the current user is friend_from or friend_to
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isCurrentUserSender = friend.friendFromId == currentUserId;
    final friendUserId = isCurrentUserSender ? friend.friendToId : friend.friendFromId;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Friend'),
          content: Text('Are you sure you want to remove $friendUserId from your friends list?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Remove'),
              onPressed: () {
                friendProvider.removeFriend(friend.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Friend removed')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}