// screens/arcade_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class ArcadeScreen extends StatefulWidget {
  const ArcadeScreen({Key? key}) : super(key: key);

  @override
  _ArcadeScreenState createState() => _ArcadeScreenState();
}

class _ArcadeScreenState extends State<ArcadeScreen> {
  String? pseudo;
  bool isLoading = true;
  List<Map<String, dynamic>> games = [];
  int tickets = 42; // Nombre de tickets (à remplacer par les données de votre API)

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadGames();
  }

  Future<void> _loadUserData() async {
    User? user = Provider.of<User?>(context, listen: false);

    if (user == null) {
      setState(() {
        pseudo = 'Joueur';
        isLoading = false;
      });
      return;
    }

    // Utiliser le displayName de Firebase Auth
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      setState(() {
        pseudo = user.displayName;
        isLoading = false;
      });
      print('Arcade: Pseudo chargé depuis Auth: $pseudo');
    } else {
      setState(() {
        pseudo = 'Joueur';
        isLoading = false;
      });
      print('Arcade: Pas de displayName, utilisation du nom par défaut');
    }
  }

  Future<void> _loadGames() async {
    // Simuler un chargement
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      games = [
        {
          'title': 'Space Adventure',
          'description': 'Explorez l\'univers et combattez des aliens',
          'image': 'space',
          'color': Colors.indigo,
          'icon': Icons.rocket,
          'tickets': 5,
        },
        {
          'title': 'Puzzle Master',
          'description': 'Résolvez des énigmes complexes',
          'image': 'puzzle',
          'color': Colors.orange,
          'icon': Icons.extension,
          'tickets': 3,
        },
        {
          'title': 'Racing Legends',
          'description': 'Courses à haute vitesse',
          'image': 'racing',
          'color': Colors.red,
          'icon': Icons.directions_car,
          'tickets': 4,
        },
        {
          'title': 'Treasure Hunt',
          'description': 'Trouvez des trésors cachés',
          'image': 'treasure',
          'color': Colors.amber,
          'icon': Icons.search,
          'tickets': 2,
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arcade'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Nouvelle en-tête avec DisplayName et Tickets
          _buildHeader(),

          // Titre de section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jeux populaires',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Voir tout',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Liste de jeux
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: games.length,
              itemBuilder: (context, index) {
                final game = games[index];
                final gameTickets = game['tickets'] as int; // Correction ici

                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      _showGameDetailsDialog(context, game);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        // Image/icône du jeu
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: game['color'],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                          child: Icon(
                            game['icon'],
                            size: 50,
                            color: Colors.white,
                          ),
                        ),

                        // Informations du jeu
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  game['title'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  game['description'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Prix en tickets
                                Row(
                                  children: [
                                    const Icon(Icons.confirmation_number,
                                        size: 16,
                                        color: Colors.green
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$gameTickets tickets',
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Bouton de jeu
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: IconButton(
                            icon: const Icon(Icons.play_circle_filled, size: 40, color: Colors.blue),
                            onPressed: () {
                              // Vérifier si l'utilisateur a assez de tickets
                              if (tickets >= gameTickets) {
                                // Lancer le jeu et déduire des tickets
                                setState(() {
                                  tickets -= gameTickets; // Correction appliquée ici
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Lancement de ${game['title']}... $gameTickets tickets utilisés")),
                                );
                              } else {
                                // Pas assez de tickets
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Pas assez de tickets! Achetez-en plus dans la boutique."),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // DisplayName et avatar
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  pseudo != null && pseudo!.isNotEmpty
                      ? pseudo![0].toUpperCase()
                      : 'J',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                pseudo ?? 'Joueur',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          // Tickets
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.confirmation_number,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '$tickets tickets',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGameDetailsDialog(BuildContext context, Map<String, dynamic> game) {
    final gameTickets = game['tickets'] as int; // Correction ici

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(game['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: game['color'],
                shape: BoxShape.circle,
              ),
              child: Icon(
                game['icon'],
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(game['description']),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.confirmation_number, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '$gameTickets tickets requis',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tickets >= gameTickets
                  ? 'Vous avez assez de tickets pour jouer!'
                  : 'Vous avez besoin de ${gameTickets - tickets} tickets supplémentaires',
              style: TextStyle(
                color: tickets >= gameTickets ? Colors.green : Colors.red,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: tickets >= gameTickets ? () {
              // Déduire les tickets et lancer le jeu
              setState(() {
                tickets -= gameTickets; // Correction appliquée ici
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Lancement de ${game['title']}... $gameTickets tickets utilisés")),
              );
            } : null, // Désactiver si pas assez de tickets
            child: const Text('Jouer'),
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}