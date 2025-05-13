// screens/scoreboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class ScoreboardScreen extends StatefulWidget {
  const ScoreboardScreen({Key? key}) : super(key: key);

  @override
  _ScoreboardScreenState createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> leaderboardEntries = [];
  String selectedCategory = 'Global';

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    // Simule un chargement des données
    await Future.delayed(const Duration(milliseconds: 800));

    // Données fictives pour le moment
    setState(() {
      leaderboardEntries = [
        {
          'rank': 1,
          'username': 'Champion87',
          'score': 9850,
          'avatar': Icons.emoji_events,
          'avatarColor': Colors.amber,
        },
        {
          'rank': 2,
          'username': 'RetroMaster',
          'score': 9540,
          'avatar': Icons.workspace_premium,
          'avatarColor': Colors.grey.shade400,
        },
        {
          'rank': 3,
          'username': 'PixelPro',
          'score': 8970,
          'avatar': Icons.emoji_events,
          'avatarColor': Colors.brown.shade300,
        },
        {
          'rank': 4,
          'username': 'GameWizard',
          'score': 8120,
          'avatar': Icons.person,
          'avatarColor': Colors.blue,
        },
        {
          'rank': 5,
          'username': 'ArcadeFan',
          'score': 7890,
          'avatar': Icons.person,
          'avatarColor': Colors.green,
        },
        {
          'rank': 6,
          'username': 'RetroGamer',
          'score': 7340,
          'avatar': Icons.person,
          'avatarColor': Colors.orange,
        },
        {
          'rank': 7,
          'username': 'HighScorer',
          'score': 6950,
          'avatar': Icons.person,
          'avatarColor': Colors.deepPurple,
        },
        {
          'rank': 8,
          'username': 'PixelHero',
          'score': 6720,
          'avatar': Icons.person,
          'avatarColor': Colors.red,
        },
        {
          'rank': 9,
          'username': 'GameChamp',
          'score': 6340,
          'avatar': Icons.person,
          'avatarColor': Colors.teal,
        },
        {
          'rank': 10,
          'username': 'LevelMaster',
          'score': 5980,
          'avatar': Icons.person,
          'avatarColor': Colors.indigo,
        },
      ];

      // Ajouter l'utilisateur actuel dans le classement (exemple)
      leaderboardEntries.add({
        'rank': 42,
        'username': 'Vous',
        'score': 3250,
        'avatar': Icons.person,
        'avatarColor': Colors.blue,
        'isCurrentUser': true,
      });

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classement'),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // En-tête avec catégories
          _buildCategorySelector(),

          // Bannière principale
          _buildHeaderBanner(),

          // Liste des joueurs
          Expanded(
            child: ListView.builder(
              itemCount: leaderboardEntries.length,
              itemBuilder: (context, index) {
                final entry = leaderboardEntries[index];
                return _buildLeaderboardItem(entry);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            _buildCategoryChip('Global', Icons.public),
            _buildCategoryChip('Amis', Icons.people),
            _buildCategoryChip('Mensuel', Icons.calendar_month),
            _buildCategoryChip('Arcade', Icons.sports_esports),
            _buildCategoryChip('Puzzle', Icons.extension),
            _buildCategoryChip('Action', Icons.flash_on),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String title, IconData icon) {
    final isSelected = selectedCategory == title;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(title),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              selectedCategory = title;
              // Recharger les données du leaderboard selon la catégorie
              _loadLeaderboard();
            });
          }
        },
        backgroundColor: Colors.white,
        selectedColor: Colors.blue,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),

          // Texte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Classement',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Consultez les meilleurs scores',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> entry) {
    final isCurrentUser = entry['isCurrentUser'] == true;
    final rank = entry['rank'];

    // Déterminer le style en fonction du rang
    Color rankColor;
    IconData? medalIcon;

    if (rank == 1) {
      rankColor = Colors.amber;  // Or
      medalIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = Colors.grey.shade400;  // Argent
      medalIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = Colors.brown.shade300;  // Bronze
      medalIcon = Icons.emoji_events;
    } else {
      rankColor = Colors.blue.shade700; // Autre
      medalIcon = null;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isCurrentUser ? 3 : 1,
      color: isCurrentUser ? Colors.blue.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isCurrentUser
            ? BorderSide(color: Colors.blue.shade300, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        // Affichage du rang
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: rankColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: medalIcon != null
                ? Icon(medalIcon, color: rankColor, size: 24)
                : Text(
              '#$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: rankColor,
                fontSize: 16,
              ),
            ),
          ),
        ),

        // Avatar et nom d'utilisateur
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: entry['avatarColor'],
              child: Icon(
                entry['avatar'],
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry['username'],
                style: TextStyle(
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),

        // Score
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${entry['score']}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),

        onTap: () {
          // Afficher plus de détails sur le joueur
          _showPlayerDetails(entry);
        },
      ),
    );
  }

  void _showPlayerDetails(Map<String, dynamic> player) {
    final isCurrentUser = player['isCurrentUser'] == true;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: player['avatarColor'],
              child: Icon(
                player['avatar'],
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              player['username'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rang #${player['rank']} • Score: ${player['score']}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // Stats du joueur
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('Parties', '124'),
                _buildStatColumn('Victoires', '78'),
                _buildStatColumn('Taux', '63%'),
              ],
            ),

            const SizedBox(height: 24),

            if (isCurrentUser)
              const Text(
                'C\'est votre score actuel. Continuez à jouer pour améliorer votre classement!',
                textAlign: TextAlign.center,
                style: TextStyle(fontStyle: FontStyle.italic),
              )
            else
              ElevatedButton(
                onPressed: () {
                  // Logique pour ajouter un ami
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invitation envoyée à ${player['username']}')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Ajouter en ami'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}