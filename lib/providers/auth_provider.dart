import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  User? _firebaseUser;
  bool _isLoading = true;
  bool _isFirebaseInitialized = false;

  AuthProvider() {
    _init();
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  User? get firebaseUser => _firebaseUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _firebaseUser != null && _isFirebaseInitialized;

  // Initialize auth state listener
  void _init() async {
    _authService.authStateChanges.listen((User? user) async {
      _firebaseUser = user;

      if (user != null) {
        try {
          // Get user data from Firestore
          _currentUser = await _authService.getUserData(user.uid);
          _isFirebaseInitialized = true;
        } catch (e) {
          print('Error getting user data: $e');
          _isFirebaseInitialized = false;
        }
      } else {
        _currentUser = null;
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  // Sign in
  Future<bool> signIn(String email, String password) async {
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (user != null) {
        _currentUser = user;
        _isFirebaseInitialized = true;
        notifyListeners();
        return true;
      }
    } catch (e) {
      rethrow;
    }
    return false;
  }

  // Sign up
  Future<bool> signUp(String email, String password, String displayName) async {
    try {
      final user = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (user != null) {
        _currentUser = user;
        _isFirebaseInitialized = true;
        notifyListeners();
        return true;
      }
    } catch (e) {
      rethrow;
    }
    return false;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _currentUser = null;
      _firebaseUser = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Update user data
  void updateUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }
}