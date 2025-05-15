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
        title: const Text('Amis'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mes amis'),
            Tab(text: 'Demandes'),
            Tab(text: 'Ajouter'),
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
                    child: const Text('Réessayer'),
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
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentSystemId = friendProvider.currentUserSystemId;

    if (confirmedFriends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Vous n\'avez aucun ami pour le moment',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _tabController.animateTo(2); // Switch to Add Friends tab
              },
              child: const Text('Ajouter des amis'),
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
          // Obtenir le nom d'affichage ou l'ID public de l'ami (pas l'UUID)
          final friendDisplayName = friend.getOtherUserDisplayName(currentSystemId ?? '');

          // Obtenir la première lettre pour l'avatar
          final initial = friendDisplayName.isNotEmpty ? friendDisplayName[0].toUpperCase() : 'A';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade200,
                child: Text(initial),
              ),
              title: Text(friendDisplayName),
              subtitle: Text(
                  'Ami depuis ${DateTime.now().toString().substring(0, 10)}'
              ),
              trailing: IconButton(
                icon: const Icon(Icons.person_remove),
                onPressed: () => _showRemoveFriendDialog(context, friend, friendProvider),
                tooltip: 'Supprimer cet ami',
              ),
              onTap: () {
                // Afficher le profil de l'ami ou démarrer une conversation
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Voir le profil de $friendDisplayName'))
                );
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
    final currentSystemId = friendProvider.currentUserSystemId;

    print("Building requests tab - incoming: ${incomingRequests.length}, outgoing: ${outgoingRequests.length}");

    if (incomingRequests.isEmpty && outgoingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mail_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucune demande d\'ami en attente',
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
          // SECTION DES DEMANDES REÇUES
          if (incomingRequests.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Demandes reçues',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...incomingRequests.map((friend) {
              print("Rendering incoming request: ${friend.id}");
              return _buildIncomingRequestItem(
                friend,
                friendProvider,
                currentSystemId ?? '',
              );
            }).toList(),
          ],

          // SECTION DES DEMANDES ENVOYÉES
          if (outgoingRequests.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Demandes envoyées',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...outgoingRequests.map((friend) {
              print("Rendering outgoing request: ${friend.id}");
              return _buildOutgoingRequestItem(
                friend,
                friendProvider,
                currentSystemId ?? '',
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildIncomingRequestItem(Friend request, FriendProvider friendProvider, String currentSystemId) {
    // Obtenir le nom d'affichage ou l'ID public du demandeur
    final senderName = request.friendFromName ?? request.friendFromPublicId ?? "Utilisateur ${request.friendFromId.substring(0, 8)}";

    // Obtenir la première lettre pour l'avatar
    final initial = senderName.isNotEmpty ? senderName[0].toUpperCase() : 'A';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade200,
          child: Text(initial),
        ),
        title: Text('Demande de: $senderName'),
        subtitle: const Text('Veut être votre ami'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton d'acceptation
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () {
                print('Accepting friend request ID: ${request.id}');
                friendProvider.acceptFriendRequest(request.id);
                // Afficher une confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Demande d\'ami de $senderName acceptée')),
                );
              },
              tooltip: 'Accepter',
            ),
            // Bouton de refus
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                print('Declining friend request ID: ${request.id}');
                friendProvider.declineFriendRequest(request.id);
                // Afficher une confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Demande d\'ami de $senderName refusée')),
                );
              },
              tooltip: 'Refuser',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutgoingRequestItem(Friend request, FriendProvider friendProvider, String currentSystemId) {
    // Obtenir le nom d'affichage ou l'ID public du destinataire
    final recipientName = request.friendToName ?? request.friendToPublicId ?? "Utilisateur ${request.friendToId.substring(0, 8)}";

    // Obtenir la première lettre pour l'avatar
    final initial = recipientName.isNotEmpty ? recipientName[0].toUpperCase() : 'A';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade200,
          child: Text(initial),
        ),
        title: Text('Demande à: $recipientName'),
        subtitle: const Text('En attente de confirmation'),
        trailing: IconButton(
          icon: const Icon(Icons.cancel, color: Colors.grey),
          onPressed: () => friendProvider.cancelFriendRequest(request.id),
          tooltip: 'Annuler la demande',
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
                    labelText: 'Rechercher des utilisateurs',
                    hintText: 'Entrez un nom ou un ID public',
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
                child: const Text('Rechercher'),
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
                // Afficher le nom complet ou l'ID public
                final displayName =
                '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim().isNotEmpty
                    ? '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim()
                    : user.publiqueId ?? 'Utilisateur';

                // Obtenir l'initiale pour l'avatar
                final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

                // Ne pas afficher l'utilisateur actuel
                final currentUser = FirebaseAuth.instance.currentUser;
                if (user.firebaseId == currentUser?.uid) {
                  // Si c'est le dernier élément et qu'il s'agit de l'utilisateur actuel
                  if (index == _searchResults.length - 1 && _searchResults.length == 1) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Aucun utilisateur trouvé sauf vous-même'),
                      ),
                    );
                  }
                  return const SizedBox.shrink(); // Ne pas afficher l'utilisateur actuel
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade200,
                      child: Text(initial),
                    ),
                    title: Text(displayName),
                    subtitle: Text('ID: ${user.publiqueId ?? "Non défini"}'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        try {
                          // Envoyer une demande d'ami en utilisant l'ID public
                          if (user.publiqueId != null) {
                            friendProvider.sendFriendRequestByPublicId(user.publiqueId!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Demande d\'ami envoyée à $displayName')),
                            );
                          } else {
                            throw Exception("L'ID public de cet utilisateur n'est pas défini");
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('Ajouter'),
                    ),
                    onTap: () {
                      // Voir le profil de l'utilisateur
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Voir le profil de $displayName'))
                      );
                    },
                  ),
                );
              },
            ),
          )
        else if (_searchController.text.isNotEmpty)
            const Expanded(
              child: Center(
                child: Text('Aucun utilisateur trouvé'),
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
                      'Recherchez des utilisateurs pour les ajouter comme amis',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Vous pouvez rechercher par nom ou ID public',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        _searchController.text = ''; // Vider le champ
                        _searchUsers(); // Rechercher tous les utilisateurs
                      },
                      child: const Text('Afficher tous les utilisateurs'),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  void _showRemoveFriendDialog(BuildContext context, Friend friend, FriendProvider friendProvider) {
    final currentSystemId = friendProvider.currentUserSystemId ?? '';
    final friendName = friend.getOtherUserDisplayName(currentSystemId);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer un ami'),
          content: Text('Êtes-vous sûr de vouloir supprimer $friendName de votre liste d\'amis ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Supprimer'),
              onPressed: () {
                friendProvider.removeFriend(friend.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$friendName a été retiré de vos amis')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}