import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../core/constants/firebase_constants.dart';
import '../services/firebase/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isInitialized = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isGoogleLoading => _isGoogleLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _auth.authStateChanges().listen(_onAuthStateChanged);

    // Check if there's a current user on startup
    final currentFirebaseUser = _auth.currentUser;
    if (currentFirebaseUser != null) {
      await _loadUserData(currentFirebaseUser.uid);
    }
    _isInitialized = true;
    notifyListeners();
  }

  void _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    if (firebaseUser != null) {
      await _loadUserData(firebaseUser.uid);
    } else {
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> _loadUserData(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        _currentUser = UserModel.fromJson({
          ...doc.data()!,
          'userId': doc.id,
        });
        notifyListeners();

        // Save FCM token for push notifications
        _saveFcmToken(userId);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  /// Save FCM token for push notifications
  Future<void> _saveFcmToken(String userId) async {
    try {
      final notificationService = NotificationService();
      final token = await notificationService.getFcmToken();
      if (token != null) {
        await notificationService.saveFcmToken(userId, token);
        debugPrint('FCM token saved for user: $userId');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _loadUserData(credential.user!.uid);
        return true;
      }
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An error occurred. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user document in Firestore (without role initially)
        final newUser = UserModel(
          userId: credential.user!.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          role: '', // Will be set in role selection
          isVerified: false,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(credential.user!.uid)
            .set(newUser.toJson());

        _currentUser = newUser;
        notifyListeners();
        return true;
      }
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An error occurred. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      _isGoogleLoading = true;
      _error = null;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _error = 'Google sign in was cancelled';
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Check if user exists in Firestore
        final userDoc = await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          // Existing user
          await _loadUserData(userCredential.user!.uid);
          return 'existing_user';
        } else {
          // New user - create document
          final nameParts = userCredential.user!.displayName?.split(' ') ?? ['', ''];
          final newUser = UserModel(
            userId: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            firstName: nameParts.first,
            lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
            role: '', // Will be set in role selection
            profileImage: userCredential.user!.photoURL,
            isVerified: false,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await _firestore
              .collection(FirebaseConstants.usersCollection)
              .doc(userCredential.user!.uid)
              .set(newUser.toJson());

          _currentUser = newUser;
          notifyListeners();
          return 'new_user';
        }
      }
      return null;
    } catch (e) {
      _error = 'Google sign in failed. Please try again.';
      notifyListeners();
      return null;
    } finally {
      _isGoogleLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserRole(String role) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_currentUser == null) return false;

      final updateData = <String, dynamic>{
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // If job provider, set pending_approval status
      if (role == 'job_provider') {
        updateData['providerStatus'] = 'pending_approval';
      }

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(_currentUser!.userId)
          .update(updateData);

      _currentUser = _currentUser!.copyWith(
        role: role,
        providerStatus: role == 'job_provider' ? 'pending_approval' : null,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update role. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent successfully');
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      _error = _getAuthErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Error sending reset email: $e');
      _error = 'Failed to send reset email. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh current user data from Firestore
  Future<void> refreshUserData() async {
    if (_currentUser == null) return;
    await _loadUserData(_currentUser!.userId);
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
