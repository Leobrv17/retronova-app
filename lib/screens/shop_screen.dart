// screens/shop_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  String? pseudo;
  int coins = 0;
  List<Map<String, dynamic>> products = [];
  String selectedCategory = 'Tous';
  List<String> categories = ['Tous', 'Populaire', 'Nouveautés', 'Promotions'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProducts();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = Provider.of<User?>(context, listen: false);
      if (user != null) {
        // Vérifier d'abord s'il y a un displayName dans Firebase Auth
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          setState(() {
            pseudo = user.displayName;
          });
          print('Shop: Pseudo chargé depuis Auth: $pseudo');
        }

        // Chercher dans Firestore pour avoir toutes les données
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            // Si le pseudo n'a pas déjà été défini depuis Auth
            if (pseudo == null) {
              pseudo = data['pseudo'];
            }
            coins = data['coins'] ?? 0;
            isLoading = false;
          });
          print('Shop: Données chargées depuis Firestore: $pseudo, $coins pièces');
        } else {
          print('Shop: Document utilisateur non trouvé');
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    // Normalement, vous chargeriez les produits depuis Firestore
    // Ici, nous utilisons des données fictives
    setState(() {
      products = [
        {
          'id': 'prod1',
          'name': 'Pack de démarrage',
          'description': '1000 pièces + bonus exclusifs',
          'price': 9.99,
          'image': 'pack',
          'color': Colors.blue,
          'icon': Icons.card_giftcard,
          'category': 'Populaire',
          'isPromo': false,
        },
        {
          'id': 'prod2',
          'name': 'Pack VIP',
          'description': '5000 pièces + skin premium',
          'price': 24.99,
          'image': 'vip',
          'color': Colors.purple,
          'icon': Icons.star,
          'category': 'Populaire',
          'isPromo': false,
        },
        {
          'id': 'prod3',
          'name': 'Skin Galaxy',
          'description': 'Personnalisez votre avatar',
          'price': 4.99,
          'image': 'skin',
          'color': Colors.indigo,
          'icon': Icons.person,
          'category': 'Nouveautés',
          'isPromo': false,
        },
        {
          'id': 'prod4',
          'name': 'Pack Illimité',
          'description': '10000 pièces + tous les skins',
          'price': 39.99,
          'oldPrice': 49.99,
          'image': 'unlimited',
          'color': Colors.amber,
          'icon': Icons.attach_money,
          'category': 'Promotions',
          'isPromo': true,
        },
        {
          'id': 'prod5',
          'name': 'Boost XP',
          'description': 'Double XP pendant 7 jours',
          'price': 7.99,
          'image': 'xp',
          'color': Colors.green,
          'icon': Icons.speed,
          'category': 'Nouveautés',
          'isPromo': false,
        },
        {
          'id': 'prod6',
          'name': 'Super Pack',
          'description': '3000 pièces + 5 boosters',
          'price': 14.99,
          'oldPrice': 19.99,
          'image': 'super',
          'color': Colors.red,
          'icon': Icons.shopping_bag,
          'category': 'Promotions',
          'isPromo': true,
        },
      ];
    });
  }

  List<Map<String, dynamic>> getFilteredProducts() {
    if (selectedCategory == 'Tous') {
      return products;
    } else {
      return products.where((product) => product['category'] == selectedCategory).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = getFilteredProducts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boutique'),
        actions: [
          // Affichage des pièces/monnaie
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  coins.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // En-tête avec bannière promotionnelle
          Container(
            width: double.infinity,
            height: 120,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Icon(
                    Icons.shopping_cart,
                    size: 80,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'OFFRE SPÉCIALE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '-20% sur tous les packs premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('En profiter'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filtres par catégorie
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Grille de produits
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                final isPromo = product['isPromo'] == true;

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      _showProductDetailsDialog(context, product);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image du produit
                        Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: product['color'],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  product['icon'],
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                              if (isPromo)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'PROMO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Informations du produit
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product['description'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (isPromo) ...[
                                    Text(
                                      '${product['oldPrice']} €',
                                      style: TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    '${product['price']} €',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isPromo ? 16 : 14,
                                      color: isPromo ? Colors.red : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Bouton d'achat
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // Logique d'achat
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Achat de ${product['name']}...")),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text('Acheter'),
                            ),
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

  void _showProductDetailsDialog(BuildContext context, Map<String, dynamic> product) {
    final isPromo = product['isPromo'] == true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: product['color'],
                shape: BoxShape.circle,
              ),
              child: Icon(
                product['icon'],
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(product['description']),
            const SizedBox(height: 8),
            if (isPromo) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${product['oldPrice']} €',
                    style: TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${product['price']} €',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                '${product['price']} €',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Paiement sécurisé • Livraison instantanée',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Achat de ${product['name']} effectué!")),
              );
            },
            child: const Text('Acheter maintenant'),
          ),
        ],
      ),
    );
  }
}