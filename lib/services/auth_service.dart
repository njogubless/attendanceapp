// FILE: lib/services/auth_service.dart
import 'package:attendanceapp/Models/user_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register user without signing in
  Future<void> registerOnly({
    required String email,
    required String password,
    required String name,
    required String role,
    required String regNo,
  }) async {
    try {
      // Create user with Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user model and store in Firestore
      UserModel userModel = UserModel(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        role: role,
        regNo: regNo, // Added registration number
        status: 'active', // Set to active by default
      );

      // Store user info in Firestore
      await _firestore.collection('users').doc(userModel.id).set(
            userModel.toFirestore(),
          );

      // Sign out immediately
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch user data from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found in database. Please contact support or register again.'); 
      }

      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  Future<void> updateProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }
}