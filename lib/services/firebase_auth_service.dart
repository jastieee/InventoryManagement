import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Initialize and check if user is already logged in
  Future<void> initialize() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _loadUserData(firebaseUser.uid);
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _currentUser = User(
          id: uid,
          username: data['username'] ?? '',
          email: data['email'] ?? '',
          name: data['name'] ?? '',
          role: data['role'] ?? 'user',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Login with email or username and password
  Future<Map<String, dynamic>> login(String usernameOrEmail, String password) async {
    try {
      String email = usernameOrEmail.trim();

      // Check if input is a username (doesn't contain @)
      if (!usernameOrEmail.contains('@')) {
        // Look up email from username
        final usernameDoc = await _firestore
            .collection('usernames')
            .doc(usernameOrEmail.toLowerCase())
            .get();

        if (!usernameDoc.exists) {
          return {
            'success': false,
            'message': 'User not found',
          };
        }

        // Get the user's email
        final uid = usernameDoc.data()!['uid'];
        final userDoc = await _firestore.collection('users').doc(uid).get();

        if (!userDoc.exists) {
          return {
            'success': false,
            'message': 'User data not found',
          };
        }

        email = userDoc.data()!['email'];
      }

      // Now authenticate with email
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _loadUserData(credential.user!.uid);

      return {
        'success': true,
        'message': 'Login successful',
        'user': _currentUser,
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      String message = 'An error occurred';

      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'wrong-password':
          message = 'Wrong password';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password';
          break;
        default:
          message = e.message ?? 'Authentication failed';
      }

      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Register new user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String name,
    String role = 'user',
  }) async {
    try {
      // Check if username is already taken
      final usernameExists = await this.usernameExists(username);
      if (usernameExists) {
        return {
          'success': false,
          'message': 'Username already taken',
        };
      }

      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'username': username.toLowerCase(),
        'email': email.toLowerCase(),
        'name': name,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Also store username mapping for quick lookup
      await _firestore.collection('usernames').doc(username.toLowerCase()).set({
        'uid': credential.user!.uid,
      });

      await _loadUserData(credential.user!.uid);

      return {
        'success': true,
        'message': 'Registration successful',
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      String message = 'An error occurred';

      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email already registered';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'weak-password':
          message = 'Password is too weak (min 6 characters)';
          break;
        default:
          message = e.message ?? 'Registration failed';
      }

      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Update user
  Future<Map<String, dynamic>> updateUser({
    required String username,
    required String name,
    required String role,
    String? newPassword,
  }) async {
    try {
      // Find user by username
      final usernameDoc = await _firestore
          .collection('usernames')
          .doc(username.toLowerCase())
          .get();

      if (!usernameDoc.exists) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }

      final uid = usernameDoc.data()!['uid'];

      // Update user data in Firestore
      await _firestore.collection('users').doc(uid).update({
        'name': name,
        'role': role,
      });

      // Update password if provided
      if (newPassword != null && newPassword.isNotEmpty) {
        // Note: This requires the user to be logged in as themselves
        // For admin password reset, you'd need Firebase Admin SDK
        final currentFirebaseUser = _auth.currentUser;
        if (currentFirebaseUser != null && currentFirebaseUser.uid == uid) {
          await currentFirebaseUser.updatePassword(newPassword);
        }
      }

      return {
        'success': true,
        'message': 'User updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Delete user
  Future<Map<String, dynamic>> deleteUser(String username) async {
    try {
      // Find user by username
      final usernameDoc = await _firestore
          .collection('usernames')
          .doc(username.toLowerCase())
          .get();

      if (!usernameDoc.exists) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }

      final uid = usernameDoc.data()!['uid'];

      // Delete from Firestore
      await _firestore.collection('users').doc(uid).delete();
      await _firestore.collection('usernames').doc(username.toLowerCase()).delete();

      // Note: Deleting from Firebase Auth requires Firebase Admin SDK
      // or the user must be currently logged in
      // For production, implement Firebase Cloud Functions for this

      return {
        'success': true,
        'message': 'User deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Check if username exists
  Future<bool> usernameExists(String username) async {
    try {
      final doc = await _firestore
          .collection('usernames')
          .doc(username.toLowerCase())
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Check if email exists (deprecated method, use alternative)
  Future<bool> emailExists(String email) async {
    try {
      // Alternative: Query Firestore users collection
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get all users (Admin only) - Returns Map<String, String>
  Future<List<Map<String, String>>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'username': (data['username'] ?? '') as String,
          'email': (data['email'] ?? '') as String,
          'name': (data['name'] ?? '') as String,
          'role': (data['role'] ?? 'user') as String,
        };
      }).toList();
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
  }
}