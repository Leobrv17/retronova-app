// Now let's update the main.dart file to include our friends functionality
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'screens/arcade_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/search_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/scoreboard_screen.dart';
import 'screens/friends_screen.dart'; // New import
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'services/auth_service.dart';
import 'providers/friend_provider.dart'; // New import
import 'widgets/friend_request_badge.dart'; // New import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        StreamProvider(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
        ),
        ChangeNotifierProvider(
          create: (_) => FriendProvider(), // Add the FriendProvider
        ),
      ],
      child: MaterialApp(
        title: 'Application avec Navbar',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const Wrapper(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/friends': (context) => const FriendsScreen(), // Add FriendsScreen route
        },
      ),
    );
  }
}

// Wrapper for navigation based on authentication state
class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    // If user is authenticated, show HomeScreen, otherwise show LoginScreen
    if (user != null) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Updated screens list with FriendsScreen
  static final List<Widget> _screens = [
    const ArcadeScreen(),
    const ShopScreen(),
    const SearchScreen(),
    const ScoreboardScreen(),
    const FriendsScreen(), // New FriendsScreen
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initialize FriendProvider when the home screen is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FriendProvider>(context, listen: false).initialize();
    });

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Important for more than 3 items
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports),
            label: 'Arcade',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Shop',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Scores',
          ),
          // Friend item with badge for pending requests
          BottomNavigationBarItem(
            icon: FriendRequestBadge(
              child: const Icon(Icons.people),
            ),
            label: 'Friends',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}