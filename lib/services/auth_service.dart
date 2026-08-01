import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<User?> signInAnonymously() async {
    // Already signed in from a previous launch — this is a local check,
    // no network needed. Only hit the network the very first time.
    if (_auth.currentUser != null) return _auth.currentUser;
    final credential = await _auth.signInAnonymously();
    return credential.user;
  }

  static User? get currentUser => _auth.currentUser;
}