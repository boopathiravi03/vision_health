import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  Future<String?> getRole(String uid) async {
    final profile = await _firestore.collection('users').doc(uid).get();
    final data = profile.data();
    if (data == null) return null;
    return data['role']?.toString();
  }

  Future<bool> hasRole(String uid, String role) async {
    final currentRole = await getRole(uid);
    if (currentRole == role) return true;
    if (currentRole == null) {
      await _firestore.collection('users').doc(uid).set({
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    }
    return false;
  }
}
