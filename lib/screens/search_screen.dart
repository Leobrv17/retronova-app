// screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _recentSearches = [];
  List<Map<String, dynamic>> _suggestedItems = [];
  String _searchCategory = 'Tout'; // Catégorie de recherche sélectionnée
  final List<String> _categories = ['Tout', 'Jeux', 'Utilisateurs', 'Produits'];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadSuggestedItems();
  }

  Future<void> _loadRecentSearches() async {
    // Normalement, vous les chargeriez depuis Firestore pour l'utilisateur actuel
    // Pour notre démo, nous utilisons des données fictives
    setState(() {
      _recentSearches = [
        'Space Adventure',
        'Pack VIP',
        'Puzzle Master',
      ];
    });
  }

  Future<void> _loadSuggestedItems() async {
    // Normalement, vous chargeriez les éléments suggérés depuis Firestore
    // Pour notre démo, nous utilisons des données fictives
    setState(() {
      _suggestedItems = [
        {
          'id': 'game1',
          'title': 'Space Adventure',
          'type': 'Jeu',
          'icon': Icons.rocket,
          'color': Colors.indigo,
        },
        {
          'id': 'prod1',
          'title': 'Pack de démarrage',
          'type': 'Produit',
          'icon': Icons.card_giftcard,
          'color': Colors.blue,
        },
        {
          'id': 'user1',
          'title': 'JoueurPro1',
          'type': 'Utilisateur',
          'icon': Icons.person,
          'color': Colors.green,
        },
        {
          'id': 'game2',
          'title': 'Racing Legends',
          'type': 'Jeu',
          'icon': Icons.directions_car,
          'color': Colors.red,
        },
      ];
    });
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Simuler une recherche Firestore
      // Dans une vraie application, vous interrogeriez Firestore ici
      await Future.delayed(const Duration(milliseconds: 500));

      // Filtrer les éléments suggérés pour simuler une recherche
      final results = _suggestedItems.where((item) {
        final matchesQuery = item['title'].toString().toLowerCase().contains(query.toLowerCase());
        final matchesCategory = _searchCategory == 'Tout' ||
            item['type'] == _searchCategory ||
            (_searchCategory == 'Jeux' && item['type'] == 'Jeu');
        return matchesQuery && matchesCategory;
      }).toList();

      // Ajouter des résultats supplémentaires pour la démo
      if (query.length > 2) {
        results.add({
          'id': 'result1',
          'title': 'Résultat pour "$query"',
          'type': 'Jeu',
          'icon': Icons.gamepad,
          'color': Colors.purple,
        });

        results.add({
          'id': 'result2',
          'title': 'Pack $query Premium',
          'type': 'Produit',
          'icon': Icons.shopping_bag,
          'color': Colors.orange,
        });
      }

      setState(() {
        _searchResults = results;
        isLoading = false;
      });

      // Sauvegarder la recherche dans l'historique (normalement dans Firestore)
      if (query.length > 2 && !_recentSearches.contains(query)) {
        setState(() {
          _recentSearches.insert(0, query);
          if (_recentSearches.length > 5) {
            _recentSearches.removeLast();
          }
        });
      }
    } catch (e) {
      print('Erreur lors de la recherche: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche'),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: _performSearch,
                ),
                const SizedBox(height: 8),

                // Filtres de catégorie
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _searchCategory == category,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _searchCategory = category;
                              });
                              // Refaire la recherche avec la nouvelle catégorie
                              _performSearch(_searchController.text);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Contenu principal
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isNotEmpty
                ? _buildSearchResults()
                : _searchController.text.isEmpty
                ? _buildInitialContent()
                : const Center(
              child: Text('Aucun résultat trouvé'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: item['color'],
              child: Icon(
                item['icon'],
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(item['title']),
            subtitle: Text(item['type']),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {
                // Naviguer vers l'élément
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Ouverture de ${item['title']}...")),
                );
              },
            ),
            onTap: () {
              // Naviguer vers l'élément
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Ouverture de ${item['title']}...")),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInitialContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recherches récentes
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recherches récentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _recentSearches = [];
                    });
                  },
                  child: const Text('Effacer'),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: _recentSearches.map((search) {
                return Chip(
                  label: Text(search),
                  onDeleted: () {
                    setState(() {
                      _recentSearches.remove(search);
                    });
                  },
                  backgroundColor: Colors.grey[200],
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Suggestions populaires
          const Text(
            'Populaire en ce moment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _suggestedItems.length,
            itemBuilder: (context, index) {
              final item = _suggestedItems[index];
              return Card(
                color: item['color'],
                child: InkWell(
                  onTap: () {
                    _searchController.text = item['title'];
                    _performSearch(item['title']);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.3),
                          child: Icon(
                            item['icon'],
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Catégories de recherche
          const Text(
            'Parcourir par catégorie',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCategoryButton(Icons.sports_esports, 'Jeux', Colors.indigo),
              _buildCategoryButton(Icons.shopping_bag, 'Produits', Colors.orange),
              _buildCategoryButton(Icons.person, 'Utilisateurs', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {
        setState(() {
          _searchCategory = label;
        });
        if (_searchController.text.isNotEmpty) {
          _performSearch(_searchController.text);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}