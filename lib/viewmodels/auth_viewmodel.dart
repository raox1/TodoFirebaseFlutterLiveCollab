import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthViewModel with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  String? _errorMessage;
  bool _isLoading = false; // Add this line

  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading; // Add this getter

  AuthViewModel() {
    _auth.authStateChanges().listen((user) {
      _currentUser = user;
      _errorMessage = null; // Clear error on auth state change
      _isLoading = false; // Ensure loading is false when auth state changes
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    _errorMessage = null;
    _isLoading = true; // Set loading to true
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
      debugPrint("Sign In Error: ${e.code} - ${e.message}");
    } finally {
      _isLoading = false; // Set loading to false
      notifyListeners();
    }
  }

Future<void> signUp(String email, String password) async {
  _errorMessage = null;
  notifyListeners();
  try {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    User? user = userCredential.user;

    if (user != null) {
      // --- IMPORTANT: Create user profile in Firestore 'users' collection ---
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        // You can add more profile info here, e.g., 'displayName': 'Lalit Kumar'
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  } on FirebaseAuthException catch (e) {
    _errorMessage = e.message;
    debugPrint("Sign Up Error: ${e.code} - ${e.message}");
  } finally {
    notifyListeners();
  }
}

  Future<void> signOut() async {
    _isLoading = true; // Set loading to true
    notifyListeners();
    try {
      await _auth.signOut();
    } catch (e) {
      _errorMessage = 'Failed to sign out: $e';
      debugPrint('Sign Out Error: $e');
    } finally {
      _isLoading = false; // Set loading to false
      notifyListeners();
    }
  }
}