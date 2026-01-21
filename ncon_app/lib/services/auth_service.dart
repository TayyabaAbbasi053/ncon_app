import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current Firebase user
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Stream to detect authentication changes
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Sign in
  Future<firebase_auth.User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint("✅ Sign-in successful: ${result.user?.email}");
      return result.user;
    } catch (error) {
      debugPrint("❌ Sign-in error: $error");
      rethrow;
    }
  }

  // Register a new user
  Future<firebase_auth.User?> registerWithEmailAndPassword(
      String email, String password, String name, String cmsId,
      {bool isSociety = false}) async {

    // 1. Let the error bubble up to the UI (No internal try-catch here)
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = result.user;
    if (user != null) {
      debugPrint("✅ User created: ${user.email}, UID: ${user.uid}");

      // 2. Save extra details to Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'name': name,
        'cmsId': cmsId,
        'isSociety': isSociety,
        'isVerified': false,
        'isAdmin': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      debugPrint("✅ User document created in Firestore!");
    }

    return user;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint("✅ User signed out successfully");
    } catch (error) {
      debugPrint("❌ Sign-out error: $error");
    }
  }
}