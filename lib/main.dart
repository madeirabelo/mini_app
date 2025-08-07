import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'currency.dart';
import 'smvm.dart';
import 'dart:async';
import 'maps_page.dart';

// For web, the clientId is provided via meta tag in index.html
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: <String>[
    'email',
    'profile',
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    print("Initializing Firebase...");
    if (kIsWeb) {
      // For web, Firebase is initialized in index.html
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: "AIzaSyC9VP3Ims1wdmdcFLx9bpTHNW2T4LfdKtA",
          authDomain: "miniapp-17d46.firebaseapp.com",
          projectId: "miniapp-17d46",
          storageBucket: "miniapp-17d46.firebasestorage.app",
          messagingSenderId: "311492212143",
          appId: "1:311492212143:web:f483c1327a2b97a4216b5a",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    print("Firebase initialized successfully");
  } catch (e, stackTrace) {
    print("Error initializing Firebase: $e");
    print("Stack trace: $stackTrace");
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Apps',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.deepPurple,
        colorScheme: ColorScheme.dark(
          primary: Colors.deepPurple,
          secondary: Colors.tealAccent,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white.withOpacity(0.9),
          displayColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, // Explicitly set lighter text color
            backgroundColor: Colors.deepPurple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 16, // A bit bigger
              fontWeight: FontWeight.w500,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
        ),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _currentUser;
  bool _isAuthorized = false;
  List<dynamic> _authorizedUsers = [];
  bool _showAuthBanner = false;

  @override
  void initState() {
    super.initState();
    _loadAuthorizedUsers();
    print("Setting up auth state listener");
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      print("=== Auth state changed ===");
      print("User object: ${user?.toString() ?? 'null'}");
      print("User email: ${user?.email ?? 'null'}");
      print("User display name: ${user?.displayName ?? 'null'}");
      print("User uid: ${user?.uid ?? 'null'}");
      
      setState(() {
        _currentUser = user;
        _checkAuthorization();
        if (_currentUser != null) {
          _showAuthBanner = true;
          Timer(Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showAuthBanner = false;
              });
            }
          });
        }
      });
      
      if (_currentUser != null) {
        print("User signed in: ${_currentUser!.email}");
      } else {
        print("User signed out or not signed in");
      }
      print("=== End auth state change ===");
    });
  }

  Future<void> _handleSignIn() async {
    try {
      print("=== Starting Firebase Google Sign-In process ===");
      
      // Use Firebase's built-in Google Sign-In method
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser == null) {
        print("User canceled the sign-in");
        return;
      }
      
      print("Google Sign-In successful for: ${googleUser.email}");
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Check if we have the required tokens
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        print("ERROR: No tokens received from Google authentication");
        return;
      }
      
      print("Google auth tokens received - accessToken: ${googleAuth.accessToken != null}, idToken: ${googleAuth.idToken != null}");
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the Google credential
      print("Signing in to Firebase with Google credential");
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      setState(() {
        _currentUser = userCredential.user;
        _checkAuthorization();
        if (_currentUser != null) {
          _showAuthBanner = true;
          Timer(Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showAuthBanner = false;
              });
            }
          });
        }
      });
      
      // Verify the current user
      final currentUser = FirebaseAuth.instance.currentUser;
      print("Current Firebase user: ${currentUser?.email ?? 'null'}");
      
      // Add a small delay to ensure state updates properly
      await Future.delayed(Duration(milliseconds: 500));
      print("=== Firebase Google Sign-In process completed ===");
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.message}');
      print('Error code: ${e.code}');
    } catch (error, stackTrace) {
      print('Error signing in: $error');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _handleSignOut() async {
    try {
      print("Signing out...");
      await _googleSignIn.signOut(); // Sign out from Google
      await FirebaseAuth.instance.signOut(); // Sign out from Firebase
      print("Signed out successfully");
    } catch (error) {
      print('Error signing out: $error');
    }
  }

  Future<void> _loadAuthorizedUsers() async {
    try {
      final String yamlString = await rootBundle.loadString('users.yaml');
      final dynamic yamlMap = loadYaml(yamlString);
      setState(() {
        _authorizedUsers = yamlMap['users'];
        _checkAuthorization();
      });
    } catch (e) {
      print('Error loading authorized users: $e');
    }
  }

  void _checkAuthorization() {
    if (_currentUser == null) {
      setState(() {
        _isAuthorized = false;
      });
      return;
    }

    final userEmail = _currentUser!.email;
    for (var user in _authorizedUsers) {
      if (user['email'] == userEmail) {
        setState(() {
          _isAuthorized = true;
        });
        return;
      }
    }

    setState(() {
      _isAuthorized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mini Apps'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Authentication status indicator
            if (_showAuthBanner)
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _currentUser != null ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _currentUser != null ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                child: Text(
                  _currentUser != null ? '✅ AUTHENTICATED' : '❌ NOT AUTHENTICATED',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _currentUser != null ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ),
            if (_currentUser == null)
              ElevatedButton(
                child: Text('Sign in with Google'),
                onPressed: _handleSignIn,
              )
            else if (_isAuthorized)
              Column(
                children: [
                  Text('Signed in as: ${_currentUser!.displayName ?? _currentUser!.email}'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    child: Text('Currency'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CurrencyApp()),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    child: Text('SMVM'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SmvmApp()),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    child: Text('Maps'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MapsPage()),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    child: Text('Sign Out'),
                    onPressed: _handleSignOut,
                  ),
                ],
              )
            else
              Column(
                children: [
                  Text('You are not authorized to use this app.'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    child: Text('Sign Out'),
                    onPressed: _handleSignOut,
                  ),
                ],
              ),
            SizedBox(height: 20),
            SizedBox(height: 20),
            SizedBox(height: 20),
            Text(
              'Author: Antonio Belo',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}